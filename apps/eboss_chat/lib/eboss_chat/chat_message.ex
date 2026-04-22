defmodule EBossChat.ChatMessage do
  use Ash.Resource,
    otp_app: :eboss_chat,
    domain: EBossChat,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("chat_messages")
    repo(EBoss.Repo)
  end

  code_interface do
    define(:create_chat_message, action: :create)
    define(:mark_chat_message_complete, action: :mark_complete)
    define(:mark_chat_message_error, action: :mark_error)
    define(:get_chat_message, action: :read, get_by: [:id])
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)

      accept([
        :session_id,
        :workspace_id,
        :role,
        :body,
        :status,
        :sequence,
        :provider,
        :model,
        :input_tokens,
        :output_tokens,
        :total_tokens,
        :finish_reason,
        :error_message,
        :created_by_user_id
      ])
    end

    update :mark_complete do
      require_atomic?(false)

      accept([
        :body,
        :provider,
        :model,
        :input_tokens,
        :output_tokens,
        :total_tokens,
        :finish_reason
      ])

      change(set_attribute(:status, :complete))
      change(set_attribute(:error_message, nil))
    end

    update :mark_error do
      require_atomic?(false)
      accept([:error_message, :provider, :model, :finish_reason])
      change(set_attribute(:status, :error))
      change(set_attribute(:body, ""))
      change(set_attribute(:input_tokens, 0))
      change(set_attribute(:output_tokens, 0))
      change(set_attribute(:total_tokens, 0))
    end
  end

  policies do
    policy action(:read) do
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
  end

  attributes do
    uuid_primary_key(:id)

    attribute :role, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:user, :assistant, :system])
    end

    attribute :body, :string do
      allow_nil?(false)
      public?(true)
      default("")
      constraints(allow_empty?: true, trim?: false)
    end

    attribute :status, :atom do
      allow_nil?(false)
      public?(true)
      default(:complete)
      constraints(one_of: [:pending, :complete, :error])
    end

    attribute :sequence, :integer do
      allow_nil?(false)
      public?(true)
      constraints(min: 1)
    end

    attribute :provider, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :model, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :input_tokens, :integer do
      allow_nil?(true)
      public?(true)
      constraints(min: 0)
    end

    attribute :output_tokens, :integer do
      allow_nil?(true)
      public?(true)
      constraints(min: 0)
    end

    attribute :total_tokens, :integer do
      allow_nil?(true)
      public?(true)
      constraints(min: 0)
    end

    attribute :finish_reason, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :error_message, :string do
      allow_nil?(true)
      public?(true)
    end

    timestamps()
  end

  relationships do
    belongs_to :session, EBossChat.ChatSession do
      allow_nil?(false)
      public?(true)
    end

    belongs_to :workspace, EBoss.Workspaces.Workspace do
      allow_nil?(false)
      public?(true)
    end

    belongs_to :created_by_user, EBoss.Accounts.User do
      allow_nil?(true)
      public?(true)
    end
  end

  identities do
    identity(:unique_sequence_in_session, [:session_id, :sequence])
  end
end
