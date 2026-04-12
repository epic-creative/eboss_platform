defmodule EBoss.Organizations.Authorization do
  @moduledoc false

  require Ash.Query

  alias EBoss.Organizations.{Membership, Organization}

  def owner_or_admin?(actor_id, organization_id, opts \\ []) do
    owner?(actor_id, organization_id, opts) or admin?(actor_id, organization_id, opts)
  end

  def owner?(actor_id, organization_id, opts \\ []) do
    domain = Keyword.get(opts, :domain) || EBoss.Organizations

    with true <- present?(actor_id),
         true <- present?(organization_id),
         {:ok, %{owner_id: ^actor_id}} <-
           Ash.get(Organization, organization_id, domain: domain, authorize?: false) do
      true
    else
      _ -> false
    end
  end

  def admin?(actor_id, organization_id, opts \\ []) do
    domain = Keyword.get(opts, :domain) || EBoss.Organizations

    with true <- present?(actor_id),
         true <- present?(organization_id) do
      Membership
      |> Ash.Query.filter(
        user_id == ^actor_id and organization_id == ^organization_id and role == :admin
      )
      |> Ash.read_one(domain: domain, authorize?: false)
      |> case do
        {:ok, %{}} -> true
        _ -> false
      end
    else
      _ -> false
    end
  end

  def roles_by_organization_ids(actor_id, organization_ids, opts \\ []) do
    domain = Keyword.get(opts, :domain) || EBoss.Organizations

    organization_ids =
      organization_ids
      |> List.wrap()
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    with true <- present?(actor_id),
         false <- Enum.empty?(organization_ids) do
      owner_ids = owner_organization_ids(actor_id, organization_ids, domain)
      membership_roles = membership_roles_by_organization_id(actor_id, organization_ids, domain)

      Enum.reduce(organization_ids, %{}, fn organization_id, acc ->
        role =
          cond do
            MapSet.member?(owner_ids, organization_id) -> :owner
            true -> Map.get(membership_roles, organization_id, :none)
          end

        Map.put(acc, organization_id, role)
      end)
    else
      _ -> %{}
    end
  end

  defp present?(value), do: not is_nil(value)

  defp owner_organization_ids(actor_id, organization_ids, domain) do
    Organization
    |> Ash.Query.filter(id in ^organization_ids and owner_id == ^actor_id)
    |> Ash.read(domain: domain, authorize?: false)
    |> case do
      {:ok, organizations} -> organizations |> Enum.map(& &1.id) |> MapSet.new()
      _ -> MapSet.new()
    end
  end

  defp membership_roles_by_organization_id(actor_id, organization_ids, domain) do
    Membership
    |> Ash.Query.filter(user_id == ^actor_id and organization_id in ^organization_ids)
    |> Ash.read(domain: domain, authorize?: false)
    |> case do
      {:ok, memberships} ->
        Enum.reduce(memberships, %{}, fn membership, acc ->
          Map.update(
            acc,
            membership.organization_id,
            membership.role,
            &higher_role(&1, membership.role)
          )
        end)

      _ ->
        %{}
    end
  end

  defp higher_role(:owner, _), do: :owner
  defp higher_role(_, :owner), do: :owner
  defp higher_role(:admin, _), do: :admin
  defp higher_role(_, :admin), do: :admin
  defp higher_role(current, _), do: current
end
