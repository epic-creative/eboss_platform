defmodule EBossWeb.DashboardLiveRenderTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias EBossWeb.BrowserTestContracts

  @endpoint EBossWeb.Endpoint

  setup do
    for app <- [:plug_crypto, :phoenix, :phoenix_html, :phoenix_live_view, :gettext] do
      {:ok, _} = Application.ensure_all_started(app)
    end

    if is_nil(Process.whereis(EBossWeb.Endpoint)) do
      start_supervised!(EBossWeb.Endpoint)
    end

    :ok
  end

  test "dashboard live markup exposes the shell scaffold contract" do
    html =
      render_component(&EBossWeb.DashboardLive.render/1, %{
        flash: %{},
        current_scope: nil,
        current_user: %{username: "render_user", email: "render@example.com"}
      })

    assert html =~ ~s(data-testid="#{BrowserTestContracts.dashboard_shell()}")
    assert html =~ ~s(aria-label="#{BrowserTestContracts.dashboard_navigation_label()}")
    assert html =~ ~s(data-dashboard-shell-sidebar)
    assert html =~ ~s(data-dashboard-shell-main)
    assert html =~ ~s(data-dashboard-shell-header)
    assert html =~ ~s(data-dashboard-shell-body)
    assert html =~ ~s(data-dashboard-nav-group="primary-routes")
    assert html =~ ~s(data-dashboard-nav-group="upcoming-surfaces")
    assert html =~ ~s(data-dashboard-nav-item="dashboard")
    assert html =~ ~s(data-dashboard-nav-item="workspaces")
    assert html =~ ~s(data-dashboard-nav-item="folio")
    assert html =~ ~s(data-dashboard-secondary-nav)
    assert html =~ ~s(data-dashboard-contract="page-header")
    assert html =~ ~s(data-dashboard-contract="page-content")
    assert html =~ ~s(data-dashboard-section="launchpad")
    assert html =~ ~s(data-dashboard-section="structure")
    assert html =~ ~s(data-dashboard-section="states")
    assert html =~ ~s(data-dashboard-utility-strip)
    assert html =~ ~s(data-dashboard-utility-item="primary-lane")
    assert html =~ ~s(data-dashboard-quick-actions)
    assert html =~ ~s(data-dashboard-quick-action="open-launch-surface")
    assert html =~ ~s(data-dashboard-panel-group="stack")
    assert html =~ ~s(data-dashboard-state="empty")
    assert html =~ ~s(data-dashboard-state="loading")
    assert html =~ ~s(data-dashboard-state="error")
    assert html =~ "EBoss dashboard"
    assert html =~ "Operator workspace"
    assert html =~ "@render_user"
    assert html =~ "The main dashboard now lives inside the shared operator shell"
    assert html =~ "Primary routes"
    assert html =~ "Upcoming surfaces"
    assert html =~ "Current route"
    assert html =~ "Planned surface"
    assert html =~ "Secondary cues"
    assert html =~ "Command surface"
    assert html =~ "Quick actions"
    assert html =~ "Panel groupings stay systematic instead of page-specific."
    assert html =~ "Empty, loading, and error states stay in the dashboard language."
    assert html =~ "The latest sync did not complete."
    assert html =~ "Launch surface"
    assert html =~ "Panel grouping"

    assert Regex.scan(~r/data-dashboard-header/, html) |> length() == 4
    assert Regex.scan(~r/data-dashboard-action-bar/, html) |> length() == 4
    assert Regex.scan(~r/data-dashboard-nav-group=/, html) |> length() == 2
    assert Regex.scan(~r/aria-current="page"/, html) |> length() == 1
    assert Regex.scan(~r/data-interactive="false"/, html) |> length() == 2
    assert Regex.scan(~r/data-dashboard-utility-item=/, html) |> length() == 4
    assert Regex.scan(~r/data-dashboard-quick-action=/, html) |> length() == 3
  end
end
