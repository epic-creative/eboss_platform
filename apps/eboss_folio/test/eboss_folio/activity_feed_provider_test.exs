defmodule EBossFolio.ActivityFeedProviderTest do
  use EBoss.DataCase, async: false

  alias EBossFolio.ActivityFeedProvider
  alias EBossFolio.TestSupport

  test "maps revision events to the shared workspace activity feed contract" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    correlation_id = Ash.UUID.generate()

    area =
      EBossFolio.create_area!(
        %{workspace_id: workspace.id, name: "Operations"},
        actor: owner,
        context: TestSupport.audit_context(%{correlation_id: correlation_id, reason: "seed area"})
      )

    _updated_area =
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

    events =
      EBossFolio.list_revision_events!(
        %{workspace_id: workspace.id, resource_type: :area, resource_id: area.id},
        actor: owner
      )

    mapped_events = ActivityFeedProvider.map_events(events)

    assert length(mapped_events) == 2
    assert Enum.all?(mapped_events, &(&1.app_key == "folio"))
    assert Enum.all?(mapped_events, &(&1.provider_key == "revision_event"))
    assert Enum.all?(mapped_events, &is_binary(&1.occurred_at))

    create_event = Enum.find(mapped_events, &(&1.action == "create"))
    update_event = Enum.find(mapped_events, &(&1.action == "update"))

    assert create_event != nil
    assert create_event.id == create_event.provider_event_id
    assert create_event.subject.type == "area"
    assert create_event.subject.id == area.id
    assert create_event.actor.type == :user
    assert create_event.actor.id == owner.id
    assert create_event.summary =~ "created area #{area.id}"
    assert create_event.provider_key == "revision_event"
    assert create_event.metadata.workspace_id == workspace.id
    assert create_event.metadata.correlation_id == correlation_id

    assert create_event.metadata.reason == "seed area"
    assert update_event.metadata.reason == "add context"
    assert update_event.status == :success
    assert create_event.status == :success
  end

  test "returns an empty list for empty inputs" do
    assert ActivityFeedProvider.map_events([]) == []
  end
end
