defmodule EBossWeb.HomeLiveRenderTest do
  use ExUnit.Case, async: false

  setup do
    for app <- [:phoenix, :phoenix_html, :phoenix_live_view, :gettext, :phoenix_pubsub] do
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

  test "home live mounts the landing shell inside the public frame" do
    html =
      %{flash: %{}, current_scope: nil, current_user: nil}
      |> EBossWeb.HomeLive.render()
      |> Phoenix.LiveViewTest.rendered_to_string()

    assert html =~ ~s(data-shell-mode="public")
    assert html =~ ~s(data-public-shell-nav)
    assert html =~ ~s(data-public-shell-footer)
    assert html =~ ~s(data-name="ShellOperatorLanding")
    assert html =~ ~s(data-props="{}")
    assert html =~ ~s(data-ssr="false")
  end
end
