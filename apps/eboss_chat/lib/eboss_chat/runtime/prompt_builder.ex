defmodule EBossChat.Runtime.PromptBuilder do
  @moduledoc false

  def build(history, opts \\ []) when is_list(history) do
    workspace_name = Keyword.get(opts, :workspace_name, "workspace")
    owner_label = Keyword.get(opts, :owner_label, "workspace owner")

    transcript =
      history
      |> Enum.map_join("\n\n", &format_message/1)

    """
    You are responding inside a shared EBoss workspace chat for #{workspace_name}.
    The workspace owner context is #{owner_label}.

    Use the conversation transcript below as the complete recent history for this turn.
    Keep the reply concise, helpful, and plain text.

    #{transcript}
    """
    |> String.trim()
  end

  defp format_message(%{role: role, body: body, author: author}) do
    label =
      case {role, author} do
        {:assistant, _} -> "Assistant"
        {:system, _} -> "System"
        {:user, author} when is_binary(author) and author != "" -> "User (#{author})"
        {:user, _} -> "User"
      end

    "#{label}:\n#{body}"
  end
end
