defmodule EBossWeb.UIComponents do
  @moduledoc """
  Shared first-party UI patterns used across HEEx templates.
  """

  use Phoenix.Component

  attr :as, :string, default: "section"
  attr :class, :any, default: nil
  attr :surface, :string, values: ~w(default floating solid), default: "default"
  attr :tone, :string, values: ~w(neutral primary inverse), default: "neutral"
  attr :padding, :string, values: ~w(sm md lg), default: "md"
  attr :rest, :global

  slot :inner_block, required: true

  def panel(assigns) do
    padding_class =
      case assigns.padding do
        "sm" -> "ui-panel-padding-sm"
        "lg" -> "ui-panel-padding-lg"
        _ -> "ui-panel-padding-md"
      end

    surface =
      case assigns.surface do
        "floating" -> "floating"
        "solid" -> "solid"
        _ -> nil
      end

    tone =
      case assigns.tone do
        "primary" -> "primary"
        "inverse" -> "inverse"
        _ -> nil
      end

    assigns = assign(assigns, :panel_classes, ["ui-panel", padding_class, assigns.class])
    assigns = assign(assigns, :surface_attr, surface)
    assigns = assign(assigns, :tone_attr, tone)

    ~H"""
    <.dynamic_tag
      tag_name={@as}
      class={@panel_classes}
      data-surface={@surface_attr}
      data-tone={@tone_attr}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :class, :any, default: nil
  attr :tone, :string, values: ~w(neutral primary success warning danger), default: "neutral"
  attr :rest, :global
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={["ui-badge", @class]} data-tone={@tone} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :class, :any, default: nil
  attr :tone, :string, values: ~w(primary neutral success warning danger), default: "neutral"
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :role, :string, default: nil
  attr :live, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def alert(assigns) do
    role = alert_role(assigns.role, assigns.tone)

    assigns =
      assigns
      |> assign(:alert_role, role)
      |> assign(:alert_live, alert_live(assigns.live, role))

    ~H"""
    <div
      class={["ui-alert", @class]}
      data-tone={@tone}
      role={@alert_role}
      aria-live={@alert_live}
      aria-atomic="true"
      {@rest}
    >
      <div class="ui-alert__content">
        <p :if={@title} class="ui-alert__title">{@title}</p>
        <p :if={@description} class="ui-alert__description">{@description}</p>
        <div :if={@inner_block != []} class="ui-alert__description">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :to, :string, required: true
  attr :active, :boolean, default: false
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def nav_pill(assigns) do
    ~H"""
    <a href={@to} class={["ui-nav-pill", @class]} data-active={to_string(@active)}>
      {render_slot(@inner_block)}
    </a>
    """
  end

  attr :eyebrow, :string, default: nil
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :title_size, :string, values: ~w(hero xl lg md sm), default: "lg"

  attr :eyebrow_tone, :string,
    values: ~w(primary neutral soft muted success warning danger),
    default: "primary"

  attr :title_class, :any, default: nil
  attr :class, :any, default: nil

  slot :actions

  def section_heading(assigns) do
    ~H"""
    <header class={[
      "ui-section-header",
      @actions != [] && "flex flex-col gap-4 md:flex-row md:items-end md:justify-between",
      @class
    ]}>
      <div class="space-y-2">
        <p :if={@eyebrow} class="ui-kicker" data-tone={@eyebrow_tone}>{@eyebrow}</p>
        <h1 class={["ui-section-header__title", @title_class]} data-size={@title_size}>{@title}</h1>
        <p :if={@subtitle} class="ui-section-header__subtitle">{@subtitle}</p>
      </div>
      <div :if={@actions != []} class="flex-none">
        {render_slot(@actions)}
      </div>
    </header>
    """
  end

  attr :title, :string, required: true
  attr :copy, :string, required: true
  attr :class, :any, default: nil
  slot :actions

  def empty_state(assigns) do
    ~H"""
    <div class={["ui-empty-state", @class]}>
      <div class="space-y-2">
        <p class="ui-empty-state__title">{@title}</p>
        <p class="ui-empty-state__copy">{@copy}</p>
      </div>
      <div :if={@actions != []} class="flex flex-wrap gap-3">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  defp alert_role(role, _tone) when role in ["status", "alert"], do: role
  defp alert_role(nil, tone) when tone in ["warning", "danger"], do: "alert"
  defp alert_role(_, _tone), do: "status"

  defp alert_live(live, _role) when live in ["polite", "assertive", "off"], do: live
  defp alert_live(nil, "alert"), do: "assertive"
  defp alert_live(_, _role), do: "polite"
end
