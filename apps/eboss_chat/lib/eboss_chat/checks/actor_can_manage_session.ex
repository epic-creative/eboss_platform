defmodule EBossChat.Checks.ActorCanManageSession do
  use Ash.Policy.SimpleCheck

  alias EBossChat.Authorization

  @impl true
  def describe(_opts), do: "actor can manage the workspace chat session"

  @impl true
  def match?(nil, _record, _opts), do: false

  def match?(actor, %{changeset: %{data: session}}, _opts) do
    can_manage?(actor, session)
  end

  def match?(actor, %{resource: session}, _opts) do
    can_manage?(actor, session)
  end

  def match?(actor, record, _opts), do: can_manage?(actor, record)

  defp can_manage?(actor, record) do
    actor.id == Map.get(record, :created_by_user_id) or
      Authorization.workspace_admin?(actor.id, Map.get(record, :workspace_id))
  end
end
