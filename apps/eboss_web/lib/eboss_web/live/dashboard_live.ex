defmodule EBossWeb.DashboardLive do
  use EBossWeb, :live_view

  alias EBossWeb.AppScope

  @route_configs %{
    workspace_dashboard: %{page: "dashboard", title: "Overview"},
    workspace_projects: %{page: "projects", title: "Projects"},
    workspace_members: %{page: "members", title: "Members"},
    workspace_access: %{page: "access", title: "Access"},
    workspace_activity: %{page: "activity", title: "Activity"},
    workspace_settings: %{page: "settings", title: "Settings"}
  }

  @impl true
  def mount(params, _session, socket) do
    route_config = route_config(socket.assigns.live_action)

    case resolve_scope(socket.assigns.current_user, route_config, params) do
      {:redirect, dashboard_path} ->
        {:ok, redirect(socket, to: dashboard_path)}

      {:ok, current_scope} ->
        current_path = current_path(current_scope, route_config.page)

        {:ok,
         socket
         |> assign(:current_scope, current_scope)
         |> assign(:current_page, route_config.page)
         |> assign(:current_path, current_path)
         |> assign(:page_title, route_config.title)
         |> assign(:current_user_props, user_props(socket.assigns.current_user))
         |> assign(:current_scope_props, scope_props(current_scope))}
    end
  end

  @impl true
  def render(assigns) do
    assigns = ensure_workspace_assigns(assigns)

    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_user={@current_user}
      current_path={@current_path}
      shell_mode="workspace"
    >
      <.ShellOperatorWorkspaceApp
        currentUser={@current_user_props}
        currentScope={@current_scope_props}
        currentPage={@current_page}
        currentPath={@current_path}
        signOutPath={~p"/logout"}
        csrfToken={Plug.CSRFProtection.get_csrf_token()}
      />
    </Layouts.app>
    """
  end

  defp ensure_workspace_assigns(assigns) do
    current_scope =
      Map.get(assigns, :current_scope) || AppScope.empty(Map.get(assigns, :current_user))

    current_page = Map.get(assigns, :current_page, "dashboard")
    current_path = Map.get(assigns, :current_path) || current_path(current_scope, current_page)

    assigns
    |> assign(:current_scope, current_scope)
    |> assign(:current_page, current_page)
    |> assign(:current_path, current_path)
    |> assign(
      :current_user_props,
      Map.get(assigns, :current_user_props) || user_props(Map.get(assigns, :current_user))
    )
    |> assign(
      :current_scope_props,
      Map.get(assigns, :current_scope_props) || scope_props(current_scope)
    )
  end

  defp route_config(live_action) do
    Map.get(@route_configs, live_action, %{page: "dashboard", title: "Overview"})
  end

  defp resolve_scope(current_user, _route_config, %{
         "owner_slug" => owner_slug,
         "workspace_slug" => workspace_slug
       })
       when is_binary(owner_slug) and is_binary(workspace_slug) do
    AppScope.resolve_workspace(current_user, owner_slug, workspace_slug)
  end

  defp resolve_scope(current_user, _route_config, _params),
    do: {:ok, AppScope.empty(current_user)}

  defp current_path(%AppScope{dashboard_path: dashboard_path}, "dashboard"), do: dashboard_path

  defp current_path(%AppScope{dashboard_path: dashboard_path}, page) do
    "#{dashboard_path}/#{page}"
  end

  defp user_props(nil), do: %{username: "guest", email: ""}

  defp user_props(user) do
    %{
      username: to_string(Map.get(user, :username)),
      email: to_string(Map.get(user, :email))
    }
  end

  defp scope_props(%AppScope{} = scope) do
    %{
      empty: scope.empty?,
      dashboardPath: scope.dashboard_path,
      currentWorkspace: workspace_props(scope.current_workspace),
      owner: owner_props(scope.owner),
      capabilities: capability_props(scope.capabilities),
      accessibleWorkspaces: Enum.map(scope.accessible_workspaces, &workspace_props/1)
    }
  end

  defp workspace_props(nil), do: nil

  defp workspace_props(workspace) do
    %{
      id: workspace.id,
      name: workspace.name,
      slug: workspace.slug,
      fullPath: workspace.full_path,
      visibility: stringify_optional(workspace.visibility),
      ownerType: owner_type_label(workspace.owner_type),
      ownerSlug: workspace.owner_slug,
      ownerDisplayName: workspace.owner_display_name,
      dashboardPath: workspace.dashboard_path,
      current: Map.get(workspace, :current?, false)
    }
  end

  defp owner_props(nil), do: nil

  defp owner_props(owner) do
    %{
      type: owner_type_label(owner.type),
      slug: owner.slug,
      displayName: owner.display_name
    }
  end

  defp capability_props(capabilities) do
    %{
      readWorkspace: Map.get(capabilities, :read_workspace, false),
      manageWorkspace: Map.get(capabilities, :manage_workspace, false),
      readFolio: Map.get(capabilities, :read_folio, false),
      manageFolio: Map.get(capabilities, :manage_folio, false)
    }
  end

  defp owner_type_label(:user), do: "user"
  defp owner_type_label(:organization), do: "organization"
  defp owner_type_label(other), do: to_string(other)

  defp stringify_optional(nil), do: nil
  defp stringify_optional(value), do: to_string(value)
end
