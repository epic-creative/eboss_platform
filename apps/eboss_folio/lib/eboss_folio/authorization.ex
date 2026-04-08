defmodule EBossFolio.Authorization do
  @moduledoc false

  alias EBoss.Organizations
  alias EBoss.Workspaces

  def owner?(actor_id, workspace_id) do
    with true <- present?(actor_id),
         true <- present?(workspace_id),
         {:ok, workspace} <- Workspaces.get_workspace(workspace_id, authorize?: false) do
      case workspace.owner_type do
        :user ->
          workspace.owner_id == actor_id

        :organization ->
          Organizations.owner?(actor_id, workspace.owner_id)

        _ ->
          false
      end
    else
      _ -> false
    end
  end

  defp present?(value), do: not is_nil(value)
end
