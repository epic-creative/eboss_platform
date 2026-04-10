defmodule EBossWeb.Dev.DesignSystemLive do
  use EBossWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Design System")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={assigns[:current_user]}
    >
      <div class="ui-dev-preview">
        <.section_heading
          eyebrow="Development route"
          title="EBoss design system"
          subtitle="This surface previews the first-party HEEx primitives and page patterns in the same shell the product uses."
          title_class="text-4xl"
        />

        <section class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Buttons"
            title="Action styles"
            subtitle="Solid, outline, subtle, ghost, and loading states."
            title_class="text-2xl"
          />
          <.panel surface="floating" class="p-6">
            <div class="flex flex-wrap gap-3">
              <.button>Primary</.button>
              <.button variant="outline" tone="neutral">Outline</.button>
              <.button variant="subtle" tone="neutral">Subtle</.button>
              <.button variant="ghost" tone="neutral">Ghost</.button>
              <.button loading>Loading</.button>
            </div>
          </.panel>
        </section>

        <section class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Fields"
            title="Form primitives"
            subtitle="Inputs, select, textarea, and checkbox all share one contract."
            title_class="text-2xl"
          />
          <.panel surface="floating" class="p-6">
            <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
              <div class="space-y-4">
                <.input
                  name="workspace"
                  value="agent-foundry"
                  label="Workspace slug"
                  hint="Stable identifiers are used in URLs and API surfaces."
                  prefix="workspace/"
                />
                <.input
                  name="operator_email"
                  value="lead@example.com"
                  type="email"
                  label="Operator email"
                />
                <.input
                  name="orchestration_mode"
                  type="select"
                  label="Execution mode"
                  prompt="Choose a mode"
                  options={[Production: "prod", Review: "review", Simulation: "sim"]}
                />
              </div>

              <div class="space-y-4">
                <.input
                  name="notes"
                  type="textarea"
                  label="Run prompt"
                  value="Summarize stalled branches and approvals before 9am."
                  hint="Long-form inputs use the same shell."
                />
                <.input
                  name="notify"
                  type="checkbox"
                  label="Notify operators when a run stalls"
                  hint="Checkboxes keep the same focus and validation treatment."
                  checked
                />
              </div>
            </div>
          </.panel>
        </section>

        <section class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Feedback"
            title="Alerts and status"
            subtitle="Inline feedback components for success, warning, and errors."
            title_class="text-2xl"
          />
          <div class="ui-dev-preview__grid ui-dev-preview__grid--3">
            <div class="ui-alert" data-tone="primary">
              <div class="ui-alert__content">
                <p class="ui-alert__title">Queue healthy</p>
                <p class="ui-alert__description">
                  Agents are making progress with no approval backlog.
                </p>
              </div>
            </div>
            <div class="ui-alert" data-tone="warning">
              <div class="ui-alert__content">
                <p class="ui-alert__title">Human review requested</p>
                <p class="ui-alert__description">A sensitive branch is waiting for operator input.</p>
              </div>
            </div>
            <div class="ui-alert" data-tone="danger">
              <div class="ui-alert__content">
                <p class="ui-alert__title">Delivery failed</p>
                <p class="ui-alert__description">
                  The external system did not acknowledge the previous step.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Patterns"
            title="Panels, nav, and empty states"
            subtitle="Shared surface patterns used across auth and dashboard flows."
            title_class="text-2xl"
          />
          <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
            <.panel surface="floating" class="space-y-5 p-6">
              <div class="flex flex-wrap gap-2">
                <.nav_pill to="#runs" active>Runs</.nav_pill>
                <.nav_pill to="#agents">Agents</.nav_pill>
                <.nav_pill to="#audit">Audit</.nav_pill>
              </div>

              <.empty_state
                title="No active runs"
                copy="Start a run, import a plan, or attach an integration to begin populating this workspace."
              >
                <:actions>
                  <.button>Start a run</.button>
                  <.button variant="outline" tone="neutral">Import plan</.button>
                </:actions>
              </.empty_state>
            </.panel>

            <.panel surface="floating" class="p-4">
              <.AuthScene
                eyebrow="Auth shell"
                title="First-party auth pages"
                subtitle="A branded shell around the existing authentication engine."
                detailOne="Password and magic-link flows stay consistent."
                detailTwo="Validation feedback reuses shared form contracts."
                detailThree="The same shell extends into the dashboard and control surfaces."
              />
            </.panel>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
