defmodule EBoss.Accounts.User.Changes.SyncWorkspaceOwnerSnapshots do
  use Ash.Resource.Change

  alias EBoss.Data.WorkspaceOwnerSnapshots

  @impl true
  def change(changeset, _opts, _context) do
    if Ash.Changeset.changing_attribute?(changeset, :username) do
      Ash.Changeset.after_action(changeset, fn _changeset, user ->
        :ok = WorkspaceOwnerSnapshots.sync_active(:user, user.id, user.username, user.username)
        {:ok, user}
      end)
    else
      changeset
    end
  end
end
