defmodule EBossWeb.Dev.DesignSystemLiveTest do
  use EBossWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders the dev design system preview", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/dev/design-system")

    assert html =~ "EBoss design system"
    assert html =~ "Operator console first, marketing polish second."
    assert html =~ "Dashboard surfaces"
    assert html =~ "Auth surfaces"
    assert html =~ "Public surfaces"
    assert html =~ "No active runs"
    assert html =~ "ui-text-display"
    assert html =~ "ui-text-title"
    assert html =~ "ui-text-body"
    assert html =~ "ui-text-meta"
  end
end
