defmodule EBossWeb.DashboardLiveTest do
  use ExUnit.Case, async: false
  use EBossWeb, :verified_routes

  import Phoenix.ConnTest
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

  test "dashboard live render keeps the authenticated shell contract on the main surface" do
    current_user = %{username: "shell_user", email: "shell@example.com"}

    html =
      render_component(&EBossWeb.DashboardLive.render/1, %{
        flash: %{},
        current_scope: nil,
        current_user: current_user
      })

    assert html =~ ~s(data-testid="#{BrowserTestContracts.dashboard_shell()}")
    assert html =~ ~s(aria-label="#{BrowserTestContracts.dashboard_navigation_label()}")
    assert html =~ ~s(data-dashboard-shell-sidebar)
    assert html =~ ~s(data-dashboard-shell-main)
    assert html =~ ~s(data-dashboard-shell-header)
    assert html =~ ~s(data-dashboard-shell-body)
    assert html =~ ~s(data-dashboard-contract="page-header")
    assert html =~ ~s(data-dashboard-contract="page-content")
    assert html =~ ~s(data-dashboard-section="launchpad")
    assert html =~ ~s(data-dashboard-section="structure")
    assert html =~ ~s(data-dashboard-panel-group="stack")
    assert html =~ "EBoss dashboard"
    assert html =~ "Operator workspace"
    assert html =~ "The main dashboard now lives inside the shared operator shell"
    assert html =~ "Launch surface"
    assert html =~ "Panel groupings stay systematic instead of page-specific."
    assert html =~ "@#{current_user.username}"

    assert Regex.scan(~r/data-dashboard-header/, html) |> length() == 3
    assert Regex.scan(~r/data-dashboard-action-bar/, html) |> length() == 3

    refute html =~ "Dark / compact"
  end

  test "dashboard route redirects anonymous visitors to sign-in" do
    assert {:error, {:redirect, %{to: "/sign-in"}}} = live(build_conn(), ~p"/dashboard")
  end
end
