defmodule EBossWeb.PublicShellSmokeTest do
  use ExUnit.Case, async: false
  use EBossWeb, :verified_routes

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

  test "public routes render the shared shell chrome without persistence setup" do
    routes = [~p"/", ~p"/sign-in", ~p"/register", ~p"/forgot-password"]

    for route <- routes do
      assert {:ok, view, _html} = live(build_conn(), route)
      assert has_element?(view, ".ui-shell[data-shell-mode='public']")
      assert has_element?(view, "[data-public-shell-nav]")
      assert has_element?(view, "[data-public-shell-footer]")
      assert has_element?(view, "[data-public-shell-nav] .ui-nav-pill[data-active='true']")

      assert has_element?(
               view,
               ~s(nav[aria-label="#{BrowserTestContracts.public_routes_nav_label()}"])
             )

      assert has_element?(
               view,
               ~s(footer[aria-label="#{BrowserTestContracts.public_footer_label()}"])
             )

      assert has_element?(
               view,
               ~s([data-testid="#{BrowserTestContracts.public_shell_context_action()}"])
             )
    end
  end

  test "home route renders the shared CTA frame" do
    assert {:ok, view, _html} = live(build_conn(), ~p"/")
    assert has_element?(view, "[data-public-cta-frame]")
  end

  test "home route renders the reframed landing narrative" do
    assert {:ok, view, _html} = live(build_conn(), ~p"/")

    assert has_element?(view, ".ui-public-hero[data-public-section-pattern='hero']")
    assert has_element?(view, ".ui-public-proof-band[data-public-section-pattern='proof-band']")
    assert has_element?(view, ".ui-public-feature-row[data-public-section-pattern='feature-row']")
    assert has_element?(view, "[data-public-cta-frame][data-public-section-pattern='cta-band']")

    assert has_element?(
             view,
             ".ui-public-closing-section[data-public-section-pattern='closing-section']"
           )

    assert has_element?(view, "[data-home-hero]")
    assert has_element?(view, "[data-home-proof-strip]")
    assert has_element?(view, "[data-home-story='continuity']")
    assert has_element?(view, "[data-home-story='tempo']")
    assert has_element?(view, ~s([data-testid="#{BrowserTestContracts.home_hero()}"]))
    assert has_element?(view, ~s([data-testid="#{BrowserTestContracts.home_proof_band()}"]))

    assert has_element?(
             view,
             ~s([data-testid="#{BrowserTestContracts.home_feature_row_continuity()}"])
           )

    assert has_element?(
             view,
             ~s([data-testid="#{BrowserTestContracts.home_feature_row_tempo()}"])
           )

    assert has_element?(view, ~s([data-testid="#{BrowserTestContracts.home_closing()}"]))

    assert has_element?(
             view,
             "[data-home-hero] .ui-section-header__title",
             "A calmer launch page for teams that need the shell to stay precise."
           )

    assert has_element?(
             view,
             "[data-home-proof-strip] .ui-text-display",
             "The landing page leads with product posture, then proves it."
           )
  end
end
