defmodule EBossNotify.Notification do
  @moduledoc """
  Immutable notification event envelope.
  """

  use Ash.Resource,
    otp_app: :eboss_notify,
    domain: EBossNotify,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("notify_notifications")
    repo(EBoss.Repo)
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)

      accept([
        :scope_type,
        :scope_id,
        :workspace_id,
        :organization_id,
        :app_key,
        :notification_key,
        :title,
        :body,
        :severity,
        :actor_type,
        :actor_id,
        :subject_type,
        :subject_id,
        :subject_label,
        :action_url,
        :metadata,
        :idempotency_key,
        :occurred_at
      ])
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if(expr(exists(recipients, user_id == ^actor(:id))))
    end

    policy action_type([:create, :update, :destroy]) do
      forbid_if(always())
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :scope_type, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:system, :user, :organization, :workspace, :app])
    end

    attribute :scope_id, :uuid do
      allow_nil?(true)
      public?(true)
    end

    attribute :workspace_id, :uuid do
      allow_nil?(true)
      public?(true)
    end

    attribute :organization_id, :uuid do
      allow_nil?(true)
      public?(true)
    end

    attribute :app_key, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :notification_key, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :title, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :body, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :severity, :atom do
      allow_nil?(false)
      public?(true)
      default(:info)
      constraints(one_of: [:info, :success, :warning, :error])
    end

    attribute :actor_type, :atom do
      allow_nil?(false)
      public?(true)
      default(:system)
      constraints(one_of: [:system, :user, :api_key, :agent, :bot])
    end

    attribute :actor_id, :uuid do
      allow_nil?(true)
      public?(true)
    end

    attribute :subject_type, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :subject_id, :uuid do
      allow_nil?(true)
      public?(true)
    end

    attribute :subject_label, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :action_url, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :metadata, :map do
      allow_nil?(false)
      public?(true)
      default(%{})
    end

    attribute :idempotency_key, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :occurred_at, :utc_datetime_usec do
      allow_nil?(false)
      public?(true)
      default(&DateTime.utc_now/0)
    end

    create_timestamp(:inserted_at)
  end

  relationships do
    has_many :recipients, EBossNotify.NotificationRecipient do
      destination_attribute(:notification_id)
      public?(true)
    end

    has_many :deliveries, EBossNotify.NotificationDelivery do
      destination_attribute(:notification_id)
      public?(true)
    end
  end

  identities do
    identity(:unique_idempotency_key, [:idempotency_key])
  end
end
