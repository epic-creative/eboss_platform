defmodule EBoss.OrganizationsBoundaryTest do
  use EBoss.DataCase, async: false

  import Ash.Expr
  require Ash.Query

  alias EBoss.Accounts
  alias EBoss.Organizations

  @moduletag :boundary

  test "organization lifecycle and authorization checks go through the organizations boundary" do
    owner = register_user()
    org_admin = register_user()
    platform_admin = register_user() |> promote_to_admin()

    organization =
      Organizations.create_organization!(
        %{name: "Acme Labs", settings: %{timezone: "UTC"}},
        actor: owner
      )

    _membership = create_membership(owner, organization, org_admin, :admin)

    assert organization.owner_slug == "acme-labs"
    assert organization.settings == %{timezone: "UTC"}
    assert Organizations.get_organization!(organization.id, actor: owner).id == organization.id

    assert Organizations.get_organization_by_owner_slug!("acme-labs", actor: owner).id ==
             organization.id

    updated_organization =
      Organizations.update_organization!(
        organization,
        %{name: "Acme Platform", description: "Core org"},
        actor: owner
      )

    assert updated_organization.owner_slug == "acme-labs"
    assert updated_organization.description == "Core org"

    admin_updated_organization =
      Organizations.admin_update_organization!(
        updated_organization,
        %{description: "Updated by platform admin"},
        actor: platform_admin
      )

    assert admin_updated_organization.description == "Updated by platform admin"
    assert Organizations.owner?(owner.id, organization.id)
    assert Organizations.admin?(org_admin.id, organization.id)
    assert Organizations.owner_or_admin?(org_admin.id, organization.id)
  end

  test "ownership transfer and destroy go through the organizations boundary" do
    owner = register_user()
    new_owner = register_user()
    member = register_user()

    organization =
      Organizations.create_organization!(
        %{name: "Boundary Destroy Org"},
        actor: owner
      )

    membership = create_membership(owner, organization, member, :member)
    invitation = create_invitation(owner, organization, "pending-boundary@example.com")

    transferred_organization =
      Organizations.transfer_organization_ownership!(organization, new_owner.id, actor: owner)

    assert transferred_organization.owner_id == new_owner.id
    assert membership_for!(organization.id, new_owner.id).role == :owner
    assert membership_for!(organization.id, owner.id).role == :member

    Organizations.destroy_organization!(transferred_organization, actor: new_owner)

    assert organization_archived?(organization.id)
    assert archived?(membership.id, "memberships")
    assert archived?(invitation.id, "invitations")

    visible_orgs =
      EBoss.Organizations.Organization
      |> Ash.Query.filter(expr(id == ^organization.id))
      |> Ash.read!(actor: new_owner)

    assert visible_orgs == []
  end

  test "non-bang organization boundary functions return expected tuples" do
    owner = register_user()
    org_admin = register_user()
    platform_admin = register_user() |> promote_to_admin()

    assert {:ok, organization} =
             Organizations.create_organization(
               %{name: "Boundary Org", description: "Created via non-bang"},
               actor: owner
             )

    _membership = create_membership(owner, organization, org_admin, :admin)

    assert {:ok, same_org} = Organizations.get_organization(organization.id, actor: owner)
    assert same_org.id == organization.id

    assert {:ok, updated_org} =
             Organizations.update_organization(
               organization,
               %{description: "Updated via non-bang"},
               actor: owner
             )

    assert updated_org.description == "Updated via non-bang"

    assert {:ok, admin_updated_org} =
             Organizations.admin_update_organization(
               updated_org,
               %{description: "Admin updated via non-bang"},
               actor: platform_admin
             )

    assert admin_updated_org.description == "Admin updated via non-bang"
    assert Organizations.owner?(owner.id, organization.id)
    assert Organizations.admin?(org_admin.id, organization.id)
    assert Organizations.owner_or_admin?(org_admin.id, organization.id)

    assert {:ok, transferred_org} =
             Organizations.transfer_organization_ownership(
               admin_updated_org,
               org_admin.id,
               actor: owner
             )

    assert transferred_org.owner_id == org_admin.id

    assert :ok = Organizations.destroy_organization(transferred_org, actor: org_admin)
  end

  test "default-argument organization wrappers are exercised" do
    owner = register_user()
    new_owner = register_user()
    platform_admin = register_user() |> promote_to_admin()

    organization = Organizations.create_organization!(%{name: "Defaults Org"}, actor: owner)

    assert {:error, _error} = Organizations.create_organization(%{name: "No Actor Org"})

    assert_raise Ash.Error.Invalid, fn ->
      Organizations.create_organization!(%{name: "No Actor Org Bang"})
    end

    assert {:error, _error} =
             Organizations.update_organization(organization, %{description: "forbidden update"})

    assert_raise Ash.Error.Forbidden, fn ->
      Organizations.update_organization!(organization, %{description: "forbidden bang update"})
    end

    assert {:error, _error} =
             Organizations.admin_update_organization(organization, %{description: "no admin"})

    assert_raise Ash.Error.Forbidden, fn ->
      Organizations.admin_update_organization!(organization, %{description: "no admin bang"})
    end

    assert {:error, _error} =
             Organizations.transfer_organization_ownership(organization, new_owner.id)

    assert_raise Ash.Error.Forbidden, fn ->
      Organizations.transfer_organization_ownership!(organization, new_owner.id)
    end

    assert {:error, _error} = Organizations.destroy_organization(organization)

    assert_raise Ash.Error.Forbidden, fn ->
      Organizations.destroy_organization!(organization)
    end

    assert {:error, _error} = Organizations.get_organization(organization.id)

    assert_raise Ash.Error.Forbidden, fn ->
      Organizations.get_organization!(organization.id)
    end

    assert {:ok, admin_updated_org} =
             Organizations.admin_update_organization(
               organization,
               %{description: "admin success"},
               actor: platform_admin
             )

    assert admin_updated_org.description == "admin success"
  end

  test "organization owner slugs remain immutable and global" do
    owner = register_user()
    user = register_user(%{username: "global-org-owner"})

    organization = Organizations.create_organization!(%{name: "Immutable Org"}, actor: owner)

    assert organization.owner_slug == "immutable-org"

    assert {:error, error} =
             Organizations.create_organization(%{name: "Global Org Owner"}, actor: user)

    assert Exception.message(error) =~ "has already been taken"
    assert invalid_attribute_fields(error) == [:owner_slug]

    assert {:ok, updated_organization} =
             Organizations.update_organization(organization, %{name: "Immutable Org Renamed"},
               actor: owner
             )

    assert updated_organization.owner_slug == "immutable-org"
  end

  defp register_user(overrides \\ %{}) do
    params =
      Map.merge(
        %{
          email: unique_email(),
          username: "user#{System.unique_integer([:positive])}",
          password: password(),
          password_confirmation: password()
        },
        overrides
      )

    Accounts.register_with_password!(params, authorize?: false)
  end

  defp invalid_attribute_fields(%Ash.Error.Invalid{errors: errors}) do
    errors
    |> Enum.flat_map(&invalid_attribute_fields/1)
    |> Enum.uniq()
  end

  defp invalid_attribute_fields(%Ash.Error.Changes.InvalidAttribute{field: field}), do: [field]
  defp invalid_attribute_fields(_error), do: []

  defp promote_to_admin(user) do
    user
    |> Ash.Changeset.for_update(:update, %{role: :admin})
    |> Ash.update!(authorize?: false)
  end

  defp create_membership(actor, organization, user, role) do
    EBoss.Organizations.Membership
    |> Ash.Changeset.for_create(
      :create,
      %{
        user_id: user.id,
        organization_id: organization.id,
        role: role
      },
      actor: actor
    )
    |> Ash.create!()
  end

  defp create_invitation(actor, organization, email) do
    EBoss.Organizations.Invitation
    |> Ash.Changeset.for_create(
      :create,
      %{
        email: email,
        role: :member,
        organization_id: organization.id,
        invited_by_id: actor.id
      },
      actor: actor
    )
    |> Ash.create!()
  end

  defp membership_for!(organization_id, user_id) do
    EBoss.Organizations.Membership
    |> Ash.Query.filter(expr(organization_id == ^organization_id and user_id == ^user_id))
    |> Ash.read_one!(authorize?: false)
  end

  defp unique_email do
    "user#{System.unique_integer([:positive])}@example.com"
  end

  defp password, do: "supersecret123"

  defp organization_archived?(id) do
    id = Ecto.UUID.dump!(id)

    [[archived_at, encrypted_settings]] =
      Ecto.Adapters.SQL.query!(
        Repo,
        "SELECT archived_at, encrypted_settings FROM organizations WHERE id = $1",
        [id]
      ).rows

    not is_nil(archived_at) and is_binary(encrypted_settings)
  end

  defp archived?(id, table) do
    id = Ecto.UUID.dump!(id)

    [[archived_at]] =
      Ecto.Adapters.SQL.query!(
        Repo,
        "SELECT archived_at FROM #{table} WHERE id = $1",
        [id]
      ).rows

    not is_nil(archived_at)
  end
end
