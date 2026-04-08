defmodule EBoss.Organizations.Organization.Changes.CleanupDependencies do
  @moduledoc """
  Removes dependent organization records before destroy.
  """

  use Ash.Resource.Change

  alias EBoss.Workspaces.Workspace

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      case cleanup_dependencies(changeset.data) do
        :ok -> changeset
        {:error, error} -> Ash.Changeset.add_error(changeset, error)
      end
    end)
  end

  defp cleanup_dependencies(organization) do
    destroy_org_workspaces(organization)
  end

  defp destroy_org_workspaces(organization) do
    Workspace
    |> Ash.Query.filter(owner_type == :organization and owner_id == ^organization.id)
    |> Ash.read(domain: EBoss.Workspaces, authorize?: false)
    |> case do
      {:ok, workspaces} ->
        Enum.reduce_while(workspaces, :ok, fn workspace, :ok ->
          workspace
          |> Ash.Changeset.for_destroy(:destroy)
          |> Ash.destroy(domain: EBoss.Workspaces, authorize?: false)
          |> case do
            :ok -> {:cont, :ok}
            {:error, error} -> {:halt, {:error, error}}
          end
        end)

      {:error, error} ->
        {:error, error}
    end
  end
end
