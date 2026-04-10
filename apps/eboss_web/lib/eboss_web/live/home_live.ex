defmodule EBossWeb.HomeLive do
  use EBossWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "EBoss")

    if socket.assigns.current_user do
      {:ok, redirect(socket, to: ~p"/dashboard")}
    else
      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={assigns[:current_user]}
    >
      <section class="ui-hero-grid">
        <div class="space-y-8">
          <.section_heading
            eyebrow="Workspace-native operations"
            title="Keep the control surface sharp while the agent domains grow."
            subtitle="EBoss keeps orchestration, workspaces, and planning flows legible without turning the product into an anxious dashboard."
            title_class="max-w-4xl text-5xl sm:text-6xl"
          />

          <div class="flex flex-wrap gap-4">
            <.button navigate={~p"/register"} size="lg">
              Create your account
            </.button>
            <.button navigate={~p"/sign-in"} variant="outline" tone="neutral" size="lg">
              Sign in
            </.button>
          </div>

          <dl class="ui-card-grid ui-card-grid--3">
            <div class="ui-metric-card">
              <dt class="text-xs font-semibold uppercase tracking-[0.24em] text-stone-500">
                Identity
              </dt>
              <dd class="mt-3 text-sm leading-6 text-ui-text-muted">
                Email confirmation, magic links, and password flows stay on AshAuthentication’s happy path.
              </dd>
            </div>
            <div class="ui-metric-card">
              <dt class="text-xs font-semibold uppercase tracking-[0.24em] text-stone-500">
                Workspaces
              </dt>
              <dd class="mt-3 text-sm leading-6 text-ui-text-muted">
                Owner-aware routing and API-ready boundaries are already in place for the larger application to come.
              </dd>
            </div>
            <div class="ui-metric-card">
              <dt class="text-xs font-semibold uppercase tracking-[0.24em] text-stone-500">Folio</dt>
              <dd class="mt-3 text-sm leading-6 text-ui-text-muted">
                Planning primitives, audit history, and strict workspace scoping are ready for the next layer.
              </dd>
            </div>
          </dl>
        </div>

        <.panel surface="floating" class="ui-frame-card">
          <.AuthScene
            eyebrow="Authentication foundation"
            title="Custom pages, standard auth engine"
            subtitle="The web layer stays first-party and branded while Ash handles strategy rules, token lifecycles, and sessions."
            detailOne="Custom LiveView pages with LiveVue-backed presentation"
            detailTwo="Password, reset, confirm, and magic-link flows on existing auth routes"
            detailThree="A private dashboard gate for authenticated users only"
          />
        </.panel>
      </section>
    </Layouts.app>
    """
  end
end
