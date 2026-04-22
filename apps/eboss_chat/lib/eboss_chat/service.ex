defmodule EBossChat.Service do
  @moduledoc false

  alias EBossChat.ChatMessage
  alias EBossChat.ChatSession

  def create_session(workspace_id, title_seed, opts \\ []) when is_binary(workspace_id) do
    EBossChat.create_chat_session(
      %{
        workspace_id: workspace_id,
        title_seed: title_seed
      },
      opts
    )
  end

  def archive_session(%ChatSession{} = session, opts \\ []) do
    EBossChat.archive_chat_session(session, opts)
  end

  def stream_session_reply(%ChatSession{} = session, body, opts \\ []) when is_binary(body) do
    actor = Keyword.fetch!(opts, :actor)
    emit = Keyword.get(opts, :emit, fn _event, _payload -> :ok end)
    chat_model = Keyword.get(opts, :chat_model, EBossChat.default_chat_model())

    recent_history_limit =
      Keyword.get(opts, :recent_history_limit, EBossChat.recent_history_limit())

    with :ok <- ensure_active_session(session),
         :ok <- ensure_available(session.id),
         {:ok, user_message} <- create_user_message(session, actor, body),
         {:ok, assistant_message} <- create_pending_assistant_message(session, chat_model),
         :ok <- emit.(:user_message_committed, %{session: session, message: user_message}),
         :ok <- emit.(:assistant_started, %{session: session, message: assistant_message}),
         {:ok, history} <- recent_history(session, recent_history_limit, actor),
         {:ok, result} <- stream_reply_via_adapter(session, history, chat_model, emit) do
      complete_assistant(session, assistant_message, result, emit)
    else
      {:error, :session_busy} ->
        {:error, :session_busy}

      {:error, reason} ->
        if match?(
             {:ok, %ChatMessage{}},
             EBossChat.active_assistant_message(session.id, authorize?: false)
           ) do
          case EBossChat.active_assistant_message(session.id, authorize?: false) do
            {:ok, %ChatMessage{} = assistant_message} ->
              fail_assistant(session, assistant_message, reason, chat_model, emit)

            _ ->
              {:error, format_error(reason)}
          end
        else
          {:error, format_error(reason)}
        end
    end
  end

  defp ensure_active_session(%ChatSession{status: :archived}), do: {:error, :session_archived}
  defp ensure_active_session(_session), do: :ok

  defp ensure_available(session_id) do
    case EBossChat.active_assistant_message(session_id, authorize?: false) do
      {:ok, nil} -> :ok
      {:ok, _message} -> {:error, :session_busy}
      {:error, _reason} -> :ok
    end
  end

  defp create_user_message(session, actor, body) do
    now = DateTime.utc_now()

    with {:ok, message} <-
           EBossChat.create_chat_message(
             %{
               session_id: session.id,
               workspace_id: session.workspace_id,
               role: :user,
               body: String.trim(body),
               status: :complete,
               sequence: EBossChat.next_sequence_for_session(session.id),
               created_by_user_id: actor.id
             },
             actor: actor
           ),
         {:ok, _session} <-
           EBossChat.touch_chat_session_activity(
             session,
             %{last_message_at: now, last_activity_at: now},
             actor: actor
           ) do
      {:ok, message}
    end
  end

  defp create_pending_assistant_message(session, chat_model) do
    EBossChat.create_chat_message(
      %{
        session_id: session.id,
        workspace_id: session.workspace_id,
        role: :assistant,
        body: "",
        status: :pending,
        provider: chat_model.provider,
        model: chat_model.model,
        sequence: EBossChat.next_sequence_for_session(session.id),
        created_by_user_id: nil
      },
      authorize?: false
    )
  rescue
    _error -> {:error, :session_busy}
  end

  defp recent_history(session, limit, actor) do
    case EBossChat.list_messages_in_session(
           session.id,
           session.workspace_id,
           actor: actor,
           load: [created_by_user: []]
         ) do
      {:ok, messages} ->
        recent =
          messages
          |> Enum.take(-limit)
          |> Enum.map(fn message ->
            %{
              role: message.role,
              body: message.body,
              author: message_author(message)
            }
          end)

        {:ok, recent}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp stream_reply_via_adapter(session, history, chat_model, emit) do
    adapter = EBossChat.chat_runtime_adapter()

    adapter.stream_reply(
      session.id,
      history,
      [
        workspace_name: session.title,
        owner_label: session.workspace_id,
        chat_model: chat_model,
        timeout_ms: 60_000
      ],
      fn delta ->
        _ = emit.(:assistant_delta, %{session_id: session.id, delta: delta})
      end
    )
  end

  defp complete_assistant(session, assistant_message, result, emit) do
    now = DateTime.utc_now()

    with {:ok, message} <-
           EBossChat.mark_chat_message_complete(
             assistant_message,
             %{
               body: result.body,
               provider: result.provider,
               model: result.model,
               input_tokens: result.input_tokens,
               output_tokens: result.output_tokens,
               total_tokens: result.total_tokens,
               finish_reason: result.finish_reason
             },
             authorize?: false
           ),
         {:ok, _session} <-
           EBossChat.touch_chat_session_activity(
             session,
             %{last_message_at: now, last_activity_at: now},
             authorize?: false
           ) do
      _ = emit.(:assistant_completed, %{session: session, message: message})
      {:ok, %{session: session, assistant_message: message}}
    end
  end

  def fail_assistant(session, assistant_message, reason, chat_model, emit) do
    with {:ok, message} <-
           EBossChat.mark_chat_message_error(
             assistant_message,
             %{
               error_message: format_error(reason),
               provider: chat_model.provider,
               model: chat_model.model,
               finish_reason: "error"
             },
             authorize?: false
           ),
         {:ok, _session} <-
           EBossChat.touch_chat_session_activity(
             session,
             %{last_activity_at: DateTime.utc_now()},
             authorize?: false
           ) do
      _ = emit.(:assistant_failed, %{session: session, message: message})
      {:error, format_error(reason)}
    end
  end

  defp message_author(%ChatMessage{created_by_user: %{username: username}}), do: username
  defp message_author(%ChatMessage{created_by_user: %{email: email}}), do: to_string(email)
  defp message_author(_message), do: nil

  defp format_error(%{message: message}) when is_binary(message), do: message
  defp format_error({:error, reason}), do: format_error(reason)
  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: "Chat request failed: #{inspect(reason)}"
end
