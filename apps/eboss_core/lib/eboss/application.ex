defmodule EBoss.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EBoss.Repo,
      {DNSCluster, query: Application.get_env(:eboss_core, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EBoss.PubSub},
      {Task.Supervisor, name: EBoss.Logs.TaskSupervisor},
      {AshAuthentication.Supervisor, otp_app: :eboss_core}
      # Start a worker by calling: EBoss.Worker.start_link(arg)
      # {EBoss.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: EBoss.Supervisor)
  end
end
