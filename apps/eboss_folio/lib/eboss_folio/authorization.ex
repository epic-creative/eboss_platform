defmodule EBossFolio.Authorization do
  @moduledoc false

  alias EBoss.Organizations
  alias EBoss.Workspaces

  def role(actor_id, workspace_id) do
    with true <- present?(actor_id),
         true <- present?(workspace_id),
         {:ok, workspace} <- Workspaces.get_workspace(workspace_id, authorize?: false) do
      case workspace.owner_type do
        :user ->
          if workspace.owner_id == actor_id, do: :owner, else: :none

        :organization ->
          cond do
            Organizations.owner?(actor_id, workspace.owner_id) -> :owner
            Organizations.admin?(actor_id, workspace.owner_id) -> :admin
            true -> :none
          end

        _ ->
          :none
      end
    else
      _ -> :none
    end
  end

  def owner?(actor_id, workspace_id) do
    role(actor_id, workspace_id) == :owner
  end

  def owner_or_admin?(actor_id, workspace_id),
    do: role(actor_id, workspace_id) in [:owner, :admin]

  defp present?(value), do: not is_nil(value)
end
