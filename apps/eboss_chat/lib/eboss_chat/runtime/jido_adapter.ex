defmodule EBossChat.Runtime.JidoAdapter do
  @moduledoc false

  @behaviour EBossChat.Runtime.Adapter

  alias EBossChat.Runtime.PromptBuilder
  alias Jido.Agent.InstanceManager
  alias Jido.AgentServer

  @default_timeout_ms 60_000
  @poll_interval_ms 75

  @impl true
  def stream_reply(session_id, history, opts, on_delta)
      when is_binary(session_id) and is_list(history) and is_function(on_delta, 1) do
    chat_model = Keyword.get(opts, :chat_model, EBossChat.default_chat_model())
    manager = chat_model.manager
    agent = chat_model.agent

    try do
      with {:ok, pid} <- InstanceManager.get(manager, session_id),
           :ok <- AgentServer.attach(pid),
           {:ok, request} <-
             agent.ask(
               pid,
               PromptBuilder.build(history, opts),
               timeout: timeout_ms(opts)
             ) do
        task =
          Task.async(fn ->
            agent.await(request, timeout: timeout_ms(opts))
          end)

        await_stream(agent, chat_model, pid, task, on_delta, "")
      end
    after
      safe_detach(manager, session_id)
    end
  end

  defp await_stream(agent, chat_model, pid, task, on_delta, emitted_text) do
    snapshot = current_snapshot(agent, pid)
    streaming_text = snapshot.details[:streaming_text] || ""
    emitted_text = emit_new_delta(streaming_text, emitted_text, on_delta)

    case Task.yield(task, @poll_interval_ms) || Task.yield(task, 0) do
      {:ok, {:ok, body}} ->
        snapshot = current_snapshot(agent, pid)
        streaming_text = snapshot.details[:streaming_text] || body || ""
        _ = emit_new_delta(streaming_text, emitted_text, on_delta)

        usage = snapshot.details[:usage] || %{}

        {:ok,
         %{
           body: body || streaming_text,
           provider: chat_model.provider,
           model: model_label(snapshot.details[:model], chat_model),
           input_tokens: normalize_integer(usage[:input_tokens]),
           output_tokens: normalize_integer(usage[:output_tokens]),
           total_tokens:
             normalize_integer(usage[:total_tokens]) ||
               normalize_integer(usage[:input_tokens]) + normalize_integer(usage[:output_tokens]),
           finish_reason: to_string(snapshot.details[:termination_reason] || "stop")
         }}

      {:ok, {:error, reason}} ->
        {:error, reason}

      nil ->
        await_stream(agent, chat_model, pid, task, on_delta, emitted_text)
    end
  end

  defp current_snapshot(agent, pid) do
    with {:ok, state} <- AgentServer.state(pid) do
      agent.strategy_snapshot(state.agent)
    else
      _ -> %{details: %{}, result: nil}
    end
  end

  defp emit_new_delta(streaming_text, emitted_text, on_delta) do
    if String.starts_with?(streaming_text, emitted_text) do
      delta = String.replace_prefix(streaming_text, emitted_text, "")

      if delta != "" do
        on_delta.(delta)
      end

      streaming_text
    else
      emitted_text
    end
  end

  defp model_label(nil, chat_model), do: chat_model.model
  defp model_label(model, _chat_model) when is_binary(model), do: model
  defp model_label(model, _chat_model), do: Jido.AI.model_label(model)

  defp normalize_integer(nil), do: 0
  defp normalize_integer(value) when is_integer(value), do: value
  defp normalize_integer(value) when is_float(value), do: trunc(value)
  defp normalize_integer(_value), do: 0

  defp timeout_ms(opts), do: Keyword.get(opts, :timeout_ms, @default_timeout_ms)

  defp safe_detach(manager, session_id) do
    case InstanceManager.lookup(manager, session_id) do
      {:ok, pid} -> AgentServer.detach(pid)
      :error -> :ok
    end
  end
end
