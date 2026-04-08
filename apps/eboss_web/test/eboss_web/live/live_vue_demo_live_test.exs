defmodule EBossWeb.LiveVueDemoLiveTest do
  use EBossWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders the demo vue component and updates props through LiveView events", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, EBossWeb.LiveVueDemoLive)

    vue = LiveVue.Test.get_vue(view, name: "LiveVueDemo")

    assert vue.component == "LiveVueDemo"
    assert vue.ssr == false
    assert vue.props["count"] == 2
    assert vue.props["headline"] == "LiveVue + Vite are wired up"

    render_hook(view, "increment", %{})

    vue = LiveVue.Test.get_vue(view, name: "LiveVueDemo")
    assert vue.props["count"] == 3

    render_hook(view, "reset", %{})

    vue = LiveVue.Test.get_vue(view, name: "LiveVueDemo")
    assert vue.props["count"] == 0
  end
end
