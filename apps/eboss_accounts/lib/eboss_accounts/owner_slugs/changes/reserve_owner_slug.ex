defmodule EBoss.OwnerSlugs.Changes.ReserveOwnerSlug do
  use Ash.Resource.Change

  alias Ash.Error.Changes.InvalidAttribute
  alias Ash.Error.Invalid
  alias EBoss.OwnerSlugs

  @impl true
  def change(changeset, opts, _context) do
    owner_type = Keyword.fetch!(opts, :owner_type)
    field = Keyword.get(opts, :field, :slug)
    changeset = validate_owner_slug_availability(changeset, field)

    Ash.Changeset.after_action(changeset, fn _changeset, record ->
      case OwnerSlugs.reserve_owner_slug(record.owner_slug, owner_type, record.id,
             authorize?: false
           ) do
        {:ok, _owner_slug} -> {:ok, record}
        {:error, error} -> {:error, remap_field(error, field)}
      end
    end)
  end

  defp remap_field(%Invalid{errors: errors} = error, field) do
    %{error | errors: Enum.map(errors, &remap_field(&1, field))}
  end

  defp remap_field(%InvalidAttribute{field: :slug} = error, field) do
    %{error | field: field}
  end

  defp remap_field(error, _field), do: error

  defp validate_owner_slug_availability(changeset, field) do
    owner_slug = owner_slug_candidate(changeset)

    case OwnerSlugs.resolve_owner_by_slug(owner_slug, authorize?: false) do
      {:ok, nil} ->
        changeset

      {:ok, _owner_slug} ->
        Ash.Changeset.add_error(changeset, field: field, message: "has already been taken")

      {:error, _error} ->
        changeset
    end
  end

  defp owner_slug_candidate(changeset) do
    changeset
    |> Ash.Changeset.get_attribute(:owner_slug)
    |> case do
      slug when is_binary(slug) ->
        slug

      _ ->
        changeset
        |> Ash.Changeset.get_attribute(:name)
        |> slugify_name()
    end
  end

  defp slugify_name(name) when is_binary(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  defp slugify_name(_name), do: nil
end
