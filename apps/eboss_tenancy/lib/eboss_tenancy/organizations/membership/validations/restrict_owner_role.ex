defmodule EBoss.Organizations.Membership.Validations.RestrictOwnerRole do
  @moduledoc """
  Keeps organization ownership single-sourced in `organizations.owner_id`.
  """

  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts, _context) do
    role = Ash.Changeset.get_attribute(changeset, :role)

    if role == :owner do
      {:error,
       field: :role,
       message: "owner role is system-managed; transfer organization ownership instead"}
    else
      :ok
    end
  end
end
