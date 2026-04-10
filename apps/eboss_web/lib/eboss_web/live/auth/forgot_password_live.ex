defmodule EBossWeb.Auth.ForgotPasswordLive do
  use EBossWeb, :live_view

  alias AshPhoenix.Form
  alias EBossWeb.{AuthComponents, AuthForms}
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
    {:noreply, assign(socket, :form, Form.validate(socket.assigns.form, params, errors: false))}
  end

  def handle_event("submit", %{"user" => params}, socket) do
    case Form.submit(socket.assigns.form, params: params) do
      :ok ->
        {:noreply,
         socket
         |> assign(:form, AuthForms.forgot_password_form())
         |> assign(:request_sent, true)
         |> put_flash(:info, "If that account exists, we just emailed reset instructions.")}

      {:ok, _result} ->
        {:noreply,
         socket
         |> assign(:form, AuthForms.forgot_password_form())
         |> assign(:request_sent, true)
         |> put_flash(:info, "If that account exists, we just emailed reset instructions.")}

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
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
        eyebrow="Password recovery"
        title="Send a reset link"
        subtitle="The request flow uses AshAuthentication’s reset action while keeping the page itself custom."
        detail_one="Email delivery still goes through the configured sender"
        detail_two="Reset links land on the same public route contract"
        detail_three="Successful resets create an authenticated session and go to the dashboard"
      >
        <div class="space-y-8">
          <.section_heading
            eyebrow="Password reset"
            title="Forgot your password?"
            subtitle="Enter the email for your account and we will send a reset link if it exists."
            title_size="md"
          />
          <.auth_nav current_path="/forgot-password" />

          <.alert :if={@request_sent} tone="success" role="status" live="polite">
            Reset instructions are on the way if the account exists.
          </.alert>

          <.form_errors form={@form} />

          <.form
            :let={form}
            for={@form}
            id="forgot-password-form"
            phx-change="validate"
            phx-submit="submit"
            class="space-y-4"
          >
            <.input field={form[:email]} type="email" label="Email" autocomplete="email" />

            <div class="flex items-center justify-between gap-4">
              <a
                href={~p"/sign-in"}
                class="ui-text-link"
              >
                Back to sign in
              </a>
              <.button type="submit">
                Email reset link
              </.button>
            </div>
          </.form>
        </div>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
