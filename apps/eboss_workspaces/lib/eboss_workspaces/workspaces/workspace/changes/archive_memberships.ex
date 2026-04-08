defmodule EBoss.Workspaces.Workspace.Changes.ArchiveMemberships do
  use Ash.Resource.Change

  alias EBoss.Workspaces.WorkspaceMembership

  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn changeset, workspace ->
      case archive_memberships(workspace, changeset.domain) do
        :ok -> {:ok, workspace}
        {:error, error} -> {:error, error}
      end
    end)
  end

  defp archive_memberships(workspace, domain) do
    WorkspaceMembership
    |> Ash.Query.filter(workspace_id == ^workspace.id)
    |> Ash.read(domain: domain, authorize?: false)
    |> case do
      {:ok, memberships} ->
        Enum.reduce_while(memberships, :ok, fn membership, :ok ->
          case Ash.destroy(
                 Ash.Changeset.for_destroy(membership, :destroy, %{}),
                 domain: domain,
                 authorize?: false
               ) do
            :ok -> {:cont, :ok}
            {:ok, _membership} -> {:cont, :ok}
            {:error, error} -> {:halt, {:error, error}}
          end
        end)

      {:error, error} ->
        {:error, error}
    end
  end
end
