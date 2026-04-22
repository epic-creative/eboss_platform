defmodule EBoss.Repo.Migrations.AddEbossChatV1 do
  use Ecto.Migration

  def change do
    create table(:chat_sessions, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :title, :text, null: false
      add :status, :text, null: false, default: "active"
      add :last_message_at, :utc_datetime_usec
      add :last_activity_at, :utc_datetime_usec

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :workspace_id,
          references(:workspaces,
            column: :id,
            type: :uuid,
            name: "chat_sessions_workspace_id_fkey",
            prefix: "public"
          ),
          null: false

      add :created_by_user_id,
          references(:users,
            column: :id,
            type: :uuid,
            name: "chat_sessions_created_by_user_id_fkey",
            prefix: "public"
          ),
          null: false
    end

    create index(:chat_sessions, [:workspace_id, :status, :last_activity_at],
             name: "chat_sessions_workspace_status_activity_index"
           )

    create index(:chat_sessions, [:workspace_id, :inserted_at],
             name: "chat_sessions_workspace_inserted_at_index"
           )

    create table(:chat_messages, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :role, :text, null: false
      add :body, :text, null: false, default: ""
      add :status, :text, null: false, default: "complete"
      add :sequence, :bigint, null: false
      add :provider, :text
      add :model, :text
      add :input_tokens, :bigint
      add :output_tokens, :bigint
      add :total_tokens, :bigint
      add :finish_reason, :text
      add :error_message, :text

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :session_id,
          references(:chat_sessions,
            column: :id,
            type: :uuid,
            name: "chat_messages_session_id_fkey",
            prefix: "public"
          ),
          null: false

      add :workspace_id,
          references(:workspaces,
            column: :id,
            type: :uuid,
            name: "chat_messages_workspace_id_fkey",
            prefix: "public"
          ),
          null: false

      add :created_by_user_id,
          references(:users,
            column: :id,
            type: :uuid,
            name: "chat_messages_created_by_user_id_fkey",
            prefix: "public"
          )
    end

    create unique_index(:chat_messages, [:session_id, :sequence],
             name: "chat_messages_unique_session_sequence_index"
           )

    create unique_index(:chat_messages, [:session_id],
             name: "chat_messages_unique_pending_assistant_index",
             where: "role = 'assistant' AND status = 'pending'"
           )

    create index(:chat_messages, [:workspace_id, :inserted_at],
             name: "chat_messages_workspace_inserted_at_index"
           )

    create index(:chat_messages, [:session_id, :inserted_at],
             name: "chat_messages_session_inserted_at_index"
           )
  end
end
