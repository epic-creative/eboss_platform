defmodule EBoss.Repo.Migrations.AddEbossNotifyV1 do
  use Ecto.Migration

  def change do
    create table(:notify_notifications, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :scope_type, :text, null: false
      add :scope_id, :uuid
      add :workspace_id, :uuid
      add :organization_id, :uuid
      add :app_key, :text
      add :notification_key, :text, null: false
      add :title, :text, null: false
      add :body, :text
      add :severity, :text, null: false, default: "info"
      add :actor_type, :text, null: false, default: "system"
      add :actor_id, :uuid
      add :subject_type, :text
      add :subject_id, :uuid
      add :subject_label, :text
      add :action_url, :text
      add :metadata, :map, null: false, default: %{}
      add :idempotency_key, :text
      add :occurred_at, :utc_datetime_usec, null: false
      add :inserted_at, :utc_datetime_usec, null: false
    end

    create unique_index(:notify_notifications, [:idempotency_key],
             name: "notify_notifications_unique_idempotency_key_index",
             where: "idempotency_key IS NOT NULL"
           )

    create index(:notify_notifications, [:scope_type, :scope_id, :occurred_at],
             name: "notify_notifications_scope_index"
           )

    create index(:notify_notifications, [:workspace_id, :app_key, :occurred_at],
             name: "notify_notifications_workspace_app_index"
           )

    create table(:notify_notification_recipients, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :notification_id,
          references(:notify_notifications, type: :uuid, on_delete: :delete_all),
          null: false

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :status, :text, null: false, default: "unread"
      add :read_at, :utc_datetime_usec
      add :archived_at, :utc_datetime_usec
      add :last_seen_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:notify_notification_recipients, [:notification_id, :user_id],
             name: "notify_notification_recipients_unique_user_index"
           )

    create index(:notify_notification_recipients, [:user_id, :status, :inserted_at],
             name: "notify_notification_recipients_user_status_index"
           )

    create table(:notify_channel_endpoints, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :channel, :text, null: false
      add :address, :text
      add :external_id, :text
      add :status, :text, null: false, default: "unverified"
      add :primary, :boolean, null: false, default: false
      add :verified_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:notify_channel_endpoints, [:user_id, :channel, :address],
             name: "notify_channel_endpoints_unique_address_index",
             where: "address IS NOT NULL"
           )

    create index(:notify_channel_endpoints, [:user_id, :channel],
             name: "notify_channel_endpoints_user_channel_index"
           )

    create table(:notify_preferences, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :scope_type, :text, null: false, default: "system"
      add :scope_id, :uuid
      add :app_key, :text
      add :notification_key, :text
      add :channel, :text, null: false
      add :enabled, :boolean, null: false, default: true
      add :cadence, :text, null: false, default: "immediate"
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(
             :notify_preferences,
             [
               :user_id,
               :scope_type,
               "COALESCE(scope_id, '00000000-0000-0000-0000-000000000000'::uuid)",
               "COALESCE(app_key, '')",
               "COALESCE(notification_key, '')",
               :channel
             ],
             name: "notify_preferences_unique_match_index"
           )

    create index(:notify_preferences, [:user_id, :channel],
             name: "notify_preferences_user_channel_index"
           )

    create table(:notify_deliveries, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :notification_id,
          references(:notify_notifications, type: :uuid, on_delete: :delete_all),
          null: false

      add :recipient_id,
          references(:notify_notification_recipients, type: :uuid, on_delete: :delete_all),
          null: false

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :channel, :text, null: false
      add :endpoint_id, :uuid
      add :status, :text, null: false, default: "pending"
      add :provider, :text
      add :provider_message_id, :text
      add :attempt_count, :integer, null: false, default: 0
      add :last_attempt_at, :utc_datetime_usec
      add :delivered_at, :utc_datetime_usec
      add :error_message, :text
      add :metadata, :map, null: false, default: %{}
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:notify_deliveries, [:recipient_id, :channel],
             name: "notify_deliveries_unique_recipient_channel_index"
           )

    create index(:notify_deliveries, [:user_id, :channel, :status],
             name: "notify_deliveries_user_channel_status_index"
           )
  end
end
