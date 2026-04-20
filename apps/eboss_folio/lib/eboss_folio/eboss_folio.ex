defmodule EBossFolio do
  @moduledoc """
  Workspace-scoped Folio domain for planning resources and revision history.
  """

  use Ash.Domain, otp_app: :eboss_folio
  import Ash.Expr
  require Ash.Query

  alias EBossFolio.ActivityFeedProvider
  alias EBossFolio.Contact
  alias EBossFolio.Project
  alias EBossFolio.Task

  resources do
    resource EBossFolio.Area do
      define(:create_area, action: :create)
      define(:update_area, action: :update)
      define(:archive_area, action: :archive)
    end

    resource EBossFolio.Context do
      define(:create_context, action: :create)
      define(:update_context, action: :update)
      define(:archive_context, action: :archive)
    end

    resource EBossFolio.Horizon do
      define(:create_horizon, action: :create)
      define(:update_horizon, action: :update)
      define(:archive_horizon, action: :archive)
    end

    resource EBossFolio.Contact do
      define(:create_contact, action: :create)
      define(:update_contact, action: :update)
      define(:archive_contact, action: :archive)
    end

    resource EBossFolio.Project do
      define(:create_project, action: :create)
      define(:update_project_details, action: :update_details)
      define(:activate_project, action: :activate)
      define(:put_project_on_hold, action: :put_on_hold)
      define(:complete_project, action: :complete)
      define(:cancel_project, action: :cancel)
      define(:archive_project, action: :archive)
      define(:reposition_project, action: :reposition)
    end

    resource EBossFolio.Task do
      define(:create_task, action: :create)
      define(:update_task_details, action: :update_details)
      define(:move_task_to_inbox, action: :move_to_inbox)
      define(:mark_task_next_action, action: :mark_next_action)
      define(:mark_task_waiting_for, action: :mark_waiting_for)
      define(:schedule_task, action: :schedule)
      define(:mark_task_someday_maybe, action: :mark_someday_maybe)
      define(:complete_task, action: :complete)
      define(:cancel_task, action: :cancel)
      define(:archive_task, action: :archive)
      define(:reposition_task, action: :reposition)
    end

    resource EBossFolio.Delegation do
      define(:delegate_task, action: :delegate)
      define(:complete_delegation, action: :complete)
      define(:cancel_delegation, action: :cancel)
    end

    resource EBossFolio.RevisionEvent do
      define(:list_revision_events, action: :list)
    end
  end

  def bootstrap_summary_counts(workspace_id, opts \\ []) when is_binary(workspace_id) do
    with {:ok, project_count} <- count_records(Project, workspace_id, opts),
         {:ok, task_count} <- count_records(Task, workspace_id, opts) do
      {:ok, %{projects: project_count, tasks: task_count}}
    end
  end

  def list_projects_in_workspace(workspace_id, opts \\ []) when is_binary(workspace_id) do
    workspace_id
    |> projects_query()
    |> Ash.read(opts)
  end

  def list_projects_in_workspace!(workspace_id, opts \\ []) when is_binary(workspace_id) do
    case list_projects_in_workspace(workspace_id, opts) do
      {:ok, projects} -> projects
      {:error, reason} -> raise reason
    end
  end

  def get_project_in_workspace(project_id, workspace_id, opts \\ [])
      when is_binary(project_id) and is_binary(workspace_id) do
    case Project
         |> Ash.Query.for_read(:read)
         |> Ash.Query.filter(expr(id == ^project_id and workspace_id == ^workspace_id))
         |> Ash.read_one(opts) do
      {:ok, nil} -> {:error, :not_found}
      result -> result
    end
  end

  def get_project_in_workspace!(project_id, workspace_id, opts \\ [])
      when is_binary(project_id) and is_binary(workspace_id) do
    case get_project_in_workspace(project_id, workspace_id, opts) do
      {:ok, project} -> project
      {:error, reason} -> raise reason
    end
  end

  def list_tasks_in_workspace(workspace_id, opts \\ []) when is_binary(workspace_id) do
    workspace_id
    |> tasks_query()
    |> Ash.read(opts)
  end

  def list_tasks_in_workspace!(workspace_id, opts \\ []) when is_binary(workspace_id) do
    case list_tasks_in_workspace(workspace_id, opts) do
      {:ok, tasks} -> tasks
      {:error, reason} -> raise reason
    end
  end

  def get_task_in_workspace(task_id, workspace_id, opts \\ [])
      when is_binary(task_id) and is_binary(workspace_id) do
    case Task
         |> Ash.Query.for_read(:read)
         |> Ash.Query.filter(expr(id == ^task_id and workspace_id == ^workspace_id))
         |> Ash.read_one(opts) do
      {:ok, nil} -> {:error, :not_found}
      result -> result
    end
  end

  def get_task_in_workspace!(task_id, workspace_id, opts \\ [])
      when is_binary(task_id) and is_binary(workspace_id) do
    case get_task_in_workspace(task_id, workspace_id, opts) do
      {:ok, task} -> task
      {:error, reason} -> raise reason
    end
  end

  def get_contact_in_workspace(contact_id, workspace_id, opts \\ [])
      when is_binary(contact_id) and is_binary(workspace_id) do
    case Contact
         |> Ash.Query.for_read(:read)
         |> Ash.Query.filter(expr(id == ^contact_id and workspace_id == ^workspace_id))
         |> Ash.read_one(opts) do
      {:ok, nil} -> {:error, :not_found}
      result -> result
    end
  end

  def get_contact_in_workspace!(contact_id, workspace_id, opts \\ [])
      when is_binary(contact_id) and is_binary(workspace_id) do
    case get_contact_in_workspace(contact_id, workspace_id, opts) do
      {:ok, contact} -> contact
      {:error, reason} -> raise reason
    end
  end

  def list_activity_feed(workspace_id, opts \\ []) when is_binary(workspace_id) do
    with {:ok, revision_events} <- list_revision_events(%{workspace_id: workspace_id}, opts) do
      {:ok, ActivityFeedProvider.map_events(revision_events)}
    end
  end

  def list_activity_feed!(workspace_id, opts \\ []) when is_binary(workspace_id) do
    case list_activity_feed(workspace_id, opts) do
      {:ok, activity_events} -> activity_events
      {:error, reason} -> raise reason
    end
  end

  defp projects_query(workspace_id) do
    Project
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(expr(workspace_id == ^workspace_id))
    |> Ash.Query.sort(inserted_at: :asc)
  end

  defp tasks_query(workspace_id) do
    Task
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(expr(workspace_id == ^workspace_id))
    |> Ash.Query.load(delegations: :contact)
    |> Ash.Query.sort(inserted_at: :asc)
  end

  defp count_records(resource, workspace_id_value, opts) do
    query =
      resource
      |> Ash.Query.for_read(:read)
      |> Ash.Query.filter(expr(workspace_id == ^workspace_id_value))

    Ash.count(query, opts)
  end
end
