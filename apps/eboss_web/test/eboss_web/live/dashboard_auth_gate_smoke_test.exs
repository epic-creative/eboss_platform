defmodule EBossWeb.DashboardAuthGateSmokeTest do
  use ExUnit.Case, async: false
  use EBossWeb, :verified_routes

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

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

  test "dashboard redirects anonymous visitors to sign-in" do
    assert {:error, {:redirect, %{to: "/sign-in"}}} = live(build_conn(), ~p"/dashboard")
  end

  test "app routes redirect anonymous visitors to sign-in" do
    assert {:error, {:redirect, %{to: "/sign-in"}}} =
             live(build_conn(), ~p"/route-owner/route-workspace/apps/folio")

    assert {:error, {:redirect, %{to: "/sign-in"}}} =
             live(build_conn(), ~p"/route-owner/route-workspace/apps/folio/files")
  end
end
