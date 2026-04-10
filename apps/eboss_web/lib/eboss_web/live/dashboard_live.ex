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
      <section class="space-y-8">
        <.section_heading
          eyebrow="Authenticated shell"
          title={"Welcome back, @#{Map.get(@current_user, :username)}."}
          subtitle="This dashboard is intentionally lean. It confirms the session boundary, gives the authenticated user a stable landing page, and leaves room for the orchestration surfaces to grow."
          title_size="lg"
        />

        <div class="ui-split-grid">
          <.panel surface="floating" class="ui-frame-card">
            <.DashboardLaunchpad
              username={Map.get(@current_user, :username)}
              email={to_string(Map.get(@current_user, :email))}
              workspaceLabel="Workspace routes and JSON:API are live"
              folioLabel="Folio remains workspace-scoped and boundary-driven"
            />
          </.panel>

          <.panel surface="floating" class="space-y-4 p-8">
            <div class="space-y-2">
              <p class="ui-text-meta" data-tone="muted">Current account</p>
              <p class="ui-text-title" data-size="lg">
                @{Map.get(@current_user, :username)}
              </p>
              <p class="ui-text-body" data-size="sm" data-tone="soft">
                {to_string(Map.get(@current_user, :email))}
              </p>
            </div>

            <.panel tone="inverse" surface="solid" class="space-y-3 px-5 py-6">
              <p class="ui-text-meta" data-tone="primary">Next layer</p>
              <p class="ui-text-title" data-size="md">
                Attach workspaces, then bring Folio into the shell.
              </p>
              <p class="ui-text-body" data-tone="soft">
                This page is the authenticated anchor for the rest of the application. Everything else can grow outward from here.
              </p>
            </.panel>

            <form action={~p"/logout"} method="post">
              <input type="hidden" name="_method" value="delete" />
              <.button
                type="submit"
                variant="outline"
                tone="neutral"
                icon="hero-arrow-left-on-rectangle"
              >
                Sign out
              </.button>
            </form>
          </.panel>
        </div>
      </section>
    </Layouts.app>
    """
  end
end
