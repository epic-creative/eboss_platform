defmodule EBossWeb.JsonApiHttpTest do
  use EBossWeb.ApiIntegrationCase

  @moduletag :integration

  alias EBossFolio

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
             "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/tasks"
           )
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
    assert user_response.body["capabilities"]["manage_folio"] == true
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
    assert org_response.body["capabilities"]["manage_folio"] == false
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
    assert response.body["summary_counts"] == %{"projects" => 1, "tasks" => 1}
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

  defp get_header(response, header) do
    response.headers
    |> Enum.filter(fn {key, _value} -> String.downcase(key) == String.downcase(header) end)
    |> Enum.flat_map(fn
      {_key, values} when is_list(values) -> values
      {_key, value} -> [value]
    end)
    |> List.first("")
  end
end
