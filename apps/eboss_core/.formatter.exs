[
  import_deps: [:ash, :ash_postgres, :ash_authentication, :ecto, :ecto_sql],
  subdirectories: ["priv/*/migrations"],
  plugins: [Spark.Formatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
