defmodule EBossWeb.DashboardLive do
  use EBossWeb, :live_view

  alias EBossChat
  alias EBossFolio
  alias EBossNotify
  alias EBossWeb.AppScope
  alias EBossWeb.ChatPayloads
  alias EBossWeb.FolioPayloads
  alias EBossWeb.NotificationController

  @workspace_routes %{
    "dashboard" => %{surface: "dashboard", title: "Overview"},
    "members" => %{surface: "members", title: "Members"},
    "access" => %{surface: "access", title: "Access"},
    "settings" => %{surface: "settings", title: "Settings"}
  }
  @default_workspace_page "dashboard"

  @impl true
  def mount(params, _session, socket) do
    case resolve_scope(socket.assigns.current_user, params) do
      {:redirect, dashboard_path} ->
        {:ok, redirect(socket, to: dashboard_path)}

      {:ok, current_scope} ->
        if connected?(socket) do
          :ok = EBossNotify.subscribe(socket.assigns.current_user)
        end

        route = resolve_current_route(current_scope, socket.assigns.live_action, params)

        {:ok,
         socket
         |> assign(:page_title, route.title)
         |> assign(:current_user_props, user_props(socket.assigns.current_user))
         |> assign(:notification_bootstrap, notification_bootstrap(socket.assigns.current_user))
         |> stream(:chat_sessions, [])
         |> stream(:chat_messages, [])
         |> assign_workspace_context(current_scope, route)}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    case resolve_scope(socket.assigns.current_user, params) do
      {:redirect, dashboard_path} ->
        {:noreply, redirect(socket, to: dashboard_path)}

      {:ok, current_scope} ->
        route = resolve_current_route(current_scope, socket.assigns.live_action, params)

        {:noreply,
         socket
         |> assign(:page_title, route.title)
         |> assign_workspace_context(current_scope, route)}
    end
  end

  @impl true
  def handle_info({:notification_created, _recipient}, socket), do: refresh_notifications(socket)
  def handle_info({:notification_updated, _recipient}, socket), do: refresh_notifications(socket)
  def handle_info({:notifications_read_all, _user_id}, socket), do: refresh_notifications(socket)

  def handle_info({:notification_preferences_updated, _user_id}, socket),
    do: refresh_notifications(socket)

  def handle_info({:notification_channels_updated, _user_id}, socket),
    do: refresh_notifications(socket)

  @impl true
  def handle_event("notifications:mark_read", %{"recipient_id" => recipient_id}, socket) do
    reply_with_notification_action(socket, fn current_user ->
      EBossNotify.mark_read(current_user, recipient_id)
    end)
  end

  def handle_event("notifications:mark_all_read", _params, socket) do
    reply_with_notification_action(socket, &EBossNotify.mark_all_read/1)
  end

  def handle_event("folio:refresh", _params, socket) do
    socket = assign_folio_state(socket)
    {:reply, %{ok: true, folio_state: socket.assigns.folio_state}, socket}
  end

  def handle_event("folio:create_project", params, socket) do
    reply_with_folio_manage(socket, fn scope, current_user ->
      with {:ok, title} <- required_text(params, :title),
           {:ok, project} <-
             EBossFolio.create_project(
               %{workspace_id: scope.current_workspace.id, title: title},
               actor: current_user
             ) do
        {:ok, %{project: FolioPayloads.project_summary(project)}}
      end
    end)
  end

  def handle_event("folio:update_project", params, socket) do
    reply_with_folio_manage(socket, fn scope, current_user ->
      with {:ok, project_id} <- required_text(params, :project_id),
           {:ok, attrs} <- project_update_attrs(params),
           {:ok, project} <-
             EBossFolio.get_project_in_workspace(project_id, scope.current_workspace.id,
               actor: current_user
             ),
           {:ok, project} <-
             EBossFolio.update_project_details(project, attrs, actor: current_user) do
        {:ok, %{project: FolioPayloads.project_summary(project)}}
      end
    end)
  end

  def handle_event("folio:transition_project", params, socket) do
    reply_with_folio_manage(socket, fn scope, current_user ->
      with {:ok, project_id} <- required_text(params, :project_id),
           {:ok, status} <-
             required_status(params, :status, [
               :active,
               :on_hold,
               :completed,
               :canceled,
               :archived
             ]),
           {:ok, project} <-
             EBossFolio.get_project_in_workspace(project_id, scope.current_workspace.id,
               actor: current_user
             ),
           {:ok, project} <- transition_project(project, status, current_user) do
        {:ok, %{project: FolioPayloads.project_summary(project)}}
      end
    end)
  end

  def handle_event("folio:create_task", params, socket) do
    reply_with_folio_manage(socket, fn scope, current_user ->
      with {:ok, title} <- required_text(params, :title),
           {:ok, project_id} <- optional_text(params, :project_id),
           {:ok, task} <-
             EBossFolio.create_task(
               %{}
               |> Map.put(:workspace_id, scope.current_workspace.id)
               |> Map.put(:title, title)
               |> maybe_put_value(:project_id, project_id),
               actor: current_user
             ) do
        {:ok, %{task: FolioPayloads.task_summary(task)}}
      end
    end)
  end

  def handle_event("folio:transition_task", params, socket) do
    reply_with_folio_manage(socket, fn scope, current_user ->
      with {:ok, task_id} <- required_text(params, :task_id),
           {:ok, status} <-
             required_status(params, :status, [
               :inbox,
               :next_action,
               :waiting_for,
               :scheduled,
               :someday_maybe,
               :done,
               :canceled,
               :archived
             ]),
           {:ok, task} <-
             EBossFolio.get_task_in_workspace(task_id, scope.current_workspace.id,
               actor: current_user,
               load: [delegations: :contact]
             ),
           {:ok, task} <- transition_task(task, status, current_user),
           {:ok, task} <-
             load_task_with_delegations(task, scope.current_workspace.id, current_user) do
        {:ok, %{task: FolioPayloads.task_summary(task)}}
      end
    end)
  end

  def handle_event("folio:delegate_task", params, socket) do
    reply_with_folio_manage(socket, fn scope, current_user ->
      workspace_id = scope.current_workspace.id

      with {:ok, task_id} <- required_text(params, :task_id),
           {:ok, delegation_attrs} <- task_delegation_attrs(params),
           {:ok, task} <-
             EBossFolio.get_task_in_workspace(task_id, workspace_id,
               actor: current_user,
               load: [delegations: :contact]
             ),
           :ok <- ensure_task_can_be_marked_waiting_for(task),
           {:ok, contact} <-
             resolve_delegation_contact(
               delegation_attrs.contact_reference,
               workspace_id,
               current_user
             ),
           {:ok, _delegation} <-
             create_task_delegation(
               task,
               workspace_id,
               contact.id,
               delegation_attrs,
               current_user
             ),
           {:ok, task} <- transition_task(task, :waiting_for, current_user),
           {:ok, task} <- load_task_with_delegations(task, workspace_id, current_user) do
        {:ok, %{task: FolioPayloads.task_summary(task)}}
      end
    end)
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> ensure_workspace_assigns()
      |> assign(
        :chat_sessions_stream,
        get_in(assigns, [:streams, :chat_sessions]) || []
      )
      |> assign(
        :chat_messages_stream,
        get_in(assigns, [:streams, :chat_messages]) || []
      )

    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_user={@current_user}
      current_path={@current_path}
      shell_mode="workspace"
    >
      <.ShellOperatorWorkspaceApp
        currentUser={@current_user_props}
        currentScope={@current_scope_props}
        currentPage={@current_navigation}
        currentPath={@current_path}
        notificationBootstrap={@notification_bootstrap}
        folioState={@folio_state}
        chatState={@chat_state}
        chatSessions={@chat_sessions_stream}
        chatMessages={@chat_messages_stream}
        signOutPath={~p"/logout"}
        csrfToken={Plug.CSRFProtection.get_csrf_token()}
      />
    </Layouts.app>
    """
  end

  defp ensure_workspace_assigns(assigns) do
    current_scope =
      Map.get(assigns, :current_scope) || AppScope.empty(Map.get(assigns, :current_user))

    current_navigation =
      Map.get(assigns, :current_navigation, %{
        type: "workspace",
        surface: @default_workspace_page,
        app_key: nil,
        app_surface: nil,
        title: "Overview",
        current_path: current_path(current_scope, @default_workspace_page)
      })

    current_path = Map.get(assigns, :current_path) || Map.get(current_navigation, :current_path)

    assigns
    |> assign(:current_scope, current_scope)
    |> assign(:current_navigation, current_navigation)
    |> assign(:current_path, current_path)
    |> assign(
      :current_user_props,
      Map.get(assigns, :current_user_props) || user_props(Map.get(assigns, :current_user))
    )
    |> assign(
      :current_scope_props,
      Map.get(assigns, :current_scope_props) || scope_props(current_scope)
    )
    |> assign(
      :notification_bootstrap,
      Map.get(assigns, :notification_bootstrap) ||
        notification_bootstrap(Map.get(assigns, :current_user))
    )
    |> assign(
      :folio_state,
      Map.get(assigns, :folio_state) ||
        folio_state_props(current_scope, Map.get(assigns, :current_user), current_navigation)
    )
    |> assign(
      :chat_state,
      Map.get(assigns, :chat_state) ||
        chat_state_props(current_scope, Map.get(assigns, :current_user), current_navigation)
    )
  end

  defp resolve_current_route(current_scope, :workspace_root, _params) do
    resolve_workspace_route(current_scope, @default_workspace_page)
  end

  defp resolve_current_route(current_scope, :workspace_surface, %{"workspace_surface" => surface}) do
    resolve_workspace_route(current_scope, surface)
  end

  defp resolve_current_route(current_scope, :workspace_surface, _params),
    do: resolve_workspace_route(current_scope, @default_workspace_page)

  defp resolve_current_route(current_scope, :workspace_app, %{"app_key" => app_key} = params) do
    app_path =
      case Map.get(params, "app_path") do
        path when is_list(path) ->
          path

        nil ->
          case Map.get(params, "app_surface") do
            surface when is_binary(surface) and surface != "" -> [surface]
            _ -> []
          end
      end

    resolve_app_route(current_scope, app_key, app_path)
  end

  defp resolve_current_route(current_scope, _live_action, _params) do
    resolve_workspace_route(current_scope, @default_workspace_page)
  end

  defp resolve_workspace_route(%AppScope{} = current_scope, page)
       when is_binary(page) do
    resolved = Map.get(@workspace_routes, page, @workspace_routes[@default_workspace_page])

    %{
      type: "workspace",
      surface: resolved.surface,
      title: resolved.title,
      app_key: nil,
      app_surface: nil,
      current_path: workspace_path(current_scope, resolved.surface)
    }
  end

  defp resolve_app_route(%AppScope{apps: apps} = current_scope, app_key, app_path)
       when is_binary(app_key) and is_list(app_path) do
    case fetch_map_field(apps, app_key) do
      app when is_map(app) ->
        if fetch_map_field(app, :enabled, false) do
          app_label = fetch_map_field(app, :label, to_string(app_key))
          normalized_path = normalize_app_path(app_path)
          normalized_surface = List.first(normalized_path)
          app_key_string = to_string(app_key)

          %{
            type: "app",
            app_key: app_key_string,
            app_surface: normalized_surface,
            app_path: normalized_path,
            title: app_title(app_label, app_key_string, normalized_path),
            current_path: app_path(current_scope, app, app_key_string, normalized_path)
          }
        else
          resolve_workspace_route(current_scope, @default_workspace_page)
        end

      _ ->
        resolve_workspace_route(current_scope, @default_workspace_page)
    end
  end

  defp resolve_app_route(%AppScope{} = current_scope, _app_key, _app_path) do
    resolve_workspace_route(current_scope, @default_workspace_page)
  end

  defp resolve_scope(current_user, %{
         "owner_slug" => owner_slug,
         "workspace_slug" => workspace_slug
       })
       when is_binary(owner_slug) and is_binary(workspace_slug) do
    AppScope.resolve_workspace(current_user, owner_slug, workspace_slug)
  end

  defp resolve_scope(current_user, _params),
    do: {:ok, AppScope.empty(current_user)}

  defp current_path(%AppScope{dashboard_path: dashboard_path}, "dashboard"), do: dashboard_path

  defp current_path(%AppScope{dashboard_path: dashboard_path}, page) when is_binary(page) do
    "#{dashboard_path}/#{page}"
  end

  defp workspace_path(%AppScope{dashboard_path: dashboard_path}, "dashboard"), do: dashboard_path

  defp workspace_path(%AppScope{dashboard_path: dashboard_path}, page)
       when is_binary(page) do
    "#{dashboard_path}/#{page}"
  end

  defp app_path(%AppScope{dashboard_path: dashboard_path}, app, app_key, nil) do
    fetch_map_field(app, :default_path, "#{dashboard_path}/apps/#{app_key}")
  end

  defp app_path(%AppScope{dashboard_path: dashboard_path}, app, app_key, []) do
    fetch_map_field(app, :default_path, "#{dashboard_path}/apps/#{app_key}")
  end

  defp app_path(%AppScope{dashboard_path: dashboard_path}, app, app_key, app_path_segments)
       when is_list(app_path_segments) do
    base_path = fetch_map_field(app, :default_path, "#{dashboard_path}/apps/#{app_key}")
    Enum.reduce(app_path_segments, base_path, fn segment, path -> "#{path}/#{segment}" end)
  end

  defp app_title(app_label, _app_key, []), do: app_label

  defp app_title(app_label, "chat", ["new"]), do: "#{app_label} · New"
  defp app_title(app_label, "chat", ["sessions", _session_id]), do: app_label

  defp app_title(app_label, _app_key, [app_surface | _rest]) do
    "#{app_label} · #{String.capitalize(app_surface)}"
  end

  defp normalize_app_path(path) when is_list(path) do
    path
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
  end

  defp assign_workspace_context(socket, %AppScope{} = current_scope, route) do
    chat_context = chat_context(current_scope, socket.assigns.current_user, route)

    socket
    |> assign(:current_scope, current_scope)
    |> assign(:current_navigation, route)
    |> assign(:current_path, route.current_path)
    |> assign(:current_scope_props, scope_props(current_scope))
    |> assign(
      :folio_state,
      folio_state_props(current_scope, socket.assigns.current_user, route)
    )
    |> assign(
      :chat_state,
      chat_context.state
    )
    |> stream(:chat_sessions, chat_context.sessions, reset: true)
    |> stream(:chat_messages, chat_context.messages, reset: true)
  end

  defp refresh_notifications(socket) do
    {:noreply, assign_notification_bootstrap(socket)}
  end

  defp reply_with_notification_action(socket, action) do
    case action.(socket.assigns.current_user) do
      {:ok, _result} ->
        socket = assign_notification_bootstrap(socket)
        {:reply, %{ok: true, bootstrap: socket.assigns.notification_bootstrap}, socket}

      {:error, reason} ->
        {:reply, %{ok: false, error: notification_error(reason)}, socket}
    end
  end

  defp assign_notification_bootstrap(socket) do
    assign(socket, :notification_bootstrap, notification_bootstrap(socket.assigns.current_user))
  end

  defp notification_bootstrap(nil), do: empty_notification_bootstrap()

  defp notification_bootstrap(current_user) do
    case EBossNotify.bootstrap(current_user) do
      {:ok, bootstrap} -> NotificationController.bootstrap_payload(bootstrap)
      {:error, _reason} -> empty_notification_bootstrap()
    end
  end

  defp notification_error(reason) when is_binary(reason), do: reason
  defp notification_error(reason), do: inspect(reason)

  defp reply_with_folio_manage(socket, operation) do
    scope = socket.assigns.current_scope

    cond do
      !match?(
        %AppScope{current_workspace: %{id: workspace_id}} when is_binary(workspace_id),
        scope
      ) ->
        {:reply, %{ok: false, error: "Workspace scope is unavailable."}, socket}

      !Map.get(scope.capabilities, :manage_folio, false) ->
        {:reply, %{ok: false, error: "Workspace access is forbidden."}, socket}

      true ->
        case operation.(scope, socket.assigns.current_user) do
          {:ok, payload} ->
            socket = assign_folio_state(socket)

            {:reply,
             payload
             |> Map.put(:ok, true)
             |> Map.put(:folio_state, socket.assigns.folio_state), socket}

          {:error, reason} ->
            {:reply, %{ok: false, error: folio_error(reason)}, socket}

          {:error, reason, message} ->
            {:reply, %{ok: false, error: folio_error({reason, message})}, socket}
        end
    end
  end

  defp assign_folio_state(socket) do
    assign(
      socket,
      :folio_state,
      folio_state_props(
        socket.assigns.current_scope,
        socket.assigns.current_user,
        socket.assigns.current_navigation
      )
    )
  end

  defp folio_state_props(
         %AppScope{} = scope,
         current_user,
         %{type: "app", app_key: "folio"} = route
       ) do
    surface = Map.get(route, :app_surface) || "tasks"
    state = empty_folio_state(surface)

    cond do
      !Map.get(scope.capabilities, :read_folio, false) ->
        state
        |> Map.put(:projectsError, "Workspace access is forbidden.")
        |> Map.put(:tasksError, "Workspace access is forbidden.")
        |> Map.put(:activityError, "Workspace access is forbidden.")

      surface == "projects" ->
        load_folio_projects(state, scope, current_user)

      surface == "activity" ->
        load_folio_activity(state, scope, current_user)

      true ->
        state
        |> maybe_load_task_project_options(scope, current_user)
        |> load_folio_tasks(scope, current_user)
    end
  end

  defp folio_state_props(_scope, _current_user, _route), do: empty_folio_state(nil)

  defp empty_folio_state(surface) do
    %{
      surface: surface,
      projects: [],
      tasks: [],
      events: [],
      projectsLoading: false,
      tasksLoading: false,
      activityLoading: false,
      projectsError: nil,
      tasksError: nil,
      activityError: nil
    }
  end

  defp maybe_load_task_project_options(state, %AppScope{} = scope, current_user) do
    if Map.get(scope.capabilities, :manage_folio, false) do
      load_folio_projects(state, scope, current_user)
    else
      state
    end
  end

  defp load_folio_projects(state, %AppScope{} = scope, current_user) do
    case EBossFolio.list_projects_in_workspace(scope.current_workspace.id, actor: current_user) do
      {:ok, projects} ->
        Map.put(state, :projects, Enum.map(projects, &FolioPayloads.project_summary/1))

      {:error, reason} ->
        Map.put(state, :projectsError, folio_error(reason))
    end
  end

  defp load_folio_tasks(state, %AppScope{} = scope, current_user) do
    case EBossFolio.list_tasks_in_workspace(scope.current_workspace.id,
           actor: current_user,
           load: [delegations: :contact]
         ) do
      {:ok, tasks} ->
        Map.put(state, :tasks, Enum.map(tasks, &FolioPayloads.task_summary/1))

      {:error, reason} ->
        Map.put(state, :tasksError, folio_error(reason))
    end
  end

  defp load_folio_activity(state, %AppScope{} = scope, current_user) do
    case EBossFolio.list_activity_feed(scope.current_workspace.id, actor: current_user) do
      {:ok, events} ->
        Map.put(state, :events, events)

      {:error, reason} ->
        Map.put(state, :activityError, folio_error(reason))
    end
  end

  defp chat_context(
         %AppScope{} = scope,
         current_user,
         %{type: "app", app_key: "chat"} = route
       ) do
    surface = chat_route_surface(route)
    state = empty_chat_state(surface)

    cond do
      !Map.get(scope.capabilities, :read_chat, false) ->
        %{
          state: Map.put(state, :error, "Workspace access is forbidden."),
          sessions: [],
          messages: []
        }

      true ->
        load_chat_context(state, scope, current_user, route)
    end
  end

  defp chat_context(_scope, _current_user, _route) do
    %{state: empty_chat_state(nil), sessions: [], messages: []}
  end

  defp chat_state_props(scope, current_user, route) do
    scope
    |> chat_context(current_user, route)
    |> Map.fetch!(:state)
  end

  defp empty_chat_state(surface) do
    %{
      surface: surface,
      current_session: nil,
      default_model_key: EBossChat.default_chat_model_key(),
      models: EBossChat.chat_model_options(),
      usage_totals: %{sessions: 0, input_tokens: 0, output_tokens: 0, total_tokens: 0},
      loading: false,
      error: nil
    }
  end

  defp chat_route_surface(%{app_path: ["new" | _]}), do: "new"
  defp chat_route_surface(%{app_path: ["sessions", _session_id | _]}), do: "session"
  defp chat_route_surface(_route), do: "index"

  defp load_chat_context(state, %AppScope{} = scope, current_user, route) do
    case EBossChat.list_active_sessions_in_workspace(scope.current_workspace.id,
           actor: current_user
         ) do
      {:ok, sessions} ->
        session_summaries = Enum.map(sessions, &ChatPayloads.session_summary(&1, scope))
        state = Map.put(state, :usage_totals, EBossChat.usage_totals_for_sessions(sessions))
        load_chat_session_context(state, session_summaries, scope, current_user, route)

      {:error, reason} ->
        %{
          state: Map.put(state, :error, chat_error(reason)),
          sessions: [],
          messages: []
        }
    end
  end

  defp load_chat_session_context(
         %{error: nil} = state,
         session_summaries,
         %AppScope{} = scope,
         current_user,
         %{app_path: ["sessions", session_id | _]}
       )
       when is_binary(session_id) do
    with {:ok, session} <-
           EBossChat.get_session_in_workspace(
             session_id,
             scope.current_workspace.id,
             actor: current_user,
             load: ChatPayloads.session_load()
           ),
         {:ok, messages} <-
           EBossChat.list_messages_in_session(
             session.id,
             scope.current_workspace.id,
             actor: current_user,
             load: [created_by_user: []]
           ) do
      state
      |> Map.put(:current_session, ChatPayloads.session_summary(session, scope))
      |> then(fn state ->
        %{
          state: state,
          sessions: session_summaries,
          messages: Enum.map(messages, &ChatPayloads.message_summary/1)
        }
      end)
    else
      {:error, reason} ->
        %{
          state: Map.put(state, :error, chat_error(reason)),
          sessions: session_summaries,
          messages: []
        }
    end
  end

  defp load_chat_session_context(state, session_summaries, _scope, _current_user, _route) do
    %{state: state, sessions: session_summaries, messages: []}
  end

  defp project_update_attrs(params) do
    with {:ok, title} <- optional_text(params, :title),
         {:ok, description} <- optional_text(params, :description),
         {:ok, notes} <- optional_text(params, :notes),
         {:ok, due_at} <- optional_datetime(params, :due_at),
         {:ok, review_at} <- optional_datetime(params, :review_at),
         {:ok, metadata} <- optional_metadata(params, :metadata) do
      attrs =
        %{}
        |> maybe_put_value(:title, title)
        |> maybe_put_value(:description, description)
        |> maybe_put_value(:notes, notes)
        |> maybe_put_value(:due_at, due_at)
        |> maybe_put_value(:review_at, review_at)
        |> maybe_put_value(:metadata, metadata)

      if map_size(attrs) == 0, do: {:error, :invalid_payload}, else: {:ok, attrs}
    end
  end

  defp task_delegation_attrs(params) do
    with {:ok, contact_reference} <- delegation_contact_reference(params),
         {:ok, delegated_summary} <- required_text(params, :delegated_summary),
         {:ok, quality_expectations} <- optional_text(params, :quality_expectations),
         {:ok, deadline_expectations_at} <- optional_datetime(params, :deadline_expectations_at),
         {:ok, follow_up_at} <- optional_datetime(params, :follow_up_at) do
      attrs =
        %{
          contact_reference: contact_reference,
          delegated_summary: delegated_summary
        }
        |> maybe_put_value(:quality_expectations, quality_expectations)
        |> maybe_put_value(:deadline_expectations_at, deadline_expectations_at)
        |> maybe_put_value(:follow_up_at, follow_up_at)

      {:ok, attrs}
    end
  end

  defp delegation_contact_reference(params) do
    case optional_text(params, :contact_id) do
      {:ok, contact_id} when contact_id in [nil, :missing] ->
        with {:ok, contact_name} <- required_text(params, :contact_name) do
          {:ok, {:new, contact_name}}
        end

      {:ok, contact_id} ->
        {:ok, {:existing, contact_id}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp required_text(params, field) do
    case fetch_payload_field(params, field) do
      :missing ->
        {:error, :invalid_payload}

      {:present, value} ->
        normalize_required_text(value)
    end
  end

  defp optional_text(params, field) do
    case fetch_payload_field(params, field) do
      :missing ->
        {:ok, :missing}

      {:present, value} ->
        normalize_optional_text(value)
    end
  end

  defp optional_datetime(params, field) do
    case fetch_payload_field(params, field) do
      :missing -> {:ok, :missing}
      {:present, value} -> normalize_optional_datetime(value)
    end
  end

  defp optional_metadata(params, field) do
    case fetch_payload_field(params, field) do
      :missing -> {:ok, :missing}
      {:present, nil} -> {:ok, %{}}
      {:present, value} when is_map(value) -> {:ok, value}
      {:present, value} when is_binary(value) -> decode_metadata(value)
      {:present, _value} -> {:error, :invalid_payload}
    end
  end

  defp required_status(params, field, allowed_statuses) do
    case fetch_payload_field(params, field) do
      :missing ->
        {:error, :invalid_payload}

      {:present, value} ->
        normalize_status(value, allowed_statuses)
    end
  end

  defp fetch_payload_field(params, field) when is_map(params) do
    string_field = to_string(field)

    cond do
      Map.has_key?(params, string_field) -> {:present, Map.get(params, string_field)}
      Map.has_key?(params, field) -> {:present, Map.get(params, field)}
      true -> :missing
    end
  end

  defp normalize_required_text(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> {:error, :invalid_payload}
      text -> {:ok, text}
    end
  end

  defp normalize_required_text(value) when is_atom(value),
    do: value |> to_string() |> normalize_required_text()

  defp normalize_required_text(_value), do: {:error, :invalid_payload}

  defp normalize_optional_text(nil), do: {:ok, nil}

  defp normalize_optional_text(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> {:ok, nil}
      text -> {:ok, text}
    end
  end

  defp normalize_optional_text(value) when is_atom(value),
    do: value |> to_string() |> normalize_optional_text()

  defp normalize_optional_text(_value), do: {:error, :invalid_payload}

  defp normalize_optional_datetime(nil), do: {:ok, nil}

  defp normalize_optional_datetime(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" ->
        {:ok, nil}

      trimmed ->
        case parse_datetime_value(trimmed) do
          {:ok, datetime} -> {:ok, datetime}
          {:error, :invalid_format} -> parse_date_value(trimmed)
        end
    end
  end

  defp normalize_optional_datetime(value) when is_atom(value),
    do: value |> to_string() |> normalize_optional_datetime()

  defp normalize_optional_datetime(_value), do: {:error, :invalid_payload}

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
      _ -> {:error, :invalid_payload}
    end
  end

  defp decode_metadata(value) do
    case String.trim(value) do
      "" ->
        {:ok, %{}}

      json ->
        case Jason.decode(json) do
          {:ok, decoded} when is_map(decoded) -> {:ok, decoded}
          _ -> {:error, :invalid_payload}
        end
    end
  end

  defp normalize_status(value, allowed_statuses) when is_binary(value) do
    status = String.trim(value)

    case Enum.find(allowed_statuses, &(to_string(&1) == status)) do
      nil -> {:error, :invalid_payload}
      status -> {:ok, status}
    end
  end

  defp normalize_status(value, allowed_statuses) when is_atom(value) do
    if value in allowed_statuses, do: {:ok, value}, else: {:error, :invalid_payload}
  end

  defp normalize_status(_value, _allowed_statuses), do: {:error, :invalid_payload}

  defp maybe_put_value(attrs, _field, :missing), do: attrs
  defp maybe_put_value(attrs, field, value), do: Map.put(attrs, field, value)

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

  defp ensure_task_can_be_marked_waiting_for(%EBossFolio.Task{status: status}) do
    if status in [:inbox, :next_action, :waiting_for, :scheduled, :someday_maybe] do
      :ok
    else
      {:error, {:invalid_task_workflow, "cannot delegate task from #{status} status"}}
    end
  end

  defp resolve_delegation_contact({:existing, contact_id}, workspace_id, actor) do
    EBossFolio.get_contact_in_workspace(contact_id, workspace_id, actor: actor)
  end

  defp resolve_delegation_contact({:new, contact_name}, workspace_id, actor) do
    EBossFolio.create_contact(%{workspace_id: workspace_id, name: contact_name}, actor: actor)
  end

  defp create_task_delegation(task, workspace_id, contact_id, attrs, actor) do
    %{
      workspace_id: workspace_id,
      task_id: task.id,
      contact_id: contact_id,
      delegated_summary: attrs.delegated_summary
    }
    |> maybe_put_value(:quality_expectations, Map.get(attrs, :quality_expectations, :missing))
    |> maybe_put_value(
      :deadline_expectations_at,
      Map.get(attrs, :deadline_expectations_at, :missing)
    )
    |> maybe_put_value(:follow_up_at, Map.get(attrs, :follow_up_at, :missing))
    |> EBossFolio.delegate_task(actor: actor)
  end

  defp load_task_with_delegations(task, workspace_id, actor) do
    EBossFolio.get_task_in_workspace(task.id, workspace_id,
      actor: actor,
      load: [delegations: :contact]
    )
  end

  defp folio_error(%Ash.Error.Invalid{} = error), do: Exception.message(error)
  defp folio_error({:invalid_task_workflow, message}), do: message
  defp folio_error(:invalid_payload), do: "Folio payload could not be processed."
  defp folio_error(:not_found), do: "Folio resource was not found."
  defp folio_error(reason) when is_binary(reason), do: reason
  defp folio_error(reason), do: inspect(reason)

  defp chat_error(%Ash.Error.Forbidden{}), do: "Workspace access is forbidden."
  defp chat_error(%Ash.Error.Invalid{} = error), do: Exception.message(error)
  defp chat_error(:not_found), do: "Chat session not found."
  defp chat_error(:forbidden), do: "Workspace access is forbidden."
  defp chat_error(reason) when is_binary(reason), do: reason
  defp chat_error(reason), do: inspect(reason)

  defp empty_notification_bootstrap do
    %{
      unread_count: 0,
      recent: [],
      preferences: [],
      channels: [],
      supported_channels: Enum.map(EBossNotify.supported_channels(), &to_string/1),
      inactive_external_channels: Enum.map(EBossNotify.inactive_external_channels(), &to_string/1)
    }
  end

  defp user_props(nil), do: %{username: "guest", email: ""}

  defp user_props(user) do
    %{
      username: to_string(Map.get(user, :username)),
      email: to_string(Map.get(user, :email))
    }
  end

  defp scope_props(%AppScope{} = scope) do
    %{
      empty: scope.empty?,
      dashboardPath: scope.dashboard_path,
      currentWorkspace: workspace_props(scope.current_workspace),
      owner: owner_props(scope.owner),
      capabilities: capability_props(scope.capabilities),
      accessibleWorkspaces: Enum.map(scope.accessible_workspaces, &workspace_props/1),
      apps: app_registry_props(scope.apps)
    }
  end

  defp workspace_props(nil), do: nil

  defp workspace_props(workspace) do
    %{
      id: workspace.id,
      name: workspace.name,
      slug: workspace.slug,
      fullPath: workspace.full_path,
      visibility: stringify_optional(workspace.visibility),
      ownerType: owner_type_label(workspace.owner_type),
      ownerSlug: workspace.owner_slug,
      ownerDisplayName: workspace.owner_display_name,
      dashboardPath: workspace.dashboard_path,
      current: Map.get(workspace, :current?, false)
    }
  end

  defp owner_props(nil), do: nil

  defp owner_props(owner) do
    %{
      type: owner_type_label(owner.type),
      slug: owner.slug,
      displayName: owner.display_name
    }
  end

  defp capability_props(capabilities) do
    %{
      readWorkspace: Map.get(capabilities, :read_workspace, false),
      manageWorkspace: Map.get(capabilities, :manage_workspace, false),
      readFolio: Map.get(capabilities, :read_folio, false),
      manageFolio: Map.get(capabilities, :manage_folio, false),
      readChat: Map.get(capabilities, :read_chat, false),
      manageChat: Map.get(capabilities, :manage_chat, false)
    }
  end

  defp app_registry_props(apps) when is_map(apps) do
    apps
    |> Enum.into(%{}, fn {app_key, app} ->
      {to_string(app_key), app_props(app)}
    end)
  end

  defp app_registry_props(_), do: %{}

  defp app_props(app) do
    capabilities = fetch_map_field(app, :capabilities, %{})

    %{
      key: fetch_map_field(app, :key),
      label: fetch_map_field(app, :label),
      defaultPath: fetch_map_field(app, :default_path),
      enabled: fetch_map_field(app, :enabled, false),
      capabilities: %{
        read: fetch_map_field(capabilities, :read, false),
        manage: fetch_map_field(capabilities, :manage, false)
      }
    }
  end

  defp fetch_map_field(map, key, default \\ nil)

  defp fetch_map_field(map, key, default) when is_map(map) do
    Map.get(map, key, Map.get(map, to_string(key), default))
  end

  defp fetch_map_field(_, _key, default), do: default

  defp owner_type_label(:user), do: "user"
  defp owner_type_label(:organization), do: "organization"
  defp owner_type_label(other), do: to_string(other)

  defp stringify_optional(nil), do: nil
  defp stringify_optional(value), do: to_string(value)
end
