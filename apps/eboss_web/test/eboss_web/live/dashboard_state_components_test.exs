defmodule EBossWeb.DashboardStateComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "dashboard empty state renders the shared sparse contract" do
    html =
      render_component(&EBossWeb.DashboardComponents.dashboard_empty_state/1, %{
        density: "sparse",
        title: "Nothing is scheduled yet.",
        description: "Keep the shell ready for the first run without resetting the route."
      })

    assert html =~ ~s(data-dashboard-state="empty")
    assert html =~ ~s(data-dashboard-density="sparse")
    assert html =~ "Sparse context"
    assert html =~ "Empty"
    assert html =~ ~s(data-state-style="empty")
    assert Regex.scan(~r/ui-dashboard-state__placeholder/, html) |> length() == 3
  end

  test "dashboard loading state preserves dense layout structure" do
    html =
      render_component(&EBossWeb.DashboardComponents.dashboard_loading_state/1, %{
        density: "dense",
        title: "Signals are syncing.",
        description: "Keep the rail footprint steady while data resolves."
      })

    assert html =~ ~s(data-dashboard-state="loading")
    assert html =~ ~s(data-dashboard-density="dense")
    assert html =~ "Dense context"
    assert html =~ "Loading"
    assert html =~ ~s(data-state-style="loading")
    assert html =~ "ui-spinner"
    assert html =~ "Layout slots stay reserved while the dashboard requests the next data pass."
  end

  test "dashboard error state keeps alert semantics inside dashboard chrome" do
    html =
      render_component(&EBossWeb.DashboardComponents.dashboard_error_state/1, %{
        title: "The sync failed.",
        description: "Recovery guidance should stay inside the grouped dashboard panel."
      })

    assert html =~ ~s(data-dashboard-state="error")
    assert html =~ ~s(data-dashboard-density="dense")
    assert html =~ "Attention"
    assert html =~ ~s(role="alert")
    assert html =~ ~s(aria-live="assertive")
    assert html =~ ~s(data-tone="danger")
    assert html =~ "Recovery stays inside the dashboard frame"
  end
end
