defmodule EBossWeb.ChatControllerTest do
  use EBossWeb.ConnCase, async: false

  alias EBossChat
  alias EBossChat.Service
  alias EBossNotify

  test "authenticated API clients can bootstrap, list, create, show, stream, and archive chat sessions",
       %{
         conn: conn
       } do
    owner = register_user()
    api_key = create_api_key(owner)
    workspace = create_user_workspace(owner, %{name: "Chat API Workspace"})

    auth_conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")

    bootstrap_payload =
      auth_conn
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/bootstrap")
      |> json_response(200)

    assert bootstrap_payload["scope"]["app_key"] == "chat"
    assert bootstrap_payload["scope"]["workspace"]["id"] == workspace.id
    assert bootstrap_payload["scope"]["app"]["key"] == "chat"
    assert bootstrap_payload["scope"]["capabilities"] == %{"manage" => true, "read" => true}
    assert bootstrap_payload["default_model_key"] == "anthropic_haiku_4_5"

    assert Enum.map(bootstrap_payload["models"], & &1["key"]) == [
             "anthropic_haiku_4_5",
             "openai_gpt_4o_mini"
           ]

    assert bootstrap_payload["sessions"] == []

    assert bootstrap_payload["usage_totals"] == %{
             "input_tokens" => 0,
             "output_tokens" => 0,
             "sessions" => 0,
             "total_tokens" => 0
           }

    create_payload =
      auth_conn
      |> recycle()
      |> post(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions",
        %{title_seed: "Launch prep thread"}
      )
      |> json_response(201)

    session_id = create_payload["session"]["id"]
    assert create_payload["session"]["title"] == "Launch prep thread"
    assert create_payload["session"]["status"] == "active"

    assert create_payload["session"]["path"] ==
             "/#{owner.owner_slug}/#{workspace.slug}/apps/chat/sessions/#{session_id}"

    show_payload =
      auth_conn
      |> recycle()
      |> get(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions/#{session_id}"
      )
      |> json_response(200)

    assert show_payload["session"]["id"] == session_id
    assert show_payload["messages"] == []

    stream_conn =
      auth_conn
      |> recycle()
      |> post(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions/#{session_id}/messages/stream",
        %{body: "What should we tackle next?", model_key: "openai_gpt_4o_mini"}
      )

    assert stream_conn.status == 200
    assert get_resp_header(stream_conn, "content-type") == ["text/event-stream; charset=utf-8"]
    assert get_resp_header(stream_conn, "cache-control") == ["no-cache"]
    assert get_resp_header(stream_conn, "x-accel-buffering") == ["no"]

    stream_body = IO.iodata_to_binary(stream_conn.resp_body || "")

    assert stream_body =~ "event: stream_ready"
    assert stream_body =~ "event: user_message_committed"
    assert stream_body =~ "event: assistant_started"
    assert stream_body =~ "event: assistant_delta"
    assert stream_body =~ "event: assistant_completed"
    assert stream_body =~ "\"session_id\":\"#{session_id}\""
    assert stream_body =~ "OpenAI mock reply: What should we tackle next?"

    session_after_stream =
      auth_conn
      |> recycle()
      |> get(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions/#{session_id}"
      )
      |> json_response(200)

    assert Enum.map(session_after_stream["messages"], & &1["role"]) == ["user", "assistant"]
    assert Enum.at(session_after_stream["messages"], 1)["status"] == "complete"
    assert Enum.at(session_after_stream["messages"], 1)["provider"] == "openai"
    assert Enum.at(session_after_stream["messages"], 1)["model"] == "openai:gpt-4o-mini"
    assert Enum.at(session_after_stream["messages"], 1)["total_tokens"] > 0

    list_payload =
      auth_conn
      |> recycle()
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions")
      |> json_response(200)

    assert Enum.any?(list_payload["sessions"], &(&1["id"] == session_id))

    archive_payload =
      auth_conn
      |> recycle()
      |> patch(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions/#{session_id}",
        %{status: "archived"}
      )
      |> json_response(200)

    assert archive_payload["session"]["id"] == session_id
    assert archive_payload["session"]["status"] == "archived"

    list_after_archive =
      auth_conn
      |> recycle()
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions")
      |> json_response(200)

    refute Enum.any?(list_after_archive["sessions"], &(&1["id"] == session_id))
  end

  test "chat endpoints distinguish unauthenticated, forbidden, and missing resources", %{
    conn: conn
  } do
    owner = register_user()
    outsider = register_user()
    owner_api_key = create_api_key(owner)
    outsider_api_key = create_api_key(outsider)
    workspace = create_user_workspace(owner, %{name: "Chat status workspace"})

    unauthenticated_payload =
      conn
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/bootstrap")
      |> json_response(401)

    assert unauthenticated_payload["error"]["code"] == "authentication_required"

    forbidden_payload =
      conn
      |> put_req_header("authorization", "Bearer #{outsider_api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/bootstrap")
      |> json_response(403)

    assert forbidden_payload["error"]["code"] == "workspace_forbidden"

    missing_payload =
      conn
      |> put_req_header("authorization", "Bearer #{owner_api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/missing-workspace/apps/chat/bootstrap")
      |> json_response(404)

    assert missing_payload["error"]["code"] == "workspace_not_found"
  end

  test "session-authenticated browsers can read chat endpoints without bearer tokens", %{
    conn: conn
  } do
    %{conn: session_conn, current_user: owner} = register_and_log_in_user(%{conn: conn})
    workspace = create_user_workspace(owner, %{name: "Session chat workspace"})
    {:ok, session} = Service.create_session(workspace.id, "Session browser thread", actor: owner)

    assert {:ok, _reply} =
             Service.stream_session_reply(session, "Session-authenticated prompt", actor: owner)

    bootstrap_payload =
      session_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/bootstrap")
      |> json_response(200)

    assert bootstrap_payload["scope"]["app_key"] == "chat"
    assert Enum.any?(bootstrap_payload["sessions"], &(&1["id"] == session.id))

    show_payload =
      session_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> get(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions/#{session.id}"
      )
      |> json_response(200)

    assert Enum.map(show_payload["messages"], & &1["role"]) == ["user", "assistant"]
  end

  test "stream failures remain on the event stream and persist assistant error state", %{
    conn: conn
  } do
    owner = register_user()
    api_key = create_api_key(owner)
    workspace = create_user_workspace(owner, %{name: "Chat stream failure workspace"})
    {:ok, session} = Service.create_session(workspace.id, "Failure stream", actor: owner)

    stream_conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> post(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions/#{session.id}/messages/stream",
        %{body: "please fail chat now"}
      )

    assert stream_conn.status == 200

    stream_body = IO.iodata_to_binary(stream_conn.resp_body || "")

    assert stream_body =~ "event: stream_ready"
    assert stream_body =~ "event: assistant_failed"
    refute stream_body =~ "\"code\":\"invalid_chat_request\""

    show_payload =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions/#{session.id}"
      )
      |> json_response(200)

    assert Enum.at(show_payload["messages"], 1)["status"] == "error"

    assert Enum.at(show_payload["messages"], 1)["error_message"] ==
             "The fake chat runtime rejected this request."

    assert {:ok, [failure_notification]} =
             EBossNotify.list_notifications(owner, %{app_key: "chat", status: "all"})

    assert failure_notification.notification.notification_key == "chat.assistant_run_failed"
    assert failure_notification.notification.severity == :error
  end

  test "stream rejects unsupported model keys before starting a run", %{conn: conn} do
    owner = register_user()
    api_key = create_api_key(owner)
    workspace = create_user_workspace(owner, %{name: "Unsupported model workspace"})
    {:ok, session} = Service.create_session(workspace.id, "Unsupported model", actor: owner)

    payload =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> post(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions/#{session.id}/messages/stream",
        %{body: "Use an invalid provider", model_key: "unknown_model"}
      )
      |> json_response(400)

    assert payload["error"]["code"] == "unsupported_chat_model"

    assert {:ok, []} =
             EBossChat.list_messages_in_session(session.id, workspace.id, actor: owner)
  end

  defp create_api_key(user) do
    api_key =
      EBoss.Accounts.ApiKey
      |> Ash.Changeset.for_create(:create, %{
        user_id: user.id,
        expires_at: DateTime.add(DateTime.utc_now(), 3_600, :second)
      })
      |> Ash.create!(authorize?: false)

    api_key.__metadata__.plaintext_api_key
  end
end
