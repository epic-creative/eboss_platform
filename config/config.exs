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

config :mime,
  extensions: %{
    "jsonapi" => "application/vnd.api+json"
  },
  types: %{
    "application/vnd.api+json" => ["json-api", "jsonapi"]
  }

config :ash_json_api, use_deep_object_for_filter_type?: false

if Code.ensure_loaded?(Dotenvy) do
  dotenv_path = Path.expand("../.env", __DIR__)

  dotenv_vars =
    Dotenvy.source!([
      System.get_env(),
      dotenv_path,
      System.get_env()
    ])

  System.put_env(dotenv_vars)
end

# Configure Mix tasks and generators
config :eboss_data,
  ecto_repos: [EBoss.Repo]

config :eboss_accounts,
  namespace: EBoss,
  ecto_repos: [EBoss.Repo],
  ash_domains: [EBoss.Accounts]

config :eboss_tenancy,
  namespace: EBoss,
  ecto_repos: [EBoss.Repo],
  ash_domains: [
    EBoss.Organizations,
    EBoss.Logs
  ]

config :eboss_workspaces,
  namespace: EBoss,
  ecto_repos: [EBoss.Repo],
  ash_domains: [EBoss.Workspaces]

config :eboss_folio,
  ecto_repos: [EBoss.Repo],
  ash_domains: [EBossFolio]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :eboss_accounts, EBoss.Mailer, adapter: Swoosh.Adapters.Local

config :eboss_web,
  namespace: EBossWeb,
  ecto_repos: [EBoss.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :eboss_web, EBossWeb.Endpoint,
  url: [host: "local.eboss.ai"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: EBossWeb.ErrorHTML, json: EBossWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: EBoss.PubSub,
  live_view: [signing_salt: "K622cRXx"]

config :live_vue,
  ssr: false,
  ssr_module: nil

config :phoenix_vite, PhoenixVite.Npm,
  assets: [
    args: [],
    cd: Path.expand("../apps/eboss_web/assets", __DIR__)
  ],
  vite: [
    args: ~w(exec -- vite),
    cd: Path.expand("../apps/eboss_web/assets", __DIR__),
    env: %{
      "MIX_BUILD_PATH" => Mix.Project.build_path(),
      "EBOSS_ENV" => System.get_env("EBOSS_ENV", "local"),
      "PHX_HOST" => System.get_env("PHX_HOST", "local.eboss.ai"),
      "VITE_PORT" => System.get_env("VITE_PORT", "5173")
    }
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
