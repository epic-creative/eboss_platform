defmodule EBossFolio.Project do
  use Ash.Resource,
    otp_app: :eboss_folio,
    domain: EBossFolio,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("folio_projects")
    repo(EBoss.Repo)
  end

  actions do
    read :read do
      primary?(true)
    end

    create :create do
      primary?(true)

      accept([
        :workspace_id,
        :title,
        :description,
        :status,
        :due_at,
        :review_at,
        :priority_position,
        :notes,
        :metadata,
        :source,
        :area_id,
        :horizon_id,
        :context_id
      ])

      validate(
        {EBossFolio.Validations.BelongsToWorkspace,
         relationships: [
           area_id: EBossFolio.Area,
           horizon_id: EBossFolio.Horizon,
           context_id: EBossFolio.Context
         ]}
      )

      change({EBossFolio.Changes.AuditAction, event_action: :create})
    end

    update :update_details do
      require_atomic?(false)

      accept([
        :title,
        :description,
        :due_at,
        :review_at,
        :notes,
        :metadata,
        :area_id,
        :horizon_id,
        :context_id
      ])

      validate(
        {EBossFolio.Validations.BelongsToWorkspace,
         relationships: [
           area_id: EBossFolio.Area,
           horizon_id: EBossFolio.Horizon,
           context_id: EBossFolio.Context
         ]}
      )

      change({EBossFolio.Changes.AuditAction, event_action: :update})
    end

    update :reposition do
      require_atomic?(false)
      accept([:priority_position])
      change({EBossFolio.Changes.AuditAction, event_action: :update})
    end

    update :activate do
      require_atomic?(false)
      accept([])
      change({EBossFolio.Changes.SetProjectStatus, to: :active})
      change({EBossFolio.Changes.AuditAction, event_action: :transition})
    end

    update :put_on_hold do
      require_atomic?(false)
      accept([])
      change({EBossFolio.Changes.SetProjectStatus, to: :on_hold})
      change({EBossFolio.Changes.AuditAction, event_action: :transition})
    end

    update :complete do
      require_atomic?(false)
      accept([])
      change({EBossFolio.Changes.SetProjectStatus, to: :completed})
      change({EBossFolio.Changes.AuditAction, event_action: :transition})
    end

    update :cancel do
      require_atomic?(false)
      accept([])
      change({EBossFolio.Changes.SetProjectStatus, to: :canceled})
      change({EBossFolio.Changes.AuditAction, event_action: :transition})
    end

    update :archive do
      require_atomic?(false)
      accept([])
      change({EBossFolio.Changes.SetProjectStatus, to: :archived})
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

    attribute :title, :string do
      allow_nil?(false)
      public?(true)
      constraints(min_length: 1, max_length: 255)
    end

    attribute :description, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :status, :atom do
      allow_nil?(false)
      public?(true)
      default(:active)
      constraints(one_of: [:active, :on_hold, :completed, :canceled, :archived])
    end

    attribute :due_at, :utc_datetime_usec do
      allow_nil?(true)
      public?(true)
    end

    attribute :review_at, :utc_datetime_usec do
      allow_nil?(true)
      public?(true)
    end

    attribute :priority_position, :integer do
      allow_nil?(true)
      public?(true)
    end

    attribute :metadata, :map do
      allow_nil?(false)
      public?(true)
      default(%{})
    end

    attribute :notes, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :source, :atom do
      allow_nil?(false)
      public?(true)
      default(:manual)
      constraints(one_of: [:manual, :telegram, :api, :cli, :external_import])
    end

    timestamps()
  end

  relationships do
    belongs_to :workspace, EBoss.Workspaces.Workspace do
      allow_nil?(false)
      public?(true)
    end

    belongs_to :area, EBossFolio.Area do
      allow_nil?(true)
      public?(true)
    end

    belongs_to :horizon, EBossFolio.Horizon do
      allow_nil?(true)
      public?(true)
    end

    belongs_to :context, EBossFolio.Context do
      allow_nil?(true)
      public?(true)
    end

    has_many :tasks, EBossFolio.Task do
      destination_attribute(:project_id)
      public?(true)
    end
  end
end
