defmodule EBossWeb.DesignTypographyTest do
  use ExUnit.Case, async: true

  @app_dir Path.expand("..", __DIR__)
  @app_css Path.join(@app_dir, "assets/css/app.css")
  @tokens_css Path.join(@app_dir, "assets/css/system/tokens.css")
  @primitives_css Path.join(@app_dir, "assets/css/system/primitives.css")

  @heex_files [
    "lib/eboss_web/components/core_components.ex",
    "lib/eboss_web/components/layouts.ex",
    "lib/eboss_web/components/ui_components.ex",
    "lib/eboss_web/live/auth/confirm_live.ex",
    "lib/eboss_web/live/auth/forgot_password_live.ex",
    "lib/eboss_web/live/auth/magic_link_request_component.ex",
    "lib/eboss_web/live/auth/magic_link_live.ex",
    "lib/eboss_web/live/auth/password_sign_in_component.ex",
    "lib/eboss_web/live/auth/register_live.ex",
    "lib/eboss_web/live/auth/reset_password_live.ex",
    "lib/eboss_web/live/auth/sign_in_live.ex",
    "lib/eboss_web/live/dashboard_live.ex",
    "lib/eboss_web/live/dev/design_system_live.ex",
    "lib/eboss_web/live/home_live.ex",
    "lib/eboss_web/live/live_vue_demo_live.ex"
  ]

  @vue_files [
    "assets/vue/LiveVueDemo.vue",
    "assets/vue/auth/AuthScene.vue",
    "assets/vue/components/ui/UiDialog.story.vue",
    "assets/vue/components/ui/UiDialog.vue",
    "assets/vue/components/ui/UiTabs.vue",
    "assets/vue/components/ui/UiTooltip.vue",
    "assets/vue/dashboard/DashboardLaunchpad.vue",
    "assets/vue/stories/StoryControls.vue",
    "assets/vue/stories/VisualDna.story.vue"
  ]

  test "the CSS foundation defines shared semantic typography roles" do
    app_css = File.read!(@app_css)
    tokens_css = File.read!(@tokens_css)
    primitives_css = File.read!(@primitives_css)

    assert app_css =~ ~s(@import "./system/tokens.css";)
    assert app_css =~ ~s(@import "./system/primitives.css";)

    assert tokens_css =~ "--type-display-hero-size"
    assert tokens_css =~ "--type-title-lg-size"
    assert tokens_css =~ "--type-body-md-size"
    assert tokens_css =~ "--type-meta-size"

    assert primitives_css =~ ".ui-text-display"
    assert primitives_css =~ ".ui-text-title"
    assert primitives_css =~ ".ui-text-body"
    assert primitives_css =~ ".ui-text-meta"
    assert primitives_css =~ ".ui-text-link"
  end

  test "shared HEEx surfaces use the semantic typography hierarchy" do
    contents = read_files(@heex_files)

    assert contents =~ ~s(class="ui-text-display")
    assert contents =~ ~s(class="ui-text-title")
    assert contents =~ ~s(class="ui-text-body")
    assert contents =~ ~s(class="ui-text-meta")
    assert contents =~ ~s(class="ui-text-link")
    assert contents =~ ~s(title_size="lg")
    assert contents =~ ~s(title_size="md")
    assert contents =~ ~s(title_size="sm")

    refute contents =~ ~s(title_class="text-3xl")
    refute contents =~ ~s(title_class="text-4xl")
    refute contents =~ ~s(text-xs font-semibold uppercase tracking-[0.24em])
    refute contents =~ ~s(text-sm font-medium text-ui-accent)
    refute contents =~ ~s(ui-heading text-3xl)
  end

  test "shared Vue surfaces and primitives use the same semantic typography hierarchy" do
    contents = read_files(@vue_files)

    assert contents =~ ~s(class="ui-text-display")
    assert contents =~ ~s(class="ui-text-title")
    assert contents =~ ~s(class="ui-text-body")
    assert contents =~ ~s(class="ui-text-meta")

    refute contents =~ ~s(ui-heading text-3xl)
    refute contents =~ ~s(ui-kicker text-ui-accent)
    refute contents =~ ~s(text-sm leading-6 text-ui-text-muted)
  end

  defp read_files(paths) do
    paths
    |> Enum.map(&Path.join(@app_dir, &1))
    |> Enum.map_join("\n", &File.read!/1)
  end
end
