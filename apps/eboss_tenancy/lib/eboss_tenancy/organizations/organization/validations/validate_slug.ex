defmodule EBoss.Organizations.Organization.Validations.ValidateSlug do
  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts, _context) do
    slug = Ash.Changeset.get_attribute(changeset, :owner_slug)

    if slug do
      case EBoss.Slugs.validate_slug(slug) do
        :ok -> :ok
        {:error, reason} -> {:error, field: :owner_slug, message: reason}
      end
    else
      :ok
    end
  end
end
