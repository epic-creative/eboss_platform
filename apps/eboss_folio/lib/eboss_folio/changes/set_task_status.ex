defmodule EBossFolio.Changes.SetTaskStatus do
  use Ash.Resource.Change

  require Ash.Query

  alias EBossFolio.Delegation

  @impl true
  def change(changeset, opts, _context) do
    target = Keyword.fetch!(opts, :to)
    current = changeset.data.status

    cond do
      not allowed_transition?(current, target) ->
        Ash.Changeset.add_error(
          changeset,
          field: :status,
          message: "cannot transition task from #{current} to #{target}"
        )

      target == :waiting_for and not waiting_for_allowed?(changeset) ->
        Ash.Changeset.add_error(
          changeset,
          field: :status,
          message: "waiting_for tasks require notes or an active delegation"
        )

      true ->
        Ash.Changeset.change_attribute(changeset, :status, target)
    end
  end

  defp waiting_for_allowed?(changeset) do
    notes = Ash.Changeset.get_attribute(changeset, :notes) || changeset.data.notes

    present_notes?(notes) or active_delegation?(changeset.data.id)
  end

  defp active_delegation?(nil), do: false

  defp active_delegation?(task_id_value) do
    case Delegation
         |> Ash.Query.filter(task_id == ^task_id_value and status == :active)
         |> Ash.read_one(domain: EBossFolio, authorize?: false) do
      {:ok, %Delegation{}} -> true
      _ -> false
    end
  end

  defp present_notes?(value), do: value |> to_string() |> String.trim() |> Kernel.!=("")

  defp allowed_transition?(:inbox, target),
    do:
      target in [
        :inbox,
        :next_action,
        :waiting_for,
        :scheduled,
        :someday_maybe,
        :done,
        :canceled,
        :archived
      ]

  defp allowed_transition?(:next_action, target),
    do:
      target in [
        :inbox,
        :next_action,
        :waiting_for,
        :scheduled,
        :someday_maybe,
        :done,
        :canceled,
        :archived
      ]

  defp allowed_transition?(:waiting_for, target),
    do:
      target in [
        :inbox,
        :next_action,
        :waiting_for,
        :scheduled,
        :someday_maybe,
        :done,
        :canceled,
        :archived
      ]

  defp allowed_transition?(:scheduled, target),
    do:
      target in [
        :inbox,
        :next_action,
        :waiting_for,
        :scheduled,
        :someday_maybe,
        :done,
        :canceled,
        :archived
      ]

  defp allowed_transition?(:someday_maybe, target),
    do:
      target in [
        :inbox,
        :next_action,
        :waiting_for,
        :scheduled,
        :someday_maybe,
        :done,
        :canceled,
        :archived
      ]

  defp allowed_transition?(:done, :archived), do: true
  defp allowed_transition?(:canceled, :archived), do: true
  defp allowed_transition?(:archived, :archived), do: true
  defp allowed_transition?(current, target), do: current == target
end
