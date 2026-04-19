defmodule EBoss.Workspaces.Workspace.Changes.SetOwnerSnapshot do
  use Ash.Resource.Change

  alias EBoss.Workspaces.Workspace.OwnerSnapshot

  @impl true
  def change(changeset, _opts, _context) do
    owner_type = Ash.Changeset.get_attribute(changeset, :owner_type)
    owner_id = Ash.Changeset.get_attribute(changeset, :owner_id)

    with owner_type when not is_nil(owner_type) <- owner_type,
         owner_id when not is_nil(owner_id) <- owner_id,
         {:ok, %{owner_slug: owner_slug, owner_display_name: owner_display_name}} <-
           OwnerSnapshot.attributes(owner_type, owner_id) do
      changeset
      |> Ash.Changeset.force_change_attribute(:owner_slug, owner_slug)
      |> Ash.Changeset.force_change_attribute(:owner_display_name, owner_display_name)
    else
      _ -> changeset
    end
  end
end
