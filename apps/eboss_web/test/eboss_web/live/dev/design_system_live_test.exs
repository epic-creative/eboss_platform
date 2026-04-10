defmodule EBossWeb.Dev.DesignSystemLiveTest do
  use ExUnit.Case, async: true

  @design_system_live Path.expand(
                        "../../../../lib/eboss_web/live/dev/design_system_live.ex",
                        __DIR__
                      )

  test "defines the dev design system preview content for shared surfaces" do
    source = File.read!(@design_system_live)

    assert source =~ "EBoss design system"
    assert source =~ "Default, floating, and solid surfaces each have one job"
    assert source =~ "Default surface"
    assert source =~ "Floating surface"
    assert source =~ "Solid surface"
    assert source =~ "Operator console first, marketing polish second."
    assert source =~ "Dashboard surfaces"
    assert source =~ "Auth surfaces"
    assert source =~ "Public surfaces"
    assert source =~ "No active runs"
    assert source =~ "Semantic tones"
    assert source =~ "Operator note"
    assert source =~ "ui-text-display"
    assert source =~ "ui-text-title"
    assert source =~ "ui-text-body"
    assert source =~ "ui-text-meta"
  end
end
