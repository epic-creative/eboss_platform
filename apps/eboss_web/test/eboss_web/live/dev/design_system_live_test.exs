defmodule EBossWeb.Dev.DesignSystemLiveTest do
  use EBossWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders the dev design system preview", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/dev/design-system")

    assert html =~ "EBoss design system"
    assert html =~ "Action styles"
    assert html =~ "No active runs"
  end
end
