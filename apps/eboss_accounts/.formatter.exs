# Used by "mix format"
[
  import_deps: [:ash, :ash_archival, :ash_authentication, :ash_cloak, :ash_postgres],
  plugins: [Spark.Formatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
