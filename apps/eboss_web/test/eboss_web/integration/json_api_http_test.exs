defmodule EBossWeb.JsonApiHttpTest do
  use EBossWeb.ApiIntegrationCase

  @moduletag :integration

  test "open api is reachable over the external http surface", %{req: req} do
    response = Req.get!(json_req(req), url: "/api/v1/open_api")

    assert response.status == 200
    assert get_header(response, "content-type") =~ "application/json"
    assert Map.has_key?(response.body["paths"], "/api/v1/workspaces")
    assert Map.has_key?(response.body["paths"], "/api/v1/users/{owner_handle}/workspaces/{slug}")
    assert Map.has_key?(response.body["paths"], "/api/v1/orgs/{owner_handle}/workspaces/{slug}")

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/users/{owner_handle}/workspaces/{slug}/bootstrap"
           )

    assert Map.has_key?(
             response.body["paths"],
             "/api/v1/orgs/{owner_handle}/workspaces/{slug}/bootstrap"
           )
  end

  test "user-owned workspaces are reachable over http by id and owner handle route", %{req: req} do
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

    natural_key_response =
      Req.get!(authed_req, url: "/api/v1/users/#{owner.username}/workspaces/#{workspace.slug}")

    assert natural_key_response.status == 200
    assert natural_key_response.body["data"]["id"] == workspace.id
    assert natural_key_response.body["data"]["attributes"]["slug"] == workspace.slug
    assert natural_key_response.body["data"]["attributes"]["owner_type"] == "user"
  end

  test "organization workspaces are reachable over http by org handle route", %{req: req} do
    owner = register_user()
    member = register_user()
    organization = Organizations.create_organization!(%{name: "External API Org"}, actor: owner)

    create_org_membership(owner, organization, member, :member)

    api_key = create_api_key(member)

    workspace =
      Workspaces.create_workspace!(
        %{
          name: "External Org Workspace",
          owner_type: :organization,
          owner_id: organization.id
        },
        actor: owner
      )

    response =
      req
      |> json_api_req(api_key)
      |> Req.get!(url: "/api/v1/orgs/#{organization.slug}/workspaces/#{workspace.slug}")

    assert response.status == 200
    assert response.body["data"]["id"] == workspace.id
    assert response.body["data"]["attributes"]["owner_type"] == "organization"
    assert response.body["data"]["attributes"]["slug"] == workspace.slug
  end

  test "workspace bootstrap endpoints are reachable over http for user and org routes", %{
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
      |> Req.get!(
        url: "/api/v1/users/#{owner.username}/workspaces/#{user_workspace.slug}/bootstrap"
      )

    assert user_response.status == 200
    assert user_response.body["workspace"]["slug"] == user_workspace.slug
    assert user_response.body["capabilities"]["manage_folio"] == true
    assert user_response.body["owner"]["handle"] == owner.username

    org_response =
      req
      |> Req.merge(
        headers: [{"authorization", "Bearer #{member_api_key}"}, {"accept", "application/json"}]
      )
      |> Req.get!(
        url: "/api/v1/orgs/#{organization.slug}/workspaces/#{org_workspace.slug}/bootstrap"
      )

    assert org_response.status == 200
    assert org_response.body["workspace"]["slug"] == org_workspace.slug
    assert org_response.body["capabilities"]["manage_folio"] == false
    assert org_response.body["owner"]["handle"] == organization.slug
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
