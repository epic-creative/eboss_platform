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
    {:noreply, assign(socket, :magic_link_form, form)}
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
         |> assign(:magic_link_requested, true)
         |> put_flash(:info, "If that account exists, we just sent a magic link.")}

      {:ok, _result} ->
        {:noreply,
         socket
         |> assign(
           :magic_link_form,
           AuthForms.magic_link_request_form(nil, %{}, as: "magic_link_user")
         )
         |> assign(:magic_link_requested, true)
         |> put_flash(:info, "If that account exists, we just sent a magic link.")}

      {:error, form} ->
        {:noreply, assign(socket, :magic_link_form, form)}
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
        <div class="space-y-8">
          <.section_heading
            eyebrow="Account access"
            title="Sign in"
            subtitle="Your account session is handled by AshAuthentication. This page keeps the experience first-party."
            title_size="md"
          />
          <.auth_nav current_path="/sign-in" />

          <div class="space-y-8">
            <div class="space-y-4">
              <div class="space-y-1">
                <h2 class="ui-text-title" data-size="md">Password</h2>
                <p class="ui-text-body" data-size="sm" data-tone="soft">
                  Use the password flow for a normal sign-in session.
                </p>
              </div>

              <.form_errors form={@password_form} />

              <.form
                :let={form}
                for={@password_form}
                id="sign-in-password-form"
                phx-change="validate_password"
                phx-submit="submit_password"
                class="space-y-4"
              >
                <.input
                  field={form[:email]}
                  type="email"
                  label="Email"
                  autocomplete="section-password email"
                />
                <.input
                  field={form[:password]}
                  type="password"
                  label="Password"
                  autocomplete="section-password current-password"
                />

                <div class="flex items-center justify-between gap-4">
                  <a
                    href={~p"/forgot-password"}
                    class="ui-text-link"
                  >
                    Forgot your password?
                  </a>
                  <.button type="submit">
                    Continue
                  </.button>
                </div>
              </.form>
            </div>

            <div class="h-px bg-ui-border-subtle" />

            <div class="space-y-4">
              <div class="space-y-1">
                <h2 class="ui-text-title" data-size="md">Magic link</h2>
                <p class="ui-text-body" data-size="sm" data-tone="soft">
                  Request a one-time sign-in link for an existing account.
                </p>
              </div>

              <div
                :if={@magic_link_requested}
                class="ui-alert"
                data-tone="success"
                role="status"
                aria-live="polite"
                aria-atomic="true"
              >
                Check your email for the sign-in link.
              </div>

              <.form_errors form={@magic_link_form} />

              <.form
                :let={form}
                for={@magic_link_form}
                id="sign-in-magic-link-form"
                phx-change="validate_magic_link"
                phx-submit="submit_magic_link"
                class="space-y-4"
              >
                <.input
                  field={form[:email]}
                  type="email"
                  label="Email"
                  autocomplete="section-magic-link email"
                />

                <.button type="submit" variant="outline" tone="neutral">
                  Email me a magic link
                </.button>
              </.form>
            </div>
          </div>
        </div>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
