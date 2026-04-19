defmodule EBoss.Organizations.Organization do
  use Ash.Resource,
    otp_app: :eboss_tenancy,
    domain: EBoss.Organizations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshArchival.Resource, AshCloak, AshSlug]

  require Ash.Query

  resource do
    base_filter(expr(is_nil(archived_at)))
  end

  postgres do
    table("organizations")
    repo(EBoss.Repo)
    base_filter_sql("(archived_at IS NULL)")
  end

  archive do
    base_filter?(true)
  end

  code_interface do
    define(:create_organization, action: :create)
    define(:update_organization, action: :update)
    define(:admin_update_organization, action: :admin_update)
    define(:transfer_organization_ownership, action: :transfer_ownership, args: [:new_owner_id])
    define(:destroy_organization, action: :destroy)
    define(:get_organization, action: :read, get_by: [:id])
    define(:get_organization_by_owner_slug, action: :by_owner_slug, args: [:owner_slug])
  end

  cloak do
    vault(EBoss.Vault)
    attributes([:settings])
    decrypt_by_default([:settings])
  end

  actions do
    defaults([:read])

    create :create do
      accept([:name, :description, :settings])

      change(relate_actor(:owner))
      change(slugify(:name, into: :owner_slug))
      change(EBoss.Organizations.Organization.Changes.SyncOwnerMembership)
      validate(EBoss.Organizations.Organization.Validations.ValidateSlug)

      change(
        {EBoss.OwnerSlugs.Changes.ReserveOwnerSlug, owner_type: :organization, field: :owner_slug}
      )
    end

    update :update do
      accept([:name, :description, :settings])
      require_atomic?(false)
      validate(EBoss.Organizations.Organization.Validations.ValidateSlug)
      change(EBoss.Organizations.Organization.Changes.SyncWorkspaceOwnerSnapshots)
    end

    update :transfer_ownership do
      accept([])
      require_atomic?(false)
      argument(:new_owner_id, :uuid, allow_nil?: false)
      change(set_attribute(:owner_id, arg(:new_owner_id)))
      change(EBoss.Organizations.Organization.Changes.SyncOwnerMembership)
    end

    destroy :destroy do
      require_atomic?(false)
      change(EBoss.Organizations.Organization.Changes.ArchiveDependents)
    end

    read :admin_index do
      pagination(offset?: true, keyset?: true, required?: false)

      prepare(fn query, _context ->
        query
      end)
    end

    create :admin_create do
      accept([:name, :description, :settings])
      argument(:owner_id, :uuid, allow_nil?: false)
      change(set_attribute(:owner_id, arg(:owner_id)))
      change(slugify(:name, into: :owner_slug))
      change(EBoss.Organizations.Organization.Changes.SyncOwnerMembership)
      validate(EBoss.Organizations.Organization.Validations.ValidateSlug)

      change(
        {EBoss.OwnerSlugs.Changes.ReserveOwnerSlug, owner_type: :organization, field: :owner_slug}
      )
    end

    update :admin_update do
      accept([:name, :description, :settings])
      argument(:owner_id, :uuid, allow_nil?: true)

      change(manage_relationship(:owner_id, :owner, type: :append_and_remove),
        where: [present(:owner_id)]
      )

      require_atomic?(false)
      change(EBoss.Organizations.Organization.Changes.SyncOwnerMembership)
      validate(EBoss.Organizations.Organization.Validations.ValidateSlug)
      change(EBoss.Organizations.Organization.Changes.SyncWorkspaceOwnerSnapshots)
    end

    read :by_owner_slug do
      get?(true)

      argument :owner_slug, :string do
        allow_nil?(false)
      end

      prepare(fn query, _context ->
        owner_slug_arg = Ash.Query.get_argument(query, :owner_slug)
        normalized = if owner_slug_arg, do: String.downcase(owner_slug_arg), else: ""
        Ash.Query.filter(query, expr(owner_slug == ^normalized))
      end)
    end
  end

  policies do
    bypass action([:admin_index, :admin_create, :admin_update]) do
      authorize_if(expr(^actor(:role) == :admin))
    end

    policy action([:admin_index, :admin_create, :admin_update]) do
      access_type(:strict)
      forbid_if(expr(^actor(:role) != :admin))
    end

    policy action_type(:read) do
      authorize_if(relates_to_actor_via(:owner))
      authorize_if(relates_to_actor_via([:memberships, :user]))
    end

    policy action_type(:create) do
      authorize_if(actor_present())
    end

    policy action_type([:update, :destroy]) do
      authorize_if(relates_to_actor_via(:owner))
    end

    policy action(:transfer_ownership) do
      authorize_if(relates_to_actor_via(:owner))
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      public?(true)
      constraints(min_length: 1, max_length: 255)
    end

    attribute :owner_slug, :string do
      allow_nil?(false)
      public?(true)
      constraints(match: ~r/^[a-z0-9\-]+$/)
    end

    attribute :description, :string do
      public?(true)
      constraints(max_length: 1000)
    end

    attribute :settings, :map do
      public?(true)
      default(%{})
    end

    timestamps()
  end

  relationships do
    belongs_to :owner, EBoss.Accounts.User do
      allow_nil?(false)
      public?(true)
      attribute_writable?(false)
    end

    has_many :memberships, EBoss.Organizations.Membership do
      public?(true)
    end

    has_many :invitations, EBoss.Organizations.Invitation do
      public?(true)
    end

    many_to_many :members, EBoss.Accounts.User do
      through(EBoss.Organizations.Membership)
      join_relationship(:memberships)
      source_attribute_on_join_resource(:organization_id)
      destination_attribute_on_join_resource(:user_id)
      public?(true)
    end
  end

  identities do
    identity(:unique_owner_slug, [:owner_slug])
  end
end
