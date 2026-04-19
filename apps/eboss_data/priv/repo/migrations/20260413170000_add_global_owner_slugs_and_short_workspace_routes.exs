defmodule EBoss.Repo.Migrations.AddGlobalOwnerSlugsAndShortWorkspaceRoutes do
  use Ecto.Migration

  def up do
    create table(:owner_slugs, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :slug, :text, null: false
      add :owner_type, :text, null: false
      add :owner_id, :uuid, null: false

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    alter table(:users) do
      add :owner_slug, :text
    end

    rename table(:organizations), :slug, to: :owner_slug

    drop_if_exists(
      unique_index(:organizations, [:owner_slug], name: "organizations_unique_slug_index")
    )

    create(
      unique_index(:organizations, [:owner_slug],
        where: "((archived_at IS NULL))",
        name: "organizations_unique_owner_slug_index"
      )
    )

    rename table(:workspaces), :owner_handle, to: :owner_slug

    execute("""
    UPDATE users
    SET owner_slug = lower(username)
    WHERE owner_slug IS NULL
    """)

    alter table(:users) do
      modify :owner_slug, :text, null: false
    end

    create unique_index(:users, [:owner_slug], name: "users_unique_owner_slug_index")

    create unique_index(:owner_slugs, [:slug], name: "owner_slugs_unique_slug_index")

    create unique_index(:owner_slugs, [:owner_type, :owner_id], name: "owner_slugs_unique_owner_index")

    execute("""
    INSERT INTO owner_slugs (slug, owner_type, owner_id, inserted_at, updated_at)
    SELECT owner_slug, 'user', id, (now() AT TIME ZONE 'utc'), (now() AT TIME ZONE 'utc')
    FROM users
    """)

    execute("""
    INSERT INTO owner_slugs (slug, owner_type, owner_id, inserted_at, updated_at)
    SELECT owner_slug, 'organization', id, (now() AT TIME ZONE 'utc'), (now() AT TIME ZONE 'utc')
    FROM organizations
    """)
  end

  def down do
    rename table(:workspaces), :owner_slug, to: :owner_handle

    drop_if_exists(
      unique_index(:organizations, [:owner_slug], name: "organizations_unique_owner_slug_index")
    )

    create(
      unique_index(:organizations, [:owner_slug],
        where: "((archived_at IS NULL))",
        name: "organizations_unique_slug_index"
      )
    )

    rename table(:organizations), :owner_slug, to: :slug

    drop_if_exists(unique_index(:users, [:owner_slug], name: "users_unique_owner_slug_index"))

    alter table(:users) do
      remove :owner_slug
    end

    drop table(:owner_slugs)
  end
end
