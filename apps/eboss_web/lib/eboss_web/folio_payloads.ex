defmodule EBossWeb.FolioPayloads do
  @moduledoc false

  def project_summary(%EBossFolio.Project{} = project) do
    %{
      id: project.id,
      title: project.title,
      description: project.description,
      status: project.status,
      priority_position: project.priority_position,
      due_at: project.due_at,
      review_at: project.review_at,
      notes: project.notes,
      metadata: project.metadata
    }
  end

  def task_summary(%EBossFolio.Task{} = task) do
    %{
      id: task.id,
      title: task.title,
      status: task.status,
      project_id: task.project_id,
      priority_position: task.priority_position,
      due_at: task.due_at,
      review_at: task.review_at,
      active_delegation: active_delegation(task)
    }
  end

  defp active_delegation(%EBossFolio.Task{delegations: delegations})
       when is_list(delegations) do
    case Enum.find(delegations, &(&1.status == :active)) do
      nil ->
        nil

      delegation ->
        %{
          id: delegation.id,
          status: delegation.status,
          delegated_at: delegation.delegated_at,
          delegated_summary: delegation.delegated_summary,
          quality_expectations: delegation.quality_expectations,
          deadline_expectations_at: delegation.deadline_expectations_at,
          follow_up_at: delegation.follow_up_at,
          contact: delegation_contact(delegation)
        }
    end
  end

  defp active_delegation(_task), do: nil

  defp delegation_contact(%EBossFolio.Delegation{
         contact: %EBossFolio.Contact{} = contact
       }) do
    %{
      id: contact.id,
      name: contact.name,
      email: contact.email
    }
  end

  defp delegation_contact(%EBossFolio.Delegation{contact_id: contact_id}) do
    %{
      id: contact_id,
      name: nil,
      email: nil
    }
  end
end
