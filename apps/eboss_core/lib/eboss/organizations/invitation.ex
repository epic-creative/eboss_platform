defmodule EBoss.Organizations.Invitation do
  use Ash.Resource,
    otp_app: :eboss_core,
    domain: EBoss.Organizations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "invitations"
    repo EBoss.Repo

    skip_unique_indexes [:unique_pending_invitation]
  end

  actions do
    defaults [:read]

    create :create do
      accept [:email, :role]
      argument :organization_id, :uuid, allow_nil?: false
      argument :invited_by_id, :uuid, allow_nil?: false

      change set_attribute(:organization_id, arg(:organization_id))
      change set_attribute(:invited_by_id, arg(:invited_by_id))
      change {EBoss.Organizations.Invitation.Changes.ValidateInvitationPermissions, []}
      change {EBoss.Organizations.Invitation.Changes.GenerateToken, []}
      change {EBoss.Organizations.Invitation.Changes.SetExpiration, []}

      validate {EBoss.Organizations.Invitation.Validations.PreventDuplicatePendingInvitation, []}
    end

    update :accept do
      accept []
      require_atomic? false
      argument :token, :string, allow_nil?: false
      argument :accepting_user_id, :uuid, allow_nil?: false

      change {EBoss.Organizations.Invitation.Changes.AcceptInvitation, []}
    end

    update :resend do
      accept []
      require_atomic? false
      change {EBoss.Organizations.Invitation.Changes.GenerateToken, []}
      change {EBoss.Organizations.Invitation.Changes.SetExpiration, []}
    end

    destroy :destroy

    read :by_token do
      get? true
      argument :token, :string, allow_nil?: false

      filter expr(
               token == ^arg(:token) and is_nil(accepted_at) and expires_at > ^DateTime.utc_now()
             )
    end
  end

  policies do
    bypass action(:accept) do
      authorize_if always()
    end

    bypass action(:by_token) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if EBoss.Organizations.Invitation.Checks.CanCreateInvitation
    end

    policy action_type([:read, :update, :destroy]) do
      authorize_if relates_to_actor_via([:organization, :owner])

      authorize_if expr(
                     organization.memberships.user_id == ^actor(:id) and
                       organization.memberships.role == :admin
                   )
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true

      constraints max_length: 255,
                  match: ~r/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
    end

    attribute :role, :atom do
      allow_nil? false
      public? true
      constraints one_of: [:admin, :member]
      default :member
    end

    attribute :token, :string do
      allow_nil? false
      public? true
      sensitive? true
    end

    attribute :expires_at, :utc_datetime do
      allow_nil? false
      public? true
    end

    attribute :accepted_at, :utc_datetime do
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :organization, EBoss.Organizations.Organization do
      allow_nil? false
      public? true
    end

    belongs_to :invited_by, EBoss.Accounts.User do
      allow_nil? false
      public? true
    end
  end

  identities do
    identity :unique_token, [:token]

    identity :unique_pending_invitation, [:email, :organization_id] do
      where expr(is_nil(accepted_at) and expires_at > ^DateTime.utc_now())
    end
  end
end
