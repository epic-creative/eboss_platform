# EBoss.Umbrella

Runtime host defaults are environment-aware:

* `local` -> `http://local.eboss.ai:4000`
* `stage` -> `https://stage.eboss.ai`
* `prod` -> `https://eboss.ai`

Use `EBOSS_ENV` plus `PUBLIC_HOST`, `PUBLIC_SCHEME`, `PUBLIC_PORT`, or `PUBLIC_URL` to override the defaults.

`PORT` controls the Phoenix listener, and `VITE_HOST` / `VITE_SCHEME` / `VITE_PORT` control the LiveVue dev server in development.

Canonical-host redirects follow the same host model by default:

* `local` redirects to `local.eboss.ai`
* `stage` redirects to `stage.eboss.ai`
* `prod` redirects to `eboss.ai`

Use `CANONICAL_HOST_ENABLED`, `CANONICAL_HOST`, or `CANONICAL_HOST_PASSTHROUGH_HOSTS` to override that behavior.
