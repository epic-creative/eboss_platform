defmodule EBossWeb.NotificationLiveEventsTest do
  use EBossWeb.ConnCase, async: false

  import LiveVue.Test

  alias EBossNotify

  test "notification center owns visible inbox state through LiveView events", %{conn: conn} do
    %{conn: conn, current_user: user} = register_and_log_in_user(%{conn: conn})

    assert {:ok, %{recipients: [recipient]}} =
             EBossNotify.notify(
               %{
                 scope_type: :system,
                 notification_key: "system.live_center",
                 title: "Live center notice",
                 body: "This arrives through LiveView props.",
                 idempotency_key: "system.live_center:#{user.id}"
               },
               {:user, user}
             )

    assert {:ok, view, _html} = live(conn, ~p"/notifications")

    center = get_vue(view, name: "NotificationCenterApp")
    assert center.props["notificationBootstrap"]["unread_count"] == 1
    assert hd(center.props["notifications"])["title"] == "Live center notice"

    render_hook(view, "notifications:mark_read", %{"recipient_id" => recipient.id})

    center = get_vue(view, name: "NotificationCenterApp")
    assert center.props["notificationBootstrap"]["unread_count"] == 0
    assert hd(center.props["notifications"])["status"] == "read"

    render_hook(view, "notifications:filter", %{"status" => "unread", "scope" => "all"})

    center = get_vue(view, name: "NotificationCenterApp")
    assert center.props["activeStatus"] == "unread"
    assert center.props["notifications"] == []
  end

  test "workspace notification bell uses LiveView events for read-all", %{conn: conn} do
    %{conn: conn, current_user: user} = register_and_log_in_user(%{conn: conn})
    workspace = create_user_workspace(user, %{name: "Notification Workspace"})

    assert {:ok, %{recipients: [_recipient]}} =
             EBossNotify.notify(
               %{
                 scope_type: :workspace,
                 workspace_id: workspace.id,
                 notification_key: "workspace.live_bell",
                 title: "Bell notice",
                 idempotency_key: "workspace.live_bell:#{user.id}"
               },
               {:user, user}
             )

    assert {:ok, view, _html} = live(conn, dashboard_path(user.owner_slug, workspace.slug))

    shell = get_vue(view, name: "ShellOperatorWorkspaceApp")
    assert shell.props["notificationBootstrap"]["unread_count"] == 1

    render_hook(view, "notifications:mark_all_read", %{})

    shell = get_vue(view, name: "ShellOperatorWorkspaceApp")
    assert shell.props["notificationBootstrap"]["unread_count"] == 0
  end
end
