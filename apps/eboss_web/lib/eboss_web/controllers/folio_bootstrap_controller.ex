defmodule EBossWeb.FolioBootstrapController do
  use EBossWeb, :controller

  alias Ash.PlugHelpers
  alias EBossFolio
  alias EBossWeb.AppScope

  def show(conn, %{"owner_slug" => owner_slug, "slug" => slug}) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    case AppScope.fetch_workspace_scope(current_user, owner_slug, slug) do
      {:ok, %AppScope{} = scope} ->
        case authorize_folio_read(scope) do
          :ok ->
            handle_authorized_scope(conn, scope, current_user)

          {:error, :forbidden} ->
            error_json(conn, :forbidden, "workspace_forbidden", "Workspace access is forbidden")
        end

      {:error, :unauthorized} ->
        error_json(conn, :unauthorized, "authentication_required", "Authentication is required")

      {:error, :forbidden} ->
        error_json(conn, :forbidden, "workspace_forbidden", "Workspace access is forbidden")

      {:error, :not_found} ->
        error_json(conn, :not_found, "workspace_not_found", "Workspace not found")
    end
  end

  defp authorize_folio_read(%AppScope{} = scope) do
    if Map.get(scope.capabilities, :read_folio, false) do
      :ok
    else
      {:error, :forbidden}
    end
  end

  defp handle_authorized_scope(conn, %AppScope{} = scope, current_user) do
    with {:ok, summary_counts} <- summary_counts(scope.current_workspace.id, current_user) do
      json(conn, %{
        scope: folio_scope_payload(scope),
        summary_counts: summary_counts
      })
    else
      {:error, _reason} ->
        error_json(conn, :forbidden, "workspace_forbidden", "Workspace access is forbidden")
    end
  end

  defp summary_counts(workspace_id, actor) do
    EBossFolio.bootstrap_summary_counts(workspace_id, actor: actor)
  end

  defp folio_scope_payload(%AppScope{} = scope) do
    app = Map.get(scope.apps, "folio", %{})

    %{
      app_key: "folio",
      workspace: scope.current_workspace,
      owner: scope.owner,
      app: normalize_payload_map(app),
      capabilities: payload_map_get(app, :capabilities, %{}),
      workspace_path: Map.get(scope.current_workspace, :dashboard_path),
      app_path: payload_map_get(app, :default_path)
    }
  end

  defp payload_map_get(payload, key, default \\ nil) when is_map(payload) do
    payload
    |> Map.get(key, Map.get(payload, to_string(key), default))
    |> normalize_payload_map()
  end

  defp normalize_payload_map(%{} = payload) do
    Enum.into(payload, %{}, fn {key, value} ->
      {to_string(key), normalize_payload_map(value)}
    end)
  end

  defp normalize_payload_map(value), do: value

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
