defmodule EBossWeb.DesignAccessibilityTest do
  use ExUnit.Case, async: true

  @app_dir Path.expand("..", __DIR__)
  @design_md Path.expand("../../DESIGN.md", @app_dir)
  @primitives_css Path.join(@app_dir, "assets/css/system/primitives.css")

  test "DESIGN.md makes accessibility and interaction rules explicit" do
    design_md = File.read!(@design_md)

    assert design_md =~ "### Focus and keyboard access"
    assert design_md =~ "Disabled links must stop behaving like links."
    assert design_md =~ "`aria-describedby` and `aria-invalid`"
    assert design_md =~ "### Contrast and clarity"
    assert design_md =~ "`prefers-reduced-motion`"
  end

  test "shared CSS primitives define focus visibility and reduced-motion fallbacks" do
    primitives_css = File.read!(@primitives_css)

    assert primitives_css =~ ".ui-text-link:focus-visible"
    assert primitives_css =~ ~s(.ui-field-control[data-invalid="true"]:focus-within)
    assert primitives_css =~ "@media (prefers-reduced-motion: reduce)"
    assert primitives_css =~ ".ui-spinner"
  end

  test "shared HEEx and Vue primitives expose explicit accessibility contracts" do
    core_components = read_file("lib/eboss_web/components/core_components.ex")
    auth_components = read_file("lib/eboss_web/components/auth_components.ex")
    sign_in_live = read_file("lib/eboss_web/live/auth/sign_in_live.ex")
    forgot_password_live = read_file("lib/eboss_web/live/auth/forgot_password_live.ex")
    design_system_live = read_file("lib/eboss_web/live/dev/design_system_live.ex")
    ui_button_vue = read_file("assets/vue/components/ui/UiButton.vue")
    ui_input_vue = read_file("assets/vue/components/ui/UiInput.vue")
    ui_select_vue = read_file("assets/vue/components/ui/UiSelect.vue")
    ui_textarea_vue = read_file("assets/vue/components/ui/UiTextarea.vue")
    ui_alert_vue = read_file("assets/vue/components/ui/UiAlert.vue")

    assert core_components =~ "assigns.is_link && assigns.button_disabled"
    assert core_components =~ "aria-describedby={@describedby}"
    assert core_components =~ "aria-invalid={invalid_attr(@invalid_state)}"
    assert core_components =~ "aria-live=\"polite\""
    assert core_components =~ "aria-live=\"assertive\""

    assert auth_components =~ "role=\"alert\""
    assert sign_in_live =~ "role=\"status\""
    assert forgot_password_live =~ "role=\"status\""
    assert design_system_live =~ "aria-live=\"assertive\""

    assert ui_button_vue =~ "props.href && disabledState.value"
    assert ui_button_vue =~ ":aria-busy=\"loading ? 'true' : undefined\""

    assert ui_input_vue =~ "defineOptions({ inheritAttrs: false })"
    assert ui_input_vue =~ ":aria-describedby=\"describedBy\""
    assert ui_input_vue =~ ":aria-invalid=\"invalidState || undefined\""
    assert ui_select_vue =~ ":aria-describedby=\"describedBy\""
    assert ui_select_vue =~ ":aria-invalid=\"invalidState || undefined\""
    assert ui_textarea_vue =~ ":aria-invalid=\"invalidState || undefined\""

    assert ui_alert_vue =~ ":role=\"alertRole\""
    assert ui_alert_vue =~ ":aria-live=\"alertLive\""
  end

  defp read_file(path) do
    @app_dir
    |> Path.join(path)
    |> File.read!()
  end
end
