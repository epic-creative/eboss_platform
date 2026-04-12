defmodule EBoss.Workspaces.RouteAccess do
  @moduledoc false

  alias EBoss.Workspaces.Workspace

  def resolve(actor, owner_type, owner_handle, slug, accessible_workspaces \\ [])

  def resolve(nil, _owner_type, _owner_handle, _slug, _accessible_workspaces),
    do: {:error, :unauthorized}

  def resolve(_actor, owner_type, owner_handle, slug, accessible_workspaces)
      when owner_type in [:user, :organization] do
    case Enum.find(accessible_workspaces, &workspace_match?(&1, owner_type, owner_handle, slug)) do
      nil ->
        case Workspace.get_workspace_by_owner_handle_and_slug(
               owner_type,
               owner_handle,
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

      workspace ->
        {:ok, workspace}
    end
  end

  defp workspace_match?(workspace, owner_type, owner_handle, slug) do
    workspace.owner_type == owner_type and workspace.owner_handle == owner_handle and
      workspace.slug == slug
  end
end
