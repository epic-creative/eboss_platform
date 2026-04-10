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
    assert html =~ ~s(data-dashboard-nav-item="dashboard")
    assert html =~ ~s(data-dashboard-contract="page-header")
    assert html =~ ~s(data-dashboard-contract="page-content")
    assert html =~ "EBoss dashboard"
    assert html =~ "Operator workspace"
    assert html =~ "@render_user"
    assert html =~ "The main dashboard now lives inside the shared operator shell"
  end
end
