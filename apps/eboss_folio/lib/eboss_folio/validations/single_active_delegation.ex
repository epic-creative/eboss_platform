defmodule EBossFolio.Validations.SingleActiveDelegation do
  use Ash.Resource.Validation

  require Ash.Query

  alias EBossFolio.Delegation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    status = Ash.Changeset.get_attribute(changeset, :status) || changeset.data.status
    task_id = Ash.Changeset.get_attribute(changeset, :task_id) || changeset.data.task_id

    if status == :active and active_delegation_exists?(task_id) do
      {:error, field: :task_id, message: "already has an active delegation"}
    else
      :ok
    end
  end

  defp active_delegation_exists?(nil), do: false

  defp active_delegation_exists?(task_id_value) do
    case Delegation
         |> Ash.Query.filter(task_id == ^task_id_value and status == :active)
         |> Ash.read_one(domain: EBossFolio, authorize?: false) do
      {:ok, %Delegation{}} -> true
      _ -> false
    end
  end
end
