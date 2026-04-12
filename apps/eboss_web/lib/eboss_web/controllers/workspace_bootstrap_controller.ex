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

    case AppScope.fetch_workspace_scope(current_user, owner_type, owner_handle, slug) do
      {:ok, %AppScope{} = scope} ->
        json(conn, AppScope.bootstrap_payload(scope))

      {:error, :unauthorized} ->
        error_json(conn, :unauthorized, "authentication_required", "Authentication is required")

      {:error, :forbidden} ->
        error_json(conn, :forbidden, "workspace_forbidden", "Workspace access is forbidden")

      {:error, :not_found} ->
        error_json(conn, :not_found, "workspace_not_found", "Workspace not found")
    end
  end

  defp error_json(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(%{
      error: %{
        code: code,
        message: message
      }
    })
  end
end
