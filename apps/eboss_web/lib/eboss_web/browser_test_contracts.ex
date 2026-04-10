defmodule EBossWeb.BrowserTestContracts do
  @moduledoc """
  Stable browser-test contracts for the auth, public, and dashboard shell surfaces.

  Prefer accessible selectors first:

  - `navigation` named `"Public routes"`
  - `navigation` named `"Authentication routes"`
  - `navigation` named `"Dashboard navigation"`
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
  def dashboard_navigation_label, do: "Dashboard navigation"
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
end
