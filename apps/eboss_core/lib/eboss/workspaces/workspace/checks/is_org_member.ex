defmodule EBoss.Workspaces.Workspace.Checks.IsOrgMember do
  use Ash.Policy.FilterCheck

  @impl true
  def describe(_), do: "actor is member of organization that owns workspace"

  @impl true
  def filter(nil, _context, _opts), do: false

  def filter(_actor, _context, _opts) do
    import Ash.Expr

    expr(
      owner_type == :organization and
        exists(organization_memberships, user_id == ^actor(:id))
    )
  end
end
