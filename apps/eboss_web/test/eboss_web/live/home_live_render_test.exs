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

  test "home live renders the reframed landing structure" do
    html =
      %{flash: %{}, current_scope: nil, current_user: nil}
      |> EBossWeb.HomeLive.render()
      |> Phoenix.LiveViewTest.rendered_to_string()

    assert html =~ ~s(data-home-hero)
    assert html =~ ~s(data-home-proof-strip)
    assert html =~ ~s(data-home-story="continuity")
    assert html =~ ~s(data-home-story="tempo")
    assert html =~ ~s(data-home-closing)
    assert html =~ ~s(data-public-section-pattern="hero")
    assert html =~ ~s(data-public-section-pattern="proof-band")
    assert html =~ ~s(data-public-section-pattern="cta-band")
    assert html =~ ~s(data-public-section-pattern="closing-section")
    assert html =~ "A calmer launch page for teams that need the shell to stay precise."
    assert html =~ "The landing page leads with product posture, then proves it."
    assert html =~ "Enter the product from a page that already speaks the same language."

    assert Regex.scan(~r/data-public-section-pattern="feature-row"/, html) |> length() == 2
  end
end
