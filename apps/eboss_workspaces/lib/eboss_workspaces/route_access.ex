defmodule EBoss.Workspaces.RouteAccess do
  @moduledoc false

  alias EBoss.OwnerSlugs
  alias EBoss.Workspaces.Workspace

  def resolve(actor, owner_slug, slug, accessible_workspaces \\ [])

  def resolve(nil, _owner_slug, _slug, _accessible_workspaces),
    do: {:error, :unauthorized}

  def resolve(_actor, owner_slug, slug, accessible_workspaces)
      when is_binary(owner_slug) and is_binary(slug) do
    case Enum.find(accessible_workspaces, &workspace_match?(&1, owner_slug, slug)) do
      nil ->
        case OwnerSlugs.resolve_owner_by_slug(owner_slug, authorize?: false) do
          {:ok, nil} ->
            {:error, :not_found}

          {:ok, owner} ->
            case Workspace.get_workspace_by_owner_and_slug(
                   owner.owner_type,
                   owner.owner_id,
                   slug,
                   authorize?: false
                 ) do
              {:ok, nil} ->
                {:error, :not_found}

              {:ok, _workspace} ->
                {:error, :forbidden}

              {:error, _error} ->
                {:error, :not_found}
            end

          {:error, _error} ->
            {:error, :not_found}
        end

      workspace ->
        {:ok, workspace}
    end
  end

  defp workspace_match?(workspace, owner_slug, slug) do
    workspace.owner_slug == owner_slug and workspace.slug == slug
  end
end
