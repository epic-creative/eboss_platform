# Playwright Layout

Local browser confidence starts in this tree.

- `tests/playwright/smoke`: cheap runner checks that prove Playwright can execute in this repo before app-backed smoke coverage lands.
- `tests/playwright/regression`: targeted bug coverage once a browser-visible issue is fixed.
- `tests/playwright/setup`: deterministic-state verification for app-backed auth/public browser runs.
- `tests/playwright/fixtures`: future storage states, uploads, and helper assets for deterministic runs.
- `tests/playwright/.auth`: generated public/authenticated storage states and metadata from the setup command.
- `test-results/playwright`: generated traces, screenshots, and raw test output.
- `test-results/playwright/report`: generated HTML report for local review.

Local smoke command from `apps/eboss_web/assets`:

```bash
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

To verify the prepared state against the real app, start the test server from `apps/eboss_web/assets` in one shell:

```bash
npm run playwright:server:test
```

Then run the setup verification subset in another shell:

```bash
npm run playwright:verify-setup
```

Tooling decisions:

- The bootstrap smoke stays self-contained on a checked-in HTML fixture so this story proves the runner without pulling later auth/public coverage forward.
- The bootstrap suite defaults to the locally installed Google Chrome channel. Override with `PLAYWRIGHT_BROWSER_CHANNEL` if another installed browser should drive the run.
- Deterministic browser setup lives in a test-only Mix task so CI and local runs can recreate the same user and storage-state files without manual accounts or hand-built sessions.
- The first `npm run playwright:*` execution downloads `playwright@1.59.1` into the npm cache unless it is already present.
