# DESIGN.md

This document is the design-system counterpart to `AGENTS.md`.

It defines how the EBoss design layer is organized, where design code lives, and how to extend it without turning the UI into a set of unrelated page-level decisions.

The goal is not to lock in a single visual treatment forever. The goal is to keep the system coherent while the product evolves.

## Canonical Source

The canonical visual source for EBoss is the Lovable shell-operator system:

- published reference: `https://shell-operator-system.lovable.app`
- local source clone: `/private/tmp/shell-operator-system`
- porting blueprint: `docs/porting/shell_operator_system_port.md`

This is the product design we are standardizing on.

The layered EBoss CSS architecture remains the implementation mechanism:

- `tokens.css` defines the shared semantic variables
- `themes.css` maps the supported light/dark modes
- `primitives.css` defines reusable control contracts
- `patterns.css` defines page and shell composition rules

Those layers should express the Lovable shell system. They should not compete with it or invent a parallel visual language.

## Intent

The EBoss UI should feel like one product, not a collection of screens.

Design work in this repository should:

- build from shared primitives before page-specific styling
- use semantic tokens instead of hardcoded visual values
- keep HEEx and Vue surfaces visually aligned
- separate visual structure from business logic
- prefer repeatable patterns over one-off hero implementations
- make component states visible in development tooling before they spread through the app
- keep the runtime product visually faithful to the Lovable shell reference while adapting it to Phoenix, HEEx, and Vue

## Visual Thesis

EBoss should feel like the shell-operator system across workspace, auth, and public surfaces:

- operator-grade clarity over decorative novelty
- restrained typography over loud marketing scale shifts
- cool, controlled surfaces over glossy color blocking
- strong shell identity over floating page fragments
- utility-led emphasis over ornament-first composition

We are not using the in-repo `ui-*` layer as an independent art direction. It exists to encode and share the shell-operator system cleanly across HEEx and Vue.

## Shared Visual DNA

These rules apply across dashboard, auth, and public surfaces.

- Shell-first clarity. Start with the frame, panel hierarchy, border rhythm, and reading order before adding decorative moments. If the shell disappears, the UI will drift off-brand.
- Restrained typography. Use display type for key product-defining moments, body type for working copy, and mono accents for operator labels, state cues, and metadata. Avoid stacking multiple expressive text treatments in one view.
- Cool surface discipline. Default to slate, stone, ink, and canvas relationships with subtle gradients and controlled contrast shifts. Accent color is a signal, not a wallpaper.
- Utility-led emphasis. Create priority through spacing, alignment, density, contrast, and component state before reaching for illustration, oversized icons, or saturated fills.
- Branded precision. Corners, shadows, and highlights should feel engineered and deliberate. Surfaces may glow softly, but they should never look inflated, gummy, or playful.

## Surface Expression

The shared DNA stays constant, but its expression changes by surface.

### Dashboard surfaces

Dashboard views are the purest expression of the system.

- Keep shell chrome strongest here: stable headers, clear section breaks, deliberate panel boundaries, and dense-but-readable information groupings.
- Let mono labels, badges, tabs, and status treatments carry more of the hierarchy.
- Reserve the strongest emphasis for action states, live status, and important panel transitions.
- Prefer compact confidence over theatrical reveal patterns.

### Auth surfaces

Auth views should feel like a trusted entry point into the same operator environment.

- Keep the same materials, border language, and color family as the dashboard, but loosen the rhythm and reduce simultaneous choices.
- Use more breathing room, simpler grouping, and one dominant action per step.
- Let reassurance come from clarity, not friendliness theater. The tone should be calm, direct, and high-trust.
- Avoid consumer-app tropes like oversized mascots, whimsical empty space, or candy-colored success states.

### Public surfaces

Public pages can be more narrative, but they still belong to the same product family.

- Use larger display moments and more asymmetry than dashboard or auth screens, while keeping the same typography, materials, and shell cues.
- Pair narrative copy with concrete panels, metrics, or framed content so the page still reads like product infrastructure, not lifestyle marketing.
- Use accent and warning tones sparingly to create momentum around actions and proof points.
- Keep the page composed and intentional. Public does not mean soft, generic, or illustration-heavy.

## Off-Brand Rejections

Reject UI directions that conflict with the system, even if they look polished in isolation.

- Neon gradients, candy palettes, or high-saturation fills used as the primary identity
- Hero sections that read like a startup pitch deck instead of an operator-grade product surface
- Soft, borderless cards floating without shell structure or panel hierarchy
- Playful typography mixes, oversized display copy blocks, or trendy editorial treatments in working UI
- Decorative icons, illustrations, or motion that compete with task flow or state clarity

## System Shape

The design layer currently has four main levels:

1. Foundations
   Typography, spacing, radii, shadows, color tokens, motion, density.
2. Primitives
   Inputs, buttons, panels, alerts, badges, tabs, dialogs, empty states, and related low-level controls.
3. Patterns
   Auth shells, form layouts, dashboard sections, split panes, empty states, feedback blocks, navigation shells.
4. Screens
   Product-specific pages built from the layers above.

Do not build screen-first and only later try to extract a system. Start from the lowest stable layer that fits the change.

## File Locations

The current design-system surface is split across CSS, HEEx, Vue, and development previews.

### CSS foundation

- `apps/eboss_web/assets/css/app.css`
  Entry point for the web styling stack.
- `apps/eboss_web/assets/css/system/tokens.css`
  Semantic tokens and theme-facing variable mapping.
- `apps/eboss_web/assets/css/system/themes.css`
  Theme definitions and theme-specific overrides.
- `apps/eboss_web/assets/css/system/primitives.css`
  Shared primitive styles such as buttons, fields, panels, alerts, and common interaction states.
- `apps/eboss_web/assets/css/system/patterns.css`
  Higher-level layout and page-pattern rules.

### HEEx components

- `apps/eboss_web/lib/eboss_web/components/core_components.ex`
  Core HEEx primitives used directly in LiveViews and templates.
- `apps/eboss_web/lib/eboss_web/components/ui_components.ex`
  Shared HEEx UI patterns and composition helpers.
- `apps/eboss_web/lib/eboss_web/components/layouts.ex`
  Global shell and layout frame.
- `apps/eboss_web/lib/eboss_web/components/auth_components.ex`
  Auth-specific shared patterns.

### Vue components

- `apps/eboss_web/assets/vue/components/ui/`
  Reusable Vue primitives and low-level building blocks.
- `apps/eboss_web/assets/vue/stories/`
  Histoire helpers used to present and inspect component states.
- `apps/eboss_web/assets/vue/auth/`
  Auth-focused Vue scenes and page-level composition.
- `apps/eboss_web/assets/vue/dashboard/`
  Dashboard-focused Vue scenes and composition.

### Development previews

- `apps/eboss_web/assets/histoire.config.ts`
  Histoire configuration.
- `apps/eboss_web/assets/histoire.setup.ts`
  Histoire setup and CSS loading.
- `apps/eboss_web/lib/eboss_web/live/dev/design_system_live.ex`
  HEEx-side design-system preview page.
- `/dev/design-system`
  In-app HEEx preview route for primitives and patterns.

## Typography

Typography is part of the system, not a per-page decision.

- Use the tokenized font roles:
  - display
  - body
  - mono
- Use display typography for headings and product-defining moments, not for all text.
- Use body typography for dense product UI, forms, tables, explanatory copy, and long-reading surfaces.
- Use mono typography sparingly for metadata, labels, operator context, short codes, and technical accents.
- Prefer semantic classes and tokens over direct font-family decisions at call sites.
- If a screen needs a new text treatment, first decide whether it is:
  - a missing token
  - a missing primitive style
  - a one-off that should not exist

Avoid introducing typography variants that are distinguishable only by tiny weight or spacing changes. If users cannot reliably feel the difference, it is noise.

## CSS Rules

The CSS layer should stay intentional and layered.

- Put shared variables in `tokens.css`.
- Put theme-specific mappings and overrides in `themes.css`.
- Put reusable control styling in `primitives.css`.
- Put layout and screen-pattern rules in `patterns.css`.
- Keep `app.css` as the composition entrypoint, not a dumping ground.

### Preferred CSS approach

- Prefer semantic custom properties over hardcoded raw values.
- Prefer shared `ui-*` class contracts for reusable pieces when they faithfully encode the shell-operator design.
- Prefer Tailwind utilities for local layout composition when they do not create repeated visual contracts.
- Promote repeated visual structures into shared CSS and components.
- Keep shell-operator-derived classes and tokens as temporary adapters only when a shared `ui-*` contract is not ready yet.

### Avoid

- page-specific color literals when a semantic token should exist
- component-local design systems that bypass the canonical shell-operator vocabulary
- one-off spacing scales
- arbitrary visual fixes duplicated across pages
- mixing structural and stateful styles in a way that makes states hard to reason about

## HEEx and Vue Parity

This project has both HEEx components and Vue components. They must behave like one design system.

- If a primitive exists in HEEx and Vue, it should share the same visual vocabulary and state model.
- Naming should stay aligned across both layers.
- Variants should mean the same thing in both layers.
- Tone names should mean the same thing in both layers.
- Focus, hover, loading, disabled, empty, error, and success states should feel equivalent.

Do not let HEEx become the “server look” and Vue become the “modern look.” They are both part of the same product.

## Theme and Density Parity

Shared design review must cover the supported system modes, not only the default screenshot state.

Supported review modes:

- Themes: `light` and `dark`
- Densities: `default` and `compact`
- Review matrix: `dark/default`, `dark/compact`, `light/default`, and `light/compact`

Parity expectations:

- Shared primitives must keep contrast, padding rhythm, focus visibility, and state clarity in every supported theme and density combination.
- Shell patterns must tighten together when density changes. Do not leave compact controls floating inside roomy headers, panels, or form shells.
- `system` theme is a runtime selector, not a separate visual contract. It must resolve cleanly to the `light` or `dark` review states above.
- Shared review surfaces should expose the supported matrix where practical: use Histoire for Vue primitives and `/dev/design-system` for HEEx primitives and shell patterns.

## Vue Component Logic

Vue components in the design layer should be primarily presentational and compositional.

- Keep reusable UI primitives in `assets/vue/components/ui/`.
- Keep product scenes and page compositions outside the primitive directory.
- Prefer props, slots, and emitted events over internal business rules.
- Keep domain logic, auth decisions, persistence, and server state in LiveView or the application layer unless there is a clear client-only need.
- When a component needs state, keep that state local and interface-driven.
- Avoid coupling primitives to specific routes, API payloads, or Ash resource details.

A good primitive answers: “How should this look and interact?”

It should not answer: “What business process owns this?”

## LiveView and LiveVue Guidance

LiveView owns server state and application flow.
Vue should enhance presentation, composition, and controlled client interactions.

- Treat `/dev/design-system` as the canonical in-app patterns page for shared HEEx, shell, and LiveVue runtime review.
- Prefer HEEx for server-driven forms, auth flows, and content that closely tracks assigns.
- Prefer Vue where richer interaction, structured client composition, or component-driven presentation adds value.
- Keep the contract between LiveView and Vue explicit through props and events.
- Do not bury application-critical behavior inside opaque client-side component state.
- Route state, persisted state, authorization-sensitive actions, validation, and real-time updates belong to LiveView.
- Presentation, local-only UI state, panel open/closed state, draft text, popovers, small transitions, and connection affordances may live in Vue.

When in doubt, put truth on the server and presentation in the component layer.

### LiveVue Runtime Patterns

Signed-in browser UI should use LiveVue as a LiveView presentation layer, not as a standalone SPA.

- Navigation: use `Link` and `useLiveNavigation()` instead of manual `window.history` edits so `handle_params/3` remains the route source of truth.
- Mutations: use `$live.pushEvent()`, `useEventReply()`, or `phx-*` bindings for browser UI writes such as create, update, transition, archive, mark-read, and preference actions.
- Live updates: use `push_event/3`, `useLiveEvent()`, LiveView assigns, and Phoenix streams for changing rows, notifications, activity, and chat deltas.
- Forms: use `useLiveForm()` for repeated Vue forms that need server validation or Ash/Phoenix form semantics.
- Connection state: use `useLiveConnection()` for subtle reconnecting/offline affordances and to disable sensitive actions when appropriate.
- Uploads: use `useLiveUpload()` for future attachment flows instead of separate browser upload clients.
- SSR: keep global SSR disabled for now; revisit SSR in a focused public/auth-page pass after hydration behavior is verified.
- External API: keep REST and SSE endpoints available for API clients, automation, external integrations, and focused controller tests. Same-origin signed-in UI should not default to `fetch()` unless the interaction is intentionally outside LiveView.
- Module boundaries: default Vue barrels such as `./chat` and `./folio` should expose LiveVue-safe types/path helpers only. REST/SSE clients belong in explicit `http.ts` or `queries.ts` imports and must be labeled as external-contract helpers.

## Component Contracts

Every shared primitive should have a small, explicit contract.

That contract should answer:

- what problem the component solves
- what variants it supports
- what states it supports
- what inputs it accepts
- what slots it exposes
- what accessibility guarantees it provides
- whether it is intended for primitive use or screen composition

If a new component cannot explain its contract simply, it is probably a pattern or screen, not a primitive.

## Accessibility

Accessibility is part of design quality, not a later pass.

### Focus and keyboard access

- Never remove a visible focus indicator without replacing it with the shared focus treatment or a stronger, clearer equivalent.
- Interactive primitives must use native controls or preserve equivalent keyboard semantics. Do not fake buttons, links, tabs, or dialogs with click-only containers.
- Disabled links must stop behaving like links. Do not leave keyboard-activatable anchors styled as disabled buttons.
- Icon-only controls must expose an accessible name.
- Keyboard order should follow the reading order of the layout, not visual decoration.

### Feedback semantics

- Inputs must have clear labels, and validation feedback must stay connected to the control with `aria-describedby` and `aria-invalid`.
- Informational or success feedback should use polite live-region semantics. Destructive or blocking feedback should use alert semantics.
- Dialogs, tabs, alerts, and form feedback must keep their expected semantics instead of relying on visual treatment alone.
- Color must not be the only signal for validation, warning, success, active, or selected states.

### Contrast and clarity

- Text, icons, borders, and focus indicators must remain legible across supported themes and density modes.
- Disabled, loading, empty, and error states must stay understandable without animation or decorative illustration.
- If a state disappears when color is removed, the design is underspecified.

## Motion and Feedback

Motion should clarify, not decorate.

- Use motion to reinforce hierarchy, entry, feedback, and state change.
- Keep transitions restrained and consistent.
- Prefer a small motion vocabulary reused throughout the app.
- Loading states should preserve layout stability whenever possible.
- Shared motion must degrade cleanly under `prefers-reduced-motion`.
- Reduced-motion behavior should remove non-essential transforms and animation while preserving the clarity of feedback.

Avoid layered animations that compete with content or make operator workflows feel soft or slow.

## Histoire Usage

Histoire is the primary workbench for Vue-side primitive and pattern development.

Use it to:

- inspect component states in isolation
- compare variants and tones
- validate responsive behavior
- exercise empty, loading, error, and dense-content cases
- document intended usage through stories

Do not use Histoire as a replacement for:

- LiveView integration testing
- browser auth-flow testing
- end-to-end workflow validation

### Histoire expectations

- Every reusable Vue primitive should have a story.
- Stories should show meaningful states, not only the happy path.
- Stories should include boundary examples such as long labels, missing content, dense content, and disabled/loading states where relevant.
- Stories for shared primitives should remain reviewable in the supported theme and density matrix.
- Stories should use the shared story helpers in `assets/vue/stories/` when useful.
- Histoire should load the same CSS entrypoint as the app so components are reviewed in the real design language.

Useful scripts:

- `npm run histoire`
- `npm run histoire:build`
- `npm run vue:check`

Run them from `apps/eboss_web/assets`.

## In-App Design Preview

The HEEx design layer should also stay inspectable outside Vue stories.

Use `/dev/design-system` to:

- preview shared HEEx primitives
- compare shell and layout patterns
- review supported theme and density combinations for shared shell and primitive patterns
- validate form and panel composition in the app shell
- make sure HEEx patterns stay aligned with Vue patterns

If a shared HEEx pattern matters, it should be visible there.

## Design Review Heuristics

When changing UI, ask:

- Is this using the existing system or bypassing it?
- Is this a primitive, a pattern, or a screen concern?
- Should this visual decision become reusable?
- Does this create parity problems between HEEx and Vue?
- Does this improve operator clarity, or only add novelty?
- Are all major states represented?
- Would this still feel coherent if repeated across five more screens?

## What Not To Do

- Do not reintroduce ad hoc visual frameworks or component libraries as the primary design language.
- Do not define page-level styling as the default way of building the UI.
- Do not hide important interaction rules inside visual components.
- Do not add new variants unless they carry clear product meaning.
- Do not let stories drift away from real production component usage.

## Practical Default

When adding or changing UI:

1. Start with the existing token and primitive vocabulary.
2. Decide whether the work belongs in CSS foundations, a primitive, a pattern, or a screen.
3. Update or add Histoire stories for shared Vue components.
4. Update `/dev/design-system` when HEEx primitives or shared patterns change.
5. Keep HEEx and Vue parity in mind before merging new component contracts.

This file should evolve as the design system gets stricter and the product surface gets broader.
