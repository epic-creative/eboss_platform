defmodule EBossWeb.DesignSurfaceTest do
  use ExUnit.Case, async: true

  @app_dir Path.expand("..", __DIR__)
  @tokens_css Path.join(@app_dir, "assets/css/system/tokens.css")
  @primitives_css Path.join(@app_dir, "assets/css/system/primitives.css")
  @patterns_css Path.join(@app_dir, "assets/css/system/patterns.css")

  test "the CSS foundation defines a systematic shell, panel, and card surface scale" do
    tokens_css = File.read!(@tokens_css)
    primitives_css = File.read!(@primitives_css)
    patterns_css = File.read!(@patterns_css)

    assert tokens_css =~ "--radius-shell"
    assert tokens_css =~ "--radius-panel"
    assert tokens_css =~ "--radius-card"
    assert tokens_css =~ "--shadow-shell"
    assert tokens_css =~ "--shadow-surface-default"
    assert tokens_css =~ "--shadow-surface-floating"
    assert tokens_css =~ "--shadow-surface-solid"

    assert tokens_css =~ "--color-surface-default"
    assert tokens_css =~ "--color-surface-floating"
    assert tokens_css =~ "--color-surface-solid"
    assert tokens_css =~ "--color-surface-subtle"

    assert primitives_css =~ ~s(.ui-panel[data-surface="floating"])
    assert primitives_css =~ ~s(.ui-panel[data-surface="solid"])

    assert patterns_css =~ ".ui-preview-frame"
    assert patterns_css =~ "var(--radius-shell)"
    assert patterns_css =~ "var(--radius-card)"

    refute primitives_css =~ ".ui-heading"
    refute primitives_css =~ ".ui-copy-muted"
    refute patterns_css =~ ".ui-frame-card"
    refute patterns_css =~ ".ui-form-card"

    refute patterns_css =~ "border-radius: 1.35rem;"
    refute patterns_css =~ "border-radius: 1.5rem;"
  end

  test "HEEx and Vue surfaces share the same default, floating, and solid vocabulary" do
    design_system_live = read_file("lib/eboss_web/live/dev/design_system_live.ex")
    home_live = read_file("lib/eboss_web/live/home_live.ex")
    ui_components = read_file("lib/eboss_web/components/ui_components.ex")
    story_surface = read_file("assets/vue/stories/StorySurface.vue")
    visual_dna_story = read_file("assets/vue/stories/VisualDna.story.vue")
    ui_panel_story = read_file("assets/vue/components/ui/UiPanel.story.vue")
    ui_dialog_vue = read_file("assets/vue/components/ui/UiDialog.vue")
    ui_tabs_vue = read_file("assets/vue/components/ui/UiTabs.vue")
    auth_scene_vue = read_file("assets/vue/auth/AuthScene.vue")
    dashboard_launchpad_vue = read_file("assets/vue/dashboard/DashboardLaunchpad.vue")
    shell_operator_landing_vue = read_file("assets/vue/shell/public/ShellOperatorLanding.vue")

    shell_operator_workspace_vue =
      read_file("assets/vue/shell/workspace/ShellOperatorWorkspaceApp.vue")

    workspace_sidebar_vue = read_file("assets/vue/shell/workspace/WorkspaceSidebar.vue")

    assert design_system_live =~ "Default surface"
    assert design_system_live =~ "Floating surface"
    assert design_system_live =~ "Solid surface"

    assert ui_panel_story =~ "Default surface"
    assert ui_panel_story =~ "Floating surface"
    assert ui_panel_story =~ "Solid surface"

    assert home_live =~ ~s(shell_mode="public")
    assert home_live =~ ~s(current_path="/")
    assert home_live =~ ~s(<.ShellOperatorLanding />)

    assert ui_components =~ "def public_hero_section(assigns)"
    assert ui_components =~ "def public_proof_band(assigns)"
    assert ui_components =~ "def public_feature_row(assigns)"
    assert ui_components =~ "def public_closing_section(assigns)"

    assert story_surface =~ ~s(class="ui-preview-frame")
    assert visual_dna_story =~ ~s(<UiPanel surface="solid" padding="sm" class="space-y-3">)
    assert auth_scene_vue =~ ~s(<UiPanel class="ui-auth-scene__tile p-4" surface="solid">)

    assert dashboard_launchpad_vue =~ ~s(<section class="ui-dashboard-launchpad">)
    assert dashboard_launchpad_vue =~ ~s(<div class="ui-dashboard-launchpad__signals">)

    assert dashboard_launchpad_vue =~
             ~s(<UiPanel class="ui-dashboard-launchpad__tile" surface="solid" padding="sm">)

    assert shell_operator_landing_vue =~ ~s(<HomeHeroSection />)
    assert shell_operator_landing_vue =~ ~s(<HomeProofStrip />)
    assert shell_operator_landing_vue =~ ~s(<HomeClosingSection />)
    assert shell_operator_landing_vue =~ ~s(v-for="story in storySections")

    assert shell_operator_workspace_vue =~ "WorkspaceSidebar"
    assert shell_operator_workspace_vue =~ "InspectorPane"
    assert shell_operator_workspace_vue =~ "No accessible workspaces yet"
    assert workspace_sidebar_vue =~ "Projects"
    assert workspace_sidebar_vue =~ "Members"

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
    root_layout = read_file("lib/eboss_web/components/layouts/root.html.heex")
    ui_components = read_file("lib/eboss_web/components/ui_components.ex")
    ui_panel_vue = read_file("assets/vue/components/ui/UiPanel.vue")
    theme_toggle_vue = read_file("assets/vue/shell/shared/ThemeToggleButton.vue")
    use_theme = read_file("assets/vue/shell/shared/useTheme.ts")
    workspace_shell_vue = read_file("assets/vue/shell/workspace/ShellOperatorWorkspaceApp.vue")

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
    assert patterns_css =~ ".ui-auth-shell__frame"

    assert layouts =~ "ui-shell-header__inner"
    assert layouts =~ "ui-shell-main"
    assert ui_components =~ ~s("ui-panel-padding-md")
    assert ui_panel_vue =~ ~s(return "ui-panel-padding-md")
    assert root_layout =~ "window.EBossTheme ="
    assert theme_toggle_vue =~ ~s(class="ui-theme-toggle")
    assert use_theme =~ "export type ThemeMode"
    assert workspace_shell_vue =~ ~s(../shared/ThemeToggleButton.vue)

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

  test "public shell patterns define shared navigation, footer, and CTA framing" do
    patterns_css = File.read!(@patterns_css)
    browser_test_contracts = read_file("lib/eboss_web/browser_test_contracts.ex")
    layouts = read_file("lib/eboss_web/components/layouts.ex")
    home_live = read_file("lib/eboss_web/live/home_live.ex")
    design_system_live = read_file("lib/eboss_web/live/dev/design_system_live.ex")
    public_page_patterns = read_file("lib/eboss_web/public_page_patterns.ex")
    sign_in_live = read_file("lib/eboss_web/live/auth/sign_in_live.ex")
    register_live = read_file("lib/eboss_web/live/auth/register_live.ex")
    forgot_password_live = read_file("lib/eboss_web/live/auth/forgot_password_live.ex")
    shell_operator_landing_vue = read_file("assets/vue/shell/public/ShellOperatorLanding.vue")

    assert patterns_css =~ ".ui-public-shell__nav"
    assert patterns_css =~ ".ui-public-shell__controls"
    assert patterns_css =~ ".ui-shell-support"
    assert patterns_css =~ ".ui-public-cta"
    assert patterns_css =~ ".ui-public-footer"
    assert patterns_css =~ ".ui-public-footer__grid"
    assert patterns_css =~ ".ui-public-footer__link[data-active=\"true\"]"
    assert patterns_css =~ ".ui-public-page"
    assert patterns_css =~ ".ui-public-hero"
    assert patterns_css =~ ".ui-public-proof-band"
    assert patterns_css =~ ".ui-public-feature-row"
    assert patterns_css =~ ".ui-public-route-sequence__step-inner"
    assert patterns_css =~ ".ui-home-page"
    assert patterns_css =~ ".ui-home-hero"
    assert patterns_css =~ ".ui-home-proof-grid"
    assert patterns_css =~ ".ui-home-story"
    assert patterns_css =~ ".ui-home-story--reverse"
    assert patterns_css =~ ".ui-home-route-sequence__step-inner"
    assert patterns_css =~ ".ui-public-pattern-catalog"
    assert patterns_css =~ ".ui-public-pattern-card"
    assert patterns_css =~ ".ui-public-pattern-map"

    assert layouts =~
             ~s|attr(:shell_mode, :string, values: ~w(product public auth workspace), default: "product")|

    assert layouts =~ ~s(data-shell-mode={@shell_mode_attr})
    assert layouts =~ "workspace_shell?"
    assert layouts =~ ~s(class="ui-shell__workspace")
    assert layouts =~ ~s(data-public-shell-nav)
    assert layouts =~ ~s(data-public-shell-footer)
    assert layouts =~ "public_routes_nav_label()"
    assert layouts =~ "public_footer_label()"
    assert layouts =~ "public_shell_context_action()"
    assert layouts =~ "def public_cta_frame(assigns)"
    assert layouts =~ ~s(data-public-section-pattern={@section_pattern})

    assert home_live =~ ~s(shell_mode="public")
    assert home_live =~ ~s(current_path="/")
    assert home_live =~ ~s(<.ShellOperatorLanding />)

    assert shell_operator_landing_vue =~ ~s(<HomeHeroSection />)
    assert shell_operator_landing_vue =~ ~s(<HomeProofStrip />)
    assert shell_operator_landing_vue =~ ~s(<HomeClosingSection />)
    assert shell_operator_landing_vue =~ ~s(v-for="story in storySections")

    assert public_page_patterns =~ "defmodule EBossWeb.PublicPagePatterns"
    assert public_page_patterns =~ ~s(id: :hero)
    assert public_page_patterns =~ ~s(id: :proof_band)
    assert public_page_patterns =~ ~s(id: :feature_row)
    assert public_page_patterns =~ ~s(id: :cta_band)
    assert public_page_patterns =~ ~s(id: :closing_section)
    assert public_page_patterns =~ "def home_page_sections"

    assert design_system_live =~ ~s(id="public-patterns")
    assert design_system_live =~ "Reusable public section patterns"
    assert design_system_live =~ "Current home-page mapping"

    assert design_system_live =~
             "Repeat proof, feature, and CTA patterns. Keep hero and closing anchored."

    assert design_system_live =~ "public_section_patterns()"
    assert design_system_live =~ "public_home_page_sections()"
    assert design_system_live =~ "defp public_section_pattern_label(id)"

    assert browser_test_contracts =~
             "Stable browser-test contracts for the auth, public, and dashboard shell surfaces."

    assert browser_test_contracts =~ ~s(- `public-shell-context-action`)
    assert browser_test_contracts =~ ~s(def public_routes_nav_label)
    assert browser_test_contracts =~ ~s(def public_footer_label)
    assert browser_test_contracts =~ ~s(def home_feature_row_tempo)

    assert sign_in_live =~ ~s(shell_mode="auth")
    assert register_live =~ ~s(shell_mode="auth")
    assert forgot_password_live =~ ~s(shell_mode="auth")
  end

  test "dashboard shell pattern defines a reusable authenticated scaffold" do
    patterns_css = File.read!(@patterns_css)
    browser_test_contracts = read_file("lib/eboss_web/browser_test_contracts.ex")
    dashboard_components = read_file("lib/eboss_web/components/dashboard_components.ex")
    dashboard_live = read_file("lib/eboss_web/live/dashboard_live.ex")
    design_system_live = read_file("lib/eboss_web/live/dev/design_system_live.ex")
    eboss_web = read_file("lib/eboss_web.ex")

    assert patterns_css =~ ".ui-dashboard-shell"
    assert patterns_css =~ ".ui-dashboard-shell__nav"
    assert patterns_css =~ ".ui-dashboard-shell__nav-group"
    assert patterns_css =~ ".ui-dashboard-nav__item"
    assert patterns_css =~ ".ui-dashboard-nav__meta"
    assert patterns_css =~ ".ui-dashboard-page"
    assert patterns_css =~ ".ui-dashboard-page__rail"
    assert patterns_css =~ ".ui-dashboard-section"
    assert patterns_css =~ ".ui-dashboard-header"
    assert patterns_css =~ ".ui-dashboard-action-bar"
    assert patterns_css =~ ".ui-dashboard-panel-group"
    assert patterns_css =~ ".ui-dashboard-utility-strip"
    assert patterns_css =~ ".ui-dashboard-quick-actions"
    assert patterns_css =~ ".ui-dashboard-keycap"

    assert dashboard_components =~ "def dashboard_shell(assigns)"
    assert dashboard_components =~ "def dashboard_header(assigns)"
    assert dashboard_components =~ "def dashboard_section(assigns)"
    assert dashboard_components =~ "def dashboard_action_bar(assigns)"
    assert dashboard_components =~ "def dashboard_utility_strip(assigns)"
    assert dashboard_components =~ "def dashboard_quick_actions(assigns)"
    assert dashboard_components =~ "def dashboard_keycap(assigns)"
    assert dashboard_components =~ "def dashboard_panel_group(assigns)"
    assert dashboard_components =~ "dashboard_navigation_label()"
    assert dashboard_components =~ ~s(data-dashboard-shell)
    assert dashboard_components =~ ~s(data-dashboard-shell-sidebar)
    assert dashboard_components =~ ~s(data-dashboard-shell-main)
    assert dashboard_components =~ ~s(data-dashboard-shell-header)
    assert dashboard_components =~ ~s(data-dashboard-shell-body)
    assert dashboard_components =~ ~s(data-dashboard-nav-group={group.id})
    assert dashboard_components =~ ~s(data-dashboard-header)
    assert dashboard_components =~ ~s(data-dashboard-section)
    assert dashboard_components =~ ~s(data-dashboard-action-bar)
    assert dashboard_components =~ ~s(data-dashboard-utility-strip)
    assert dashboard_components =~ ~s(data-dashboard-quick-actions)
    assert dashboard_components =~ ~s(data-dashboard-keycap)
    assert dashboard_components =~ ~s(data-dashboard-panel-group={@columns})
    assert dashboard_components =~ ~s(data-dashboard-secondary-nav)
    assert dashboard_components =~ ~s(data-dashboard-nav-item={@item.id})

    assert dashboard_live =~ "<.ShellOperatorWorkspaceApp"
    assert dashboard_live =~ ~s(shell_mode="workspace")
    assert dashboard_live =~ "AppScope.resolve_workspace"
    assert dashboard_live =~ "current_scope_props"
    assert dashboard_live =~ "current_user_props"
    assert dashboard_live =~ "defp route_config"
    assert dashboard_live =~ "workspace_dashboard"
    assert dashboard_live =~ "workspace_projects"

    assert design_system_live =~ ~s(id="dashboard-commands")
    assert design_system_live =~ "Quick actions and utility cues stay light but task-oriented."
    assert design_system_live =~ "<.dashboard_utility_strip"
    assert design_system_live =~ "<.dashboard_quick_actions"

    assert browser_test_contracts =~ ~s(def dashboard_shell)
    assert browser_test_contracts =~ ~s(def dashboard_navigation_label)

    assert eboss_web =~ "import EBossWeb.DashboardComponents"
  end

  test "HEEx and Vue primitive contracts align for alerts and invalid field states" do
    core_components = read_file("lib/eboss_web/components/core_components.ex")
    ui_components = read_file("lib/eboss_web/components/ui_components.ex")
    auth_components = read_file("lib/eboss_web/components/auth_components.ex")

    magic_link_request_component =
      read_file("lib/eboss_web/live/auth/magic_link_request_component.ex")

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

    assert forgot_password_live =~ ~s|so-alert-panel so-alert-panel-success|
    assert forgot_password_live =~ "Check your email"

    assert forgot_password_live =~
             "We sent a link to reset your password. Check spam if you don't see it."

    refute forgot_password_live =~
             ~s|put_flash(:info, "If that account exists, we just emailed reset instructions.")|

    refute forgot_password_live =~ ~s|<.auth_feedback|

    assert magic_link_request_component =~ ~s|<.auth_feedback|

    assert magic_link_request_component =~
             ~s|message="If the account exists, a sign-in link is on the way."|

    refute magic_link_request_component =~
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
    browser_test_contracts = read_file("lib/eboss_web/browser_test_contracts.ex")
    auth_components = read_file("lib/eboss_web/components/auth_components.ex")
    design_system_live = read_file("lib/eboss_web/live/dev/design_system_live.ex")
    sign_in_live = read_file("lib/eboss_web/live/auth/sign_in_live.ex")

    password_sign_in_component =
      read_file("lib/eboss_web/live/auth/password_sign_in_component.ex")

    magic_link_request_component =
      read_file("lib/eboss_web/live/auth/magic_link_request_component.ex")

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
    assert patterns_css =~ ".ui-auth-shell__frame"
    assert patterns_css =~ ".ui-auth-shell__route"

    assert auth_components =~ "def auth_page(assigns)"
    assert auth_components =~ "def auth_page_footer(assigns)"
    assert auth_components =~ "authentication_routes_nav_label()"
    assert auth_components =~ "data-testid={BrowserTestContracts.auth_shell()}"
    assert auth_components =~ "ui-auth-shell so-theme text-[hsl(var(--so-foreground))]"
    assert auth_components =~ ~s(<.panel)
    assert auth_components =~ ~s(<.auth_nav current_path={@current_path} />)
    assert auth_components =~ ~s(class={["ui-auth-page so-auth-page", @class]})
    assert auth_components =~ ~s(class="ui-auth-card-muted so-auth-card-muted text-center")
    assert auth_components =~ "def auth_form(assigns)"
    assert auth_components =~ "def auth_submit(assigns)"

    refute auth_components =~ "ui-frame-card"
    refute auth_components =~ "ui-form-card"

    assert browser_test_contracts =~ ~s(- `auth-shell`)
    assert browser_test_contracts =~ ~s(def password_sign_in_form_label)
    assert browser_test_contracts =~ ~s(def magic_link_confirmation_form_label)

    assert design_system_live =~ "<.auth_page"
    assert sign_in_live =~ "<.auth_page"
    assert sign_in_live =~ "PasswordSignInComponent"
    assert sign_in_live =~ "MagicLinkRequestComponent"
    assert password_sign_in_component =~ "password_sign_in_form_label()"
    assert magic_link_request_component =~ "magic_link_request_form_label()"
    assert register_live =~ "<.auth_page"
    assert register_live =~ "register_form_label()"
    assert forgot_password_live =~ "<.auth_page"
    assert forgot_password_live =~ "forgot_password_form_label()"
    assert reset_password_live =~ "<.auth_page"
    assert reset_password_live =~ "reset_password_form_label()"
    assert confirm_live =~ "<.auth_page"
    assert confirm_live =~ "confirm_email_form_label()"
    assert magic_link_live =~ "<.auth_page"
    assert magic_link_live =~ "magic_link_confirmation_form_label()"
  end

  defp read_file(path) do
    @app_dir
    |> Path.join(path)
    |> File.read!()
  end
end
