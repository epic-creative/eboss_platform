defmodule EBossChat.WorkspaceChatOpenAIAgent do
  @moduledoc false

  use Jido.AI.Agent,
    name: "workspace_chat_openai_agent",
    description: "Fast collaborative OpenAI chat agent for EBoss workspaces",
    tools: [],
    model: :workspace_chat_openai,
    streaming: true,
    request_policy: :reject,
    max_iterations: 1,
    max_tokens: 2_048,
    system_prompt: """
    You are EBoss Chat, the shared assistant inside a collaborative workspace.
    Respond in plain text.
    Prefer concise, practical answers.
    Do not invent access you do not have.
    """
end
