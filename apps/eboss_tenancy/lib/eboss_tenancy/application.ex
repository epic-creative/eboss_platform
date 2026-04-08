defmodule EBossTenancy.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: EBoss.Logs.TaskSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: EBossTenancy.Supervisor)
  end
end
