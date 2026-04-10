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
    <section class="ui-auth-grid" data-auth-shell>
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

  attr :eyebrow, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :current_path, :string, default: nil
  attr :family_label, :string, default: "Secure access"
  attr :family_badge, :string, default: "First-party auth"
  attr :show_nav, :boolean, default: true
  slot :inner_block, required: true
  slot :footer

  def auth_page(assigns) do
    ~H"""
    <div class="ui-auth-page">
      <header class="ui-auth-page__header">
        <div class="ui-auth-page__meta">
          <p class="ui-text-meta" data-tone="soft">{@family_label}</p>
          <.badge tone="neutral">{@family_badge}</.badge>
        </div>

        <.section_heading
          eyebrow={@eyebrow}
          title={@title}
          subtitle={@subtitle}
          title_size="md"
        />

        <div :if={@show_nav} class="ui-auth-page__nav">
          <.auth_nav current_path={@current_path || ""} />
        </div>
      </header>

      <div class="ui-auth-page__body">
        {render_slot(@inner_block)}
      </div>

      <footer :if={@footer != []} class="ui-auth-page__footer">
        {render_slot(@footer)}
      </footer>
    </div>
    """
  end

  attr :prompt, :string, required: true
  attr :link_text, :string, required: true
  attr :link_href, :string, required: true
  attr :note, :string, default: nil

  def auth_page_footer(assigns) do
    ~H"""
    <div class="ui-auth-page__footer-copy">
      <p class="ui-text-body" data-size="sm" data-tone="soft">
        {@prompt} <a href={@link_href} class="ui-text-link">{@link_text}</a>.
      </p>
      <p :if={@note} class="ui-text-body" data-size="sm" data-tone="muted">
        {@note}
      </p>
    </div>
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
    <.alert
      :if={@messages != []}
      tone="danger"
      role="alert"
      live="assertive"
      title="We need a quick fix before continuing."
    >
      <div class="grid gap-2">
        <p :for={message <- @messages}>{message}</p>
      </div>
    </.alert>
    """
  end

  attr :current_path, :string, required: true

  def auth_nav(assigns) do
    ~H"""
    <nav class="ui-auth-nav flex flex-wrap gap-2" aria-label="Authentication routes">
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
