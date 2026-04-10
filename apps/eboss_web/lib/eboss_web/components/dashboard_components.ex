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

  attr :current_user, :map, required: true
  attr :current_path, :string, default: nil
  attr :shell_label, :string, default: "Authenticated product surface"
  attr :shell_title, :string, default: "EBoss control center"

  attr :shell_copy, :string,
    default:
      "Keep route context, operator identity, and persistent utilities anchored while each working surface changes."

  slot :page_header, required: true
  slot :inner_block, required: true
  slot :sidebar_footer

  def dashboard_shell(assigns) do
    assigns = assign(assigns, :nav_items, dashboard_nav_items(assigns.current_path))

    ~H"""
    <section
      class="ui-dashboard-shell"
      data-dashboard-shell
      data-testid={BrowserTestContracts.dashboard_shell()}
    >
      <aside class="ui-dashboard-shell__sidebar" data-dashboard-shell-sidebar>
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
            <.dashboard_nav_item :for={item <- @nav_items} item={item} />
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
            {render_slot(@sidebar_footer)}
          </div>
        </div>
      </aside>

      <div class="ui-dashboard-shell__main" data-dashboard-shell-main>
        <header class="ui-dashboard-shell__header" data-dashboard-shell-header>
          {render_slot(@page_header)}
        </header>

        <div class="ui-dashboard-shell__body" data-dashboard-shell-body>
          {render_slot(@inner_block)}
        </div>
      </div>
    </section>
    """
  end

  attr :item, :map, required: true

  defp dashboard_nav_item(assigns) do
    assigns = assign(assigns, :active_attr, to_string(assigns.item.active?))

    ~H"""
    <a
      :if={@item.path}
      href={@item.path}
      class="ui-dashboard-nav__item"
      aria-current={if @item.active?, do: "page", else: nil}
      data-active={@active_attr}
      data-state={@item.state}
      data-dashboard-nav-item={@item.id}
    >
      <span class="ui-dashboard-nav__icon">
        <.icon name={@item.icon} class="size-4" />
      </span>

      <div class="ui-dashboard-nav__copy">
        <p class="ui-text-body" data-size="sm">{@item.label}</p>
        <p class="ui-text-body" data-size="sm" data-tone="muted">{@item.detail}</p>
      </div>

      <.badge tone="neutral">{@item.badge}</.badge>
    </a>

    <div
      :if={is_nil(@item.path)}
      class="ui-dashboard-nav__item"
      data-active={@active_attr}
      data-state={@item.state}
      data-dashboard-nav-item={@item.id}
    >
      <span class="ui-dashboard-nav__icon">
        <.icon name={@item.icon} class="size-4" />
      </span>

      <div class="ui-dashboard-nav__copy">
        <p class="ui-text-body" data-size="sm">{@item.label}</p>
        <p class="ui-text-body" data-size="sm" data-tone="muted">{@item.detail}</p>
      </div>

      <.badge tone="neutral">{@item.badge}</.badge>
    </div>
    """
  end

  defp dashboard_nav_items(current_path) do
    [
      %{
        id: "dashboard",
        label: "Dashboard",
        detail: "Authenticated control surface",
        badge: "Live",
        icon: "hero-home",
        path: ~p"/dashboard",
        active?: current_path == "/dashboard",
        state: "active"
      },
      %{
        id: "workspaces",
        label: "Workspaces",
        detail: "Next authenticated surface",
        badge: "Queued",
        icon: "hero-rectangle-stack",
        path: nil,
        active?: false,
        state: "planned"
      },
      %{
        id: "folio",
        label: "Folio",
        detail: "Scoped execution surface",
        badge: "Scoped",
        icon: "hero-document-text",
        path: nil,
        active?: false,
        state: "planned"
      }
    ]
  end
end
