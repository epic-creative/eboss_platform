defmodule EBossWeb.Plugs.CanonicalHost do
  @moduledoc false

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    endpoint_config = Application.get_env(:eboss_web, EBossWeb.Endpoint, [])

    canonical_host = Keyword.get(endpoint_config, :canonical_host)

    cond do
      not is_binary(canonical_host) or canonical_host == "" ->
        conn

      true ->
        opts = PlugCanonicalHost.init(canonical_host: canonical_host)
        PlugCanonicalHost.call(conn, opts)
    end
  end
end
