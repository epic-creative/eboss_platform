defmodule EBossFolio.Area do
  use Ash.Resource,
    otp_app: :eboss_folio,
    domain: EBossFolio,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("folio_areas")
    repo(EBoss.Repo)
  end

  actions do
    read :read do
      primary?(true)
    end

    create :create do
      primary?(true)
      accept([:workspace_id, :name, :description, :review_interval_days])
      change({EBossFolio.Changes.AuditAction, event_action: :create})
    end

    update :update do
      primary?(true)
      require_atomic?(false)
      accept([:name, :description, :review_interval_days])
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
      authorize_if(EBossFolio.Checks.ActorOwnsWorkspaceFilter)
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

    attribute :description, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :review_interval_days, :integer do
      allow_nil?(true)
      public?(true)
      constraints(min: 1)
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
  end

  identities do
    identity(:unique_name_in_workspace, [:workspace_id, :name])
  end
end
