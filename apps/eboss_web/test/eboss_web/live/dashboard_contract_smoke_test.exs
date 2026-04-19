defmodule EBossWeb.DashboardContractSmokeTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias EBossWeb.DashboardScope

  @endpoint EBossWeb.Endpoint

  setup do
    for app <- [:plug_crypto, :phoenix, :phoenix_html, :phoenix_live_view, :gettext] do
      {:ok, _} = Application.ensure_all_started(app)
    end

    if is_nil(Process.whereis(EBossWeb.Endpoint)) do
      start_supervised!(EBossWeb.Endpoint)
    end

    :ok
  end

  test "dashboard live render exposes the workspace shell props contract" do
    current_user = %{username: "contract_user", email: "contract@example.com"}
    current_scope = DashboardScope.for_user(current_user, %{workspace_slug: "contract-workspace"})

    html =
      render_component(&EBossWeb.DashboardLive.render/1, %{
        flash: %{},
        current_scope: current_scope,
        current_user: current_user
      })

    assert html =~ ~s(data-shell-mode="workspace")
    assert html =~ ~s(data-name="ShellOperatorWorkspaceApp")
    assert html =~ current_scope.current_workspace.slug
    assert html =~ current_scope.current_workspace.name
    assert html =~ current_user.username
    assert html =~ "currentWorkspace"
    assert html =~ "accessibleWorkspaces"
    assert html =~ "&quot;apps&quot;"
    assert html =~ "readFolio"
    assert html =~ "manageFolio"
  end
end
