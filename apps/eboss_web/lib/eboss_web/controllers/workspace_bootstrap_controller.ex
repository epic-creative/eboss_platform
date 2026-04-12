defmodule EBossWeb.WorkspaceBootstrapController do
  use EBossWeb, :controller

  alias Ash.PlugHelpers
  alias EBossWeb.AppScope

  def show_user(conn, %{"owner_handle" => owner_handle, "slug" => slug}) do
    render_bootstrap(conn, :user, owner_handle, slug)
  end

  def show_org(conn, %{"owner_handle" => owner_handle, "slug" => slug}) do
    render_bootstrap(conn, :organization, owner_handle, slug)
  end

  defp render_bootstrap(conn, owner_type, owner_handle, slug) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    case AppScope.resolve_workspace(current_user, owner_type, owner_handle, slug) do
      {:ok, %AppScope{empty?: false} = scope} ->
        json(conn, AppScope.bootstrap_payload(scope))

      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{
          error: %{
            code: "workspace_not_found",
            message: "Workspace not found"
          }
        })
    end
  end
end
