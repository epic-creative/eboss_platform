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

  defp present?(value), do: not is_nil(value)
end
