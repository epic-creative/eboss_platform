defmodule EBossFolio.ActivityFeedProvider do
  @moduledoc """
  Maps `EBossFolio.RevisionEvent` records into the workspace activity feed contract.
  """

  @behaviour EBoss.Workspaces.ActivityFeed.Provider

  alias EBoss.Workspaces.ActivityFeed
  alias EBoss.Workspaces.ActivityFeed.Provider

  @app_key "folio"
  @provider_key "revision_event"

  @doc """
  App key used by the workspace shell contract.
  """
  @impl true
  def app_key, do: @app_key

  @doc """
  Provider identity used to disambiguate multiple sources from the same app.
  """
  @impl true
  def provider_key, do: @provider_key

  @doc """
  Maps one revision event into the shared activity feed contract.
  """
  @impl true
  def to_entry(%EBossFolio.RevisionEvent{} = revision_event, _opts) do
    ActivityFeed.build_entry(%{
      id: revision_event.id,
      app_key: @app_key,
      provider_key: @provider_key,
      provider_event_id: revision_event.id,
      occurred_at: revision_event.occurred_at,
      actor: actor_entry(revision_event),
      action: to_string(revision_event.action),
      summary: build_summary(revision_event),
      subject: %{
        type: to_string(revision_event.resource_type),
        id: revision_event.resource_id,
        label: nil
      },
      details: revision_event.reason,
      status: derive_status(revision_event.action),
      changes: revision_event.diff,
      metadata: %{
        reason: revision_event.reason,
        workspace_id: revision_event.workspace_id,
        source: to_string(revision_event.source),
        correlation_id: revision_event.correlation_id
      }
    })
  end

  @doc """
  Maps a collection of revision events into contract entries.
  """
  def map_events(revision_events, opts \\ []) when is_list(revision_events) do
    Provider.map_events(__MODULE__, revision_events, opts)
  end

  defp actor_entry(%EBossFolio.RevisionEvent{actor_type: actor_type, actor_id: actor_id}) do
    %{
      type: actor_type || :system,
      id: actor_id,
      label: actor_label(actor_type, actor_id)
    }
  end

  defp actor_label(:user, actor_id), do: "user:#{actor_id}"
  defp actor_label(:system, _actor_id), do: "system"
  defp actor_label(:cli, _actor_id), do: "cli"
  defp actor_label(:telegram_bot, _actor_id), do: "telegram bot"
  defp actor_label(:api_key, _actor_id), do: "api key"
  defp actor_label(:agent, _actor_id), do: "agent"
  defp actor_label(:bot, _actor_id), do: "bot"
  defp actor_label(_, nil), do: "system"
  defp actor_label(_, actor_id), do: "actor:#{actor_id}"

  defp build_summary(%EBossFolio.RevisionEvent{
         action: action,
         resource_type: resource_type,
         resource_id: resource_id
       }) do
    "#{action_to_label(action)} #{to_string(resource_type)} #{resource_id}"
  end

  defp action_to_label(:create), do: "created"
  defp action_to_label(:update), do: "updated"
  defp action_to_label(:transition), do: "transitioned"
  defp action_to_label(:delete), do: "deleted"
  defp action_to_label(:attach), do: "attached"
  defp action_to_label(:detach), do: "detached"
  defp action_to_label(:expand), do: "expanded"
  defp action_to_label(:import), do: "imported"
  defp action_to_label(:policy_apply), do: "updated policy for"
  defp action_to_label(other), do: to_string(other)

  defp derive_status(:delete), do: :warning
  defp derive_status(_action), do: :success
end
