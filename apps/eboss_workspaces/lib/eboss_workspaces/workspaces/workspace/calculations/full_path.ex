defmodule EBoss.Workspaces.Workspace.Calculations.FullPath do
  use Ash.Resource.Calculation

  def init(opts), do: {:ok, opts}

  def calculate(records, _opts, %{domain: _domain}) do
    Enum.map(records, fn record ->
      case record.owner_type do
        :user ->
          case Ash.get(EBoss.Accounts.User, record.owner_id,
                 domain: EBoss.Accounts,
                 authorize?: false
               ) do
            {:ok, user} -> "@#{user.username}/#{record.slug}"
            {:error, _error} -> "unknown/#{record.slug}"
          end

        :organization ->
          case Ash.get(EBoss.Organizations.Organization, record.owner_id,
                 domain: EBoss.Organizations,
                 authorize?: false
               ) do
            {:ok, organization} -> "@#{organization.slug}/#{record.slug}"
            {:error, _error} -> "unknown/#{record.slug}"
          end
      end
    end)
  end
end
