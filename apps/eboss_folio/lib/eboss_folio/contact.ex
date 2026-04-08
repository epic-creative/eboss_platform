defmodule EBossFolio.Contact do
  use Ash.Resource,
    otp_app: :eboss_folio,
    domain: EBossFolio,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("folio_contacts")
    repo(EBoss.Repo)
  end

  actions do
    read :read do
      primary?(true)
    end

    create :create do
      primary?(true)
      accept([:workspace_id, :name, :email, :capability_notes])
      change({EBossFolio.Changes.AuditAction, event_action: :create})
    end

    update :update do
      primary?(true)
      require_atomic?(false)
      accept([:name, :email, :capability_notes])
      change({EBossFolio.Changes.AuditAction, event_action: :update})
    end

    update :archive do
      require_atomic?(false)
      accept([])
      change(set_attribute(:status, :archived))
      change({EBossFolio.Changes.AuditAction, event_action: :transition})
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if(expr(workspace.owner_type == :user and workspace.owner_id == ^actor(:id)))
      authorize_if(relates_to_actor_via([:workspace, :organization, :owner]))
    end

    policy action_type([:create, :update]) do
      authorize_if(EBossFolio.Checks.ActorOwnsWorkspace)
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      public?(true)
      constraints(min_length: 1, max_length: 255)
    end

    attribute :email, :ci_string do
      allow_nil?(true)
      public?(true)
    end

    attribute :capability_notes, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :status, :atom do
      allow_nil?(false)
      public?(true)
      default(:active)
      constraints(one_of: [:active, :archived])
    end

    timestamps()
  end

  relationships do
    belongs_to :workspace, EBoss.Workspaces.Workspace do
      allow_nil?(false)
      public?(true)
    end

    has_many :delegations, EBossFolio.Delegation do
      destination_attribute(:contact_id)
      public?(true)
    end
  end

  identities do
    identity(:unique_email_in_workspace, [:workspace_id, :email])
  end
end
