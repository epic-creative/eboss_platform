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
          title_class="text-4xl"
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
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-stone-500">
                Current account
              </p>
              <p class="text-2xl font-semibold text-stone-950">
                @{Map.get(@current_user, :username)}
              </p>
              <p class="text-sm text-stone-600">{to_string(Map.get(@current_user, :email))}</p>
            </div>

            <.panel tone="inverse" surface="solid" class="space-y-3 px-5 py-6 text-ui-text">
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-ui-warning">
                Next layer
              </p>
              <p class="text-lg font-semibold">
                Attach workspaces, then bring Folio into the shell.
              </p>
              <p class="text-sm leading-6 text-ui-text-soft">
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
