defmodule EBossWeb.DashboardScope do
  @moduledoc false

  alias EBossWeb.AppScope

  def for_user(user, attrs \\ %{}) do
    owner_type = Map.get(attrs, :owner_type, :user)
    owner_slug = Map.get(attrs, :owner_slug, Map.get(user, :owner_slug, user.username))
    owner_id = Map.get(attrs, :owner_id, Map.get(user, :id, "user-test-id"))
    workspace_slug = Map.get(attrs, :workspace_slug, "operator-workspace")
    workspace_name = Map.get(attrs, :workspace_name, "Operator Workspace")
    dashboard_path = AppScope.dashboard_path(owner_slug, workspace_slug)

    current_workspace = %{
      id: Map.get(attrs, :workspace_id, "workspace-test-id"),
      name: workspace_name,
      slug: workspace_slug,
      full_path: Map.get(attrs, :full_path, full_path(owner_slug, workspace_slug)),
      visibility: Map.get(attrs, :visibility, :private),
      owner_type: owner_type,
      owner_id: owner_id,
      owner_slug: owner_slug,
      owner_display_name:
        Map.get(attrs, :owner_display_name, owner_display_name(owner_type, owner_slug)),
      dashboard_path: dashboard_path
    }

    capabilities = Map.get(attrs, :capabilities, default_capabilities(owner_type))

    %AppScope{
      current_user: user,
      current_workspace: current_workspace,
      owner: %{
        type: owner_type,
        id: owner_id,
        slug: owner_slug,
        display_name: current_workspace.owner_display_name
      },
      capabilities: capabilities,
      apps: Map.get(attrs, :apps, default_apps(current_workspace, capabilities)),
      accessible_workspaces:
        Map.get(attrs, :accessible_workspaces, [Map.put(current_workspace, :current?, true)]),
      dashboard_path: dashboard_path,
      empty?: false
    }
  end

  defp default_apps(%{dashboard_path: dashboard_path}, capabilities) do
    read_folio = Map.get(capabilities, :read_folio, false)
    manage_folio = Map.get(capabilities, :manage_folio, false)

    %{
      "folio" => %{
        key: "folio",
        label: "Folio",
        default_path: "#{dashboard_path}/apps/folio",
        enabled: read_folio,
        capabilities: %{
          read: read_folio,
          manage: manage_folio
        }
      }
    }
  end

  defp default_apps(_workspace, _capabilities), do: %{}

  defp full_path(owner_slug, workspace_slug), do: "#{owner_slug}/#{workspace_slug}"

  defp owner_display_name(:user, owner_slug), do: owner_slug
  defp owner_display_name(:organization, owner_slug), do: owner_slug

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
