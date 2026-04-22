defmodule EBossChat.Authorization do
  @moduledoc false

  alias EBoss.Organizations
  alias EBoss.Workspaces

  def workspace_member?(actor_id, workspace_id, _opts \\ []) do
    with true <- present?(actor_id),
         true <- present?(workspace_id),
         {:ok, workspace} <-
           Workspaces.get_workspace(workspace_id,
             authorize?: false,
             load: [:workspace_memberships]
           ) do
      case workspace.owner_type do
        :user ->
          workspace.owner_id == actor_id or
            Enum.any?(workspace.workspace_memberships, &(&1.user_id == actor_id))

        :organization ->
          Organizations.roles_by_organization_ids(actor_id, [workspace.owner_id])
          |> Map.get(workspace.owner_id) != :none

        _ ->
          false
      end
    else
      _ -> false
    end
  end

  def workspace_admin?(actor_id, workspace_id, opts \\ []) do
    with true <- present?(actor_id),
         true <- present?(workspace_id),
         {:ok, workspace} <-
           Workspaces.get_workspace(workspace_id,
             authorize?: false,
             load: [:workspace_memberships]
           ) do
      case workspace.owner_type do
        :user ->
          workspace.owner_id == actor_id or
            Enum.any?(workspace.workspace_memberships, fn membership ->
              membership.user_id == actor_id and membership.role in [:owner, :admin]
            end)

        :organization ->
          Organizations.owner_or_admin?(actor_id, workspace.owner_id, opts)

        _ ->
          false
      end
    else
      _ -> false
    end
  end

  defp present?(value), do: not is_nil(value)
end
