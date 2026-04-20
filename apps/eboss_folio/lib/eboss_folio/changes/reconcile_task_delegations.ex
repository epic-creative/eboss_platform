defmodule EBossFolio.Changes.ReconcileTaskDelegations do
  use Ash.Resource.Change

  import Ash.Expr

  require Ash.Query

  alias EBossFolio.Delegation

  @supported_resolutions [:complete, :cancel]

  @impl true
  def change(changeset, opts, context) do
    resolution = Keyword.fetch!(opts, :with)

    if resolution not in @supported_resolutions do
      raise ArgumentError, "unsupported task delegation reconciliation: #{inspect(resolution)}"
    end

    Ash.Changeset.after_action(changeset, fn _changeset, task ->
      with {:ok, delegations} <- active_delegations(task.id, context.actor),
           :ok <- reconcile_delegations(delegations, resolution, context.actor) do
        {:ok, task}
      end
    end)
  end

  defp active_delegations(task_id, actor) do
    Delegation
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(expr(task_id == ^task_id and status == :active))
    |> Ash.read(actor: actor)
  end

  defp reconcile_delegations([], _resolution, _actor), do: :ok

  defp reconcile_delegations(delegations, resolution, actor) do
    Enum.reduce_while(delegations, :ok, fn delegation, :ok ->
      case resolve_delegation(delegation, resolution, actor) do
        {:ok, _delegation} -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp resolve_delegation(delegation, :complete, actor) do
    EBossFolio.complete_delegation(delegation, actor: actor)
  end

  defp resolve_delegation(delegation, :cancel, actor) do
    EBossFolio.cancel_delegation(delegation, actor: actor)
  end
end
