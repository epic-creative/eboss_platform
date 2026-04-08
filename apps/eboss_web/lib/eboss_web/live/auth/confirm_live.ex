defmodule EBossWeb.Auth.ConfirmLive do
  use EBossWeb, :live_view

  alias AshPhoenix.Form
  alias EBossWeb.{AuthComponents, AuthForms}
  import AuthComponents

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Confirm email")
     |> assign(:token, token)
     |> assign(:trigger_action, false)
     |> assign(:form, AuthForms.confirm_form(token))}
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
        eyebrow="Account confirmation"
        title="Confirm your email address"
        subtitle="The confirmation token stays on the public URL while the final verification is posted to AshAuthentication."
        detail_one="Confirmation uses the existing add-on action"
        detail_two="Unconfirmed accounts still stay inside the first-party UX"
        detail_three="Successful confirmations land on the dashboard shell"
      >
        <div class="space-y-8">
          <div class="space-y-3">
            <p class="text-xs font-semibold uppercase tracking-[0.28em] text-amber-700">
              Email confirmation
            </p>
            <h1 class="text-3xl font-semibold tracking-tight text-stone-950">Confirm your account</h1>
            <p class="text-sm leading-6 text-stone-600">
              Use the button below to verify the email address attached to this account.
            </p>
          </div>

          <.form_errors form={@form} />

          <.form
            :let={form}
            for={@form}
            id="confirm-form"
            phx-submit="submit"
            phx-trigger-action={@trigger_action}
            action={AuthForms.auth_path(@socket, AuthForms.confirmation_strategy!(), :confirm)}
            method="post"
            class="space-y-5"
          >
            <input type="hidden" name={form[:confirm].name} value={@token} />

            <button
              type="submit"
              class="rounded-full bg-stone-950 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-stone-800"
            >
              Confirm email
            </button>
          </.form>
        </div>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
