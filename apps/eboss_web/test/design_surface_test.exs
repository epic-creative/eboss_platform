defmodule EBossWeb.DesignSurfaceTest do
  use ExUnit.Case, async: true

  @app_dir Path.expand("..", __DIR__)
  @tokens_css Path.join(@app_dir, "assets/css/system/tokens.css")
  @themes_css Path.join(@app_dir, "assets/css/system/themes.css")
  @primitives_css Path.join(@app_dir, "assets/css/system/primitives.css")
  @patterns_css Path.join(@app_dir, "assets/css/system/patterns.css")

  test "the CSS foundation defines a systematic shell, panel, and card surface scale" do
    tokens_css = File.read!(@tokens_css)
    themes_css = File.read!(@themes_css)
    primitives_css = File.read!(@primitives_css)
    patterns_css = File.read!(@patterns_css)

    assert tokens_css =~ "--radius-shell"
    assert tokens_css =~ "--radius-panel"
    assert tokens_css =~ "--radius-card"
    assert tokens_css =~ "--shadow-shell"
    assert tokens_css =~ "--shadow-surface-default"
    assert tokens_css =~ "--shadow-surface-floating"
    assert tokens_css =~ "--shadow-surface-solid"

    assert themes_css =~ "--color-surface-default"
    assert themes_css =~ "--color-surface-floating"
    assert themes_css =~ "--color-surface-solid"
    assert themes_css =~ "--color-surface-subtle"

    assert primitives_css =~ ~s(.ui-panel[data-surface="floating"])
    assert primitives_css =~ ~s(.ui-panel[data-surface="solid"])

    assert patterns_css =~ ".ui-preview-frame"
    assert patterns_css =~ "var(--radius-shell)"
    assert patterns_css =~ "var(--radius-card)"

    refute patterns_css =~ "border-radius: 1.35rem;"
    refute patterns_css =~ "border-radius: 1.5rem;"
  end

  test "HEEx and Vue surfaces share the same default, floating, and solid vocabulary" do
    design_system_live = read_file("lib/eboss_web/live/dev/design_system_live.ex")
    home_live = read_file("lib/eboss_web/live/home_live.ex")
    story_surface = read_file("assets/vue/stories/StorySurface.vue")
    visual_dna_story = read_file("assets/vue/stories/VisualDna.story.vue")
    ui_panel_story = read_file("assets/vue/components/ui/UiPanel.story.vue")
    ui_dialog_vue = read_file("assets/vue/components/ui/UiDialog.vue")
    ui_tabs_vue = read_file("assets/vue/components/ui/UiTabs.vue")
    auth_scene_vue = read_file("assets/vue/auth/AuthScene.vue")
    dashboard_launchpad_vue = read_file("assets/vue/dashboard/DashboardLaunchpad.vue")

    assert design_system_live =~ "Default surface"
    assert design_system_live =~ "Floating surface"
    assert design_system_live =~ "Solid surface"

    assert ui_panel_story =~ "Default surface"
    assert ui_panel_story =~ "Floating surface"
    assert ui_panel_story =~ "Solid surface"

    assert home_live =~ ~s(<.panel as="div" surface="solid" padding="sm" class="ui-metric-card">)
    assert story_surface =~ ~s(class="ui-preview-frame")
    assert visual_dna_story =~ ~s(<UiPanel surface="solid" padding="sm" class="space-y-3">)
    assert auth_scene_vue =~ ~s(<UiPanel class="ui-auth-scene__tile p-4" surface="solid">)

    assert dashboard_launchpad_vue =~
             ~s(<UiPanel class="ui-auth-scene__tile p-4" surface="solid">)

    assert ui_dialog_vue =~ ~s(<UiPanel as="div" surface="floating" class="sm:p-8">)
    assert ui_tabs_vue =~ ~s(<UiPanel as="div" surface="solid">)

    refute design_system_live =~ "rounded-[1.35rem]"
    refute visual_dna_story =~ "rounded-[1.35rem]"
    refute visual_dna_story =~ "bg-ui-panel-muted/70"
    refute ui_dialog_vue =~ ~s(<div class="ui-panel)
    refute ui_tabs_vue =~ ~s(<div class="ui-panel)
  end

  test "shared previews and shell contracts expose the supported theme and density matrix" do
    tokens_css = File.read!(@tokens_css)
    primitives_css = File.read!(@primitives_css)
    patterns_css = File.read!(@patterns_css)
    design_system_live = read_file("lib/eboss_web/live/dev/design_system_live.ex")
    story_controls = read_file("assets/vue/stories/StoryControls.vue")
    story_surface = read_file("assets/vue/stories/StorySurface.vue")
    layouts = read_file("lib/eboss_web/components/layouts.ex")
    ui_components = read_file("lib/eboss_web/components/ui_components.ex")
    ui_panel_vue = read_file("assets/vue/components/ui/UiPanel.vue")

    assert tokens_css =~ "--space-shell-inline"
    assert tokens_css =~ "--space-preview-gap"
    assert tokens_css =~ "--space-panel-md"
    assert tokens_css =~ ~s([data-density="compact"])

    assert primitives_css =~ ":where(.ui-panel-padding-md)"
    assert primitives_css =~ ".ui-nav-pill"
    assert primitives_css =~ "min-height: var(--control-height-md)"

    assert patterns_css =~ ".ui-shell-header__inner"
    assert patterns_css =~ ".ui-shell-main"
    assert patterns_css =~ ".ui-preview-shell"
    assert patterns_css =~ ".ui-preview-shell__grid"

    assert layouts =~ "ui-shell-header__inner"
    assert layouts =~ "ui-shell-main"
    assert ui_components =~ ~s("ui-panel-padding-md")
    assert ui_panel_vue =~ ~s(return "ui-panel-padding-md")

    assert story_controls =~ "update:density"
    assert story_surface =~ ~s(:data-density="density === 'compact' ? 'compact' : undefined")

    assert design_system_live =~ "Theme and density review matrix"
    assert design_system_live =~ "Dark / default"
    assert design_system_live =~ "Dark / compact"
    assert design_system_live =~ "Light / default"
    assert design_system_live =~ "Light / compact"
    assert design_system_live =~ "data-theme={@theme}"
    assert design_system_live =~ "data-density={@density_attr}"
  end

  test "HEEx and Vue primitive contracts align for alerts and invalid field states" do
    core_components = read_file("lib/eboss_web/components/core_components.ex")
    ui_components = read_file("lib/eboss_web/components/ui_components.ex")
    auth_components = read_file("lib/eboss_web/components/auth_components.ex")
    sign_in_live = read_file("lib/eboss_web/live/auth/sign_in_live.ex")
    forgot_password_live = read_file("lib/eboss_web/live/auth/forgot_password_live.ex")
    design_system_live = read_file("lib/eboss_web/live/dev/design_system_live.ex")
    ui_alert_vue = read_file("assets/vue/components/ui/UiAlert.vue")
    ui_alert_story = read_file("assets/vue/components/ui/UiAlert.story.vue")
    ui_input_vue = read_file("assets/vue/components/ui/UiInput.vue")
    ui_select_vue = read_file("assets/vue/components/ui/UiSelect.vue")
    ui_textarea_vue = read_file("assets/vue/components/ui/UiTextarea.vue")
    ui_input_story = read_file("assets/vue/components/ui/UiInput.story.vue")
    ui_select_story = read_file("assets/vue/components/ui/UiSelect.story.vue")
    ui_textarea_story = read_file("assets/vue/components/ui/UiTextarea.story.vue")

    assert core_components =~ ~s(attr :invalid, :boolean, default: false)
    assert ui_components =~ "def alert(assigns)"

    assert ui_components =~
             ~s|attr :tone, :string, values: ~w(primary neutral success warning danger), default: "neutral"|

    assert ui_components =~ ~s(attr :role, :string, default: nil)
    assert ui_components =~ ~s(attr :live, :string, default: nil)

    assert ui_components =~
             ~s|defp alert_role(nil, tone) when tone in ["warning", "danger"], do: "alert"|

    assert ui_components =~ ~s|defp alert_live(nil, "alert"), do: "assertive"|

    assert auth_components =~
             ~s|<.auth_feedback
      :if={@messages != []}
      tone="danger"
      data-feedback="danger"
      role="alert"
      live="assertive"|

    assert auth_components =~ "def auth_feedback(assigns)"
    assert auth_components =~ "def auth_form(assigns)"
    assert auth_components =~ "def auth_submit(assigns)"
    assert auth_components =~ "def auth_email_input(assigns)"
    assert auth_components =~ "def auth_username_input(assigns)"
    assert auth_components =~ "def auth_password_input(assigns)"

    assert forgot_password_live =~ ~s|<.auth_feedback|
    assert forgot_password_live =~ ~s|title="Request received."|

    assert forgot_password_live =~
             ~s|message="If the account exists, reset instructions are on the way."|

    refute forgot_password_live =~
             ~s|put_flash(:info, "If that account exists, we just emailed reset instructions.")|

    assert sign_in_live =~ ~s|<.auth_feedback|
    assert sign_in_live =~ ~s|message="If the account exists, a sign-in link is on the way."|

    refute sign_in_live =~
             ~s|put_flash(:info, "If that account exists, we just sent a magic link.")|

    assert design_system_live =~ ~s(<.alert)
    refute design_system_live =~ ~s(class="ui-alert")

    assert ui_alert_vue =~
             "tone?: \"primary\" | \"neutral\" | \"success\" | \"warning\" | \"danger\""

    assert ui_alert_vue =~
             "const alertRole = computed(() => props.role ?? ([\"warning\", \"danger\"].includes(props.tone) ? \"alert\" : \"status\"))"

    assert design_system_live =~ "Operator note"
    assert design_system_live =~ "Human review requested"
    assert design_system_live =~ "Delivery failed"
    assert ui_alert_story =~ "Operator note"
    assert ui_alert_story =~ "Human review requested"
    assert ui_alert_story =~ "Delivery failed"

    assert ui_input_vue =~ "errors?: string[]"
    assert ui_input_vue =~ "invalid?: boolean"
    assert ui_input_vue =~ "props.invalid || errorMessages.value.length > 0"
    assert ui_input_story =~ ~s(:errors="['A more descriptive label is required.']")

    assert ui_select_vue =~ "errors?: string[]"
    assert ui_select_vue =~ "invalid?: boolean"
    assert ui_select_vue =~ "props.invalid || errorMessages.value.length > 0"
    assert ui_select_story =~ ~s(:errors="['Choose a route before continuing.']")

    assert ui_textarea_vue =~ "errors?: string[]"
    assert ui_textarea_vue =~ "invalid?: boolean"
    assert ui_textarea_vue =~ "props.invalid || errorMessages.value.length > 0"

    assert ui_textarea_story =~
             ~s(:errors="['Add the triggering run, owner, and current blocker.']")
  end

  test "auth routes share a reusable shell hierarchy and preview contract" do
    patterns_css = File.read!(@patterns_css)
    auth_components = read_file("lib/eboss_web/components/auth_components.ex")
    design_system_live = read_file("lib/eboss_web/live/dev/design_system_live.ex")
    sign_in_live = read_file("lib/eboss_web/live/auth/sign_in_live.ex")
    register_live = read_file("lib/eboss_web/live/auth/register_live.ex")
    forgot_password_live = read_file("lib/eboss_web/live/auth/forgot_password_live.ex")
    reset_password_live = read_file("lib/eboss_web/live/auth/reset_password_live.ex")
    confirm_live = read_file("lib/eboss_web/live/auth/confirm_live.ex")
    magic_link_live = read_file("lib/eboss_web/live/auth/magic_link_live.ex")

    assert patterns_css =~ ".ui-auth-page"
    assert patterns_css =~ ".ui-auth-page__header"
    assert patterns_css =~ ".ui-auth-page__body"
    assert patterns_css =~ ".ui-auth-page__footer"
    assert patterns_css =~ ".ui-auth-flow-stack"
    assert patterns_css =~ ".ui-auth-form"
    assert patterns_css =~ ".ui-auth-form__fieldset"
    assert patterns_css =~ ".ui-auth-form.phx-submit-loading .ui-auth-submit::after"

    assert auth_components =~ "def auth_page(assigns)"
    assert auth_components =~ "def auth_page_footer(assigns)"
    assert auth_components =~ ~s(aria-label="Authentication routes")
    assert auth_components =~ "def auth_form(assigns)"
    assert auth_components =~ "def auth_submit(assigns)"

    assert design_system_live =~ "<.auth_page"
    assert sign_in_live =~ "<.auth_page"
    assert sign_in_live =~ "<.auth_form"
    assert register_live =~ "<.auth_page"
    assert register_live =~ "<.auth_form"
    assert forgot_password_live =~ "<.auth_page"
    assert forgot_password_live =~ "<.auth_form"
    assert reset_password_live =~ "<.auth_page"
    assert reset_password_live =~ "<.auth_form"
    assert confirm_live =~ "<.auth_page"
    assert confirm_live =~ "<.auth_form"
    assert magic_link_live =~ "<.auth_page"
    assert magic_link_live =~ "<.auth_form"
  end

  defp read_file(path) do
    @app_dir
    |> Path.join(path)
    |> File.read!()
  end
end
