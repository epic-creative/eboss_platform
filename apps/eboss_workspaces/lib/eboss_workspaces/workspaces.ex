defmodule EBoss.Workspaces do
  @moduledoc """
  The Workspaces domain for managing user and organization workspaces.
  """

  use Ash.Domain, otp_app: :eboss_workspaces

  resources do
    resource(EBoss.Workspaces.Workspace)
    resource(EBoss.Workspaces.WorkspaceMembership)
  end
end
