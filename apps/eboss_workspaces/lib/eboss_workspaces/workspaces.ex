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
    end
  end

  resources do
    resource(EBoss.Workspaces.Workspace)
    resource(EBoss.Workspaces.WorkspaceMembership)
  end

  alias EBoss.Workspaces.{RouteAccess, Workspace, WorkspaceMembership}
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

  defdelegate list_workspaces_for_owner(owner_type, owner_id, opts \\ []), to: Workspace
  defdelegate list_workspaces_for_owner!(owner_type, owner_id, opts \\ []), to: Workspace
  defdelegate create_workspace_membership(attrs, opts \\ []), to: WorkspaceMembership
  defdelegate create_workspace_membership!(attrs, opts \\ []), to: WorkspaceMembership

  defdelegate resolve_workspace_route(actor, owner_slug, slug, accessible_workspaces \\ []),
    to: RouteAccess,
    as: :resolve
end
