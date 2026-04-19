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
    assert workspace_shell.props["currentPage"] == "dashboard"
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

    assert workspace_shell.props["currentPage"] == "dashboard"
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
