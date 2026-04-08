defmodule EBossFolio.Authorization do
  @moduledoc false

  alias EBoss.Organizations.Authorization, as: OrganizationAuthorization
  alias EBoss.Workspaces.Workspace

  def owner?(actor_id, workspace_id) do
    with true <- present?(actor_id),
         true <- present?(workspace_id),
         {:ok, workspace} <-
           Ash.get(Workspace, workspace_id, domain: EBoss.Workspaces, authorize?: false) do
      case workspace.owner_type do
        :user ->
          workspace.owner_id == actor_id

        :organization ->
          OrganizationAuthorization.owner?(actor_id, workspace.owner_id)

        _ ->
          false
      end
    else
      _ -> false
    end
  end

  defp present?(value), do: not is_nil(value)
end
