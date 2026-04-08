defmodule EBoss.Organizations do
  use Ash.Domain, otp_app: :eboss_tenancy

  resources do
    resource(EBoss.Organizations.Organization)
    resource(EBoss.Organizations.Membership)
    resource(EBoss.Organizations.Invitation)
  end

  alias EBoss.Organizations.Organization
  alias EBoss.Organizations.Authorization

  defdelegate owner?(actor_id, organization_id, opts \\ []), to: Authorization
  defdelegate admin?(actor_id, organization_id, opts \\ []), to: Authorization
  defdelegate owner_or_admin?(actor_id, organization_id, opts \\ []), to: Authorization

  def create_organization(attrs, opts \\ []) do
    Organization
    |> Ash.Changeset.for_create(:create, attrs, action_opts(opts))
    |> Ash.create(default_opts(opts))
  end

  def create_organization!(attrs, opts \\ []) do
    case create_organization(attrs, opts) do
      {:ok, organization} -> organization
      {:error, error} -> raise error
    end
  end

  def update_organization(organization, attrs, opts \\ []) do
    organization
    |> Ash.Changeset.for_update(:update, attrs, action_opts(opts))
    |> Ash.update(default_opts(opts))
  end

  def update_organization!(organization, attrs, opts \\ []) do
    case update_organization(organization, attrs, opts) do
      {:ok, updated_organization} -> updated_organization
      {:error, error} -> raise error
    end
  end

  def admin_update_organization(organization, attrs, opts \\ []) do
    organization
    |> Ash.Changeset.for_update(:admin_update, attrs, action_opts(opts))
    |> Ash.update(default_opts(opts))
  end

  def admin_update_organization!(organization, attrs, opts \\ []) do
    case admin_update_organization(organization, attrs, opts) do
      {:ok, updated_organization} -> updated_organization
      {:error, error} -> raise error
    end
  end

  def transfer_organization_ownership(organization, new_owner_id, opts \\ []) do
    organization
    |> Ash.Changeset.for_update(
      :transfer_ownership,
      %{new_owner_id: new_owner_id},
      action_opts(opts)
    )
    |> Ash.update(default_opts(opts))
  end

  def transfer_organization_ownership!(organization, new_owner_id, opts \\ []) do
    case transfer_organization_ownership(organization, new_owner_id, opts) do
      {:ok, updated_organization} -> updated_organization
      {:error, error} -> raise error
    end
  end

  def destroy_organization(organization, opts \\ []) do
    organization
    |> Ash.Changeset.for_destroy(:destroy, %{}, action_opts(opts))
    |> Ash.destroy(default_opts(opts))
  end

  def destroy_organization!(organization, opts \\ []) do
    case destroy_organization(organization, opts) do
      {:ok, destroyed_organization} -> destroyed_organization
      :ok -> :ok
      {:error, error} -> raise error
    end
  end

  def get_organization(id, opts \\ []) do
    Ash.get(Organization, id, default_opts(opts))
  end

  def get_organization!(id, opts \\ []) do
    Ash.get!(Organization, id, default_opts(opts))
  end

  defp default_opts(opts), do: Keyword.put_new(opts, :domain, __MODULE__)

  defp action_opts(opts) do
    opts
    |> Keyword.take([:actor, :tenant, :tracer, :authorize?, :scope, :context])
  end
end
