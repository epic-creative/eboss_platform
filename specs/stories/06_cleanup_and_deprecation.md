# Epic 06: Cleanup and Deprecation

This epic exists to retire stale shared UI paths after the new design system has been adopted across the important product surfaces.

It should run after:

- design foundation convergence
- auth and public convergence
- dashboard convergence
- auth and public confidence work that protects critical browser paths
- dashboard and component confidence work that protects the stabilized product shell

### ST-DSN-010 Remove deprecated shared UI paths after system convergence
#### Goal
Retire stale shared UI paths so the new design system becomes the default implementation path rather than an optional layer.

#### Scope
- Identify deprecated shared UI patterns, classes, or component paths left behind after convergence work.
- Remove or consolidate obsolete shared primitives and design-system detours.
- Keep the resulting shared layer easier to navigate and extend.

#### Acceptance Criteria
- Deprecated shared UI paths are removed or clearly consolidated.
- The current design-system path is easier to identify in code.
- The cleanup does not break auth, public, or dashboard surfaces.

#### Verification
- Code review of removed or consolidated paths.
- Route smoke checks for shared surfaces affected by the cleanup.

#### Dependencies
- `ST-DSN-007`
- `ST-DSN-008`
- `ST-DSN-009`
- `ST-AUTH-002`
- `ST-PUB-004`
- `ST-DSH-006`
- `ST-TST-004`
- `ST-TST-005`
- `ST-TST-008`
- `ST-TST-009`
- `ST-TST-010`
