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
     |> assign(:password_form, AuthForms.password_sign_in_form())
     |> assign(:magic_link_form, AuthForms.magic_link_request_form())
     |> assign(:magic_link_requested, false)}
  end

  @impl true
  def handle_event("validate_password", %{"user" => params}, socket) do
    form = Form.validate(socket.assigns.password_form, params, errors: false)
    {:noreply, assign(socket, :password_form, form)}
  end

  def handle_event("submit_password", %{"user" => params}, socket) do
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

  def handle_event("validate_magic_link", %{"user" => params}, socket) do
    form = Form.validate(socket.assigns.magic_link_form, params, errors: false)
    {:noreply, assign(socket, :magic_link_form, form)}
  end

  def handle_event("submit_magic_link", %{"user" => params}, socket) do
    case Form.submit(socket.assigns.magic_link_form, params: params) do
      :ok ->
        {:noreply,
         socket
         |> assign(:magic_link_form, AuthForms.magic_link_request_form())
         |> assign(:magic_link_requested, true)
         |> put_flash(:info, "If that account exists, we just sent a magic link.")}

      {:ok, _result} ->
        {:noreply,
         socket
         |> assign(:magic_link_form, AuthForms.magic_link_request_form())
         |> assign(:magic_link_requested, true)
         |> put_flash(:info, "If that account exists, we just sent a magic link.")}

      {:error, form} ->
        {:noreply, assign(socket, :magic_link_form, form)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} current_user={@current_user}>
      <.auth_shell
        eyebrow="Custom authentication"
        title="Sign in without leaving the product"
        subtitle="Use your password for a full session or request a one-time magic link for a faster return."
        detail_one="Password sign-in still uses AshAuthentication sign-in tokens"
        detail_two="Magic links stay sign-in only for existing accounts"
        detail_three="Every session lands on a dedicated dashboard shell"
      >
        <div class="space-y-8">
          <div class="space-y-3">
            <p class="text-xs font-semibold uppercase tracking-[0.28em] text-amber-700">
              Account access
            </p>
            <h1 class="text-3xl font-semibold tracking-tight text-stone-950">Sign in</h1>
            <p class="text-sm leading-6 text-stone-600">
              Your account session is handled by AshAuthentication. This page keeps the experience first-party.
            </p>
            <.auth_nav current_path="/sign-in" />
          </div>

          <div class="space-y-8">
            <div class="space-y-4">
              <div class="space-y-1">
                <h2 class="text-lg font-semibold text-stone-950">Password</h2>
                <p class="text-sm text-stone-600">
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
                <.input field={form[:email]} type="email" label="Email" autocomplete="email" />
                <.input
                  field={form[:password]}
                  type="password"
                  label="Password"
                  autocomplete="current-password"
                />

                <div class="flex items-center justify-between gap-4">
                  <a
                    href={~p"/forgot-password"}
                    class="text-sm font-medium text-sky-700 hover:text-sky-900"
                  >
                    Forgot your password?
                  </a>
                  <button
                    type="submit"
                    class="rounded-full bg-stone-950 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-stone-800"
                  >
                    Continue
                  </button>
                </div>
              </.form>
            </div>

            <div class="h-px bg-stone-200" />

            <div class="space-y-4">
              <div class="space-y-1">
                <h2 class="text-lg font-semibold text-stone-950">Magic link</h2>
                <p class="text-sm text-stone-600">
                  Request a one-time sign-in link for an existing account.
                </p>
              </div>

              <div
                :if={@magic_link_requested}
                class="rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800"
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
                <.input field={form[:email]} type="email" label="Email" autocomplete="email" />

                <button
                  type="submit"
                  class="rounded-full border border-stone-300 bg-white px-5 py-2.5 text-sm font-semibold text-stone-700 transition hover:border-stone-400 hover:text-stone-950"
                >
                  Email me a magic link
                </button>
              </.form>
            </div>
          </div>
        </div>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
