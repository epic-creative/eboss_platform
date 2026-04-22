defmodule EBossChat.ChatSession do
  use Ash.Resource,
    otp_app: :eboss_chat,
    domain: EBossChat,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("chat_sessions")
    repo(EBoss.Repo)
  end

  code_interface do
    define(:create_chat_session, action: :create)
    define(:archive_chat_session, action: :archive)
    define(:touch_chat_session_activity, action: :touch_activity)
    define(:get_chat_session, action: :read, get_by: [:id])
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:workspace_id])

      argument :title_seed, :string do
        allow_nil?(true)
      end

      change(relate_actor(:created_by_user, allow_nil?: false))
      change(set_attribute(:status, :active))
      change(set_attribute(:last_activity_at, &DateTime.utc_now/0))
      change(EBossChat.Changes.DeriveSessionTitle)
    end

    update :archive do
      require_atomic?(false)
      accept([])
      change(set_attribute(:status, :archived))
      change(set_attribute(:last_activity_at, &DateTime.utc_now/0))
    end

    update :touch_activity do
      require_atomic?(false)
      accept([:last_message_at, :last_activity_at])
    end
  end

  policies do
    policy action([:read, :touch_activity]) do
      authorize_if(expr(workspace.owner_type == :user and workspace.owner_id == ^actor(:id)))
      authorize_if(expr(exists(workspace.workspace_memberships, user_id == ^actor(:id))))

      authorize_if(
        expr(
          workspace.owner_type == :organization and
            exists(workspace.organization_memberships, user_id == ^actor(:id))
        )
      )
    end

    policy action(:create) do
      authorize_if(EBossChat.Checks.ActorCanAccessWorkspace)
    end

    policy action(:archive) do
      authorize_if(expr(created_by_user_id == ^actor(:id)))
      authorize_if(EBossChat.Checks.ActorCanManageSession)
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :title, :string do
      allow_nil?(false)
      public?(true)
      constraints(min_length: 1, max_length: 80)
    end

    attribute :status, :atom do
      allow_nil?(false)
      public?(true)
      default(:active)
      constraints(one_of: [:active, :archived])
    end

    attribute :last_message_at, :utc_datetime_usec do
      allow_nil?(true)
      public?(true)
    end

    attribute :last_activity_at, :utc_datetime_usec do
      allow_nil?(true)
      public?(true)
    end

    timestamps()
  end

  relationships do
    belongs_to :workspace, EBoss.Workspaces.Workspace do
      allow_nil?(false)
      public?(true)
    end

    belongs_to :created_by_user, EBoss.Accounts.User do
      allow_nil?(false)
      public?(true)
    end

    has_many :messages, EBossChat.ChatMessage do
      destination_attribute(:session_id)
    end
  end

  aggregates do
    count(:message_count, :messages)
    sum(:total_input_tokens, :messages, :input_tokens)
    sum(:total_output_tokens, :messages, :output_tokens)
    sum(:total_tokens_sum, :messages, :total_tokens)
  end
end
