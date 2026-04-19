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

  def projects(conn, %{"owner_slug" => owner_slug, "slug" => slug}) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    case AppScope.fetch_workspace_scope(current_user, owner_slug, slug) do
      {:ok, %AppScope{} = scope} ->
        case authorize_folio_read(scope) do
          :ok ->
            handle_authorized_projects_scope(conn, scope, current_user)

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

  def tasks(conn, %{"owner_slug" => owner_slug, "slug" => slug}) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    case AppScope.fetch_workspace_scope(current_user, owner_slug, slug) do
      {:ok, %AppScope{} = scope} ->
        case authorize_folio_read(scope) do
          :ok ->
            handle_authorized_tasks_scope(conn, scope, current_user)

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

  def activity(conn, %{"owner_slug" => owner_slug, "slug" => slug}) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    case AppScope.fetch_workspace_scope(current_user, owner_slug, slug) do
      {:ok, %AppScope{} = scope} ->
        case authorize_folio_read(scope) do
          :ok ->
            handle_authorized_activity_scope(conn, scope, current_user)

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

  defp handle_authorized_projects_scope(conn, %AppScope{} = scope, current_user) do
    with {:ok, projects} <-
           EBossFolio.list_projects_in_workspace(scope.current_workspace.id, actor: current_user) do
      json(conn, %{
        scope: folio_scope_payload(scope),
        projects: Enum.map(projects, &project_summary_payload/1)
      })
    else
      {:error, _reason} ->
        error_json(conn, :forbidden, "workspace_forbidden", "Workspace access is forbidden")
    end
  end

  defp handle_authorized_tasks_scope(conn, %AppScope{} = scope, current_user) do
    with {:ok, tasks} <-
           EBossFolio.list_tasks_in_workspace(scope.current_workspace.id, actor: current_user) do
      json(conn, %{
        scope: folio_scope_payload(scope),
        tasks: Enum.map(tasks, &task_summary_payload/1)
      })
    else
      {:error, _reason} ->
        error_json(conn, :forbidden, "workspace_forbidden", "Workspace access is forbidden")
    end
  end

  defp handle_authorized_activity_scope(conn, %AppScope{} = scope, current_user) do
    with {:ok, events} <-
           EBossFolio.list_activity_feed(scope.current_workspace.id, actor: current_user) do
      json(conn, %{
        scope: folio_scope_payload(scope),
        events: events
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

  defp project_summary_payload(%EBossFolio.Project{} = project) do
    %{
      id: project.id,
      title: project.title,
      status: project.status,
      priority_position: project.priority_position,
      due_at: project.due_at,
      review_at: project.review_at
    }
  end

  defp task_summary_payload(%EBossFolio.Task{} = task) do
    %{
      id: task.id,
      title: task.title,
      status: task.status,
      project_id: task.project_id,
      priority_position: task.priority_position,
      due_at: task.due_at,
      review_at: task.review_at
    }
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
