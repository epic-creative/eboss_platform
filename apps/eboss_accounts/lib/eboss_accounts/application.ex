defmodule EBossAccounts.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {AshAuthentication.Supervisor, otp_app: :eboss_accounts}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: EBossAccounts.Supervisor)
  end
end
