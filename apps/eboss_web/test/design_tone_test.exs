defmodule EBossWeb.DesignToneTest do
  use ExUnit.Case, async: true

  @app_dir Path.expand("..", __DIR__)
  @tokens_css Path.join(@app_dir, "assets/css/system/tokens.css")
  @themes_css Path.join(@app_dir, "assets/css/system/themes.css")
  @patterns_css Path.join(@app_dir, "assets/css/system/patterns.css")
  @primitives_css Path.join(@app_dir, "assets/css/system/primitives.css")

  @heex_surface_files [
    "lib/eboss_web/components/layouts.ex",
    "lib/eboss_web/live/dashboard_live.ex",
    "lib/eboss_web/live/dev/design_system_live.ex",
    "lib/eboss_web/live/home_live.ex"
  ]

  @vue_surface_files [
    "assets/vue/LiveVueDemo.vue",
    "assets/vue/auth/AuthScene.vue",
    "assets/vue/dashboard/DashboardLaunchpad.vue",
    "assets/vue/stories/VisualDna.story.vue"
  ]

  test "the CSS foundation defines semantic tone tokens and removes decorative warning washes" do
    tokens_css = File.read!(@tokens_css)
    themes_css = File.read!(@themes_css)
    patterns_css = File.read!(@patterns_css)
    primitives_css = File.read!(@primitives_css)

    assert tokens_css =~ "--color-ui-primary"
    assert tokens_css =~ "--color-ui-neutral"
    assert tokens_css =~ "--color-ui-success"
    assert tokens_css =~ "--color-ui-warning"
    assert tokens_css =~ "--color-ui-danger"

    assert primitives_css =~ "--ui-button-tone-color"
    assert primitives_css =~ ~s(.ui-button[data-tone="success"])
    assert primitives_css =~ ~s(.ui-button[data-tone="warning"])
    assert primitives_css =~ ~s(.ui-button[data-tone="danger"])
    assert primitives_css =~ ~s(.ui-alert[data-tone="primary"])
    assert primitives_css =~ ~s(.ui-alert[data-tone="warning"])

    refute themes_css =~ "var(--color-warning) 12%"
    refute patterns_css =~ "var(--color-warning) 12%"
    refute patterns_css =~ "var(--color-warning) 18%"
  end

  test "shared HEEx and Vue primitives use the same semantic tone vocabulary" do
    core_components = read_file("lib/eboss_web/components/core_components.ex")
    ui_components = read_file("lib/eboss_web/components/ui_components.ex")
    ui_button_vue = read_file("assets/vue/components/ui/UiButton.vue")
    ui_badge_vue = read_file("assets/vue/components/ui/UiBadge.vue")
    ui_alert_vue = read_file("assets/vue/components/ui/UiAlert.vue")
    ui_panel_vue = read_file("assets/vue/components/ui/UiPanel.vue")

    assert core_components =~
             ~r/attr :tone, :string,\s+values: ~w\(primary neutral success warning danger\),\s+default: "primary"/s

    assert ui_button_vue =~ ~s(tone?: "primary" | "neutral" | "success" | "warning" | "danger")

    assert ui_components =~
             ~r/attr :tone, :string,\s+values: ~w\(neutral primary success warning danger\),\s+default: "neutral"/s

    assert ui_badge_vue =~ ~s(tone?: "neutral" | "primary" | "success" | "warning" | "danger")
    assert ui_alert_vue =~ ~s(tone?: "primary" | "neutral" | "success" | "warning" | "danger")

    assert ui_components =~
             ~r/attr :tone, :string,\s+values: ~w\(neutral primary inverse\),\s+default: "neutral"/s

    assert ui_panel_vue =~ ~s(tone?: "neutral" | "primary" | "inverse")

    assert ui_components =~
             ~r/attr :eyebrow_tone, :string,\s+values: ~w\(primary neutral soft muted success warning danger\),\s+default: "primary"/s
  end

  test "shared surfaces reserve warning and danger tones for actual state cues" do
    heex_contents = read_files(@heex_surface_files)
    vue_contents = read_files(@vue_surface_files)
    design_system_live = read_file("lib/eboss_web/live/dev/design_system_live.ex")
    ui_alert_story = read_file("assets/vue/components/ui/UiAlert.story.vue")

    refute heex_contents =~ ~s(<.badge tone="warning">)
    refute vue_contents =~ ~s(<UiBadge tone="warning">)
    refute heex_contents =~ ~s(data-tone="accent")
    refute vue_contents =~ ~s(data-tone="accent")

    assert heex_contents =~ ~s(<.badge tone="neutral">Dashboard surfaces</.badge>)
    assert vue_contents =~ ~s(<UiBadge tone="neutral">Dashboard surfaces</UiBadge>)

    assert design_system_live =~ ~s(<div class="ui-alert" data-tone="warning">)
    assert design_system_live =~ ~s(<div class="ui-alert" data-tone="danger">)
    assert ui_alert_story =~ ~s(<UiAlert tone="warning")
    assert ui_alert_story =~ ~s(<UiAlert tone="danger")
  end

  defp read_files(paths) do
    paths
    |> Enum.map(&read_file/1)
    |> Enum.join("\n")
  end

  defp read_file(path) do
    @app_dir
    |> Path.join(path)
    |> File.read!()
  end
end
