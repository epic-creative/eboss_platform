defmodule EBoss.WorkspacesBoundaryTest do
  use EBoss.DataCase, async: false

  alias EBoss.Accounts
  alias EBoss.Organizations
  alias EBoss.Workspaces

  @moduletag :boundary

  test "user workspace lifecycle goes through the workspaces boundary" do
    owner = register_user()
    member = register_user()

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Studio Space",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    fetched_workspace =
      Workspaces.get_workspace!(workspace.id, actor: owner, load: [:full_path, :owner])

    looked_up_workspace =
      Workspaces.get_workspace_by_owner_and_slug!(:user, owner.id, workspace.slug, actor: owner)

    visible_workspaces = Workspaces.list_workspaces_for_owner!(:user, owner.id, actor: owner)

    assert fetched_workspace.full_path == "#{owner.owner_slug}/studio-space"
    assert fetched_workspace.owner.slug == owner.owner_slug
    assert looked_up_workspace.id == workspace.id
    assert Enum.map(visible_workspaces, & &1.id) == [workspace.id]

    membership =
      Workspaces.create_workspace_membership!(
        %{
          workspace_id: workspace.id,
          user_id: member.id,
          role: :member
        },
        actor: owner
      )

    updated_workspace =
      Workspaces.update_workspace!(
        workspace,
        %{settings: %{theme: "focus"}},
        actor: owner
      )

    assert updated_workspace.settings == %{theme: "focus"}

    Workspaces.destroy_workspace!(updated_workspace, actor: owner)

    assert workspace_archived?(workspace.id)
    assert archived_membership?(membership.id)
    assert Workspaces.list_workspaces_for_owner!(:user, owner.id, actor: owner) == []
  end

  test "organization workspace access and membership validation go through the workspaces boundary" do
    owner = register_user()
    org_member = register_user()
    outsider = register_user()

    organization = Organizations.create_organization!(%{name: "Workspace Org"}, actor: owner)
    _membership = create_org_membership(owner, organization, org_member, :member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Ops",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    loaded_workspace =
      Workspaces.get_workspace!(workspace.id, actor: owner, load: [:full_path, :owner])

    member_visible =
      Workspaces.list_workspaces_for_owner!(:organization, organization.id, actor: org_member)

    outsider_visible =
      Workspaces.list_workspaces_for_owner!(:organization, organization.id, actor: outsider)

    looked_up_workspace =
      Workspaces.get_workspace_by_owner_and_slug!(
        :organization,
        organization.id,
        workspace.slug,
        actor: owner
      )

    assert loaded_workspace.full_path == "#{organization.owner_slug}/ops"
    assert loaded_workspace.owner.slug == organization.owner_slug
    assert Enum.map(member_visible, & &1.id) == [workspace.id]
    assert outsider_visible == []
    assert looked_up_workspace.id == workspace.id

    assert {:error, error} =
             Workspaces.create_workspace_membership(
               %{
                 workspace_id: workspace.id,
                 user_id: org_member.id,
                 role: :member
               },
               actor: owner
             )

    assert Exception.message(error) =~
             "Organization-owned workspaces use organization memberships"
  end

  test "non-bang workspace boundary functions return expected tuples" do
    owner = register_user()
    member = register_user()

    organization =
      Organizations.create_organization!(%{name: "Boundary Workspace Org"}, actor: owner)

    assert {:ok, user_workspace} =
             Workspaces.create_workspace(
               %{
                 name: "Research",
                 owner_type: :user,
                 owner_id: owner.id
               },
               actor: owner
             )

    assert {:ok, same_user_workspace} =
             Workspaces.get_workspace(user_workspace.id, actor: owner, load: [:full_path])

    assert same_user_workspace.full_path == "#{owner.owner_slug}/research"

    assert {:ok, found_user_workspace} =
             Workspaces.get_workspace_by_owner_and_slug(
               :user,
               owner.id,
               user_workspace.slug,
               actor: owner
             )

    assert found_user_workspace.id == user_workspace.id

    assert {:ok, visible_user_workspaces} =
             Workspaces.list_workspaces_for_owner(:user, owner.id, actor: owner)

    assert Enum.any?(visible_user_workspaces, &(&1.id == user_workspace.id))

    assert {:ok, membership} =
             Workspaces.create_workspace_membership(
               %{
                 workspace_id: user_workspace.id,
                 user_id: member.id,
                 role: :member
               },
               actor: owner
             )

    assert membership.workspace_id == user_workspace.id

    assert {:ok, updated_user_workspace} =
             Workspaces.update_workspace(
               user_workspace,
               %{settings: %{mode: "deep-work"}},
               actor: owner
             )

    assert updated_user_workspace.settings == %{mode: "deep-work"}

    assert :ok = Workspaces.destroy_workspace(updated_user_workspace, actor: owner)

    assert {:ok, org_workspace} =
             Workspaces.create_workspace(
               %{
                 name: "Operations",
                 owner_type: :organization,
                 owner_id: organization.id
               },
               actor: owner
             )

    assert {:ok, same_org_workspace} =
             Workspaces.get_workspace(org_workspace.id, actor: owner, load: [:full_path, :owner])

    assert same_org_workspace.full_path == "#{organization.owner_slug}/operations"
    assert same_org_workspace.owner.slug == organization.owner_slug

    assert {:ok, found_org_workspace} =
             Workspaces.get_workspace_by_owner_and_slug(
               :organization,
               organization.id,
               org_workspace.slug,
               actor: owner
             )

    assert found_org_workspace.id == org_workspace.id

    assert {:ok, org_visible_workspaces} =
             Workspaces.list_workspaces_for_owner(:organization, organization.id, actor: owner)

    assert Enum.any?(org_visible_workspaces, &(&1.id == org_workspace.id))
  end

  test "default-argument workspace wrappers are exercised" do
    owner = register_user()
    member = register_user()

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Defaults Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    assert {:error, _error} =
             Workspaces.create_workspace(%{
               name: "Forbidden Workspace",
               owner_type: :user,
               owner_id: owner.id
             })

    assert_raise Ash.Error.Forbidden, fn ->
      Workspaces.create_workspace!(%{
        name: "Forbidden Workspace Bang",
        owner_type: :user,
        owner_id: owner.id
      })
    end

    assert {:error, _error} =
             Workspaces.update_workspace(workspace, %{settings: %{mode: "forbidden"}})

    assert_raise Ash.Error.Forbidden, fn ->
      Workspaces.update_workspace!(workspace, %{settings: %{mode: "forbidden bang"}})
    end

    assert {:error, _error} = Workspaces.destroy_workspace(workspace)

    assert_raise Ash.Error.Forbidden, fn ->
      Workspaces.destroy_workspace!(workspace)
    end

    assert {:error, _error} = Workspaces.get_workspace(workspace.id)

    assert_raise Ash.Error.Invalid, fn ->
      Workspaces.get_workspace!(workspace.id)
    end

    assert {:ok, nil} =
             Workspaces.get_workspace_by_owner_and_slug(:user, owner.id, workspace.slug)

    assert nil == Workspaces.get_workspace_by_owner_and_slug!(:user, owner.id, workspace.slug)

    assert {:ok, []} = Workspaces.list_workspaces_for_owner(:user, owner.id)

    assert [] == Workspaces.list_workspaces_for_owner!(:user, owner.id)

    assert {:error, _error} =
             Workspaces.create_workspace_membership(%{
               workspace_id: workspace.id,
               user_id: member.id,
               role: :member
             })

    assert_raise Ash.Error.Forbidden, fn ->
      Workspaces.create_workspace_membership!(%{
        workspace_id: workspace.id,
        user_id: member.id,
        role: :member
      })
    end
  end

  test "workspace route resolution distinguishes accessible, forbidden, missing, and unauthorized" do
    owner = register_user()
    outsider = register_user()

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Route Resolution Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    accessible_summary = %{
      owner_type: :user,
      owner_slug: owner.owner_slug,
      slug: workspace.slug,
      id: workspace.id
    }

    assert {:ok, ^accessible_summary} =
             Workspaces.resolve_workspace_route(
               owner,
               owner.owner_slug,
               workspace.slug,
               [accessible_summary]
             )

    assert {:error, :forbidden} =
             Workspaces.resolve_workspace_route(outsider, owner.owner_slug, workspace.slug)

    assert {:error, :not_found} =
             Workspaces.resolve_workspace_route(owner, owner.owner_slug, "missing-workspace")

    assert {:error, :unauthorized} =
             Workspaces.resolve_workspace_route(nil, owner.owner_slug, workspace.slug)
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

  defp create_org_membership(actor, organization, user, role) do
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

  defp unique_email do
    "user#{System.unique_integer([:positive])}@example.com"
  end

  defp password, do: "supersecret123"

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
