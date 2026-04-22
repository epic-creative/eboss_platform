defmodule EBossChat do
  @moduledoc """
  Workspace-scoped chat domain for collaborative AI conversations.
  """

  use Ash.Domain, otp_app: :eboss_chat

  import Ash.Expr
  require Ash.Query

  alias EBossChat.ChatMessage
  alias EBossChat.ChatSession

  resources do
    resource EBossChat.ChatSession do
      define(:create_chat_session, action: :create)
      define(:archive_chat_session, action: :archive)
      define(:touch_chat_session_activity, action: :touch_activity)
      define(:get_chat_session, action: :read, get_by: [:id])
    end

    resource EBossChat.ChatMessage do
      define(:create_chat_message, action: :create)
      define(:mark_chat_message_complete, action: :mark_complete)
      define(:mark_chat_message_error, action: :mark_error)
      define(:get_chat_message, action: :read, get_by: [:id])
    end
  end

  def list_sessions_in_workspace(workspace_id, opts \\ []) when is_binary(workspace_id) do
    workspace_id
    |> sessions_query()
    |> Ash.read(opts)
  end

  def list_active_sessions_in_workspace(workspace_id, opts \\ []) when is_binary(workspace_id) do
    workspace_id
    |> sessions_query()
    |> Ash.Query.filter(expr(status == :active))
    |> Ash.read(opts)
  end

  def get_session_in_workspace(session_id, workspace_id, opts \\ [])
      when is_binary(session_id) and is_binary(workspace_id) do
    if valid_uuid?(session_id) and valid_uuid?(workspace_id) do
      case ChatSession
           |> Ash.Query.for_read(:read)
           |> Ash.Query.filter(expr(id == ^session_id and workspace_id == ^workspace_id))
           |> Ash.read_one(opts) do
        {:ok, nil} -> {:error, :not_found}
        result -> result
      end
    else
      {:error, :not_found}
    end
  end

  def get_session_in_workspace!(session_id, workspace_id, opts \\ [])
      when is_binary(session_id) and is_binary(workspace_id) do
    case get_session_in_workspace(session_id, workspace_id, opts) do
      {:ok, session} -> session
      {:error, reason} -> raise reason
    end
  end

  def list_messages_in_session(session_id, workspace_id, opts \\ [])
      when is_binary(session_id) and is_binary(workspace_id) do
    if valid_uuid?(session_id) and valid_uuid?(workspace_id) do
      ChatMessage
      |> Ash.Query.for_read(:read)
      |> Ash.Query.filter(expr(session_id == ^session_id and workspace_id == ^workspace_id))
      |> Ash.Query.sort(sequence: :asc)
      |> Ash.read(opts)
    else
      {:error, :not_found}
    end
  end

  def next_sequence_for_session(session_id, opts \\ []) when is_binary(session_id) do
    case ChatMessage
         |> Ash.Query.for_read(:read)
         |> Ash.Query.filter(expr(session_id == ^session_id))
         |> Ash.Query.sort(sequence: :desc)
         |> Ash.Query.limit(1)
         |> Ash.read_one(Keyword.put(opts, :authorize?, false)) do
      {:ok, nil} -> 1
      {:ok, message} -> message.sequence + 1
      {:error, _reason} -> 1
    end
  end

  def active_assistant_message(session_id, opts \\ []) when is_binary(session_id) do
    ChatMessage
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(
      expr(session_id == ^session_id and role == :assistant and status == :pending)
    )
    |> Ash.read_one(opts)
  end

  def usage_totals_for_sessions(sessions) when is_list(sessions) do
    Enum.reduce(
      sessions,
      %{sessions: 0, input_tokens: 0, output_tokens: 0, total_tokens: 0},
      fn session, acc ->
        %{
          sessions: acc.sessions + 1,
          input_tokens:
            acc.input_tokens + normalize_integer(Map.get(session, :total_input_tokens)),
          output_tokens:
            acc.output_tokens + normalize_integer(Map.get(session, :total_output_tokens)),
          total_tokens: acc.total_tokens + normalize_integer(Map.get(session, :total_tokens_sum))
        }
      end
    )
  end

  def chat_runtime_adapter do
    Application.fetch_env!(:eboss_chat, :runtime_adapter)
  end

  def recent_history_limit do
    Application.get_env(:eboss_chat, :recent_history_limit, 40)
  end

  def chat_model_options, do: EBossChat.ModelCatalog.public_options()

  def default_chat_model_key, do: EBossChat.ModelCatalog.default_key()

  def default_chat_model, do: EBossChat.ModelCatalog.default_option()

  def resolve_chat_model(key), do: EBossChat.ModelCatalog.resolve(key)

  defp sessions_query(workspace_id) do
    ChatSession
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(expr(workspace_id == ^workspace_id))
    |> Ash.Query.load([
      :message_count,
      :total_input_tokens,
      :total_output_tokens,
      :total_tokens_sum,
      created_by_user: []
    ])
    |> Ash.Query.sort(last_activity_at: :desc, inserted_at: :desc)
  end

  defp normalize_integer(nil), do: 0
  defp normalize_integer(value) when is_integer(value), do: value
  defp normalize_integer(value) when is_float(value), do: trunc(value)
  defp normalize_integer(_value), do: 0

  defp valid_uuid?(value) when is_binary(value), do: match?({:ok, _uuid}, Ecto.UUID.cast(value))
  defp valid_uuid?(_value), do: false
end
