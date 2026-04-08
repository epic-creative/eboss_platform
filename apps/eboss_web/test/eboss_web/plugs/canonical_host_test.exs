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

  test "skips redirects when canonical host is not configured" do
    put_endpoint_config(canonical_host: nil)

    conn =
      :get
      |> conn("/")
      |> Map.put(:host, "localhost")
      |> CanonicalHost.call([])

    refute conn.halted
    assert conn.status in [nil, 200]
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

  test "skips redirects when request already uses the canonical host" do
    put_endpoint_config(canonical_host: "stage.eboss.ai")

    conn =
      :get
      |> conn("/")
      |> Map.put(:host, "stage.eboss.ai")
      |> CanonicalHost.call([])

    refute conn.halted
    assert conn.status in [nil, 200]
  end

  defp put_endpoint_config(overrides) do
    endpoint_config =
      Application.fetch_env!(:eboss_web, EBossWeb.Endpoint)
      |> Keyword.merge(overrides)

    Application.put_env(:eboss_web, EBossWeb.Endpoint, endpoint_config)
  end
end
