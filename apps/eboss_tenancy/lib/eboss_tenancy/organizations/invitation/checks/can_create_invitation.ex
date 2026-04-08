defmodule EBoss.Organizations.Invitation.Checks.CanCreateInvitation do
  use Ash.Policy.SimpleCheck

  alias EBoss.Organizations

  @impl true
  def describe(_), do: "actor can create invitations for the organization"

  @impl true
  def match?(actor, %{changeset: changeset}, _opts) do
    with %{id: actor_id} <- actor,
         organization_id when not is_nil(organization_id) <-
           Ash.Changeset.get_argument(changeset, :organization_id) do
      Organizations.owner_or_admin?(actor_id, organization_id, domain: changeset.domain)
    else
      _ -> false
    end
  end

  def match?(_actor, _context, _opts), do: false
end
