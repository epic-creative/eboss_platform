defmodule EBossWeb.BrowserTestContracts do
  @moduledoc """
  Stable browser-test contracts for the auth, public, and dashboard shell surfaces.

  Prefer accessible selectors first:

  - `navigation` named `"Public routes"`
  - `navigation` named `"Authentication routes"`
  - `region` named `"Dashboard shell"`
  - `complementary` named `"Dashboard sidebar"`
  - `navigation` named `"Dashboard navigation"`
  - `region` named `"Dashboard workspace"`
  - `region` named `"Dashboard launch surface"`
  - `region` named `"Dashboard structure surface"`
  - `region` named `"Dashboard state surface"`
  - `region` named `"Dashboard command surface"`
  - `navigation` named `"Dashboard quick actions"`
  - `region` named `"Dashboard empty state"`
  - `region` named `"Dashboard loading state"`
  - `region` named `"Dashboard error state"`
  - `contentinfo` named `"Public shell footer"`
  - `form` landmarks using the labels returned by this module

  Use explicit `data-testid` hooks only for structural regions or route-dependent
  controls without a stable accessible name:

  - `auth-shell`
  - `dashboard-shell`
  - `public-shell-context-action`
  - `home-hero`
  - `home-proof-band`
  - `home-feature-row-continuity`
  - `home-feature-row-tempo`
  - `home-closing`
  """

  def public_routes_nav_label, do: "Public routes"
  def authentication_routes_nav_label, do: "Authentication routes"
  def dashboard_shell_label, do: "Dashboard shell"
  def dashboard_sidebar_label, do: "Dashboard sidebar"
  def dashboard_navigation_label, do: "Dashboard navigation"
  def dashboard_workspace_label, do: "Dashboard workspace"
  def dashboard_command_surface_label, do: "Dashboard command surface"
  def dashboard_quick_actions_label, do: "Dashboard quick actions"
  def public_footer_label, do: "Public shell footer"

  def auth_shell, do: "auth-shell"
  def dashboard_shell, do: "dashboard-shell"
  def public_shell_context_action, do: "public-shell-context-action"
  def home_hero, do: "home-hero"
  def home_proof_band, do: "home-proof-band"
  def home_feature_row_continuity, do: "home-feature-row-continuity"
  def home_feature_row_tempo, do: "home-feature-row-tempo"
  def home_closing, do: "home-closing"

  def password_sign_in_form_label, do: "Password sign-in"
  def magic_link_request_form_label, do: "Magic-link request"
  def register_form_label, do: "Register account"
  def forgot_password_form_label, do: "Forgot password request"
  def reset_password_form_label, do: "Reset password"
  def confirm_email_form_label, do: "Confirm email"
  def magic_link_confirmation_form_label, do: "Magic-link confirmation"

  def dashboard_section_label(section) do
    case to_string(section) do
      "launchpad" -> "Dashboard launch surface"
      "structure" -> "Dashboard structure surface"
      "states" -> "Dashboard state surface"
      other -> raise ArgumentError, "unknown dashboard section contract: #{inspect(other)}"
    end
  end

  def dashboard_state_label(variant) do
    case to_string(variant) do
      "empty" -> "Dashboard empty state"
      "loading" -> "Dashboard loading state"
      "error" -> "Dashboard error state"
      other -> raise ArgumentError, "unknown dashboard state contract: #{inspect(other)}"
    end
  end
end
