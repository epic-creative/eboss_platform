defmodule EBossWeb.Auth.ConfirmLive do
  use EBossWeb, :live_view

  alias AshPhoenix.Form
  alias EBossWeb.{AuthComponents, AuthForms, BrowserTestContracts}
  import AuthComponents

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Confirm email")
     |> assign(:token, token)
     |> assign(:trigger_action, false)
     |> assign(:form, AuthForms.confirm_form(token))}
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
      current_path="/confirm"
    >
      <.auth_shell current_path="/confirm">
        <.auth_page
          title="Confirm account"
          subtitle="Use the button below to verify your email address."
        >
          <div class="so-auth-card p-4">
            <.form_errors form={@form} />

            <.auth_form
              :let={form}
              for={@form}
              id="confirm-form"
              aria-label={BrowserTestContracts.confirm_email_form_label()}
              phx-submit="submit"
              phx-trigger-action={@trigger_action}
              action={AuthForms.auth_path(@socket, AuthForms.confirmation_strategy!(), :confirm)}
              method="post"
            >
              <input type="hidden" name={form[:confirm].name} value={@token} />

              <:actions>
                <.auth_submit
                  label="Confirm email"
                  busy_label="Confirming email..."
                />
              </:actions>
            </.auth_form>
          </div>

          <:footer>
            <.auth_page_footer
              prompt="Need to return to sign in?"
              link_text="Sign in"
              link_href={~p"/sign-in"}
            />
          </:footer>
        </.auth_page>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
