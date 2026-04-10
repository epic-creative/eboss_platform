defmodule EBossWeb.AuthContractSmokeTest do
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

  test "anonymous auth routes expose stable shell and form contracts" do
    routes = [
      {~p"/sign-in",
       [
         BrowserTestContracts.password_sign_in_form_label(),
         BrowserTestContracts.magic_link_request_form_label()
       ]},
      {~p"/register", [BrowserTestContracts.register_form_label()]},
      {~p"/forgot-password", [BrowserTestContracts.forgot_password_form_label()]}
    ]

    for {route, form_labels} <- routes do
      assert {:ok, view, _html} = live(build_conn(), route)
      assert has_element?(view, ~s([data-testid="#{BrowserTestContracts.auth_shell()}"]))
      assert has_element?(view, ".ui-auth-grid > .ui-panel.ui-panel-padding-sm")
      assert has_element?(view, ".ui-auth-grid > .ui-panel.ui-panel-padding-lg")
      refute has_element?(view, ".ui-frame-card")
      refute has_element?(view, ".ui-form-card")

      assert has_element?(
               view,
               ~s(nav[aria-label="#{BrowserTestContracts.authentication_routes_nav_label()}"])
             )

      for form_label <- form_labels do
        assert has_element?(view, ~s(form[aria-label="#{form_label}"]))
      end
    end
  end
end
