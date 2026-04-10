# Epic 05: Dashboard and Component Confidence

This epic adds the remaining browser and component coverage after the product shell and shared Vue primitives stabilize.

The sequence here matters:

- stabilize the dashboard shell first
- define dashboard-specific test contracts second
- add dashboard smoke and Vue component tests third

### ST-TST-006 Add stable test contracts for dashboard surfaces
#### Goal
Make dashboard browser testing resilient by defining stable selectors and access patterns after the shell structure stops moving.

#### Scope
- Identify the dashboard shell and state surfaces that need stable test hooks.
- Prefer accessible roles and labels first.
- Add explicit test IDs only where semantics are insufficient or unstable.
- Keep the contract focused on authenticated dashboard surfaces.

#### Acceptance Criteria
- Key dashboard surfaces have stable test contracts.
- Test selectors do not depend on fragile incidental markup where avoidable.
- The chosen approach is documented in code or stories where necessary.

#### Verification
- Review dashboard shell and state surfaces for stable selectors and labels.
- Confirm the contracts are sufficient for dashboard Playwright smoke coverage.

#### Dependencies
- `ST-DSH-002`

### ST-TST-007 Bootstrap Vitest and Vue component behavior test tooling
#### Goal
Set up a concrete Vue component-test stack before asking Ralph to write behavior tests for Vue primitives.

#### Scope
- Use `Vitest` with `@vue/test-utils` as the default component-test stack for Vue code in this repo.
- Add the minimal configuration, setup helpers, and one proof-of-life test path.
- Make sure the setup works cleanly with the Vite-based asset pipeline and `live_vue` component authoring.
- Keep the story focused on toolchain readiness, not broad coverage.

#### Acceptance Criteria
- The repo can execute Vitest-based Vue component tests locally.
- The tooling choice and command path are clear for later stories.
- The setup is ready for stable primitive tests.

#### Verification
- Run the selected Vitest component test command locally.
- Run `npm run vue:check` from `apps/eboss_web/assets`.

#### Dependencies
- `ST-DSN-008`
- `ST-DSN-009`

### ST-TST-008 Add Vitest component behavior tests for stable LiveVue primitives
#### Goal
Add focused component-level confidence for the Vue primitive layer once contracts stop moving.

#### Scope
- Select a small set of stable Vue primitives for behavior-oriented tests using `Vitest` and `@vue/test-utils`.
- Start with primitives that already have strong Histoire coverage and stable contracts.
- Focus on logic, props, emitted events, keyboard behavior, and state transitions rather than screenshot churn.
- Avoid writing tests for components whose contracts are still being redesigned.
- Avoid snapshot-heavy tests when targeted behavior assertions are clearer.

#### Acceptance Criteria
- Stable Vue primitives have meaningful behavior tests.
- The tests validate component contracts rather than implementation trivia.
- Component tests complement, rather than duplicate, Histoire review surfaces and browser smoke tests.

#### Verification
- Run the Vitest component test command set selected in implementation.
- Run `npm run vue:check` from `apps/eboss_web/assets`.

#### Dependencies
- `ST-TST-007`
- `ST-DSN-008`
- `ST-DSN-009`

### ST-TST-009 Add dashboard smoke coverage after shell stabilization
#### Goal
Extend browser confidence into the authenticated product shell once dashboard structure is stable enough to test.

#### Scope
- Add a small Playwright smoke layer for the dashboard shell and its core states.
- Focus on navigation, shell rendering, and high-value dashboard interactions.
- Avoid broad workflow automation until the product flows themselves stabilize.

#### Acceptance Criteria
- The dashboard has a minimal but meaningful browser smoke suite.
- Coverage reflects shell stability rather than speculative future workflow behavior.
- The tests provide confidence without overfitting to unstable markup.

#### Verification
- Run the dashboard smoke subset in Playwright.

#### Dependencies
- `ST-TST-004`
- `ST-TST-006`
- `ST-DSH-002`
- `ST-DSH-003`
- `ST-DSH-004`

### ST-TST-010 Wire Playwright and Vitest lanes into an automated repo gate
#### Goal
Make the new browser and component suites protect the repo instead of existing only as local developer tools.

#### Scope
- Add an automated gate for the chosen Playwright and Vitest commands, such as CI or an equivalent always-on repo workflow.
- Keep the gated suite intentionally lean enough for regular execution.
- Document what runs automatically and when.
- Avoid broadening the gate beyond the stable high-signal suites already added in this backlog.

#### Acceptance Criteria
- Playwright and Vitest have an automated execution path that runs without manual intervention.
- Failures in the chosen suites are visible and fail the automated gate.
- The repo documents the intended automated test path clearly enough for ongoing use.

#### Verification
- Execute the automated gate locally or in its target environment where practical.
- Confirm the configured gate runs the intended Playwright and Vitest commands.

#### Dependencies
- `ST-TST-005`
- `ST-TST-008`
- `ST-TST-009`
