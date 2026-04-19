defmodule EBossWeb.Auth.RegisterLive do
  use EBossWeb, :live_view

  alias AshPhoenix.Form
  alias EBossWeb.{AuthComponents, AuthForms, BrowserTestContracts}
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
      <.auth_shell current_path="/register">
        <.auth_page
          title="Create your account"
          subtitle="Start building your workspace"
        >
          <div class="ui-auth-card so-auth-card p-4">
            <.form_errors form={@form} />

            <.auth_form
              :let={form}
              for={@form}
              id="register-form"
              aria-label={BrowserTestContracts.register_form_label()}
              phx-change="validate"
              phx-submit="submit"
            >
              <.auth_username_input
                field={form[:username]}
                hint="This becomes your workspace identifier."
              />
              <.auth_email_input field={form[:email]} autocomplete="email" />
              <.auth_password_input
                field={form[:password]}
                autocomplete="new-password"
                hint="At least 15 characters, or 8 with a number and letter."
              />
              <.auth_password_input
                field={form[:password_confirmation]}
                label="Confirm password"
                hint="Repeat the same password exactly."
                autocomplete="new-password"
              />

              <p class="text-[11px] leading-relaxed text-[hsl(var(--so-muted-foreground))]">
                By creating an account, you agree to the <a
                  href="#"
                  class="text-[hsl(var(--so-primary))] hover:underline"
                >Terms of Service</a>.
              </p>

              <:actions>
                <.auth_submit
                  label="Create account"
                  busy_label="Creating account..."
                />
              </:actions>
            </.auth_form>
          </div>

          <:footer>
            <.auth_page_footer
              prompt="Already have an account?"
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
