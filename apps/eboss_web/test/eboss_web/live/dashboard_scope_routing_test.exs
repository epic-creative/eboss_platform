defmodule EBossWeb.DashboardScopeRoutingTest do
  use EBossWeb.ConnCase, async: false

  import LiveVue.Test

  test "dashboard compatibility route redirects to the first canonical workspace route", %{
    conn: conn
  } do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "scope-routing@example.com",
        username: "scope-routing-user"
      })

    user_workspace =
      create_user_workspace(context.current_user, %{
        name: "Primary Scope Workspace"
      })

    {_organization, _org_workspace} =
      create_org_workspace(context.current_user, %{
        name: "Routing Org",
        workspace_name: "Secondary Scope Workspace"
      })

    dashboard_path = dashboard_path(context.current_user.owner_slug, user_workspace.slug)

    assert_redirect_path(live(context.conn, ~p"/dashboard"), dashboard_path)
  end

  test "canonical workspace routes render with a populated workspace scope", %{conn: conn} do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "canonical-workspace@example.com",
        username: "canonical-workspace-user"
      })

    workspace =
      create_user_workspace(context.current_user, %{
        name: "Canonical Workspace"
      })

    path = dashboard_path(context.current_user.owner_slug, workspace.slug)

    assert {:ok, view, html} = live(context.conn, path)
    assert html =~ ~s(data-shell-mode="workspace")

    workspace_shell = get_vue(view, name: "ShellOperatorWorkspaceApp")

    assert workspace_shell.component == "ShellOperatorWorkspaceApp"
    assert workspace_shell.ssr == false
    assert workspace_shell.props["currentPage"]["type"] == "workspace"
    assert workspace_shell.props["currentPage"]["surface"] == "dashboard"
    assert workspace_shell.props["currentPath"] == path
    assert workspace_shell.props["currentUser"]["username"] == context.current_user.username
    assert workspace_shell.props["currentScope"]["currentWorkspace"]["slug"] == workspace.slug

    assert workspace_shell.props["currentScope"]["currentWorkspace"]["name"] ==
             "Canonical Workspace"

    assert workspace_shell.props["currentScope"]["dashboardPath"] == path

    current_scope = current_scope(view)
    refute is_nil(current_scope)
    refute current_scope.empty?
    assert current_scope.current_workspace.slug == workspace.slug
    assert current_scope.dashboard_path == path
  end

  test "workspace platform surfaces map to stable currentPage values", %{conn: conn} do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "route-contract@example.com",
        username: "route-contract-user"
      })

    workspace =
      create_user_workspace(context.current_user, %{name: "Contract Workspace"})

    base_path = dashboard_path(context.current_user.owner_slug, workspace.slug)

    platform_routes = [
      {"dashboard", base_path},
      {"members", "#{base_path}/members"},
      {"access", "#{base_path}/access"},
      {"settings", "#{base_path}/settings"}
    ]

    for {expected_page, route_path} <- platform_routes do
      assert {:ok, view, _html} = live(context.conn, route_path)

      workspace_shell = get_vue(view, name: "ShellOperatorWorkspaceApp")

      assert workspace_shell.props["currentPage"]["type"] == "workspace"
      assert workspace_shell.props["currentPage"]["surface"] == expected_page
      assert workspace_shell.props["currentPath"] == route_path
      assert workspace_shell.props["currentScope"]["dashboardPath"] == base_path
      assert workspace_shell.props["currentScope"]["currentWorkspace"]["slug"] == workspace.slug
    end

    for removed_page <- ["projects", "activity"] do
      assert {:ok, view, _html} = live(context.conn, "#{base_path}/#{removed_page}")
      workspace_shell = get_vue(view, name: "ShellOperatorWorkspaceApp")

      assert workspace_shell.props["currentPage"]["type"] == "workspace"
      assert workspace_shell.props["currentPage"]["surface"] == "dashboard"
      assert workspace_shell.props["currentPath"] == base_path
      assert workspace_shell.props["currentScope"]["dashboardPath"] == base_path
      assert workspace_shell.props["currentScope"]["currentWorkspace"]["slug"] == workspace.slug
    end
  end

  test "app-aware workspace routes map to app-specific currentRoute keys", %{conn: conn} do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "app-route-contract@example.com",
        username: "app-route-contract-user"
      })

    workspace =
      create_user_workspace(context.current_user, %{name: "App Route Workspace"})

    base_path = dashboard_path(context.current_user.owner_slug, workspace.slug)
    app_base_path = "#{base_path}/apps/folio"
    app_tasks_surface_path = "#{app_base_path}/tasks"
    app_files_surface_path = "#{app_base_path}/files"

    assert {:ok, view, _html} = live(context.conn, app_base_path)

    workspace_shell = get_vue(view, name: "ShellOperatorWorkspaceApp")

    assert workspace_shell.props["currentPage"]["type"] == "app"
    assert workspace_shell.props["currentPage"]["app_key"] == "folio"
    assert workspace_shell.props["currentPage"]["app_surface"] == nil
    assert workspace_shell.props["currentPage"]["app_path"] == []
    assert workspace_shell.props["currentPath"] == app_base_path
    assert workspace_shell.props["currentScope"]["dashboardPath"] == base_path
    assert workspace_shell.props["currentScope"]["currentWorkspace"]["slug"] == workspace.slug

    assert {:ok, view_with_tasks, _html} = live(context.conn, app_tasks_surface_path)

    workspace_shell_with_tasks = get_vue(view_with_tasks, name: "ShellOperatorWorkspaceApp")

    assert workspace_shell_with_tasks.props["currentPage"]["type"] == "app"
    assert workspace_shell_with_tasks.props["currentPage"]["app_key"] == "folio"
    assert workspace_shell_with_tasks.props["currentPage"]["app_surface"] == "tasks"
    assert workspace_shell_with_tasks.props["currentPage"]["app_path"] == ["tasks"]
    assert workspace_shell_with_tasks.props["currentPath"] == app_tasks_surface_path

    assert {:ok, view_with_surface, _html} = live(context.conn, app_files_surface_path)

    workspace_shell_with_surface = get_vue(view_with_surface, name: "ShellOperatorWorkspaceApp")

    assert workspace_shell_with_surface.props["currentPage"]["type"] == "app"
    assert workspace_shell_with_surface.props["currentPage"]["app_key"] == "folio"
    assert workspace_shell_with_surface.props["currentPage"]["app_surface"] == "files"
    assert workspace_shell_with_surface.props["currentPage"]["app_path"] == ["files"]
    assert workspace_shell_with_surface.props["currentPath"] == app_files_surface_path
  end

  test "chat app routes preserve nested app path context", %{conn: conn} do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "chat-route-contract@example.com",
        username: "chat-route-contract-user"
      })

    workspace =
      create_user_workspace(context.current_user, %{name: "Chat Route Workspace"})

    base_path = dashboard_path(context.current_user.owner_slug, workspace.slug)
    chat_new_path = "#{base_path}/apps/chat/new"
    chat_session_path = "#{base_path}/apps/chat/sessions/session-123"

    assert {:ok, new_view, _html} = live(context.conn, chat_new_path)

    new_shell = get_vue(new_view, name: "ShellOperatorWorkspaceApp")

    assert new_shell.props["currentPage"]["type"] == "app"
    assert new_shell.props["currentPage"]["app_key"] == "chat"
    assert new_shell.props["currentPage"]["app_surface"] == "new"
    assert new_shell.props["currentPage"]["app_path"] == ["new"]
    assert new_shell.props["currentPath"] == chat_new_path
    assert new_shell.props["chatState"]["surface"] == "new"
    assert is_list(new_shell.props["chatState"]["sessions"])
    assert is_list(new_shell.props["chatState"]["models"])

    assert {:ok, session_view, _html} = live(context.conn, chat_session_path)

    session_shell = get_vue(session_view, name: "ShellOperatorWorkspaceApp")

    assert session_shell.props["currentPage"]["type"] == "app"
    assert session_shell.props["currentPage"]["app_key"] == "chat"
    assert session_shell.props["currentPage"]["app_surface"] == "sessions"
    assert session_shell.props["currentPage"]["app_path"] == ["sessions", "session-123"]
    assert session_shell.props["currentPath"] == chat_session_path
    assert session_shell.props["chatState"]["surface"] == "session"
    assert session_shell.props["chatState"]["error"] == "Chat session not found."
  end

  test "app routes without read capability fall back to workspace routing", %{conn: conn} do
    owner = register_user()

    {organization, workspace} =
      create_org_workspace(owner, %{
        name: "App-Aware Fallback Org",
        workspace_name: "App-Aware Fallback Workspace"
      })

    member_context = register_and_log_in_user(%{conn: conn})
    member = member_context.current_user
    create_org_membership(owner, organization, member, :member)

    base_path = dashboard_path(organization.owner_slug, workspace.slug)
    app_base_path = "#{base_path}/apps/folio"
    app_surface_path = "#{app_base_path}/files"

    assert {:ok, view, _html} = live(member_context.conn, app_base_path)

    workspace_shell = get_vue(view, name: "ShellOperatorWorkspaceApp")

    assert workspace_shell.props["currentPage"]["type"] == "workspace"
    assert workspace_shell.props["currentPage"]["surface"] == "dashboard"
    assert workspace_shell.props["currentPath"] == base_path
    assert workspace_shell.props["currentScope"]["dashboardPath"] == base_path
    assert workspace_shell.props["currentScope"]["apps"]["folio"]["enabled"] == false
    assert workspace_shell.props["currentScope"]["apps"]["folio"]["capabilities"]["read"] == false

    assert {:ok, surface_view, _html} = live(member_context.conn, app_surface_path)

    surface_shell = get_vue(surface_view, name: "ShellOperatorWorkspaceApp")

    assert surface_shell.props["currentPage"]["type"] == "workspace"
    assert surface_shell.props["currentPage"]["surface"] == "dashboard"
    assert surface_shell.props["currentPath"] == base_path
  end

  test "unknown app keys in app-aware routing fallback to workspace routing", %{conn: conn} do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "unknown-app-route@example.com",
        username: "unknown-app-route-user"
      })

    workspace =
      create_user_workspace(context.current_user, %{
        name: "Unknown App Route Workspace"
      })

    base_path = dashboard_path(context.current_user.owner_slug, workspace.slug)
    unknown_app_path = "#{base_path}/apps/does-not-exist"

    assert {:ok, view, _html} = live(context.conn, unknown_app_path)

    workspace_shell = get_vue(view, name: "ShellOperatorWorkspaceApp")

    assert workspace_shell.props["currentPage"]["type"] == "workspace"
    assert workspace_shell.props["currentPage"]["surface"] == "dashboard"
    assert workspace_shell.props["currentPath"] == base_path
    assert workspace_shell.props["currentScope"]["dashboardPath"] == base_path
    assert workspace_shell.props["currentScope"]["currentWorkspace"]["slug"] == workspace.slug
  end

  test "invalid workspace routes redirect to the first accessible workspace", %{conn: conn} do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "invalid-route@example.com",
        username: "invalid-route-user"
      })

    workspace =
      create_user_workspace(context.current_user, %{
        name: "Fallback Workspace"
      })

    dashboard_path = dashboard_path(context.current_user.owner_slug, workspace.slug)

    assert_redirect_path(
      live(context.conn, ~p"/invalid-route-user/missing-workspace"),
      dashboard_path
    )
  end

  test "signed-in users with no accessible workspaces see the authenticated empty shell", %{
    conn: conn
  } do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "empty-shell@example.com",
        username: "empty-shell-user"
      })

    assert {:ok, view, html} = live(context.conn, ~p"/dashboard")
    assert html =~ ~s(data-shell-mode="workspace")

    workspace_shell = get_vue(view, name: "ShellOperatorWorkspaceApp")

    assert workspace_shell.props["currentPage"]["type"] == "workspace"
    assert workspace_shell.props["currentPage"]["surface"] == "dashboard"
    assert workspace_shell.props["currentScope"]["empty"] == true
    assert workspace_shell.props["currentScope"]["currentWorkspace"] == nil
    assert workspace_shell.props["currentScope"]["accessibleWorkspaces"] == []

    current_scope = current_scope(view)
    refute is_nil(current_scope)
    assert current_scope.empty?
    assert current_scope.dashboard_path == "/dashboard"
  end

  test "public workspaces do not become the default dashboard for unrelated users", %{conn: conn} do
    owner =
      register_user(%{
        email: "public-default-owner@example.com",
        username: "public-default-owner"
      })

    _public_workspace =
      create_user_workspace(owner, %{
        name: "Public Default Workspace",
        visibility: :public
      })

    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "public-default-outsider@example.com",
        username: "public-default-outsider"
      })

    assert {:ok, view, html} = live(context.conn, ~p"/dashboard")
    assert html =~ ~s(data-shell-mode="workspace")

    workspace_shell = get_vue(view, name: "ShellOperatorWorkspaceApp")

    assert workspace_shell.props["currentScope"]["empty"] == true
    assert workspace_shell.props["currentScope"]["currentWorkspace"] == nil
    assert workspace_shell.props["currentScope"]["accessibleWorkspaces"] == []
  end

  test "signed-in users can still open public workspace routes directly", %{conn: conn} do
    owner =
      register_user(%{
        email: "public-route-owner@example.com",
        username: "public-route-owner"
      })

    public_workspace =
      create_user_workspace(owner, %{
        name: "Public Route Workspace",
        visibility: :public
      })

    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "public-route-outsider@example.com",
        username: "public-route-outsider"
      })

    path = dashboard_path(owner.owner_slug, public_workspace.slug)

    assert {:ok, view, html} = live(context.conn, path)
    assert html =~ ~s(data-shell-mode="workspace")

    workspace_shell = get_vue(view, name: "ShellOperatorWorkspaceApp")

    assert workspace_shell.props["currentScope"]["empty"] == false

    assert workspace_shell.props["currentScope"]["currentWorkspace"]["slug"] ==
             public_workspace.slug

    assert workspace_shell.props["currentScope"]["accessibleWorkspaces"] == []
  end

  test "unknown canonical workspace routes fall back to the authenticated empty shell when none exist",
       %{conn: conn} do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "empty-canonical@example.com",
        username: "empty-canonical-user"
      })

    assert {:ok, view, html} =
             live(context.conn, ~p"/empty-canonical-user/missing-workspace")

    assert html =~ ~s(data-shell-mode="workspace")

    workspace_shell = get_vue(view, name: "ShellOperatorWorkspaceApp")

    assert workspace_shell.props["currentScope"]["empty"] == true
    assert workspace_shell.props["currentScope"]["currentWorkspace"] == nil
  end

  defp current_scope(view) do
    case :sys.get_state(view.pid) do
      %{socket: %{assigns: %{current_scope: current_scope}}} ->
        current_scope

      %{socket: %{socket: %{assigns: %{current_scope: current_scope}}}} ->
        current_scope

      other ->
        raise "unexpected live view state: #{inspect(other)}"
    end
  end

  defp assert_redirect_path({:error, {:redirect, %{to: to}}}, expected_path),
    do: assert(to == expected_path)

  defp assert_redirect_path({:error, {:live_redirect, %{to: to}}}, expected_path),
    do: assert(to == expected_path)
end
