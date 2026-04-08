defmodule EBoss.Workspaces.Workspace.Checks.IsOrgAdmin do
  use Ash.Policy.SimpleCheck

  require Ash.Query

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
    case Ash.get(EBoss.Organizations.Organization, organization_id,
           domain: EBoss.Organizations,
           authorize?: false
         ) do
      {:ok, organization} ->
        if organization.owner_id == actor.id do
          true
        else
          query =
            EBoss.Organizations.Membership
            |> Ash.Query.filter(
              organization_id == ^organization_id and
                user_id == ^actor.id and role == :admin
            )
            |> Ash.Query.limit(1)

          case Ash.read(query, domain: EBoss.Organizations, authorize?: false) do
            {:ok, [_membership]} -> true
            _ -> false
          end
        end

      _ ->
        false
    end
  end

  defp check_org_admin(_, _), do: false
end
