defmodule EBossWeb.Plugs.SessionApiCsrf do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn

  @safe_methods ~w(GET HEAD OPTIONS)

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    if unsafe_method?(conn) and cookie_authenticated_request?(conn) and
         not auth_header_request?(conn) do
      verify_csrf_token!(conn)
    else
      conn
    end
  end

  defp unsafe_method?(conn), do: conn.method not in @safe_methods

  defp cookie_authenticated_request?(conn) do
    get_req_header(conn, "cookie") != []
  end

  defp auth_header_request?(conn) do
    get_req_header(conn, "authorization") != []
  end

  defp verify_csrf_token!(conn) do
    session_state =
      conn
      |> get_session("_csrf_token")
      |> Plug.CSRFProtection.dump_state_from_session()

    if Plug.CSRFProtection.valid_state_and_csrf_token?(session_state, request_csrf_token(conn)) do
      conn
    else
      raise Plug.CSRFProtection.InvalidCSRFTokenError
    end
  end

  defp request_csrf_token(conn) do
    List.first(get_req_header(conn, "x-csrf-token")) || Map.get(conn.body_params, "_csrf_token")
  end
end
