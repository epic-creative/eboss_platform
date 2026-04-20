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

  def create_project(conn, %{"owner_slug" => owner_slug, "slug" => slug}) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    case AppScope.fetch_workspace_scope(current_user, owner_slug, slug) do
      {:ok, %AppScope{} = scope} ->
        case authorize_folio_manage(scope) do
          :ok ->
            handle_authorized_project_create(conn, scope, current_user)

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

  def update_project(
        conn,
        %{"owner_slug" => owner_slug, "slug" => slug, "project_id" => project_id}
      ) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    case AppScope.fetch_workspace_scope(current_user, owner_slug, slug) do
      {:ok, %AppScope{} = scope} ->
        case authorize_folio_manage(scope) do
          :ok ->
            handle_authorized_project_update(conn, scope, current_user, project_id)

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

  def create_task(conn, %{"owner_slug" => owner_slug, "slug" => slug}) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    case AppScope.fetch_workspace_scope(current_user, owner_slug, slug) do
      {:ok, %AppScope{} = scope} ->
        case authorize_folio_manage(scope) do
          :ok ->
            handle_authorized_task_create(conn, scope, current_user)

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

  defp authorize_folio_manage(%AppScope{} = scope) do
    if Map.get(scope.capabilities, :manage_folio, false) do
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

  defp handle_authorized_project_create(conn, %AppScope{} = scope, current_user) do
    with {:ok, params} <- parse_project_create_params(conn.body_params),
         {:ok, project} <-
           EBossFolio.create_project(
             Map.put(params, :workspace_id, scope.current_workspace.id),
             actor: current_user
           ) do
      conn
      |> put_status(:created)
      |> json(%{
        scope: folio_scope_payload(scope),
        project: project_summary_payload(project)
      })
    else
      {:error, _reason} ->
        error_json(
          conn,
          :bad_request,
          "invalid_project_payload",
          "Project payload could not be processed"
        )
    end
  end

  defp handle_authorized_project_update(
         conn,
         %AppScope{} = scope,
         current_user,
         project_id
       ) do
    with {:ok, params} <- parse_project_update_params(conn.body_params),
         {:ok, project} <-
           EBossFolio.get_project_in_workspace(project_id, scope.current_workspace.id,
             actor: current_user
           ),
         {:ok, project} <- EBossFolio.update_project_details(project, params, actor: current_user) do
      json(conn, %{
        scope: folio_scope_payload(scope),
        project: project_summary_payload(project)
      })
    else
      {:error, :not_found} ->
        error_json(conn, :not_found, "project_not_found", "Project not found")

      {:error, :invalid_payload} ->
        error_json(
          conn,
          :bad_request,
          "invalid_project_payload",
          "Project payload could not be processed"
        )

      {:error, _reason} ->
        error_json(
          conn,
          :bad_request,
          "invalid_project_payload",
          "Project payload could not be processed"
        )
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

  defp handle_authorized_task_create(conn, %AppScope{} = scope, current_user) do
    with {:ok, params} <- parse_task_create_params(conn.body_params),
         {:ok, task} <-
           EBossFolio.create_task(
             Map.put(params, :workspace_id, scope.current_workspace.id),
             actor: current_user
           ) do
      conn
      |> put_status(:created)
      |> json(%{
        scope: folio_scope_payload(scope),
        task: task_summary_payload(task)
      })
    else
      {:error, _reason} ->
        error_json(
          conn,
          :bad_request,
          "invalid_task_payload",
          "Task payload could not be processed"
        )
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
      description: project.description,
      status: project.status,
      priority_position: project.priority_position,
      due_at: project.due_at,
      review_at: project.review_at,
      notes: project.notes,
      metadata: project.metadata
    }
  end

  defp parse_project_create_params(%{"title" => title}) when is_binary(title) do
    parse_project_create_params(%{title: String.trim(title)})
  end

  defp parse_project_create_params(%{"title" => title}) when is_atom(title) do
    parse_project_create_params(%{title: to_string(title)})
  end

  defp parse_project_create_params(payload) when is_map(payload) do
    title = normalized_project_title(payload)

    if title == nil do
      {:error, :invalid_payload}
    else
      {:ok, %{title: title}}
    end
  end

  defp parse_project_create_params(_payload) do
    {:error, :invalid_payload}
  end

  defp parse_task_create_params(payload) when is_map(payload) do
    with {:ok, title} <- required_task_title(payload),
         {:ok, project_id} <- optional_task_project_id(payload) do
      attrs =
        %{}
        |> maybe_put(:title, title)
        |> maybe_put(:project_id, project_id)

      {:ok, attrs}
    end
  end

  defp parse_task_create_params(_payload) do
    {:error, :invalid_payload}
  end

  defp required_task_title(payload) do
    case fetch_payload_field(payload, :title) do
      :missing ->
        {:error, :invalid_payload}

      {:present, value} ->
        normalize_required_task_title_value(value)
    end
  end

  defp optional_task_project_id(payload) do
    case fetch_payload_field(payload, :project_id) do
      :missing ->
        {:ok, :missing}

      {:present, value} ->
        normalize_task_project_id_value(value)
    end
  end

  defp normalize_required_task_title_value(value) when is_binary(value) do
    title = String.trim(value)

    if title == "" do
      {:error, :invalid_payload}
    else
      {:ok, {:set, title}}
    end
  end

  defp normalize_required_task_title_value(value) when is_atom(value) do
    value
    |> to_string()
    |> normalize_required_task_title_value()
  end

  defp normalize_required_task_title_value(_value), do: {:error, :invalid_payload}

  defp normalize_task_project_id_value(nil), do: {:ok, {:set, nil}}

  defp normalize_task_project_id_value(value) when is_binary(value) do
    project_id = String.trim(value)
    {:ok, {:set, if(project_id == "", do: nil, else: project_id)}}
  end

  defp normalize_task_project_id_value(value) when is_atom(value) do
    value
    |> to_string()
    |> normalize_task_project_id_value()
  end

  defp normalize_task_project_id_value(_value), do: {:error, :invalid_payload}

  defp parse_project_update_params(payload) when is_map(payload) do
    with {:ok, title} <- optional_project_title(payload),
         {:ok, description} <- optional_project_text(payload, :description),
         {:ok, notes} <- optional_project_text(payload, :notes),
         {:ok, due_at} <- optional_project_datetime(payload, :due_at),
         {:ok, review_at} <- optional_project_datetime(payload, :review_at),
         {:ok, metadata} <- optional_project_metadata(payload) do
      attrs =
        %{}
        |> maybe_put(:title, title)
        |> maybe_put(:description, description)
        |> maybe_put(:notes, notes)
        |> maybe_put(:due_at, due_at)
        |> maybe_put(:review_at, review_at)
        |> maybe_put(:metadata, metadata)

      if map_size(attrs) == 0 do
        {:error, :invalid_payload}
      else
        {:ok, attrs}
      end
    end
  end

  defp parse_project_update_params(_payload) do
    {:error, :invalid_payload}
  end

  defp normalized_project_title(payload) do
    payload
    |> Map.get("title", Map.get(payload, :title, nil))
    |> case do
      title when is_binary(title) and title != "" ->
        String.trim(title)

      title when is_atom(title) ->
        title
        |> to_string()
        |> String.trim()

      _ ->
        nil
    end
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp optional_project_title(payload) do
    case fetch_payload_field(payload, :title) do
      :missing ->
        {:ok, :missing}

      {:present, value} ->
        normalize_project_title_value(value)
    end
  end

  defp optional_project_text(payload, field) do
    case fetch_payload_field(payload, field) do
      :missing ->
        {:ok, :missing}

      {:present, value} ->
        normalize_project_text_value(value)
    end
  end

  defp optional_project_datetime(payload, field) do
    case fetch_payload_field(payload, field) do
      :missing ->
        {:ok, :missing}

      {:present, value} ->
        normalize_project_datetime_value(value)
    end
  end

  defp optional_project_metadata(payload) do
    case fetch_payload_field(payload, :metadata) do
      :missing ->
        {:ok, :missing}

      {:present, value} ->
        normalize_project_metadata_value(value)
    end
  end

  defp fetch_payload_field(payload, field) do
    string_field = to_string(field)

    cond do
      Map.has_key?(payload, string_field) -> {:present, Map.get(payload, string_field)}
      Map.has_key?(payload, field) -> {:present, Map.get(payload, field)}
      true -> :missing
    end
  end

  defp normalize_project_title_value(value) when is_binary(value) do
    title = String.trim(value)

    if title == "" do
      {:error, :invalid_payload}
    else
      {:ok, {:set, title}}
    end
  end

  defp normalize_project_title_value(value) when is_atom(value) do
    value
    |> to_string()
    |> normalize_project_title_value()
  end

  defp normalize_project_title_value(_value), do: {:error, :invalid_payload}

  defp normalize_project_text_value(nil), do: {:ok, {:set, nil}}

  defp normalize_project_text_value(value) when is_binary(value) do
    trimmed = String.trim(value)
    {:ok, {:set, if(trimmed == "", do: nil, else: trimmed)}}
  end

  defp normalize_project_text_value(value) when is_atom(value) do
    value
    |> to_string()
    |> normalize_project_text_value()
  end

  defp normalize_project_text_value(_value), do: {:error, :invalid_payload}

  defp normalize_project_datetime_value(nil), do: {:ok, {:set, nil}}

  defp normalize_project_datetime_value(value) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      trimmed == "" ->
        {:ok, {:set, nil}}

      true ->
        with {:error, :invalid_format} <- parse_datetime_value(trimmed),
             {:error, :invalid_format} <- parse_date_value(trimmed) do
          {:error, :invalid_payload}
        else
          {:ok, datetime} -> {:ok, {:set, datetime}}
        end
    end
  end

  defp normalize_project_datetime_value(value) when is_atom(value) do
    value
    |> to_string()
    |> normalize_project_datetime_value()
  end

  defp normalize_project_datetime_value(_value), do: {:error, :invalid_payload}

  defp parse_datetime_value(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> {:ok, datetime}
      {:error, _reason} -> {:error, :invalid_format}
    end
  end

  defp parse_date_value(value) do
    with {:ok, date} <- Date.from_iso8601(value),
         {:ok, datetime} <- DateTime.new(date, ~T[00:00:00], "Etc/UTC") do
      {:ok, datetime}
    else
      _ -> {:error, :invalid_format}
    end
  end

  defp normalize_project_metadata_value(nil), do: {:ok, {:set, %{}}}

  defp normalize_project_metadata_value(value) when is_map(value), do: {:ok, {:set, value}}

  defp normalize_project_metadata_value(value) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      trimmed == "" ->
        {:ok, {:set, %{}}}

      true ->
        case Jason.decode(trimmed) do
          {:ok, decoded} when is_map(decoded) -> {:ok, {:set, decoded}}
          _ -> {:error, :invalid_payload}
        end
    end
  end

  defp normalize_project_metadata_value(_value), do: {:error, :invalid_payload}

  defp maybe_put(attrs, _field, :missing), do: attrs
  defp maybe_put(attrs, field, {:set, value}), do: Map.put(attrs, field, value)

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
