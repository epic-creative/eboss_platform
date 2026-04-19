defmodule EBossFolio do
  @moduledoc """
  Workspace-scoped Folio domain for planning resources and revision history.
  """

  use Ash.Domain, otp_app: :eboss_folio
  import Ash.Expr
  require Ash.Query

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

  defp count_records(resource, workspace_id_value, opts) do
    query =
      resource
      |> Ash.Query.for_read(:read)
      |> Ash.Query.filter(expr(workspace_id == ^workspace_id_value))

    with {:ok, records} <- Ash.read(query, opts) do
      {:ok, length(records)}
    end
  end
end
