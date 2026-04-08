defmodule EBoss.Workspaces.Workspace.Checks.IsOrgAdmin do
  use Ash.Policy.SimpleCheck

  alias EBoss.Organizations

  def describe(_opts), do: "user is the owner or an admin of the workspace's organization"

  def match?(actor, %{changeset: %{data: workspace}}, _opts)
      when workspace.owner_type == :organization do
    check_org_admin(actor, workspace.owner_id)
  end

  def match?(actor, %{resource: workspace}, _opts) when workspace.owner_type == :organization do
    check_org_admin(actor, workspace.owner_id)
  end

  def match?(_, _, _), do: false

  defp check_org_admin(actor, organization_id) when not is_nil(actor) do
    Organizations.owner_or_admin?(actor.id, organization_id)
  end

  defp check_org_admin(_, _), do: false
end
