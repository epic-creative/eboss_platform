# Playwright Layout

Local browser confidence starts in this tree.

- `tests/playwright/smoke`: the small public/auth smoke lane, including the bootstrap fixture and app-backed route checks for the anonymous home shell, auth boundary, and authenticated dashboard handoff.
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

The default setup user is `playwright-auth@localhost` with username `playwright_auth_user` and password `playwright-pass-123`.
Override `EBOSS_PLAYWRIGHT_EMAIL`, `EBOSS_PLAYWRIGHT_USERNAME`, `EBOSS_PLAYWRIGHT_PASSWORD`, or `PLAYWRIGHT_BASE_URL` when a local override is required.

To verify the prepared state against the real app:

```bash
npm run playwright:setup
npm run playwright:verify-setup
```

The Playwright runner starts the Phoenix test server automatically for `playwright:smoke`, `playwright:verify-setup`, and `playwright:test`. Keep `npm run playwright:server:test` for manual debugging when you want the server running outside the test runner.

Tooling decisions:

- The bootstrap smoke stays self-contained on a checked-in HTML fixture, and the smoke lane now adds the smallest app-backed auth/public checks that reuse deterministic state from `playwright:setup`.
- Smoke coverage stops at route entry, redirect, and authenticated handoff. Deeper sign-in regressions and broader dashboard behavior stay in dedicated follow-on suites.
- The bootstrap suite defaults to the locally installed Google Chrome channel. Override with `PLAYWRIGHT_BROWSER_CHANNEL` if another installed browser should drive the run.
- Deterministic browser setup lives in a test-only Mix task so CI and local runs can recreate the same user and storage-state files without manual accounts or hand-built sessions.
- The first `npm run playwright:*` execution downloads `playwright@1.59.1` into the npm cache unless it is already present.
