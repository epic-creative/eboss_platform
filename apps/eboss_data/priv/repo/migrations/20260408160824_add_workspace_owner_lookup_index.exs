defmodule EBoss.Repo.Migrations.AddWorkspaceOwnerLookupIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    create(
      index(:workspaces, [:owner_type, :owner_id],
        name: "workspaces_owner_lookup_index",
        where: "(archived_at IS NULL)",
        concurrently: true
      )
    )
  end

  def down do
    drop_if_exists(
      index(:workspaces, [:owner_type, :owner_id],
        name: "workspaces_owner_lookup_index",
        concurrently: true
      )
    )
  end
end
