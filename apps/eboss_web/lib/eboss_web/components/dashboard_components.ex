defmodule EBossWeb.DashboardComponents do
  @moduledoc """
  Shared dashboard shell patterns for authenticated product surfaces.

  The shell chrome owns product identity, primary navigation, and persistent
  operator context. Route-specific headings, actions, and working panels belong
  in the page slots so future authenticated surfaces can reuse the same frame.
  """

  use Phoenix.Component
  use EBossWeb, :verified_routes

  import EBossWeb.CoreComponents
  import EBossWeb.UIComponents

  alias EBossWeb.BrowserTestContracts

  attr(:current_user, :map, required: true)
  attr(:current_path, :string, default: nil)
  attr(:shell_label, :string, default: "Authenticated product surface")
  attr(:shell_title, :string, default: "EBoss control center")

  attr(:shell_copy, :string,
    default:
      "Keep route context, operator identity, and persistent utilities anchored while each working surface changes."
  )

  slot(:page_header, required: true)
  slot(:inner_block, required: true)
  slot(:sidebar_footer)

  def dashboard_shell(assigns) do
    assigns = assign(assigns, :nav_groups, dashboard_nav_groups(assigns.current_path))

    ~H"""
    <section
      class="ui-dashboard-shell"
      aria-label={BrowserTestContracts.dashboard_shell_label()}
      data-dashboard-shell
      data-testid={BrowserTestContracts.dashboard_shell()}
    >
      <aside
        class="ui-dashboard-shell__sidebar"
        aria-label={BrowserTestContracts.dashboard_sidebar_label()}
        data-dashboard-shell-sidebar
      >
        <div class="ui-dashboard-shell__rail">
          <div class="ui-dashboard-shell__identity" data-dashboard-chrome="identity">
            <div class="space-y-3">
              <div class="flex flex-wrap items-center gap-2">
                <p class="ui-text-meta" data-tone="primary">{@shell_label}</p>
                <.badge tone="neutral">Dashboard convergence</.badge>
              </div>

              <div class="space-y-2">
                <h2 class="ui-text-title" data-size="md">{@shell_title}</h2>
                <p class="ui-text-body" data-size="sm" data-tone="soft">{@shell_copy}</p>
              </div>
            </div>

            <div class="ui-dashboard-shell__identity-signals">
              <.badge tone="neutral">@{Map.get(@current_user, :username)}</.badge>
              <.badge tone="neutral">Signed in</.badge>
            </div>
          </div>

          <nav
            class="ui-dashboard-shell__nav"
            aria-label={BrowserTestContracts.dashboard_navigation_label()}
          >
            <section
              :for={group <- @nav_groups}
              class="ui-dashboard-shell__nav-group"
              data-dashboard-nav-group={group.id}
            >
              <div class="ui-dashboard-shell__nav-group-header">
                <p class="ui-text-meta" data-tone="soft">{group.label}</p>
                <p class="ui-text-body" data-size="sm" data-tone="soft">{group.description}</p>
              </div>

              <ul class="ui-dashboard-shell__nav-list" role="list">
                <li :for={item <- group.items}>
                  <.dashboard_nav_item item={item} />
                </li>
              </ul>
            </section>
          </nav>

          <.panel
            as="section"
            surface="solid"
            padding="sm"
            class="ui-dashboard-shell__context"
            data-dashboard-chrome="context"
          >
            <p class="ui-text-meta" data-tone="soft">Operator context</p>

            <div class="space-y-2">
              <p class="ui-text-title" data-size="sm">@{Map.get(@current_user, :username)}</p>
              <p class="ui-text-body" data-size="sm" data-tone="muted">
                {to_string(Map.get(@current_user, :email))}
              </p>
            </div>

            <p class="ui-text-body" data-size="sm" data-tone="soft">
              Session controls stay in the product header while route-level work can change without
              breaking the frame.
            </p>
          </.panel>

          <div :if={@sidebar_footer != []} class="ui-dashboard-shell__sidebar-footer">
            <div class="ui-dashboard-shell__secondary-nav" data-dashboard-secondary-nav>
              <p class="ui-text-meta" data-tone="soft">Secondary cues</p>
              <p class="ui-text-body" data-size="sm" data-tone="soft">
                Route jumps and review cues stay separate from primary product routes.
              </p>
            </div>

            {render_slot(@sidebar_footer)}
          </div>
        </div>
      </aside>

      <section
        class="ui-dashboard-shell__main"
        aria-label={BrowserTestContracts.dashboard_workspace_label()}
        data-dashboard-shell-main
      >
        <header class="ui-dashboard-shell__header" data-dashboard-shell-header>
          {render_slot(@page_header)}
        </header>

        <div class="ui-dashboard-shell__body" data-dashboard-shell-body>
          {render_slot(@inner_block)}
        </div>
      </section>
    </section>
    """
  end

  attr(:eyebrow, :string, default: nil)
  attr(:title, :string, required: true)
  attr(:description, :string, default: nil)
  attr(:title_tag, :string, values: ~w(h1 h2 h3), default: "h2")
  attr(:title_size, :string, values: ~w(xl lg md sm), default: "md")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:badge)
  slot(:signal)
  slot(:actions)

  def dashboard_header(assigns) do
    ~H"""
    <header class={["ui-dashboard-header", @class]} data-dashboard-header {@rest}>
      <div class="ui-dashboard-header__copy">
        <div :if={@eyebrow || @badge != []} class="ui-dashboard-header__context">
          <p :if={@eyebrow} class="ui-kicker" data-tone="primary">{@eyebrow}</p>
          <div :if={@badge != []} class="ui-dashboard-header__badges">
            {render_slot(@badge)}
          </div>
        </div>

        <div class="space-y-2">
          <.dynamic_tag tag_name={@title_tag} class="ui-section-header__title" data-size={@title_size}>
            {@title}
          </.dynamic_tag>
          <p :if={@description} class="ui-section-header__subtitle">{@description}</p>
        </div>
      </div>

      <div :if={@signal != [] || @actions != []} class="ui-dashboard-header__aside">
        <div :if={@signal != []} class="ui-dashboard-header__signals">
          {render_slot(@signal)}
        </div>

        {render_slot(@actions)}
      </div>
    </header>
    """
  end

  attr(:section, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  def dashboard_section(assigns) do
    ~H"""
    <section
      class={["ui-dashboard-section", @class]}
      aria-label={BrowserTestContracts.dashboard_section_label(@section)}
      data-dashboard-section={@section}
      {@rest}
    >
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  def dashboard_action_bar(assigns) do
    ~H"""
    <div class={["ui-dashboard-action-bar", @class]} data-dashboard-action-bar {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:label, :string, default: BrowserTestContracts.dashboard_command_surface_label())
  attr(:title, :string, default: "Command surface")

  attr(:description, :string,
    default:
      "Keep route orientation and the next move visible without adding heavier workflow chrome."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:item, required: true) do
    attr(:id, :string, required: true)
    attr(:label, :string, required: true)
    attr(:value, :string, required: true)
    attr(:hint, :string)
    attr(:href, :string)
    attr(:shortcut, :string)
    attr(:icon, :string)
    attr(:tone, :string, values: ~w(neutral primary success warning danger))
  end

  def dashboard_utility_strip(assigns) do
    ~H"""
    <.panel
      as="section"
      surface="solid"
      padding="sm"
      class={["ui-dashboard-utility-strip", @class]}
      aria-label={@label}
      data-dashboard-utility-strip
      {@rest}
    >
      <div class="ui-dashboard-utility-strip__intro">
        <p class="ui-text-meta" data-tone="soft">{@title}</p>
        <p class="ui-text-body" data-size="sm" data-tone="soft">{@description}</p>
      </div>

      <div class="ui-dashboard-utility-strip__items">
        <.dashboard_utility_item :for={item <- @item} item={item} />
      </div>
    </.panel>
    """
  end

  attr(:label, :string, default: BrowserTestContracts.dashboard_quick_actions_label())
  attr(:title, :string, default: "Quick actions")

  attr(:description, :string,
    default:
      "Mnemonic route cues keep the dashboard easy to move through before a fuller command palette exists."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:action, required: true) do
    attr(:id, :string, required: true)
    attr(:label, :string, required: true)
    attr(:description, :string, required: true)
    attr(:href, :string, required: true)
    attr(:shortcut, :string)
    attr(:badge, :string)
    attr(:icon, :string)
    attr(:tone, :string, values: ~w(neutral primary success warning danger))
  end

  def dashboard_quick_actions(assigns) do
    ~H"""
    <.panel
      as="nav"
      surface="solid"
      padding="sm"
      class={["ui-dashboard-quick-actions", @class]}
      aria-label={@label}
      data-dashboard-quick-actions
      {@rest}
    >
      <div class="ui-dashboard-quick-actions__header">
        <p class="ui-text-meta" data-tone="soft">{@title}</p>
        <p class="ui-text-body" data-size="sm" data-tone="soft">{@description}</p>
      </div>

      <div class="ui-dashboard-quick-actions__list">
        <a
          :for={action <- @action}
          href={action[:href]}
          class="ui-dashboard-quick-actions__item"
          data-tone={Map.get(action, :tone, "neutral")}
          data-dashboard-quick-action={action[:id]}
        >
          <div class="ui-dashboard-quick-actions__item-copy">
            <div class="ui-dashboard-quick-actions__item-context">
              <span class="ui-dashboard-quick-actions__item-icon">
                <.icon name={Map.get(action, :icon, "hero-bolt")} class="size-4" />
              </span>
              <p class="ui-text-title" data-size="sm">{action[:label]}</p>
              <.badge :if={action[:badge]} tone={Map.get(action, :tone, "neutral")}>
                {action[:badge]}
              </.badge>
            </div>

            <p class="ui-text-body" data-size="sm" data-tone="soft">{action[:description]}</p>
          </div>

          <div class="ui-dashboard-quick-actions__item-meta">
            <div :if={action[:shortcut]} class="ui-dashboard-quick-actions__cue">
              <p class="ui-text-meta" data-tone={Map.get(action, :tone, "neutral")}>Cue</p>
              <.dashboard_keycap>{action[:shortcut]}</.dashboard_keycap>
            </div>

            <span class="ui-dashboard-quick-actions__arrow">
              <.icon name="hero-arrow-right" class="size-4" />
            </span>
          </div>
        </a>
      </div>
    </.panel>
    """
  end

  attr(:class, :any, default: nil)

  slot(:inner_block, required: true)

  def dashboard_keycap(assigns) do
    ~H"""
    <span class={["ui-dashboard-keycap", @class]} data-dashboard-keycap>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr(:columns, :string, values: ~w(stack split), default: "stack")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  def dashboard_panel_group(assigns) do
    ~H"""
    <div
      class={["ui-dashboard-panel-group", @class]}
      data-dashboard-panel-group={@columns}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:label, :string, default: nil)
  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:density, :string, values: ~w(sparse dense), default: "dense")
  attr(:details, :list, default: [])
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:actions)

  def dashboard_empty_state(assigns) do
    assigns =
      assigns
      |> assign_dashboard_state_label()
      |> assign_dashboard_state_details([
        "Keep the section header, action row, and supporting cues visible.",
        "Reserve space for metrics, rows, and queue notes before work lands."
      ])

    ~H"""
    <.dashboard_state_frame
      variant="empty"
      density={@density}
      label={@label}
      status="Empty"
      status_tone="neutral"
      title={@title}
      description={@description}
      class={@class}
      {@rest}
    >
      <div class="ui-dashboard-state__layout">
        <div class="ui-dashboard-state__stack">
          <ul :if={@details != []} class="ui-dashboard-state__list">
            <li :for={detail <- @details}>{detail}</li>
          </ul>
        </div>

        <div class="ui-dashboard-state__structure" data-state-style="empty" aria-hidden="true">
          <div class="ui-dashboard-state__placeholder" data-span="wide" />
          <div class="ui-dashboard-state__placeholder" />
          <div class="ui-dashboard-state__placeholder" />
        </div>
      </div>

      <:actions>
        {render_slot(@actions)}
      </:actions>
    </.dashboard_state_frame>
    """
  end

  attr(:label, :string, default: nil)
  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:density, :string, values: ~w(sparse dense), default: "dense")
  attr(:details, :list, default: [])
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:actions)

  def dashboard_loading_state(assigns) do
    assigns =
      assigns
      |> assign_dashboard_state_label()
      |> assign_dashboard_state_details([
        "Hold the same shell hierarchy while the next snapshot resolves.",
        "Keep action placement stable so the route never collapses into a spinner-only screen."
      ])

    ~H"""
    <.dashboard_state_frame
      variant="loading"
      density={@density}
      label={@label}
      status="Loading"
      status_tone="primary"
      title={@title}
      description={@description}
      class={@class}
      {@rest}
    >
      <div class="ui-dashboard-state__layout">
        <div class="ui-dashboard-state__stack">
          <div class="ui-dashboard-state__signal">
            <span class="ui-spinner" data-size="sm" aria-hidden="true" />
            <p class="ui-text-body" data-size="sm" data-tone="soft">
              Layout slots stay reserved while the dashboard requests the next data pass.
            </p>
          </div>

          <ul :if={@details != []} class="ui-dashboard-state__list">
            <li :for={detail <- @details}>{detail}</li>
          </ul>

          <div class="ui-dashboard-state__bars" data-state-style="loading" aria-hidden="true">
            <span class="ui-dashboard-state__bar" data-width="wide" />
            <span class="ui-dashboard-state__bar" />
            <span class="ui-dashboard-state__bar" data-width="short" />
          </div>
        </div>

        <div class="ui-dashboard-state__structure" data-state-style="loading" aria-hidden="true">
          <div class="ui-dashboard-state__placeholder" data-span="wide" />
          <div class="ui-dashboard-state__placeholder" />
          <div class="ui-dashboard-state__placeholder" />
        </div>
      </div>

      <:actions>
        {render_slot(@actions)}
      </:actions>
    </.dashboard_state_frame>
    """
  end

  attr(:label, :string, default: nil)
  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:density, :string, values: ~w(sparse dense), default: "dense")
  attr(:details, :list, default: [])
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:actions)

  def dashboard_error_state(assigns) do
    assigns =
      assigns
      |> assign_dashboard_state_label()
      |> assign_dashboard_state_details([
        "Show the recovery path and scope context in the same panel rhythm as healthy content.",
        "Keep the operator close to retry and event review without dropping into generic alert chrome."
      ])

    ~H"""
    <.dashboard_state_frame
      variant="error"
      density={@density}
      label={@label}
      status="Attention"
      status_tone="danger"
      title={@title}
      description={@description}
      class={@class}
      {@rest}
    >
      <div class="ui-dashboard-state__stack">
        <.alert
          tone="danger"
          role="alert"
          live="assertive"
          title="Recovery stays inside the dashboard frame"
          description="Retry and event inspection stay grouped with the same shell hierarchy and action treatment."
        />

        <ul :if={@details != []} class="ui-dashboard-state__list">
          <li :for={detail <- @details}>{detail}</li>
        </ul>
      </div>

      <:actions>
        {render_slot(@actions)}
      </:actions>
    </.dashboard_state_frame>
    """
  end

  attr(:variant, :string, values: ~w(empty loading error), required: true)
  attr(:density, :string, values: ~w(sparse dense), default: "dense")
  attr(:label, :string, required: true)
  attr(:status, :string, required: true)
  attr(:status_tone, :string, values: ~w(neutral primary success warning danger), required: true)
  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:actions)
  slot(:inner_block, required: true)

  defp dashboard_state_frame(assigns) do
    surface = if assigns.density == "sparse", do: "floating", else: "solid"
    padding = if assigns.density == "sparse", do: "lg", else: "md"
    title_size = if assigns.density == "sparse", do: "md", else: "sm"

    assigns =
      assigns
      |> assign(:surface, surface)
      |> assign(:padding, padding)
      |> assign(:title_size, title_size)

    ~H"""
    <.panel
      as="section"
      surface={@surface}
      padding={@padding}
      class={["ui-dashboard-state", @class]}
      aria-label={BrowserTestContracts.dashboard_state_label(@variant)}
      data-dashboard-state={@variant}
      data-dashboard-density={@density}
      {@rest}
    >
      <div class="ui-dashboard-state__header">
        <div class="space-y-3">
          <div class="ui-dashboard-state__context">
            <p class="ui-text-meta" data-tone={dashboard_state_label_tone(@variant)}>{@label}</p>
            <.badge tone={@status_tone}>{@status}</.badge>
          </div>

          <div class="space-y-2">
            <p class="ui-text-title" data-size={@title_size}>{@title}</p>
            <p class="ui-text-body" data-size="sm" data-tone="soft">{@description}</p>
          </div>
        </div>

        <div :if={@actions != []} class="ui-dashboard-state__actions">
          {render_slot(@actions)}
        </div>
      </div>

      <div class="ui-dashboard-state__body">
        {render_slot(@inner_block)}
      </div>
    </.panel>
    """
  end

  attr(:item, :map, required: true)

  defp dashboard_nav_item(assigns) do
    assigns =
      assigns
      |> assign(:active_attr, to_string(assigns.item.active?))
      |> assign(:interactive_attr, to_string(not is_nil(assigns.item.path)))
      |> assign(:badge_tone, Map.get(assigns.item, :badge_tone, "neutral"))

    ~H"""
    <a
      :if={@item.path}
      href={@item.path}
      class="ui-dashboard-nav__item"
      aria-current={if @item.active?, do: "page", else: nil}
      data-active={@active_attr}
      data-state={@item.state}
      data-interactive={@interactive_attr}
      data-dashboard-nav-item={@item.id}
    >
      <span class="ui-dashboard-nav__icon">
        <.icon name={@item.icon} class="size-4" />
      </span>

      <div class="ui-dashboard-nav__copy">
        <div class="ui-dashboard-nav__meta">
          <p class="ui-text-meta" data-tone={Map.get(@item, :meta_tone, "soft")}>{@item.meta}</p>
          <span class="ui-dashboard-nav__state" data-state={@item.state} aria-hidden="true" />
        </div>
        <p class="ui-text-title" data-size="sm">{@item.label}</p>
        <p class="ui-text-body" data-size="sm" data-tone="muted">{@item.detail}</p>
      </div>

      <.badge tone={@badge_tone}>{@item.badge}</.badge>
    </a>

    <div
      :if={is_nil(@item.path)}
      class="ui-dashboard-nav__item"
      data-active={@active_attr}
      data-state={@item.state}
      data-interactive={@interactive_attr}
      data-dashboard-nav-item={@item.id}
    >
      <span class="ui-dashboard-nav__icon">
        <.icon name={@item.icon} class="size-4" />
      </span>

      <div class="ui-dashboard-nav__copy">
        <div class="ui-dashboard-nav__meta">
          <p class="ui-text-meta" data-tone={Map.get(@item, :meta_tone, "soft")}>{@item.meta}</p>
          <span class="ui-dashboard-nav__state" data-state={@item.state} aria-hidden="true" />
        </div>
        <p class="ui-text-title" data-size="sm">{@item.label}</p>
        <p class="ui-text-body" data-size="sm" data-tone="muted">{@item.detail}</p>
      </div>

      <.badge tone={@badge_tone}>{@item.badge}</.badge>
    </div>
    """
  end

  defp dashboard_nav_groups(current_path) do
    [
      %{
        id: "primary-routes",
        label: "Primary routes",
        description: "Move between authenticated product surfaces.",
        items: [
          %{
            id: "dashboard",
            label: "Dashboard",
            meta: "Current route",
            meta_tone: "primary",
            detail: "Shared operator workspace",
            badge: "Current",
            badge_tone: "primary",
            icon: "hero-home",
            path: ~p"/dashboard",
            active?: current_path == "/dashboard",
            state: "active"
          }
        ]
      },
      %{
        id: "upcoming-surfaces",
        label: "Upcoming surfaces",
        description: "Shared shell targets still converging on the same frame.",
        items: [
          %{
            id: "workspaces",
            label: "Workspaces",
            meta: "Planned surface",
            meta_tone: "soft",
            detail: "Next authenticated surface",
            badge: "Planned",
            badge_tone: "neutral",
            icon: "hero-rectangle-stack",
            path: nil,
            active?: false,
            state: "planned"
          },
          %{
            id: "folio",
            label: "Folio",
            meta: "Planned surface",
            meta_tone: "soft",
            detail: "Scoped execution surface",
            badge: "Planned",
            badge_tone: "neutral",
            icon: "hero-document-text",
            path: nil,
            active?: false,
            state: "planned"
          }
        ]
      }
    ]
  end

  attr(:item, :map, required: true)

  defp dashboard_utility_item(assigns) do
    assigns =
      assigns
      |> assign(:linked?, is_binary(assigns.item[:href]))
      |> assign(:tone, Map.get(assigns.item, :tone, "neutral"))
      |> assign(:icon, Map.get(assigns.item, :icon, "hero-arrow-up-right"))
      |> assign(:hint, Map.get(assigns.item, :hint))
      |> assign(:shortcut, Map.get(assigns.item, :shortcut))

    ~H"""
    <a
      :if={@linked?}
      href={@item[:href]}
      class="ui-dashboard-utility-strip__item"
      data-tone={@tone}
      data-dashboard-utility-item={@item[:id]}
    >
      <div class="ui-dashboard-utility-strip__item-copy">
        <p class="ui-text-meta" data-tone={@tone}>{@item[:label]}</p>
        <p class="ui-text-body" data-size="sm">{@item[:value]}</p>
      </div>

      <div class="ui-dashboard-utility-strip__item-meta">
        <p :if={@hint} class="ui-text-body" data-size="sm" data-tone="muted">
          {@hint}
        </p>
        <.dashboard_keycap :if={@shortcut}>{@shortcut}</.dashboard_keycap>
        <.icon :if={@icon} name={@icon} class="size-4" />
      </div>
    </a>

    <div
      :if={not @linked?}
      class="ui-dashboard-utility-strip__item"
      data-tone={@tone}
      data-dashboard-utility-item={@item[:id]}
    >
      <div class="ui-dashboard-utility-strip__item-copy">
        <p class="ui-text-meta" data-tone={@tone}>{@item[:label]}</p>
        <p class="ui-text-body" data-size="sm">{@item[:value]}</p>
      </div>

      <div class="ui-dashboard-utility-strip__item-meta">
        <p :if={@hint} class="ui-text-body" data-size="sm" data-tone="muted">
          {@hint}
        </p>
        <.dashboard_keycap :if={@shortcut}>{@shortcut}</.dashboard_keycap>
        <.icon :if={@icon} name={@icon} class="size-4" />
      </div>
    </div>
    """
  end

  defp assign_dashboard_state_label(assigns) do
    if is_nil(assigns.label) do
      assign(assigns, :label, dashboard_state_context_label(assigns.density))
    else
      assigns
    end
  end

  defp assign_dashboard_state_details(assigns, default_details) do
    if assigns.details == [] do
      assign(assigns, :details, default_details)
    else
      assigns
    end
  end

  defp dashboard_state_context_label("sparse"), do: "Sparse context"
  defp dashboard_state_context_label("dense"), do: "Dense context"

  defp dashboard_state_label_tone("error"), do: "danger"
  defp dashboard_state_label_tone("loading"), do: "primary"
  defp dashboard_state_label_tone(_variant), do: "soft"
end
