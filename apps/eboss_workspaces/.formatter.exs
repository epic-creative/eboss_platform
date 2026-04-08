# Used by "mix format"
[
  import_deps: [:ash, :ash_archival, :ash_cloak, :ash_postgres, :ash_slug],
  plugins: [Spark.Formatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
