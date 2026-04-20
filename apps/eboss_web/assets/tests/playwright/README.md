# Playwright Layout

Local browser confidence starts in this tree.

- `tests/playwright/smoke`: the small public/auth smoke lane, including the bootstrap fixture, app-backed read coverage, and focused Folio mutation workflows for projects and tasks.
- `tests/playwright/smoke/dashboard-shell.spec.ts`: the authenticated dashboard shell smoke subset for route chrome, section states, and shell-owned interactions.
- `tests/playwright/regression`: targeted bug coverage once a browser-visible issue is fixed.
- `tests/playwright/setup`: deterministic-state verification for app-backed auth/public browser runs.
- `tests/playwright/fixtures`: future storage states, uploads, and helper assets for deterministic runs.
- `tests/playwright/.auth`: generated public/authenticated storage states and metadata from the setup command.
- `test-results/playwright`: generated traces, screenshots, and raw test output.
- `test-results/playwright/report`: generated HTML report for local review.

Local smoke command from `apps/eboss_web/assets`:

```bash
npm run playwright:setup
npm run playwright:smoke
npm run playwright:smoke:folio-mutation
```

Automated repo gate from the umbrella root:

```bash
mix frontend.gate
```

The `Frontend Confidence` GitHub Actions workflow runs that gate on pushes and pull requests. The automated lane keeps Playwright to deterministic setup plus `npm run playwright:smoke` and `npm run playwright:smoke:folio-mutation`.

Dashboard smoke subset from `apps/eboss_web/assets`:

```bash
npm run playwright:setup
npm run playwright:smoke:dashboard
```

Focused Folio mutation smoke from `apps/eboss_web/assets`:

```bash
npm run playwright:setup
npm run playwright:smoke:folio-mutation
```

Full suite command from `apps/eboss_web/assets`:

```bash
npm run playwright:test
```

Deterministic auth/public setup from `apps/eboss_web/assets`:

```bash
npm run playwright:setup
```

This creates a rerunnable browser-test account plus generated storage-state files for:

- an anonymous public context
- an authenticated dashboard context

The default setup user is `playwright-auth@localhost` with username `playwright-auth-user` and password `playwright-pass-123`.
Override `EBOSS_PLAYWRIGHT_EMAIL`, `EBOSS_PLAYWRIGHT_USERNAME`, `EBOSS_PLAYWRIGHT_PASSWORD`, or `PLAYWRIGHT_BASE_URL` when a local override is required.

To verify the prepared state against the real app:

```bash
npm run playwright:setup
npm run playwright:verify-setup
```

The Playwright runner starts the Phoenix test server automatically for `playwright:smoke`, `playwright:smoke:dashboard`, `playwright:verify-setup`, and `playwright:test`. Keep `npm run playwright:server:test` for manual debugging when you want the server running outside the test runner.

Tooling decisions:

- The bootstrap smoke stays self-contained on a checked-in HTML fixture, and the smoke lane now adds the smallest app-backed auth boundary and auth/public checks that reuse deterministic state from `playwright:setup`.
- The dashboard shell smoke stays route-focused: it checks shell landmarks, section/state coverage, and the shell-owned links/actions that should stay stable while deeper workflows continue to move.
- Smoke coverage stops at route entry, redirect, and dashboard handoff/authenticated handoff. Deeper sign-in regressions and broader dashboard behavior stay in dedicated follow-on suites.
- Local and CI runs default to the Playwright-managed `chromium` channel. Override `PLAYWRIGHT_BROWSER_CHANNEL` only when another installed browser should drive a local debugging session.
- Deterministic browser setup lives in a test-only Mix task so CI and local runs can recreate the same user and storage-state files without manual accounts or hand-built sessions.
- Install asset dependencies with `npm install` or `npm ci` first so the local Playwright package and CLI are available before running the browser suite.
