defmodule EBossWeb.DashboardLiveTest do
  use ExUnit.Case, async: false
  use EBossWeb, :verified_routes

  import Phoenix.ConnTest
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

  test "dashboard live render mounts the workspace shell with serialized scope props" do
    current_user = %{username: "shell_user", email: "shell@example.com"}
    current_scope = DashboardScope.for_user(current_user, %{workspace_slug: "shell-workspace"})

    html =
      render_component(&EBossWeb.DashboardLive.render/1, %{
        flash: %{},
        current_scope: current_scope,
        current_user: current_user
      })

    assert html =~ ~s(data-shell-mode="workspace")
    assert html =~ ~s(data-name="ShellOperatorWorkspaceApp")
    assert html =~ ~s(data-ssr="false")
    assert html =~ current_scope.current_workspace.slug
    assert html =~ current_scope.current_workspace.name
    assert html =~ current_user.username
    assert html =~ "currentWorkspace"
    assert html =~ "accessibleWorkspaces"
    assert html =~ "capabilities"

    refute html =~ ~s(data-shell-mode="product")
  end

  test "dashboard route redirects anonymous visitors to sign-in" do
    assert {:error, {:redirect, %{to: "/sign-in"}}} = live(build_conn(), ~p"/dashboard")
  end
end
