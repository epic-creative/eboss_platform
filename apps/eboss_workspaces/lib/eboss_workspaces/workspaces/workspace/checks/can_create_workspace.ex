defmodule EBoss.Workspaces.Workspace.Checks.CanCreateWorkspace do
  use Ash.Policy.SimpleCheck

  alias EBoss.Organizations

  def describe(_opts), do: "user can create workspace for themselves or organizations they admin"

  def match?(nil, _context, _opts), do: false

  def match?(actor, %{changeset: changeset}, _opts) do
    owner_type = Ash.Changeset.get_argument(changeset, :owner_type)
    owner_id = Ash.Changeset.get_argument(changeset, :owner_id)

    case owner_type do
      :user ->
        owner_id == actor.id

      :organization ->
        Organizations.owner_or_admin?(actor.id, owner_id)

      _ ->
        false
    end
  end

  def match?(_, _, _), do: false
end
