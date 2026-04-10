defmodule EBossWeb.Dev.DesignSystemLive do
  use EBossWeb, :live_view

  import EBossWeb.AuthComponents,
    only: [auth_nav: 1, auth_page: 1, auth_page_footer: 1, auth_shell: 1]

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
      <div class="ui-dev-preview" id="design-system-preview">
        <.section_heading
          eyebrow="Development route"
          title="EBoss design system"
          subtitle="Use this route as the in-app review surface for shared HEEx primitives, shells, and state treatments instead of checking them page by page across the product."
          title_size="lg"
        >
          <:actions>
            <div class="flex flex-wrap gap-2">
              <.nav_pill :for={link <- review_links()} to={link.to}>
                {link.label}
              </.nav_pill>
            </div>
          </:actions>
        </.section_heading>

        <section id="review-index" class="ui-dev-preview__section">
          <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
            <.panel surface="floating" class="space-y-5">
              <.header title_size="md">
                Shared HEEx review index
                <:subtitle>
                  Review the shell, panel, form, feedback, and navigation vocabulary here before
                  checking individual product routes.
                </:subtitle>
                <:actions>
                  <div class="flex flex-wrap gap-3">
                    <.button size="sm" href="#shells">
                      Inspect shells
                    </.button>
                    <.button
                      variant="outline"
                      tone="neutral"
                      size="sm"
                      href="#forms"
                      icon="hero-arrow-right"
                      icon_position="trailing"
                    >
                      Inspect forms
                    </.button>
                  </div>
                </:actions>
              </.header>

              <.list>
                <:item :for={item <- review_checklist()} title={item.title}>
                  {item.copy}
                </:item>
              </.list>
            </.panel>

            <.panel tone="inverse" surface="solid" class="space-y-5">
              <div class="space-y-3">
                <p class="ui-text-meta" data-tone="soft">Coverage targets</p>
                <div class="flex flex-wrap gap-2">
                  <.badge :for={target <- coverage_targets()} tone="neutral">
                    {target}
                  </.badge>
                </div>
              </div>

              <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
                <.panel as="div" surface="solid" padding="sm" class="space-y-3">
                  <p class="ui-text-meta" data-tone="soft">Review states</p>
                  <p class="ui-text-body" data-tone="muted">
                    Valid, invalid, loading, disabled, empty, success, warning, and danger states
                    should remain visible on this page as the shared primitives evolve.
                  </p>
                </.panel>

                <.panel as="div" surface="solid" padding="sm" class="space-y-3">
                  <p class="ui-text-meta" data-tone="soft">Drift guard</p>
                  <p class="ui-text-body" data-tone="muted">
                    If a shared HEEx primitive changes in the product, update this route in the same
                    pass so design review stays current.
                  </p>
                </.panel>
              </div>
            </.panel>
          </div>
        </section>

        <section id="review-matrix" class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Parity review"
            title="Theme and density review matrix"
            subtitle="Review shared shell and primitive surfaces in dark/default, dark/compact, light/default, and light/compact without leaving the app."
            title_size="sm"
          />
          <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
            <.parity_review_card
              :for={variant <- parity_variants()}
              label={variant.label}
              theme={variant.theme}
              density={variant.density}
            />
          </div>
        </section>

        <section id="panels" class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Panels"
            title="Surface vocabulary and grouped content"
            subtitle="Default stays anchored in the shell, floating handles raised moments, and solid tightens nested content without inventing a new visual language."
            title_size="sm"
          />

          <div class="ui-dev-preview__grid ui-dev-preview__grid--3">
            <.panel class="space-y-3">
              <p class="ui-text-meta" data-tone="soft">Default surface</p>
              <p class="ui-text-title" data-size="md">Anchored section chrome.</p>
              <p class="ui-text-body" data-tone="muted">
                Use this for standard panels that sit directly in the shell and should feel grounded
                rather than lifted.
              </p>
            </.panel>

            <.panel surface="floating" class="space-y-3">
              <p class="ui-text-meta" data-tone="soft">Floating surface</p>
              <p class="ui-text-title" data-size="md">Raised shell-leading chrome.</p>
              <p class="ui-text-body" data-tone="muted">
                Use this for dialogs, featured panels, and moments that should visibly lift above
                the default shell plane.
              </p>
            </.panel>

            <.panel surface="solid" class="space-y-3">
              <p class="ui-text-meta" data-tone="soft">Solid surface</p>
              <p class="ui-text-title" data-size="md">Dense inset chrome.</p>
              <p class="ui-text-body" data-tone="muted">
                Use this for grouped content nested inside another panel or scene so the hierarchy
                tightens without adding extra lift.
              </p>
            </.panel>
          </div>

          <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
            <.panel surface="floating" class="space-y-4">
              <.header title_size="md">
                Panel grouping reference
                <:subtitle>
                  Shared panels should scale from shell sections to inset cards without changing the
                  product language.
                </:subtitle>
                <:actions>
                  <div class="flex flex-wrap gap-3">
                    <.button size="sm">Review frame</.button>
                    <.button variant="outline" tone="neutral" size="sm">
                      Compare density
                    </.button>
                  </div>
                </:actions>
              </.header>

              <div class="grid gap-3">
                <.panel
                  :for={item <- dashboard_signals()}
                  as="div"
                  surface="solid"
                  padding="sm"
                  class="space-y-2"
                >
                  <p class="ui-text-meta" data-tone="soft">{item.label}</p>
                  <p class="ui-text-title" data-size="md">{item.value}</p>
                  <p class="ui-text-body" data-tone="muted">{item.copy}</p>
                </.panel>
              </div>
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

              <.list>
                <:item :for={item <- panel_review_notes()} title={item.title}>
                  {item.copy}
                </:item>
              </.list>
            </.panel>
          </div>
        </section>

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
                <.panel as="div" surface="solid" padding="sm" class="space-y-3">
                  <p class="ui-text-meta" data-tone="soft">Lean on</p>
                  <p class="ui-text-body" data-tone="muted">
                    cool surfaces, stable shell chrome, restrained type, mono metadata, and
                    utility-led emphasis
                  </p>
                </.panel>
                <.panel as="div" surface="solid" padding="sm" class="space-y-3">
                  <p class="ui-text-meta" data-tone="soft">Reject</p>
                  <p class="ui-text-body" data-tone="muted">
                    neon gradients, borderless cards, pitch-deck heroes, and decorative motion that
                    competes with state clarity
                  </p>
                </.panel>
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
                <.panel
                  :for={item <- dashboard_signals()}
                  as="div"
                  surface="solid"
                  padding="sm"
                  class="space-y-2"
                >
                  <p class="ui-text-meta" data-tone="soft">{item.label}</p>
                  <p class="ui-text-title" data-size="md">{item.value}</p>
                  <p class="ui-text-body" data-tone="muted">{item.copy}</p>
                </.panel>
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
                <.panel
                  :for={item <- public_proof_points()}
                  as="div"
                  surface="solid"
                  padding="sm"
                  class="space-y-2"
                >
                  <p class="ui-text-meta" data-tone="soft">{item.label}</p>
                  <p class="ui-text-body" data-tone="muted">{item.copy}</p>
                </.panel>
              </div>
            </.panel>
          </div>
        </section>

        <section id="shells" class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Shells"
            title="Workflow shells and page composition"
            subtitle="Review the main shell hierarchy, interior headers, data tables, and fallback content as one surface instead of checking each screen in isolation."
            title_size="sm"
          />

          <div id="shell-preview-frame" class="ui-preview-frame" data-theme="dark">
            <div class="ui-preview-shell">
              <header class="ui-shell-header">
                <div class="ui-shell-header__inner">
                  <div class="ui-shell-brand">
                    <div class="ui-brand-mark">EB</div>
                    <div class="ui-shell-brand__lockup">
                      <p class="ui-kicker">Workflow shell</p>
                      <p class="ui-text-body" data-size="sm" data-tone="soft">
                        Shared page rhythm under real content density.
                      </p>
                    </div>
                  </div>

                  <div class="ui-control-cluster">
                    <.badge tone="neutral">Dark</.badge>
                    <.button variant="outline" tone="neutral" size="sm">
                      Inspect shell
                    </.button>
                  </div>
                </div>
              </header>

              <div class="ui-preview-shell__body">
                <div class="ui-preview-shell__nav">
                  <.nav_pill to="#runs" active>Runs</.nav_pill>
                  <.nav_pill to="#agents">Agents</.nav_pill>
                  <.nav_pill to="#audit">Audit</.nav_pill>
                  <.nav_pill to="#settings">Settings</.nav_pill>
                </div>

                <div class="ui-preview-shell__grid">
                  <.panel surface="floating" class="space-y-4">
                    <.header title_size="md">
                      Operator queue
                      <:subtitle>
                        Headers, actions, and tables should read cleanly inside the same shell rhythm
                        used elsewhere in the product.
                      </:subtitle>
                      <:actions>
                        <div class="flex flex-wrap gap-3">
                          <.button size="sm">Approve queue</.button>
                          <.button variant="outline" tone="neutral" size="sm">
                            Export report
                          </.button>
                        </div>
                      </:actions>
                    </.header>

                    <.table
                      id="shell-preview-runs"
                      rows={shell_preview_rows()}
                      row_id={&"shell-run-#{&1.id}"}
                    >
                      <:col :let={row} label="Run">
                        <div class="space-y-1">
                          <p class="ui-text-title" data-size="sm">{row.name}</p>
                          <p class="ui-text-body" data-size="sm" data-tone="soft">
                            {row.summary}
                          </p>
                        </div>
                      </:col>
                      <:col :let={row} label="Owner">
                        <span class="ui-text-body" data-size="sm">{row.owner}</span>
                      </:col>
                      <:col :let={row} label="Status">
                        <.badge tone={row.tone}>{row.status}</.badge>
                      </:col>
                      <:action :let={row}>
                        <.button variant="ghost" tone="neutral" size="sm" href={"#run-#{row.id}"}>
                          Inspect
                        </.button>
                      </:action>
                    </.table>
                  </.panel>

                  <div class="grid gap-4">
                    <.panel surface="solid" padding="sm" class="space-y-4">
                      <p class="ui-text-meta" data-tone="soft">Shell review notes</p>
                      <.list>
                        <:item :for={item <- shell_review_notes()} title={item.title}>
                          {item.copy}
                        </:item>
                      </.list>
                    </.panel>

                    <.panel surface="solid" padding="sm" class="space-y-4">
                      <.empty_state
                        title="No escalations in this shell"
                        copy="Fallback states should preserve the same frame, spacing, and action treatment as busy tables."
                      >
                        <:actions>
                          <.button size="sm">Create escalation</.button>
                          <.button variant="outline" tone="neutral" size="sm">
                            Inspect history
                          </.button>
                        </:actions>
                      </.empty_state>
                    </.panel>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="forms" class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Forms"
            title="Field states and action controls"
            subtitle="Inputs, buttons, and auth entry flows should stay consistent across valid, invalid, loading, and disabled states."
            title_size="sm"
          />

          <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
            <.panel surface="floating" class="space-y-6">
              <.header title_size="md">
                Form primitives
                <:subtitle>
                  Buttons and fields share one accessibility, tone, and interaction contract.
                </:subtitle>
              </.header>

              <div class="flex flex-wrap gap-3">
                <.button size="sm" icon="hero-play">
                  Start review
                </.button>
                <.button variant="outline" tone="neutral" size="sm" loading>
                  Syncing
                </.button>
                <.button variant="subtle" tone="success" size="sm">
                  Healthy
                </.button>
                <.button
                  variant="ghost"
                  tone="neutral"
                  size="sm"
                  href="#review-path"
                  icon="hero-arrow-right"
                  icon_position="trailing"
                >
                  Read path
                </.button>
                <.button variant="outline" tone="neutral" size="sm" href="#disabled-cta" disabled>
                  Disabled CTA
                </.button>
              </div>

              <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
                <div class="space-y-4">
                  <.input
                    name="workspace_slug"
                    value="agent-foundry"
                    label="Workspace slug"
                    hint="Stable identifiers are used in URLs and API surfaces."
                    prefix="workspace/"
                  />
                  <.input
                    name="execution_mode"
                    type="select"
                    label="Execution mode"
                    prompt="Choose a mode"
                    options={[Production: "prod", Review: "review", Simulation: "sim"]}
                  />
                  <.input
                    name="review_prompt"
                    type="textarea"
                    label="Run prompt"
                    value="Summarize stalled branches and approvals before 9am."
                    hint="Long-form fields use the same border, padding, and focus treatment."
                  />
                </div>

                <div class="space-y-4">
                  <.input
                    id="operator-email-preview"
                    name="operator_email_preview"
                    value="lead-at-example.com"
                    type="email"
                    label="Operator email"
                    hint="Validation stays in place without changing the surrounding shell."
                    errors={["Use a complete email address for escalation notices."]}
                    invalid
                  />
                  <.input
                    name="locked_workspace"
                    value="foundry-core"
                    label="Locked workspace"
                    hint="Disabled controls remain legible but clearly inactive."
                    disabled
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

            <div class="space-y-3">
              <p class="ui-text-meta" data-tone="soft">Authentication shell reference</p>

              <div id="auth-shell-preview" class="ui-preview-frame" data-theme="light">
                <div class="p-6">
                  <.auth_shell
                    eyebrow="Auth shell"
                    title="The shared auth surface stays in the same system."
                    subtitle="The same panel language, navigation treatment, and form controls should hold up before the user reaches the private shell."
                    detail_one="Entry flows should inherit the same shell materials and spacing."
                    detail_two="Navigation between auth steps should feel related to the primary shell pills."
                    detail_three="Validation and feedback should land inside the same frame vocabulary."
                  >
                    <.auth_page
                      eyebrow="Entry flow"
                      title="Sign in"
                      subtitle="Review auth framing, nav, and form controls without leaving the preview route."
                      current_path="/sign-in"
                    >
                      <div class="space-y-4">
                        <.input
                          name="auth_email_preview"
                          type="email"
                          label="Email"
                          autocomplete="email"
                          value="operator@example.com"
                        />
                        <.input
                          name="auth_password_preview"
                          type="password"
                          label="Password"
                          autocomplete="current-password"
                          value="supersecret123"
                        />

                        <div class="flex items-center justify-between gap-4">
                          <a href="#forgot-password" class="ui-text-link">
                            Forgot your password?
                          </a>
                          <.button size="sm">Continue</.button>
                        </div>
                      </div>

                      <:footer>
                        <.auth_page_footer
                          prompt="Need a neighboring route?"
                          link_text="Register"
                          link_href="#register"
                          note="Preview the shell hierarchy, then carry the same frame across every auth route."
                        />
                      </:footer>
                    </.auth_page>
                  </.auth_shell>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="feedback" class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Feedback"
            title="Runtime feedback, flash messages, and semantic status"
            subtitle="Review transient and persistent feedback without depending on real redirect flows or product data."
            title_size="sm"
          />

          <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
            <.panel surface="floating" class="space-y-5">
              <.header title_size="md">
                Flash messages
                <:subtitle>
                  Use the shared flash primitive for queue-level messages so icon, spacing, and tone
                  stay aligned with the rest of the shell.
                </:subtitle>
              </.header>

              <div id="preview-flash-group" class="grid gap-3">
                <.flash
                  id="preview-flash-info"
                  kind={:info}
                  flash={%{}}
                  title="Queued for review"
                  dismissible={false}
                >
                  The preview route keeps flash spacing, icon treatment, and message tone visible
                  without relying on a real redirect.
                </.flash>

                <.flash
                  id="preview-flash-error"
                  kind={:error}
                  flash={%{}}
                  title="Delivery failed"
                  dismissible={false}
                >
                  Errors should feel urgent through contrast and structure, not through decorative
                  color noise.
                </.flash>
              </div>
            </.panel>

            <.panel surface="floating" class="space-y-5">
              <.header title_size="md">
                Inline alerts and status badges
                <:subtitle>
                  Inline alerts should reserve warning and danger tones for real state changes, while
                  badges provide compact status at a glance.
                </:subtitle>
              </.header>

              <div class="grid gap-3">
                <.alert
                  tone="neutral"
                  role="status"
                  live="polite"
                  title="Operator note"
                  description="Default feedback stays grounded in the same shell palette as the rest of the product."
                />

                <.alert
                  tone="primary"
                  role="status"
                  live="polite"
                  title="Queue scheduled"
                  description="The next orchestration step is active and using the primary product signal."
                />

                <.alert
                  tone="success"
                  role="status"
                  live="polite"
                  title="Run approved"
                  description="Execution can continue because the latest policy checks have passed."
                />

                <.alert
                  tone="warning"
                  role="alert"
                  live="assertive"
                  title="Human review requested"
                  description="A sensitive branch is waiting for operator input."
                />

                <.alert
                  tone="danger"
                  role="alert"
                  live="assertive"
                  title="Delivery failed"
                  description="The external system did not acknowledge the previous step."
                />
              </div>

              <div class="flex flex-wrap gap-2">
                <.badge :for={status <- feedback_statuses()} tone={status.tone}>
                  {status.label}
                </.badge>
              </div>
            </.panel>
          </div>
        </section>

        <section id="navigation" class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Navigation"
            title="Primary, secondary, and auth navigation patterns"
            subtitle="Navigation should feel like part of the shell rather than detached pills or route-specific styling."
            title_size="sm"
          />

          <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
            <.panel surface="floating" class="space-y-5">
              <.header title_size="md">
                Primary shell navigation
                <:subtitle>
                  Active pills should show current context, while inactive items stay visible without
                  competing with page-level actions.
                </:subtitle>
              </.header>

              <div class="space-y-4">
                <div class="flex flex-wrap gap-2">
                  <.nav_pill to="#runs" active>Runs</.nav_pill>
                  <.nav_pill to="#agents">Agents</.nav_pill>
                  <.nav_pill to="#audit">Audit</.nav_pill>
                  <.nav_pill to="#settings">Settings</.nav_pill>
                </div>

                <div class="flex flex-wrap gap-3">
                  <.button variant="outline" tone="neutral" size="sm">
                    Inspect shell
                  </.button>
                  <.button size="sm">Open workspace</.button>
                </div>
              </div>

              <.list>
                <:item :for={item <- navigation_review_notes()} title={item.title}>
                  {item.copy}
                </:item>
              </.list>
            </.panel>

            <.panel surface="floating" class="space-y-5">
              <.header title_size="md">
                Auth and route transitions
                <:subtitle>
                  Secondary navigation should keep the same spacing, radius, and interaction language
                  as the main shell.
                </:subtitle>
              </.header>

              <.auth_nav current_path="/sign-in" />

              <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
                <.panel as="div" surface="solid" padding="sm" class="space-y-2">
                  <p class="ui-text-meta" data-tone="soft">Public</p>
                  <p class="ui-text-body" data-tone="muted">
                    Entry paths use quieter actions until the primary commitment point.
                  </p>
                </.panel>

                <.panel as="div" surface="solid" padding="sm" class="space-y-2">
                  <p class="ui-text-meta" data-tone="soft">Authenticated</p>
                  <p class="ui-text-body" data-tone="muted">
                    Once inside, navigation density can increase without changing the component
                    language.
                  </p>
                </.panel>
              </div>
            </.panel>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  attr :label, :string, required: true
  attr :theme, :string, values: ~w(light dark), required: true
  attr :density, :string, values: ~w(default compact), required: true

  defp parity_review_card(assigns) do
    density_attr = if assigns.density == "compact", do: "compact", else: nil
    assigns = assign(assigns, :density_attr, density_attr)

    ~H"""
    <article class="space-y-3">
      <div class="flex items-center justify-between gap-3">
        <div class="space-y-1">
          <p class="ui-text-meta" data-tone="soft">Supported review variant</p>
          <p class="ui-text-title" data-size="sm">{@label}</p>
        </div>
        <.badge tone="neutral">{String.capitalize(@theme)}</.badge>
      </div>

      <div class="ui-preview-frame" data-theme={@theme} data-density={@density_attr}>
        <div class="ui-preview-shell">
          <header class="ui-shell-header">
            <div class="ui-shell-header__inner">
              <div class="ui-shell-brand">
                <div class="ui-brand-mark">EB</div>
                <div class="ui-shell-brand__lockup">
                  <p class="ui-kicker">Shell parity</p>
                  <p class="ui-text-body" data-size="sm" data-tone="soft">{@label}</p>
                </div>
              </div>

              <div class="ui-control-cluster">
                <.badge tone="neutral">{String.capitalize(@density)}</.badge>
                <.button variant="outline" tone="neutral" size="sm">Inspect</.button>
              </div>
            </div>
          </header>

          <div class="ui-preview-shell__body">
            <div class="ui-preview-shell__nav">
              <.nav_pill to="#runs" active>Runs</.nav_pill>
              <.nav_pill to="#agents">Agents</.nav_pill>
              <.nav_pill to="#audit">Audit</.nav_pill>
            </div>

            <div class="ui-preview-shell__grid">
              <.panel surface="floating" padding="sm" class="space-y-3">
                <div class="space-y-1">
                  <p class="ui-text-meta" data-tone="soft">Shell state</p>
                  <p class="ui-text-title" data-size="md">Hierarchy survives the mode shift.</p>
                </div>
                <p class="ui-text-body" data-tone="muted">
                  Header chrome, navigation, and primary actions should compress together without
                  losing their reading order.
                </p>
                <div class="flex flex-wrap gap-2">
                  <.button size="sm">Approve</.button>
                  <.button variant="outline" tone="neutral" size="sm">Inspect</.button>
                </div>
              </.panel>

              <.panel surface="solid" padding="sm" class="space-y-3">
                <.input
                  id={"review-#{@theme}-#{@density}"}
                  name={"review-#{@theme}-#{@density}"}
                  label="Operator note"
                  value="Parity holds across the supported shell states."
                  hint="Fields, badges, alerts, and panel framing move together across theme and density."
                />
                <.alert
                  tone="success"
                  role="status"
                  live="polite"
                  title="Review ready"
                  description="Contrast, spacing, and state cues stay legible in this combination."
                />
              </.panel>
            </div>
          </div>
        </div>
      </div>
    </article>
    """
  end

  defp review_links do
    [
      %{label: "Matrix", to: "#review-matrix"},
      %{label: "Panels", to: "#panels"},
      %{label: "Shells", to: "#shells"},
      %{label: "Forms", to: "#forms"},
      %{label: "Feedback", to: "#feedback"},
      %{label: "Navigation", to: "#navigation"}
    ]
  end

  defp review_checklist do
    [
      %{
        title: "Shell review",
        copy:
          "Check header chrome, content rhythm, and navigation hierarchy together instead of reviewing panels one at a time."
      },
      %{
        title: "Primitive coverage",
        copy:
          "Shared HEEx primitives like header, table, list, flash, button, input, nav, and empty states should all stay visible on this route."
      },
      %{
        title: "State fidelity",
        copy:
          "Keep valid, invalid, loading, disabled, success, warning, danger, and empty states here so design review does not depend on backend data."
      },
      %{
        title: "Accessibility cues",
        copy:
          "Use this page to confirm readable focus, status semantics, and disabled-action treatment without stepping through the full product."
      }
    ]
  end

  defp coverage_targets do
    [
      "Layouts.app",
      "section_heading",
      "header",
      "panel",
      "table",
      "list",
      "button",
      "input",
      "flash",
      "auth_nav",
      "auth_shell"
    ]
  end

  defp parity_variants do
    [
      %{label: "Dark / default", theme: "dark", density: "default"},
      %{label: "Dark / compact", theme: "dark", density: "compact"},
      %{label: "Light / default", theme: "light", density: "default"},
      %{label: "Light / compact", theme: "light", density: "compact"}
    ]
  end

  defp panel_review_notes do
    [
      %{
        title: "Anchored sections",
        copy:
          "Default panels should feel attached to the shell, not like free-floating cards dropped onto a page."
      },
      %{
        title: "Inset grouping",
        copy:
          "Solid panels are for nested content and fallback states that need tighter grouping without more elevation."
      },
      %{
        title: "Raised moments",
        copy:
          "Floating panels should be reserved for featured or interruptive content so their lift stays meaningful."
      }
    ]
  end

  defp shell_preview_rows do
    [
      %{
        id: "queue-sync",
        name: "Policy sync for onboarding",
        summary: "Two approvals are still pending before the rollout can continue.",
        owner: "@ops_lead",
        status: "Needs review",
        tone: "warning"
      },
      %{
        id: "audit-report",
        name: "Weekly audit export",
        summary: "All checks passed and the report package is ready for delivery.",
        owner: "@finance_ops",
        status: "Healthy",
        tone: "success"
      },
      %{
        id: "workspace-import",
        name: "Workspace import",
        summary: "The queue is staged and waiting on the next orchestration step.",
        owner: "@platform",
        status: "Queued",
        tone: "primary"
      }
    ]
  end

  defp shell_review_notes do
    [
      %{
        title: "Headers stay utility-first",
        copy:
          "Page-level headers should lead with status, next actions, and context instead of decorative hero treatment."
      },
      %{
        title: "Tables live inside the shell system",
        copy:
          "Dense data views still need the same border, spacing, and action treatment as the rest of the interface."
      },
      %{
        title: "Fallbacks keep the frame",
        copy:
          "Empty states should occupy the same surface hierarchy as busy data views so the route never feels visually reset."
      }
    ]
  end

  defp feedback_statuses do
    [
      %{label: "Queued", tone: "neutral"},
      %{label: "In progress", tone: "primary"},
      %{label: "Healthy", tone: "success"},
      %{label: "Needs review", tone: "warning"},
      %{label: "Blocked", tone: "danger"}
    ]
  end

  defp navigation_review_notes do
    [
      %{
        title: "Primary context",
        copy:
          "Active nav pills should show where the operator is without overpowering page-level buttons or alerts."
      },
      %{
        title: "Secondary route changes",
        copy:
          "Auth navigation should use the same component family and spacing rules as the private shell instead of introducing a separate tab language."
      },
      %{
        title: "Continuity across states",
        copy:
          "Public, auth, and authenticated navigation should all feel like one system moving through different density levels."
      }
    ]
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
