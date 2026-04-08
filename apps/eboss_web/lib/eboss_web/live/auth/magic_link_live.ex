defmodule EBossWeb.Auth.MagicLinkLive do
  use EBossWeb, :live_view

  alias AshPhoenix.Form
  alias EBossWeb.{AuthComponents, AuthForms}
  import AuthComponents

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Magic link")
     |> assign(:token, token)
     |> assign(:trigger_action, false)
     |> assign(:form, AuthForms.magic_link_consume_form(token))}
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    form = Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form, trigger_action: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} current_user={@current_user}>
      <.auth_shell
        eyebrow="Magic link access"
        title="Finish signing in"
        subtitle="Magic links stay sign-in only in v1, so this route is a simple confirmation step into a normal authenticated session."
        detail_one="The token stays in the standard AshAuthentication action"
        detail_two="No parallel custom JSON auth endpoint is introduced"
        detail_three="The final destination is the same dashboard shell as password sign-in"
      >
        <div class="space-y-8">
          <div class="space-y-3">
            <p class="text-xs font-semibold uppercase tracking-[0.28em] text-amber-700">Magic link</p>
            <h1 class="text-3xl font-semibold tracking-tight text-stone-950">
              Use this sign-in link
            </h1>
            <p class="text-sm leading-6 text-stone-600">
              Confirm the sign-in and we will take you into the authenticated part of the app.
            </p>
          </div>

          <.form_errors form={@form} />

          <.form
            :let={form}
            for={@form}
            id="magic-link-form"
            phx-submit="submit"
            phx-trigger-action={@trigger_action}
            action={AuthForms.auth_path(@socket, AuthForms.magic_link_strategy!(), :sign_in)}
            method="post"
            class="space-y-5"
          >
            <input type="hidden" name={form[:token].name} value={@token} />

            <button
              type="submit"
              class="rounded-full bg-stone-950 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-stone-800"
            >
              Sign me in
            </button>
          </.form>
        </div>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
