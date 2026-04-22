defmodule EBossWeb.ChatPayloads do
  @moduledoc false

  alias Ash.NotLoaded
  alias EBossWeb.AppScope

  def session_load do
    [
      :message_count,
      :total_input_tokens,
      :total_output_tokens,
      :total_tokens_sum,
      created_by_user: []
    ]
  end

  def scope_summary(%AppScope{} = scope) do
    app = Map.get(scope.apps, "chat", %{})

    %{
      app_key: "chat",
      workspace: scope.current_workspace,
      owner: scope.owner,
      app: normalize_payload_map(app),
      capabilities: payload_map_get(app, :capabilities, %{}),
      workspace_path: Map.get(scope.current_workspace, :dashboard_path),
      app_path: payload_map_get(app, :default_path)
    }
  end

  def session_summary(session, %AppScope{} = scope) do
    %{
      id: session.id,
      title: session.title,
      status: session.status,
      last_message_at: session.last_message_at,
      last_activity_at: session.last_activity_at,
      message_count: Map.get(session, :message_count, 0),
      usage_totals: %{
        input_tokens: Map.get(session, :total_input_tokens, 0) || 0,
        output_tokens: Map.get(session, :total_output_tokens, 0) || 0,
        total_tokens: Map.get(session, :total_tokens_sum, 0) || 0
      },
      created_by_user: user_summary(session.created_by_user),
      path: "#{scope.dashboard_path}/apps/chat/sessions/#{session.id}"
    }
  end

  def message_summary(message) do
    %{
      id: message.id,
      role: message.role,
      body: message.body,
      status: message.status,
      sequence: message.sequence,
      provider: message.provider,
      model: message.model,
      input_tokens: message.input_tokens || 0,
      output_tokens: message.output_tokens || 0,
      total_tokens: message.total_tokens || 0,
      finish_reason: message.finish_reason,
      error_message: message.error_message,
      inserted_at: message.inserted_at,
      author: user_summary(message.created_by_user)
    }
  end

  def serialize_stream_payload(%{session: session, message: message}) do
    %{
      session: %{id: session.id, workspace_id: session.workspace_id},
      message: message_summary(message)
    }
  end

  def serialize_stream_payload(%{session_id: session_id, delta: delta}) do
    %{session_id: session_id, delta: delta}
  end

  def serialize_stream_payload(%{} = payload), do: normalize_payload_map(payload)
  def serialize_stream_payload(payload), do: payload

  defp user_summary(nil), do: nil
  defp user_summary(%NotLoaded{}), do: nil

  defp user_summary(user) do
    %{
      id: user.id,
      username: user.username,
      email: to_string(user.email)
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
end
