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

After `mix setup`, run the Playwright bootstrap smoke from the web assets app:

```bash
cd apps/eboss_web/assets
npm run playwright:smoke
```

The bootstrap smoke stays self-contained on a checked-in fixture page so the runner is proven before auth/public browser coverage lands. Smoke specs live in `apps/eboss_web/assets/tests/playwright/smoke`, future regression coverage lives in `apps/eboss_web/assets/tests/playwright/regression`, and generated traces, screenshots, and reports stay under `apps/eboss_web/assets/test-results/playwright/`.

For deterministic auth/public browser setup, prepare the dedicated browser-test user and storage states from `apps/eboss_web/assets`:

```bash
npm run playwright:setup
```

The default browser-test account is `playwright-auth@localhost` / `playwright-pass-123`.

Then start the test server and run the setup verification subset:

```bash
npm run playwright:server:test
npm run playwright:verify-setup
```
