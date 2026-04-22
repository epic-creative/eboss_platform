defmodule EBossChat.Checks.ActorCanAccessWorkspace do
  use Ash.Policy.SimpleCheck

  alias EBossChat.Authorization

  @impl true
  def describe(_opts), do: "actor can access the workspace attached to the chat resource"

  @impl true
  def match?(%{id: actor_id}, %{changeset: %Ash.Changeset{} = changeset}, _opts) do
    workspace_id =
      Ash.Changeset.get_argument(changeset, :workspace_id) ||
        Ash.Changeset.get_attribute(changeset, :workspace_id) ||
        Map.get(changeset.data, :workspace_id)

    Authorization.workspace_member?(actor_id, workspace_id)
  end

  def match?(%{id: actor_id}, %{resource: %{workspace_id: workspace_id}}, _opts)
      when is_binary(workspace_id) do
    Authorization.workspace_member?(actor_id, workspace_id)
  end

  def match?(_, _, _), do: false
end
