defmodule EBossFolio.TestSupport do
  @moduledoc false

  alias EBoss.Workspaces.Workspace

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

    EBoss.Accounts.User
    |> Ash.Changeset.for_create(:register_with_password, params)
    |> Ash.Changeset.set_context(%{private: %{ash_authentication?: true}})
    |> Ash.create!(authorize?: false)
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

    Workspace
    |> Ash.Changeset.for_create(:create, workspace_attrs, actor: owner)
    |> Ash.create!()
  end

  def create_organization(owner, attrs \\ %{}) do
    organization_attrs =
      Map.merge(
        %{name: "Organization #{System.unique_integer([:positive])}"},
        attrs
      )

    EBoss.Organizations.Organization
    |> Ash.Changeset.for_create(:create, organization_attrs, actor: owner)
    |> Ash.create!()
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
