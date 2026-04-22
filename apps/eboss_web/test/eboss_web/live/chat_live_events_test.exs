defmodule EBossWeb.ChatLiveEventsTest do
  use EBossWeb.ConnCase, async: false

  alias EBossChat

  test "workspace Chat draft send runs through LiveView events and pushes assistant stream events",
       %{conn: conn} do
    %{conn: conn, current_user: user} = register_and_log_in_user(%{conn: conn})
    workspace = create_user_workspace(user, %{name: "Chat Live Events"})

    assert {:ok, view, _html} =
             live(conn, dashboard_path(user.owner_slug, workspace.slug) <> "/apps/chat/new")

    render_hook(view, "chat:send_message", %{
      "body" => "Draft chat event",
      "model_key" => "anthropic_haiku_4_5"
    })

    assert_reply view, %{
      ok: true,
      session: %{id: session_id, title: "Draft chat event"}
    }

    assert_push_event view,
                      "chat:assistant_delta",
                      %{session_id: ^session_id, delta: _delta},
                      1_000

    assert_push_event view,
                      "chat:assistant_completed",
                      %{
                        session_id: ^session_id,
                        message: %{role: :assistant, status: :complete, body: assistant_body}
                      },
                      1_000

    assert assistant_body =~ "Haiku mock reply: Draft chat event"

    assert {:ok, messages} =
             EBossChat.list_messages_in_session(session_id, workspace.id, actor: user)

    assert Enum.map(messages, & &1.role) == [:user, :assistant]
  end

  test "workspace Chat archive runs through LiveView events", %{conn: conn} do
    %{conn: conn, current_user: user} = register_and_log_in_user(%{conn: conn})
    workspace = create_user_workspace(user, %{name: "Chat Archive Live Events"})

    {:ok, session} =
      EBossChat.Service.create_session(workspace.id, "Archive through LiveView", actor: user)

    assert {:ok, view, _html} =
             live(
               conn,
               dashboard_path(user.owner_slug, workspace.slug) <>
                 "/apps/chat/sessions/#{session.id}"
             )

    render_hook(view, "chat:archive_session", %{"session_id" => session.id})

    assert_reply view, %{
      ok: true,
      session: %{id: session_id, status: :archived}
    }

    assert session_id == session.id

    assert {:ok, archived_session} =
             EBossChat.get_session_in_workspace(session.id, workspace.id,
               actor: user,
               load: EBossWeb.ChatPayloads.session_load()
             )

    assert archived_session.status == :archived
  end
end
