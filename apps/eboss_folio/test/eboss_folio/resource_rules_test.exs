defmodule EBossFolio.ResourceRulesTest do
  use EBoss.DataCase, async: false

  alias EBossFolio.TestSupport

  test "workspace uniqueness rules are enforced for names and contact emails" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    other_workspace = TestSupport.create_user_workspace(owner)

    _area = EBossFolio.create_area!(%{workspace_id: workspace.id, name: "Home"}, actor: owner)

    _context =
      EBossFolio.create_context!(%{workspace_id: workspace.id, name: "Computer"}, actor: owner)

    _horizon =
      EBossFolio.create_horizon!(%{workspace_id: workspace.id, name: "1 Year", level: 1},
        actor: owner
      )

    _contact =
      EBossFolio.create_contact!(
        %{workspace_id: workspace.id, name: "Alex", email: "alex@example.com"},
        actor: owner
      )

    assert {:error, area_error} =
             EBossFolio.create_area(%{workspace_id: workspace.id, name: "Home"}, actor: owner)

    assert {:error, context_error} =
             EBossFolio.create_context(%{workspace_id: workspace.id, name: "Computer"},
               actor: owner
             )

    assert {:error, horizon_error} =
             EBossFolio.create_horizon(
               %{workspace_id: workspace.id, name: "1 Year", level: 2},
               actor: owner
             )

    assert {:error, contact_error} =
             EBossFolio.create_contact(
               %{workspace_id: workspace.id, name: "Alex Two", email: "alex@example.com"},
               actor: owner
             )

    assert Exception.message(area_error) =~ "has already been taken"
    assert Exception.message(context_error) =~ "has already been taken"
    assert Exception.message(horizon_error) =~ "has already been taken"
    assert Exception.message(contact_error) =~ "has already been taken"

    assert %{name: "Home"} =
             EBossFolio.create_area!(%{workspace_id: other_workspace.id, name: "Home"},
               actor: owner
             )
  end

  test "task and delegation relationships must stay inside the same workspace" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    other_workspace = TestSupport.create_user_workspace(owner)

    project =
      EBossFolio.create_project!(%{workspace_id: workspace.id, title: "Main Project"},
        actor: owner
      )

    other_area =
      EBossFolio.create_area!(%{workspace_id: other_workspace.id, name: "Foreign Area"},
        actor: owner
      )

    task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "Draft docs"}, actor: owner)

    foreign_contact =
      EBossFolio.create_contact!(
        %{workspace_id: other_workspace.id, name: "Remote Contact"},
        actor: owner
      )

    assert {:error, task_error} =
             EBossFolio.create_task(
               %{
                 workspace_id: workspace.id,
                 title: "Bad task",
                 project_id: project.id,
                 area_id: other_area.id
               },
               actor: owner
             )

    assert {:error, delegation_error} =
             EBossFolio.delegate_task(
               %{
                 workspace_id: workspace.id,
                 task_id: task.id,
                 contact_id: foreign_contact.id,
                 delegated_summary: "Need a cross-workspace delegation"
               },
               actor: owner
             )

    assert Exception.message(task_error) =~ "same workspace"
    assert Exception.message(delegation_error) =~ "same workspace"
  end

  test "org admins can access org-owned Folio while members and non-owners cannot" do
    owner = TestSupport.register_user()
    admin = TestSupport.register_user()
    member = TestSupport.register_user()
    {organization, workspace} = TestSupport.create_org_workspace(owner)
    _admin_membership = TestSupport.add_org_member(owner, organization, admin, :admin)
    _member_membership = TestSupport.add_org_member(owner, organization, member)

    area =
      EBossFolio.create_area!(%{workspace_id: workspace.id, name: "Owner Area"}, actor: owner)

    admin_area =
      EBossFolio.create_area!(%{workspace_id: workspace.id, name: "Admin Area"}, actor: admin)

    assert {:error, create_error} =
             EBossFolio.create_area(%{workspace_id: workspace.id, name: "Member Area"},
               actor: member
             )

    assert {:error, read_error} =
             Ash.get(EBossFolio.Area, area.id, domain: EBossFolio, actor: member)

    assert Ash.get!(EBossFolio.Area, area.id, domain: EBossFolio, actor: owner).id == area.id
    assert Ash.get!(EBossFolio.Area, area.id, domain: EBossFolio, actor: admin).id == area.id
    assert admin_area.workspace_id == workspace.id

    assert Exception.message(create_error) =~ "forbidden"
    assert Exception.message(read_error) =~ "not found"

    user_owned_workspace = TestSupport.create_user_workspace(owner)

    user_area =
      EBossFolio.create_area!(%{workspace_id: user_owned_workspace.id, name: "Private Area"},
        actor: owner
      )

    assert {:error, user_workspace_create_error} =
             EBossFolio.create_area(
               %{workspace_id: user_owned_workspace.id, name: "Admin Cannot Create"},
               actor: admin
             )

    assert {:error, user_workspace_read_error} =
             Ash.get(EBossFolio.Area, user_area.id, domain: EBossFolio, actor: admin)

    assert Exception.message(user_workspace_create_error) =~ "forbidden"
    assert Exception.message(user_workspace_read_error) =~ "not found"
  end
end
