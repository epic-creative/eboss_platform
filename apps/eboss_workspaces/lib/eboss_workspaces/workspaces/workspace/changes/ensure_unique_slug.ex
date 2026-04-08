defmodule EBoss.Workspaces.Workspace.Changes.EnsureUniqueSlug do
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      case Ash.Changeset.get_attribute(changeset, :slug) do
        slug when is_binary(slug) and slug != "" ->
          owner_type = Ash.Changeset.get_attribute(changeset, :owner_type)
          owner_id = Ash.Changeset.get_attribute(changeset, :owner_id)

          Ash.Changeset.force_change_attribute(
            changeset,
            :slug,
            ensure_unique_slug(
              changeset.domain,
              slug,
              owner_type,
              owner_id,
              changeset.data.id,
              0
            )
          )

        _ ->
          changeset
      end
    end)
  end

  defp ensure_unique_slug(domain, base_slug, owner_type, owner_id, current_id, counter) do
    candidate = if counter == 0, do: base_slug, else: "#{base_slug}-#{counter}"

    query =
      EBoss.Workspaces.Workspace
      |> Ash.Query.filter(
        owner_type == ^owner_type and
          owner_id == ^owner_id and
          slug == ^candidate
      )
      |> maybe_exclude_current(current_id)
      |> Ash.Query.limit(1)

    case Ash.read(query, domain: domain, authorize?: false) do
      {:ok, []} ->
        candidate

      {:ok, _} ->
        ensure_unique_slug(domain, base_slug, owner_type, owner_id, current_id, counter + 1)

      {:error, _} ->
        candidate
    end
  end

  defp maybe_exclude_current(query, nil), do: query
  defp maybe_exclude_current(query, current_id), do: Ash.Query.filter(query, id != ^current_id)
end
