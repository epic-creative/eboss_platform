defmodule EBoss.Organizations.Organization.Changes.SyncOwnerMembership do
  @moduledoc """
  Keeps organization owner memberships synchronized with `organization.owner_id`.
  """

  use Ash.Resource.Change

  alias EBoss.Organizations.Membership

  require Ash.Query

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn changeset, organization ->
      case sync_owner_membership(organization, changeset.domain) do
        :ok -> {:ok, organization}
        {:error, error} -> {:error, error}
      end
    end)
  end

  defp sync_owner_membership(organization, domain) do
    with :ok <- demote_stale_owner_memberships(organization, domain) do
      upsert_current_owner_membership(organization, domain)
    end
  end

  defp demote_stale_owner_memberships(organization, domain) do
    Membership
    |> Ash.Query.filter(
      organization_id == ^organization.id and role == :owner and user_id != ^organization.owner_id
    )
    |> Ash.read(domain: domain, authorize?: false)
    |> case do
      {:ok, memberships} ->
        Enum.reduce_while(memberships, :ok, fn membership, :ok ->
          membership
          |> Ash.Changeset.for_update(:demote_owner_role, %{})
          |> Ash.update(domain: domain, authorize?: false)
          |> case do
            {:ok, _updated_membership} -> {:cont, :ok}
            {:error, error} -> {:halt, {:error, error}}
          end
        end)

      {:error, error} ->
        {:error, error}
    end
  end

  defp upsert_current_owner_membership(organization, domain) do
    Membership
    |> Ash.Query.filter(organization_id == ^organization.id and user_id == ^organization.owner_id)
    |> Ash.read_one(domain: domain, authorize?: false)
    |> case do
      {:ok, nil} ->
        Membership
        |> Ash.Changeset.new()
        |> Ash.Changeset.set_argument(:user_id, organization.owner_id)
        |> Ash.Changeset.set_argument(:organization_id, organization.id)
        |> Ash.Changeset.for_create(:create_owner_membership, %{})
        |> Ash.create(domain: domain, authorize?: false)
        |> normalize_result()

      {:ok, %Membership{role: :owner}} ->
        :ok

      {:ok, membership} ->
        membership
        |> Ash.Changeset.for_update(:set_owner_role, %{})
        |> Ash.update(domain: domain, authorize?: false)
        |> normalize_result()

      {:error, error} ->
        {:error, error}
    end
  end

  defp normalize_result({:ok, _record}), do: :ok
  defp normalize_result({:error, error}), do: {:error, error}
end
