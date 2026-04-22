defmodule EBossChat.ModelCatalog do
  @moduledoc false

  @type option :: %{
          key: String.t(),
          label: String.t(),
          provider: String.t(),
          model: String.t(),
          model_alias: atom(),
          manager: atom(),
          agent: module()
        }

  @default_key "anthropic_haiku_4_5"

  @options [
    %{
      key: "anthropic_haiku_4_5",
      label: "Claude Haiku 4.5",
      provider: "anthropic",
      model_alias: :workspace_chat_anthropic,
      manager: :workspace_chat_anthropic_sessions,
      agent: EBossChat.WorkspaceChatAgent
    },
    %{
      key: "openai_gpt_4o_mini",
      label: "OpenAI GPT-4o mini",
      provider: "openai",
      model_alias: :workspace_chat_openai,
      manager: :workspace_chat_openai_sessions,
      agent: EBossChat.WorkspaceChatOpenAIAgent
    }
  ]

  @spec options() :: [option()]
  def options do
    @options
    |> Enum.map(&normalize_option/1)
  end

  @spec public_options() :: [map()]
  def public_options do
    Enum.map(options(), fn option ->
      %{
        key: option.key,
        label: option.label,
        provider: option.provider,
        model: option.model
      }
    end)
  end

  @spec default_key() :: String.t()
  def default_key, do: @default_key

  @spec default_option() :: option()
  def default_option do
    {:ok, option} = resolve(nil)
    option
  end

  @spec resolve(String.t() | nil) :: {:ok, option()} | {:error, :unsupported_chat_model}
  def resolve(nil), do: resolve(default_key())
  def resolve(""), do: resolve(default_key())

  def resolve(key) when is_binary(key) do
    case Enum.find(options(), &(&1.key == key)) do
      nil -> {:error, :unsupported_chat_model}
      option -> {:ok, option}
    end
  end

  def resolve(_key), do: {:error, :unsupported_chat_model}

  defp normalize_option(%{} = option) do
    model_alias = Map.fetch!(option, :model_alias)

    option
    |> Map.put(:model, Jido.AI.model_label(model_alias))
    |> Map.update!(:key, &to_string/1)
    |> Map.update!(:label, &to_string/1)
    |> Map.update!(:provider, &to_string/1)
  end
end
