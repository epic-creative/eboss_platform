defmodule EBossWeb.Plugs.CanonicalHost do
  @moduledoc false

  @behaviour Plug

  def init(opts), do: opts

  def call(%Plug.Conn{host: host} = conn, _opts) do
    endpoint_config = Application.get_env(:eboss_web, EBossWeb.Endpoint, [])

    canonical_host = Keyword.get(endpoint_config, :canonical_host)
    canonical_host_enabled = Keyword.get(endpoint_config, :canonical_host_enabled, true)

    passthrough_hosts =
      endpoint_config
      |> Keyword.get(:canonical_host_passthrough_hosts, [])
      |> MapSet.new()

    cond do
      not canonical_host_enabled ->
        conn

      not is_binary(canonical_host) or canonical_host == "" ->
        conn

      host in passthrough_hosts ->
        conn

      true ->
        opts = PlugCanonicalHost.init(canonical_host: canonical_host)
        PlugCanonicalHost.call(conn, opts)
    end
  end
end
