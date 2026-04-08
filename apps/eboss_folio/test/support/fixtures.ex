defmodule EBossFolio.TestSupport do
  @moduledoc false

  def register_user(overrides \\ %{}) do
    params =
      Map.merge(
        %{
          email: "user#{System.unique_integer([:positive])}@example.com",
          username: "user#{System.unique_integer([:positive])}",
          password: "supersecret123",
          password_confirmation: "supersecret123"
        },
        overrides
      )

    EBoss.Accounts.register_with_password!(params, authorize?: false)
  end

  def create_user_workspace(owner, attrs \\ %{}) do
    workspace_attrs =
      Map.merge(
        %{
          name: "Workspace #{System.unique_integer([:positive])}",
          owner_type: :user,
          owner_id: owner.id
        },
        attrs
      )

    EBoss.Workspaces.create_workspace!(workspace_attrs, actor: owner)
  end

  def create_organization(owner, attrs \\ %{}) do
    organization_attrs =
      Map.merge(
        %{name: "Organization #{System.unique_integer([:positive])}"},
        attrs
      )

    EBoss.Organizations.create_organization!(organization_attrs, actor: owner)
  end

  def create_org_workspace(owner, attrs \\ %{}) do
    organization = create_organization(owner)

    workspace =
      create_user_workspace(owner, %{
        name: Map.get(attrs, :name, "Org Workspace #{System.unique_integer([:positive])}"),
        owner_type: :organization,
        owner_id: organization.id
      })

    {organization, workspace}
  end

  def add_org_member(owner, organization, member, role \\ :member) do
    EBoss.Organizations.Membership
    |> Ash.Changeset.for_create(
      :create,
      %{user_id: member.id, organization_id: organization.id, role: role},
      actor: owner
    )
    |> Ash.create!()
  end

  def audit_context(overrides \\ %{}) do
    %{private: %{folio_audit: Map.merge(%{source: :internal}, overrides)}}
  end
end
