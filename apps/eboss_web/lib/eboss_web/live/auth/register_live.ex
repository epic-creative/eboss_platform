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
    <Layouts.app flash={@flash} current_scope={@current_scope} current_user={@current_user}>
      <.auth_shell
        eyebrow="Custom authentication"
        title="Create a first-party account"
        subtitle="Registration is kept on the password strategy so usernames, confirmation, and session handling stay aligned."
        detail_one="Username validation uses the existing accounts boundary rules"
        detail_two="New registrations sign in through Ash sign-in tokens"
        detail_three="Email confirmation links keep the same public route contract"
      >
        <div class="space-y-8">
          <div class="space-y-3">
            <p class="text-xs font-semibold uppercase tracking-[0.28em] text-amber-700">
              New account
            </p>
            <h1 class="text-3xl font-semibold tracking-tight text-stone-950">Register</h1>
            <p class="text-sm leading-6 text-stone-600">
              Create your account with an email, a stable username, and a password you can rotate later.
            </p>
            <.auth_nav current_path="/register" />
          </div>

          <.form_errors form={@form} />

          <.form
            :let={form}
            for={@form}
            id="register-form"
            phx-change="validate"
            phx-submit="submit"
            class="space-y-4"
          >
            <.input field={form[:email]} type="email" label="Email" autocomplete="email" />
            <.input field={form[:username]} type="text" label="Username" autocomplete="username" />
            <.input
              field={form[:password]}
              type="password"
              label="Password"
              autocomplete="new-password"
            />
            <.input
              field={form[:password_confirmation]}
              type="password"
              label="Confirm password"
              autocomplete="new-password"
            />

            <div class="flex items-center justify-between gap-4">
              <p class="text-sm text-stone-500">
                Already have an account? <a
                  href={~p"/sign-in"}
                  class="font-medium text-sky-700 hover:text-sky-900"
                >Sign in</a>.
              </p>
              <button
                type="submit"
                class="rounded-full bg-stone-950 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-stone-800"
              >
                Create account
              </button>
            </div>
          </.form>
        </div>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
