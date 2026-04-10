defmodule EBossWeb.Auth.SignInLive do
  use EBossWeb, :live_view

  alias EBossWeb.Auth.{MagicLinkRequestComponent, PasswordSignInComponent}
  alias EBossWeb.AuthComponents
  import AuthComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sign in")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={assigns[:current_user]}
    >
      <.auth_shell
        eyebrow="Custom authentication"
        title="Sign in without leaving the product"
        subtitle="Use your password for a full session or request a one-time magic link for a faster return."
        detail_one="Password sign-in still uses AshAuthentication sign-in tokens"
        detail_two="Magic links stay sign-in only for existing accounts"
        detail_three="Every session lands on a dedicated dashboard shell"
      >
        <.auth_page
          eyebrow="Account access"
          title="Sign in"
          subtitle="Choose your entry path. Password and magic-link access stay inside the same first-party shell."
          current_path="/sign-in"
        >
          <div class="ui-auth-flow-stack">
            <.live_component module={PasswordSignInComponent} id="password-sign-in" />

            <div class="ui-auth-flow-divider" />

            <.live_component module={MagicLinkRequestComponent} id="magic-link-request" />
          </div>

          <:footer>
            <.auth_page_footer
              prompt="Need a fresh account?"
              link_text="Register"
              link_href={~p"/register"}
              note="Password and magic-link access land in the same authenticated dashboard shell."
            />
          </:footer>
        </.auth_page>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
