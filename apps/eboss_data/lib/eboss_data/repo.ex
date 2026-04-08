defmodule EBoss.Repo do
  use Ecto.Repo,
    otp_app: :eboss_data,
    adapter: Ecto.Adapters.Postgres

  use AshPostgres.Repo,
    define_ecto_repo?: false

  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end

  def installed_extensions do
    ["ash-functions", "citext"]
  end
end
