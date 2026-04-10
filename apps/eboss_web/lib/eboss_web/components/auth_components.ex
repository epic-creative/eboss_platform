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
    <.auth_feedback
      :if={@messages != []}
      tone="danger"
      data-feedback="danger"
      role="alert"
      live="assertive"
      title="Review the highlighted fields."
      messages={@messages}
    />
    """
  end

  attr :tone, :string, values: ~w(success danger), required: true
  attr :title, :string, required: true
  attr :message, :string, default: nil
  attr :messages, :list, default: []
  attr :class, :any, default: nil
  attr :role, :string, default: nil
  attr :live, :string, default: nil
  attr :rest, :global

  def auth_feedback(assigns) do
    items = feedback_items(assigns.message, assigns.messages)

    assigns =
      assigns
      |> assign(:items, items)
      |> assign(:single_item, List.first(items))

    ~H"""
    <.alert
      :if={@items != []}
      class={["ui-auth-feedback", @class]}
      tone={@tone}
      title={@title}
      role={@role}
      live={@live}
      {@rest}
    >
      <p :if={length(@items) == 1}>{@single_item}</p>

      <ul :if={length(@items) > 1} class="ui-auth-feedback__list">
        <li :for={item <- @items} class="ui-auth-feedback__item">{item}</li>
      </ul>
    </.alert>
    """
  end

  attr :for, :any, required: true
  attr :id, :string, required: true
  attr :class, :any, default: nil
  attr :actions_layout, :string, values: ~w(end between), default: "end"

  attr :rest, :global,
    include:
      ~w(action autocomplete method novalidate phx-change phx-submit phx-target phx-trigger-action)

  slot :inner_block, required: true
  slot :actions, required: true

  def auth_form(assigns) do
    ~H"""
    <.form :let={form} for={@for} id={@id} class={["ui-auth-form", @class]} {@rest}>
      <fieldset class="ui-auth-form__fieldset">
        <div class="ui-auth-form__fields">
          {render_slot(@inner_block, form)}
        </div>

        <div class="ui-auth-form__actions" data-layout={@actions_layout}>
          {render_slot(@actions, form)}
        </div>
      </fieldset>
    </.form>
    """
  end

  attr :label, :string, required: true
  attr :busy_label, :string, required: true
  attr :variant, :string, values: ~w(solid outline ghost subtle), default: "solid"
  attr :tone, :string, values: ~w(primary neutral success warning danger), default: "primary"
  attr :size, :string, values: ~w(sm md lg), default: "md"
  attr :class, :any, default: nil

  def auth_submit(assigns) do
    ~H"""
    <.button
      type="submit"
      variant={@variant}
      tone={@tone}
      size={@size}
      class={["ui-auth-submit", @class]}
      phx-disable-with={@busy_label}
    >
      {@label}
    </.button>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :autocomplete, :string, required: true
  attr :label, :string, default: "Email"
  attr :hint, :string, default: "Use the email address tied to this account."

  def auth_email_input(assigns) do
    ~H"""
    <.input
      field={@field}
      type="email"
      label={@label}
      hint={@hint}
      autocomplete={@autocomplete}
    />
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: "Username"

  attr :hint, :string,
    default: "4-30 characters. Use lowercase letters, numbers, hyphens, or underscores."

  def auth_username_input(assigns) do
    ~H"""
    <.input field={@field} type="text" label={@label} hint={@hint} autocomplete="username" />
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :autocomplete, :string, required: true
  attr :label, :string, default: "Password"
  attr :hint, :string, default: "Passwords are case sensitive."

  def auth_password_input(assigns) do
    ~H"""
    <.input
      field={@field}
      type="password"
      label={@label}
      hint={@hint}
      autocomplete={@autocomplete}
    />
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

  defp feedback_items(message, messages) do
    [message | List.wrap(messages)]
    |> Enum.reject(&(is_nil(&1) || &1 == ""))
  end
end
