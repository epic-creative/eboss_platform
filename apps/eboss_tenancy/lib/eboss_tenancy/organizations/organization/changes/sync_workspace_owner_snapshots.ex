defmodule EBoss.Organizations.Organization.Changes.SyncWorkspaceOwnerSnapshots do
  use Ash.Resource.Change

  alias EBoss.Data.WorkspaceOwnerSnapshots

  @impl true
  def change(changeset, _opts, _context) do
    if Ash.Changeset.changing_attribute?(changeset, :name) do
      Ash.Changeset.after_action(changeset, fn _changeset, organization ->
        :ok =
          WorkspaceOwnerSnapshots.sync_active(
            :organization,
            organization.id,
            organization.owner_slug,
            organization.name
          )

        {:ok, organization}
      end)
    else
      changeset
    end
  end
end
