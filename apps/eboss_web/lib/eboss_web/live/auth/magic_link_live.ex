defmodule EBossWeb.Auth.MagicLinkLive do
  use EBossWeb, :live_view

  alias AshPhoenix.Form
  alias EBossWeb.{AuthComponents, AuthForms, BrowserTestContracts}
  import AuthComponents

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Magic link")
     |> assign(:token, token)
     |> assign(:trigger_action, false)
     |> assign(:form, AuthForms.magic_link_consume_form(token))}
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    form = Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form, trigger_action: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={assigns[:current_user]}
      shell_mode="workspace"
      current_path="/magic-link"
    >
      <.auth_shell current_path="/magic-link">
        <.auth_page
          title="Use this sign-in link"
          subtitle="Confirm the sign-in and we’ll take you into the authenticated part of the app."
        >
          <div class="ui-auth-card so-auth-card p-4">
            <.form_errors form={@form} />

            <.auth_form
              :let={form}
              for={@form}
              id="magic-link-form"
              aria-label={BrowserTestContracts.magic_link_confirmation_form_label()}
              phx-submit="submit"
              phx-trigger-action={@trigger_action}
              action={AuthForms.auth_path(@socket, AuthForms.magic_link_strategy!(), :sign_in)}
              method="post"
            >
              <input type="hidden" name={form[:token].name} value={@token} />

              <:actions>
                <.auth_submit
                  label="Sign in"
                  busy_label="Signing you in..."
                />
              </:actions>
            </.auth_form>
          </div>

          <:footer>
            <.auth_page_footer
              prompt="Prefer a standard credential flow?"
              link_text="Sign in with password"
              link_href={~p"/sign-in"}
            />
          </:footer>
        </.auth_page>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
