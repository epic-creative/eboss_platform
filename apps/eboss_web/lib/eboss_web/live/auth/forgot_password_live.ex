defmodule EBossWeb.Auth.ForgotPasswordLive do
  use EBossWeb, :live_view

  alias AshPhoenix.Form
  alias EBossWeb.{AuthComponents, AuthForms, BrowserTestContracts}
  import AuthComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Forgot password")
     |> assign(:form, AuthForms.forgot_password_form())
     |> assign(:request_sent, false)}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    {:noreply,
     socket
     |> assign(:form, Form.validate(socket.assigns.form, params, errors: false))
     |> assign(:request_sent, false)}
  end

  def handle_event("submit", %{"user" => params}, socket) do
    case Form.submit(socket.assigns.form, params: params) do
      :ok ->
        {:noreply,
         socket
         |> assign(:form, AuthForms.forgot_password_form())
         |> assign(:request_sent, true)}

      {:ok, _result} ->
        {:noreply,
         socket
         |> assign(:form, AuthForms.forgot_password_form())
         |> assign(:request_sent, true)}

      {:error, form} ->
        {:noreply, socket |> assign(:form, form) |> assign(:request_sent, false)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={assigns[:current_user]}
      shell_mode="auth"
      current_path="/forgot-password"
    >
      <.auth_shell current_path="/forgot-password">
        <.auth_page
          title="Reset your password"
          subtitle="Enter your email and we'll send a reset link."
        >
          <div class="ui-auth-card so-auth-card p-4">
            <div
              :if={@request_sent}
              class="ui-alert-panel ui-alert-panel-success so-alert-panel so-alert-panel-success space-y-3 text-center"
            >
              <p class="text-sm font-medium text-[hsl(var(--so-foreground))]">Check your email</p>
              <p class="text-xs text-[hsl(var(--so-muted-foreground))]">
                We sent a link to reset your password. Check spam if you don't see it.
              </p>
              <.button navigate={~p"/sign-in"} variant="outline" tone="neutral" size="sm">
                Return to sign in
              </.button>
            </div>

            <div :if={!@request_sent}>
              <.form_errors form={@form} />

              <.auth_form
                :let={form}
                for={@form}
                id="forgot-password-form"
                aria-label={BrowserTestContracts.forgot_password_form_label()}
                phx-change="validate"
                phx-submit="submit"
              >
                <.auth_email_input
                  field={form[:email]}
                  autocomplete="email"
                  hint="Use the email address tied to your account. We only send reset links when it exists."
                />

                <:actions>
                  <.auth_submit
                    label="Send password reset email"
                    busy_label="Sending reset link..."
                  />
                </:actions>
              </.auth_form>
            </div>
          </div>

          <:footer>
            <div class="ui-auth-card-muted so-auth-card-muted text-center">
              <p class="text-xs text-[hsl(var(--so-muted-foreground))]">
                <a
                  href={~p"/sign-in"}
                  class="font-medium text-[hsl(var(--so-primary))] hover:underline"
                >
                  Back to sign in
                </a>
              </p>
            </div>
          </:footer>
        </.auth_page>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
