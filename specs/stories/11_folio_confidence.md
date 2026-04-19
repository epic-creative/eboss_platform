# Epic 11: Folio Confidence

This epic adds the test and browser confidence needed to keep iterating on the first real workspace app without the shell regressing underneath it.

The aim is not maximal coverage.
The aim is stable high-signal coverage for the new platform and Folio surfaces:

- app-aware shell routing
- Folio read states
- key mutation flows
- real browser confidence

### ST-FOL-030 Add stable test contracts for workspace-app and Folio surfaces
#### Goal
Make the new multi-app workspace shell and Folio pages testable without relying on fragile incidental markup.

#### Scope
- Identify the app-aware shell and Folio surfaces that need stable selectors or semantic hooks.
- Prefer accessible roles and labels first.
- Add explicit test IDs only where semantics are not stable enough.
- Keep the contract focused on the new platform and Folio surfaces.

#### Acceptance Criteria
- The app-aware shell and key Folio surfaces have stable test contracts.
- Test selectors do not depend on fragile incidental markup where avoidable.
- The contract is sufficient for later Vue, LiveView, and browser coverage.

#### Verification
- Review selectors and surface contracts in code.
- Confirm the contracts are sufficient for the next confidence stories.

#### Dependencies
- `ST-WAP-004`
- `ST-FOL-010`
- `ST-FOL-011`
- `ST-FOL-012`

### ST-FOL-031 Add Vue behavior coverage for the app-aware shell and Folio read states
#### Goal
Protect the client-side behavior that now matters once real app data replaces the earlier mock-only shell work.

#### Scope
- Add or extend `Vitest` coverage for app-aware shell navigation and Folio read-state behavior.
- Focus on selection, navigation, empty-state, loading-state, and inspector behavior where the client owns meaningful logic.
- Avoid brittle snapshot-heavy tests.
- Keep the coverage focused on stable contracts only.

#### Acceptance Criteria
- The app-aware shell and key Folio read behaviors have meaningful Vue tests.
- The tests validate behavior rather than implementation trivia.
- The suite complements browser and LiveView coverage instead of duplicating it.

#### Verification
- Run the relevant Vitest command set.
- Run `npm run vue:check` from `apps/eboss_web/assets`.

#### Dependencies
- `ST-FOL-030`
- `ST-FOL-014`

### ST-FOL-032 Add LiveView and server coverage for workspace-app and Folio routing/bootstrap wiring
#### Goal
Protect the server-driven routing and scope contract now that the workspace shell is app-aware.

#### Scope
- Add or extend LiveView and server-side tests for app-aware workspace routes.
- Add focused coverage for workspace bootstrap and Folio bootstrap wiring.
- Keep the story focused on server-side contract confidence rather than broad workflow tests.

#### Acceptance Criteria
- App-aware route rendering and auth gating have server-side coverage.
- Workspace and Folio bootstrap wiring are protected by focused tests.
- The suite makes route and scope regressions easier to catch early.

#### Verification
- Run the selected LiveView and server-side test subset.

#### Dependencies
- `ST-WAP-003`
- `ST-WAP-004`
- `ST-FOL-002`
- `ST-FOL-006`

### ST-FOL-033 Add Playwright smoke coverage for real Folio read flows
#### Goal
Introduce real browser confidence for the first live app surfaces once they are stable enough to test meaningfully.

#### Scope
- Add a small Playwright smoke layer for app-aware workspace navigation and Folio read flows.
- Focus on shell rendering, app navigation, projects, tasks, and activity reads.
- Avoid broad mutation coverage in this story unless the flows are already stable.
- Use deterministic seeded or scripted state, not manual ad hoc accounts.

#### Acceptance Criteria
- The new Folio app has a minimal but meaningful browser smoke suite.
- The tests verify real app-aware navigation and read surfaces.
- The suite provides confidence without overfitting to unstable markup.

#### Verification
- Run the selected Playwright smoke subset for Folio.

#### Dependencies
- `ST-FOL-030`
- `ST-FOL-032`

### ST-FOL-034 Add focused confidence for Folio mutation workflows and repo gating
#### Goal
Extend confidence from read flows into the first real Folio write paths and make the stable suites part of the repo’s normal protection path.

#### Scope
- Add targeted automated coverage for the highest-value Folio mutation workflows.
- Extend existing repo automation or gates to include the stable Folio confidence commands.
- Keep the gated suite lean enough for regular execution.
- Avoid turning every new workflow into an end-to-end browser script.

#### Acceptance Criteria
- The key Folio mutation workflows have targeted automated coverage.
- The stable Folio confidence commands are part of an automated repo gate.
- The repo clearly documents what Folio confidence runs automatically.

#### Verification
- Run the selected mutation-focused test commands.
- Run the configured automated gate locally or in its target environment where practical.

#### Dependencies
- `ST-FOL-023`
- `ST-FOL-024`
- `ST-FOL-025`
- `ST-FOL-031`
- `ST-FOL-032`
- `ST-FOL-033`
- `ST-TST-010`
