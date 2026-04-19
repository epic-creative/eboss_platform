defmodule EBossFolio.FolioBoundaryTest do
  use EBoss.DataCase, async: false

  alias EBoss.Folio
  alias EBossFolio.TestSupport

  @moduletag :boundary

  test "reference resource lifecycle methods go through the folio boundary" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)

    area =
      Folio.create_area!(%{workspace_id: workspace.id, name: "Home"}, actor: owner)
      |> then(&Folio.update_area!(&1, %{description: "Personal domain"}, actor: owner))
      |> then(&Folio.archive_area!(&1, actor: owner))

    context =
      Folio.create_context!(%{workspace_id: workspace.id, name: "Computer"}, actor: owner)
      |> then(&Folio.update_context!(&1, %{description: "Laptop work"}, actor: owner))
      |> then(&Folio.archive_context!(&1, actor: owner))

    horizon =
      Folio.create_horizon!(%{workspace_id: workspace.id, name: "1 Year", level: 1}, actor: owner)
      |> then(&Folio.update_horizon!(&1, %{description: "Annual focus"}, actor: owner))
      |> then(&Folio.archive_horizon!(&1, actor: owner))

    contact =
      Folio.create_contact!(
        %{workspace_id: workspace.id, name: "Taylor", email: "taylor@example.com"},
        actor: owner
      )
      |> then(
        &Folio.update_contact!(&1, %{capability_notes: "Reliable collaborator"}, actor: owner)
      )
      |> then(&Folio.archive_contact!(&1, actor: owner))

    assert area.status == :archived
    assert context.status == :archived
    assert horizon.status == :archived
    assert contact.status == :archived
    assert contact.capability_notes == "Reliable collaborator"
  end

  test "project, task, and delegation workflows go through the folio boundary" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)

    active_project =
      Folio.create_project!(%{workspace_id: workspace.id, title: "Release train"}, actor: owner)
      |> then(&Folio.update_project_details!(&1, %{description: "Q2 release"}, actor: owner))
      |> then(&Folio.reposition_project!(&1, %{priority_position: 2}, actor: owner))
      |> then(&Folio.put_project_on_hold!(&1, actor: owner))
      |> then(&Folio.activate_project!(&1, actor: owner))
      |> then(&Folio.complete_project!(&1, actor: owner))
      |> then(&Folio.archive_project!(&1, actor: owner))

    canceled_project =
      Folio.create_project!(%{workspace_id: workspace.id, title: "Paused initiative"},
        actor: owner
      )
      |> then(&Folio.cancel_project!(&1, actor: owner))
      |> then(&Folio.archive_project!(&1, actor: owner))

    task =
      Folio.create_task!(%{workspace_id: workspace.id, title: "Review inbox"}, actor: owner)
      |> then(
        &Folio.update_task_details!(
          &1,
          %{notes: "Waiting on external review", estimated_minutes: 25},
          actor: owner
        )
      )
      |> then(&Folio.reposition_task!(&1, %{priority_position: 3}, actor: owner))
      |> then(&Folio.mark_task_next_action!(&1, actor: owner))
      |> then(&Folio.schedule_task!(&1, %{}, actor: owner))
      |> then(&Folio.mark_task_someday_maybe!(&1, actor: owner))
      |> then(&Folio.move_task_to_inbox!(&1, actor: owner))
      |> then(&Folio.mark_task_waiting_for!(&1, actor: owner))
      |> then(&Folio.complete_task!(&1, actor: owner))
      |> then(&Folio.archive_task!(&1, actor: owner))

    canceled_task =
      Folio.create_task!(%{workspace_id: workspace.id, title: "Drop task"}, actor: owner)
      |> then(&Folio.cancel_task!(&1, actor: owner))
      |> then(&Folio.archive_task!(&1, actor: owner))

    contact = Folio.create_contact!(%{workspace_id: workspace.id, name: "Jordan"}, actor: owner)

    completed_delegation =
      Folio.create_task!(%{workspace_id: workspace.id, title: "Delegated review"}, actor: owner)
      |> then(fn delegated_task ->
        Folio.delegate_task!(
          %{
            workspace_id: workspace.id,
            task_id: delegated_task.id,
            contact_id: contact.id,
            delegated_summary: "Review the current draft"
          },
          actor: owner
        )
      end)
      |> then(&Folio.complete_delegation!(&1, actor: owner))

    canceled_delegation =
      Folio.create_task!(%{workspace_id: workspace.id, title: "Delegated follow-up"},
        actor: owner
      )
      |> then(fn delegated_task ->
        Folio.delegate_task!(
          %{
            workspace_id: workspace.id,
            task_id: delegated_task.id,
            contact_id: contact.id,
            delegated_summary: "Handle the follow-up"
          },
          actor: owner
        )
      end)
      |> then(&Folio.cancel_delegation!(&1, actor: owner))

    assert active_project.status == :archived
    assert canceled_project.status == :archived
    assert task.status == :archived
    assert canceled_task.status == :archived
    assert completed_delegation.status == :completed
    assert canceled_delegation.status == :canceled
  end

  test "revision events can be listed through the folio boundary" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    correlation_id = Ash.UUID.generate()

    area =
      Folio.create_area!(
        %{workspace_id: workspace.id, name: "Operations"},
        actor: owner,
        context: TestSupport.audit_context(%{correlation_id: correlation_id, reason: "seed area"})
      )

    _updated_area =
      Folio.update_area!(
        area,
        %{description: "Core operations"},
        actor: owner,
        context:
          TestSupport.audit_context(%{
            correlation_id: correlation_id,
            reason: "add context"
          })
      )

    events =
      Folio.list_revision_events!(
        %{workspace_id: workspace.id, resource_type: :area, resource_id: area.id},
        actor: owner
      )

    create_event = Enum.find(events, &(&1.action == :create))
    update_event = Enum.find(events, &(&1.action == :update))

    assert create_event.correlation_id == correlation_id
    assert create_event.reason == "seed area"
    assert update_event.after["description"] == "Core operations"
  end

  test "workspace-scoped project reads are available through the folio boundary" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    other_workspace = TestSupport.create_user_workspace(owner)

    active_project =
      Folio.create_project!(
        %{workspace_id: workspace.id, title: "Active project", status: :active},
        actor: owner
      )

    archived_project =
      Folio.create_project!(
        %{workspace_id: workspace.id, title: "Archived project", status: :archived},
        actor: owner
      )

    _other_workspace_project =
      Folio.create_project!(
        %{workspace_id: other_workspace.id, title: "Different workspace"},
        actor: owner
      )

    assert {:ok, projects} = Folio.list_projects_in_workspace(workspace.id, actor: owner)
    assert length(projects) == 2

    assert Enum.any?(projects, &(&1.id == active_project.id))
    assert Enum.any?(projects, &(&1.id == archived_project.id))
    assert Enum.all?(projects, &(&1.workspace_id == workspace.id))

    assert {:ok, fetched_project} =
             Folio.get_project_in_workspace(active_project.id, workspace.id, actor: owner)

    assert fetched_project.id == active_project.id
    assert fetched_project.title == "Active project"
    assert fetched_project.status == :active

    assert {:error, _} =
             Folio.get_project_in_workspace(active_project.id, other_workspace.id, actor: owner)
  end

  test "workspace-scoped task reads are available through the folio boundary" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    other_workspace = TestSupport.create_user_workspace(owner)

    linked_project =
      Folio.create_project!(%{workspace_id: workspace.id, title: "Home task project"},
        actor: owner
      )

    inbox_task =
      Folio.create_task!(%{workspace_id: workspace.id, title: "Inbox task"}, actor: owner)

    next_action_task =
      Folio.create_task!(
        %{
          workspace_id: workspace.id,
          title: "Linked next action",
          status: :next_action,
          project_id: linked_project.id
        },
        actor: owner
      )

    _other_workspace_task =
      Folio.create_task!(%{workspace_id: other_workspace.id, title: "Different workspace"},
        actor: owner
      )

    assert {:ok, tasks} = Folio.list_tasks_in_workspace(workspace.id, actor: owner)
    assert length(tasks) == 2

    assert Enum.any?(tasks, &(&1.id == inbox_task.id))
    assert Enum.any?(tasks, &(&1.id == next_action_task.id))
    assert Enum.all?(tasks, &(&1.workspace_id == workspace.id))

    assert {:ok, fetched_task} =
             Folio.get_task_in_workspace(next_action_task.id, workspace.id, actor: owner)

    assert fetched_task.id == next_action_task.id
    assert fetched_task.title == "Linked next action"
    assert fetched_task.project_id == linked_project.id
    assert fetched_task.status == :next_action

    assert {:error, _} =
             Folio.get_task_in_workspace(next_action_task.id, other_workspace.id, actor: owner)
  end

  test "non-bang folio boundary functions return expected tuples" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)

    assert {:ok, area} =
             Folio.create_area(%{workspace_id: workspace.id, name: "Health"}, actor: owner)

    assert {:ok, area} = Folio.update_area(area, %{description: "Personal upkeep"}, actor: owner)
    assert {:ok, area} = Folio.archive_area(area, actor: owner)
    assert area.status == :archived

    assert {:ok, context} =
             Folio.create_context(%{workspace_id: workspace.id, name: "Phone"}, actor: owner)

    assert {:ok, context} =
             Folio.update_context(context, %{description: "Mobile calls"}, actor: owner)

    assert {:ok, context} = Folio.archive_context(context, actor: owner)
    assert context.status == :archived

    assert {:ok, horizon} =
             Folio.create_horizon(%{workspace_id: workspace.id, name: "3 Years", level: 3},
               actor: owner
             )

    assert {:ok, horizon} =
             Folio.update_horizon(horizon, %{description: "Long-term direction"}, actor: owner)

    assert {:ok, horizon} = Folio.archive_horizon(horizon, actor: owner)
    assert horizon.status == :archived

    assert {:ok, contact} =
             Folio.create_contact(%{workspace_id: workspace.id, name: "Morgan"}, actor: owner)

    assert {:ok, contact} =
             Folio.update_contact(contact, %{capability_notes: "Operations partner"},
               actor: owner
             )

    assert {:ok, contact} = Folio.archive_contact(contact, actor: owner)
    assert contact.status == :archived

    assert {:ok, active_project} =
             Folio.create_project(%{workspace_id: workspace.id, title: "Platform refresh"},
               actor: owner
             )

    assert {:ok, active_project} =
             Folio.update_project_details(active_project, %{description: "Boundary path"},
               actor: owner
             )

    assert {:ok, active_project} =
             Folio.reposition_project(active_project, %{priority_position: 1}, actor: owner)

    assert {:ok, active_project} = Folio.put_project_on_hold(active_project, actor: owner)
    assert {:ok, active_project} = Folio.activate_project(active_project, actor: owner)
    assert {:ok, active_project} = Folio.complete_project(active_project, actor: owner)
    assert {:ok, active_project} = Folio.archive_project(active_project, actor: owner)
    assert active_project.status == :archived

    assert {:ok, canceled_project} =
             Folio.create_project(%{workspace_id: workspace.id, title: "Canceled project"},
               actor: owner
             )

    assert {:ok, canceled_project} = Folio.cancel_project(canceled_project, actor: owner)
    assert {:ok, canceled_project} = Folio.archive_project(canceled_project, actor: owner)
    assert canceled_project.status == :archived

    assert {:ok, task} =
             Folio.create_task(%{workspace_id: workspace.id, title: "Follow up"}, actor: owner)

    assert {:ok, task} =
             Folio.update_task_details(
               task,
               %{notes: "Waiting on a reply", estimated_minutes: 20},
               actor: owner
             )

    assert {:ok, task} = Folio.reposition_task(task, %{priority_position: 4}, actor: owner)
    assert {:ok, task} = Folio.mark_task_next_action(task, actor: owner)
    assert {:ok, task} = Folio.schedule_task(task, %{}, actor: owner)
    assert {:ok, task} = Folio.mark_task_someday_maybe(task, actor: owner)
    assert {:ok, task} = Folio.move_task_to_inbox(task, actor: owner)
    assert {:ok, task} = Folio.mark_task_waiting_for(task, actor: owner)
    assert {:ok, task} = Folio.complete_task(task, actor: owner)
    assert {:ok, task} = Folio.archive_task(task, actor: owner)
    assert task.status == :archived

    assert {:ok, canceled_task} =
             Folio.create_task(%{workspace_id: workspace.id, title: "Abandon task"}, actor: owner)

    assert {:ok, canceled_task} = Folio.cancel_task(canceled_task, actor: owner)
    assert {:ok, canceled_task} = Folio.archive_task(canceled_task, actor: owner)
    assert canceled_task.status == :archived

    assert {:ok, live_contact} =
             Folio.create_contact!(%{workspace_id: workspace.id, name: "Jamie"}, actor: owner)
             |> then(&{:ok, &1})

    assert {:ok, delegated_task} =
             Folio.create_task(%{workspace_id: workspace.id, title: "Delegated task"},
               actor: owner
             )

    assert {:ok, delegation} =
             Folio.delegate_task(
               %{
                 workspace_id: workspace.id,
                 task_id: delegated_task.id,
                 contact_id: live_contact.id,
                 delegated_summary: "Review this task"
               },
               actor: owner
             )

    assert {:ok, delegation} = Folio.complete_delegation(delegation, actor: owner)
    assert delegation.status == :completed

    assert {:ok, delegated_task_two} =
             Folio.create_task(%{workspace_id: workspace.id, title: "Delegated task two"},
               actor: owner
             )

    assert {:ok, delegation_two} =
             Folio.delegate_task(
               %{
                 workspace_id: workspace.id,
                 task_id: delegated_task_two.id,
                 contact_id: live_contact.id,
                 delegated_summary: "Cancel this task"
               },
               actor: owner
             )

    assert {:ok, delegation_two} = Folio.cancel_delegation(delegation_two, actor: owner)
    assert delegation_two.status == :canceled

    assert {:ok, revision_events} =
             Folio.list_revision_events(%{workspace_id: workspace.id}, actor: owner)

    assert Enum.any?(revision_events, &(&1.resource_type == :task))
  end
end
