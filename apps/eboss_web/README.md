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
* `PHX_HOST` controls the app hostname used in generated URLs and, for stage/prod, the canonical redirect target.
* `VITE_PORT` controls the LiveVue/Vite dev-server port.
* In `local`, both `local.eboss.ai` and `localhost` are accepted. Set `PHX_HOST=localhost` if you want generated asset and auth URLs to stay on localhost.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
