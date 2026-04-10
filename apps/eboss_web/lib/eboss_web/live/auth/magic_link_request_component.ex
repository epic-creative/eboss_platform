defmodule EBossWeb.Auth.MagicLinkRequestComponent do
  use EBossWeb, :live_component

  alias AshPhoenix.Form
  alias EBossWeb.{AuthComponents, AuthForms}
  import AuthComponents

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:form, AuthForms.magic_link_request_form(nil, %{}, as: "magic_link_user"))
     |> assign(:magic_link_requested, false)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("validate_magic_link", %{"magic_link_user" => params}, socket) do
    form = Form.validate(socket.assigns.form, params, errors: false)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:magic_link_requested, false)}
  end

  def handle_event("submit_magic_link", %{"magic_link_user" => params}, socket) do
    case Form.submit(socket.assigns.form, params: params) do
      :ok ->
        {:noreply,
         socket
         |> assign(:form, AuthForms.magic_link_request_form(nil, %{}, as: "magic_link_user"))
         |> assign(:magic_link_requested, true)}

      {:ok, _result} ->
        {:noreply,
         socket
         |> assign(:form, AuthForms.magic_link_request_form(nil, %{}, as: "magic_link_user"))
         |> assign(:magic_link_requested, true)}

      {:error, form} ->
        {:noreply,
         socket
         |> assign(:form, form)
         |> assign(:magic_link_requested, false)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
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

      <.form_errors form={@form} />

      <.auth_form
        :let={form}
        for={@form}
        id="sign-in-magic-link-form"
        phx-change="validate_magic_link"
        phx-submit="submit_magic_link"
        phx-target={@myself}
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
    """
  end
end
