defmodule EBossWeb.AppScope do
  @moduledoc false

  use EBossWeb, :verified_routes

  alias EBoss.Organizations
  alias EBoss.Workspaces

  defstruct current_user: nil,
            current_workspace: nil,
            owner: nil,
            capabilities: %{},
            accessible_workspaces: [],
            dashboard_path: "/dashboard",
            empty?: true

  @type workspace_summary :: %{
          id: String.t(),
          name: String.t(),
          slug: String.t(),
          full_path: String.t() | nil,
          visibility: atom() | String.t() | nil,
          owner_type: atom(),
          owner_id: String.t(),
          owner_handle: String.t(),
          owner_display_name: String.t(),
          dashboard_path: String.t()
        }

  @type t :: %__MODULE__{
          current_user: map() | nil,
          current_workspace: workspace_summary() | nil,
          owner: map() | nil,
          capabilities: map(),
          accessible_workspaces: [workspace_summary()],
          dashboard_path: String.t(),
          empty?: boolean()
        }

  def default_dashboard_path(nil), do: ~p"/dashboard"

  def default_dashboard_path(current_user) do
    case load_access_context(current_user).workspaces do
      [%{dashboard_path: dashboard_path} | _rest] -> dashboard_path
      [] -> ~p"/dashboard"
    end
  end

  def resolve_default(current_user) do
    case load_access_context(current_user).workspaces do
      [%{dashboard_path: dashboard_path} | _rest] -> {:redirect, dashboard_path}
      [] -> {:ok, empty(current_user)}
    end
  end

  def resolve_workspace(current_user, owner_type, owner_handle, workspace_slug)
      when owner_type in [:user, :organization] do
    access_context = load_access_context(current_user)

    case Workspaces.resolve_workspace_route(
           current_user,
           owner_type,
           owner_handle,
           workspace_slug,
           access_context.workspaces
         ) do
      {:ok, current_workspace} ->
        {:ok, build_scope(current_user, current_workspace, access_context)}

      {:error, :forbidden} ->
        fallback_scope(current_user, access_context.workspaces)

      {:error, :not_found} ->
        fallback_scope(current_user, access_context.workspaces)

      {:error, :unauthorized} ->
        {:ok, empty(current_user)}
    end
  end

  def fetch_workspace_scope(current_user, owner_type, owner_handle, workspace_slug)
      when owner_type in [:user, :organization] do
    access_context = load_access_context(current_user)

    case Workspaces.resolve_workspace_route(
           current_user,
           owner_type,
           owner_handle,
           workspace_slug,
           access_context.workspaces
         ) do
      {:ok, current_workspace} ->
        {:ok, build_scope(current_user, current_workspace, access_context)}

      {:error, :forbidden} ->
        {:error, :forbidden}

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :unauthorized}
    end
  end

  def empty(current_user) do
    %__MODULE__{
      current_user: current_user,
      current_workspace: nil,
      owner: nil,
      capabilities: empty_capabilities(),
      accessible_workspaces: [],
      dashboard_path: ~p"/dashboard",
      empty?: true
    }
  end

  def bootstrap_payload(%__MODULE__{} = scope) do
    %{
      current_user: user_summary(scope.current_user),
      workspace: scope.current_workspace,
      owner: scope.owner,
      capabilities: scope.capabilities,
      accessible_workspaces: scope.accessible_workspaces
    }
  end

  def dashboard_path_for(%{
        owner_type: owner_type,
        owner_handle: owner_handle,
        slug: workspace_slug
      })
      when owner_type in [:user, :organization] do
    dashboard_path(owner_type, owner_handle, workspace_slug)
  end

  def dashboard_path(owner_type, owner_handle, workspace_slug)
      when owner_type in [:user, :organization] do
    case owner_type do
      :user -> ~p"/users/#{owner_handle}/#{workspace_slug}/dashboard"
      :organization -> ~p"/orgs/#{owner_handle}/#{workspace_slug}/dashboard"
    end
  end

  defp fallback_scope(_current_user, [%{dashboard_path: dashboard_path} | _rest]) do
    {:redirect, dashboard_path}
  end

  defp fallback_scope(current_user, []), do: {:ok, empty(current_user)}

  defp load_access_context(nil), do: %{workspaces: [], organization_roles: %{}}

  defp load_access_context(current_user) do
    case Workspaces.list_workspaces(actor: current_user, load: [:owner, :full_path]) do
      {:ok, workspaces} ->
        workspace_summaries =
          workspaces
          |> Enum.map(&workspace_summary/1)
          |> Enum.sort_by(&workspace_sort_key/1)

        %{
          workspaces: workspace_summaries,
          organization_roles: organization_roles_by_id(current_user, workspace_summaries)
        }

      _ ->
        %{workspaces: [], organization_roles: %{}}
    end
  end

  defp workspace_summary(workspace) do
    %{
      id: workspace.id,
      name: workspace.name,
      slug: workspace.slug,
      full_path: Map.get(workspace, :full_path),
      visibility: workspace.visibility,
      owner_type: workspace.owner_type,
      owner_id: workspace.owner_id,
      owner_handle: workspace.owner_handle,
      owner_display_name: workspace.owner_display_name,
      dashboard_path: dashboard_path(workspace.owner_type, workspace.owner_handle, workspace.slug)
    }
  end

  defp workspace_sort_key(workspace) do
    {
      owner_rank(workspace.owner_type),
      String.downcase(workspace.owner_handle),
      String.downcase(workspace.slug)
    }
  end

  defp owner_rank(:user), do: 0
  defp owner_rank(:organization), do: 1

  defp build_scope(current_user, current_workspace, access_context) do
    owner = owner_summary(current_workspace)
    capabilities = capabilities(current_user, current_workspace, access_context)

    %__MODULE__{
      current_user: current_user,
      current_workspace: current_workspace,
      owner: owner,
      capabilities: capabilities,
      accessible_workspaces:
        mark_current_workspace(access_context.workspaces, current_workspace.id),
      dashboard_path: current_workspace.dashboard_path,
      empty?: false
    }
  end

  defp mark_current_workspace(accessible_workspaces, current_workspace_id) do
    Enum.map(accessible_workspaces, fn workspace ->
      Map.put(workspace, :current?, workspace.id == current_workspace_id)
    end)
  end

  defp owner_summary(%{
         owner_type: owner_type,
         owner_id: owner_id,
         owner_handle: owner_handle,
         owner_display_name: owner_display_name
       }) do
    %{
      type: owner_type,
      id: owner_id,
      handle: owner_handle,
      display_name: owner_display_name
    }
  end

  defp capabilities(current_user, %{owner_type: :user, owner_id: owner_id}, _access_context) do
    manages_workspace? = not is_nil(current_user) and current_user.id == owner_id

    %{
      read_workspace: true,
      manage_workspace: manages_workspace?,
      read_folio: manages_workspace?,
      manage_folio: manages_workspace?
    }
  end

  defp capabilities(
         _current_user,
         %{owner_type: :organization, owner_id: organization_id},
         access_context
       ) do
    role = Map.get(access_context.organization_roles, organization_id, :none)
    manages_workspace? = role in [:owner, :admin]

    %{
      read_workspace: true,
      manage_workspace: manages_workspace?,
      read_folio: manages_workspace?,
      manage_folio: manages_workspace?
    }
  end

  defp empty_capabilities do
    %{
      read_workspace: false,
      manage_workspace: false,
      read_folio: false,
      manage_folio: false
    }
  end

  defp user_summary(nil), do: nil

  defp user_summary(user) do
    %{
      id: user.id,
      email: to_string(user.email),
      username: user.username,
      role: user.role
    }
  end

  defp organization_roles_by_id(current_user, workspaces) do
    organization_ids =
      workspaces
      |> Enum.filter(&(&1.owner_type == :organization))
      |> Enum.map(& &1.owner_id)
      |> Enum.uniq()

    Organizations.roles_by_organization_ids(current_user.id, organization_ids)
  end
end
