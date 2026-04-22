defmodule EBossChat.Runtime.Adapter do
  @moduledoc false

  @type history_message :: %{
          role: :user | :assistant | :system,
          body: String.t(),
          author: String.t() | nil
        }

  @type result :: %{
          body: String.t(),
          provider: String.t(),
          model: String.t(),
          input_tokens: non_neg_integer(),
          output_tokens: non_neg_integer(),
          total_tokens: non_neg_integer(),
          finish_reason: String.t()
        }

  @callback stream_reply(
              session_id :: String.t(),
              history :: [history_message()],
              opts :: keyword(),
              on_delta :: (String.t() -> any())
            ) :: {:ok, result()} | {:error, term()}
end
