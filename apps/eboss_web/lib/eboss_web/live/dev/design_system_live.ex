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
          subtitle="This surface makes the dashboard-derived visual DNA explicit so shared primitives, auth flows, and public-facing moments stay in one product language."
          title_size="lg"
        />

        <section class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Visual DNA"
            title="Operator console first, marketing polish second."
            subtitle="EBoss borrows shell discipline from the `jido_hub` dashboard reference and carries it across every surface without cloning that product."
            title_size="sm"
          />
          <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
            <.panel tone="inverse" surface="solid" class="space-y-6">
              <div class="space-y-3">
                <.badge tone="neutral">Shared thesis</.badge>
                <h2 class="ui-text-display" data-size="xl">
                  Calm control surfaces, framed precisely enough to carry real work.
                </h2>
                <p class="ui-text-body max-w-3xl" data-size="lg" data-tone="soft">
                  The shell, borders, panels, and type hierarchy should do most of the brand work.
                  Accent and motion stay secondary. If a design needs loud color, playful type, or
                  floating fragments to feel interesting, it is drifting off-brand.
                </p>
              </div>

              <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
                <div class="rounded-[1.35rem] border border-ui-border-subtle bg-ui-panel-muted/70 p-4">
                  <p class="ui-text-meta" data-tone="soft">Lean on</p>
                  <p class="ui-text-body mt-3" data-tone="muted">
                    cool surfaces, stable shell chrome, restrained type, mono metadata, and
                    utility-led emphasis
                  </p>
                </div>
                <div class="rounded-[1.35rem] border border-ui-border-subtle bg-ui-panel-muted/70 p-4">
                  <p class="ui-text-meta" data-tone="soft">Reject</p>
                  <p class="ui-text-body mt-3" data-tone="muted">
                    neon gradients, borderless cards, pitch-deck heroes, and decorative motion that
                    competes with state clarity
                  </p>
                </div>
              </div>
            </.panel>

            <div class="grid gap-4">
              <.panel
                :for={rule <- visual_dna_rules()}
                surface="floating"
                padding="sm"
                class="space-y-2"
              >
                <p class="ui-text-meta" data-tone="soft">{rule.title}</p>
                <p class="ui-text-body" data-tone="muted">{rule.copy}</p>
              </.panel>
            </div>
          </div>
        </section>

        <section class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Surface expression"
            title="One visual system, three modes of expression"
            subtitle="Dashboard stays densest, auth keeps the same trust cues with more breathing room, and public pages become more narrative without going soft or generic."
            title_size="sm"
          />
          <div class="ui-dev-preview__grid ui-dev-preview__grid--3">
            <.panel surface="floating" class="space-y-5">
              <div class="space-y-3">
                <.badge tone="neutral">Dashboard surfaces</.badge>
                <h3 class="ui-text-title" data-size="xl">
                  Strong chrome, compact hierarchy, status-first emphasis.
                </h3>
                <p class="ui-text-body" data-tone="soft">
                  This is the clearest expression of the system: framed navigation, dense groupings,
                  and signal-rich panels that stay calm under load.
                </p>
              </div>

              <div class="flex flex-wrap gap-2">
                <.nav_pill to="#queue" active>Queue</.nav_pill>
                <.nav_pill to="#agents">Agents</.nav_pill>
                <.nav_pill to="#audit">Audit</.nav_pill>
              </div>

              <div class="grid gap-3">
                <div
                  :for={item <- dashboard_signals()}
                  class="rounded-[1.35rem] border border-ui-border-subtle bg-ui-panel-muted/70 p-4"
                >
                  <p class="ui-text-meta" data-tone="soft">{item.label}</p>
                  <p class="ui-text-title mt-2" data-size="md">{item.value}</p>
                  <p class="ui-text-body mt-1" data-tone="muted">{item.copy}</p>
                </div>
              </div>
            </.panel>

            <.panel surface="floating" padding="sm">
              <.AuthScene
                eyebrow="Auth surfaces"
                title="Same shell, less noise, higher trust."
                subtitle="Entry flows keep the dashboard materials and typography, but reduce simultaneous choices and put the primary action in sharper focus."
                detailOne="One dominant action per step, with calm feedback and clear validation."
                detailTwo="Reassurance comes from control, not from consumer-app friendliness theater."
                detailThree="The transition into the private shell should feel inevitable, not stylistically disconnected."
              />
            </.panel>

            <.panel surface="floating" class="space-y-5">
              <div class="space-y-3">
                <.badge tone="neutral">Public surfaces</.badge>
                <h3 class="ui-text-display" data-size="lg">
                  Narrative rhythm, still anchored in product infrastructure.
                </h3>
                <p class="ui-text-body" data-size="lg" data-tone="soft">
                  Public pages can stretch out and sell the system, but they should stay rooted in
                  the same cool palette, precise shell framing, and proof-first content blocks.
                </p>
              </div>

              <div class="flex flex-wrap gap-3">
                <.button>Request access</.button>
                <.button variant="outline" tone="neutral">Inspect the shell</.button>
              </div>

              <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
                <div
                  :for={item <- public_proof_points()}
                  class="rounded-[1.35rem] border border-ui-border-subtle bg-ui-panel-muted/70 p-4"
                >
                  <p class="ui-text-meta" data-tone="soft">{item.label}</p>
                  <p class="ui-text-body mt-2" data-tone="muted">{item.copy}</p>
                </div>
              </div>
            </.panel>
          </div>
        </section>

        <section class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Buttons"
            title="Action styles"
            subtitle="Variant and tone combinations share the same semantic color contract."
            title_size="sm"
          />
          <.panel surface="floating" class="p-6">
            <div class="space-y-5">
              <div class="flex flex-wrap gap-3">
                <.button>Primary</.button>
                <.button variant="outline" tone="neutral">Outline</.button>
                <.button variant="subtle" tone="neutral">Subtle</.button>
                <.button variant="ghost" tone="neutral">Ghost</.button>
                <.button loading>Loading</.button>
              </div>

              <div class="space-y-3">
                <p class="ui-text-meta" data-tone="soft">Semantic tones</p>
                <div class="flex flex-wrap gap-3">
                  <.button tone="primary">Primary</.button>
                  <.button tone="neutral">Neutral</.button>
                  <.button tone="success">Success</.button>
                  <.button tone="warning">Warning</.button>
                  <.button tone="danger">Danger</.button>
                </div>
                <div class="flex flex-wrap gap-3">
                  <.button variant="outline" tone="primary">Primary outline</.button>
                  <.button variant="outline" tone="neutral">Neutral outline</.button>
                  <.button variant="outline" tone="success">Success outline</.button>
                  <.button variant="outline" tone="warning">Warning outline</.button>
                  <.button variant="outline" tone="danger">Danger outline</.button>
                </div>
              </div>
            </div>
          </.panel>
        </section>

        <section class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Fields"
            title="Form primitives"
            subtitle="Inputs, select, textarea, and checkbox all share one contract."
            title_size="sm"
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
            subtitle="Neutral, primary, success, warning, and danger all stay on one semantic palette."
            title_size="sm"
          />
          <div class="ui-dev-preview__grid ui-dev-preview__grid--3">
            <div class="ui-alert" data-tone="neutral">
              <div class="ui-alert__content">
                <p class="ui-alert__title">Operator note</p>
                <p class="ui-alert__description">
                  Default feedback stays grounded in the same shell palette as the rest of the product.
                </p>
              </div>
            </div>
            <div class="ui-alert" data-tone="primary">
              <div class="ui-alert__content">
                <p class="ui-alert__title">Queue scheduled</p>
                <p class="ui-alert__description">
                  The next orchestration step is active and using the product’s primary signal.
                </p>
              </div>
            </div>
            <div class="ui-alert" data-tone="success">
              <div class="ui-alert__content">
                <p class="ui-alert__title">Run approved</p>
                <p class="ui-alert__description">
                  Execution can continue because the latest policy checks have passed.
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
            subtitle="Shared patterns still inherit the same shell language and status semantics."
            title_size="sm"
          />
          <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
            <.panel surface="floating" class="space-y-5">
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

            <.panel tone="inverse" surface="solid" class="space-y-4">
              <div class="space-y-2">
                <p class="ui-text-meta">Pattern rule</p>
                <p class="ui-text-title" data-size="md">
                  Patterns should reveal the system, not invent a new one.
                </p>
                <p class="ui-text-body" data-tone="soft">
                  If a shared pattern needs a one-off surface treatment to feel useful, the system is
                  missing a primitive. Tighten the primitive instead of styling around it.
                </p>
              </div>
            </.panel>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  defp visual_dna_rules do
    [
      %{
        title: "Shell-first clarity",
        copy:
          "Lead with frames, borders, panels, and reading order before adding decorative moments."
      },
      %{
        title: "Restrained typography",
        copy:
          "Display marks key moments, body carries most work, and mono handles labels and operator context."
      },
      %{
        title: "Cool surface discipline",
        copy:
          "Slate, stone, ink, and canvas do the heavy lifting; accent is reserved for signal, not wallpaper."
      },
      %{
        title: "Utility-led emphasis",
        copy:
          "Hierarchy comes from spacing, density, contrast, and state treatment before illustration or saturated fill."
      },
      %{
        title: "Branded precision",
        copy:
          "Corners, shadows, highlights, and motion should feel engineered, not playful or inflated."
      }
    ]
  end

  defp dashboard_signals do
    [
      %{
        label: "Queue health",
        value: "14 active runs",
        copy:
          "Status is visible immediately without turning the shell into a neon analytics wall."
      },
      %{
        label: "Escalations",
        value: "2 waiting",
        copy:
          "Warnings stand out through tone and placement, not through decorative alarm styling."
      },
      %{
        label: "Shell rhythm",
        value: "Stable sections",
        copy:
          "Navigation, metrics, and next actions read as one system instead of isolated widgets."
      }
    ]
  end

  defp public_proof_points do
    [
      %{
        label: "Narrative",
        copy: "Larger display moments can appear here, but they still sit inside a precise shell."
      },
      %{
        label: "Proof",
        copy: "Metrics and framed content blocks keep the page grounded in product reality."
      },
      %{
        label: "Tone",
        copy:
          "Public does not mean lifestyle marketing, soft gradients, or generic startup hero patterns."
      },
      %{
        label: "Continuity",
        copy:
          "A visitor should feel the same product family when they reach sign-in or the dashboard."
      }
    ]
  end
end
