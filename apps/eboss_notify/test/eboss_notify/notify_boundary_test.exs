defmodule EBossNotify.NotifyBoundaryTest do
  use EBoss.DataCase, async: false

  alias EBossNotify
  alias EBossNotify.TestSupport

  @moduletag :boundary

  test "user notifications create immutable envelope, recipient state, and in-app delivery" do
    user = TestSupport.register_user()

    assert {:ok, %{notification: notification, recipients: [recipient], deliveries: deliveries}} =
             EBossNotify.notify(
               %{
                 scope_type: :user,
                 scope_id: user.id,
                 notification_key: "account.confirmed",
                 title: "Account confirmed",
                 body: "Your account is ready.",
                 severity: :success,
                 idempotency_key: "account.confirmed:#{user.id}"
               },
               {:user, user}
             )

    assert notification.title == "Account confirmed"
    assert recipient.user_id == user.id
    assert recipient.status == :unread

    assert Enum.map(deliveries, & &1.channel) == [:in_app]
    assert hd(deliveries).status == :delivered

    assert {:ok, 1} = EBossNotify.unread_count(user)
  end

  test "idempotency prevents duplicate notification envelopes and recipients" do
    user = TestSupport.register_user()

    attrs = %{
      scope_type: :system,
      notification_key: "system.notice",
      title: "System notice",
      idempotency_key: "system.notice:#{user.id}"
    }

    assert {:ok, first} = EBossNotify.notify(attrs, {:user, user})
    assert {:ok, second} = EBossNotify.notify(attrs, {:user, user})

    assert first.notification.id == second.notification.id
    assert length(second.recipients) == 1

    assert {:ok, notifications} = EBossNotify.list_notifications(user, %{status: "all"})
    assert length(notifications) == 1
  end

  test "in-app preference is independent from external channel delivery" do
    user = TestSupport.register_user()

    assert {:ok, _preferences} =
             EBossNotify.put_preferences(user, [
               %{
                 scope_type: :system,
                 channel: :in_app,
                 enabled: false,
                 cadence: :disabled
               },
               %{
                 scope_type: :system,
                 channel: :email,
                 enabled: true,
                 cadence: :immediate
               }
             ])

    assert {:ok, %{recipients: [recipient], deliveries: [delivery]}} =
             EBossNotify.notify(
               %{
                 scope_type: :system,
                 notification_key: "system.email_only",
                 title: "Email-only notice"
               },
               {:user, user}
             )

    assert recipient.status == :read
    assert delivery.channel == :email
    assert delivery.status == :pending
    assert {:ok, 0} = EBossNotify.unread_count(user)
  end

  test "external channels are preference-backed but provider delivery is deferred" do
    user = TestSupport.register_user()

    assert {:ok, _endpoint} =
             EBossNotify.put_channel_endpoint(user, %{
               channel: :telegram,
               external_id: "telegram-123",
               status: :verified,
               primary: true
             })

    assert {:ok, _preferences} =
             EBossNotify.put_preferences(user, [
               %{scope_type: :system, channel: :email, enabled: true, cadence: :immediate},
               %{scope_type: :system, channel: :sms, enabled: true, cadence: :immediate},
               %{scope_type: :system, channel: :telegram, enabled: true, cadence: :immediate}
             ])

    assert {:ok, %{deliveries: deliveries}} =
             EBossNotify.notify(
               %{
                 scope_type: :system,
                 notification_key: "system.channels",
                 title: "Channel notice"
               },
               {:user, user}
             )

    deliveries_by_channel = Map.new(deliveries, &{&1.channel, &1})

    assert deliveries_by_channel.in_app.status == :delivered
    assert deliveries_by_channel.email.status == :pending
    assert deliveries_by_channel.sms.status == :not_configured
    assert deliveries_by_channel.telegram.status == :pending
    assert deliveries_by_channel.telegram.endpoint_id
  end

  test "workspace audience expands to owner and user-workspace members" do
    owner = TestSupport.register_user()
    member = TestSupport.register_user()
    outsider = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    _membership = TestSupport.create_workspace_member(owner, workspace, member)

    assert {:ok, %{recipients: recipients}} =
             EBossNotify.notify_workspace(workspace.id, "workspace.member_changed", %{
               title: "Workspace changed"
             })

    recipient_user_ids = Enum.map(recipients, & &1.user_id) |> Enum.sort()
    assert recipient_user_ids == Enum.sort([owner.id, member.id])

    assert {:ok, [_notification]} = EBossNotify.list_notifications(owner, %{status: "all"})
    assert {:ok, [_notification]} = EBossNotify.list_notifications(member, %{status: "all"})
    assert {:ok, []} = EBossNotify.list_notifications(outsider, %{status: "all"})
  end

  test "producer options can exclude the actor from shared workspace notifications" do
    owner = TestSupport.register_user()
    member = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    _membership = TestSupport.create_workspace_member(owner, workspace, member)

    assert {:ok, %{recipients: recipients}} =
             EBossNotify.notify(
               %{
                 scope_type: :app,
                 scope_id: workspace.id,
                 workspace_id: workspace.id,
                 app_key: "chat",
                 notification_key: "chat.session_created",
                 title: "New shared chat session"
               },
               {:app, workspace.id, "chat"},
               exclude_user_ids: [owner.id]
             )

    assert Enum.map(recipients, & &1.user_id) == [member.id]
  end

  test "read and archive state is scoped to the recipient user" do
    owner = TestSupport.register_user()
    member = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    _membership = TestSupport.create_workspace_member(owner, workspace, member)

    assert {:ok, %{recipients: recipients}} =
             EBossNotify.notify_workspace(workspace.id, "workspace.scope", %{
               title: "Scoped notice"
             })

    owner_recipient = Enum.find(recipients, &(&1.user_id == owner.id))
    member_recipient = Enum.find(recipients, &(&1.user_id == member.id))

    assert {:ok, read_recipient} = EBossNotify.mark_read(owner, owner_recipient.id)
    assert read_recipient.status == :read

    assert {:error, _reason} = EBossNotify.mark_read(owner, member_recipient.id)

    assert {:ok, archived_recipient} = EBossNotify.archive(member, member_recipient.id)
    assert archived_recipient.status == :archived

    assert {:ok, 0} = EBossNotify.unread_count(member)
  end

  test "notification envelopes are only readable by recipients" do
    owner = TestSupport.register_user()
    outsider = TestSupport.register_user()

    assert {:ok, %{notification: notification}} =
             EBossNotify.notify(
               %{
                 scope_type: :system,
                 notification_key: "system.private_envelope",
                 title: "Private envelope"
               },
               {:user, owner}
             )

    assert {:ok, _notification} = EBossNotify.get_notification(notification.id, actor: owner)
    assert {:error, _reason} = EBossNotify.get_notification(notification.id, actor: outsider)
  end
end
