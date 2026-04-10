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
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={assigns[:current_user]}
    >
      <.auth_shell
        eyebrow="Account confirmation"
        title="Confirm your email address"
        subtitle="The confirmation token stays on the public URL while the final verification is posted to AshAuthentication."
        detail_one="Confirmation uses the existing add-on action"
        detail_two="Unconfirmed accounts still stay inside the first-party UX"
        detail_three="Successful confirmations land on the dashboard shell"
      >
        <div class="space-y-8">
          <.section_heading
            eyebrow="Email confirmation"
            title="Confirm your account"
            subtitle="Use the button below to verify the email address attached to this account."
            title_size="md"
          />

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

            <.button type="submit">
              Confirm email
            </.button>
          </.form>
        </div>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
