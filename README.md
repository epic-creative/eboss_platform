# EBoss.Umbrella

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
