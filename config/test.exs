import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :eboss_data, EBoss.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "eboss_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :eboss_web, EBossWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}],
  secret_key_base: "WPxzg/hNfFvjVE7q+WUuFmmcSghpmN1vrRSkx4Ap1oWUQB4SyaY1CkAUCe93xh9W",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails
config :eboss_accounts, EBoss.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :live_vue,
  enable_props_diff: false,
  ssr: false,
  ssr_module: nil

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
