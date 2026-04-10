# Epic 01: Design Foundation

This epic establishes the shared visual language for EBoss before broader page rewrites or browser automation coverage.

The aesthetic direction should take the strongest parts of `jido_hub`'s dashboard UI:

- operator-grade clarity
- restrained typography
- cool, controlled surfaces
- strong shell identity
- utility over ornament

and adapt that language for EBoss across HEEx, Vue, and development previews.

### ST-DSN-001 Codify EBoss visual DNA
#### Goal
Turn the current visual direction into an explicit design-system position that future stories can build from.

#### Scope
- Update `DESIGN.md` with a concise visual thesis derived from the `jido_hub` dashboard reference.
- Define how that DNA should express differently across dashboard, auth, and public surfaces.
- Make the direction legible in the design-system preview surfaces, not only in prose.

#### Acceptance Criteria
- `DESIGN.md` explains the visual character of EBoss in concrete design terms.
- The document distinguishes shared design DNA from surface-specific expression.
- The guidance is specific enough to reject obviously off-brand UI choices.

#### Verification
- Review `DESIGN.md` and confirm it provides actionable rules rather than vague taste statements.
- Review `/dev/design-system` and Histoire notes to ensure the language is consistent with the written direction.

#### Dependencies
- None

### ST-DSN-002 Normalize semantic typography roles
#### Goal
Make typography a consistent system rather than a page-by-page collection of text sizes.

#### Scope
- Tighten semantic text roles across the CSS system.
- Align shared HEEx and Vue primitives to those roles.
- Reduce ad hoc heading, body, and metadata usage in shared surfaces.

#### Acceptance Criteria
- Shared typography roles are clearly represented in the CSS foundation.
- HEEx and Vue primitives use the same semantic text hierarchy.
- Shared shells and primitives avoid arbitrary one-off text treatments.

#### Verification
- Review typography in `app.css` imports and `assets/css/system/*`.
- Review shared HEEx and Vue primitives for typography consistency.

#### Dependencies
- `ST-DSN-001`

### ST-DSN-003 Normalize semantic tone and color usage
#### Goal
Ensure color meaning is stable across the product.

#### Scope
- Tighten the meaning of semantic tones such as primary, neutral, success, warning, and danger.
- Align CSS tokens, HEEx primitives, and Vue primitives to the same tone model.
- Remove tone usage that is decorative but not semantic.

#### Acceptance Criteria
- The same tone names mean the same thing across HEEx and Vue.
- Shared primitives no longer drift between different color interpretations of the same state.
- Public, auth, and dashboard surfaces all read as part of one palette family.

#### Verification
- Review shared CSS tokens and primitive styles.
- Review Histoire stories and `/dev/design-system` for tone consistency.

#### Dependencies
- `ST-DSN-001`

### ST-DSN-004 Normalize surfaces, elevation, radius, and shadow rules
#### Goal
Make shared surfaces feel like they belong to one product shell.

#### Scope
- Tighten panel, card, shell, border, radius, and shadow rules in the shared CSS layer.
- Align the meaning of floating, solid, and default surfaces.
- Remove visual drift between HEEx and Vue implementations of the same surface concepts.

#### Acceptance Criteria
- Shared surfaces have a consistent elevation and border language.
- Radius and shadow decisions feel systematic rather than page-specific.
- Dashboard, auth, and public surfaces can all compose from the same surface vocabulary.

#### Verification
- Review `tokens.css`, `themes.css`, `primitives.css`, and `patterns.css`.
- Compare equivalent HEEx and Vue surface components side by side.

#### Dependencies
- `ST-DSN-001`
- `ST-DSN-003`

### ST-DSN-005 Add accessibility and interaction rules to the shared design system
#### Goal
Make accessibility and interaction quality explicit design-system work instead of an assumed side effect.

#### Scope
- Tighten shared rules around focus visibility, keyboard interaction, feedback semantics, contrast, and reduced-motion behavior.
- Review shared HEEx and Vue primitives for accessibility contract gaps.
- Update design documentation and shared patterns to reflect those expectations.

#### Acceptance Criteria
- Shared primitives have explicit accessibility and interaction expectations.
- Focus and keyboard behavior are treated as first-class design concerns.
- Motion and feedback rules account for reduced-motion and clarity needs.

#### Verification
- Review `DESIGN.md` and the shared primitive layer for explicit accessibility rules.
- Keyboard and focus review of representative shared surfaces.

#### Dependencies
- `ST-DSN-002`
- `ST-DSN-003`
- `ST-DSN-004`

### ST-DSN-006 Add theme and density parity review to the shared design system
#### Goal
Ensure the system holds together across themes and density settings, not only in one default state.

#### Scope
- Review shared primitives and shell patterns in available theme and density combinations.
- Tighten any inconsistent theme or density behavior in the shared design layer.
- Make parity expectations explicit in the design-system guidance.

#### Acceptance Criteria
- Shared primitives remain coherent across supported themes and density states.
- Shells do not rely on a single theme or density assumption to look correct.
- Theme and density expectations are explicit in the system guidance.

#### Verification
- Review shared surfaces in theme and density variants.
- Confirm the results are reflected in docs and preview surfaces where appropriate.

#### Dependencies
- `ST-DSN-002`
- `ST-DSN-003`
- `ST-DSN-004`

### ST-DSN-007 Expand HEEx design preview coverage
#### Goal
Use `/dev/design-system` as the in-app reference for shared HEEx primitives and patterns.

#### Scope
- Extend `EBossWeb.Dev.DesignSystemLive` to cover the important shared HEEx components and states.
- Add missing pattern examples for shells, panels, forms, feedback, and navigation.
- Make the preview useful for design review, not just a demo page.

#### Acceptance Criteria
- `/dev/design-system` demonstrates the main HEEx primitives and common states.
- Shared HEEx patterns can be reviewed without navigating the full product.
- The preview reflects the current design language instead of lagging behind it.

#### Verification
- Manual review of `/dev/design-system`.
- LiveView coverage where appropriate for preview route rendering.

#### Dependencies
- `ST-DSN-002`
- `ST-DSN-003`
- `ST-DSN-004`
- `ST-DSN-005`
- `ST-DSN-006`

### ST-DSN-008 Expand Histoire coverage for Vue primitives
#### Goal
Make Histoire the reliable workbench for Vue-side design review.

#### Scope
- Add or tighten stories for shared Vue primitives.
- Ensure each important primitive shows meaningful variant and state coverage.
- Use story helpers consistently for review surfaces and controls.
- Keep state names and scenario coverage aligned with the component-test cases that will later be written in Vitest.

#### Acceptance Criteria
- Each shared Vue primitive has at least one useful story.
- Stories show more than the happy path where state matters.
- Histoire can be used to review visual parity with HEEx primitives.
- Stable states are clear enough to serve as inputs for later component-test coverage.

#### Verification
- Run `npm run histoire:build` from `apps/eboss_web/assets`.
- Run `npm run vue:check` from `apps/eboss_web/assets`.

#### Dependencies
- `ST-DSN-002`
- `ST-DSN-003`
- `ST-DSN-004`
- `ST-DSN-005`
- `ST-DSN-006`

### ST-DSN-009 Align HEEx and Vue primitive contracts
#### Goal
Ensure the design system behaves like one system even though it spans two rendering layers.

#### Scope
- Align naming, variants, and state contracts between HEEx and Vue primitives.
- Tighten gaps where one layer supports states or variants the other does not.
- Reduce duplicated concepts that differ only because of implementation history.

#### Acceptance Criteria
- HEEx and Vue primitives use the same conceptual vocabulary where they overlap.
- Shared variants and tones behave consistently across both layers.
- The system no longer presents obvious parity mismatches in common controls.

#### Verification
- Compare HEEx preview states and Histoire states for equivalent primitives.
- Review the shared primitive APIs in code.

#### Dependencies
- `ST-DSN-002`
- `ST-DSN-003`
- `ST-DSN-004`
- `ST-DSN-005`
- `ST-DSN-006`
