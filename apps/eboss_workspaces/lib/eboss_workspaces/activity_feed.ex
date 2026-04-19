defmodule EBoss.Workspaces.ActivityFeed do
  @moduledoc """
  Shared envelope contract for workspace activity feed entries.

  The workspace shell consumes entries in this shape. Apps contribute events through
  a provider module that maps their domain models to this contract.
  """

  @type actor_type :: :system | :user | :telegram_bot | :api_key | :cli | :agent | :bot
  @type status :: :success | :warning | :pending | :info | :error
  @type activity_id :: String.t()
  @type app_key :: String.t()
  @type provider_key :: String.t()

  @type actor :: %{
          required(:type) => actor_type() | String.t(),
          optional(:id) => activity_id() | nil,
          optional(:label) => String.t() | nil
        }

  @type subject :: %{
          required(:type) => String.t(),
          required(:id) => activity_id() | nil,
          optional(:label) => String.t() | nil
        }

  @type t :: %{
          required(:id) => activity_id(),
          required(:app_key) => app_key(),
          required(:provider_key) => provider_key(),
          required(:provider_event_id) => activity_id(),
          required(:occurred_at) => String.t(),
          required(:actor) => actor(),
          required(:action) => String.t(),
          required(:summary) => String.t(),
          required(:subject) => subject(),
          optional(:details) => String.t() | nil,
          optional(:status) => status(),
          optional(:changes) => map() | nil,
          optional(:metadata) => map(),
          optional(:resource_path) => String.t() | nil
        }

  @platform_app_key "workspace"

  @doc """
  App/platform bucket reserved for non-app sources such as memberships or access changes.
  """
  @spec platform_app_key() :: app_key()
  def platform_app_key, do: @platform_app_key

  @doc """
  Builds a normalized event payload for the shared contract.
  """
  @spec build_entry(map()) :: t()
  def build_entry(attrs) when is_map(attrs) do
    attrs
    |> normalize_occurred_at()
    |> Map.put_new(:status, :success)
    |> Map.put_new(:changes, nil)
    |> Map.put_new(:details, nil)
    |> Map.put_new(:metadata, %{})
    |> Map.put_new(:resource_path, nil)
    |> validate_required_fields!()
  end

  defp normalize_occurred_at(%{occurred_at: %DateTime{} = occurred_at} = attrs),
    do: Map.put(attrs, :occurred_at, DateTime.to_iso8601(occurred_at))

  defp normalize_occurred_at(attrs), do: attrs

  defp validate_required_fields!(attrs) do
    required_fields = [
      :id,
      :app_key,
      :provider_key,
      :provider_event_id,
      :occurred_at,
      :actor,
      :action,
      :summary,
      :subject
    ]

    missing_fields =
      required_fields
      |> Enum.filter(fn field -> !Map.has_key?(attrs, field) end)

    if missing_fields == [] do
      attrs
    else
      raise ArgumentError, "missing required activity fields: #{inspect(missing_fields)}"
    end
  end
end

defmodule EBoss.Workspaces.ActivityFeed.Provider do
  @moduledoc """
  Behaviour for workspace activity providers.

  Each app provider maps source events to the shared contract.
  """

  alias EBoss.Workspaces.ActivityFeed

  @callback app_key() :: String.t()
  @callback provider_key() :: String.t()
  @callback to_entry(source_event :: term(), opts :: keyword()) :: ActivityFeed.t()

  @doc """
  Normalize and map a list of source events from a provider.
  """
  @spec map_events(module(), [term()], keyword()) :: [ActivityFeed.t()]
  def map_events(provider, source_events, opts \\ [])
      when is_atom(provider) and is_list(source_events) do
    Enum.map(source_events, &provider.to_entry(&1, opts))
  end
end
