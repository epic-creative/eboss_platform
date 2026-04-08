defmodule EBossFolio.Validations.TaskWaitingFor do
  use Ash.Resource.Validation

  require Ash.Query

  alias EBossFolio.Delegation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    target_status = Ash.Changeset.get_attribute(changeset, :status) || changeset.data.status

    if target_status == :waiting_for and not waiting_for_allowed?(changeset) do
      {:error, field: :status, message: "waiting_for tasks require notes or an active delegation"}
    else
      :ok
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
end
