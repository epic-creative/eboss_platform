defmodule EBossChat.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    idle_timeout = Application.get_env(:eboss_chat, :agent_idle_timeout_ms, :timer.minutes(15))

    children = [
      EBossChat.Jido,
      Jido.Agent.InstanceManager.child_spec(
        name: :workspace_chat_anthropic_sessions,
        agent: EBossChat.WorkspaceChatAgent,
        jido: EBossChat.Jido,
        idle_timeout: idle_timeout,
        storage: nil,
        agent_opts: [jido: EBossChat.Jido]
      ),
      Jido.Agent.InstanceManager.child_spec(
        name: :workspace_chat_openai_sessions,
        agent: EBossChat.WorkspaceChatOpenAIAgent,
        jido: EBossChat.Jido,
        idle_timeout: idle_timeout,
        storage: nil,
        agent_opts: [jido: EBossChat.Jido]
      )
    ]

    opts = [strategy: :one_for_one, name: EBossChat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
