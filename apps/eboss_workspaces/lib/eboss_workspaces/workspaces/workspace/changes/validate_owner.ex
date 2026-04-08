defmodule EBoss.Workspaces.Workspace.Changes.ValidateOwner do
  use Ash.Resource.Change

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
    case Ash.get(EBoss.Accounts.User, owner_id, domain: EBoss.Accounts, authorize?: false) do
      {:ok, _user} ->
        changeset

      {:error, _error} ->
        Ash.Changeset.add_error(changeset, field: :owner_id, message: "User not found")
    end
  end

  defp validate_owner_exists(changeset, :organization, owner_id) do
    case Ash.get(EBoss.Organizations.Organization, owner_id,
           domain: EBoss.Organizations,
           authorize?: false
         ) do
      {:ok, _organization} ->
        changeset

      {:error, _error} ->
        Ash.Changeset.add_error(changeset, field: :owner_id, message: "Organization not found")
    end
  end
end
