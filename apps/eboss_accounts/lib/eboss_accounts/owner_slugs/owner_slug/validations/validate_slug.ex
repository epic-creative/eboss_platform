defmodule EBoss.OwnerSlugs.OwnerSlug.Validations.ValidateSlug do
  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts, _context) do
    slug =
      changeset
      |> Ash.Changeset.get_attribute(:slug)
      |> normalize_slug()

    case EBoss.Slugs.validate_slug(slug) do
      :ok -> :ok
      {:error, reason} -> {:error, field: :slug, message: reason}
    end
  end

  defp normalize_slug(slug) when is_binary(slug), do: String.downcase(slug)
  defp normalize_slug(_slug), do: ""
end
