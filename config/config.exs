# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :eboss_core,
  namespace: EBoss,
  ecto_repos: [EBoss.Repo],
  ash_domains: [
    EBoss.Accounts,
    EBoss.Organizations,
    EBoss.Workspaces,
    EBoss.Logs
  ]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :eboss_core, EBoss.Mailer, adapter: Swoosh.Adapters.Local

config :eboss_web,
  namespace: EBossWeb,
  ecto_repos: [EBoss.Repo],
  generators: [context_app: :eboss_core, binary_id: true]

# Configures the endpoint
config :eboss_web, EBossWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: EBossWeb.ErrorHTML, json: EBossWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: EBoss.PubSub,
  live_view: [signing_salt: "K622cRXx"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  eboss_web: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../apps/eboss_web/assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  eboss_web: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("../apps/eboss_web", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
