defmodule EBossFolio do
  @moduledoc """
  Workspace-scoped Folio domain for planning resources and revision history.
  """

  use Ash.Domain, otp_app: :eboss_folio

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
end
