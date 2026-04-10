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
        <div class="space-y-8">
          <.section_heading
            eyebrow="Reset password"
            title="Set a new password"
            subtitle="Choose a fresh password and we will sign you back into the application."
            title_class="text-3xl"
          />

          <.form_errors form={@form} />

          <.form
            :let={form}
            for={@form}
            id="reset-password-form"
            phx-change="change"
            phx-submit="submit"
            class="space-y-4"
          >
            <input type="hidden" name={form[:reset_token].name} value={@token} />
            <.input
              field={form[:password]}
              type="password"
              label="New password"
              autocomplete="new-password"
            />
            <.input
              field={form[:password_confirmation]}
              type="password"
              label="Confirm new password"
              autocomplete="new-password"
            />

            <.button type="submit">
              Reset password
            </.button>
          </.form>
        </div>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
