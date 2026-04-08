defmodule EBossFolio.Validations.BelongsToWorkspace do
  use Ash.Resource.Validation

  @impl true
  def init(opts) do
    case Keyword.get(opts, :relationships) do
      relationships when is_list(relationships) -> {:ok, opts}
      _ -> {:error, "relationships must be a keyword list"}
    end
  end

  @impl true
  def validate(changeset, opts, _context) do
    workspace_id =
      Ash.Changeset.get_attribute(changeset, :workspace_id) || changeset.data.workspace_id

    Enum.reduce_while(opts[:relationships], :ok, fn {field, resource}, :ok ->
      case Ash.Changeset.get_attribute(changeset, field) do
        nil ->
          {:cont, :ok}

        value ->
          with {:ok, related} <-
                 Ash.get(resource, value,
                   domain: domain_for(resource),
                   authorize?: false
                 ),
               true <- related.workspace_id == workspace_id do
            {:cont, :ok}
          else
            _ ->
              {:halt,
               {:error, field: field, message: "must reference a record in the same workspace"}}
          end
      end
    end)
  end

  defp domain_for(EBoss.Workspaces.Workspace), do: EBoss.Workspaces
  defp domain_for(_resource), do: EBossFolio
end
