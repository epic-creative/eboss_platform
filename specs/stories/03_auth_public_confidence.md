# Epic 03: Auth and Public Confidence

This epic introduces the earliest browser-confidence work only where the UI is already stable enough to justify it.

It exists to support two practical needs:

- catch browser-only auth and public regressions before deeper dashboard work
- bootstrap Playwright early enough that known auth bugs do not stay unprotected

### ST-TST-001 Add stable test contracts for auth and public surfaces
#### Goal
Make early browser testing resilient by defining stable selectors and access patterns for auth and public surfaces before broader Playwright work begins.

#### Scope
- Identify the auth and public surfaces that need stable test hooks.
- Prefer accessible roles and labels first.
- Add explicit test IDs only where semantics are insufficient or unstable.
- Keep the contract focused on auth and public pages rather than the dashboard.

#### Acceptance Criteria
- Key auth and public surfaces have stable test contracts.
- Test selectors do not depend on fragile incidental markup where avoidable.
- The chosen approach is documented in code or stories where necessary.

#### Verification
- Review key auth and public screens for stable selectors and labels.
- Confirm the contracts are sufficient for Playwright smoke and regression tests.

#### Dependencies
- `ST-AUTH-001`
- `ST-PUB-001`

### ST-TST-002 Bootstrap Playwright tooling and local smoke execution
#### Goal
Create the Playwright foundation before adding real browser coverage stories.

#### Scope
- Add Playwright project scaffolding and local execution commands.
- Decide where traces, screenshots, and test assets should live.
- Prove the toolchain can execute successfully in this repo.

#### Acceptance Criteria
- The repo can execute Playwright locally with a documented command.
- The Playwright structure is ready for smoke and regression tests.
- Tooling decisions are clear enough for later stories to build on directly.

#### Verification
- Run Playwright locally in this repo.
- Document or encode the commands needed to execute it.

#### Dependencies
- `ST-TST-001`

### ST-TST-003 Add deterministic browser test data and session setup for auth and public flows
#### Goal
Ensure Playwright runs against known state instead of ad hoc local accounts or manually prepared sessions.

#### Scope
- Establish deterministic user and session setup for the early auth and public browser suite.
- Prefer scripted or seeded setup that can be rerun locally and in CI.
- Avoid hidden dependencies on manually created dev accounts or one-off state.
- Keep the setup narrow and aligned with the early smoke suite rather than future full-product workflow coverage.

#### Acceptance Criteria
- Auth and public browser tests can run against deterministic state.
- The setup path does not depend on ad hoc manual data.
- The repo has a clear path for preparing required browser-test users or sessions.

#### Verification
- Run the setup path locally.
- Run the auth and public smoke subset against the prepared state.

#### Dependencies
- `ST-TST-002`

### ST-TST-004 Add Playwright auth and public smoke harness
#### Goal
Introduce a small browser smoke suite for the highest-value public and auth flows.

#### Scope
- Add a minimal smoke suite for critical auth and public flows.
- Cover only the highest-signal scenarios for now.
- Keep the suite intentionally small and stable.

#### Acceptance Criteria
- The suite covers the critical auth and public flows agreed in scope.
- The smoke suite is stable enough for iterative use.
- The suite is clearly separated from deeper regression coverage.

#### Verification
- Run the new Playwright smoke subset locally.

#### Dependencies
- `ST-TST-003`
- `ST-AUTH-001`
- `ST-PUB-001`

### ST-TST-005 Add sign-in browser regression coverage
#### Goal
Lock in coverage for the sign-in field-retention bug after the behavior is corrected.

#### Scope
- Add a browser regression test for the sign-in interaction that was reproduced manually.
- Make sure the test reflects real user interaction rather than only form submission.
- Keep the test stable by using the contracts established in earlier testability work.

#### Acceptance Criteria
- The known sign-in field-retention regression is covered in Playwright.
- The test fails against the broken behavior and passes against the corrected behavior.
- The test is stable enough to keep in the smoke suite or regression suite.

#### Verification
- Run the targeted Playwright regression test.

#### Dependencies
- `ST-TST-004`
- `ST-AUTH-003`
