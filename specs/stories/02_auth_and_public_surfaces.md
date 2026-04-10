# Epic 02: Auth and Public Surfaces

This epic applies the design foundation to the first surfaces users see:

- auth
- landing
- public shell

These surfaces should share the same design system as the dashboard, but with a different tempo:

- more open than the dashboard
- clearer narrative hierarchy
- fewer simultaneous controls
- the same product DNA

### ST-AUTH-001 Unify auth shell layout and hierarchy
#### Goal
Make all auth pages feel like one coherent flow instead of separate screens sharing only mechanics.

#### Scope
- Align shell structure, spacing, headings, and narrative hierarchy across auth pages.
- Make sign-in, register, forgot-password, reset, confirm, and magic-link surfaces read as one family.
- Reuse shared layout and pattern components where possible.

#### Acceptance Criteria
- Auth pages share a clear and consistent shell structure.
- Visual hierarchy across auth pages is consistent and easy to scan.
- Shared auth patterns live in reusable components instead of duplicated page markup.
- The auth shell holds together on desktop and mobile.
- The auth shell remains coherent across supported theme and density states.

#### Verification
- Review all auth routes visually.
- Run existing auth LiveView tests and update them where markup contracts legitimately change.

#### Dependencies
- `ST-DSN-002`
- `ST-DSN-003`
- `ST-DSN-004`
- `ST-DSN-005`
- `ST-DSN-006`
- `ST-DSN-009`

### ST-AUTH-002 Unify auth fields, validation, and feedback states
#### Goal
Make the auth experience feel trustworthy and consistent under real form interaction.

#### Scope
- Standardize field treatment, validation tone, error messaging presentation, and inline feedback across auth forms.
- Reduce surface-specific differences in loading and disabled states.
- Ensure auth feedback aligns with shared primitive rules.

#### Acceptance Criteria
- Auth forms present validation and feedback consistently.
- Error and success messaging uses a shared visual contract.
- Focus, invalid, loading, and disabled states feel intentional and stable.

#### Verification
- Review auth forms in the browser.
- Run auth LiveView tests and update them where behavior or copy changes intentionally.

#### Dependencies
- `ST-AUTH-001`

### ST-AUTH-003 Fix sign-in field retention regressions in real browser interaction
#### Goal
Resolve the browser-visible sign-in UX issue that currently blocks confidence in frontend behavior.

#### Scope
- Fix the sign-in form behavior where typed values are lost during real browser interaction.
- Verify the fix in an actual browser flow, not only server-side tests.
- Leave a regression test behind once the behavior is stable.

#### Acceptance Criteria
- Typing into the sign-in form no longer clears unrelated fields unexpectedly.
- The fix holds under real browser interaction.
- The implementation does not introduce regressions across password and magic-link flows.

#### Verification
- Browser-driven verification of `/sign-in`.
- Add or update automated coverage when the behavior is stable.

#### Dependencies
- `ST-AUTH-001`
- `ST-AUTH-002`

### ST-PUB-001 Unify public navigation, footer, and CTA frame
#### Goal
Make the public shell feel like the same product as the dashboard and auth surfaces.

#### Scope
- Rework public navigation, footer, and shared CTA framing around the EBoss design system.
- Reduce leftover generic marketing-shell patterns.
- Align shell-level interactions with the product tone.

#### Acceptance Criteria
- Public shell chrome matches the design-system vocabulary.
- Navigation and CTA framing feel product-native rather than generic.
- Footer and global shell elements no longer feel disconnected from the dashboard and auth surfaces.
- The public shell holds together on desktop and mobile.
- The public shell remains coherent across supported theme and density states.

#### Verification
- Visual review of the public shell on desktop and mobile.
- Route smoke checks for public pages.

#### Dependencies
- `ST-DSN-002`
- `ST-DSN-003`
- `ST-DSN-004`
- `ST-DSN-005`
- `ST-DSN-006`
- `ST-DSN-009`

### ST-PUB-002 Reframe landing-page hero and narrative rhythm
#### Goal
Use the dashboard-derived EBoss design DNA to sharpen the landing experience without making it feel like a tool console.

#### Scope
- Rework hero, headline hierarchy, supporting copy rhythm, and section pacing on the landing page.
- Preserve the shared visual system while giving the public page more openness and narrative control.
- Remove public-page patterns that feel too generic, noisy, or agency-like.

#### Acceptance Criteria
- The landing page feels clearly related to the product UI.
- The page has stronger narrative pacing and clearer visual priorities.
- The hero and supporting sections use the design system intentionally rather than as decoration.

#### Verification
- Visual review on desktop and mobile.
- Manual review against the design principles documented in `DESIGN.md`.

#### Dependencies
- `ST-DSN-001`
- `ST-PUB-001`

### ST-PUB-003 Define reusable public section patterns
#### Goal
Define a stable pattern vocabulary for public-page composition before migrating the page to it.

#### Scope
- Identify recurring public-page section types such as hero, proof, feature rows, CTA bands, and closing sections.
- Define which section types should become repeatable patterns.
- Clarify the intended structure and usage of those patterns without requiring the whole page to migrate in the same story.

#### Acceptance Criteria
- The recurring public section types are explicitly defined.
- The pattern vocabulary is clear enough to guide later migration work.
- Public-page composition rules are easier to discuss and review.

#### Verification
- Review the public page structure in code and in the browser.
- Confirm repeated section patterns are clearly identifiable and named.

#### Dependencies
- `ST-PUB-001`
- `ST-PUB-002`

### ST-PUB-004 Migrate the public page to standardized section patterns
#### Goal
Move the actual public page onto the reusable section vocabulary defined earlier.

#### Scope
- Rework the public page to use the standardized section patterns.
- Reduce leftover one-off section construction in the home surface.
- Keep the result aligned with the shared EBoss design system.

#### Acceptance Criteria
- The public page uses the standardized section patterns in practice.
- One-off layout improvisation is reduced materially.
- The public page remains visually coherent across desktop and mobile.

#### Verification
- Review the public page structure in code and in the browser.
- Confirm the standardized patterns are actually used by the page.

#### Dependencies
- `ST-PUB-003`
