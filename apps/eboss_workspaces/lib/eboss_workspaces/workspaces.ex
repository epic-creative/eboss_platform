defmodule EBoss.Workspaces do
  @moduledoc """
  The Workspaces domain for managing user and organization workspaces.
  """

  use Ash.Domain, otp_app: :eboss_workspaces, extensions: [AshJsonApi.Domain]

  json_api do
    routes do
      base_route "/workspaces", EBoss.Workspaces.Workspace do
        index :read
        get(:read)
      end

      base_route "/users/:owner_handle/workspaces", EBoss.Workspaces.Workspace do
        get :by_user_handle_and_slug do
          route("/:slug")
          name "get_user_workspace_by_slug"
        end
      end

      base_route "/orgs/:owner_handle/workspaces", EBoss.Workspaces.Workspace do
        get :by_org_handle_and_slug do
          route("/:slug")
          name "get_org_workspace_by_slug"
        end
      end
    end
  end

  resources do
    resource(EBoss.Workspaces.Workspace)
    resource(EBoss.Workspaces.WorkspaceMembership)
  end

  alias EBoss.Workspaces.{Workspace, WorkspaceMembership}
  defdelegate list_workspaces(opts \\ []), to: Workspace
  defdelegate list_workspaces!(opts \\ []), to: Workspace
  defdelegate create_workspace(attrs, opts \\ []), to: Workspace
  defdelegate create_workspace!(attrs, opts \\ []), to: Workspace
  defdelegate update_workspace(workspace, attrs, opts \\ []), to: Workspace
  defdelegate update_workspace!(workspace, attrs, opts \\ []), to: Workspace
  defdelegate destroy_workspace(workspace, opts \\ []), to: Workspace
  defdelegate destroy_workspace!(workspace, opts \\ []), to: Workspace
  defdelegate get_workspace(id, opts \\ []), to: Workspace
  defdelegate get_workspace!(id, opts \\ []), to: Workspace

  defdelegate get_workspace_by_owner_and_slug(owner_type, owner_id, slug, opts \\ []),
    to: Workspace

  defdelegate get_workspace_by_owner_and_slug!(owner_type, owner_id, slug, opts \\ []),
    to: Workspace

  defdelegate get_workspace_by_owner_handle_and_slug(owner_type, owner_handle, slug, opts \\ []),
    to: Workspace

  defdelegate get_workspace_by_owner_handle_and_slug!(
                owner_type,
                owner_handle,
                slug,
                opts \\ []
              ),
              to: Workspace

  defdelegate list_workspaces_for_owner(owner_type, owner_id, opts \\ []), to: Workspace
  defdelegate list_workspaces_for_owner!(owner_type, owner_id, opts \\ []), to: Workspace
  defdelegate create_workspace_membership(attrs, opts \\ []), to: WorkspaceMembership
  defdelegate create_workspace_membership!(attrs, opts \\ []), to: WorkspaceMembership
end
