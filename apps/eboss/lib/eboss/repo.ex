defmodule EBoss.Repo do
  use Ecto.Repo,
    otp_app: :eboss,
    adapter: Ecto.Adapters.Postgres
end
