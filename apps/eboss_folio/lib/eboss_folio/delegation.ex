defmodule EBossFolio.Delegation do
  use Ash.Resource,
    otp_app: :eboss_folio,
    domain: EBossFolio,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("folio_delegations")
    repo(EBoss.Repo)
  end

  actions do
    read :read do
      primary?(true)
    end

    create :delegate do
      primary?(true)

      accept([
        :workspace_id,
        :task_id,
        :contact_id,
        :delegated_summary,
        :quality_expectations,
        :deadline_expectations_at,
        :follow_up_at
      ])

      validate(
        {EBossFolio.Validations.BelongsToWorkspace,
         relationships: [
           task_id: EBossFolio.Task,
           contact_id: EBossFolio.Contact
         ]}
      )

      validate(EBossFolio.Validations.SingleActiveDelegation)

      change({EBossFolio.Changes.AuditAction, event_action: :create})
    end

    update :complete do
      require_atomic?(false)
      accept([])
      change(set_attribute(:status, :completed))
      change({EBossFolio.Changes.AuditAction, event_action: :transition})
    end

    update :cancel do
      require_atomic?(false)
      accept([])
      change(set_attribute(:status, :canceled))
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

    attribute :delegated_at, :utc_datetime_usec do
      allow_nil?(false)
      public?(true)
      default(&DateTime.utc_now/0)
    end

    attribute :delegated_summary, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :quality_expectations, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :deadline_expectations_at, :utc_datetime_usec do
      allow_nil?(true)
      public?(true)
    end

    attribute :follow_up_at, :utc_datetime_usec do
      allow_nil?(true)
      public?(true)
    end

    attribute :status, :atom do
      allow_nil?(false)
      public?(true)
      default(:active)
      constraints(one_of: [:active, :completed, :canceled])
    end

    timestamps()
  end

  relationships do
    belongs_to :workspace, EBoss.Workspaces.Workspace do
      allow_nil?(false)
      public?(true)
    end

    belongs_to :task, EBossFolio.Task do
      allow_nil?(false)
      public?(true)
    end

    belongs_to :contact, EBossFolio.Contact do
      allow_nil?(false)
      public?(true)
    end
  end
end
