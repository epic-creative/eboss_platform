# EBoss.Umbrella

## Design System

Design-system guidance for typography, CSS layering, HEEx and Vue component boundaries, file locations, and Histoire usage lives in `DESIGN.md`.

Runtime host defaults are environment-aware:

* `local` -> `http://local.eboss.ai:4000`
* `stage` -> `https://stage.eboss.ai`
* `prod` -> `https://eboss.ai`

Use `EBOSS_ENV` to pick the default environment host, `PHX_HOST` to override the public hostname, and `PORT` to override the Phoenix listener.

`VITE_PORT` controls the LiveVue dev server in development.

Canonical-host redirects follow the same host model by default:

* `local` accepts both `local.eboss.ai` and `localhost`
* `stage` redirects to `stage.eboss.ai`
* `prod` redirects to `eboss.ai`

## Demo Data

Run deterministic local demo seeds from the umbrella root:

```bash
mix seed
```

Optional:

```bash
EBOSS_SEED_PASSWORD=supersecret123 mix seed
```

The seed script creates example users, an organization, user and org workspaces,
and a small Folio graph for local auth and API testing.

## Browser Smoke

After `mix setup`, prepare deterministic browser state and run the Playwright auth/public smoke subset from the web assets app:

```bash
cd apps/eboss_web/assets
npm run playwright:setup
npm run playwright:smoke
```

The smoke lane keeps the checked-in bootstrap fixture as a runner sanity check and adds app-backed coverage for the anonymous home shell, the dashboard-to-sign-in auth boundary, and the authenticated dashboard handoff. Smoke specs live in `apps/eboss_web/assets/tests/playwright/smoke`, future regression coverage lives in `apps/eboss_web/assets/tests/playwright/regression`, and generated traces, screenshots, and reports stay under `apps/eboss_web/assets/test-results/playwright/`.

The default browser-test account is `playwright-auth@localhost` / `playwright-pass-123`.

```bash
npm run playwright:verify-setup
```

The Playwright runner starts the Phoenix test server automatically for the smoke and setup-verification lanes. Use `npm run playwright:server:test` only when you want the test server running outside the Playwright process.

## Automated Frontend Gate

Run the lean repo gate from the umbrella root:

```bash
mix frontend.gate
```

That command runs `npm run vue:test`, `npm run playwright:setup`, and `npm run playwright:smoke` from `apps/eboss_web/assets`.

GitHub Actions runs the same gate in the `Frontend Confidence` workflow on pushes and pull requests. Local and CI runs default to `PLAYWRIGHT_BROWSER_CHANNEL=chromium`, so failures in either the Vitest lane or the Playwright smoke lane fail the workflow directly. Override the channel only when a different installed browser is required for debugging.
