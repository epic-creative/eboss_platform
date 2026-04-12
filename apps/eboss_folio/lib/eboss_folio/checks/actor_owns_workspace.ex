defmodule EBossFolio.Checks.ActorOwnsWorkspace do
  use Ash.Policy.SimpleCheck

  alias EBossFolio.Authorization

  @impl true
  def describe(_opts), do: "actor can manage the workspace attached to the Folio resource"

  @impl true
  def match?(%{id: actor_id}, %{changeset: %Ash.Changeset{} = changeset}, _opts) do
    workspace_id =
      Ash.Changeset.get_argument(changeset, :workspace_id) ||
        Ash.Changeset.get_attribute(changeset, :workspace_id) ||
        changeset.data.workspace_id

    Authorization.owner_or_admin?(actor_id, workspace_id)
  end

  def match?(%{id: actor_id}, %{resource: %{workspace_id: workspace_id}}, _opts)
      when is_binary(workspace_id) do
    Authorization.owner_or_admin?(actor_id, workspace_id)
  end

  def match?(_, _, _), do: false
end
