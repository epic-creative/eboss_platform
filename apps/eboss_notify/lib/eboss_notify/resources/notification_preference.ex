defmodule EBossNotify.NotificationPreference do
  @moduledoc """
  Per-user channel preference for a scope/app/notification key.
  """

  use Ash.Resource,
    otp_app: :eboss_notify,
    domain: EBossNotify,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("notify_preferences")
    repo(EBoss.Repo)
    identity_index_names(unique_user_preference: "notify_preferences_unique_match_index")
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)

      accept([
        :user_id,
        :scope_type,
        :scope_id,
        :app_key,
        :notification_key,
        :channel,
        :enabled,
        :cadence
      ])
    end

    update :update do
      primary?(true)
      accept([:enabled, :cadence])
    end
  end

  policies do
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

    attribute :scope_type, :atom do
      allow_nil?(false)
      public?(true)
      default(:system)
      constraints(one_of: [:system, :user, :organization, :workspace, :app])
    end

    attribute :scope_id, :uuid do
      allow_nil?(true)
      public?(true)
    end

    attribute :app_key, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :notification_key, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :channel, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:in_app, :email, :sms, :telegram, :webhook, :push])
    end

    attribute :enabled, :boolean do
      allow_nil?(false)
      public?(true)
      default(true)
    end

    attribute :cadence, :atom do
      allow_nil?(false)
      public?(true)
      default(:immediate)
      constraints(one_of: [:immediate, :digest, :disabled])
    end

    timestamps()
  end

  identities do
    identity(:unique_user_preference, [
      :user_id,
      :scope_type,
      :scope_id,
      :app_key,
      :notification_key,
      :channel
    ])
  end
end
