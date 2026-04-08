defmodule EBoss.Organizations.Membership.Changes.ProtectOwnerMembership do
  @moduledoc """
  Prevents public actions from mutating the system-managed owner membership row.
  """

  use Ash.Resource.Change

  alias EBoss.Organizations.Membership

  @impl true
  def change(changeset, _opts, _context) do
    if owner_membership?(changeset) do
      Ash.Changeset.add_error(
        changeset,
        field: :role,
        message: "owner membership is system-managed; transfer organization ownership instead"
      )
    else
      changeset
    end
  end

  defp owner_membership?(changeset) do
    domain = changeset.domain || EBoss.Organizations

    case changeset.data do
      %{id: id, role: role} when is_nil(id) ->
        role == :owner

      %{id: id, role: role} ->
        case Ash.get(Membership, id, domain: domain, authorize?: false) do
          {:ok, membership} -> membership.role == :owner
          _ -> role == :owner
        end

      %{role: role} ->
        role == :owner

      _ ->
        false
    end
  end
end
