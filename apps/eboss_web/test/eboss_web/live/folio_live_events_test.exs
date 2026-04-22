defmodule EBossWeb.FolioLiveEventsTest do
  use EBossWeb.ConnCase, async: false

  alias EBossFolio

  test "workspace Folio project mutations run through LiveView event replies", %{conn: conn} do
    %{conn: conn, current_user: user} = register_and_log_in_user(%{conn: conn})
    workspace = create_user_workspace(user, %{name: "Folio Live Events"})

    assert {:ok, view, _html} =
             live(conn, dashboard_path(user.owner_slug, workspace.slug) <> "/apps/folio/projects")

    render_hook(view, "folio:create_project", %{"title" => "Live project"})

    assert_reply view, %{
      ok: true,
      project: %{id: project_id, title: "Live project", status: :active}
    }

    assert {:ok, project} =
             EBossFolio.get_project_in_workspace(project_id, workspace.id, actor: user)

    assert project.title == "Live project"

    render_hook(view, "folio:transition_project", %{
      "project_id" => project_id,
      "status" => "completed"
    })

    assert_reply view, %{
      ok: true,
      project: %{id: ^project_id, title: "Live project", status: :completed}
    }
  end

  test "workspace Folio task mutations run through LiveView event replies", %{conn: conn} do
    %{conn: conn, current_user: user} = register_and_log_in_user(%{conn: conn})
    workspace = create_user_workspace(user, %{name: "Folio Task Events"})

    project =
      EBossFolio.create_project!(%{workspace_id: workspace.id, title: "Task project"},
        actor: user
      )

    assert {:ok, view, _html} =
             live(conn, dashboard_path(user.owner_slug, workspace.slug) <> "/apps/folio/tasks")

    render_hook(view, "folio:create_task", %{
      "title" => "Live task",
      "project_id" => project.id
    })

    assert_reply view, %{
      ok: true,
      task: %{id: task_id, title: "Live task", status: :inbox, project_id: project_id}
    }

    assert project_id == project.id

    render_hook(view, "folio:transition_task", %{
      "task_id" => task_id,
      "status" => "done"
    })

    assert_reply view, %{
      ok: true,
      task: %{id: ^task_id, title: "Live task", status: :done}
    }
  end

  test "workspace Folio delegation returns the active delegation in the task payload", %{
    conn: conn
  } do
    %{conn: conn, current_user: user} = register_and_log_in_user(%{conn: conn})
    workspace = create_user_workspace(user, %{name: "Folio Delegation Events"})

    task =
      EBossFolio.create_task!(%{workspace_id: workspace.id, title: "Delegate live task"},
        actor: user
      )

    assert {:ok, view, _html} =
             live(conn, dashboard_path(user.owner_slug, workspace.slug) <> "/apps/folio/tasks")

    render_hook(view, "folio:delegate_task", %{
      "task_id" => task.id,
      "contact_name" => "Avery Partner",
      "delegated_summary" => "Send updated approval notes"
    })

    assert_reply view, %{
      ok: true,
      task: %{
        id: task_id,
        status: :waiting_for,
        active_delegation: %{
          status: :active,
          delegated_summary: "Send updated approval notes",
          contact: %{name: "Avery Partner"}
        }
      }
    }

    assert task_id == task.id
  end
end
