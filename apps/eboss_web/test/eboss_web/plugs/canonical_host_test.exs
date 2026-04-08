defmodule EBossWeb.Plugs.CanonicalHostTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  alias EBossWeb.Plugs.CanonicalHost

  setup do
    endpoint_config = Application.fetch_env!(:eboss_web, EBossWeb.Endpoint)

    on_exit(fn ->
      Application.put_env(:eboss_web, EBossWeb.Endpoint, endpoint_config)
    end)

    :ok
  end

  test "redirects localhost to the local canonical host" do
    put_endpoint_config(canonical_host: "local.eboss.ai")

    conn =
      :get
      |> conn("/dev/live_vue?debug=1")
      |> Map.put(:host, "localhost")
      |> Map.put(:port, 4000)
      |> CanonicalHost.call([])

    assert conn.status == 301
    assert conn.halted

    assert get_resp_header(conn, "location") == [
             "http://local.eboss.ai:4000/dev/live_vue?debug=1"
           ]
  end

  test "redirects to the stage canonical host behind a proxy" do
    put_endpoint_config(canonical_host: "stage.eboss.ai")

    conn =
      :get
      |> conn("/health")
      |> Map.put(:host, "preview.internal")
      |> Map.put(:port, 4000)
      |> put_req_header("x-forwarded-proto", "https")
      |> put_req_header("x-forwarded-port", "443")
      |> CanonicalHost.call([])

    assert conn.status == 301
    assert get_resp_header(conn, "location") == ["https://stage.eboss.ai/health"]
  end

  test "redirects to the production canonical host behind a proxy" do
    put_endpoint_config(canonical_host: "eboss.ai")

    conn =
      :get
      |> conn("/status")
      |> Map.put(:host, "old.eboss.ai")
      |> Map.put(:port, 4000)
      |> put_req_header("x-forwarded-proto", "https")
      |> put_req_header("x-forwarded-port", "443")
      |> CanonicalHost.call([])

    assert conn.status == 301
    assert get_resp_header(conn, "location") == ["https://eboss.ai/status"]
  end

  test "skips redirects when canonical host is disabled" do
    put_endpoint_config(canonical_host_enabled: false, canonical_host: "local.eboss.ai")

    conn =
      :get
      |> conn("/")
      |> Map.put(:host, "localhost")
      |> CanonicalHost.call([])

    refute conn.halted
    assert conn.status in [nil, 200]
  end

  test "skips redirects for passthrough hosts" do
    put_endpoint_config(
      canonical_host: "local.eboss.ai",
      canonical_host_passthrough_hosts: ["preview.eboss.ai"]
    )

    conn =
      :get
      |> conn("/")
      |> Map.put(:host, "preview.eboss.ai")
      |> CanonicalHost.call([])

    refute conn.halted
    assert conn.status in [nil, 200]
  end

  defp put_endpoint_config(overrides) do
    endpoint_config =
      Application.fetch_env!(:eboss_web, EBossWeb.Endpoint)
      |> Keyword.merge(canonical_host_enabled: true, canonical_host_passthrough_hosts: [])
      |> Keyword.merge(overrides)

    Application.put_env(:eboss_web, EBossWeb.Endpoint, endpoint_config)
  end
end
