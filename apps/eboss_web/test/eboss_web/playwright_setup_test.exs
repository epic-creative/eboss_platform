defmodule EBossWeb.PlaywrightSetupTest do
  use EBoss.DataCase, async: false

  import Phoenix.ConnTest

  alias EBoss.Accounts
  alias EBossWeb.Endpoint
  alias EBossWeb.PlaywrightSetup

  test "prepare! writes deterministic public and authenticated storage state" do
    state_dir =
      Path.join(System.tmp_dir!(), "eboss-playwright-#{System.unique_integer([:positive])}")

    base_url = "http://127.0.0.1:4002"

    summary = PlaywrightSetup.prepare!(state_dir: state_dir, base_url: base_url)

    assert summary.credentials.email == "playwright-auth@localhost"
    assert summary.credentials.username == "playwright-auth-user"
    assert summary.credentials.password == "playwright-pass-123"

    assert summary.user.email |> to_string() == summary.credentials.email
    assert summary.user.username == summary.credentials.username
    assert summary.workspace.slug == "playwright-workspace"
    assert summary.dashboard_path == "/playwright-auth-user/playwright-workspace"

    public_state = read_json!(summary.public_storage_state_path)
    authenticated_state = read_json!(summary.authenticated_storage_state_path)
    metadata = read_json!(summary.metadata_path)

    assert public_state == %{"cookies" => [], "origins" => []}

    assert %{
             "cookies" => [
               %{
                 "name" => "_eboss_web_key",
                 "domain" => "127.0.0.1",
                 "path" => "/",
                 "expires" => -1,
                 "httpOnly" => true,
                 "sameSite" => "Lax",
                 "secure" => false,
                 "value" => value
               }
             ],
             "origins" => []
           } = authenticated_state

    assert is_binary(value)
    assert value != ""

    dashboard_redirect_conn =
      build_conn()
      |> put_req_cookie("_eboss_web_key", value)
      |> dispatch(Endpoint, :get, "/dashboard", %{})

    assert redirected_to(dashboard_redirect_conn) == summary.dashboard_path

    dashboard_conn =
      build_conn()
      |> put_req_cookie("_eboss_web_key", value)
      |> dispatch(Endpoint, :get, summary.dashboard_path, %{})

    assert dashboard_conn.status == 200
    assert to_string(dashboard_conn.assigns.current_user.email) == summary.credentials.email

    dashboard_html = html_response(dashboard_conn, 200)

    assert dashboard_html =~ ~s(data-name="ShellOperatorWorkspaceApp")
    assert dashboard_html =~ "playwright-auth-user"
    assert dashboard_html =~ "playwright-workspace"

    assert metadata == %{
             "base_url" => base_url,
             "dashboard_path" => summary.dashboard_path,
             "storage_state" => %{
               "authenticated" => summary.authenticated_storage_state_path,
               "public" => summary.public_storage_state_path
             },
             "user" => %{
               "email" => summary.credentials.email,
               "username" => summary.credentials.username
             },
             "workspace" => %{
               "name" => "Playwright Workspace",
               "owner_slug" => summary.credentials.username,
               "slug" => "playwright-workspace"
             }
           }

    assert %{} =
             Accounts.sign_in_with_password!(
               %{
                 email: summary.credentials.email,
                 password: summary.credentials.password
               },
               authorize?: false
             )

    rerun = PlaywrightSetup.prepare!(state_dir: state_dir, base_url: base_url)

    assert rerun.user.email == summary.user.email
    assert rerun.user.username == summary.user.username
    assert rerun.workspace.slug == summary.workspace.slug
    assert rerun.dashboard_path == summary.dashboard_path
    assert File.exists?(rerun.public_storage_state_path)
    assert File.exists?(rerun.authenticated_storage_state_path)
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> Jason.decode!()
  end
end
