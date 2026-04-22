defmodule EBossNotify.NotificationRecipient do
  @moduledoc """
  Per-user in-app state for a notification.
  """

  use Ash.Resource,
    otp_app: :eboss_notify,
    domain: EBossNotify,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("notify_notification_recipients")
    repo(EBoss.Repo)
    identity_index_names(unique_notification_recipient: "notify_recipients_unique_user_index")
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:notification_id, :user_id, :status, :read_at, :last_seen_at])
    end

    update :mark_read do
      accept([])
      require_atomic?(false)
      change(set_attribute(:status, :read))
      change(set_attribute(:read_at, &DateTime.utc_now/0))
      change(set_attribute(:last_seen_at, &DateTime.utc_now/0))
    end

    update :archive do
      accept([])
      require_atomic?(false)
      change(set_attribute(:status, :archived))
      change(set_attribute(:archived_at, &DateTime.utc_now/0))
      change(set_attribute(:last_seen_at, &DateTime.utc_now/0))
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

    attribute :status, :atom do
      allow_nil?(false)
      public?(true)
      default(:unread)
      constraints(one_of: [:unread, :read, :archived])
    end

    attribute :read_at, :utc_datetime_usec do
      allow_nil?(true)
      public?(true)
    end

    attribute :archived_at, :utc_datetime_usec do
      allow_nil?(true)
      public?(true)
    end

    attribute :last_seen_at, :utc_datetime_usec do
      allow_nil?(true)
      public?(true)
    end

    timestamps()
  end

  relationships do
    belongs_to :notification, EBossNotify.Notification do
      allow_nil?(false)
      public?(true)
    end

    has_many :deliveries, EBossNotify.NotificationDelivery do
      destination_attribute(:recipient_id)
      public?(true)
    end
  end

  identities do
    identity(:unique_notification_recipient, [:notification_id, :user_id])
  end
end
