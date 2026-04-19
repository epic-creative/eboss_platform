defmodule EBoss.Workspaces.Workspace.Calculations.Owner do
  use Ash.Resource.Calculation

  alias EBoss.Workspaces.Workspace.OwnerSnapshot

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def load(_query, _opts, _context),
    do: [:owner_type, :owner_id, :owner_slug, :owner_display_name]

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, &OwnerSnapshot.owner_summary/1)
  end
end
