defmodule EBossWeb.HomeLive do
  use EBossWeb, :live_view

  @public_section_patterns EBossWeb.PublicPagePatterns

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
      <div class="ui-home-page">
        <section
          class="ui-home-hero"
          data-home-hero
          data-public-section-pattern={public_section_pattern_slug(:hero)}
        >
          <div class="ui-home-hero__copy">
            <div class="space-y-6">
              <.section_heading
                eyebrow="Dashboard-derived public surface"
                title="A calmer launch page for teams that need the shell to stay precise."
                subtitle="EBoss opens with more narrative room, but it keeps the same operator-grade borders, typography, and route logic that shape the authenticated product."
                title_size="hero"
                title_class="max-w-4xl"
              />

              <div class="ui-home-hero__narrative">
                <p class="ui-text-body" data-size="lg" data-tone="soft">
                  The landing surface borrows its discipline from the dashboard: calm chrome,
                  controlled emphasis, and proof that reads like product infrastructure instead of
                  agency-style filler.
                </p>
                <p class="ui-text-body" data-size="lg" data-tone="muted">
                  Route continuity, workspace guardrails, and session handoff do the explanatory
                  work so the page stays open without losing the product’s center of gravity.
                </p>
              </div>
            </div>

            <div class="ui-home-hero__actions">
              <.button navigate={~p"/register"} size="lg">
                Create your account
              </.button>
              <.button navigate={~p"/sign-in"} variant="outline" tone="neutral" size="lg">
                Sign in
              </.button>
            </div>

            <div class="ui-home-hero__signals">
              <.badge :for={signal <- hero_signals()} tone="neutral">
                {signal}
              </.badge>
            </div>
          </div>

          <.panel surface="floating" class="ui-home-hero__frame">
            <div class="ui-home-hero__frame-stack">
              <div class="space-y-4">
                <div class="flex flex-wrap items-center justify-between gap-3">
                  <.badge tone="neutral">Launch rhythm</.badge>
                  <p class="ui-text-meta" data-tone="soft">Public -> auth -> dashboard</p>
                </div>

                <div class="space-y-3">
                  <h2 class="ui-text-display" data-size="lg">
                    Public, auth, and dashboard move like one route family.
                  </h2>
                  <p class="ui-text-body" data-tone="soft">
                    The public page gets more openness and longer beats, but the material stack and
                    handoff cues still feel like the working shell.
                  </p>
                </div>
              </div>

              <div class="ui-home-route-sequence">
                <.panel
                  :for={step <- route_sequence()}
                  as="div"
                  surface="solid"
                  padding="sm"
                  class="ui-home-route-sequence__step"
                  data-home-route-step={step.id}
                >
                  <div class="ui-home-route-sequence__step-inner">
                    <div class="space-y-2">
                      <p class="ui-text-meta" data-tone="primary">{step.label}</p>
                      <p class="ui-text-title" data-size="sm">{step.title}</p>
                      <p class="ui-text-body" data-size="sm" data-tone="muted">{step.copy}</p>
                    </div>
                    <span class="ui-home-step-index">{step.index}</span>
                  </div>
                </.panel>
              </div>

              <.panel as="div" surface="solid" padding="sm" class="ui-home-hero__note">
                <p class="ui-text-meta" data-tone="soft">Why this stays on-brand</p>
                <p class="ui-text-body" data-size="sm" data-tone="muted">
                  Narrative space comes from copy rhythm, asymmetry, and panel pacing, not from
                  soft illustration or detached marketing fragments.
                </p>
              </.panel>
            </div>
          </.panel>
        </section>

        <section
          class="ui-home-proof-strip"
          data-home-proof-strip
          data-public-section-pattern={public_section_pattern_slug(:proof_band)}
        >
          <div class="space-y-3 max-w-3xl">
            <p class="ui-kicker" data-tone="primary">Narrative proof</p>
            <h2 class="ui-text-display" data-size="xl">
              The landing page leads with product posture, then proves it.
            </h2>
            <p class="ui-text-body" data-size="lg" data-tone="soft">
              Each supporting beat exists to confirm continuity with the dashboard instead of
              filling space with generic marketing gestures.
            </p>
          </div>

          <div class="ui-home-proof-grid">
            <.panel
              :for={card <- proof_cards()}
              as="article"
              surface="floating"
              class="ui-home-proof-card"
              data-home-proof-card={card.id}
            >
              <p class="ui-text-meta" data-tone="soft">{card.label}</p>
              <h3 class="ui-text-title" data-size="md">{card.title}</h3>
              <p class="ui-text-body" data-tone="muted">{card.copy}</p>
            </.panel>
          </div>
        </section>

        <section
          class="ui-home-story"
          data-home-story="continuity"
          data-public-section-pattern={public_section_pattern_slug(:feature_row)}
        >
          <div class="ui-home-story__copy">
            <p class="ui-kicker" data-tone="primary">Route continuity</p>
            <h2 class="ui-text-display" data-size="xl">
              The first click already feels inside the product.
            </h2>
            <p class="ui-text-body" data-size="lg" data-tone="soft">
              Visitors should not cross a stylistic border when they move from home into sign-in,
              recovery, or the dashboard. The route family stays visibly intact.
            </p>
            <p class="ui-text-body" data-tone="muted">
              That continuity carries trust better than decorative polish. It lets the public page
              stay open without pretending the underlying product is a lifestyle brand.
            </p>

            <div class="flex flex-wrap gap-2">
              <.badge :for={signal <- continuity_signals()} tone="neutral">
                {signal}
              </.badge>
            </div>
          </div>

          <.panel surface="floating" class="ui-home-story__frame">
            <div class="ui-home-story__frame-stack">
              <div class="space-y-3">
                <p class="ui-text-meta" data-tone="soft">Shared route family</p>
                <h3 class="ui-text-title" data-size="md">
                  Home, sign-in, recovery, and dashboard handoff stay in one visual conversation.
                </h3>
              </div>

              <div class="ui-home-story__grid">
                <.panel
                  :for={item <- continuity_cards()}
                  as="div"
                  surface="solid"
                  padding="sm"
                  class="ui-home-story__card"
                >
                  <p class="ui-text-meta" data-tone="primary">{item.label}</p>
                  <p class="ui-text-body" data-size="sm" data-tone="muted">{item.copy}</p>
                </.panel>
              </div>
            </div>
          </.panel>
        </section>

        <section
          class="ui-home-story ui-home-story--reverse"
          data-home-story="tempo"
          data-public-section-pattern={public_section_pattern_slug(:feature_row)}
        >
          <div class="ui-home-story__copy">
            <p class="ui-kicker" data-tone="primary">Narrative rhythm</p>
            <h2 class="ui-text-display" data-size="xl">
              The page now moves in deliberate beats instead of repeating generic sections.
            </h2>
            <p class="ui-text-body" data-size="lg" data-tone="soft">
              The hero opens with space, the proof strip grounds the story, and the closing CTA
              resolves into a clear next step.
            </p>
            <p class="ui-text-body" data-tone="muted">
              That pacing makes the product feel sharper and more confident without pushing it
              toward pitch-deck theatrics or a console screenshot wall.
            </p>
          </div>

          <.panel surface="floating" class="ui-home-story__frame">
            <div class="ui-home-story__frame-stack">
              <div class="space-y-3">
                <p class="ui-text-meta" data-tone="soft">Page cadence</p>
                <h3 class="ui-text-title" data-size="md">
                  Lead, ground, and move the visitor forward without noise.
                </h3>
              </div>

              <div class="ui-home-story__grid">
                <.panel
                  :for={beat <- pace_cards()}
                  as="div"
                  surface="solid"
                  padding="sm"
                  class="ui-home-story__card"
                >
                  <p class="ui-text-meta" data-tone="primary">{beat.label}</p>
                  <p class="ui-text-title" data-size="sm">{beat.title}</p>
                  <p class="ui-text-body" data-size="sm" data-tone="muted">{beat.copy}</p>
                </.panel>
              </div>
            </div>
          </.panel>
        </section>
      </div>

      <:shell_footer>
        <section
          data-home-closing
          data-public-section-pattern={public_section_pattern_slug(:closing_section)}
        >
          <Layouts.public_cta_frame
            eyebrow="Working-shell handoff"
            title="Enter the product from a page that already speaks the same language."
            subtitle="Registration, sign-in, recovery, and dashboard entry stay inside one route family, one material system, and one operator-grade posture."
            primary_label="Create your account"
            primary_to={~p"/register"}
            secondary_label="Sign in"
            secondary_to={~p"/sign-in"}
            section_pattern={public_section_pattern_slug(:cta_band)}
          >
            <:details :for={detail <- cta_details()}>
              <.panel as="div" surface="solid" padding="sm" class="space-y-2">
                <p class="ui-text-meta" data-tone="soft">{detail.label}</p>
                <p class="ui-text-body" data-size="sm" data-tone="muted">{detail.copy}</p>
              </.panel>
            </:details>
          </Layouts.public_cta_frame>
        </section>
      </:shell_footer>
    </Layouts.app>
    """
  end

  defp hero_signals do
    ["Shared shell", "Restrained type", "Direct dashboard handoff"]
  end

  defp route_sequence do
    [
      %{
        id: "open",
        index: "01",
        label: "Open",
        title: "Home keeps the shell visible",
        copy:
          "The landing page loosens the pace without dropping borders, route cues, or product tone."
      },
      %{
        id: "enter",
        index: "02",
        label: "Enter",
        title: "Auth stays in the same family",
        copy:
          "Sign-in, register, confirm, and recovery live inside the same public frame and token system."
      },
      %{
        id: "work",
        index: "03",
        label: "Work",
        title: "Dashboard handoff is immediate",
        copy:
          "The first authenticated destination is the working shell instead of a disconnected marketing step."
      }
    ]
  end

  defp proof_cards do
    [
      %{
        id: "dna",
        label: "Dashboard DNA",
        title: "The landing page still reads like product infrastructure.",
        copy:
          "Panel hierarchy, route chrome, and restrained type do most of the work before accent or motion."
      },
      %{
        id: "pacing",
        label: "Open pacing",
        title: "The story opens up without losing visual discipline.",
        copy:
          "Longer lines of copy, asymmetry, and staged sections create momentum instead of repeating a generic marketing-card grid."
      },
      %{
        id: "handoff",
        label: "Operator handoff",
        title: "Every action points cleanly into the authenticated shell.",
        copy:
          "Registration, sign-in, recovery, and dashboard entry keep one material system and one route family."
      }
    ]
  end

  defp continuity_signals do
    ["Shared navigation", "Theme parity", "Session continuity"]
  end

  defp continuity_cards do
    [
      %{
        label: "Public shell",
        copy:
          "Visitors see the same borders, navigation logic, and theme controls before they ever authenticate."
      },
      %{
        label: "Auth entry",
        copy:
          "Sign-in, registration, confirmation, and recovery stay inside the same visual frame instead of branching into a separate flow."
      },
      %{
        label: "Workspace handoff",
        copy:
          "Once the account is ready, the route resolves directly into the dashboard shell that carries the real work."
      }
    ]
  end

  defp pace_cards do
    [
      %{
        label: "Lead",
        title: "Open with one product-defining idea",
        copy:
          "The hero uses restrained display type, supporting copy, and one framed proof surface instead of a pitch-deck collage."
      },
      %{
        label: "Ground",
        title: "Follow with concrete signals",
        copy:
          "Supporting sections turn continuity, trust, and shared shell behavior into readable evidence."
      },
      %{
        label: "Move",
        title: "Close with a clear next step",
        copy:
          "The CTA frame resolves the narrative into account creation or sign-in without changing products or posture."
      }
    ]
  end

  defp cta_details do
    [
      %{
        label: "Route continuity",
        copy:
          "Home, sign-in, registration, recovery, and token confirmation stay visually aligned inside the same family."
      },
      %{
        label: "System parity",
        copy:
          "Theme changes and compact density reuse the same tokens that already drive dashboard and auth surfaces."
      },
      %{
        label: "Working-shell entry",
        copy:
          "The final transition still resolves directly into the authenticated dashboard instead of detouring through another launch page."
      }
    ]
  end

  defp public_section_pattern_slug(id) do
    apply(@public_section_patterns, :slug, [id])
  end
end
