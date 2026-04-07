defmodule EBossWeb.PageController do
  use EBossWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
