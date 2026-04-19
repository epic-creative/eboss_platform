defmodule EBossWeb.AppScope do
  @moduledoc false

  use EBossWeb, :verified_routes

  alias EBoss.Organizations
  alias EBoss.Workspaces

  defstruct current_user: nil,
            current_workspace: nil,
            owner: nil,
            capabilities: %{},
            apps: %{},
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
          owner_slug: String.t(),
          owner_display_name: String.t(),
          dashboard_path: String.t()
        }

  @type t :: %__MODULE__{
          current_user: map() | nil,
          current_workspace: workspace_summary() | nil,
          owner: map() | nil,
          capabilities: map(),
          apps: map(),
          accessible_workspaces: [workspace_summary()],
          dashboard_path: String.t(),
          empty?: boolean()
        }

  def default_dashboard_path(nil), do: ~p"/dashboard"

  def default_dashboard_path(current_user) do
    case load_access_context(current_user).dashboard_workspaces do
      [%{dashboard_path: dashboard_path} | _rest] -> dashboard_path
      [] -> ~p"/dashboard"
    end
  end

  def resolve_default(current_user) do
    case load_access_context(current_user).dashboard_workspaces do
      [%{dashboard_path: dashboard_path} | _rest] -> {:redirect, dashboard_path}
      [] -> {:ok, empty(current_user)}
    end
  end

  def resolve_workspace(current_user, owner_slug, workspace_slug)
      when is_binary(owner_slug) and is_binary(workspace_slug) do
    access_context = load_access_context(current_user)

    case Workspaces.resolve_workspace_route(
           current_user,
           owner_slug,
           workspace_slug,
           access_context.route_workspaces
         ) do
      {:ok, current_workspace} ->
        {:ok, build_scope(current_user, current_workspace, access_context)}

      {:error, :forbidden} ->
        fallback_scope(current_user, access_context.dashboard_workspaces)

      {:error, :not_found} ->
        fallback_scope(current_user, access_context.dashboard_workspaces)

      {:error, :unauthorized} ->
        {:ok, empty(current_user)}
    end
  end

  def fetch_workspace_scope(current_user, owner_slug, workspace_slug)
      when is_binary(owner_slug) and is_binary(workspace_slug) do
    access_context = load_access_context(current_user)

    case Workspaces.resolve_workspace_route(
           current_user,
           owner_slug,
           workspace_slug,
           access_context.route_workspaces
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
      apps: %{},
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
      apps: normalize_payload_map(scope.apps),
      accessible_workspaces: scope.accessible_workspaces
    }
  end

  defp normalize_payload_map(%{} = payload) do
    Enum.into(payload, %{}, fn {key, value} ->
      {to_string(key), normalize_payload_map(value)}
    end)
  end

  defp normalize_payload_map(value), do: value

  def dashboard_path_for(%{
        owner_slug: owner_slug,
        slug: workspace_slug
      })
      when is_binary(owner_slug) and is_binary(workspace_slug) do
    dashboard_path(owner_slug, workspace_slug)
  end

  def dashboard_path(owner_slug, workspace_slug)
      when is_binary(owner_slug) and is_binary(workspace_slug) do
    ~p"/#{owner_slug}/#{workspace_slug}"
  end

  defp fallback_scope(_current_user, [%{dashboard_path: dashboard_path} | _rest]) do
    {:redirect, dashboard_path}
  end

  defp fallback_scope(current_user, []), do: {:ok, empty(current_user)}

  defp load_access_context(nil),
    do: %{route_workspaces: [], dashboard_workspaces: [], organization_roles: %{}}

  defp load_access_context(current_user) do
    case Workspaces.list_workspaces(
           actor: current_user,
           load: [:owner, :full_path, :workspace_memberships]
         ) do
      {:ok, workspaces} ->
        organization_roles = organization_roles_by_id(current_user, workspaces)

        route_workspaces =
          workspaces
          |> Enum.map(&workspace_summary/1)
          |> Enum.sort_by(&workspace_sort_key/1)

        dashboard_workspaces =
          workspaces
          |> Enum.filter(&dashboard_workspace?(&1, current_user, organization_roles))
          |> Enum.map(&workspace_summary/1)
          |> Enum.sort_by(&workspace_sort_key/1)

        %{
          route_workspaces: route_workspaces,
          dashboard_workspaces: dashboard_workspaces,
          organization_roles: organization_roles
        }

      _ ->
        %{route_workspaces: [], dashboard_workspaces: [], organization_roles: %{}}
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
      owner_slug: workspace.owner_slug,
      owner_display_name: workspace.owner_display_name,
      dashboard_path: dashboard_path(workspace.owner_slug, workspace.slug)
    }
  end

  defp workspace_sort_key(workspace) do
    {
      owner_rank(workspace.owner_type),
      String.downcase(workspace.owner_slug),
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
      apps: app_registry(current_workspace, capabilities),
      accessible_workspaces:
        mark_current_workspace(access_context.dashboard_workspaces, current_workspace.id),
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
         owner_slug: owner_slug,
         owner_display_name: owner_display_name
       }) do
    %{
      type: owner_type,
      id: owner_id,
      slug: owner_slug,
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

  defp app_registry(%{dashboard_path: dashboard_path}, capabilities) do
    read_folio = Map.get(capabilities, :read_folio, false)
    manage_folio = Map.get(capabilities, :manage_folio, false)

    %{
      "folio" => %{
        key: "folio",
        label: "Folio",
        default_path: "#{dashboard_path}/apps/folio",
        enabled: read_folio,
        capabilities: %{read: read_folio, manage: manage_folio}
      }
    }
  end

  defp app_registry(_workspace, _capabilities), do: %{}

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

  defp dashboard_workspace?(
         %{owner_type: :user, owner_id: owner_id} = workspace,
         current_user,
         _roles
       ) do
    owner_id == current_user.id or workspace_membership?(workspace, current_user.id)
  end

  defp dashboard_workspace?(
         %{owner_type: :organization, owner_id: organization_id},
         _current_user,
         roles
       ) do
    Map.get(roles, organization_id, :none) != :none
  end

  defp workspace_membership?(workspace, user_id) do
    workspace
    |> Map.get(:workspace_memberships, [])
    |> Enum.any?(&(&1.user_id == user_id))
  end
end
