defmodule EBossWeb.DashboardScope do
  @moduledoc false

  alias EBossWeb.AppScope

  def for_user(user, attrs \\ %{}) do
    owner_type = Map.get(attrs, :owner_type, :user)
    owner_handle = Map.get(attrs, :owner_handle, user.username)
    owner_id = Map.get(attrs, :owner_id, Map.get(user, :id, "user-test-id"))
    workspace_slug = Map.get(attrs, :workspace_slug, "operator-workspace")
    workspace_name = Map.get(attrs, :workspace_name, "Operator Workspace")
    dashboard_path = AppScope.dashboard_path(owner_type, owner_handle, workspace_slug)

    current_workspace = %{
      id: Map.get(attrs, :workspace_id, "workspace-test-id"),
      name: workspace_name,
      slug: workspace_slug,
      full_path: Map.get(attrs, :full_path, full_path(owner_type, owner_handle, workspace_slug)),
      visibility: Map.get(attrs, :visibility, :private),
      owner_type: owner_type,
      owner_id: owner_id,
      owner_handle: owner_handle,
      owner_display_name:
        Map.get(attrs, :owner_display_name, owner_display_name(owner_type, owner_handle)),
      dashboard_path: dashboard_path
    }

    %AppScope{
      current_user: user,
      current_workspace: current_workspace,
      owner: %{
        type: owner_type,
        id: owner_id,
        handle: owner_handle,
        display_name: current_workspace.owner_display_name
      },
      capabilities: Map.get(attrs, :capabilities, default_capabilities(owner_type)),
      accessible_workspaces:
        Map.get(attrs, :accessible_workspaces, [Map.put(current_workspace, :current?, true)]),
      dashboard_path: dashboard_path,
      empty?: false
    }
  end

  defp full_path(:user, owner_handle, workspace_slug), do: "@#{owner_handle}/#{workspace_slug}"

  defp full_path(:organization, owner_handle, workspace_slug),
    do: "#{owner_handle}/#{workspace_slug}"

  defp owner_display_name(:user, owner_handle), do: "@#{owner_handle}"
  defp owner_display_name(:organization, owner_handle), do: owner_handle

  defp default_capabilities(:user) do
    %{
      read_workspace: true,
      manage_workspace: true,
      read_folio: true,
      manage_folio: true
    }
  end

  defp default_capabilities(:organization) do
    %{
      read_workspace: true,
      manage_workspace: true,
      read_folio: true,
      manage_folio: true
    }
  end
end
