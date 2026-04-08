defmodule EBoss.Folio do
  @moduledoc """
  Public boundary for the Folio domain.
  """

  defdelegate create_area(attrs, opts \\ []), to: EBossFolio
  defdelegate create_area!(attrs, opts \\ []), to: EBossFolio
  defdelegate update_area(record, attrs, opts \\ []), to: EBossFolio
  defdelegate update_area!(record, attrs, opts \\ []), to: EBossFolio
  defdelegate archive_area(record, opts \\ []), to: EBossFolio
  defdelegate archive_area!(record, opts \\ []), to: EBossFolio

  defdelegate create_context(attrs, opts \\ []), to: EBossFolio
  defdelegate create_context!(attrs, opts \\ []), to: EBossFolio
  defdelegate update_context(record, attrs, opts \\ []), to: EBossFolio
  defdelegate update_context!(record, attrs, opts \\ []), to: EBossFolio
  defdelegate archive_context(record, opts \\ []), to: EBossFolio
  defdelegate archive_context!(record, opts \\ []), to: EBossFolio

  defdelegate create_horizon(attrs, opts \\ []), to: EBossFolio
  defdelegate create_horizon!(attrs, opts \\ []), to: EBossFolio
  defdelegate update_horizon(record, attrs, opts \\ []), to: EBossFolio
  defdelegate update_horizon!(record, attrs, opts \\ []), to: EBossFolio
  defdelegate archive_horizon(record, opts \\ []), to: EBossFolio
  defdelegate archive_horizon!(record, opts \\ []), to: EBossFolio

  defdelegate create_contact(attrs, opts \\ []), to: EBossFolio
  defdelegate create_contact!(attrs, opts \\ []), to: EBossFolio
  defdelegate update_contact(record, attrs, opts \\ []), to: EBossFolio
  defdelegate update_contact!(record, attrs, opts \\ []), to: EBossFolio
  defdelegate archive_contact(record, opts \\ []), to: EBossFolio
  defdelegate archive_contact!(record, opts \\ []), to: EBossFolio

  defdelegate create_project(attrs, opts \\ []), to: EBossFolio
  defdelegate create_project!(attrs, opts \\ []), to: EBossFolio
  defdelegate update_project_details(record, attrs, opts \\ []), to: EBossFolio
  defdelegate update_project_details!(record, attrs, opts \\ []), to: EBossFolio
  defdelegate activate_project(record, opts \\ []), to: EBossFolio
  defdelegate activate_project!(record, opts \\ []), to: EBossFolio
  defdelegate put_project_on_hold(record, opts \\ []), to: EBossFolio
  defdelegate put_project_on_hold!(record, opts \\ []), to: EBossFolio
  defdelegate complete_project(record, opts \\ []), to: EBossFolio
  defdelegate complete_project!(record, opts \\ []), to: EBossFolio
  defdelegate cancel_project(record, opts \\ []), to: EBossFolio
  defdelegate cancel_project!(record, opts \\ []), to: EBossFolio
  defdelegate archive_project(record, opts \\ []), to: EBossFolio
  defdelegate archive_project!(record, opts \\ []), to: EBossFolio
  defdelegate reposition_project(record, attrs, opts \\ []), to: EBossFolio
  defdelegate reposition_project!(record, attrs, opts \\ []), to: EBossFolio

  defdelegate create_task(attrs, opts \\ []), to: EBossFolio
  defdelegate create_task!(attrs, opts \\ []), to: EBossFolio
  defdelegate update_task_details(record, attrs, opts \\ []), to: EBossFolio
  defdelegate update_task_details!(record, attrs, opts \\ []), to: EBossFolio
  defdelegate move_task_to_inbox(record, opts \\ []), to: EBossFolio
  defdelegate move_task_to_inbox!(record, opts \\ []), to: EBossFolio
  defdelegate mark_task_next_action(record, opts \\ []), to: EBossFolio
  defdelegate mark_task_next_action!(record, opts \\ []), to: EBossFolio
  defdelegate mark_task_waiting_for(record, opts \\ []), to: EBossFolio
  defdelegate mark_task_waiting_for!(record, opts \\ []), to: EBossFolio
  defdelegate schedule_task(record, attrs, opts \\ []), to: EBossFolio
  defdelegate schedule_task!(record, attrs, opts \\ []), to: EBossFolio
  defdelegate mark_task_someday_maybe(record, opts \\ []), to: EBossFolio
  defdelegate mark_task_someday_maybe!(record, opts \\ []), to: EBossFolio
  defdelegate complete_task(record, opts \\ []), to: EBossFolio
  defdelegate complete_task!(record, opts \\ []), to: EBossFolio
  defdelegate cancel_task(record, opts \\ []), to: EBossFolio
  defdelegate cancel_task!(record, opts \\ []), to: EBossFolio
  defdelegate archive_task(record, opts \\ []), to: EBossFolio
  defdelegate archive_task!(record, opts \\ []), to: EBossFolio
  defdelegate reposition_task(record, attrs, opts \\ []), to: EBossFolio
  defdelegate reposition_task!(record, attrs, opts \\ []), to: EBossFolio

  defdelegate delegate_task(attrs, opts \\ []), to: EBossFolio
  defdelegate delegate_task!(attrs, opts \\ []), to: EBossFolio
  defdelegate complete_delegation(record, opts \\ []), to: EBossFolio
  defdelegate complete_delegation!(record, opts \\ []), to: EBossFolio
  defdelegate cancel_delegation(record, opts \\ []), to: EBossFolio
  defdelegate cancel_delegation!(record, opts \\ []), to: EBossFolio

  defdelegate list_revision_events(filters \\ %{}, opts \\ []), to: EBossFolio
  defdelegate list_revision_events!(filters \\ %{}, opts \\ []), to: EBossFolio
end
