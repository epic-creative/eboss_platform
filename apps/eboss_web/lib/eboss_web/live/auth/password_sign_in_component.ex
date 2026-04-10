defmodule EBossWeb.Auth.PasswordSignInComponent do
  use EBossWeb, :live_component

  alias AshPhoenix.Form
  alias EBossWeb.{AuthComponents, AuthForms, BrowserTestContracts}
  import AuthComponents

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :form, AuthForms.password_sign_in_form(nil, %{}, as: "password_user"))}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("validate_password", %{"password_user" => params}, socket) do
    form = Form.validate(socket.assigns.form, params, errors: false)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit_password", %{"password_user" => params}, socket) do
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
        {:noreply, assign(socket, :form, Form.clear_value(form, :password))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="ui-auth-flow-section" aria-labelledby="sign-in-password-heading">
      <div class="space-y-1">
        <h2 id="sign-in-password-heading" class="ui-text-title" data-size="md">
          Password
        </h2>
        <p class="ui-text-body" data-size="sm" data-tone="soft">
          Use the password flow for a normal sign-in session.
        </p>
      </div>

      <.form_errors form={@form} />

      <.auth_form
        :let={form}
        for={@form}
        id="sign-in-password-form"
        aria-label={BrowserTestContracts.password_sign_in_form_label()}
        phx-change="validate_password"
        phx-submit="submit_password"
        phx-target={@myself}
        actions_layout="between"
      >
        <.auth_email_input
          field={form[:email]}
          autocomplete="section-password email"
        />
        <.auth_password_input
          field={form[:password]}
          autocomplete="section-password current-password"
        />

        <:actions>
          <a
            href={~p"/forgot-password"}
            class="ui-text-link"
          >
            Forgot your password?
          </a>
          <.auth_submit
            label="Continue"
            busy_label="Signing in..."
          />
        </:actions>
      </.auth_form>
    </section>
    """
  end
end
