defmodule EBossWeb.Auth.SignInLive do
  use EBossWeb, :live_view

  alias AshPhoenix.Form
  alias EBossWeb.{AuthComponents, AuthForms}
  import AuthComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sign in")
     |> assign(:password_form, AuthForms.password_sign_in_form(nil, %{}, as: "password_user"))
     |> assign(
       :magic_link_form,
       AuthForms.magic_link_request_form(nil, %{}, as: "magic_link_user")
     )
     |> assign(:magic_link_requested, false)}
  end

  @impl true
  def handle_event("validate_password", %{"password_user" => params}, socket) do
    form = Form.validate(socket.assigns.password_form, params, errors: false)
    {:noreply, assign(socket, :password_form, form)}
  end

  def handle_event("submit_password", %{"password_user" => params}, socket) do
    case Form.submit(socket.assigns.password_form, params: params, read_one?: true) do
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
        {:noreply, assign(socket, :password_form, Form.clear_value(form, :password))}
    end
  end

  def handle_event("validate_magic_link", %{"magic_link_user" => params}, socket) do
    form = Form.validate(socket.assigns.magic_link_form, params, errors: false)

    {:noreply,
     socket
     |> assign(:magic_link_form, form)
     |> assign(:magic_link_requested, false)}
  end

  def handle_event("submit_magic_link", %{"magic_link_user" => params}, socket) do
    case Form.submit(socket.assigns.magic_link_form, params: params) do
      :ok ->
        {:noreply,
         socket
         |> assign(
           :magic_link_form,
           AuthForms.magic_link_request_form(nil, %{}, as: "magic_link_user")
         )
         |> assign(:magic_link_requested, true)}

      {:ok, _result} ->
        {:noreply,
         socket
         |> assign(
           :magic_link_form,
           AuthForms.magic_link_request_form(nil, %{}, as: "magic_link_user")
         )
         |> assign(:magic_link_requested, true)}

      {:error, form} ->
        {:noreply,
         socket
         |> assign(:magic_link_form, form)
         |> assign(:magic_link_requested, false)}
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
            <section class="ui-auth-flow-section" aria-labelledby="sign-in-password-heading">
              <div class="space-y-1">
                <h2 id="sign-in-password-heading" class="ui-text-title" data-size="md">
                  Password
                </h2>
                <p class="ui-text-body" data-size="sm" data-tone="soft">
                  Use the password flow for a normal sign-in session.
                </p>
              </div>

              <.form_errors form={@password_form} />

              <.auth_form
                :let={form}
                for={@password_form}
                id="sign-in-password-form"
                phx-change="validate_password"
                phx-submit="submit_password"
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

            <div class="ui-auth-flow-divider" />

            <section class="ui-auth-flow-section" aria-labelledby="sign-in-magic-link-heading">
              <div class="space-y-1">
                <h2 id="sign-in-magic-link-heading" class="ui-text-title" data-size="md">
                  Magic link
                </h2>
                <p class="ui-text-body" data-size="sm" data-tone="soft">
                  Request a one-time sign-in link for an existing account.
                </p>
              </div>

              <.auth_feedback
                :if={@magic_link_requested}
                tone="success"
                data-feedback="success"
                title="Request received."
                message="If the account exists, a sign-in link is on the way."
              />

              <.form_errors form={@magic_link_form} />

              <.auth_form
                :let={form}
                for={@magic_link_form}
                id="sign-in-magic-link-form"
                phx-change="validate_magic_link"
                phx-submit="submit_magic_link"
              >
                <.auth_email_input
                  field={form[:email]}
                  autocomplete="section-magic-link email"
                  hint="Use the email address tied to your account. We only send sign-in links when it exists."
                />

                <:actions>
                  <.auth_submit
                    label="Email me a magic link"
                    busy_label="Sending link..."
                    variant="outline"
                    tone="neutral"
                  />
                </:actions>
              </.auth_form>
            </section>
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
