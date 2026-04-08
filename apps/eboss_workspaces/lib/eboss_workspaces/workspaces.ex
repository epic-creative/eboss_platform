defmodule EBoss.Workspaces do
  @moduledoc """
  The Workspaces domain for managing user and organization workspaces.
  """

  use Ash.Domain, otp_app: :eboss_workspaces, extensions: [AshJsonApi.Domain]

  json_api do
    routes do
      base_route "/workspaces", EBoss.Workspaces.Workspace do
        index :read
        get(:read)
      end

      base_route "/users/:owner_handle/workspaces", EBoss.Workspaces.Workspace do
        get :by_user_handle_and_slug do
          route("/:slug")
          name "get_user_workspace_by_slug"
        end
      end

      base_route "/orgs/:owner_handle/workspaces", EBoss.Workspaces.Workspace do
        get :by_org_handle_and_slug do
          route("/:slug")
          name "get_org_workspace_by_slug"
        end
      end
    end
  end

  resources do
    resource(EBoss.Workspaces.Workspace)
    resource(EBoss.Workspaces.WorkspaceMembership)
  end

  alias EBoss.Workspaces.{Workspace, WorkspaceMembership}

  def create_workspace(attrs, opts \\ []) do
    Workspace
    |> Ash.Changeset.for_create(:create, attrs, action_opts(opts))
    |> Ash.create(default_opts(opts))
  end

  def create_workspace!(attrs, opts \\ []) do
    case create_workspace(attrs, opts) do
      {:ok, workspace} -> workspace
      {:error, error} -> raise error
    end
  end

  def update_workspace(workspace, attrs, opts \\ []) do
    workspace
    |> Ash.Changeset.for_update(:update, attrs, action_opts(opts))
    |> Ash.update(default_opts(opts))
  end

  def update_workspace!(workspace, attrs, opts \\ []) do
    case update_workspace(workspace, attrs, opts) do
      {:ok, updated_workspace} -> updated_workspace
      {:error, error} -> raise error
    end
  end

  def destroy_workspace(workspace, opts \\ []) do
    workspace
    |> Ash.Changeset.for_destroy(:destroy, %{}, action_opts(opts))
    |> Ash.destroy(default_opts(opts))
  end

  def destroy_workspace!(workspace, opts \\ []) do
    case destroy_workspace(workspace, opts) do
      {:ok, destroyed_workspace} -> destroyed_workspace
      :ok -> :ok
      {:error, error} -> raise error
    end
  end

  def get_workspace(id, opts \\ []) do
    Ash.get(Workspace, id, default_opts(opts))
  end

  def get_workspace!(id, opts \\ []) do
    Ash.get!(Workspace, id, default_opts(opts))
  end

  def get_workspace_by_owner_and_slug(owner_type, owner_id, slug, opts \\ []) do
    Workspace
    |> Ash.Query.for_read(:by_slug, %{owner_type: owner_type, owner_id: owner_id, slug: slug})
    |> Ash.read_one(default_opts(opts))
  end

  def get_workspace_by_owner_and_slug!(owner_type, owner_id, slug, opts \\ []) do
    case get_workspace_by_owner_and_slug(owner_type, owner_id, slug, opts) do
      {:ok, workspace} -> workspace
      {:error, error} -> raise error
    end
  end

  def get_workspace_by_owner_handle_and_slug(owner_type, owner_handle, slug, opts \\ []) do
    Workspace
    |> Ash.Query.for_read(:by_owner_handle_and_slug, %{
      owner_type: owner_type,
      owner_handle: owner_handle,
      slug: slug
    })
    |> Ash.read_one(default_opts(opts))
  end

  def get_workspace_by_owner_handle_and_slug!(owner_type, owner_handle, slug, opts \\ []) do
    case get_workspace_by_owner_handle_and_slug(owner_type, owner_handle, slug, opts) do
      {:ok, workspace} -> workspace
      {:error, error} -> raise error
    end
  end

  def list_workspaces_for_owner(owner_type, owner_id, opts \\ []) do
    Workspace
    |> Ash.Query.for_read(:for_owner, %{owner_type: owner_type, owner_id: owner_id})
    |> Ash.read(default_opts(opts))
  end

  def list_workspaces_for_owner!(owner_type, owner_id, opts \\ []) do
    case list_workspaces_for_owner(owner_type, owner_id, opts) do
      {:ok, workspaces} -> workspaces
      {:error, error} -> raise error
    end
  end

  def create_workspace_membership(attrs, opts \\ []) do
    WorkspaceMembership
    |> Ash.Changeset.for_create(:create, attrs, action_opts(opts))
    |> Ash.create(default_opts(opts))
  end

  def create_workspace_membership!(attrs, opts \\ []) do
    case create_workspace_membership(attrs, opts) do
      {:ok, membership} -> membership
      {:error, error} -> raise error
    end
  end

  defp default_opts(opts), do: Keyword.put_new(opts, :domain, __MODULE__)

  defp action_opts(opts) do
    opts
    |> Keyword.take([:actor, :tenant, :tracer, :authorize?, :scope, :context])
  end
end
