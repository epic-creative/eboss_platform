defmodule EBossWeb.AuthComponents do
  @moduledoc false
  use EBossWeb, :html

  alias AshPhoenix.Form

  attr :eyebrow, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :detail_one, :string, required: true
  attr :detail_two, :string, required: true
  attr :detail_three, :string, required: true
  attr :current_user, :map, default: nil
  slot :inner_block, required: true

  def auth_shell(assigns) do
    ~H"""
    <section class="ui-auth-grid">
      <.panel surface="floating" class="ui-frame-card">
        <.AuthScene
          eyebrow={@eyebrow}
          title={@title}
          subtitle={@subtitle}
          detailOne={@detail_one}
          detailTwo={@detail_two}
          detailThree={@detail_three}
        />
      </.panel>

      <.panel surface="floating" class="ui-form-card">
        {render_slot(@inner_block)}
      </.panel>
    </section>
    """
  end

  attr :form, :any, required: true

  def form_errors(assigns) do
    assigns =
      assign(assigns,
        messages:
          assigns.form
          |> Form.raw_errors(for_path: :all)
          |> Enum.flat_map(fn {_path, errors} -> List.wrap(errors) end)
          |> Enum.map(&Exception.message/1)
          |> Enum.uniq()
      )

    ~H"""
    <div
      :if={@messages != []}
      class="ui-alert"
      data-tone="danger"
      role="alert"
      aria-live="assertive"
      aria-atomic="true"
    >
      <.icon name="hero-exclamation-circle" class="mt-0.5 size-5 shrink-0" />
      <div class="ui-alert__content">
        <p class="ui-alert__title">We need a quick fix before continuing.</p>
        <p :for={message <- @messages} class="ui-alert__description">{message}</p>
      </div>
    </div>
    """
  end

  attr :current_path, :string, required: true

  def auth_nav(assigns) do
    ~H"""
    <nav class="flex flex-wrap gap-2">
      <.nav_pill to={~p"/sign-in"} active={@current_path == "/sign-in"}>
        Sign in
      </.nav_pill>
      <.nav_pill to={~p"/register"} active={@current_path == "/register"}>
        Register
      </.nav_pill>
      <.nav_pill to={~p"/forgot-password"} active={@current_path == "/forgot-password"}>
        Forgot password
      </.nav_pill>
    </nav>
    """
  end
end
