defmodule EBossWeb.OpenApiController do
  use EBossWeb, :controller

  def show(conn, _params) do
    json(conn, EBossWeb.JsonApiRouter.spec())
  end
end
