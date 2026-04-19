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

    assert Map.has_key?(spec["paths"], "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/tasks")

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
