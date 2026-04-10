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
      shell_mode="public"
      current_path="/forgot-password"
    >
      <.auth_shell
        eyebrow="Password recovery"
        title="Send a reset link"
        subtitle="The request flow uses AshAuthentication’s reset action while keeping the page itself custom."
        detail_one="Email delivery still goes through the configured sender"
        detail_two="Reset links land on the same public route contract"
        detail_three="Successful resets create an authenticated session and go to the dashboard"
      >
        <.auth_page
          eyebrow="Password reset"
          title="Forgot your password?"
          subtitle="Enter the email for your account and we will send a reset link if it exists."
          current_path="/forgot-password"
        >
          <.auth_feedback
            :if={@request_sent}
            tone="success"
            data-feedback="success"
            title="Request received."
            message="If the account exists, reset instructions are on the way."
          />

          <.form_errors form={@form} />

          <.auth_form
            :let={form}
            for={@form}
            id="forgot-password-form"
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
                label="Email reset link"
                busy_label="Sending reset link..."
              />
            </:actions>
          </.auth_form>

          <:footer>
            <.auth_page_footer
              prompt="Remembered your password?"
              link_text="Back to sign in"
              link_href={~p"/sign-in"}
              note="Reset emails return to the same public auth shell before the session resumes."
            />
          </:footer>
        </.auth_page>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
