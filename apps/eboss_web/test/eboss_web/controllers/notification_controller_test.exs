defmodule EBossWeb.NotificationControllerTest do
  use EBossWeb.ConnCase, async: false

  alias EBossNotify

  test "session-authenticated browsers can bootstrap, list, read, archive, and read all", %{
    conn: conn
  } do
    %{conn: session_conn, current_user: user} = register_and_log_in_user(%{conn: conn})
    {session_conn, csrf_token} = conn_with_csrf(session_conn)

    assert {:ok, %{recipients: [first_recipient]}} =
             EBossNotify.notify(
               %{
                 scope_type: :system,
                 notification_key: "system.first",
                 title: "First notice",
                 body: "Read from the bell.",
                 idempotency_key: "system.first:#{user.id}"
               },
               {:user, user}
             )

    assert {:ok, %{recipients: [second_recipient]}} =
             EBossNotify.notify(
               %{
                 scope_type: :workspace,
                 workspace_id: Ecto.UUID.generate(),
                 notification_key: "workspace.second",
                 title: "Second notice",
                 severity: :warning,
                 idempotency_key: "workspace.second:#{user.id}"
               },
               {:user, user}
             )

    bootstrap_payload =
      session_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/notifications/bootstrap")
      |> json_response(200)

    assert bootstrap_payload["unread_count"] == 2

    assert Enum.map(bootstrap_payload["recent"], & &1["title"]) == [
             "Second notice",
             "First notice"
           ]

    assert Enum.map(bootstrap_payload["supported_channels"], & &1) ==
             ~w(in_app email sms telegram webhook push)

    assert Enum.find(bootstrap_payload["channels"], &(&1["channel"] == "email"))["address"] ==
             to_string(user.email)

    unread_payload =
      session_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/notifications?status=unread")
      |> json_response(200)

    assert length(unread_payload["notifications"]) == 2

    read_payload =
      session_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> put_req_header("x-csrf-token", csrf_token)
      |> patch("/api/v1/notifications/#{first_recipient.id}", %{status: "read"})
      |> json_response(200)

    assert read_payload["notification"]["recipient_id"] == first_recipient.id
    assert read_payload["notification"]["status"] == "read"

    archive_payload =
      session_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> put_req_header("x-csrf-token", csrf_token)
      |> patch("/api/v1/notifications/#{second_recipient.id}", %{status: "archived"})
      |> json_response(200)

    assert archive_payload["notification"]["recipient_id"] == second_recipient.id
    assert archive_payload["notification"]["status"] == "archived"

    read_all_payload =
      session_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> put_req_header("x-csrf-token", csrf_token)
      |> post("/api/v1/notifications/read-all", %{})
      |> json_response(200)

    assert read_all_payload["unread_count"] == 0
  end

  test "preferences and channel endpoints are user-scoped", %{conn: conn} do
    %{conn: owner_conn, current_user: owner} =
      register_and_log_in_user(%{conn: conn}, %{username: "notify-owner"})

    {owner_conn, owner_csrf_token} = conn_with_csrf(owner_conn)

    %{conn: other_conn, current_user: other_user} =
      register_and_log_in_user(%{conn: Phoenix.ConnTest.build_conn()}, %{
        username: "notify-other"
      })

    {other_conn, other_csrf_token} = conn_with_csrf(other_conn)

    assert {:ok, endpoint} =
             EBossNotify.put_channel_endpoint(owner, %{
               channel: :telegram,
               external_id: "telegram-owner",
               status: :verified,
               primary: true
             })

    preferences_payload =
      owner_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> put_req_header("x-csrf-token", owner_csrf_token)
      |> patch("/api/v1/notifications/preferences", %{
        preferences: [
          %{
            scope_type: "system",
            channel: "email",
            enabled: true,
            cadence: "immediate"
          },
          %{
            scope_type: "system",
            channel: "sms",
            enabled: false,
            cadence: "disabled"
          }
        ]
      })
      |> json_response(200)

    assert Enum.map(preferences_payload["preferences"], & &1["channel"]) == ["email", "sms"]

    channels_payload =
      owner_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/notifications/channels")
      |> json_response(200)

    assert Enum.find(channels_payload["channels"], &(&1["channel"] == "telegram"))[
             "external_id"
           ] == "telegram-owner"

    verify_payload =
      owner_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> put_req_header("x-csrf-token", owner_csrf_token)
      |> patch("/api/v1/notifications/channels/#{endpoint.id}", %{status: "verified"})
      |> json_response(400)

    assert verify_payload["error"]["code"] == "invalid_notification_channel"

    update_payload =
      owner_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> put_req_header("x-csrf-token", owner_csrf_token)
      |> patch("/api/v1/notifications/channels/#{endpoint.id}", %{status: "disabled"})
      |> json_response(200)

    assert update_payload["channel"]["status"] == "disabled"

    assert {:ok, %{recipients: [owner_recipient]}} =
             EBossNotify.notify(
               %{
                 scope_type: :system,
                 notification_key: "system.private",
                 title: "Private notice",
                 idempotency_key: "system.private:#{owner.id}"
               },
               {:user, owner}
             )

    other_update =
      other_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> put_req_header("x-csrf-token", other_csrf_token)
      |> patch("/api/v1/notifications/#{owner_recipient.id}", %{status: "read"})
      |> json_response(404)

    assert other_update["error"]["code"] == "notification_not_found"

    other_channel_update =
      other_conn
      |> recycle()
      |> put_req_header("accept", "application/json")
      |> put_req_header("x-csrf-token", other_csrf_token)
      |> patch("/api/v1/notifications/channels/#{endpoint.id}", %{status: "verified"})
      |> json_response(404)

    assert other_channel_update["error"]["code"] == "notification_channel_not_found"

    assert {:ok, []} = EBossNotify.list_notifications(other_user, %{status: "all"})
  end

  test "unauthenticated notification API requests are rejected", %{conn: conn} do
    payload =
      conn
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/notifications/bootstrap")
      |> json_response(401)

    assert payload["error"]["code"] == "authentication_required"
  end

  defp conn_with_csrf(conn) do
    page_conn = get(conn, "/notifications")
    csrf_token = extract_csrf_token(page_conn.resp_body)
    {recycle(page_conn), csrf_token}
  end

  defp extract_csrf_token(html) do
    case Regex.run(~r/<meta name="csrf-token" content="([^"]+)"/, html, capture: :all_but_first) do
      [token] -> token
      _ -> raise "expected csrf token meta tag in rendered html"
    end
  end
end
