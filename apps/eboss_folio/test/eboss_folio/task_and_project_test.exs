defmodule EBossFolio.TaskAndProjectTest do
  use EBoss.DataCase, async: false

  alias EBossFolio.TestSupport

  test "terminal task and project transitions only allow archival" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)

    task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "Ship release"}, actor: owner)

    task = EBossFolio.complete_task!(task, actor: owner)

    assert {:error, task_error} = EBossFolio.cancel_task(task, actor: owner)

    archived_task = EBossFolio.archive_task!(task, actor: owner)

    assert archived_task.status == :archived
    assert Exception.message(task_error) =~ "cannot transition task"

    project =
      EBossFolio.create_project!(%{workspace_id: workspace.id, title: "Release train"},
        actor: owner
      )

    project = EBossFolio.complete_project!(project, actor: owner)

    assert {:error, project_error} = EBossFolio.activate_project(project, actor: owner)

    archived_project = EBossFolio.archive_project!(project, actor: owner)

    assert archived_project.status == :archived
    assert Exception.message(project_error) =~ "cannot transition project"
  end

  test "waiting_for requires notes or an active delegation" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)

    assert {:error, create_error} =
             EBossFolio.create_task(
               %{workspace_id: workspace.id, title: "Need follow-up", status: :waiting_for},
               actor: owner
             )

    assert Exception.message(create_error) =~
             "waiting_for tasks require notes or an active delegation"

    assert %EBossFolio.Task{status: :waiting_for} =
             EBossFolio.create_task!(
               %{
                 workspace_id: workspace.id,
                 title: "Need follow-up",
                 status: :waiting_for,
                 notes: "Waiting on an external answer"
               },
               actor: owner
             )

    task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "Blocked task"}, actor: owner)

    assert {:error, transition_error} = EBossFolio.mark_task_waiting_for(task, actor: owner)

    assert Exception.message(transition_error) =~
             "waiting_for tasks require notes or an active delegation"

    contact =
      EBossFolio.create_contact!(%{workspace_id: workspace.id, name: "Taylor"}, actor: owner)

    _delegation =
      EBossFolio.delegate_task!(
        %{
          workspace_id: workspace.id,
          task_id: task.id,
          contact_id: contact.id,
          delegated_summary: "Send the requested update"
        },
        actor: owner
      )

    waiting_task = EBossFolio.mark_task_waiting_for!(task, actor: owner)
    assert waiting_task.status == :waiting_for
  end

  test "a task can only have one active delegation" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)

    task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "Coordinate vendor"},
        actor: owner
      )

    first_contact =
      EBossFolio.create_contact!(%{workspace_id: workspace.id, name: "Vendor One"}, actor: owner)

    second_contact =
      EBossFolio.create_contact!(%{workspace_id: workspace.id, name: "Vendor Two"}, actor: owner)

    _delegation =
      EBossFolio.delegate_task!(
        %{
          workspace_id: workspace.id,
          task_id: task.id,
          contact_id: first_contact.id,
          delegated_summary: "Handle the first pass"
        },
        actor: owner
      )

    assert {:error, error} =
             EBossFolio.delegate_task(
               %{
                 workspace_id: workspace.id,
                 task_id: task.id,
                 contact_id: second_contact.id,
                 delegated_summary: "Handle the second pass"
               },
               actor: owner
             )

    assert Exception.message(error) =~ "already has an active delegation"
  end

  test "completing a delegated task completes its active delegation" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)

    task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "Review delegated draft"},
        actor: owner
      )

    contact =
      EBossFolio.create_contact!(%{workspace_id: workspace.id, name: "Delegate Contact"},
        actor: owner
      )

    _delegation =
      EBossFolio.delegate_task!(
        %{
          workspace_id: workspace.id,
          task_id: task.id,
          contact_id: contact.id,
          delegated_summary: "Review the draft and send notes"
        },
        actor: owner
      )

    completed_task = EBossFolio.complete_task!(task, actor: owner)

    reloaded_task =
      EBossFolio.get_task_in_workspace!(task.id, workspace.id,
        actor: owner,
        load: [delegations: :contact]
      )

    assert completed_task.status == :done
    assert reloaded_task.status == :done
    refute Enum.any?(reloaded_task.delegations, &(&1.status == :active))

    assert Enum.any?(reloaded_task.delegations, fn delegation ->
             delegation.status == :completed and delegation.contact.name == "Delegate Contact"
           end)
  end

  test "canceling or archiving a delegated task cancels its active delegation" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)

    contact =
      EBossFolio.create_contact!(%{workspace_id: workspace.id, name: "Cancel Contact"},
        actor: owner
      )

    canceled_task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "Cancel delegated task"},
        actor: owner
      )

    _canceled_delegation =
      EBossFolio.delegate_task!(
        %{
          workspace_id: workspace.id,
          task_id: canceled_task.id,
          contact_id: contact.id,
          delegated_summary: "Wait for vendor response"
        },
        actor: owner
      )

    archived_task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "Archive delegated task"},
        actor: owner
      )

    _archived_delegation =
      EBossFolio.delegate_task!(
        %{
          workspace_id: workspace.id,
          task_id: archived_task.id,
          contact_id: contact.id,
          delegated_summary: "Hold until decision lands"
        },
        actor: owner
      )

    canceled_task = EBossFolio.cancel_task!(canceled_task, actor: owner)
    archived_task = EBossFolio.archive_task!(archived_task, actor: owner)

    reloaded_canceled_task =
      EBossFolio.get_task_in_workspace!(canceled_task.id, workspace.id,
        actor: owner,
        load: [delegations: :contact]
      )

    reloaded_archived_task =
      EBossFolio.get_task_in_workspace!(archived_task.id, workspace.id,
        actor: owner,
        load: [delegations: :contact]
      )

    assert canceled_task.status == :canceled
    assert archived_task.status == :archived
    refute Enum.any?(reloaded_canceled_task.delegations, &(&1.status == :active))
    refute Enum.any?(reloaded_archived_task.delegations, &(&1.status == :active))

    assert Enum.any?(reloaded_canceled_task.delegations, &(&1.status == :canceled))
    assert Enum.any?(reloaded_archived_task.delegations, &(&1.status == :canceled))
  end
end
