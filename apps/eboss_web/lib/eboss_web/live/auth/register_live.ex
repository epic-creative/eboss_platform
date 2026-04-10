defmodule EBossWeb.Auth.RegisterLive do
  use EBossWeb, :live_view

  alias AshPhoenix.Form
  alias EBossWeb.{AuthComponents, AuthForms}
  import AuthComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Register")
     |> assign(:form, AuthForms.register_form())}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    {:noreply, assign(socket, :form, Form.validate(socket.assigns.form, params, errors: false))}
  end

  def handle_event("submit", %{"user" => params}, socket) do
    case Form.submit(socket.assigns.form, params: params, read_one?: true) do
      {:ok, user} ->
        {:noreply,
         redirect(socket,
           to:
             AuthForms.auth_path(
               socket,
               AuthForms.password_strategy!(),
               :sign_in_with_token,
               %{token: user.__metadata__.token}
             )
         )}

      {:error, form} ->
        {:noreply, assign(socket, :form, Form.clear_value(form, :password_confirmation))}
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
      current_path="/register"
    >
      <.auth_shell
        eyebrow="Custom authentication"
        title="Create a first-party account"
        subtitle="Registration is kept on the password strategy so usernames, confirmation, and session handling stay aligned."
        detail_one="Username validation uses the existing accounts boundary rules"
        detail_two="New registrations sign in through Ash sign-in tokens"
        detail_three="Email confirmation links keep the same public route contract"
      >
        <.auth_page
          eyebrow="New account"
          title="Register"
          subtitle="Create your account with the same shell, spacing, and route hierarchy used across every auth step."
          current_path="/register"
        >
          <.form_errors form={@form} />

          <.auth_form
            :let={form}
            for={@form}
            id="register-form"
            phx-change="validate"
            phx-submit="submit"
          >
            <.auth_email_input field={form[:email]} autocomplete="email" />
            <.auth_username_input field={form[:username]} />
            <.auth_password_input
              field={form[:password]}
              autocomplete="new-password"
              hint="Use at least 8 characters."
            />
            <.auth_password_input
              field={form[:password_confirmation]}
              label="Confirm password"
              hint="Repeat the same password exactly."
              autocomplete="new-password"
            />

            <:actions>
              <.auth_submit
                label="Create account"
                busy_label="Creating account..."
              />
            </:actions>
          </.auth_form>

          <:footer>
            <.auth_page_footer
              prompt="Already have access?"
              link_text="Sign in"
              link_href={~p"/sign-in"}
              note="New accounts confirm email on the same public route family before returning to the product shell."
            />
          </:footer>
        </.auth_page>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
