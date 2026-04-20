defmodule EBossWeb.JsonApiTest do
  use EBossWeb.ConnCase, async: false

  alias EBossFolio
  alias EBoss.Workspaces
  alias EBoss.Organizations

  test "v1 open api spec is exposed", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/open_api")

    spec = json_response(conn, 200)

    assert spec["info"]["title"] == "EBoss API"
    assert Map.has_key?(spec["paths"], "/api/v1/workspaces")
    assert Map.has_key?(spec["paths"], "/api/v1/workspaces/{id}")
    assert Map.has_key?(spec["paths"], "/api/v1/{owner_slug}/workspaces/{slug}/bootstrap")

    assert Map.has_key?(
             spec["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/bootstrap"
           )

    assert Map.has_key?(
             spec["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/projects"
           )

    assert Map.has_key?(
             spec["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/projects/{project_id}"
           )

    assert Map.has_key?(spec["paths"], "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/tasks")

    assert Map.has_key?(
             spec["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/tasks/{task_id}"
           )

    assert Map.has_key?(
             spec["paths"],
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/activity"
           )

    assert get_in(spec, ["components", "schemas", "WorkspaceSummary", "properties", "full_path"]) ==
             %{
               "type" => "string",
               "nullable" => true
             }

    assert get_in(spec, ["components", "schemas", "FolioAppScope"])["required"] == [
             "app_key",
             "workspace",
             "owner",
             "app",
             "capabilities",
             "app_path"
           ]

    assert get_in(spec, [
             "components",
             "schemas",
             "FolioAppBootstrap",
             "properties",
             "scope",
             "$ref"
           ]) ==
             "#/components/schemas/FolioAppScope"

    assert get_in(spec, ["components", "schemas", "FolioAppBootstrap", "required"]) ==
             ["scope", "summary_counts"]

    assert get_in(spec, [
             "components",
             "schemas",
             "FolioProjectsResponse",
             "properties",
             "projects"
           ])["type"] ==
             "array"

    assert get_in(spec, ["components", "schemas", "FolioTasksResponse", "properties", "tasks"])[
             "type"
           ] ==
             "array"

    assert get_in(spec, [
             "paths",
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/tasks",
             "post",
             "requestBody",
             "content",
             "application/json",
             "schema",
             "$ref"
           ]) == "#/components/schemas/FolioTaskCreateRequest"

    assert get_in(spec, [
             "paths",
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/tasks",
             "post",
             "responses",
             "201",
             "content",
             "application/json",
             "schema",
             "$ref"
           ]) == "#/components/schemas/FolioTaskCreateResponse"

    assert get_in(spec, ["components", "schemas", "FolioTaskCreateResponse", "required"]) == [
             "scope",
             "task"
           ]

    assert get_in(spec, [
             "components",
             "schemas",
             "FolioProjectUpdateRequest",
             "properties",
             "status",
             "enum"
           ]) == ["active", "on_hold", "completed", "canceled", "archived"]

    assert get_in(spec, [
             "paths",
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/tasks/{task_id}",
             "patch",
             "requestBody",
             "content",
             "application/json",
             "schema",
             "$ref"
           ]) == "#/components/schemas/FolioTaskMutationRequest"

    assert get_in(spec, [
             "paths",
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/tasks/{task_id}",
             "patch",
             "responses",
             "200",
             "content",
             "application/json",
             "schema",
             "$ref"
           ]) == "#/components/schemas/FolioTaskCreateResponse"

    assert get_in(spec, ["components", "schemas", "FolioTaskTransitionRequest", "required"]) == [
             "status"
           ]

    assert get_in(spec, ["components", "schemas", "FolioTaskDelegationRequest", "required"]) == [
             "intent",
             "delegated_summary"
           ]

    assert get_in(spec, [
             "components",
             "schemas",
             "FolioTaskMutationRequest",
             "oneOf"
           ]) == [
             %{"$ref" => "#/components/schemas/FolioTaskTransitionRequest"},
             %{"$ref" => "#/components/schemas/FolioTaskDelegationRequest"}
           ]

    assert get_in(spec, ["components", "schemas", "FolioActivityResponse", "required"]) == [
             "scope",
             "events"
           ]

    assert get_in(spec, ["components", "schemas", "FolioActivityResponse", "properties", "events"])[
             "type"
           ] ==
             "array"

    assert is_map(
             get_in(spec, ["components", "schemas", "WorkspaceBootstrap", "properties", "apps"])
           )

    assert get_in(spec, ["components", "schemas", "WorkspaceApp"])["required"] == [
             "key",
             "label",
             "default_path",
             "enabled",
             "capabilities"
           ]
  end

  test "swagger ui is exposed for the v1 json api", %{conn: conn} do
    conn = get(conn, "/api/v1/swaggerui")

    assert html_response(conn, 200) =~ "/api/v1/open_api"
  end

  test "authenticated clients can list and fetch workspaces through the v1 json api", %{
    conn: conn
  } do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "API Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    index_conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/vnd.api+json")
      |> get("/api/v1/workspaces")

    index_payload = json_response(index_conn, 200)

    assert [
             %{
               "id" => workspace_id,
               "type" => "workspace",
               "attributes" => %{
                 "name" => "API Workspace",
                 "slug" => workspace_slug,
                 "owner_type" => "user",
                 "visibility" => "private"
               }
             }
           ] = index_payload["data"]

    assert workspace_id == workspace.id
    assert workspace_slug == workspace.slug
    refute Map.has_key?(hd(index_payload["data"])["attributes"], "owner_id")
    refute Map.has_key?(hd(index_payload["data"])["attributes"], "settings")

    show_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/vnd.api+json")
      |> get("/api/v1/workspaces/#{workspace.id}")

    show_payload = json_response(show_conn, 200)

    assert show_payload["data"]["id"] == workspace.id
    assert show_payload["data"]["type"] == "workspace"
    assert show_payload["data"]["attributes"]["name"] == "API Workspace"
    refute Map.has_key?(show_payload["data"]["attributes"], "owner_id")
    refute Map.has_key?(show_payload["data"]["attributes"], "settings")
  end

  test "public workspace json api does not expose internal owner ids or settings", %{conn: conn} do
    owner = register_user()

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Public API Workspace",
          owner_type: :user,
          owner_id: owner.id,
          visibility: :public
        },
        actor: owner
      )

    public_workspace =
      Workspaces.update_workspace!(workspace, %{settings: %{theme: "field-notes"}}, actor: owner)

    index_conn =
      conn
      |> put_req_header("accept", "application/vnd.api+json")
      |> get("/api/v1/workspaces")

    index_payload = json_response(index_conn, 200)

    assert [
             %{
               "id" => workspace_id,
               "type" => "workspace",
               "attributes" => attributes
             }
           ] = index_payload["data"]

    assert workspace_id == public_workspace.id
    assert attributes["name"] == "Public API Workspace"
    assert attributes["slug"] == public_workspace.slug
    assert attributes["owner_type"] == "user"
    assert attributes["visibility"] == "public"
    refute Map.has_key?(attributes, "owner_id")
    refute Map.has_key?(attributes, "settings")

    show_conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> get("/api/v1/workspaces/#{public_workspace.id}")

    show_payload = json_response(show_conn, 200)

    assert show_payload["data"]["id"] == public_workspace.id
    assert show_payload["data"]["attributes"]["name"] == "Public API Workspace"
    refute Map.has_key?(show_payload["data"]["attributes"], "owner_id")
    refute Map.has_key?(show_payload["data"]["attributes"], "settings")
  end

  test "authenticated clients can fetch a user workspace bootstrap payload", %{conn: conn} do
    owner = register_user()
    api_key = create_api_key(owner)

    current_workspace =
      Workspaces.create_workspace!(
        %{
          name: "Bootstrap Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    secondary_workspace =
      Workspaces.create_workspace!(
        %{
          name: "Secondary Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{current_workspace.slug}/bootstrap")

    payload = json_response(conn, 200)

    assert payload["current_user"]["username"] == owner.username
    assert payload["workspace"]["id"] == current_workspace.id
    assert payload["workspace"]["slug"] == current_workspace.slug

    assert payload["workspace"]["dashboard_path"] ==
             "/#{owner.owner_slug}/#{current_workspace.slug}"

    assert payload["owner"]["type"] == "user"
    assert payload["owner"]["slug"] == owner.owner_slug

    assert payload["capabilities"] == %{
             "manage_folio" => true,
             "manage_workspace" => true,
             "read_folio" => true,
             "read_workspace" => true
           }

    assert payload["apps"] == %{
             "folio" => %{
               "capabilities" => %{"manage" => true, "read" => true},
               "default_path" => "/#{owner.owner_slug}/#{current_workspace.slug}/apps/folio",
               "enabled" => true,
               "key" => "folio",
               "label" => "Folio"
             }
           }

    assert payload["workspace"]["dashboard_path"] ==
             "/#{owner.owner_slug}/#{current_workspace.slug}"

    assert payload["apps"]["folio"]["default_path"] ==
             "/#{owner.owner_slug}/#{current_workspace.slug}/apps/folio"

    assert payload["apps"]["folio"]["default_path"] ==
             "#{payload["workspace"]["dashboard_path"]}/apps/folio"

    assert Enum.any?(payload["accessible_workspaces"], fn workspace ->
             workspace["slug"] == current_workspace.slug and workspace["current?"]
           end)

    assert Enum.any?(payload["accessible_workspaces"], fn workspace ->
             workspace["slug"] == secondary_workspace.slug and workspace["current?"] == false
           end)
  end

  test "workspace and folio bootstrap payloads keep app routes aligned", %{conn: conn} do
    owner = register_user(email: "bootstrap-routing-owner@example.com")
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Bootstrap Routing Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    workspace_payload =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/bootstrap")
      |> json_response(200)

    folio_payload =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/bootstrap")
      |> json_response(200)

    assert workspace_payload["apps"]["folio"]["key"] == "folio"

    assert workspace_payload["apps"]["folio"]["default_path"] ==
             folio_payload["scope"]["app_path"]

    assert workspace_payload["apps"]["folio"]["default_path"] ==
             folio_payload["scope"]["app"]["default_path"]

    assert workspace_payload["apps"]["folio"]["capabilities"] ==
             folio_payload["scope"]["app"]["capabilities"]
  end

  test "authenticated clients can fetch a folio bootstrap payload", %{conn: conn} do
    owner = register_user()
    api_key = create_api_key(owner)

    current_workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Bootstrap Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    EBossFolio.create_project!(%{workspace_id: current_workspace.id, title: "Mount Project"},
      actor: owner
    )

    EBossFolio.create_task!(%{workspace_id: current_workspace.id, title: "Mount Task"},
      actor: owner
    )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get(
        "/api/v1/#{owner.owner_slug}/workspaces/#{current_workspace.slug}/apps/folio/bootstrap"
      )

    payload = json_response(conn, 200)

    assert payload["scope"]["app_key"] == "folio"
    assert payload["scope"]["workspace"]["id"] == current_workspace.id
    assert payload["scope"]["owner"]["slug"] == owner.owner_slug
    assert payload["scope"]["app"]["key"] == "folio"
    assert payload["scope"]["capabilities"] == %{"read" => true, "manage" => true}

    assert payload["scope"]["app_path"] ==
             "/#{owner.owner_slug}/#{current_workspace.slug}/apps/folio"

    assert payload["scope"]["workspace_path"] ==
             "/#{owner.owner_slug}/#{current_workspace.slug}"

    assert payload["scope"]["app"] == %{
             "capabilities" => %{"manage" => true, "read" => true},
             "default_path" => "/#{owner.owner_slug}/#{current_workspace.slug}/apps/folio",
             "enabled" => true,
             "key" => "folio",
             "label" => "Folio"
           }

    refute Map.has_key?(payload, "current_user")
    refute Map.has_key?(payload, "apps")
    refute Map.has_key?(payload, "capabilities")

    assert payload["summary_counts"] == %{"projects" => 1, "tasks" => 1}
  end

  test "authenticated clients can list workspace projects through the folio projects endpoint", %{
    conn: conn
  } do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Projects Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    second_workspace =
      Workspaces.create_workspace!(
        %{
          name: "External Projects Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    active_project =
      EBossFolio.create_project!(
        %{workspace_id: workspace.id, title: "Active project", status: :active},
        actor: owner
      )

    archived_project =
      EBossFolio.create_project!(
        %{workspace_id: workspace.id, title: "Archived project", status: :archived},
        actor: owner
      )

    _foreign_project =
      EBossFolio.create_project!(
        %{workspace_id: second_workspace.id, title: "Foreign project"},
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects")

    payload = json_response(conn, 200)
    project_ids = Enum.map(payload["projects"], & &1["id"])

    assert payload["scope"]["app_key"] == "folio"
    assert payload["scope"]["workspace"]["id"] == workspace.id
    assert length(payload["projects"]) == 2
    assert active_project.id in project_ids
    assert archived_project.id in project_ids
    refute _foreign_project.id in project_ids

    assert Enum.any?(payload["projects"], fn project ->
             project["id"] == active_project.id and project["title"] == "Active project" and
               project["status"] == "active"
           end)
  end

  test "authenticated clients can create workspace projects through the folio projects endpoint",
       %{
         conn: conn
       } do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Project Create Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    second_workspace =
      Workspaces.create_workspace!(
        %{
          name: "External Project Create Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects",
        Jason.encode!(%{title: "Launch console"})
      )

    payload = json_response(conn, 201)
    project_id = payload["project"]["id"]

    assert payload["scope"]["app_key"] == "folio"
    assert payload["scope"]["workspace"]["id"] == workspace.id
    assert payload["project"]["title"] == "Launch console"
    assert payload["project"]["status"] == "active"

    assert {:ok, created_project} =
             EBossFolio.get_project_in_workspace(project_id, workspace.id, actor: owner)

    assert created_project.workspace_id == workspace.id
    assert created_project.title == "Launch console"

    assert {:error, :not_found} =
             EBossFolio.get_project_in_workspace(project_id, second_workspace.id, actor: owner)
  end

  test "authenticated clients can update workspace projects through the folio project endpoint",
       %{
         conn: conn
       } do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Project Update Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    project =
      EBossFolio.create_project!(
        %{workspace_id: workspace.id, title: "Launch console", description: "Initial scope"},
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> patch(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects/#{project.id}",
        Jason.encode!(%{
          title: "Launch orchestration console",
          description: "Drive launch readiness",
          due_at: "2026-06-01",
          review_at: "2026-06-15",
          notes: "Review dependencies weekly",
          metadata: %{
            "cadence" => "weekly",
            "stream" => "infra"
          }
        })
      )

    payload = json_response(conn, 200)

    assert payload["scope"]["app_key"] == "folio"
    assert payload["scope"]["workspace"]["id"] == workspace.id
    assert payload["project"]["id"] == project.id
    assert payload["project"]["title"] == "Launch orchestration console"
    assert payload["project"]["description"] == "Drive launch readiness"
    assert payload["project"]["notes"] == "Review dependencies weekly"
    assert payload["project"]["metadata"] == %{"cadence" => "weekly", "stream" => "infra"}
    assert payload["project"]["due_at"] =~ "2026-06-01"
    assert payload["project"]["review_at"] =~ "2026-06-15"

    assert {:ok, updated_project} =
             EBossFolio.get_project_in_workspace(project.id, workspace.id, actor: owner)

    assert updated_project.title == "Launch orchestration console"
    assert updated_project.description == "Drive launch readiness"
    assert updated_project.notes == "Review dependencies weekly"
    assert updated_project.metadata["cadence"] == "weekly"
    assert updated_project.metadata["stream"] == "infra"

    projects_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects")

    projects_payload = json_response(projects_conn, 200)

    assert Enum.any?(projects_payload["projects"], fn listed_project ->
             listed_project["id"] == project.id and
               listed_project["title"] == "Launch orchestration console" and
               listed_project["description"] == "Drive launch readiness" and
               listed_project["notes"] == "Review dependencies weekly"
           end)

    activity_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/activity")

    activity_payload = json_response(activity_conn, 200)

    assert Enum.any?(activity_payload["events"], fn event ->
             event["action"] == "update" and
               event["subject"]["type"] == "project" and
               event["subject"]["id"] == project.id and
               get_in(event, ["changes", "title", "after"]) == "Launch orchestration console" and
               get_in(event, ["changes", "description", "after"]) == "Drive launch readiness"
           end)
  end

  test "authenticated clients can transition workspace projects through the folio project endpoint",
       %{
         conn: conn
       } do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Project Transition Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    project =
      EBossFolio.create_project!(%{workspace_id: workspace.id, title: "Advance project status"},
        actor: owner
      )

    transition_conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> patch(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects/#{project.id}",
        Jason.encode!(%{status: "on_hold"})
      )

    transition_payload = json_response(transition_conn, 200)

    assert transition_payload["scope"]["app_key"] == "folio"
    assert transition_payload["project"]["id"] == project.id
    assert transition_payload["project"]["status"] == "on_hold"

    assert {:ok, transitioned_project} =
             EBossFolio.get_project_in_workspace(project.id, workspace.id, actor: owner)

    assert transitioned_project.status == :on_hold

    projects_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects")

    projects_payload = json_response(projects_conn, 200)

    assert Enum.any?(projects_payload["projects"], fn listed_project ->
             listed_project["id"] == project.id and listed_project["status"] == "on_hold"
           end)

    activity_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/activity")

    activity_payload = json_response(activity_conn, 200)

    assert Enum.any?(activity_payload["events"], fn event ->
             event["action"] == "transition" and
               event["subject"]["type"] == "project" and
               event["subject"]["id"] == project.id and
               get_in(event, ["changes", "status", "after"]) == "on_hold"
           end)
  end

  test "folio project transition endpoint reports invalid transitions clearly", %{conn: conn} do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Project Transition Validation Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    project =
      EBossFolio.create_project!(
        %{workspace_id: workspace.id, title: "Closed rollout", status: :completed},
        actor: owner
      )

    transition_conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> patch(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects/#{project.id}",
        Jason.encode!(%{status: "active"})
      )

    assert %{
             "error" => %{
               "code" => "invalid_project_transition",
               "message" => message
             }
           } = json_response(transition_conn, 400)

    assert message =~ "cannot transition project from completed to active"

    assert {:ok, unchanged_project} =
             EBossFolio.get_project_in_workspace(project.id, workspace.id, actor: owner)

    assert unchanged_project.status == :completed
  end

  test "folio project update endpoint rejects invalid project payloads", %{conn: conn} do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Project Update Invalid Payload Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    project =
      EBossFolio.create_project!(
        %{workspace_id: workspace.id, title: "Unchanged title"},
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> patch(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects/#{project.id}",
        Jason.encode!(%{title: "   ", metadata: []})
      )

    assert %{
             "error" => %{
               "code" => "invalid_project_payload",
               "message" => "Project payload could not be processed"
             }
           } = json_response(conn, 400)

    assert {:ok, unchanged_project} =
             EBossFolio.get_project_in_workspace(project.id, workspace.id, actor: owner)

    assert unchanged_project.title == "Unchanged title"
    assert unchanged_project.metadata == %{}
  end

  test "folio project update endpoint forbids users without folio manage access", %{conn: conn} do
    owner = register_user()
    member = register_user()

    organization =
      Organizations.create_organization!(%{name: "Folio Update-Locked Org Workspace"},
        actor: owner
      )

    create_org_membership(owner, organization, member, :member)

    owner_api_key = create_api_key(owner)
    member_api_key = create_api_key(member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Update-Locked Org Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    project =
      build_conn()
      |> put_req_header("authorization", "Bearer #{owner_api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/#{organization.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects",
        Jason.encode!(%{title: "Protected project"})
      )
      |> json_response(201)
      |> Map.fetch!("project")
      |> Map.fetch!("id")

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{member_api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> patch(
        "/api/v1/#{organization.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects/#{project}",
        Jason.encode!(%{title: "Blocked update"})
      )

    assert %{
             "error" => %{
               "code" => "workspace_forbidden",
               "message" => "Workspace access is forbidden"
             }
           } = json_response(conn, 403)
  end

  test "folio project create endpoint rejects invalid project payloads", %{conn: conn} do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Project Invalid Payload Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects",
        Jason.encode!(%{title: "   "})
      )

    assert %{
             "error" => %{
               "code" => "invalid_project_payload",
               "message" => "Project payload could not be processed"
             }
           } = json_response(conn, 400)

    assert {:ok, []} = EBossFolio.list_projects_in_workspace(workspace.id, actor: owner)
  end

  test "folio project create endpoint forbids users without folio manage access", %{conn: conn} do
    owner = register_user()
    member = register_user()

    organization =
      Organizations.create_organization!(%{name: "Folio Create-Locked Org Workspace"},
        actor: owner
      )

    create_org_membership(owner, organization, member, :member)

    api_key = create_api_key(member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Create-Locked Org Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/#{organization.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects",
        Jason.encode!(%{title: "Blocked project"})
      )

    assert %{
             "error" => %{
               "code" => "workspace_forbidden",
               "message" => "Workspace access is forbidden"
             }
           } = json_response(conn, 403)
  end

  test "authenticated clients can list workspace tasks through the folio tasks endpoint", %{
    conn: conn
  } do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Tasks Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    second_workspace =
      Workspaces.create_workspace!(
        %{
          name: "External Tasks Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    linked_project =
      EBossFolio.create_project!(
        %{workspace_id: workspace.id, title: "Task detail project"},
        actor: owner
      )

    inbox_task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "Inbox task"}, actor: owner)

    linked_task =
      EBossFolio.create_task!(
        %{
          workspace_id: workspace.id,
          title: "Task tied to project",
          status: :next_action,
          project_id: linked_project.id
        },
        actor: owner
      )

    _foreign_task =
      EBossFolio.create_task!(%{workspace_id: second_workspace.id, title: "Foreign task"},
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks")

    payload = json_response(conn, 200)
    task_ids = Enum.map(payload["tasks"], & &1["id"])

    assert payload["scope"]["app_key"] == "folio"
    assert payload["scope"]["workspace"]["id"] == workspace.id
    assert length(payload["tasks"]) == 2
    assert inbox_task.id in task_ids
    assert linked_task.id in task_ids
    refute _foreign_task.id in task_ids

    assert Enum.any?(payload["tasks"], fn task ->
             task["id"] == linked_task.id and
               task["title"] == "Task tied to project" and
               task["project_id"] == linked_project.id and
               task["status"] == "next_action"
           end)
  end

  test "authenticated clients can create workspace tasks through the folio tasks endpoint", %{
    conn: conn
  } do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Task Create Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    second_workspace =
      Workspaces.create_workspace!(
        %{
          name: "External Task Create Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    linked_project =
      EBossFolio.create_project!(
        %{workspace_id: workspace.id, title: "Task Linking Project"},
        actor: owner
      )

    linked_task_conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks",
        Jason.encode!(%{title: "Draft rollout notes", project_id: linked_project.id})
      )

    linked_payload = json_response(linked_task_conn, 201)
    linked_task_id = linked_payload["task"]["id"]

    assert linked_payload["scope"]["app_key"] == "folio"
    assert linked_payload["scope"]["workspace"]["id"] == workspace.id
    assert linked_payload["task"]["title"] == "Draft rollout notes"
    assert linked_payload["task"]["status"] == "inbox"
    assert linked_payload["task"]["project_id"] == linked_project.id

    standalone_task_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks",
        Jason.encode!(%{title: "Inbox capture"})
      )

    standalone_payload = json_response(standalone_task_conn, 201)
    standalone_task_id = standalone_payload["task"]["id"]

    assert standalone_payload["task"]["title"] == "Inbox capture"
    assert standalone_payload["task"]["status"] == "inbox"
    assert standalone_payload["task"]["project_id"] == nil

    assert {:ok, linked_task} =
             EBossFolio.get_task_in_workspace(linked_task_id, workspace.id, actor: owner)

    assert linked_task.workspace_id == workspace.id
    assert linked_task.project_id == linked_project.id
    assert linked_task.title == "Draft rollout notes"

    assert {:ok, standalone_task} =
             EBossFolio.get_task_in_workspace(standalone_task_id, workspace.id, actor: owner)

    assert standalone_task.workspace_id == workspace.id
    assert standalone_task.project_id == nil
    assert standalone_task.title == "Inbox capture"

    assert {:error, :not_found} =
             EBossFolio.get_task_in_workspace(linked_task_id, second_workspace.id, actor: owner)
  end

  test "authenticated clients can transition workspace tasks through the folio task endpoint", %{
    conn: conn
  } do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Task Transition Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "Advance status"},
        actor: owner
      )

    transition_conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> patch(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks/#{task.id}",
        Jason.encode!(%{status: "done"})
      )

    transition_payload = json_response(transition_conn, 200)

    assert transition_payload["scope"]["app_key"] == "folio"
    assert transition_payload["task"]["id"] == task.id
    assert transition_payload["task"]["status"] == "done"

    assert {:ok, transitioned_task} =
             EBossFolio.get_task_in_workspace(task.id, workspace.id, actor: owner)

    assert transitioned_task.status == :done

    tasks_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks")

    tasks_payload = json_response(tasks_conn, 200)

    assert Enum.any?(tasks_payload["tasks"], fn listed_task ->
             listed_task["id"] == task.id and listed_task["status"] == "done"
           end)

    activity_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/activity")

    activity_payload = json_response(activity_conn, 200)

    assert Enum.any?(activity_payload["events"], fn event ->
             event["action"] == "transition" and
               event["subject"]["type"] == "task" and
               event["subject"]["id"] == task.id and
               get_in(event, ["changes", "status", "after"]) == "done"
           end)
  end

  test "authenticated clients can delegate workspace tasks through the folio task endpoint", %{
    conn: conn
  } do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Task Delegation Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "Follow up with vendor"},
        actor: owner
      )

    delegate_conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> patch(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks/#{task.id}",
        Jason.encode!(%{
          intent: "delegate",
          contact_name: "Avery Partner",
          delegated_summary: "Send the revised estimate package",
          quality_expectations: "Include licensing constraints in the response",
          follow_up_at: "2026-05-01",
          deadline_expectations_at: "2026-05-07"
        })
      )

    delegate_payload = json_response(delegate_conn, 200)

    assert delegate_payload["scope"]["app_key"] == "folio"
    assert delegate_payload["task"]["id"] == task.id
    assert delegate_payload["task"]["status"] == "waiting_for"
    assert delegate_payload["task"]["active_delegation"]["status"] == "active"

    assert delegate_payload["task"]["active_delegation"]["delegated_summary"] ==
             "Send the revised estimate package"

    assert delegate_payload["task"]["active_delegation"]["contact"]["name"] == "Avery Partner"

    assert String.starts_with?(
             delegate_payload["task"]["active_delegation"]["follow_up_at"],
             "2026-05-01"
           )

    assert String.starts_with?(
             delegate_payload["task"]["active_delegation"]["deadline_expectations_at"],
             "2026-05-07"
           )

    assert {:ok, delegated_task} =
             EBossFolio.get_task_in_workspace(task.id, workspace.id,
               actor: owner,
               load: [delegations: :contact]
             )

    assert delegated_task.status == :waiting_for

    assert Enum.any?(delegated_task.delegations, fn delegation ->
             delegation.status == :active and
               delegation.delegated_summary == "Send the revised estimate package" and
               delegation.contact.name == "Avery Partner"
           end)

    tasks_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks")

    tasks_payload = json_response(tasks_conn, 200)

    assert Enum.any?(tasks_payload["tasks"], fn listed_task ->
             listed_task["id"] == task.id and
               listed_task["status"] == "waiting_for" and
               listed_task["active_delegation"]["status"] == "active" and
               get_in(listed_task, ["active_delegation", "contact", "name"]) == "Avery Partner"
           end)

    activity_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/activity")

    activity_payload = json_response(activity_conn, 200)

    assert Enum.any?(activity_payload["events"], fn event ->
             event["action"] == "create" and event["subject"]["type"] == "delegation"
           end)

    assert Enum.any?(activity_payload["events"], fn event ->
             event["action"] == "transition" and
               event["subject"]["type"] == "task" and
               event["subject"]["id"] == task.id and
               get_in(event, ["changes", "status", "after"]) == "waiting_for"
           end)
  end

  test "folio task transition endpoint reports invalid transitions clearly", %{conn: conn} do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Task Transition Validation Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "Blocked follow-up"},
        actor: owner
      )

    transition_conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> patch(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks/#{task.id}",
        Jason.encode!(%{status: "waiting_for"})
      )

    assert %{
             "error" => %{
               "code" => "invalid_task_transition",
               "message" => message
             }
           } = json_response(transition_conn, 400)

    assert message =~ "waiting_for tasks require notes or an active delegation"

    assert {:ok, unchanged_task} =
             EBossFolio.get_task_in_workspace(task.id, workspace.id, actor: owner)

    assert unchanged_task.status == :inbox
  end

  test "folio task create endpoint rejects invalid task payloads", %{conn: conn} do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Task Invalid Payload Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks",
        Jason.encode!(%{title: "   ", project_id: []})
      )

    assert %{
             "error" => %{
               "code" => "invalid_task_payload",
               "message" => "Task payload could not be processed"
             }
           } = json_response(conn, 400)

    assert {:ok, []} = EBossFolio.list_tasks_in_workspace(workspace.id, actor: owner)
  end

  test "folio task create endpoint forbids users without folio manage access", %{conn: conn} do
    owner = register_user()
    member = register_user()

    organization =
      Organizations.create_organization!(%{name: "Folio Task Create-Locked Org Workspace"},
        actor: owner
      )

    create_org_membership(owner, organization, member, :member)

    api_key = create_api_key(member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Task Create-Locked Org Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/#{organization.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks",
        Jason.encode!(%{title: "Blocked task"})
      )

    assert %{
             "error" => %{
               "code" => "workspace_forbidden",
               "message" => "Workspace access is forbidden"
             }
           } = json_response(conn, 403)
  end

  test "folio task transition endpoint forbids users without folio manage access", %{conn: conn} do
    owner = register_user()
    member = register_user()

    organization =
      Organizations.create_organization!(%{name: "Folio Task Transition-Locked Org"},
        actor: owner
      )

    create_org_membership(owner, organization, member, :member)

    owner_api_key = create_api_key(owner)
    member_api_key = create_api_key(member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Task Transition-Locked Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    task_id =
      build_conn()
      |> put_req_header("authorization", "Bearer #{owner_api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/#{organization.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks",
        Jason.encode!(%{title: "Member cannot transition this"})
      )
      |> json_response(201)
      |> Map.fetch!("task")
      |> Map.fetch!("id")

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{member_api_key}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
      |> patch(
        "/api/v1/#{organization.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks/#{task_id}",
        Jason.encode!(%{status: "done"})
      )

    assert %{
             "error" => %{
               "code" => "workspace_forbidden",
               "message" => "Workspace access is forbidden"
             }
           } = json_response(conn, 403)
  end

  test "authenticated clients can list workspace activity through the folio activity endpoint", %{
    conn: conn
  } do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Activity Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    area =
      EBossFolio.create_area!(
        %{workspace_id: workspace.id, name: "Ops area"},
        actor: owner
      )

    _updated_area =
      EBossFolio.update_area!(
        area,
        %{description: "Operational activity"},
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/apps/folio/activity")

    payload = json_response(conn, 200)
    event_actions = Enum.map(payload["events"], & &1["action"])

    assert payload["scope"]["app_key"] == "folio"
    assert payload["scope"]["workspace"]["id"] == workspace.id
    assert is_list(payload["events"])
    assert length(payload["events"]) >= 2
    assert "create" in event_actions
    assert "update" in event_actions

    assert Enum.any?(payload["events"], fn event ->
             event["app_key"] == "folio" and
               event["provider_key"] == "revision_event" and
               event["subject"]["type"] == "area" and
               event["subject"]["id"] == area.id
           end)
  end

  test "folio projects endpoint forbids users without folio read access", %{conn: conn} do
    owner = register_user()
    member = register_user()

    organization =
      Organizations.create_organization!(%{name: "Folio Read-Locked Org Workspace"}, actor: owner)

    create_org_membership(owner, organization, member, :member)

    api_key = create_api_key(member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Read-Locked Org Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get(
        "/api/v1/#{organization.owner_slug}/workspaces/#{workspace.slug}/apps/folio/projects"
      )

    assert %{
             "error" => %{
               "code" => "workspace_forbidden",
               "message" => "Workspace access is forbidden"
             }
           } = json_response(conn, 403)
  end

  test "folio tasks endpoint forbids users without folio read access", %{conn: conn} do
    owner = register_user()
    member = register_user()

    organization =
      Organizations.create_organization!(%{name: "Folio Read-Locked Org Workspace"}, actor: owner)

    create_org_membership(owner, organization, member, :member)

    api_key = create_api_key(member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Read-Locked Org Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{organization.owner_slug}/workspaces/#{workspace.slug}/apps/folio/tasks")

    assert %{
             "error" => %{
               "code" => "workspace_forbidden",
               "message" => "Workspace access is forbidden"
             }
           } = json_response(conn, 403)
  end

  test "folio activity endpoint forbids users without folio read access", %{conn: conn} do
    owner = register_user()
    member = register_user()

    organization =
      Organizations.create_organization!(%{name: "Folio Read-Locked Org Workspace"}, actor: owner)

    create_org_membership(owner, organization, member, :member)

    api_key = create_api_key(member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Read-Locked Org Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get(
        "/api/v1/#{organization.owner_slug}/workspaces/#{workspace.slug}/apps/folio/activity"
      )

    assert %{
             "error" => %{
               "code" => "workspace_forbidden",
               "message" => "Workspace access is forbidden"
             }
           } = json_response(conn, 403)
  end

  test "folio bootstrap endpoints forbid users without folio read access", %{conn: conn} do
    owner = register_user()
    member = register_user()
    organization = Organizations.create_organization!(%{name: "Folio Org"}, actor: owner)

    create_org_membership(owner, organization, member, :member)

    api_key = create_api_key(member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Folio Read-Locked Org Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get(
        "/api/v1/#{organization.owner_slug}/workspaces/#{workspace.slug}/apps/folio/bootstrap"
      )

    assert %{
             "error" => %{
               "code" => "workspace_forbidden",
               "message" => "Workspace access is forbidden"
             }
           } = json_response(conn, 403)
  end

  test "organization members receive read-only org bootstrap capabilities", %{conn: conn} do
    owner = register_user()
    member = register_user()
    organization = Organizations.create_organization!(%{name: "Bootstrap Org"}, actor: owner)

    create_org_membership(owner, organization, member, :member)

    api_key = create_api_key(member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Bootstrap Org Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{organization.owner_slug}/workspaces/#{workspace.slug}/bootstrap")

    payload = json_response(conn, 200)

    assert payload["workspace"]["id"] == workspace.id
    assert payload["owner"]["type"] == "organization"
    assert payload["owner"]["slug"] == organization.owner_slug

    assert payload["capabilities"] == %{
             "manage_folio" => false,
             "manage_workspace" => false,
             "read_folio" => false,
             "read_workspace" => true
           }

    assert payload["apps"]["folio"]["enabled"] == false
    assert payload["apps"]["folio"]["capabilities"] == %{"read" => false, "manage" => false}

    assert [
             %{
               "slug" => workspace_slug,
               "current?" => true
             }
           ] = payload["accessible_workspaces"]

    assert workspace_slug == workspace.slug
  end

  test "bootstrap endpoints require authentication", %{conn: conn} do
    owner = register_user()

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Auth Required Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/bootstrap")

    assert %{
             "error" => %{
               "code" => "authentication_required",
               "message" => "Authentication is required"
             }
           } = json_response(conn, 401)
  end

  test "bootstrap endpoints return forbidden for inaccessible workspaces", %{conn: conn} do
    owner = register_user()
    outsider = register_user()
    api_key = create_api_key(outsider)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Forbidden Bootstrap Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/#{workspace.slug}/bootstrap")

    assert %{
             "error" => %{
               "code" => "workspace_forbidden",
               "message" => "Workspace access is forbidden"
             }
           } = json_response(conn, 403)
  end

  test "bootstrap endpoints return not found for unknown workspaces", %{conn: conn} do
    owner = register_user()
    api_key = create_api_key(owner)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/json")
      |> get("/api/v1/#{owner.owner_slug}/workspaces/missing-workspace/bootstrap")

    assert %{
             "error" => %{
               "code" => "workspace_not_found",
               "message" => "Workspace not found"
             }
           } = json_response(conn, 404)
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
