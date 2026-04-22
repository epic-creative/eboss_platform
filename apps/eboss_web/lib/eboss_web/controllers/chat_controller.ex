defmodule EBossWeb.ChatController do
  use EBossWeb, :controller

  alias Ash.PlugHelpers
  alias EBossChat
  alias EBossChat.Service
  alias EBossNotify
  alias EBossWeb.AppScope
  alias EBossWeb.ChatPayloads

  @stream_conn_key {__MODULE__, :stream_conn}

  def bootstrap(conn, %{"owner_slug" => owner_slug, "slug" => slug}) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    with {:ok, scope} <- fetch_scope(current_user, owner_slug, slug),
         :ok <- authorize_chat(scope),
         {:ok, sessions} <-
           EBossChat.list_active_sessions_in_workspace(scope.current_workspace.id,
             actor: current_user
           ) do
      json(conn, %{
        scope: ChatPayloads.scope_summary(scope),
        default_model_key: EBossChat.default_chat_model_key(),
        models: EBossChat.chat_model_options(),
        usage_totals: EBossChat.usage_totals_for_sessions(sessions),
        sessions: Enum.map(sessions, &ChatPayloads.session_summary(&1, scope))
      })
    else
      {:error, reason} -> render_scope_error(conn, reason)
    end
  end

  def index(conn, %{"owner_slug" => owner_slug, "slug" => slug}) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    with {:ok, scope} <- fetch_scope(current_user, owner_slug, slug),
         :ok <- authorize_chat(scope),
         {:ok, sessions} <-
           EBossChat.list_active_sessions_in_workspace(scope.current_workspace.id,
             actor: current_user
           ) do
      json(conn, %{
        scope: ChatPayloads.scope_summary(scope),
        sessions: Enum.map(sessions, &ChatPayloads.session_summary(&1, scope))
      })
    else
      {:error, reason} -> render_scope_error(conn, reason)
    end
  end

  def create(conn, %{"owner_slug" => owner_slug, "slug" => slug}) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)
    title_seed = parse_title_seed(conn.body_params)

    with {:ok, scope} <- fetch_scope(current_user, owner_slug, slug),
         :ok <- authorize_chat(scope),
         {:ok, session} <-
           Service.create_session(scope.current_workspace.id, title_seed, actor: current_user),
         {:ok, session} <-
           EBossChat.get_session_in_workspace(
             session.id,
             scope.current_workspace.id,
             actor: current_user,
             load: ChatPayloads.session_load()
           ) do
      notify_chat_session_created(scope, session, current_user)

      conn
      |> put_status(:created)
      |> json(%{
        scope: ChatPayloads.scope_summary(scope),
        session: ChatPayloads.session_summary(session, scope)
      })
    else
      {:error, reason} ->
        error_json(conn, :bad_request, "invalid_chat_session", format_error(reason))
    end
  end

  def show(conn, %{"owner_slug" => owner_slug, "slug" => slug, "session_id" => session_id}) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    with {:ok, scope} <- fetch_scope(current_user, owner_slug, slug),
         :ok <- authorize_chat(scope),
         {:ok, session} <-
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
      json(conn, %{
        scope: ChatPayloads.scope_summary(scope),
        session: ChatPayloads.session_summary(session, scope),
        messages: Enum.map(messages, &ChatPayloads.message_summary/1)
      })
    else
      {:error, :not_found} ->
        error_json(conn, :not_found, "chat_session_not_found", "Chat session not found")

      {:error, reason} ->
        render_scope_error(conn, reason)
    end
  end

  def update(conn, %{"owner_slug" => owner_slug, "slug" => slug, "session_id" => session_id}) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)

    with {:ok, scope} <- fetch_scope(current_user, owner_slug, slug),
         :ok <- authorize_chat(scope),
         {:ok, session} <-
           EBossChat.get_session_in_workspace(
             session_id,
             scope.current_workspace.id,
             actor: current_user,
             load: ChatPayloads.session_load()
           ),
         :ok <- validate_session_update(conn.body_params),
         {:ok, session} <- Service.archive_session(session, actor: current_user) do
      json(conn, %{
        scope: ChatPayloads.scope_summary(scope),
        session: ChatPayloads.session_summary(session, scope)
      })
    else
      {:error, :not_found} ->
        error_json(conn, :not_found, "chat_session_not_found", "Chat session not found")

      {:error, %Ash.Error.Forbidden{}} ->
        error_json(conn, :forbidden, "workspace_forbidden", "Workspace access is forbidden")

      {:error, :invalid_payload} ->
        error_json(
          conn,
          :bad_request,
          "invalid_chat_session_update",
          "Chat session payload could not be processed"
        )

      {:error, reason} ->
        error_json(conn, :bad_request, "invalid_chat_session_update", format_error(reason))
    end
  end

  def stream(conn, %{"owner_slug" => owner_slug, "slug" => slug, "session_id" => session_id}) do
    current_user = conn.assigns[:current_user] || PlugHelpers.get_actor(conn)
    body = parse_message_body(conn.body_params)
    model_key = parse_model_key(conn.body_params)

    with {:ok, scope} <- fetch_scope(current_user, owner_slug, slug),
         :ok <- authorize_chat(scope),
         {:ok, chat_model} <- EBossChat.resolve_chat_model(model_key),
         {:ok, session} <-
           EBossChat.get_session_in_workspace(
             session_id,
             scope.current_workspace.id,
             actor: current_user,
             load: ChatPayloads.session_load()
           ),
         :ok <- validate_message_body(body),
         :ok <- validate_streamable_session(session),
         :ok <- ensure_session_available(session) do
      conn = initialize_stream(conn)

      case chunk_event(conn, "stream_ready", %{session_id: session.id}) do
        :ok ->
          case Service.stream_session_reply(session, body,
                 actor: current_user,
                 chat_model: chat_model,
                 emit: &stream_event/2
               ) do
            {:ok, _result} ->
              final_conn(conn)

            {:error, reason} ->
              notify_chat_run_failed(scope, session, current_user, reason)
              final_conn(conn)
          end

        {:error, _reason} ->
          final_conn(conn)
      end
    else
      {:error, :session_busy} ->
        error_json(conn, :conflict, "chat_session_busy", "An assistant reply is already running")

      {:error, :session_archived} ->
        error_json(
          conn,
          :conflict,
          "chat_session_archived",
          "Archived chat sessions cannot be continued"
        )

      {:error, :not_found} ->
        error_json(conn, :not_found, "chat_session_not_found", "Chat session not found")

      {:error, :unsupported_chat_model} ->
        error_json(
          conn,
          :bad_request,
          "unsupported_chat_model",
          "Requested chat model is not supported"
        )

      {:error, reason} ->
        render_scope_error(conn, reason)
    end
  end

  defp fetch_scope(current_user, owner_slug, slug) do
    case AppScope.fetch_workspace_scope(current_user, owner_slug, slug) do
      {:ok, %AppScope{} = scope} -> {:ok, scope}
      {:error, reason} -> {:error, reason}
    end
  end

  defp authorize_chat(%AppScope{} = scope) do
    if Map.get(scope.capabilities, :read_chat, false) do
      :ok
    else
      {:error, :forbidden}
    end
  end

  defp ensure_session_available(session) do
    case EBossChat.active_assistant_message(session.id, authorize?: false) do
      {:ok, nil} -> :ok
      {:ok, _message} -> {:error, :session_busy}
      {:error, _reason} -> :ok
    end
  end

  defp validate_streamable_session(%{status: :archived}), do: {:error, :session_archived}
  defp validate_streamable_session(_session), do: :ok

  defp validate_session_update(%{"status" => "archived"}), do: :ok
  defp validate_session_update(%{status: :archived}), do: :ok
  defp validate_session_update(_payload), do: {:error, :invalid_payload}

  defp validate_message_body(body) when is_binary(body) and body != "", do: :ok
  defp validate_message_body(_body), do: {:error, :invalid_payload}

  defp initialize_stream(conn) do
    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("x-accel-buffering", "no")
      |> send_chunked(200)

    Process.put(@stream_conn_key, conn)
    conn
  end

  defp stream_event(event, payload) do
    case Process.get(@stream_conn_key) do
      %Plug.Conn{} = conn ->
        chunk_event(conn, to_string(event), payload)

      _ ->
        :ok
    end
  end

  defp notify_chat_session_created(%AppScope{} = scope, session, actor) do
    attrs = %{
      scope_type: :app,
      scope_id: scope.current_workspace.id,
      workspace_id: scope.current_workspace.id,
      app_key: "chat",
      notification_key: "chat.session_created",
      title: "New shared chat session",
      body: "#{user_label(actor)} started #{session.title}.",
      severity: :info,
      actor_type: :user,
      actor_id: actor.id,
      subject_type: "chat_session",
      subject_id: session.id,
      subject_label: session.title,
      action_url: "#{scope.dashboard_path}/apps/chat/sessions/#{session.id}",
      idempotency_key: "chat.session_created:#{session.id}"
    }

    _ =
      EBossNotify.notify(attrs, {:app, scope.current_workspace.id, "chat"},
        exclude_user_ids: [actor.id]
      )

    :ok
  end

  defp notify_chat_run_failed(%AppScope{} = scope, session, actor, reason) do
    attrs = %{
      scope_type: :app,
      scope_id: scope.current_workspace.id,
      workspace_id: scope.current_workspace.id,
      app_key: "chat",
      notification_key: "chat.assistant_run_failed",
      title: "Chat assistant failed",
      body: format_error(reason),
      severity: :error,
      actor_type: :agent,
      subject_type: "chat_session",
      subject_id: session.id,
      subject_label: session.title,
      action_url: "#{scope.dashboard_path}/apps/chat/sessions/#{session.id}",
      idempotency_key:
        "chat.assistant_run_failed:#{session.id}:#{System.unique_integer([:positive])}"
    }

    _ = EBossNotify.notify(attrs, {:user, actor})
    :ok
  end

  defp user_label(%{username: username}) when is_binary(username) and username != "", do: username
  defp user_label(%{email: email}) when is_binary(email), do: email
  defp user_label(_actor), do: "A workspace member"

  defp chunk_event(conn, event, payload) do
    encoded = Jason.encode!(ChatPayloads.serialize_stream_payload(payload))

    case chunk(conn, "event: #{event}\ndata: #{encoded}\n\n") do
      {:ok, next_conn} ->
        Process.put(@stream_conn_key, next_conn)
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp final_conn(_conn) do
    Process.get(@stream_conn_key)
  end

  defp parse_title_seed(%{"title_seed" => title_seed}) when is_binary(title_seed),
    do: String.trim(title_seed)

  defp parse_title_seed(%{title_seed: title_seed}) when is_binary(title_seed),
    do: String.trim(title_seed)

  defp parse_title_seed(_payload), do: ""

  defp parse_message_body(%{"body" => body}), do: normalize_body(body)
  defp parse_message_body(%{body: body}), do: normalize_body(body)
  defp parse_message_body(_payload), do: ""

  defp normalize_body(body) when is_binary(body), do: String.trim(body)
  defp normalize_body(_body), do: ""

  defp parse_model_key(%{"model_key" => model_key}) when is_binary(model_key),
    do: String.trim(model_key)

  defp parse_model_key(%{model_key: model_key}) when is_binary(model_key),
    do: String.trim(model_key)

  defp parse_model_key(_payload), do: nil

  defp render_scope_error(conn, :unauthorized) do
    error_json(conn, :unauthorized, "authentication_required", "Authentication is required")
  end

  defp render_scope_error(conn, :forbidden) do
    error_json(conn, :forbidden, "workspace_forbidden", "Workspace access is forbidden")
  end

  defp render_scope_error(conn, :not_found) do
    error_json(conn, :not_found, "workspace_not_found", "Workspace not found")
  end

  defp render_scope_error(conn, reason) do
    error_json(conn, :bad_request, "invalid_chat_request", format_error(reason))
  end

  defp error_json(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(%{error: %{code: code, message: message}})
  end

  defp format_error(%Ash.Error.Invalid{} = error), do: Exception.message(error)
  defp format_error(%{message: message}) when is_binary(message), do: message
  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: "Chat request failed: #{inspect(reason)}"
end
