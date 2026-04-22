defmodule EBossNotify.TestSupport do
  @moduledoc false

  alias EBoss.Accounts
  alias EBoss.Workspaces

  def register_user(overrides \\ %{}) do
    params =
      Map.merge(
        %{
          email: "notify-user#{System.unique_integer([:positive])}@example.com",
          username: "notify-user#{System.unique_integer([:positive])}",
          password: "supersecret123",
          password_confirmation: "supersecret123"
        },
        Map.new(overrides)
      )

    Accounts.register_with_password!(params, authorize?: false)
  end

  def create_user_workspace(owner, attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          name: "Notify Workspace #{System.unique_integer([:positive])}",
          owner_type: :user,
          owner_id: owner.id
        },
        Map.new(attrs)
      )

    Workspaces.create_workspace!(attrs, actor: owner)
  end

  def create_workspace_member(owner, workspace, user, role \\ :member) do
    Workspaces.create_workspace_membership!(
      %{workspace_id: workspace.id, user_id: user.id, role: role},
      actor: owner
    )
  end
end
