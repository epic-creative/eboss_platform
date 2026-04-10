defmodule EBossWeb.PublicShellSmokeTest do
  use ExUnit.Case, async: false
  use EBossWeb, :verified_routes

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint EBossWeb.Endpoint

  test "public routes render the shared shell chrome without persistence setup" do
    routes = [~p"/", ~p"/sign-in", ~p"/register", ~p"/forgot-password"]

    for route <- routes do
      assert {:ok, view, _html} = live(build_conn(), route)
      assert has_element?(view, ".ui-shell[data-shell-mode='public']")
      assert has_element?(view, "[data-public-shell-nav]")
      assert has_element?(view, "[data-public-shell-footer]")
      assert has_element?(view, "[data-public-shell-nav] .ui-nav-pill[data-active='true']")
    end
  end

  test "home route renders the shared CTA frame" do
    assert {:ok, view, _html} = live(build_conn(), ~p"/")
    assert has_element?(view, "[data-public-cta-frame]")
  end
end
