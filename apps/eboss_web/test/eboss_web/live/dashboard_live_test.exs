defmodule EBossWeb.DashboardLiveTest do
  use EBossWeb.ConnCase, async: false

  alias EBossWeb.BrowserTestContracts

  test "dashboard route renders the authenticated shell scaffold", context do
    %{conn: conn, current_user: current_user} = register_and_log_in_user(context)

    assert {:ok, view, _html} = live(conn, ~p"/dashboard")

    assert has_element?(view, ~s([data-testid="#{BrowserTestContracts.dashboard_shell()}"]))

    assert has_element?(
             view,
             ~s(nav[aria-label="#{BrowserTestContracts.dashboard_navigation_label()}"])
           )

    assert has_element?(view, "[data-dashboard-shell-sidebar]")
    assert has_element?(view, "[data-dashboard-shell-main]")
    assert has_element?(view, "[data-dashboard-shell-header]")
    assert has_element?(view, "[data-dashboard-shell-body]")
    assert has_element?(view, "[data-dashboard-chrome='identity']")
    assert has_element?(view, "[data-dashboard-chrome='context']")
    assert has_element?(view, ~s([data-dashboard-nav-item="dashboard"][data-active="true"]))
    assert has_element?(view, "[data-dashboard-contract='page-header']")
    assert has_element?(view, "[data-dashboard-contract='page-content']")
    assert has_element?(view, ".ui-shell[data-shell-mode='product']")
    refute has_element?(view, "[data-public-shell-nav]")

    assert has_element?(
             view,
             "[data-dashboard-chrome='context'] .ui-text-title",
             "@#{current_user.username}"
           )
  end

  test "dashboard route redirects anonymous visitors to sign-in", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/dashboard")
  end
end
