# Playwright Layout

Local browser confidence starts in this tree.

- `tests/playwright/smoke`: cheap runner checks that prove Playwright can execute in this repo before app-backed smoke coverage lands.
- `tests/playwright/regression`: targeted bug coverage once a browser-visible issue is fixed.
- `tests/playwright/fixtures`: future storage states, uploads, and helper assets for deterministic runs.
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

Tooling decisions:

- The bootstrap smoke stays self-contained on a checked-in HTML fixture so this story proves the runner without pulling later auth/public coverage forward.
- The bootstrap suite defaults to the locally installed Google Chrome channel. Override with `PLAYWRIGHT_BROWSER_CHANNEL` if another installed browser should drive the run.
- The first `npm run playwright:*` execution downloads `playwright@1.59.1` into the npm cache unless it is already present.
