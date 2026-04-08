defmodule EBoss.Workspaces.Workspace.Checks.CanCreateWorkspace do
  use Ash.Policy.SimpleCheck

  require Ash.Query

  def describe(_opts), do: "user can create workspace for themselves or organizations they admin"

  def match?(nil, _context, _opts), do: false

  def match?(actor, %{changeset: changeset}, _opts) do
    owner_type = Ash.Changeset.get_argument(changeset, :owner_type)
    owner_id = Ash.Changeset.get_argument(changeset, :owner_id)

    case owner_type do
      :user ->
        owner_id == actor.id

      :organization ->
        case Ash.get(EBoss.Organizations.Organization, owner_id,
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
                  organization_id == ^owner_id and
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

      _ ->
        false
    end
  end

  def match?(_, _, _), do: false
end
