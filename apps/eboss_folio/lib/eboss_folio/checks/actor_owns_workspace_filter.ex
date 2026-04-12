defmodule EBossFolio.Checks.ActorOwnsWorkspaceFilter do
  use Ash.Policy.FilterCheck

  import Ash.Expr

  alias EBoss.Workspaces
  alias EBossFolio.Authorization

  @impl true
  def describe(_opts), do: "actor can manage the workspace attached to the Folio resource"

  @impl true
  def filter(nil, _context, _opts), do: false

  def filter(%{id: actor_id} = actor, _context, _opts) do
    expr(workspace_id in ^manageable_workspace_ids(actor, actor_id))
  end

  defp manageable_workspace_ids(actor, actor_id) do
    case Workspaces.list_workspaces(actor: actor) do
      {:ok, workspaces} ->
        workspaces
        |> Enum.filter(&Authorization.owner_or_admin?(actor_id, &1.id))
        |> Enum.map(& &1.id)

      _ ->
        []
    end
  end
end
