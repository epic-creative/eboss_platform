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
      <.dashboard_shell current_user={@current_user} current_path="/dashboard">
        <:page_header>
          <div class="ui-dashboard-page-heading" data-dashboard-contract="page-header">
            <div class="space-y-3">
              <div class="flex flex-wrap items-center gap-2">
                <p class="ui-kicker" data-tone="primary">Dashboard convergence</p>
                <.badge tone="neutral">Reusable shell</.badge>
              </div>

              <div class="space-y-2">
                <h1 class="ui-text-display" data-size="xl">
                  Welcome back, @{Map.get(@current_user, :username)}.
                </h1>
                <p class="ui-text-body" data-size="lg" data-tone="soft">
                  Keep route context, operator identity, and working panels aligned as EBoss
                  grows deeper into authenticated surfaces.
                </p>
              </div>
            </div>

            <div class="ui-dashboard-page-heading__signals">
              <.badge tone="neutral">Authenticated surface</.badge>
              <.badge tone="neutral">Product-specific rhythm</.badge>
            </div>
          </div>
        </:page_header>

        <div class="ui-dashboard-page">
          <.panel surface="floating" class="ui-frame-card">
            <.DashboardLaunchpad
              username={Map.get(@current_user, :username)}
              email={to_string(Map.get(@current_user, :email))}
              workspaceLabel="Workspace routes and JSON:API are live"
              folioLabel="Folio remains workspace-scoped and boundary-driven"
            />
          </.panel>

          <div class="ui-dashboard-page__rail">
            <.panel
              surface="solid"
              class="space-y-4"
              data-dashboard-contract="page-content"
            >
              <p class="ui-text-meta" data-tone="primary">Route focus</p>

              <div class="space-y-2">
                <p class="ui-text-title" data-size="md">
                  Primary work can change without resetting operator context.
                </p>
                <p class="ui-text-body" data-tone="soft">
                  Route-specific actions, states, and panels belong in the working surface while
                  identity, navigation, and utilities stay anchored in the shell.
                </p>
              </div>

              <ul class="ui-dashboard-page__list">
                <li>Operational summaries land inside the page body.</li>
                <li>State changes keep the same frame on small and large screens.</li>
                <li>Future authenticated surfaces can reuse the scaffold without detouring.</li>
              </ul>
            </.panel>

            <.panel tone="inverse" surface="solid" class="space-y-4">
              <div class="space-y-2">
                <p class="ui-text-meta" data-tone="primary">System states</p>
                <p class="ui-text-title" data-size="md">
                  Theme and density stay in one rhythm.
                </p>
                <p class="ui-text-body" data-tone="soft">
                  Dark and light themes, default and compact density, and signed-in route changes
                  all keep the shell legible and intact.
                </p>
              </div>

              <div class="flex flex-wrap gap-2">
                <.badge tone="neutral">Dark / default</.badge>
                <.badge tone="neutral">Dark / compact</.badge>
                <.badge tone="neutral">Light / default</.badge>
                <.badge tone="neutral">Light / compact</.badge>
              </div>
            </.panel>
          </div>
        </div>
      </.dashboard_shell>
    </Layouts.app>
    """
  end
end
