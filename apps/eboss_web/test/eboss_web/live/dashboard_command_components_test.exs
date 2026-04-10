defmodule EBossWeb.DashboardCommandComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "dashboard utility strip renders lightweight command cues" do
    html =
      render_component(&EBossWeb.DashboardComponents.dashboard_utility_strip/1, %{
        item: [
          %{
            id: "primary-lane",
            label: "Primary lane",
            value: "Launch surface",
            hint: "Route-owned workspace entry",
            href: "#dashboard-launchpad",
            shortcut: "GL",
            tone: "primary",
            icon: "hero-bolt"
          },
          %{
            id: "state-audit",
            label: "State audit",
            value: "Fallback states",
            hint: "Review empty, loading, and error treatment",
            href: "#dashboard-states",
            shortcut: "GS",
            tone: "warning",
            icon: "hero-command-line"
          }
        ]
      })

    assert html =~ ~s(data-dashboard-utility-strip)
    assert html =~ ~s(data-dashboard-utility-item="primary-lane")
    assert html =~ ~s(data-dashboard-utility-item="state-audit")
    assert html =~ "Command surface"
    assert html =~ "Launch surface"
    assert html =~ "Fallback states"
    assert Regex.scan(~r/data-dashboard-keycap/, html) |> length() == 2
  end

  test "dashboard quick actions render a navigable command list" do
    html =
      render_component(&EBossWeb.DashboardComponents.dashboard_quick_actions/1, %{
        action: [
          %{
            id: "open-launch-surface",
            label: "Open launch surface",
            description: "Return to the primary operator lane.",
            href: "#dashboard-launchpad",
            shortcut: "GL",
            badge: "Primary",
            tone: "primary",
            icon: "hero-bolt"
          },
          %{
            id: "audit-fallback-states",
            label: "Audit fallback states",
            description: "Review empty, loading, and recovery treatment.",
            href: "#dashboard-states",
            shortcut: "GS",
            badge: "States",
            tone: "warning",
            icon: "hero-exclamation-triangle"
          }
        ]
      })

    assert html =~ ~s(data-dashboard-quick-actions)
    assert html =~ ~s(aria-label="Dashboard quick actions")
    assert html =~ ~s(data-dashboard-quick-action="open-launch-surface")
    assert html =~ ~s(data-dashboard-quick-action="audit-fallback-states")
    assert html =~ "Quick actions"
    assert html =~ "Cue"
    assert Regex.scan(~r/data-dashboard-keycap/, html) |> length() == 2
  end
end
