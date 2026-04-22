defmodule EBossNotify.NotificationChannelEndpoint do
  @moduledoc """
  Per-user address or provider handle for a notification channel.
  """

  use Ash.Resource,
    otp_app: :eboss_notify,
    domain: EBossNotify,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("notify_channel_endpoints")
    repo(EBoss.Repo)

    identity_index_names(
      unique_user_channel_address: "notify_channel_endpoints_unique_address_index"
    )
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)

      accept([
        :user_id,
        :channel,
        :address,
        :external_id,
        :status,
        :primary,
        :verified_at,
        :metadata
      ])
    end

    update :update do
      primary?(true)
      accept([:address, :external_id, :primary, :metadata])
      require_atomic?(false)
    end

    update :disable do
      accept([])
      require_atomic?(false)
      change(set_attribute(:status, :disabled))
    end

    update :verify do
      accept([:external_id, :metadata])
      require_atomic?(false)
      change(set_attribute(:status, :verified))
      change(set_attribute(:verified_at, &DateTime.utc_now/0))
    end
  end

  policies do
    policy action(:verify) do
      forbid_if(always())
    end

    policy action_type(:read) do
      authorize_if(expr(user_id == ^actor(:id)))
    end

    policy action_type(:update) do
      authorize_if(expr(user_id == ^actor(:id)))
    end

    policy action_type([:create, :destroy]) do
      forbid_if(always())
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :user_id, :uuid do
      allow_nil?(false)
      public?(true)
    end

    attribute :channel, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:in_app, :email, :sms, :telegram, :webhook, :push])
    end

    attribute :address, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :external_id, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :status, :atom do
      allow_nil?(false)
      public?(true)
      default(:unverified)
      constraints(one_of: [:unverified, :verified, :disabled])
    end

    attribute :primary, :boolean do
      allow_nil?(false)
      public?(true)
      default(false)
    end

    attribute :verified_at, :utc_datetime_usec do
      allow_nil?(true)
      public?(true)
    end

    attribute :metadata, :map do
      allow_nil?(false)
      public?(true)
      default(%{})
    end

    timestamps()
  end

  identities do
    identity(:unique_user_channel_address, [:user_id, :channel, :address])
  end
end
