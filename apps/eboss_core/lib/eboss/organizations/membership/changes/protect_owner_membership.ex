defmodule EBoss.Organizations.Membership.Changes.ProtectOwnerMembership do
  @moduledoc """
  Prevents public actions from mutating the system-managed owner membership row.
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    if changeset.data.role == :owner do
      Ash.Changeset.add_error(
        changeset,
        field: :role,
        message: "owner membership is system-managed; transfer organization ownership instead"
      )
    else
      changeset
    end
  end
end
