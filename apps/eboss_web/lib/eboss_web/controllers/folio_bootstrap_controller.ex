defmodule EBossWeb.FolioBootstrapController do
  use EBossWeb, :controller

  alias Ash.PlugHelpers
  alias EBossFolio
  alias EBossWeb.AppScope
  alias EBossWeb.FolioPayloads

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

  def update_task(
        conn,
        %{"owner_slug" => owner_slug, "slug" => slug, "task_id" => task_id}
      ) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    case AppScope.fetch_workspace_scope(current_user, owner_slug, slug) do
      {:ok, %AppScope{} = scope} ->
        case authorize_folio_manage(scope) do
          :ok ->
            handle_authorized_task_update(conn, scope, current_user, task_id)

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
        projects: Enum.map(projects, &FolioPayloads.project_summary/1)
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
        project: FolioPayloads.project_summary(project)
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
    case parse_project_update_intent(conn.body_params) do
      {:ok, :details} ->
        handle_authorized_project_details_update(conn, scope, current_user, project_id)

      {:ok, {:transition, target_status}} ->
        handle_authorized_project_transition(conn, scope, current_user, project_id, target_status)

      {:error, :invalid_payload} ->
        error_json(
          conn,
          :bad_request,
          "invalid_project_payload",
          "Project payload could not be processed"
        )
    end
  end

  defp handle_authorized_project_details_update(
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
        project: FolioPayloads.project_summary(project)
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

  defp handle_authorized_project_transition(
         conn,
         %AppScope{} = scope,
         current_user,
         project_id,
         target_status
       ) do
    with {:ok, project} <-
           EBossFolio.get_project_in_workspace(project_id, scope.current_workspace.id,
             actor: current_user
           ),
         {:ok, project} <- transition_project(project, target_status, current_user) do
      json(conn, %{
        scope: folio_scope_payload(scope),
        project: FolioPayloads.project_summary(project)
      })
    else
      {:error, :not_found} ->
        error_json(conn, :not_found, "project_not_found", "Project not found")

      {:error, %Ash.Error.Invalid{} = error} ->
        error_json(
          conn,
          :bad_request,
          "invalid_project_transition",
          Exception.message(error)
        )

      {:error, _reason} ->
        error_json(
          conn,
          :bad_request,
          "invalid_project_transition",
          "Project transition could not be processed"
        )
    end
  end

  defp handle_authorized_tasks_scope(conn, %AppScope{} = scope, current_user) do
    with {:ok, tasks} <-
           EBossFolio.list_tasks_in_workspace(scope.current_workspace.id,
             actor: current_user,
             load: [delegations: :contact]
           ) do
      json(conn, %{
        scope: folio_scope_payload(scope),
        tasks: Enum.map(tasks, &FolioPayloads.task_summary/1)
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
        task: FolioPayloads.task_summary(task)
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

  defp handle_authorized_task_update(conn, %AppScope{} = scope, current_user, task_id) do
    with {:ok, intent} <- parse_task_update_intent(conn.body_params),
         {:ok, task} <-
           EBossFolio.get_task_in_workspace(task_id, scope.current_workspace.id,
             actor: current_user,
             load: [delegations: :contact]
           ),
         {:ok, task} <- apply_task_update_intent(task, intent, scope, current_user) do
      json(conn, %{
        scope: folio_scope_payload(scope),
        task: FolioPayloads.task_summary(task)
      })
    else
      {:error, :not_found} ->
        error_json(conn, :not_found, "task_not_found", "Task not found")

      {:error, :invalid_payload} ->
        error_json(
          conn,
          :bad_request,
          "invalid_task_payload",
          "Task payload could not be processed"
        )

      {:error, %Ash.Error.Invalid{} = error} ->
        error_json(
          conn,
          :bad_request,
          "invalid_task_transition",
          Exception.message(error)
        )

      {:error, :invalid_task_workflow, message} ->
        error_json(
          conn,
          :bad_request,
          "invalid_task_transition",
          message
        )

      {:error, _reason} ->
        error_json(
          conn,
          :bad_request,
          "invalid_task_transition",
          "Task transition could not be processed"
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

  defp parse_project_update_intent(payload) when is_map(payload) do
    case fetch_payload_field(payload, :status) do
      :missing ->
        {:ok, :details}

      {:present, value} ->
        with {:ok, status} <- normalize_project_transition_status(value),
             :ok <- validate_project_transition_payload(payload) do
          {:ok, {:transition, status}}
        end
    end
  end

  defp parse_project_update_intent(_payload), do: {:error, :invalid_payload}

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

  defp parse_task_update_intent(payload) when is_map(payload) do
    case fetch_payload_field(payload, :intent) do
      :missing ->
        parse_task_transition_intent(payload)

      {:present, intent} ->
        parse_task_intent_payload(payload, intent)
    end
  end

  defp parse_task_update_intent(_payload), do: {:error, :invalid_payload}

  defp parse_task_intent_payload(payload, intent) when is_binary(intent) do
    case intent |> String.trim() do
      "transition" ->
        parse_task_transition_intent(payload)

      "delegate" ->
        with {:ok, attrs} <- parse_task_delegation_params(payload) do
          {:ok, {:delegate, attrs}}
        end

      _ ->
        {:error, :invalid_payload}
    end
  end

  defp parse_task_intent_payload(payload, intent) when is_atom(intent) do
    parse_task_intent_payload(payload, to_string(intent))
  end

  defp parse_task_intent_payload(_payload, _intent), do: {:error, :invalid_payload}

  defp parse_task_transition_intent(payload) do
    with {:ok, status} <- parse_task_transition_params(payload) do
      {:ok, {:transition, status}}
    end
  end

  defp parse_task_transition_params(payload) when is_map(payload) do
    with {:ok, status} <- required_task_transition_status(payload) do
      {:ok, status}
    end
  end

  defp parse_task_transition_params(_payload), do: {:error, :invalid_payload}

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

  defp optional_task_delegation_text(payload, field) do
    case fetch_payload_field(payload, field) do
      :missing ->
        {:ok, :missing}

      {:present, value} ->
        normalize_project_text_value(value)
    end
  end

  defp optional_task_delegation_datetime(payload, field) do
    case fetch_payload_field(payload, field) do
      :missing ->
        {:ok, :missing}

      {:present, value} ->
        normalize_project_datetime_value(value)
    end
  end

  defp required_task_transition_status(payload) do
    case fetch_payload_field(payload, :status) do
      :missing ->
        {:error, :invalid_payload}

      {:present, value} ->
        normalize_task_transition_status(value)
    end
  end

  defp parse_task_delegation_params(payload) do
    with {:ok, contact_reference} <- required_task_delegation_contact(payload),
         {:ok, delegated_summary} <- required_task_delegation_summary(payload),
         {:ok, quality_expectations} <-
           optional_task_delegation_text(payload, :quality_expectations),
         {:ok, deadline_expectations_at} <-
           optional_task_delegation_datetime(payload, :deadline_expectations_at),
         {:ok, follow_up_at} <- optional_task_delegation_datetime(payload, :follow_up_at) do
      attrs =
        %{}
        |> Map.put(:contact_reference, contact_reference)
        |> maybe_put(:delegated_summary, delegated_summary)
        |> maybe_put(:quality_expectations, quality_expectations)
        |> maybe_put(:deadline_expectations_at, deadline_expectations_at)
        |> maybe_put(:follow_up_at, follow_up_at)

      {:ok, attrs}
    end
  end

  defp required_task_delegation_contact(payload) do
    case fetch_payload_field(payload, :contact_id) do
      {:present, value} ->
        normalize_task_delegation_contact_id(value)

      :missing ->
        case fetch_payload_field(payload, :contact_name) do
          :missing ->
            {:error, :invalid_payload}

          {:present, value} ->
            normalize_task_delegation_contact_name(value)
        end
    end
  end

  defp required_task_delegation_summary(payload) do
    case fetch_payload_field(payload, :delegated_summary) do
      :missing ->
        {:error, :invalid_payload}

      {:present, value} ->
        normalize_required_task_delegation_summary(value)
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

  defp normalize_task_delegation_contact_id(value) when is_binary(value) do
    contact_id = String.trim(value)

    if contact_id == "" do
      {:error, :invalid_payload}
    else
      {:ok, {:existing, contact_id}}
    end
  end

  defp normalize_task_delegation_contact_id(value) when is_atom(value) do
    value
    |> to_string()
    |> normalize_task_delegation_contact_id()
  end

  defp normalize_task_delegation_contact_id(_value), do: {:error, :invalid_payload}

  defp normalize_task_delegation_contact_name(value) when is_binary(value) do
    contact_name = String.trim(value)

    if contact_name == "" do
      {:error, :invalid_payload}
    else
      {:ok, {:new, contact_name}}
    end
  end

  defp normalize_task_delegation_contact_name(value) when is_atom(value) do
    value
    |> to_string()
    |> normalize_task_delegation_contact_name()
  end

  defp normalize_task_delegation_contact_name(_value), do: {:error, :invalid_payload}

  defp normalize_required_task_delegation_summary(value) when is_binary(value) do
    summary = String.trim(value)

    if summary == "" do
      {:error, :invalid_payload}
    else
      {:ok, {:set, summary}}
    end
  end

  defp normalize_required_task_delegation_summary(value) when is_atom(value) do
    value
    |> to_string()
    |> normalize_required_task_delegation_summary()
  end

  defp normalize_required_task_delegation_summary(_value), do: {:error, :invalid_payload}

  defp normalize_task_transition_status(value) when is_binary(value) do
    case value |> String.trim() do
      "inbox" -> {:ok, :inbox}
      "next_action" -> {:ok, :next_action}
      "waiting_for" -> {:ok, :waiting_for}
      "scheduled" -> {:ok, :scheduled}
      "someday_maybe" -> {:ok, :someday_maybe}
      "done" -> {:ok, :done}
      "canceled" -> {:ok, :canceled}
      "archived" -> {:ok, :archived}
      _ -> {:error, :invalid_payload}
    end
  end

  defp normalize_task_transition_status(value) when is_atom(value) do
    value
    |> to_string()
    |> normalize_task_transition_status()
  end

  defp normalize_task_transition_status(_value), do: {:error, :invalid_payload}

  defp normalize_project_transition_status(value) when is_binary(value) do
    case value |> String.trim() do
      "active" -> {:ok, :active}
      "on_hold" -> {:ok, :on_hold}
      "completed" -> {:ok, :completed}
      "canceled" -> {:ok, :canceled}
      "archived" -> {:ok, :archived}
      _ -> {:error, :invalid_payload}
    end
  end

  defp normalize_project_transition_status(value) when is_atom(value) do
    value
    |> to_string()
    |> normalize_project_transition_status()
  end

  defp normalize_project_transition_status(_value), do: {:error, :invalid_payload}

  defp validate_project_transition_payload(payload) when is_map(payload) do
    if Enum.all?(Map.keys(payload), &(&1 in [:status, "status"])) do
      :ok
    else
      {:error, :invalid_payload}
    end
  end

  defp apply_task_update_intent(task, {:transition, target_status}, _scope, actor) do
    with {:ok, task} <- transition_task(task, target_status, actor) do
      load_task_with_delegations(task, task.workspace_id, actor)
    end
  end

  defp apply_task_update_intent(task, {:delegate, attrs}, %AppScope{} = scope, actor) do
    workspace_id = scope.current_workspace.id

    with :ok <- ensure_task_can_be_marked_waiting_for(task),
         {:ok, contact} <-
           resolve_delegation_contact(attrs.contact_reference, workspace_id, actor),
         {:ok, _delegation} <-
           create_task_delegation(task, workspace_id, contact.id, attrs, actor),
         {:ok, task} <- transition_task(task, :waiting_for, actor),
         {:ok, loaded_task} <- load_task_with_delegations(task, workspace_id, actor) do
      {:ok, loaded_task}
    end
  end

  defp ensure_task_can_be_marked_waiting_for(%EBossFolio.Task{status: status}) do
    if status in [:inbox, :next_action, :waiting_for, :scheduled, :someday_maybe] do
      :ok
    else
      {:error, :invalid_task_workflow, "cannot delegate task from #{status} status"}
    end
  end

  defp resolve_delegation_contact({:existing, contact_id}, workspace_id, actor) do
    EBossFolio.get_contact_in_workspace(contact_id, workspace_id, actor: actor)
  end

  defp resolve_delegation_contact({:new, contact_name}, workspace_id, actor) do
    EBossFolio.create_contact(
      %{
        workspace_id: workspace_id,
        name: contact_name
      },
      actor: actor
    )
  end

  defp create_task_delegation(task, workspace_id, contact_id, attrs, actor) do
    delegation_attrs =
      %{
        workspace_id: workspace_id,
        task_id: task.id,
        contact_id: contact_id
      }
      |> maybe_put(:delegated_summary, {:set, attrs.delegated_summary})
      |> maybe_put_value(:quality_expectations, Map.get(attrs, :quality_expectations, :missing))
      |> maybe_put_value(
        :deadline_expectations_at,
        Map.get(attrs, :deadline_expectations_at, :missing)
      )
      |> maybe_put_value(:follow_up_at, Map.get(attrs, :follow_up_at, :missing))

    EBossFolio.delegate_task(delegation_attrs, actor: actor)
  end

  defp load_task_with_delegations(task, workspace_id, actor) do
    EBossFolio.get_task_in_workspace(task.id, workspace_id,
      actor: actor,
      load: [delegations: :contact]
    )
  end

  defp transition_task(task, :inbox, actor), do: EBossFolio.move_task_to_inbox(task, actor: actor)

  defp transition_task(task, :next_action, actor),
    do: EBossFolio.mark_task_next_action(task, actor: actor)

  defp transition_task(task, :waiting_for, actor),
    do: EBossFolio.mark_task_waiting_for(task, actor: actor)

  defp transition_task(task, :scheduled, actor), do: EBossFolio.schedule_task(task, actor: actor)

  defp transition_task(task, :someday_maybe, actor),
    do: EBossFolio.mark_task_someday_maybe(task, actor: actor)

  defp transition_task(task, :done, actor), do: EBossFolio.complete_task(task, actor: actor)
  defp transition_task(task, :canceled, actor), do: EBossFolio.cancel_task(task, actor: actor)
  defp transition_task(task, :archived, actor), do: EBossFolio.archive_task(task, actor: actor)

  defp transition_project(project, :active, actor),
    do: EBossFolio.activate_project(project, actor: actor)

  defp transition_project(project, :on_hold, actor),
    do: EBossFolio.put_project_on_hold(project, actor: actor)

  defp transition_project(project, :completed, actor),
    do: EBossFolio.complete_project(project, actor: actor)

  defp transition_project(project, :canceled, actor),
    do: EBossFolio.cancel_project(project, actor: actor)

  defp transition_project(project, :archived, actor),
    do: EBossFolio.archive_project(project, actor: actor)

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
  defp maybe_put_value(attrs, _field, :missing), do: attrs
  defp maybe_put_value(attrs, field, value), do: Map.put(attrs, field, value)

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
