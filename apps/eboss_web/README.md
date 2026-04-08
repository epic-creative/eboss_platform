# EBossWeb

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server`

For local development, this project is configured around `local.eboss.ai`, assuming your DNS points it to `127.0.0.1`.

Now you can visit [`local.eboss.ai:4000`](http://local.eboss.ai:4000) from your browser.

Environment host defaults:

* `local` -> `http://local.eboss.ai:4000`
* `stage` -> `https://stage.eboss.ai`
* `prod` -> `https://eboss.ai`

Port and host overrides:

* `PORT` controls the Phoenix listener in all environments.
* `PUBLIC_HOST`, `PUBLIC_SCHEME`, `PUBLIC_PORT`, and `PUBLIC_URL` control the externally advertised app URL.
* `CANONICAL_HOST_ENABLED` toggles Phoenix-side canonical-host redirects. It defaults to `true` outside tests.
* `CANONICAL_HOST` overrides the redirect target host. By default it follows `PUBLIC_HOST`.
* `CANONICAL_HOST_PASSTHROUGH_HOSTS` allows a comma-separated list of hosts to skip canonical redirects.
* `VITE_HOST`, `VITE_SCHEME`, and `VITE_PORT` control the LiveVue/Vite dev-server URL.
* `VITE_ALLOWED_HOSTS` can be used when the dev server should accept additional host headers.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
