defmodule EBoss.Workspaces.Workspace.Changes.ValidateOwner do
  use Ash.Resource.Change

  alias EBoss.Workspaces.Workspace.OwnerSnapshot

  def init(opts), do: {:ok, opts}

  def change(changeset, _opts, _context) do
    owner_type = Ash.Changeset.get_attribute(changeset, :owner_type)
    owner_id = Ash.Changeset.get_attribute(changeset, :owner_id)

    if owner_type && owner_id do
      validate_owner_exists(changeset, owner_type, owner_id)
    else
      changeset
    end
  end

  defp validate_owner_exists(changeset, :user, owner_id) do
    case OwnerSnapshot.fetch(:user, owner_id) do
      {:ok, _snapshot} ->
        changeset

      {:error, _error} ->
        Ash.Changeset.add_error(changeset, field: :owner_id, message: "User not found")
    end
  end

  defp validate_owner_exists(changeset, :organization, owner_id) do
    case OwnerSnapshot.fetch(:organization, owner_id) do
      {:ok, _snapshot} ->
        changeset

      {:error, _error} ->
        Ash.Changeset.add_error(changeset, field: :owner_id, message: "Organization not found")
    end
  end
end
