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
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={assigns[:current_user]}
    >
      <.auth_shell
        eyebrow="Magic link access"
        title="Finish signing in"
        subtitle="Magic links stay sign-in only in v1, so this route is a simple confirmation step into a normal authenticated session."
        detail_one="The token stays in the standard AshAuthentication action"
        detail_two="No parallel custom JSON auth endpoint is introduced"
        detail_three="The final destination is the same dashboard shell as password sign-in"
      >
        <.auth_page
          eyebrow="Magic link"
          title="Use this sign-in link"
          subtitle="Confirm the sign-in and we will take you into the authenticated part of the app."
        >
          <.form_errors form={@form} />

          <.auth_form
            :let={form}
            for={@form}
            id="magic-link-form"
            phx-submit="submit"
            phx-trigger-action={@trigger_action}
            action={AuthForms.auth_path(@socket, AuthForms.magic_link_strategy!(), :sign_in)}
            method="post"
          >
            <input type="hidden" name={form[:token].name} value={@token} />

            <:actions>
              <.auth_submit
                label="Sign me in"
                busy_label="Signing you in..."
              />
            </:actions>
          </.auth_form>

          <:footer>
            <.auth_page_footer
              prompt="Prefer a standard credential flow?"
              link_text="Sign in with password"
              link_href={~p"/sign-in"}
              note="Magic-link confirmation uses the same public shell and lands in the same authenticated destination."
            />
          </:footer>
        </.auth_page>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
