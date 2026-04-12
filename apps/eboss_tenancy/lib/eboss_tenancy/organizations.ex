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
  defdelegate create_organization(attrs, opts \\ []), to: Organization
  defdelegate create_organization!(attrs, opts \\ []), to: Organization
  defdelegate update_organization(organization, attrs, opts \\ []), to: Organization
  defdelegate update_organization!(organization, attrs, opts \\ []), to: Organization
  defdelegate admin_update_organization(organization, attrs, opts \\ []), to: Organization
  defdelegate admin_update_organization!(organization, attrs, opts \\ []), to: Organization

  defdelegate transfer_organization_ownership(organization, new_owner_id, opts \\ []),
    to: Organization

  defdelegate transfer_organization_ownership!(organization, new_owner_id, opts \\ []),
    to: Organization

  defdelegate destroy_organization(organization, opts \\ []), to: Organization
  defdelegate destroy_organization!(organization, opts \\ []), to: Organization
  defdelegate get_organization(id, opts \\ []), to: Organization
  defdelegate get_organization!(id, opts \\ []), to: Organization
end
