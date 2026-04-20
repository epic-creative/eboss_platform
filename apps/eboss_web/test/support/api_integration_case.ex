defmodule EBossWeb.ApiIntegrationCase do
  @moduledoc false

  use ExUnit.CaseTemplate
  import Phoenix.ConnTest
  import Plug.Conn

  alias AshAuthentication.Info

  @endpoint EBossWeb.Endpoint
  @session_cookie_key "_eboss_web_key"

  using do
    quote do
      use EBoss.DataCase, async: false

      alias EBoss.Accounts
      alias EBoss.Organizations
      alias EBoss.Workspaces

      import EBossWeb.ApiIntegrationCase
    end
  end

  setup_all do
    port = allocate_port()

    start_supervised!(
      {Bandit, plug: EBossWeb.Endpoint, scheme: :http, ip: {127, 0, 0, 1}, port: port}
    )

    wait_for_server(port)
    {:ok, base_url: "http://127.0.0.1:#{port}"}
  end

  setup %{base_url: base_url} do
    {:ok,
     req:
       Req.new(
         base_url: base_url,
         retry: false,
         receive_timeout: 1_000
       )}
  end

  def json_api_req(req, api_key) do
    Req.merge(req,
      headers: [
        {"authorization", "Bearer #{api_key}"},
        {"accept", "application/vnd.api+json"}
      ]
    )
  end

  def json_req(req) do
    Req.merge(req, headers: [{"accept", "application/json"}])
  end

  def register_user(overrides \\ %{}) do
    unique = System.unique_integer([:positive])

    params =
      Map.merge(
        %{
          email: "user#{unique}@example.com",
          username: "user#{unique}",
          password: "supersecret123",
          password_confirmation: "supersecret123"
        },
        overrides
      )

    EBoss.Accounts.register_with_password!(params, authorize?: false)
  end

  def create_api_key(user) do
    api_key =
      EBoss.Accounts.ApiKey
      |> Ash.Changeset.for_create(:create, %{
        user_id: user.id,
        expires_at: DateTime.add(DateTime.utc_now(), 3_600, :second)
      })
      |> Ash.create!(authorize?: false)

    api_key.__metadata__.plaintext_api_key
  end

  def browser_session_cookie_header(user, password \\ "supersecret123") do
    signed_in_user =
      EBoss.Accounts.sign_in_with_password!(
        %{email: user.email, password: password},
        authorize?: false
      )

    session_key = "#{Info.authentication_subject_name!(EBoss.Accounts.User)}_token"

    conn =
      build_conn()
      |> init_test_session(%{})
      |> put_session(session_key, signed_in_user.__metadata__.token)
      |> dispatch(@endpoint, :get, "/", %{})

    case Map.fetch(conn.resp_cookies, @session_cookie_key) do
      {:ok, cookie} -> "#{@session_cookie_key}=#{cookie.value}"
      :error -> raise "expected #{@session_cookie_key} cookie on authenticated browser session"
    end
  end

  def create_org_membership(owner, organization, user, role) do
    EBoss.Organizations.Membership
    |> Ash.Changeset.for_create(:create, %{
      organization_id: organization.id,
      user_id: user.id,
      role: role
    })
    |> Ash.create!(actor: owner)
  end

  defp wait_for_server(port, attempts \\ 20)

  defp wait_for_server(_port, 0) do
    raise "integration HTTP server did not boot in time"
  end

  defp wait_for_server(port, attempts) do
    case :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false], 200) do
      {:ok, socket} ->
        :ok = :gen_tcp.close(socket)

      {:error, _reason} ->
        Process.sleep(50)
        wait_for_server(port, attempts - 1)
    end
  end

  defp allocate_port do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
    {:ok, port} = :inet.port(socket)
    :ok = :gen_tcp.close(socket)
    port
  end
end
