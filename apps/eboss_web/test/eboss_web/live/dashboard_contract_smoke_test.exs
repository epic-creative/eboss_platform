defmodule EBossWeb.DashboardContractSmokeTest do
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

  test "dashboard live render exposes stable shell and state contracts" do
    html =
      render_component(&EBossWeb.DashboardLive.render/1, %{
        flash: %{},
        current_scope: nil,
        current_user: %{username: "contract_user", email: "contract@example.com"}
      })

    assert html =~ ~s(data-testid="#{BrowserTestContracts.dashboard_shell()}")
    assert html =~ ~s(aria-label="#{BrowserTestContracts.dashboard_shell_label()}")
    assert html =~ ~s(aria-label="#{BrowserTestContracts.dashboard_sidebar_label()}")
    assert html =~ ~s(aria-label="#{BrowserTestContracts.dashboard_navigation_label()}")
    assert html =~ ~s(aria-label="#{BrowserTestContracts.dashboard_workspace_label()}")
    assert html =~ ~s(aria-label="#{BrowserTestContracts.dashboard_command_surface_label()}")
    assert html =~ ~s(aria-label="#{BrowserTestContracts.dashboard_quick_actions_label()}")

    for section <- ~w(launchpad structure states) do
      assert html =~ ~s(aria-label="#{BrowserTestContracts.dashboard_section_label(section)}")
    end

    for variant <- ~w(empty loading error) do
      assert html =~ ~s(aria-label="#{BrowserTestContracts.dashboard_state_label(variant)}")
    end

    assert html =~ ~s(href="/dashboard")
    assert html =~ ~s(href="#dashboard-launchpad")
    assert html =~ "Dashboard"
    assert html =~ "Open launch surface"
  end
end
