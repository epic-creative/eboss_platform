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

    loaded_workspace = read_workspace!(first_workspace.id, owner, [:full_path, :owner])

    assert first_workspace.owner_handle == owner.username
    assert first_workspace.owner_display_name == owner.username
    assert loaded_workspace.full_path == "@#{owner.username}/studio-space"

    assert loaded_workspace.owner == %{
             type: :user,
             id: owner.id,
             handle: owner.username,
             display_name: owner.username
           }

    refute Map.has_key?(loaded_workspace.owner, :email)
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

    loaded_workspace = read_workspace!(workspace.id, owner, [:full_path, :owner])

    assert workspace.owner_handle == organization.slug
    assert workspace.owner_display_name == organization.name
    assert loaded_workspace.full_path == "#{organization.slug}/ops"

    assert loaded_workspace.owner == %{
             type: :organization,
             id: organization.id,
             handle: organization.slug,
             display_name: organization.name
           }

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

  test "invalid owners fail with a focused owner error" do
    owner = register_user()

    assert {:error, error} =
             EBoss.Workspaces.Workspace
             |> Ash.Changeset.for_create(
               :create,
               %{
                 name: "Broken",
                 owner_type: :organization,
                 owner_id: Ecto.UUID.generate()
               },
               actor: owner
             )
             |> Ash.create()

    message = Exception.message(error)

    assert message =~ "Organization not found"
    refute message =~ "owner_handle"
    refute message =~ "owner_display_name"
  end

  test "workspaces encrypt settings and archive related memberships on destroy" do
    owner = register_user()
    member = register_user()

    workspace =
      create_workspace(owner, %{
        name: "Private Studio",
        owner_type: :user,
        owner_id: owner.id
      })

    updated_workspace =
      workspace
      |> Ash.Changeset.for_update(
        :update,
        %{settings: %{theme: "focus"}},
        actor: owner
      )
      |> Ash.update!()

    membership =
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
      |> Ash.create!()

    assert updated_workspace.settings == %{theme: "focus"}

    updated_workspace
    |> Ash.Changeset.for_destroy(:destroy, %{}, actor: owner)
    |> Ash.destroy!()

    assert workspace_archived?(workspace.id)
    assert archived_membership?(membership.id)

    visible_workspaces =
      EBoss.Workspaces.Workspace
      |> Ash.Query.for_read(:for_owner, %{owner_type: :user, owner_id: owner.id})
      |> Ash.read!(actor: owner)

    assert visible_workspaces == []
  end

  test "username changes sync active user-owned workspace owner snapshots" do
    admin = register_user() |> promote_to_admin()
    owner = register_user()

    workspace =
      create_workspace(owner, %{
        name: "Studio Space",
        owner_type: :user,
        owner_id: owner.id
      })

    renamed_owner =
      owner
      |> Ash.Changeset.for_update(
        :admin_update,
        %{username: "renamed-owner"},
        actor: admin
      )
      |> Ash.update!()

    loaded_workspace = read_workspace!(workspace.id, renamed_owner, [:full_path, :owner])

    assert loaded_workspace.owner_handle == "renamed-owner"
    assert loaded_workspace.owner_display_name == "renamed-owner"
    assert loaded_workspace.full_path == "@renamed-owner/studio-space"

    assert loaded_workspace.owner == %{
             type: :user,
             id: owner.id,
             handle: "renamed-owner",
             display_name: "renamed-owner"
           }
  end

  test "organization name changes sync active organization-owned workspace owner snapshots" do
    owner = register_user()
    organization = create_organization(owner, %{name: "Workspace Org"})

    workspace =
      create_workspace(owner, %{
        name: "Ops",
        owner_type: :organization,
        owner_id: organization.id
      })

    renamed_organization =
      organization
      |> Ash.Changeset.for_update(:update, %{name: "Platform Ops"}, actor: owner)
      |> Ash.update!()

    loaded_workspace = read_workspace!(workspace.id, owner, [:full_path, :owner])

    assert loaded_workspace.owner_handle == renamed_organization.slug
    assert loaded_workspace.owner_display_name == "Platform Ops"
    assert loaded_workspace.full_path == "#{renamed_organization.slug}/ops"

    assert loaded_workspace.owner == %{
             type: :organization,
             id: organization.id,
             handle: renamed_organization.slug,
             display_name: "Platform Ops"
           }
  end

  test "workspace owner calculations use local snapshot fields instead of live owner lookups" do
    owner = register_user(%{username: "alphaowner"})

    workspace =
      create_workspace(owner, %{
        name: "Studio Space",
        owner_type: :user,
        owner_id: owner.id
      })

    workspace_id = Ecto.UUID.dump!(workspace.id)

    from(workspace_row in "workspaces", where: workspace_row.id == ^workspace_id)
    |> Repo.update_all(
      set: [
        owner_handle: "cached-owner",
        owner_display_name: "Cached Owner"
      ]
    )

    loaded_workspace = read_workspace!(workspace.id, owner, [:full_path, :owner])

    assert loaded_workspace.full_path == "@cached-owner/studio-space"

    assert loaded_workspace.owner == %{
             type: :user,
             id: owner.id,
             handle: "cached-owner",
             display_name: "Cached Owner"
           }
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

  defp promote_to_admin(user) do
    user
    |> Ash.Changeset.for_update(:update, %{role: :admin})
    |> Ash.update!(authorize?: false)
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

  defp read_workspace!(workspace_id, actor, loads) do
    Ash.get!(EBoss.Workspaces.Workspace, workspace_id,
      domain: EBoss.Workspaces,
      actor: actor,
      load: loads
    )
  end

  defp workspace_archived?(id) do
    id = Ecto.UUID.dump!(id)

    [[archived_at, encrypted_settings]] =
      Ecto.Adapters.SQL.query!(
        Repo,
        "SELECT archived_at, encrypted_settings FROM workspaces WHERE id = $1",
        [id]
      ).rows

    not is_nil(archived_at) and is_binary(encrypted_settings)
  end

  defp archived_membership?(id) do
    id = Ecto.UUID.dump!(id)

    [[archived_at]] =
      Ecto.Adapters.SQL.query!(
        Repo,
        "SELECT archived_at FROM workspace_memberships WHERE id = $1",
        [id]
      ).rows

    not is_nil(archived_at)
  end
end
