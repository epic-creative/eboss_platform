defmodule EBossWeb.PublicShellSmokeTest do
  use ExUnit.Case, async: false
  use EBossWeb, :verified_routes

  import LiveVue.Test
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias EBossWeb.BrowserTestContracts

  @endpoint EBossWeb.Endpoint

  setup do
    for app <- [
          :plug_crypto,
          :phoenix,
          :phoenix_html,
          :phoenix_live_view,
          :gettext,
          :phoenix_pubsub
        ] do
      {:ok, _} = Application.ensure_all_started(app)
    end

    if is_nil(Process.whereis(EBossWeb.Telemetry)) do
      start_supervised!(EBossWeb.Telemetry)
    end

    if is_nil(Process.whereis(EBoss.PubSub)) do
      start_supervised!({Phoenix.PubSub, name: EBoss.PubSub})
    end

    if is_nil(Process.whereis(EBossWeb.Endpoint)) do
      start_supervised!(EBossWeb.Endpoint)
    end

    :ok
  end

  test "auth routes mount the compact auth shell while home mounts the landing shell" do
    for route <- [~p"/sign-in", ~p"/register", ~p"/forgot-password"] do
      assert {:ok, view, _html} = live(build_conn(), route)
      assert has_element?(view, ".ui-shell[data-shell-mode='auth']")
      assert has_element?(view, ~s([data-testid="#{BrowserTestContracts.auth_shell()}"]))
      assert has_element?(view, ".so-auth-page")
      refute has_element?(view, "[data-public-shell-nav]")
      refute has_element?(view, "[data-public-shell-footer]")

      refute has_element?(
               view,
               ~s([data-testid="#{BrowserTestContracts.public_shell_context_action()}"])
             )
    end

    assert {:ok, home, _html} = live(build_conn(), ~p"/")
    assert has_element?(home, ".ui-shell[data-shell-mode='public']")
    assert has_element?(home, "[data-public-shell-nav]")
    assert has_element?(home, "[data-public-shell-footer]")

    landing = get_vue(home, name: "ShellOperatorLanding")
    assert landing.component == "ShellOperatorLanding"
    assert landing.ssr == false
    assert landing.props == %{}
  end

  test "home route mounts the new landing vue surface" do
    assert {:ok, view, _html} = live(build_conn(), ~p"/")
    landing = get_vue(view, name: "ShellOperatorLanding")

    assert landing.component == "ShellOperatorLanding"
    assert landing.ssr == false
    assert landing.props == %{}
  end
end
