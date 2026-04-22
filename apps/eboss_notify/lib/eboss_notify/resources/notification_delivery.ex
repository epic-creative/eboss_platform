defmodule EBossNotify.NotificationDelivery do
  @moduledoc """
  Per-channel delivery attempt/status for a notification recipient.
  """

  use Ash.Resource,
    otp_app: :eboss_notify,
    domain: EBossNotify,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("notify_deliveries")
    repo(EBoss.Repo)
    identity_index_names(unique_recipient_channel: "notify_deliveries_unique_recipient_channel_index")
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)

      accept([
        :notification_id,
        :recipient_id,
        :user_id,
        :channel,
        :endpoint_id,
        :status,
        :provider,
        :provider_message_id,
        :attempt_count,
        :last_attempt_at,
        :delivered_at,
        :error_message,
        :metadata
      ])
    end

    update :update_status do
      accept([
        :status,
        :provider,
        :provider_message_id,
        :attempt_count,
        :last_attempt_at,
        :delivered_at,
        :error_message,
        :metadata
      ])
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if(expr(user_id == ^actor(:id)))
    end

    policy action_type(:update) do
      forbid_if(always())
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

    attribute :endpoint_id, :uuid do
      allow_nil?(true)
      public?(true)
    end

    attribute :status, :atom do
      allow_nil?(false)
      public?(true)
      default(:pending)

      constraints(
        one_of: [
          :pending,
          :suppressed,
          :not_configured,
          :queued,
          :sent,
          :delivered,
          :failed,
          :canceled
        ]
      )
    end

    attribute :provider, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :provider_message_id, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :attempt_count, :integer do
      allow_nil?(false)
      public?(true)
      default(0)
      constraints(min: 0)
    end

    attribute :last_attempt_at, :utc_datetime_usec do
      allow_nil?(true)
      public?(true)
    end

    attribute :delivered_at, :utc_datetime_usec do
      allow_nil?(true)
      public?(true)
    end

    attribute :error_message, :string do
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

  relationships do
    belongs_to :notification, EBossNotify.Notification do
      allow_nil?(false)
      public?(true)
    end

    belongs_to :recipient, EBossNotify.NotificationRecipient do
      allow_nil?(false)
      public?(true)
    end
  end

  identities do
    identity(:unique_recipient_channel, [:recipient_id, :channel])
  end
end
