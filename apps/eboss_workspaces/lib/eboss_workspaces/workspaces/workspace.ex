defmodule EBoss.Workspaces.Workspace do
  @moduledoc """
  A workspace owned by a user or organization.
  """

  use Ash.Resource,
    otp_app: :eboss_workspaces,
    domain: EBoss.Workspaces,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshArchival.Resource, AshCloak, AshSlug]

  resource do
    base_filter(expr(is_nil(archived_at)))
  end

  postgres do
    table("workspaces")
    repo(EBoss.Repo)
    base_filter_sql("(archived_at IS NULL)")

    references do
      reference(:organization, ignore?: true)
    end
  end

  archive do
    base_filter?(true)
  end

  cloak do
    vault(EBoss.Vault)
    attributes([:settings])
    decrypt_by_default([:settings])
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:visibility])

      argument :name, :string do
        allow_nil?(false)
      end

      argument :description, :string do
        allow_nil?(true)
      end

      argument :owner_type, :atom do
        allow_nil?(false)
        constraints(one_of: [:user, :organization])
      end

      argument :owner_id, :uuid do
        allow_nil?(false)
      end

      change(set_attribute(:name, arg(:name)))
      change(set_attribute(:description, arg(:description)))
      change(set_attribute(:owner_type, arg(:owner_type)))
      change(set_attribute(:owner_id, arg(:owner_id)))
      change(slugify(:name, into: :slug))
      change(EBoss.Workspaces.Workspace.Changes.EnsureUniqueSlug)
      change(EBoss.Workspaces.Workspace.Changes.ValidateOwner)
    end

    update :update do
      primary?(true)
      accept([:name, :description, :settings])
      require_atomic?(false)

      change(slugify(:name, into: :slug))
      change(EBoss.Workspaces.Workspace.Changes.EnsureUniqueSlug)
    end

    destroy :destroy do
      primary?(true)
      require_atomic?(false)
      change(EBoss.Workspaces.Workspace.Changes.ArchiveMemberships)
    end

    read :by_slug do
      description("Get a workspace by owner and slug")

      argument :owner_type, :atom do
        allow_nil?(false)
        constraints(one_of: [:user, :organization])
      end

      argument :owner_id, :uuid do
        allow_nil?(false)
      end

      argument :slug, :string do
        allow_nil?(false)
      end

      filter(
        expr(
          owner_type == ^arg(:owner_type) and
            owner_id == ^arg(:owner_id) and
            slug == ^arg(:slug)
        )
      )
    end

    read :for_owner do
      description("List all workspaces for a specific owner")

      argument :owner_type, :atom do
        allow_nil?(false)
        constraints(one_of: [:user, :organization])
      end

      argument :owner_id, :uuid do
        allow_nil?(false)
      end

      filter(expr(owner_type == ^arg(:owner_type) and owner_id == ^arg(:owner_id)))
    end
  end

  policies do
    policy action(:create) do
      authorize_if(EBoss.Workspaces.Workspace.Checks.CanCreateWorkspace)
    end

    policy action_type(:read) do
      authorize_if(expr(visibility == :public))
      authorize_if(expr(owner_type == :user and owner_id == ^actor(:id)))
      authorize_if(relates_to_actor_via([:organization, :owner]))
      authorize_if(EBoss.Workspaces.Workspace.Checks.IsOrgMember)
      authorize_if(expr(exists(workspace_memberships, user_id == ^actor(:id))))
    end

    policy action_type([:update, :destroy]) do
      authorize_if(expr(owner_type == :user and owner_id == ^actor(:id)))
      authorize_if(EBoss.Workspaces.Workspace.Checks.IsOrgAdmin)
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :slug, :string do
      allow_nil?(false)
      public?(true)
      constraints(match: ~r/^[a-z0-9\-]+$/)
    end

    attribute :description, :string do
      public?(true)
    end

    attribute :owner_type, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:user, :organization])
    end

    attribute :owner_id, :uuid do
      allow_nil?(false)
      public?(true)
    end

    attribute :settings, :map do
      public?(true)
      default(%{})
    end

    attribute :metadata, :map do
      public?(true)
      default(%{})
    end

    attribute :visibility, :atom do
      allow_nil?(false)
      public?(true)
      default(:private)
      constraints(one_of: [:public, :private])
    end

    timestamps()
  end

  relationships do
    belongs_to :organization, EBoss.Organizations.Organization do
      define_attribute?(false)
      allow_nil?(true)
      attribute_writable?(false)
      source_attribute(:owner_id)
      filter(expr(parent(owner_type) == :organization))
    end

    has_many :workspace_memberships, EBoss.Workspaces.WorkspaceMembership do
      destination_attribute(:workspace_id)
      filter(expr(workspace.owner_type == :user))
    end

    has_many :organization_memberships, EBoss.Organizations.Membership do
      no_attributes?(true)
      filter(expr(organization_id == parent(owner_id)))
    end
  end

  calculations do
    calculate(:full_path, :string, EBoss.Workspaces.Workspace.Calculations.FullPath)
    calculate(:owner, :map, EBoss.Workspaces.Workspace.Calculations.Owner)
  end

  identities do
    identity(:unique_slug_per_owner, [:owner_type, :owner_id, :slug])
  end
end
