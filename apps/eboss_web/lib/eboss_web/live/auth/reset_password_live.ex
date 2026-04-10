defmodule EBossWeb.Auth.ResetPasswordLive do
  use EBossWeb, :live_view

  alias AshPhoenix.Form
  alias EBossWeb.{AuthComponents, AuthForms}
  import AuthComponents

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Reset password")
     |> assign(:token, token)
     |> assign(:form, AuthForms.reset_password_form(token))}
  end

  @impl true
  def handle_event("change", %{"user" => params}, socket) do
    {:noreply, assign(socket, :form, Form.validate(socket.assigns.form, params, errors: false))}
  end

  def handle_event("submit", %{"user" => params}, socket) do
    form = Form.validate(socket.assigns.form, params)

    if form.valid? do
      case AuthForms.reset_password(params) do
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

        {:error, _error} ->
          {:noreply,
           socket
           |> assign(:form, Form.clear_value(form, :password_confirmation))
           |> put_flash(:error, "That reset link is invalid or expired")
           |> redirect(to: ~p"/forgot-password")}
      end
    else
      {:noreply, assign(socket, :form, form)}
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
        eyebrow="Password recovery"
        title="Choose a new password"
        subtitle="This page validates the password locally in LiveView and hands the final token submission back to AshAuthentication."
        detail_one="The reset token stays in the standard POST flow"
        detail_two="Successful resets also create a session"
        detail_three="Invalid tokens fall back to the sign-in flow cleanly"
      >
        <.auth_page
          eyebrow="Reset password"
          title="Set a new password"
          subtitle="Choose a fresh password and we will sign you back into the application."
        >
          <.form_errors form={@form} />

          <.auth_form
            :let={form}
            for={@form}
            id="reset-password-form"
            phx-change="change"
            phx-submit="submit"
          >
            <input type="hidden" name={form[:reset_token].name} value={@token} />
            <.auth_password_input
              field={form[:password]}
              label="New password"
              hint="Use at least 8 characters."
              autocomplete="new-password"
            />
            <.auth_password_input
              field={form[:password_confirmation]}
              label="Confirm new password"
              hint="Repeat the same password exactly."
              autocomplete="new-password"
            />

            <:actions>
              <.auth_submit
                label="Reset password"
                busy_label="Resetting password..."
              />
            </:actions>
          </.auth_form>

          <:footer>
            <.auth_page_footer
              prompt="Need another reset email?"
              link_text="Request a new link"
              link_href={~p"/forgot-password"}
              note="Expired or invalid tokens fall back to the same recovery flow without leaving the auth family."
            />
          </:footer>
        </.auth_page>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
