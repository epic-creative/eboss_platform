defmodule EBoss.Organizations.Membership do
  use Ash.Resource,
    otp_app: :eboss_tenancy,
    domain: EBoss.Organizations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("memberships")
    repo(EBoss.Repo)
  end

  actions do
    defaults([:read])

    create :create do
      accept([:role])
      argument(:user_id, :uuid, allow_nil?: false)
      argument(:organization_id, :uuid, allow_nil?: false)

      change(set_attribute(:user_id, arg(:user_id)))
      change(set_attribute(:organization_id, arg(:organization_id)))
      change(set_attribute(:joined_at, &DateTime.utc_now/0))
      validate(EBoss.Organizations.Membership.Validations.RestrictOwnerRole)
    end

    create :create_owner_membership do
      accept([])
      argument(:user_id, :uuid, allow_nil?: false)
      argument(:organization_id, :uuid, allow_nil?: false)

      change(set_attribute(:user_id, arg(:user_id)))
      change(set_attribute(:organization_id, arg(:organization_id)))
      change(set_attribute(:role, :owner))
      change(set_attribute(:joined_at, &DateTime.utc_now/0))
    end

    create :create_via_invite do
      accept([:role])
      argument(:user_id, :uuid, allow_nil?: false)
      argument(:organization_id, :uuid, allow_nil?: false)

      change(set_attribute(:user_id, arg(:user_id)))
      change(set_attribute(:organization_id, arg(:organization_id)))
      change(set_attribute(:joined_at, &DateTime.utc_now/0))
      validate(EBoss.Organizations.Membership.Validations.RestrictOwnerRole)
    end

    update :update_role do
      accept([:role])
      require_atomic?(false)
      change(EBoss.Organizations.Membership.Changes.ProtectOwnerMembership)
      validate(EBoss.Organizations.Membership.Validations.RestrictOwnerRole)
    end

    update :set_owner_role do
      accept([])
      require_atomic?(false)
      change(set_attribute(:role, :owner))
    end

    update :demote_owner_role do
      accept([])
      require_atomic?(false)
      change(set_attribute(:role, :member))
    end

    destroy :destroy do
      primary?(true)
      require_atomic?(false)
      change(EBoss.Organizations.Membership.Changes.ProtectOwnerMembership)
    end
  end

  policies do
    bypass action(:create_via_invite) do
      authorize_if(always())
    end

    policy action(:create) do
      authorize_if(EBoss.Organizations.Membership.Checks.CanManageMemberships)
    end

    policy action_type([:update, :destroy]) do
      authorize_if(relates_to_actor_via([:organization, :owner]))

      authorize_if(
        expr(
          exists(
            organization.memberships,
            user_id == ^actor(:id) and role == :admin
          )
        )
      )
    end

    policy action_type(:read) do
      authorize_if(relates_to_actor_via(:user))
      authorize_if(relates_to_actor_via([:organization, :owner]))
      authorize_if(relates_to_actor_via([:organization, :memberships, :user]))
    end

    policy action([:create_owner_membership, :set_owner_role, :demote_owner_role]) do
      forbid_if(always())
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :role, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:owner, :admin, :member])
      default(:member)
    end

    attribute :joined_at, :utc_datetime do
      allow_nil?(false)
      public?(true)
    end

    timestamps()
  end

  relationships do
    belongs_to :user, EBoss.Accounts.User do
      allow_nil?(false)
      public?(true)
    end

    belongs_to :organization, EBoss.Organizations.Organization do
      allow_nil?(false)
      public?(true)
    end
  end

  identities do
    identity(:unique_user_organization, [:user_id, :organization_id])
  end
end
