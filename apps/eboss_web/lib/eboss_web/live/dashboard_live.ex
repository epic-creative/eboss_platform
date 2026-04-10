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
          <.dashboard_header
            id="dashboard-top"
            class="ui-dashboard-page-heading"
            eyebrow="EBoss dashboard"
            title={"Welcome back, @#{Map.get(@current_user, :username)}."}
            description="The main dashboard now lives inside the shared operator shell, so route work can evolve without resetting navigation, identity, session controls, or lightweight command cues."
            title_tag="h1"
            title_size="xl"
            data-dashboard-contract="page-header"
          >
            <:badge>
              <.badge tone="neutral">Main route</.badge>
            </:badge>
            <:badge>
              <.badge tone="neutral">Authenticated shell</.badge>
            </:badge>
            <:signal>
              <.badge tone="neutral">Stable shell chrome</.badge>
            </:signal>
            <:signal>
              <.badge tone="neutral">Command cues visible</.badge>
            </:signal>
            <:actions>
              <.dashboard_action_bar>
                <.button href="#dashboard-utilities" variant="outline" tone="neutral" size="sm">
                  Command surface
                </.button>
                <.button href="#dashboard-structure" variant="ghost" tone="neutral" size="sm">
                  Panel grouping
                </.button>
              </.dashboard_action_bar>
            </:actions>
          </.dashboard_header>
        </:page_header>

        <:sidebar_footer>
          <.dashboard_quick_actions
            id="dashboard-quick-actions"
            title="Quick actions"
            description="Mnemonic route cues keep the next jump obvious while the dashboard stays visually calm."
          >
            <:action
              id="open-launch-surface"
              label="Open launch surface"
              description="Return to the primary operator lane and route-owned workspace context."
              href="#dashboard-launchpad"
              shortcut="GL"
              badge="Primary"
              tone="primary"
              icon="hero-bolt"
            />
            <:action
              id="inspect-panel-rhythm"
              label="Inspect panel rhythm"
              description="Review the support rail, grouped panels, and shell reuse notes."
              href="#dashboard-structure"
              shortcut="GR"
              badge="Review"
              tone="neutral"
              icon="hero-rectangle-stack"
            />
            <:action
              id="audit-fallback-states"
              label="Audit fallback states"
              description="Check empty, loading, and recovery treatments without leaving the route."
              href="#dashboard-states"
              shortcut="GS"
              badge="States"
              tone="warning"
              icon="hero-exclamation-triangle"
            />
          </.dashboard_quick_actions>
        </:sidebar_footer>

        <div class="ui-dashboard-page" data-dashboard-contract="page-content">
          <.dashboard_utility_strip
            id="dashboard-utilities"
            class="lg:col-span-2"
            title="Command surface"
            description="Keep route orientation and the next move visible with lightweight jump cues instead of heavier workflow chrome."
          >
            <:item
              id="primary-lane"
              label="Primary lane"
              value="Launch surface"
              hint="Route-owned workspace entry"
              href="#dashboard-launchpad"
              shortcut="GL"
              tone="primary"
              icon="hero-bolt"
            />
            <:item
              id="supporting-rail"
              label="Supporting rail"
              value="Panel grouping"
              hint="Review structure and shell reuse"
              href="#dashboard-structure"
              shortcut="GR"
              tone="neutral"
              icon="hero-rectangle-stack"
            />
            <:item
              id="state-audit"
              label="State audit"
              value="Fallback states"
              hint="Check empty, loading, and error treatment"
              href="#dashboard-states"
              shortcut="GS"
              tone="warning"
              icon="hero-command-line"
            />
            <:item
              id="shell-frame"
              label="Shell frame"
              value="Route context"
              hint="Identity and controls stay pinned"
              href="#dashboard-top"
              shortcut="GT"
              tone="neutral"
              icon="hero-shield-check"
            />
          </.dashboard_utility_strip>

          <.dashboard_section id="dashboard-launchpad" section="launchpad">
            <.dashboard_header
              eyebrow="Launch surface"
              title="Route-owned work stays easy to scan."
              description="The main launch area uses the same section framing, action placement, and spacing rules as the supporting rail."
            >
              <:signal>
                <.badge tone="neutral">Primary work surface</.badge>
              </:signal>
              <:signal>
                <.badge tone="neutral">Repeatable section header</.badge>
              </:signal>
              <:actions>
                <.dashboard_action_bar>
                  <.button href="#dashboard-structure" variant="outline" tone="neutral" size="sm">
                    Shell contract
                  </.button>
                  <.button href="#dashboard-panel-rhythm" variant="ghost" tone="neutral" size="sm">
                    Panel rhythm
                  </.button>
                </.dashboard_action_bar>
              </:actions>
            </.dashboard_header>

            <.DashboardLaunchpad
              username={Map.get(@current_user, :username)}
              email={to_string(Map.get(@current_user, :email))}
              workspaceLabel="Workspace routes and JSON:API stay available inside the shared product frame."
              folioLabel="Folio stays workspace-scoped while reusing the same signed-in shell."
            />
          </.dashboard_section>

          <.dashboard_section
            id="dashboard-structure"
            section="structure"
            class="ui-dashboard-page__rail"
          >
            <.dashboard_header
              eyebrow="Working structure"
              title="Panel groupings stay systematic instead of page-specific."
              description="Supporting panels now share one header pattern, one action bar rhythm, and one grouped layout contract for authenticated product work."
            >
              <:signal>
                <.badge tone="neutral">Shared panel framing</.badge>
              </:signal>
              <:signal>
                <.badge tone="neutral">Consistent actions</.badge>
              </:signal>
              <:actions>
                <.dashboard_action_bar>
                  <.button href="#dashboard-launchpad" variant="outline" tone="neutral" size="sm">
                    Launch surface
                  </.button>
                  <.button href="#dashboard-top" variant="ghost" tone="neutral" size="sm">
                    Back to top
                  </.button>
                </.dashboard_action_bar>
              </:actions>
            </.dashboard_header>

            <.dashboard_panel_group columns="stack">
              <.panel id="dashboard-frame" surface="solid" class="space-y-4">
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

              <.panel id="dashboard-panel-rhythm" tone="inverse" surface="solid" class="space-y-4">
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
            </.dashboard_panel_group>
          </.dashboard_section>

          <.dashboard_section id="dashboard-states" section="states" class="lg:col-span-2">
            <.dashboard_header
              eyebrow="State contract"
              title="Empty, loading, and error states stay in the dashboard language."
              description="Sparse launch surfaces and dense support panels now share one fallback pattern, so the route keeps its structure before deeper workflow implementation arrives."
            >
              <:signal>
                <.badge tone="neutral">Shared visual contract</.badge>
              </:signal>
              <:signal>
                <.badge tone="neutral">Sparse and dense ready</.badge>
              </:signal>
              <:actions>
                <.dashboard_action_bar>
                  <.button href="#dashboard-launchpad" variant="outline" tone="neutral" size="sm">
                    Launch surface
                  </.button>
                  <.button href="#dashboard-structure" variant="ghost" tone="neutral" size="sm">
                    Panel grouping
                  </.button>
                </.dashboard_action_bar>
              </:actions>
            </.dashboard_header>

            <div class="ui-split-grid">
              <.dashboard_empty_state
                density="sparse"
                title="Nothing is queued for this workspace yet."
                description="The launch area keeps its frame, action placement, and supporting structure visible so the route reads like a ready workspace instead of a temporary placeholder."
                details={[
                  "Primary actions stay where operators expect them.",
                  "Metrics, rows, and supporting notes keep their footprint reserved."
                ]}
              >
                <:actions>
                  <.button href="#dashboard-launchpad" size="sm">
                    Review launch surface
                  </.button>
                  <.button href="#dashboard-structure" variant="outline" tone="neutral" size="sm">
                    Inspect structure
                  </.button>
                </:actions>
              </.dashboard_empty_state>

              <div class="grid gap-4">
                <.dashboard_loading_state
                  density="dense"
                  title="Workspace signals are syncing."
                  description="Loading keeps the compact panel footprint and reserves the next set of tiles and rows so the rail stays readable while data resolves."
                >
                  <:actions>
                    <.button href="#dashboard-panel-rhythm" variant="ghost" tone="neutral" size="sm">
                      Review rail rhythm
                    </.button>
                  </:actions>
                </.dashboard_loading_state>

                <.dashboard_error_state
                  density="dense"
                  title="The latest sync did not complete."
                  description="Recovery guidance stays inside the same grouped panel treatment instead of dropping into a generic framework alert."
                >
                  <:actions>
                    <.button href="#dashboard-structure" size="sm">
                      Retry flow
                    </.button>
                    <.button href="#dashboard-top" variant="outline" tone="neutral" size="sm">
                      Review shell context
                    </.button>
                  </:actions>
                </.dashboard_error_state>
              </div>
            </div>
          </.dashboard_section>
        </div>
      </.dashboard_shell>
    </Layouts.app>
    """
  end
end
