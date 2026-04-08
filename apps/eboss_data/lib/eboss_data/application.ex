defmodule EBossData.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EBoss.Repo,
      {DNSCluster, query: Application.get_env(:eboss_data, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EBoss.PubSub}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: EBossData.Supervisor)
  end
end
