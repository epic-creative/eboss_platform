defmodule EBossFolio.Changes.SetProjectStatus do
  use Ash.Resource.Change

  @impl true
  def change(changeset, opts, _context) do
    target = Keyword.fetch!(opts, :to)
    current = changeset.data.status

    if allowed_transition?(current, target) do
      Ash.Changeset.change_attribute(changeset, :status, target)
    else
      Ash.Changeset.add_error(
        changeset,
        field: :status,
        message: "cannot transition project from #{current} to #{target}"
      )
    end
  end

  defp allowed_transition?(:active, target),
    do: target in [:active, :on_hold, :completed, :canceled, :archived]

  defp allowed_transition?(:on_hold, target),
    do: target in [:active, :on_hold, :completed, :canceled, :archived]

  defp allowed_transition?(:completed, :archived), do: true
  defp allowed_transition?(:canceled, :archived), do: true
  defp allowed_transition?(:archived, :archived), do: true
  defp allowed_transition?(current, target), do: current == target
end
