defmodule EBoss.Organizations.Organization.Changes.ArchiveDependents do
  use Ash.Resource.Change

  alias EBoss.Organizations.{Invitation, Membership}

  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn changeset, organization ->
      with :ok <- archive_memberships(organization, changeset.domain),
           :ok <- archive_invitations(organization, changeset.domain) do
        {:ok, organization}
      end
    end)
  end

  defp archive_memberships(organization, domain) do
    Membership
    |> Ash.Query.filter(organization_id == ^organization.id)
    |> Ash.read(domain: domain, authorize?: false)
    |> destroy_each(domain, ash_archival: true)
  end

  defp archive_invitations(organization, domain) do
    Invitation
    |> Ash.Query.filter(organization_id == ^organization.id)
    |> Ash.read(domain: domain, authorize?: false)
    |> destroy_each(domain)
  end

  defp destroy_each(records_or_error, domain, context \\ [])

  defp destroy_each({:ok, records}, domain, context) do
    Enum.reduce_while(records, :ok, fn record, :ok ->
      changeset =
        record
        |> Ash.Changeset.new()
        |> maybe_set_context(context)
        |> Ash.Changeset.for_destroy(:destroy, %{})

      case Ash.destroy(changeset, domain: domain, authorize?: false) do
        :ok -> {:cont, :ok}
        {:ok, _record} -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp destroy_each({:error, error}, _domain, _context), do: {:error, error}

  defp maybe_set_context(changeset, []), do: changeset

  defp maybe_set_context(changeset, context),
    do: Ash.Changeset.set_context(changeset, Map.new(context))
end
