defmodule EBossWeb.Dev.DesignSystemLive do
  use EBossWeb, :live_view

  import EBossWeb.AuthComponents,
    only: [
      auth_form: 1,
      auth_nav: 1,
      auth_page: 1,
      auth_page_footer: 1,
      auth_shell: 1,
      auth_submit: 1
    ]

  @public_section_patterns EBossWeb.PublicPagePatterns

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

        <section id="public-patterns" class="ui-dev-preview__section" data-public-pattern-catalog>
          <.section_heading
            eyebrow="Public patterns"
            title="Reusable public section patterns"
            subtitle="Name the recurring public section types once here, then migrate individual routes onto the same vocabulary without redefining the layout contract each time."
            title_size="sm"
          />

          <div class="ui-public-pattern-catalog">
            <.panel
              :for={pattern <- public_section_patterns()}
              surface="floating"
              class="ui-public-pattern-card"
              data-public-pattern-definition={pattern.slug}
            >
              <div class="ui-public-pattern-card__header">
                <div class="space-y-3">
                  <div class="flex flex-wrap gap-2">
                    <.badge tone="neutral">{pattern.label}</.badge>
                    <.badge tone={public_pattern_badge_tone(pattern.repeatability)}>
                      {public_pattern_badge_label(pattern.repeatability)}
                    </.badge>
                  </div>
                  <div class="space-y-2">
                    <h3 class="ui-text-title" data-size="lg">{pattern.summary}</h3>
                    <p class="ui-text-body" data-tone="muted">{pattern.use_when}</p>
                  </div>
                </div>

                <.panel as="div" surface="solid" padding="sm" class="space-y-2">
                  <p class="ui-text-meta" data-tone="soft">Variants</p>
                  <div class="flex flex-wrap gap-2">
                    <.badge :for={variant <- pattern.variants} tone="neutral">
                      {variant}
                    </.badge>
                  </div>
                </.panel>
              </div>

              <div class="ui-public-pattern-card__slots">
                <.panel
                  :for={slot <- pattern.required_slots}
                  as="div"
                  surface="solid"
                  padding="sm"
                  class="ui-public-pattern-card__slot"
                >
                  <p class="ui-text-meta" data-tone="primary">Required: {slot.label}</p>
                  <p class="ui-text-body" data-size="sm" data-tone="muted">{slot.description}</p>
                </.panel>

                <.panel
                  :for={slot <- pattern.optional_slots}
                  as="div"
                  surface="solid"
                  padding="sm"
                  class="ui-public-pattern-card__slot"
                >
                  <p class="ui-text-meta" data-tone="soft">Optional: {slot.label}</p>
                  <p class="ui-text-body" data-size="sm" data-tone="muted">{slot.description}</p>
                </.panel>
              </div>
            </.panel>
          </div>

          <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
            <.panel surface="floating" class="space-y-4">
              <div class="space-y-2">
                <p class="ui-text-meta" data-tone="soft">Current home-page mapping</p>
                <h3 class="ui-text-title" data-size="md">
                  The existing home route now points at the standardized pattern names.
                </h3>
                <p class="ui-text-body" data-tone="muted">
                  The page keeps its current markup, but each major section now advertises the
                  target pattern name for later migration work.
                </p>
              </div>

              <div class="ui-public-pattern-map">
                <.panel
                  :for={section <- public_home_page_sections()}
                  as="div"
                  surface="solid"
                  padding="sm"
                  class="space-y-2"
                >
                  <p class="ui-text-meta" data-tone="soft">{section.label}</p>
                  <p class="ui-text-title" data-size="sm">
                    {public_section_pattern_label(section.pattern)}
                  </p>
                  <p class="ui-text-body" data-size="sm" data-tone="muted">
                    {section.selector} - {section.variant}
                  </p>
                </.panel>
              </div>
            </.panel>

            <.panel tone="inverse" surface="solid" class="space-y-4">
              <div class="space-y-2">
                <p class="ui-text-meta">Composition rules</p>
                <h3 class="ui-text-title" data-size="md">
                  Repeat proof, feature, and CTA patterns. Keep hero and closing anchored.
                </h3>
              </div>

              <.list>
                <:item title="Anchor patterns">
                  Hero and closing section should appear once so the page opens and resolves cleanly.
                </:item>
                <:item title="Repeatable patterns">
                  Proof band, feature row, and CTA band can be reused across public routes without
                  inventing one-off layouts.
                </:item>
                <:item title="Review language">
                  Public review can now talk about hero, proof band, feature row, CTA band, and
                  closing section directly in code and in the browser.
                </:item>
              </.list>
            </.panel>
          </div>
        </section>

        <section id="shells" class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Shells"
            title="Runtime shell composition"
            subtitle="Review the actual Lovable-derived public, auth, and workspace shell direction in one place instead of checking old mock shells."
            title_size="sm"
          />

          <div class="grid gap-4">
            <.panel surface="solid" padding="sm" class="space-y-4">
              <p class="ui-text-meta" data-tone="soft">Review focus</p>
              <.list>
                <:item title="Public shell">
                  Check the real landing route framing, header chrome, proof panel treatment, and
                  CTA rhythm.
                </:item>
                <:item title="Auth shell">
                  Check the compact auth frame, card edges, tabs, feedback, and form density against
                  the Lovable source.
                </:item>
                <:item title="Workspace shell">
                  Check the real sidebar, top bar, search, action states, and inspector relationship
                  instead of reviewing a fake dashboard shell.
                </:item>
              </.list>
            </.panel>

            <div class="ui-dev-preview__grid ui-dev-preview__grid--2">
              <div class="space-y-3">
                <p class="ui-text-meta" data-tone="soft">Public landing runtime</p>
                <div class="ui-runtime-preview ui-runtime-preview--public" data-theme="light">
                  <.ShellOperatorLanding />
                </div>
              </div>

              <div class="space-y-3">
                <p class="ui-text-meta" data-tone="soft">Auth shell reference</p>
                <div class="ui-runtime-preview ui-runtime-preview--auth" data-theme="light">
                  <div class="p-6">
                    <.auth_shell current_path="/sign-in">
                      <.auth_page
                        title="Sign in"
                        subtitle="Compact auth shell and form density aligned to the Lovable source."
                      >
                        <.auth_nav current_path="/sign-in" />

                        <.auth_form
                          for={to_form(%{}, as: :runtime_shell_preview)}
                          id="auth-shell-runtime-preview"
                        >
                          <.input
                            name="auth_email_shell_preview"
                            type="email"
                            label="Email address"
                            autocomplete="email"
                            value="operator@example.com"
                          />
                          <.input
                            name="auth_password_shell_preview"
                            type="password"
                            label="Password"
                            autocomplete="current-password"
                            value="supersecret123"
                          />

                          <:actions :let={_form}>
                            <a href="#forgot-password" class="ui-text-link text-xs">
                              Forgot password?
                            </a>
                            <.auth_submit label="Sign in" busy_label="Signing in..." tone="success" />
                          </:actions>
                        </.auth_form>

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

            <div class="space-y-3">
              <p class="ui-text-meta" data-tone="soft">Workspace shell runtime</p>
              <div class="ui-runtime-preview ui-runtime-preview--workspace" data-theme="dark">
                <.ShellOperatorWorkspaceApp
                  currentUser={runtime_preview_user()}
                  currentScope={runtime_preview_scope()}
                  currentPage="dashboard"
                  currentPath={runtime_preview_dashboard_path()}
                  signOutPath="#sign-out"
                  csrfToken="preview-token"
                />
              </div>
            </div>
          </div>
        </section>

        <section id="dashboard-commands" class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Dashboard commands"
            title="Quick actions and utility cues stay light but task-oriented."
            subtitle="Review the command-surface treatment without implying a full workflow palette or custom key handling."
            title_size="sm"
          />

          <div class="grid gap-4">
            <.dashboard_utility_strip
              title="Command surface"
              description="Keep route orientation and the next move visible with lightweight jump cues instead of heavier dashboard chrome."
            >
              <:item
                id="preview-primary-lane"
                label="Primary lane"
                value="Launch surface"
                hint="Route-owned workspace entry"
                href="#dashboard-states"
                shortcut="GL"
                tone="primary"
                icon="hero-bolt"
              />
              <:item
                id="preview-supporting-rail"
                label="Supporting rail"
                value="Panel grouping"
                hint="Review structure and reuse"
                href="#shells"
                shortcut="GR"
                tone="neutral"
                icon="hero-rectangle-stack"
              />
              <:item
                id="preview-state-audit"
                label="State audit"
                value="Fallback states"
                hint="Inspect empty, loading, and recovery"
                href="#feedback"
                shortcut="GS"
                tone="warning"
                icon="hero-command-line"
              />
              <:item
                id="preview-shell-frame"
                label="Shell frame"
                value="Route context"
                hint="Identity and controls stay pinned"
                href="#navigation"
                shortcut="GT"
                tone="neutral"
                icon="hero-shield-check"
              />
            </.dashboard_utility_strip>

            <.dashboard_quick_actions
              title="Quick actions"
              description="Mnemonic route cues keep the next jump obvious while the dashboard stays visually calm."
            >
              <:action
                id="preview-open-launch-surface"
                label="Open launch surface"
                description="Return to the primary operator lane and route-owned workspace context."
                href="#shells"
                shortcut="GL"
                badge="Primary"
                tone="primary"
                icon="hero-bolt"
              />
              <:action
                id="preview-inspect-panel-rhythm"
                label="Inspect panel rhythm"
                description="Review grouped panels and supporting rail composition."
                href="#navigation"
                shortcut="GR"
                badge="Review"
                tone="neutral"
                icon="hero-rectangle-stack"
              />
              <:action
                id="preview-audit-fallback-states"
                label="Audit fallback states"
                description="Keep recovery and loading review inside the same dashboard language."
                href="#dashboard-states"
                shortcut="GS"
                badge="States"
                tone="warning"
                icon="hero-exclamation-triangle"
              />
            </.dashboard_quick_actions>
          </div>
        </section>

        <section id="dashboard-states" class="ui-dev-preview__section">
          <.section_heading
            eyebrow="Dashboard states"
            title="Empty, loading, and error states keep the same operator-grade frame."
            subtitle="Review sparse and dense dashboard fallbacks without depending on real route data or auth setup."
            title_size="sm"
          />

          <div class="ui-split-grid">
            <.dashboard_empty_state
              density="sparse"
              title="Nothing is queued for this workspace yet."
              description="The dashboard keeps the same shell hierarchy and action rhythm even when the primary lane has no live work."
            >
              <:actions>
                <.button size="sm" href="#shells">Review shell</.button>
                <.button variant="outline" tone="neutral" size="sm" href="#forms">
                  Compare controls
                </.button>
              </:actions>
            </.dashboard_empty_state>

            <div class="grid gap-4">
              <.dashboard_loading_state
                density="dense"
                title="Workspace signals are syncing."
                description="Loading panels preserve the compact rail footprint so the shell never collapses into a spinner-only placeholder."
              />

              <.dashboard_error_state
                density="dense"
                title="The latest sync did not complete."
                description="Recovery guidance stays grouped with dashboard actions and context instead of falling back to a generic framework alert."
              >
                <:actions>
                  <.button size="sm" href="#feedback">Inspect feedback</.button>
                  <.button variant="outline" tone="neutral" size="sm" href="#navigation">
                    Check nav rhythm
                  </.button>
                </:actions>
              </.dashboard_error_state>
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
                  <.auth_shell current_path="/sign-in">
                    <.auth_page
                      title="Sign in"
                      subtitle="Review the compact auth shell, card treatment, and form controls without leaving the preview route."
                    >
                      <.auth_nav current_path="/sign-in" />

                      <.auth_form
                        for={to_form(%{}, as: :forms_shell_preview)}
                        id="auth-shell-form-preview"
                      >
                        <.input
                          name="auth_email_form_preview"
                          type="email"
                          label="Email"
                          autocomplete="email"
                          value="operator@example.com"
                        />
                        <.input
                          name="auth_password_form_preview"
                          type="password"
                          label="Password"
                          autocomplete="current-password"
                          value="supersecret123"
                        />

                        <:actions :let={_form}>
                          <a href="#forgot-password" class="ui-text-link text-xs">
                            Forgot password?
                          </a>
                          <.auth_submit label="Sign in" busy_label="Signing in..." tone="success" />
                        </:actions>
                      </.auth_form>

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

  attr(:label, :string, required: true)
  attr(:theme, :string, values: ~w(light dark), required: true)
  attr(:density, :string, values: ~w(default compact), required: true)

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
      %{label: "Public patterns", to: "#public-patterns"},
      %{label: "Shells", to: "#shells"},
      %{label: "Dashboard commands", to: "#dashboard-commands"},
      %{label: "Dashboard states", to: "#dashboard-states"},
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

  defp runtime_preview_dashboard_path, do: "/shell-operator/personal-hq"

  defp runtime_preview_user do
    %{
      username: "operator",
      email: "operator@eboss.dev"
    }
  end

  defp runtime_preview_scope do
    %{
      empty: false,
      dashboardPath: runtime_preview_dashboard_path(),
      currentWorkspace: %{
        id: "preview-workspace",
        name: "Personal HQ",
        slug: "personal-hq",
        fullPath: "shell-operator/personal-hq",
        visibility: "private",
        ownerType: "user",
        ownerSlug: "shell-operator",
        ownerDisplayName: "Shell Operator",
        dashboardPath: runtime_preview_dashboard_path(),
        current: true
      },
      owner: %{
        type: "user",
        slug: "shell-operator",
        displayName: "Shell Operator"
      },
      capabilities: %{
        readWorkspace: true,
        manageWorkspace: true,
        readFolio: true,
        manageFolio: true
      },
      accessibleWorkspaces: [
        %{
          id: "preview-workspace",
          name: "Personal HQ",
          slug: "personal-hq",
          fullPath: "shell-operator/personal-hq",
          visibility: "private",
          ownerType: "user",
          ownerSlug: "shell-operator",
          ownerDisplayName: "Shell Operator",
          dashboardPath: runtime_preview_dashboard_path(),
          current: true
        },
        %{
          id: "preview-lab",
          name: "Lab",
          slug: "lab",
          fullPath: "shell-operator/lab",
          visibility: "private",
          ownerType: "user",
          ownerSlug: "shell-operator",
          ownerDisplayName: "Shell Operator",
          dashboardPath: "/shell-operator/lab",
          current: false
        }
      ]
    }
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

  defp public_pattern_badge_label(:anchor), do: "Anchor"
  defp public_pattern_badge_label(:repeatable), do: "Repeatable"

  defp public_pattern_badge_tone(:anchor), do: "primary"
  defp public_pattern_badge_tone(:repeatable), do: "neutral"

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

  defp public_section_patterns do
    apply(@public_section_patterns, :all, [])
  end

  defp public_home_page_sections do
    apply(@public_section_patterns, :home_page_sections, [])
  end

  defp public_section_pattern_label(id) do
    @public_section_patterns
    |> apply(:fetch!, [id])
    |> Map.fetch!(:label)
  end
end
