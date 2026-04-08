defmodule EBossFolio.Checks.ActorOwnsWorkspace do
  use Ash.Policy.SimpleCheck

  alias EBossFolio.Authorization

  @impl true
  def describe(_opts), do: "actor owns the workspace attached to the Folio resource"

  @impl true
  def match?(%{id: actor_id}, %{changeset: changeset}, _opts) do
    workspace_id =
      Ash.Changeset.get_attribute(changeset, :workspace_id) ||
        changeset.data.workspace_id

    Authorization.owner?(actor_id, workspace_id)
  end

  def match?(%{id: actor_id}, %{resource: %{workspace_id: workspace_id}}, _opts) do
    Authorization.owner?(actor_id, workspace_id)
  end

  def match?(_, _, _), do: false
end
