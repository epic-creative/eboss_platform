defmodule EBoss.Data.WorkspaceOwnerSnapshots do
  @moduledoc false

  import Ecto.Query

  alias EBoss.Repo

  def sync_active(owner_type, owner_id, owner_slug, owner_display_name)
      when is_binary(owner_id) and is_binary(owner_slug) and is_binary(owner_display_name) do
    owner_type = normalize_owner_type(owner_type)
    owner_id = Ecto.UUID.dump!(owner_id)

    from(workspace in "workspaces",
      where:
        workspace.owner_type == ^owner_type and
          workspace.owner_id == ^owner_id and
          is_nil(workspace.archived_at)
    )
    |> Repo.update_all(
      set: [
        owner_slug: owner_slug,
        owner_display_name: owner_display_name,
        updated_at: DateTime.utc_now()
      ]
    )

    :ok
  end

  defp normalize_owner_type(owner_type) when is_atom(owner_type), do: Atom.to_string(owner_type)
  defp normalize_owner_type(owner_type) when is_binary(owner_type), do: owner_type
end
