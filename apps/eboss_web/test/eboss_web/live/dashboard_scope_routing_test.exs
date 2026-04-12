defmodule EBossWeb.DashboardScopeRoutingTest do
  use EBossWeb.ConnCase, async: false

  test "dashboard compatibility route redirects to the first canonical workspace route", %{
    conn: conn
  } do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "scope-routing@example.com",
        username: "scope_routing_user"
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

    dashboard_path = dashboard_path(:user, context.current_user.username, user_workspace.slug)

    assert_redirect_path(live(context.conn, ~p"/dashboard"), dashboard_path)
  end

  test "canonical workspace routes render with a populated workspace scope", %{conn: conn} do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "canonical-workspace@example.com",
        username: "canonical_workspace_user"
      })

    workspace =
      create_user_workspace(context.current_user, %{
        name: "Canonical Workspace"
      })

    path = dashboard_path(:user, context.current_user.username, workspace.slug)

    assert {:ok, view, html} = live(context.conn, path)
    assert html =~ "Canonical Workspace"
    assert html =~ "@canonical_workspace_user/#{workspace.slug}"
    assert html =~ ~s(data-dashboard-workspace-link="#{workspace.slug}")

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
        username: "invalid_route_user"
      })

    workspace =
      create_user_workspace(context.current_user, %{
        name: "Fallback Workspace"
      })

    dashboard_path = dashboard_path(:user, context.current_user.username, workspace.slug)

    assert_redirect_path(
      live(context.conn, ~p"/users/invalid-route-user/missing-workspace/dashboard"),
      dashboard_path
    )
  end

  test "signed-in users with no accessible workspaces see the authenticated empty shell", %{
    conn: conn
  } do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "empty-shell@example.com",
        username: "empty_shell_user"
      })

    assert {:ok, view, html} = live(context.conn, ~p"/dashboard")
    assert html =~ "No accessible workspaces yet."
    assert html =~ "Create or join a workspace to continue."
    assert html =~ "No accessible workspace"

    current_scope = current_scope(view)
    refute is_nil(current_scope)
    assert current_scope.empty?
    assert current_scope.dashboard_path == "/dashboard"
  end

  test "unknown canonical workspace routes fall back to the authenticated empty shell when none exist",
       %{conn: conn} do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "empty-canonical@example.com",
        username: "empty_canonical_user"
      })

    assert {:ok, _view, html} =
             live(context.conn, ~p"/users/empty_canonical_user/missing-workspace/dashboard")

    assert html =~ "No accessible workspaces yet."
    assert html =~ "Create or join a workspace to continue."
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
