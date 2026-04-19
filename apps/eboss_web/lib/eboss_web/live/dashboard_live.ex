defmodule EBossWeb.DashboardLive do
  use EBossWeb, :live_view

  alias EBossWeb.AppScope

  @workspace_routes %{
    "dashboard" => %{surface: "dashboard", title: "Overview"},
    "members" => %{surface: "members", title: "Members"},
    "access" => %{surface: "access", title: "Access"},
    "settings" => %{surface: "settings", title: "Settings"}
  }
  @default_workspace_page "dashboard"

  @impl true
  def mount(params, _session, socket) do
    case resolve_scope(socket.assigns.current_user, params) do
      {:redirect, dashboard_path} ->
        {:ok, redirect(socket, to: dashboard_path)}

      {:ok, current_scope} ->
        route = resolve_current_route(current_scope, socket.assigns.live_action, params)
        current_path = route.current_path

        {:ok,
         socket
         |> assign(:current_scope, current_scope)
         |> assign(:current_navigation, route)
         |> assign(:current_path, current_path)
         |> assign(:page_title, route.title)
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
        currentPage={@current_navigation}
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

    current_navigation =
      Map.get(assigns, :current_navigation, %{
        type: "workspace",
        surface: @default_workspace_page,
        app_key: nil,
        app_surface: nil,
        title: "Overview",
        current_path: current_path(current_scope, @default_workspace_page)
      })

    current_path = Map.get(assigns, :current_path) || Map.get(current_navigation, :current_path)

    assigns
    |> assign(:current_scope, current_scope)
    |> assign(:current_navigation, current_navigation)
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

  defp resolve_current_route(current_scope, :workspace_root, _params) do
    resolve_workspace_route(current_scope, @default_workspace_page)
  end

  defp resolve_current_route(current_scope, :workspace_surface, %{"workspace_surface" => surface}) do
    resolve_workspace_route(current_scope, surface)
  end

  defp resolve_current_route(current_scope, :workspace_surface, _params),
    do: resolve_workspace_route(current_scope, @default_workspace_page)

  defp resolve_current_route(current_scope, :workspace_app, %{"app_key" => app_key} = params) do
    resolve_app_route(current_scope, app_key, Map.get(params, "app_surface"))
  end

  defp resolve_current_route(current_scope, _live_action, _params) do
    resolve_workspace_route(current_scope, @default_workspace_page)
  end

  defp resolve_workspace_route(%AppScope{} = current_scope, page)
       when is_binary(page) do
    resolved = Map.get(@workspace_routes, page, @workspace_routes[@default_workspace_page])

    %{
      type: "workspace",
      surface: resolved.surface,
      title: resolved.title,
      app_key: nil,
      app_surface: nil,
      current_path: workspace_path(current_scope, resolved.surface)
    }
  end

  defp resolve_app_route(%AppScope{apps: apps} = current_scope, app_key, app_surface)
       when is_binary(app_key) do
    case fetch_map_field(apps, app_key) do
      app when is_map(app) ->
        if fetch_map_field(app, :enabled, false) do
          app_label = fetch_map_field(app, :label, to_string(app_key))
          normalized_surface = normalize_app_surface(app_surface)
          app_key_string = to_string(app_key)

          %{
            type: "app",
            app_key: app_key_string,
            app_surface: normalized_surface,
            title: app_title(app_label, normalized_surface),
            current_path: app_path(current_scope, app, app_key_string, normalized_surface)
          }
        else
          resolve_workspace_route(current_scope, @default_workspace_page)
        end

      _ ->
        resolve_workspace_route(current_scope, @default_workspace_page)
    end
  end

  defp resolve_app_route(%AppScope{} = current_scope, _app_key, _app_surface) do
    resolve_workspace_route(current_scope, @default_workspace_page)
  end

  defp resolve_scope(current_user, %{
         "owner_slug" => owner_slug,
         "workspace_slug" => workspace_slug
       })
       when is_binary(owner_slug) and is_binary(workspace_slug) do
    AppScope.resolve_workspace(current_user, owner_slug, workspace_slug)
  end

  defp resolve_scope(current_user, _params),
    do: {:ok, AppScope.empty(current_user)}

  defp current_path(%AppScope{dashboard_path: dashboard_path}, "dashboard"), do: dashboard_path

  defp current_path(%AppScope{dashboard_path: dashboard_path}, page) when is_binary(page) do
    "#{dashboard_path}/#{page}"
  end

  defp workspace_path(%AppScope{dashboard_path: dashboard_path}, "dashboard"), do: dashboard_path

  defp workspace_path(%AppScope{dashboard_path: dashboard_path}, page)
       when is_binary(page) do
    "#{dashboard_path}/#{page}"
  end

  defp app_path(%AppScope{dashboard_path: dashboard_path}, app, app_key, nil) do
    fetch_map_field(app, :default_path, "#{dashboard_path}/apps/#{app_key}")
  end

  defp app_path(%AppScope{dashboard_path: dashboard_path}, app, app_key, app_surface)
       when is_binary(app_surface) do
    base_path = fetch_map_field(app, :default_path, "#{dashboard_path}/apps/#{app_key}")
    "#{base_path}/#{app_surface}"
  end

  defp app_title(app_label, nil), do: app_label

  defp app_title(app_label, app_surface) do
    "#{app_label} · #{String.capitalize(app_surface)}"
  end

  defp normalize_app_surface(surface) when is_binary(surface) and byte_size(surface) > 0,
    do: surface

  defp normalize_app_surface(_), do: nil

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
      accessibleWorkspaces: Enum.map(scope.accessible_workspaces, &workspace_props/1),
      apps: app_registry_props(scope.apps)
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

  defp app_registry_props(apps) when is_map(apps) do
    apps
    |> Enum.into(%{}, fn {app_key, app} ->
      {to_string(app_key), app_props(app)}
    end)
  end

  defp app_registry_props(_), do: %{}

  defp app_props(app) do
    capabilities = fetch_map_field(app, :capabilities, %{})

    %{
      key: fetch_map_field(app, :key),
      label: fetch_map_field(app, :label),
      defaultPath: fetch_map_field(app, :default_path),
      enabled: fetch_map_field(app, :enabled, false),
      capabilities: %{
        read: fetch_map_field(capabilities, :read, false),
        manage: fetch_map_field(capabilities, :manage, false)
      }
    }
  end

  defp fetch_map_field(map, key, default \\ nil)

  defp fetch_map_field(map, key, default) when is_map(map) do
    Map.get(map, key, Map.get(map, to_string(key), default))
  end

  defp fetch_map_field(_, _key, default), do: default

  defp owner_type_label(:user), do: "user"
  defp owner_type_label(:organization), do: "organization"
  defp owner_type_label(other), do: to_string(other)

  defp stringify_optional(nil), do: nil
  defp stringify_optional(value), do: to_string(value)
end
