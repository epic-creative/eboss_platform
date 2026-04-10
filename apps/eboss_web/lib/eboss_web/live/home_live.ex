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
      shell_mode="public"
      current_path="/"
    >
      <section class="ui-hero-grid">
        <div class="space-y-8">
          <.section_heading
            eyebrow="Workspace-native operations"
            title="Keep the control surface sharp while the agent domains grow."
            subtitle="EBoss keeps orchestration, workspaces, and planning flows legible without turning the product into an anxious dashboard."
            title_size="hero"
            title_class="max-w-4xl"
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
            <.panel as="div" surface="solid" padding="sm" class="ui-metric-card">
              <dt class="ui-text-meta" data-tone="muted">Identity</dt>
              <dd class="ui-text-body mt-3" data-tone="muted">
                Email confirmation, magic links, and password flows stay on AshAuthentication’s happy path.
              </dd>
            </.panel>
            <.panel as="div" surface="solid" padding="sm" class="ui-metric-card">
              <dt class="ui-text-meta" data-tone="muted">Workspaces</dt>
              <dd class="ui-text-body mt-3" data-tone="muted">
                Owner-aware routing and API-ready boundaries are already in place for the larger application to come.
              </dd>
            </.panel>
            <.panel as="div" surface="solid" padding="sm" class="ui-metric-card">
              <dt class="ui-text-meta" data-tone="muted">Folio</dt>
              <dd class="ui-text-body mt-3" data-tone="muted">
                Planning primitives, audit history, and strict workspace scoping are ready for the next layer.
              </dd>
            </.panel>
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

      <:shell_footer>
        <Layouts.public_cta_frame
          eyebrow="Public launch frame"
          title="Move from public access into the working shell without changing products."
          subtitle="Registration, sign-in, recovery, and dashboard handoff now sit inside the same frame, materials, and interaction posture."
          primary_label="Create your account"
          primary_to={~p"/register"}
          secondary_label="Sign in"
          secondary_to={~p"/sign-in"}
        >
          <:details>
            <.panel as="div" surface="solid" padding="sm" class="space-y-2">
              <p class="ui-text-meta" data-tone="soft">Route family</p>
              <p class="ui-text-body" data-size="sm" data-tone="muted">
                Home, sign-in, registration, recovery, and token confirmation stay visually aligned.
              </p>
            </.panel>

            <.panel as="div" surface="solid" padding="sm" class="space-y-2">
              <p class="ui-text-meta" data-tone="soft">State parity</p>
              <p class="ui-text-body" data-size="sm" data-tone="muted">
                Theme changes and compact density use the same system tokens as the dashboard and auth cards.
              </p>
            </.panel>

            <.panel as="div" surface="solid" padding="sm" class="space-y-2">
              <p class="ui-text-meta" data-tone="soft">Session handoff</p>
              <p class="ui-text-body" data-size="sm" data-tone="muted">
                The final transition still resolves directly into the authenticated dashboard shell.
              </p>
            </.panel>
          </:details>
        </Layouts.public_cta_frame>
      </:shell_footer>
    </Layouts.app>
    """
  end
end
