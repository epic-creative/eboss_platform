defmodule EBossWeb.DashboardLive do
  use EBossWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={assigns[:current_user]}
    >
      <.dashboard_shell
        current_user={@current_user}
        current_path="/dashboard"
        shell_label="EBoss dashboard"
        shell_title="Operator workspace"
        shell_copy="Keep the authenticated product frame stable while workspaces, folio, and future signed-in routes deepen inside it."
      >
        <:page_header>
          <div class="ui-dashboard-page-heading" data-dashboard-contract="page-header">
            <div class="space-y-3">
              <div class="flex flex-wrap items-center gap-2">
                <p class="ui-kicker" data-tone="primary">EBoss dashboard</p>
                <.badge tone="neutral">Main route</.badge>
                <.badge tone="neutral">Authenticated shell</.badge>
              </div>

              <div class="space-y-2">
                <h1 class="ui-text-display" data-size="xl">
                  Welcome back, @{Map.get(@current_user, :username)}.
                </h1>
                <p class="ui-text-body" data-size="lg" data-tone="soft">
                  The main dashboard now lives inside the shared operator shell, so route work can
                  evolve without resetting navigation, identity, or session controls.
                </p>
              </div>
            </div>

            <div class="ui-dashboard-page-heading__signals">
              <.badge tone="neutral">Stable shell chrome</.badge>
              <.badge tone="neutral">Route-owned work surface</.badge>
            </div>
          </div>
        </:page_header>

        <div class="ui-dashboard-page">
          <.DashboardLaunchpad
            username={Map.get(@current_user, :username)}
            email={to_string(Map.get(@current_user, :email))}
            workspaceLabel="Workspace routes and JSON:API stay available inside the shared product frame."
            folioLabel="Folio stays workspace-scoped while reusing the same signed-in shell."
          />

          <div class="ui-dashboard-page__rail">
            <.panel
              surface="solid"
              class="space-y-4"
              data-dashboard-contract="page-content"
            >
              <p class="ui-text-meta" data-tone="primary">Route frame</p>

              <div class="space-y-2">
                <p class="ui-text-title" data-size="md">
                  Page content can change without rebuilding the shell.
                </p>
                <p class="ui-text-body" data-tone="soft">
                  The dashboard owns the working surface while identity, navigation, theme
                  controls, and sign-out stay anchored in persistent shell chrome.
                </p>
              </div>

              <ul class="ui-dashboard-page__list">
                <li>The main route keeps its own panels and launch surface.</li>
                <li>Future authenticated routes can inherit the same shell rhythm.</li>
                <li>Small and large breakpoints keep the same dashboard frame.</li>
              </ul>
            </.panel>

            <.panel tone="inverse" surface="solid" class="space-y-4">
              <div class="space-y-2">
                <p class="ui-text-meta" data-tone="primary">Shell reuse</p>
                <p class="ui-text-title" data-size="md">
                  One authenticated frame can carry the product system.
                </p>
                <p class="ui-text-body" data-tone="soft">
                  The dashboard route now reads like part of EBoss instead of a stand-alone launch
                  page, which makes the shell ready for the next signed-in surfaces.
                </p>
              </div>

              <div class="flex flex-wrap gap-2">
                <.badge tone="neutral">Persistent nav</.badge>
                <.badge tone="neutral">Stable session frame</.badge>
                <.badge tone="neutral">Route-level panels</.badge>
              </div>
            </.panel>
          </div>
        </div>
      </.dashboard_shell>
    </Layouts.app>
    """
  end
end
