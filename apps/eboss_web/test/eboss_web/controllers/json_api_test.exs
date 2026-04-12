defmodule EBossWeb.JsonApiTest do
  use EBossWeb.ConnCase, async: false

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
    assert Map.has_key?(spec["paths"], "/api/v1/users/{owner_handle}/workspaces/{slug}")
    assert Map.has_key?(spec["paths"], "/api/v1/orgs/{owner_handle}/workspaces/{slug}")
    assert Map.has_key?(spec["paths"], "/api/v1/users/{owner_handle}/workspaces/{slug}/bootstrap")
    assert Map.has_key?(spec["paths"], "/api/v1/orgs/{owner_handle}/workspaces/{slug}/bootstrap")
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
                 "owner_id" => owner_id,
                 "visibility" => "private"
               }
             }
           ] = index_payload["data"]

    assert workspace_id == workspace.id
    assert workspace_slug == workspace.slug
    assert owner_id == owner.id

    show_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/vnd.api+json")
      |> get("/api/v1/workspaces/#{workspace.id}")

    show_payload = json_response(show_conn, 200)

    assert show_payload["data"]["id"] == workspace.id
    assert show_payload["data"]["type"] == "workspace"
    assert show_payload["data"]["attributes"]["name"] == "API Workspace"
  end

  test "authenticated clients can fetch workspaces by user owner handle and slug", %{conn: conn} do
    owner = register_user()
    api_key = create_api_key(owner)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Owner Route Workspace",
          owner_type: :user,
          owner_id: owner.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/vnd.api+json")
      |> get("/api/v1/users/#{owner.username}/workspaces/#{workspace.slug}")

    payload = json_response(conn, 200)

    assert payload["data"]["id"] == workspace.id
    assert payload["data"]["attributes"]["slug"] == workspace.slug
    assert payload["data"]["attributes"]["owner_type"] == "user"
  end

  test "organization members can fetch workspaces by org handle and slug", %{conn: conn} do
    owner = register_user()
    member = register_user()
    organization = Organizations.create_organization!(%{name: "API Org"}, actor: owner)

    create_org_membership(owner, organization, member, :member)

    api_key = create_api_key(member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "Org Route Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{api_key}")
      |> put_req_header("accept", "application/vnd.api+json")
      |> get("/api/v1/orgs/#{organization.slug}/workspaces/#{workspace.slug}")

    payload = json_response(conn, 200)

    assert payload["data"]["id"] == workspace.id
    assert payload["data"]["attributes"]["slug"] == workspace.slug
    assert payload["data"]["attributes"]["owner_type"] == "organization"
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
      |> get("/api/v1/users/#{owner.username}/workspaces/#{current_workspace.slug}/bootstrap")

    payload = json_response(conn, 200)

    assert payload["current_user"]["username"] == owner.username
    assert payload["workspace"]["id"] == current_workspace.id
    assert payload["workspace"]["slug"] == current_workspace.slug

    assert payload["workspace"]["dashboard_path"] ==
             "/users/#{owner.username}/#{current_workspace.slug}/dashboard"

    assert payload["owner"]["type"] == "user"
    assert payload["owner"]["handle"] == owner.username

    assert payload["capabilities"] == %{
             "manage_folio" => true,
             "manage_workspace" => true,
             "read_folio" => true,
             "read_workspace" => true
           }

    assert Enum.any?(payload["accessible_workspaces"], fn workspace ->
             workspace["slug"] == current_workspace.slug and workspace["current?"]
           end)

    assert Enum.any?(payload["accessible_workspaces"], fn workspace ->
             workspace["slug"] == secondary_workspace.slug and workspace["current?"] == false
           end)
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
      |> get("/api/v1/orgs/#{organization.slug}/workspaces/#{workspace.slug}/bootstrap")

    payload = json_response(conn, 200)

    assert payload["workspace"]["id"] == workspace.id
    assert payload["owner"]["type"] == "organization"
    assert payload["owner"]["handle"] == organization.slug

    assert payload["capabilities"] == %{
             "manage_folio" => false,
             "manage_workspace" => false,
             "read_folio" => false,
             "read_workspace" => true
           }

    assert [
             %{
               "slug" => workspace_slug,
               "current?" => true
             }
           ] = payload["accessible_workspaces"]

    assert workspace_slug == workspace.slug
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
