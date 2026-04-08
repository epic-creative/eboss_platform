defmodule EBoss.Organizations.Invitation.Checks.CanCreateInvitation do
  use Ash.Policy.SimpleCheck

  require Ash.Query

  @impl true
  def describe(_), do: "actor can create invitations for the organization"

  @impl true
  def match?(actor, %{changeset: changeset}, _opts) do
    with %{id: actor_id} <- actor,
         organization_id when not is_nil(organization_id) <-
           Ash.Changeset.get_argument(changeset, :organization_id) do
      check_permissions(actor_id, organization_id)
    else
      _ -> false
    end
  end

  def match?(_actor, _context, _opts), do: false

  defp check_permissions(actor_id, organization_id) do
    case Ash.get(EBoss.Organizations.Organization, organization_id,
           domain: EBoss.Organizations,
           authorize?: false
         ) do
      {:ok, %{owner_id: ^actor_id}} ->
        true

      {:ok, _organization} ->
        check_admin_membership(actor_id, organization_id)

      _ ->
        false
    end
  end

  defp check_admin_membership(actor_id, organization_id) do
    EBoss.Organizations.Membership
    |> Ash.Query.filter(
      user_id == ^actor_id and organization_id == ^organization_id and role == :admin
    )
    |> Ash.read_one(domain: EBoss.Organizations, authorize?: false)
    |> case do
      {:ok, %{}} -> true
      _ -> false
    end
  end
end
