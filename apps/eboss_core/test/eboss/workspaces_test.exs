defmodule EBoss.WorkspacesTest do
  use EBoss.DataCase, async: false

  test "user-owned workspaces get unique slugs and calculated paths" do
    owner = register_user()

    first_workspace =
      create_workspace(owner, %{
        name: "Studio Space",
        owner_type: :user,
        owner_id: owner.id
      })

    second_workspace =
      create_workspace(owner, %{
        name: "Studio Space",
        owner_type: :user,
        owner_id: owner.id
      })

    assert first_workspace.slug == "studio-space"
    assert second_workspace.slug == "studio-space-1"

    loaded_workspace =
      Ash.load!(first_workspace, [:full_path, :owner], authorize?: false)

    assert loaded_workspace.full_path == "@#{owner.username}/studio-space"
    assert loaded_workspace.owner.username == owner.username
  end

  test "organization workspaces are readable by members and reject workspace memberships" do
    owner = register_user()
    member = register_user()
    outsider = register_user()
    organization = create_organization(owner, %{name: "Workspace Org"})

    _membership =
      EBoss.Organizations.Membership
      |> Ash.Changeset.for_create(
        :create,
        %{
          user_id: member.id,
          organization_id: organization.id,
          role: :member
        },
        actor: owner
      )
      |> Ash.create!()

    workspace =
      create_workspace(owner, %{
        name: "Ops",
        owner_type: :organization,
        owner_id: organization.id
      })

    member_read =
      EBoss.Workspaces.Workspace
      |> Ash.Query.for_read(:for_owner, %{owner_type: :organization, owner_id: organization.id})
      |> Ash.read!(actor: member)

    outsider_read =
      EBoss.Workspaces.Workspace
      |> Ash.Query.for_read(:for_owner, %{owner_type: :organization, owner_id: organization.id})
      |> Ash.read!(actor: outsider)

    assert Enum.map(member_read, & &1.id) == [workspace.id]
    assert outsider_read == []

    assert {:error, error} =
             EBoss.Workspaces.WorkspaceMembership
             |> Ash.Changeset.for_create(
               :create,
               %{
                 workspace_id: workspace.id,
                 user_id: member.id,
                 role: :member
               },
               actor: owner
             )
             |> Ash.create()

    assert Exception.message(error) =~
             "Organization-owned workspaces use organization memberships"
  end

  test "organization owners can read org-owned workspaces without an explicit admin membership" do
    owner = register_user()
    organization = create_organization(owner, %{name: "Owner Read Org"})

    workspace =
      create_workspace(owner, %{
        name: "Leadership",
        owner_type: :organization,
        owner_id: organization.id
      })

    visible_workspaces =
      EBoss.Workspaces.Workspace
      |> Ash.Query.for_read(:for_owner, %{owner_type: :organization, owner_id: organization.id})
      |> Ash.read!(actor: owner)

    assert Enum.map(visible_workspaces, & &1.id) == [workspace.id]
  end

  defp register_user(overrides \\ %{}) do
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

  defp create_organization(actor, attrs) do
    EBoss.Organizations.Organization
    |> Ash.Changeset.for_create(:create, attrs, actor: actor)
    |> Ash.create!()
  end

  defp create_workspace(actor, attrs) do
    EBoss.Workspaces.Workspace
    |> Ash.Changeset.for_create(:create, attrs, actor: actor)
    |> Ash.create!()
  end
end
