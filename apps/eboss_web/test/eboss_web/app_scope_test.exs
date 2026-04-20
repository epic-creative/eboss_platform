defmodule EBossWeb.AppScopeTest do
  use EBossWeb.ConnCase, async: false

  alias EBossWeb.AppScope

  test "bootstrap payload exposes a stable app registry map" do
    scope =
      %AppScope{
        current_user: %{
          id: "owner-id",
          email: "owner@example.com",
          username: "owner",
          role: "owner"
        },
        current_workspace: %{
          id: "workspace-id",
          name: "Bootstrap Workspace",
          slug: "bootstrap-workspace",
          full_path: "/owner/bootstrap-workspace",
          visibility: :private,
          owner_type: :user,
          owner_id: "owner-id",
          owner_slug: "owner",
          owner_display_name: "Owner",
          dashboard_path: "/owner/bootstrap-workspace"
        },
        owner: %{
          type: "user",
          id: "owner-id",
          slug: "owner",
          display_name: "Owner"
        },
        capabilities: %{
          read_workspace: true,
          manage_workspace: true,
          read_folio: true,
          manage_folio: false
        },
        apps: %{
          "folio" => %{
            key: "folio",
            label: "Folio",
            default_path: "/owner/bootstrap-workspace/apps/folio",
            enabled: true,
            capabilities: %{read: true, manage: false}
          },
          "insights" => %{
            key: "insights",
            label: "Workspace Insights",
            default_path: "/owner/bootstrap-workspace/apps/insights",
            enabled: false,
            capabilities: %{read: false, manage: false}
          }
        },
        accessible_workspaces: [],
        dashboard_path: "/owner/bootstrap-workspace",
        empty?: false
      }

    payload = AppScope.bootstrap_payload(scope)

    assert payload.apps["folio"]["key"] == "folio"
    assert payload.apps["insights"]["label"] == "Workspace Insights"
    assert map_size(payload.apps) == 2
    assert payload.apps["folio"]["capabilities"]["read"] == true
  end

  test "workspace bootstrap payload disables folio app when org members lack folio capability" do
    owner = register_user()
    member = register_user()

    {organization, workspace} =
      create_org_workspace(owner, %{
        name: "App Scope Test Org",
        workspace_name: "App Scope Test Workspace"
      })

    create_org_membership(owner, organization, member, :member)

    assert {:ok, scope} =
             AppScope.fetch_workspace_scope(member, organization.owner_slug, workspace.slug)

    payload = AppScope.bootstrap_payload(scope)

    assert payload.apps["folio"]["enabled"] == false
    assert payload.apps["folio"]["capabilities"] == %{"read" => false, "manage" => false}

    assert payload.apps["folio"]["default_path"] ==
             "#{dashboard_path(organization.owner_slug, workspace.slug)}/apps/folio"
  end
end
