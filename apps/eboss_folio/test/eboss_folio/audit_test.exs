defmodule EBossFolio.AuditTest do
  use EBoss.DataCase, async: false

  alias EBossFolio.TestSupport

  test "creates revision events for create, update, and transition actions with actor metadata" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    correlation_id = Ash.UUID.generate()

    area =
      EBossFolio.create_area!(
        %{workspace_id: workspace.id, name: "Operations"},
        actor: owner,
        context: TestSupport.audit_context(%{correlation_id: correlation_id, reason: "seed area"})
      )

    updated_area =
      EBossFolio.update_area!(
        area,
        %{description: "Core operations"},
        actor: owner,
        context:
          TestSupport.audit_context(%{
            correlation_id: correlation_id,
            reason: "add context"
          })
      )

    task =
      EBossFolio.create_task!(
        %{workspace_id: workspace.id, title: "Review inbox"},
        actor: owner,
        context: TestSupport.audit_context(%{correlation_id: correlation_id})
      )

    completed_task =
      EBossFolio.complete_task!(
        task,
        actor: owner,
        context:
          TestSupport.audit_context(%{
            correlation_id: correlation_id,
            reason: "finished review"
          })
      )

    assert updated_area.description == "Core operations"
    assert completed_task.status == :done

    area_events =
      EBossFolio.list_revision_events!(
        %{workspace_id: workspace.id, resource_type: :area, resource_id: area.id},
        actor: owner
      )

    task_events =
      EBossFolio.list_revision_events!(
        %{workspace_id: workspace.id, resource_type: :task, resource_id: task.id},
        actor: owner
      )

    create_event = Enum.find(area_events, &(&1.action == :create))
    update_event = Enum.find(area_events, &(&1.action == :update))
    transition_event = Enum.find(task_events, &(&1.action == :transition))

    assert create_event.before == nil
    assert create_event.after["name"] == "Operations"
    assert create_event.actor_type == :user
    assert create_event.actor_id == owner.id
    assert create_event.source == :internal
    assert create_event.correlation_id == correlation_id
    assert create_event.reason == "seed area"

    assert update_event.before["description"] == nil
    assert update_event.after["description"] == "Core operations"

    assert update_event.diff["description"] == %{
             "before" => nil,
             "after" => "Core operations"
           }

    assert transition_event.before["status"] == "inbox"
    assert transition_event.after["status"] == "done"
    assert transition_event.diff["status"] == %{"before" => "inbox", "after" => "done"}
    assert transition_event.reason == "finished review"

    all_events =
      EBossFolio.RevisionEvent
      |> Ash.read!(domain: EBossFolio, authorize?: false)

    assert length(all_events) == 4
  end
end
