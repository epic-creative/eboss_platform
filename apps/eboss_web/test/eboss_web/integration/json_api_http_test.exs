defmodule EBossWeb.JsonApiHttpTest do
  use EBossWeb.ApiIntegrationCase

  @moduletag :integration

  alias EBossFolio
  alias EBossNotify

  test "open api is reachable over the external http surface", %{req: req} do
    response = Req.get!(json_req(req), url: "/api/v1/open_api")

    assert response.status == 200
    assert get_header(response, "content-type") =~ "application/json"
    assert Map.has_key?(response.body["paths"], "/api/v1/workspaces")

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/bootstrap"
           )

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/bootstrap"
           )

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/projects"
           )

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/projects/{project_id}"
           )

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/tasks"
           )

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/tasks/{task_id}"
           )

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/activity"
           )

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/chat/bootstrap"
           )

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/chat/sessions"
           )

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/chat/sessions/{session_id}"
           )

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/chat/sessions/{session_id}/messages/stream"
           )

    assert Map.has_key?(response.body["paths"], "/api/v1/notifications/bootstrap")
    assert Map.has_key?(response.body["paths"], "/api/v1/notifications")
    assert Map.has_key?(response.body["paths"], "/api/v1/notifications/{recipient_id}")
    assert Map.has_key?(response.body["paths"], "/api/v1/notifications/read-all")
    assert Map.has_key?(response.body["paths"], "/api/v1/notifications/preferences")
    assert Map.has_key?(response.body["paths"], "/api/v1/notifications/channels")
    assert Map.has_key?(response.body["paths"], "/api/v1/notifications/channels/{endpoint_id}")
  end

  test "user-owned workspaces are reachable over http by id", %{req: req} do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "External User Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    authed_req = json_api_req(req, api_key)

    index_response = Req.get!(authed_req, url: "/api/v1/workspaces")
    assert index_response.status == 200

    assert Enum.any?(index_response.body["data"], fn resource ->
             resource["id"] == workspace.id
           end)

    show_response = Req.get!(authed_req, url: "/api/v1/workspaces/#{workspace.id}")
    assert show_response.status == 200
    assert show_response.body["data"]["id"] == workspace.id

    assert show_response.body["data"]["attributes"]["slug"] == workspace.slug
    assert show_response.body["data"]["attributes"]["owner_type"] == "user"
    refute Map.has_key?(show_response.body["data"]["attributes"], "owner_id")
    refute Map.has_key?(show_response.body["data"]["attributes"], "settings")
  end

  test "public workspaces remain readable over http without exposing settings or owner ids", %{
    req: req
  } do
    owner = register_user()

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "External Public Workspace",
          owner_type: :user,
          owner_id: owner.id,
          visibility: :public
        },
        actor: owner
      )

    public_workspace =
      Workspaces.update_workspace!(workspace, %{settings: %{theme: "field-notes"}}, actor: owner)

    index_response = Req.get!(json_req(req), url: "/api/v1/workspaces")
    assert index_response.status == 200

    assert Enum.any?(index_response.body["data"], fn resource ->
             resource["id"] == public_workspace.id and
               not Map.has_key?(resource["attributes"], "owner_id") and
               not Map.has_key?(resource["attributes"], "settings")
           end)

    show_response = Req.get!(json_req(req), url: "/api/v1/workspaces/#{public_workspace.id}")
    assert show_response.status == 200
    assert show_response.body["data"]["id"] == public_workspace.id
    refute Map.has_key?(show_response.body["data"]["attributes"], "owner_id")
    refute Map.has_key?(show_response.body["data"]["attributes"], "settings")
  end

  test "workspace bootstrap endpoints are reachable over http for user and org owner slugs", %{
    req: req
  } do
    owner = register_user()
    member = register_user()
    organization = Organizations.create_organization!(%{name: "Bootstrap HTTP Org"}, actor: owner)

    create_org_membership(owner, organization, member, :member)

    user_api_key = create_api_key(owner)
    member_api_key = create_api_key(member)

    user_workspace =
      Workspaces.create_workspace!(
        %{
          name: "Bootstrap HTTP Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    org_workspace =
      Workspaces.create_workspace!(
        %{
          name: "Bootstrap HTTP Org Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    user_response =
      req
      |> Req.merge(
        headers: [{"authorization", "Bearer #{user_api_key}"}, {"accept", "application/json"}]
      )
      |> Req.get!(url: "/api/v1/#{owner.owner_slug}/workspaces/#{user_workspace.slug}/bootstrap")

    assert user_response.status == 200
    assert user_response.body["workspace"]["slug"] == user_workspace.slug
    assert user_response.body["capabilities"]["manage_chat"] == true
    assert user_response.body["capabilities"]["manage_folio"] == true
    assert user_response.body["apps"]["chat"]["enabled"] == true
    assert user_response.body["apps"]["folio"]["enabled"] == true
    assert user_response.body["owner"]["slug"] == owner.owner_slug

    org_response =
      req
      |> Req.merge(
        headers: [{"authorization", "Bearer #{member_api_key}"}, {"accept", "application/json"}]
      )
      |> Req.get!(
        url: "/api/v1/#{organization.owner_slug}/workspaces/#{org_workspace.slug}/bootstrap"
      )

    assert org_response.status == 200
    assert org_response.body["workspace"]["slug"] == org_workspace.slug
    assert org_response.body["capabilities"]["manage_chat"] == true
    assert org_response.body["capabilities"]["manage_folio"] == false
    assert org_response.body["apps"]["chat"]["enabled"] == true
    assert org_response.body["apps"]["folio"]["enabled"] == false
    assert org_response.body["owner"]["slug"] == organization.owner_slug
  end

  test "workspace bootstrap endpoints return 401, 403, and 404 with distinct semantics", %{
    req: req
  } do
    owner = register_user()
    outsider = register_user()
    owner_api_key = create_api_key(owner)
    outsider_api_key = create_api_key(outsider)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "HTTP Bootstrap Status Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    unauthenticated_response =
      req
      |> json_req()
      |> Req.get!(url: "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/bootstrap")

    assert unauthenticated_response.status == 401
    assert unauthenticated_response.body["error"]["code"] == "authentication_required"

    forbidden_response =
      req
      |> Req.merge(
        headers: [{"authorization", "Bearer #{outsider_api_key}"}, {"accept", "application/json"}]
      )
      |> Req.get!(url: "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/bootstrap")

    assert forbidden_response.status == 403
    assert forbidden_response.body["error"]["code"] == "workspace_forbidden"

    missing_response =
      req
      |> Req.merge(
        headers: [{"authorization", "Bearer #{owner_api_key}"}, {"accept", "application/json"}]
      )
      |> Req.get!(url: "/api/v1/#{owner.owner_slug}/workspaces/missing-workspace/bootstrap")

    assert missing_response.status == 404
    assert missing_response.body["error"]["code"] == "workspace_not_found"
  end

  test "folio bootstrap endpoint is reachable over http and returns summary counts", %{req: req} do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "HTTP Folio Bootstrap Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    EBossFolio.create_project!(%{workspace_id: workspace.id, title: "HTTP Project"}, actor: owner)

    EBossFolio.create_task!(%{workspace_id: workspace.id, title: "HTTP Task"}, actor: owner)

    response =
      req
      |> Req.merge(
        headers: [{"authorization", "Bearer #{api_key}"}, {"accept", "application/json"}]
      )
      |> Req.get!(
        url: "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/bootstrap"
      )

    assert response.status == 200
    assert response.body["scope"]["app_key"] == "folio"
    assert response.body["scope"]["capabilities"] == %{"manage" => true, "read" => true}

    assert response.body["scope"]["app_path"] ==
             "/#{owner.owner_slug}/#{workspace.slug}/apps/folio"

    assert response.body["summary_counts"] == %{"projects" => 1, "tasks" => 1}
    refute Map.has_key?(response.body, "current_user")
    refute Map.has_key?(response.body, "apps")
    refute Map.has_key?(response.body, "capabilities")
  end

  test "folio activity endpoint is reachable over http and returns revision events", %{req: req} do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "HTTP Folio Activity Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    area =
      EBossFolio.create_area!(%{workspace_id: workspace.id, name: "HTTP Area"}, actor: owner)

    EBossFolio.update_area!(
      area,
      %{description: "Revised via HTTP"},
      actor: owner
    )

    response =
      req
      |> Req.merge(
        headers: [{"authorization", "Bearer #{api_key}"}, {"accept", "application/json"}]
      )
      |> Req.get!(
        url: "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/activity"
      )

    assert response.status == 200
    assert response.body["scope"]["app_key"] == "folio"
    assert response.body["scope"]["workspace"]["id"] == workspace.id
    assert is_list(response.body["events"])
    assert length(response.body["events"]) >= 2
    assert Enum.any?(response.body["events"], &(&1["subject"]["type"] == "area"))
  end

  test "session-authenticated browsers can mutate folio over http with csrf protection", %{
    req: req
  } do
    owner = register_user()
    initial_cookie_header = browser_session_cookie_header(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "HTTP Session Folio Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "HTTP Session Task"},
        actor: owner
      )

    tasks_page_response =
      req
      |> Req.merge(headers: [{"cookie", initial_cookie_header}, {"accept", "text/html"}])
      |> Req.get!(url: "/#{owner.owner_slug}/#{workspace.slug}/apps/folio/tasks")

    csrf_token = tasks_page_response.body |> extract_csrf_token()
    cookie_header = response_cookie_header(tasks_page_response, initial_cookie_header)

    create_response =
      req
      |> Req.merge(
        headers: [
          {"cookie", cookie_header},
          {"x-csrf-token", csrf_token},
          {"accept", "application/json"}
        ]
      )
      |> Req.post!(
        url: "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks",
        json: %{title: "HTTP Session Created Task"}
      )

    assert create_response.status == 201
    assert create_response.body["task"]["title"] == "HTTP Session Created Task"
    assert create_response.body["task"]["status"] == "inbox"

    transition_response =
      req
      |> Req.merge(
        headers: [
          {"cookie", cookie_header},
          {"x-csrf-token", csrf_token},
          {"accept", "application/json"}
        ]
      )
      |> Req.patch!(
        url:
          "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks/#{task.id}",
        json: %{status: "done"}
      )

    assert transition_response.status == 200
    assert transition_response.body["task"]["id"] == task.id
    assert transition_response.body["task"]["status"] == "done"
  end

  test "session-authenticated folio mutations reject missing csrf tokens over http", %{req: req} do
    owner = register_user()
    initial_cookie_header = browser_session_cookie_header(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "HTTP Session CSRF Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    tasks_page_response =
      req
      |> Req.merge(headers: [{"cookie", initial_cookie_header}, {"accept", "text/html"}])
      |> Req.get!(url: "/#{owner.owner_slug}/#{workspace.slug}/apps/folio/tasks")

    cookie_header = response_cookie_header(tasks_page_response, initial_cookie_header)

    response =
      req
      |> Req.merge(headers: [{"cookie", cookie_header}, {"accept", "application/json"}])
      |> Req.post!(
        url: "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks",
        json: %{title: "Missing csrf"}
      )

    assert response.status == 403
  end

  test "folio bootstrap endpoints return 401, 403, and 404 with distinct semantics", %{req: req} do
    owner = register_user()
    member = register_user()
    organization = Organizations.create_organization!(%{name: "HTTP Folio Org"}, actor: owner)

    create_org_membership(owner, organization, member, :member)

    owner_api_key = create_api_key(owner)
    member_api_key = create_api_key(member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "HTTP Folio Status Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    org_workspace =
      Workspaces.create_workspace!(
        %{
          name: "HTTP Folio Locked Org Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    unauthenticated_response =
      req
      |> json_req()
      |> Req.get!(
        url: "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/bootstrap"
      )

    assert unauthenticated_response.status == 401
    assert unauthenticated_response.body["error"]["code"] == "authentication_required"

    forbidden_response =
      req
      |> Req.merge(
        headers: [{"authorization", "Bearer #{member_api_key}"}, {"accept", "application/json"}]
      )
      |> Req.get!(
        url:
          "/api/v1/#{organization.owner_slug}/workspaces/#{org_workspace.slug}/apps/folio/bootstrap"
      )

    assert forbidden_response.status == 403
    assert forbidden_response.body["error"]["code"] == "workspace_forbidden"

    missing_response =
      req
      |> Req.merge(
        headers: [{"authorization", "Bearer #{owner_api_key}"}, {"accept", "application/json"}]
      )
      |> Req.get!(
        url: "/api/v1/#{owner.owner_slug}/workspaces/missing-workspace/apps/folio/bootstrap"
      )

    assert missing_response.status == 404
    assert missing_response.body["error"]["code"] == "workspace_not_found"
  end

  test "session-authenticated browsers can create, stream, and archive chat over http with csrf protection",
       %{
         req: req
       } do
    owner = register_user()
    initial_cookie_header = browser_session_cookie_header(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "HTTP Session Chat Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    chat_page_response =
      req
      |> Req.merge(headers: [{"cookie", initial_cookie_header}, {"accept", "text/html"}])
      |> Req.get!(url: "/#{owner.owner_slug}/#{workspace.slug}/apps/chat/new")

    csrf_token = extract_csrf_token(chat_page_response.body)
    cookie_header = response_cookie_header(chat_page_response, initial_cookie_header)

    create_response =
      req
      |> Req.merge(
        headers: [
          {"cookie", cookie_header},
          {"x-csrf-token", csrf_token},
          {"accept", "application/json"}
        ]
      )
      |> Req.post!(
        url: "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions",
        json: %{title_seed: "HTTP chat session"}
      )

    assert create_response.status == 201
    session_id = create_response.body["session"]["id"]
    assert create_response.body["session"]["title"] == "HTTP chat session"

    stream_response =
      req
      |> Req.merge(
        headers: [
          {"cookie", cookie_header},
          {"x-csrf-token", csrf_token},
          {"accept", "application/json"}
        ]
      )
      |> Req.post!(
        url:
          "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions/#{session_id}/messages/stream",
        json: %{body: "What did we ship?"}
      )

    assert stream_response.status == 200
    assert get_header(stream_response, "content-type") =~ "text/event-stream"

    event_names = parse_sse_event_names(stream_response.body)

    assert Enum.take(event_names, 3) == [
             "stream_ready",
             "user_message_committed",
             "assistant_started"
           ]

    assert List.last(event_names) == "assistant_completed"
    assert Enum.any?(event_names, &(&1 == "assistant_delta"))
    assert stream_response.body =~ "Haiku mock reply: What did we ship?"

    show_response =
      req
      |> Req.merge(headers: [{"cookie", cookie_header}, {"accept", "application/json"}])
      |> Req.get!(
        url:
          "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions/#{session_id}"
      )

    assert show_response.status == 200
    assert Enum.map(show_response.body["messages"], & &1["role"]) == ["user", "assistant"]

    archive_response =
      req
      |> Req.merge(
        headers: [
          {"cookie", cookie_header},
          {"x-csrf-token", csrf_token},
          {"accept", "application/json"}
        ]
      )
      |> Req.patch!(
        url:
          "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions/#{session_id}",
        json: %{status: "archived"}
      )

    assert archive_response.status == 200
    assert archive_response.body["session"]["status"] == "archived"
  end

  test "session-authenticated chat mutations reject missing csrf tokens over http", %{req: req} do
    owner = register_user()
    initial_cookie_header = browser_session_cookie_header(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "HTTP Session Chat CSRF Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    chat_page_response =
      req
      |> Req.merge(headers: [{"cookie", initial_cookie_header}, {"accept", "text/html"}])
      |> Req.get!(url: "/#{owner.owner_slug}/#{workspace.slug}/apps/chat/new")

    csrf_token = extract_csrf_token(chat_page_response.body)
    cookie_header = response_cookie_header(chat_page_response, initial_cookie_header)

    create_without_csrf =
      req
      |> Req.merge(headers: [{"cookie", cookie_header}, {"accept", "application/json"}])
      |> Req.post!(
        url: "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions",
        json: %{title_seed: "Missing chat csrf"}
      )

    assert create_without_csrf.status == 403

    create_with_csrf =
      req
      |> Req.merge(
        headers: [
          {"cookie", cookie_header},
          {"x-csrf-token", csrf_token},
          {"accept", "application/json"}
        ]
      )
      |> Req.post!(
        url: "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions",
        json: %{title_seed: "Valid chat csrf"}
      )

    assert create_with_csrf.status == 201
    session_id = create_with_csrf.body["session"]["id"]

    stream_without_csrf =
      req
      |> Req.merge(headers: [{"cookie", cookie_header}, {"accept", "application/json"}])
      |> Req.post!(
        url:
          "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/chat/sessions/#{session_id}/messages/stream",
        json: %{body: "Missing token"}
      )

    assert stream_without_csrf.status == 403
  end

  test "session-authenticated browsers can use notification APIs over http with csrf protection",
       %{req: req} do
    owner = register_user()
    initial_cookie_header = browser_session_cookie_header(owner)

    {:ok, %{recipients: [recipient]}} =
      EBossNotify.notify(
        %{
          scope_type: :system,
          notification_key: "system.http",
          title: "HTTP notification",
          body: "This should be visible in the notification API.",
          idempotency_key: "system.http:#{owner.id}"
        },
        {:user, owner}
      )

    notifications_page_response =
      req
      |> Req.merge(headers: [{"cookie", initial_cookie_header}, {"accept", "text/html"}])
      |> Req.get!(url: "/notifications")

    csrf_token = extract_csrf_token(notifications_page_response.body)
    cookie_header = response_cookie_header(notifications_page_response, initial_cookie_header)

    bootstrap_response =
      req
      |> Req.merge(headers: [{"cookie", cookie_header}, {"accept", "application/json"}])
      |> Req.get!(url: "/api/v1/notifications/bootstrap")

    assert bootstrap_response.status == 200
    assert bootstrap_response.body["unread_count"] == 1
    assert hd(bootstrap_response.body["recent"])["title"] == "HTTP notification"

    mark_read_response =
      req
      |> Req.merge(
        headers: [
          {"cookie", cookie_header},
          {"x-csrf-token", csrf_token},
          {"accept", "application/json"}
        ]
      )
      |> Req.patch!(
        url: "/api/v1/notifications/#{recipient.id}",
        json: %{status: "read"}
      )

    assert mark_read_response.status == 200
    assert mark_read_response.body["notification"]["status"] == "read"

    preferences_response =
      req
      |> Req.merge(
        headers: [
          {"cookie", cookie_header},
          {"x-csrf-token", csrf_token},
          {"accept", "application/json"}
        ]
      )
      |> Req.patch!(
        url: "/api/v1/notifications/preferences",
        json: %{
          preferences: [
            %{
              scope_type: "system",
              channel: "telegram",
              enabled: true,
              cadence: "immediate"
            }
          ]
        }
      )

    assert preferences_response.status == 200
    assert hd(preferences_response.body["preferences"])["channel"] == "telegram"

    read_all_response =
      req
      |> Req.merge(
        headers: [
          {"cookie", cookie_header},
          {"x-csrf-token", csrf_token},
          {"accept", "application/json"}
        ]
      )
      |> Req.post!(url: "/api/v1/notifications/read-all", json: %{})

    assert read_all_response.status == 200
    assert read_all_response.body["unread_count"] == 0
  end

  test "session-authenticated notification mutations reject missing csrf tokens over http", %{
    req: req
  } do
    owner = register_user()
    initial_cookie_header = browser_session_cookie_header(owner)

    {:ok, %{recipients: [recipient]}} =
      EBossNotify.notify(
        %{
          scope_type: :system,
          notification_key: "system.http_csrf",
          title: "HTTP CSRF notification",
          idempotency_key: "system.http_csrf:#{owner.id}"
        },
        {:user, owner}
      )

    notifications_page_response =
      req
      |> Req.merge(headers: [{"cookie", initial_cookie_header}, {"accept", "text/html"}])
      |> Req.get!(url: "/notifications")

    csrf_token = extract_csrf_token(notifications_page_response.body)
    cookie_header = response_cookie_header(notifications_page_response, initial_cookie_header)

    missing_csrf_response =
      req
      |> Req.merge(headers: [{"cookie", cookie_header}, {"accept", "application/json"}])
      |> Req.patch!(
        url: "/api/v1/notifications/#{recipient.id}",
        json: %{status: "read"}
      )

    assert missing_csrf_response.status == 403

    valid_csrf_response =
      req
      |> Req.merge(
        headers: [
          {"cookie", cookie_header},
          {"x-csrf-token", csrf_token},
          {"accept", "application/json"}
        ]
      )
      |> Req.patch!(
        url: "/api/v1/notifications/#{recipient.id}",
        json: %{status: "read"}
      )

    assert valid_csrf_response.status == 200
    assert valid_csrf_response.body["notification"]["status"] == "read"
  end

  defp get_header(response, header) do
    response.headers
    |> Enum.filter(fn {key, _value} -> String.downcase(key) == String.downcase(header) end)
    |> Enum.flat_map(fn
      {_key, values} when is_list(values) -> values
      {_key, value} -> [value]
    end)
    |> List.first("")
  end

  defp extract_csrf_token(html) when is_binary(html) do
    case Regex.run(~r/<meta name="csrf-token" content="([^"]+)"/, html, capture: :all_but_first) do
      [token] -> token
      _ -> raise "expected csrf token meta tag in rendered html"
    end
  end

  defp response_cookie_header(response, fallback_cookie_header) do
    case get_header(response, "set-cookie") do
      "" -> fallback_cookie_header
      header -> String.split(header, ";", parts: 2) |> hd()
    end
  end

  defp parse_sse_event_names(body) when is_binary(body) do
    Regex.scan(~r/^event:\s*([^\n]+)$/m, body, capture: :all_but_first)
    |> List.flatten()
  end
end
