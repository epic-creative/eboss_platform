defmodule EBossChat.Runtime.FakeAdapter do
  @moduledoc false

  @behaviour EBossChat.Runtime.Adapter

  @impl true
  def stream_reply(_session_id, history, opts, on_delta) do
    chat_model = Keyword.get(opts, :chat_model, EBossChat.default_chat_model())

    user_message =
      history
      |> Enum.reverse()
      |> Enum.find_value(fn
        %{role: :user, body: body} when is_binary(body) -> body
        _ -> nil
      end)
      |> Kernel.||("Hello from EBoss chat.")

    if String.contains?(String.downcase(user_message), "fail chat") do
      {:error, %{message: "The fake chat runtime rejected this request."}}
    else
      response = "#{mock_label(chat_model)} mock reply: #{user_message}"

      response
      |> chunk_text()
      |> Enum.each(on_delta)

      input_tokens = max(div(String.length(user_message), 4), 1)
      output_tokens = max(div(String.length(response), 4), 1)

      {:ok,
       %{
         body: response,
         provider: chat_model.provider,
         model: chat_model.model,
         input_tokens: input_tokens,
         output_tokens: output_tokens,
         total_tokens: input_tokens + output_tokens,
         finish_reason: "stop"
       }}
    end
  end

  defp chunk_text(text) when is_binary(text) do
    text
    |> String.graphemes()
    |> Enum.chunk_every(18)
    |> Enum.map(&Enum.join/1)
  end

  defp mock_label(%{provider: "openai"}), do: "OpenAI"
  defp mock_label(_chat_model), do: "Haiku"
end
