defmodule EBoss.Workspaces.WorkspaceMembership do
  @moduledoc """
  Membership in a user-owned workspace.
  """

  use Ash.Resource,
    otp_app: :eboss_workspaces,
    domain: EBoss.Workspaces,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshArchival.Resource]

  resource do
    base_filter(expr(is_nil(archived_at)))
  end

  postgres do
    table("workspace_memberships")
    repo(EBoss.Repo)
    base_filter_sql("(archived_at IS NULL)")
  end

  archive do
    base_filter?(true)
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:workspace_id, :user_id, :role])

      change(set_attribute(:joined_at, &DateTime.utc_now/0))

      change(fn changeset, _ctx ->
        workspace_id = Ash.Changeset.get_attribute(changeset, :workspace_id)

        case Ash.get(EBoss.Workspaces.Workspace, workspace_id,
               domain: EBoss.Workspaces,
               authorize?: false
             ) do
          {:ok, %{owner_type: :organization}} ->
            Ash.Changeset.add_error(changeset,
              field: :workspace_id,
              message: "Organization-owned workspaces use organization memberships"
            )

          {:ok, %{owner_type: :user}} ->
            changeset

          {:error, _error} ->
            Ash.Changeset.add_error(changeset,
              field: :workspace_id,
              message: "Workspace not found"
            )

          _ ->
            changeset
        end
      end)
    end

    update :update do
      primary?(true)
      accept([:role])
    end

    destroy :destroy do
      primary?(true)
    end
  end

  policies do
    policy action(:read) do
      authorize_if(relates_to_actor_via(:user))
      authorize_if(expr(workspace.owner_type == :user and workspace.owner_id == ^actor(:id)))
    end

    policy action(:create) do
      authorize_if(EBoss.Workspaces.WorkspaceMembership.Checks.ActorOwnsUserWorkspace)
    end

    policy action([:update, :destroy]) do
      authorize_if(expr(workspace.owner_type == :user and workspace.owner_id == ^actor(:id)))
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

    attribute :joined_at, :utc_datetime_usec do
      allow_nil?(false)
      public?(true)
    end

    timestamps()
  end

  relationships do
    belongs_to :workspace, EBoss.Workspaces.Workspace do
      allow_nil?(false)
      public?(true)
    end

    belongs_to :user, EBoss.Accounts.User do
      allow_nil?(false)
      public?(true)
    end
  end

  identities do
    identity(:unique_membership, [:workspace_id, :user_id])
  end
end
