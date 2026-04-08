defmodule EBossFolio.Changes.AuditAction do
  use Ash.Resource.Change

  alias EBossFolio.RevisionEvent

  @future_actions [
    :create,
    :update,
    :delete,
    :transition,
    :attach,
    :detach,
    :expand,
    :import,
    :policy_apply
  ]

  @impl true
  def change(changeset, opts, context) do
    event_action = Keyword.fetch!(opts, :event_action)

    if event_action not in @future_actions do
      raise ArgumentError, "unsupported Folio audit action: #{inspect(event_action)}"
    end

    Ash.Changeset.after_action(changeset, fn changeset, record ->
      attrs = build_revision_attrs(changeset, record, context, event_action)

      RevisionEvent
      |> Ash.Changeset.for_create(:record, attrs)
      |> Ash.create!(domain: EBossFolio, authorize?: false)

      {:ok, record}
    end)
  end

  defp build_revision_attrs(changeset, record, context, event_action) do
    before_snapshot = before_snapshot(changeset, event_action)
    after_snapshot = snapshot(record)
    audit_meta = audit_metadata(context)

    %{
      workspace_id: record.workspace_id,
      resource_type: resource_type(record.__struct__),
      resource_id: record.id,
      action: event_action,
      actor_type: audit_meta.actor_type,
      actor_id: audit_meta.actor_id,
      source: audit_meta.source,
      occurred_at: DateTime.utc_now(),
      before: before_snapshot,
      after: after_snapshot,
      diff: diff(before_snapshot, after_snapshot),
      correlation_id: audit_meta.correlation_id,
      reason: audit_meta.reason
    }
  end

  defp before_snapshot(_changeset, :create), do: nil
  defp before_snapshot(changeset, _event_action), do: snapshot(changeset.data)

  defp audit_metadata(context) do
    meta = find_audit_meta(context) || %{}

    actor = Map.get(context, :actor)

    %{
      actor_type: Map.get(meta, :actor_type, default_actor_type(actor)),
      actor_id: Map.get(meta, :actor_id, actor_id(actor)),
      source: Map.get(meta, :source, :internal),
      correlation_id: Map.get(meta, :correlation_id),
      reason: Map.get(meta, :reason)
    }
  end

  defp find_audit_meta(nil), do: nil

  defp find_audit_meta(map) when is_map(map) do
    cond do
      is_map_key(map, :folio_audit) ->
        map[:folio_audit]

      true ->
        map
        |> Map.values()
        |> Enum.find_value(&find_audit_meta/1)
    end
  end

  defp find_audit_meta(_), do: nil

  defp default_actor_type(nil), do: :system
  defp default_actor_type(_actor), do: :user

  defp actor_id(%{id: actor_id}), do: actor_id
  defp actor_id(_), do: nil

  defp snapshot(nil), do: nil

  defp snapshot(record) do
    record
    |> Map.take(snapshot_fields(record.__struct__))
    |> normalize()
  end

  defp snapshot_fields(resource) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.map(& &1.name)
  end

  defp normalize(%_{} = value) do
    cond do
      function_exported?(value.__struct__, :__schema__, 1) ->
        value |> Map.from_struct() |> normalize()

      match?(DateTime, value.__struct__) ->
        DateTime.to_iso8601(value)

      match?(NaiveDateTime, value.__struct__) ->
        NaiveDateTime.to_iso8601(value)

      match?(Date, value.__struct__) ->
        Date.to_iso8601(value)

      match?(Time, value.__struct__) ->
        Time.to_iso8601(value)

      match?(Decimal, value.__struct__) ->
        Decimal.to_string(value)

      true ->
        value |> Map.from_struct() |> normalize()
    end
  end

  defp normalize(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), normalize(value)} end)
  end

  defp normalize(list) when is_list(list), do: Enum.map(list, &normalize/1)
  defp normalize(nil), do: nil
  defp normalize(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize(value), do: value

  defp diff(nil, after_snapshot), do: after_snapshot
  defp diff(before_snapshot, nil), do: before_snapshot

  defp diff(before_snapshot, after_snapshot) do
    before_snapshot
    |> Map.keys()
    |> Enum.concat(Map.keys(after_snapshot))
    |> Enum.uniq()
    |> Enum.reduce(%{}, fn key, acc ->
      before_value = Map.get(before_snapshot, key)
      after_value = Map.get(after_snapshot, key)

      if before_value == after_value do
        acc
      else
        Map.put(acc, key, %{"before" => before_value, "after" => after_value})
      end
    end)
  end

  defp resource_type(EBossFolio.Area), do: :area
  defp resource_type(EBossFolio.Contact), do: :contact
  defp resource_type(EBossFolio.Context), do: :context
  defp resource_type(EBossFolio.Delegation), do: :delegation
  defp resource_type(EBossFolio.Horizon), do: :horizon
  defp resource_type(EBossFolio.Project), do: :project
  defp resource_type(EBossFolio.Task), do: :task
end
