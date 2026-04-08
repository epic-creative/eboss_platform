defmodule EBoss.Workspaces.WorkspaceMembership.Checks.ActorOwnsUserWorkspace do
  use Ash.Policy.SimpleCheck

  def describe(_opts), do: "actor owns the user-owned workspace"

  def match?(actor, %{changeset: changeset}, _opts) when not is_nil(actor) do
    workspace_id =
      Ash.Changeset.get_argument(changeset, :workspace_id) ||
        Ash.Changeset.get_attribute(changeset, :workspace_id)

    check_workspace_ownership(actor, workspace_id)
  end

  def match?(actor, %{query: _query, resource: resource}, _opts) when not is_nil(actor) do
    case resource do
      %{workspace_id: workspace_id} when not is_nil(workspace_id) ->
        check_workspace_ownership(actor, workspace_id)

      _ ->
        false
    end
  end

  def match?(_, _, _), do: false

  defp check_workspace_ownership(actor, workspace_id) when is_binary(workspace_id) do
    case Ash.get(EBoss.Workspaces.Workspace, workspace_id,
           domain: EBoss.Workspaces,
           authorize?: false
         ) do
      {:ok, workspace} ->
        workspace.owner_type == :user && workspace.owner_id == actor.id

      _ ->
        false
    end
  end

  defp check_workspace_ownership(_, _), do: false
end
