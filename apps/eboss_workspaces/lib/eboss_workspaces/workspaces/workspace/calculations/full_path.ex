defmodule EBoss.Workspaces.Workspace.Calculations.FullPath do
  use Ash.Resource.Calculation

  alias EBoss.Workspaces.Workspace.OwnerSnapshot

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def load(_query, _opts, _context), do: [:owner_type, :owner_slug, :slug]

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, &OwnerSnapshot.full_path/1)
  end
end
