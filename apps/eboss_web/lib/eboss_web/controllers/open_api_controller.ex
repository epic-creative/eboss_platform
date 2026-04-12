defmodule EBossWeb.OpenApiController do
  use EBossWeb, :controller

  def show(conn, _params) do
    json(conn, EBossWeb.ApiSpec.spec())
  end
end
