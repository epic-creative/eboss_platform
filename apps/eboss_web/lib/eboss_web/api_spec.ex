defmodule EBossWeb.ApiSpec do
  @moduledoc false

  def spec do
    EBossWeb.JsonApiRouter.spec()
    |> normalize()
    |> merge_paths(bootstrap_paths())
    |> merge_paths(folio_app_paths())
    |> merge_components(bootstrap_components())
    |> merge_components(folio_app_components())
  end

  defp merge_paths(spec, extra_paths) do
    Map.update(spec, "paths", extra_paths, &Map.merge(&1, extra_paths))
  end

  defp merge_components(spec, extra_components) do
    Map.update(spec, "components", extra_components, fn components ->
      Map.merge(components, extra_components, fn
        "schemas", left, right -> Map.merge(left, right)
        _key, _left, right -> right
      end)
    end)
  end

  defp normalize(%_{} = struct), do: struct |> Map.from_struct() |> normalize()

  defp normalize(map) when is_map(map) do
    Enum.into(map, %{}, fn {key, value} ->
      {normalize_key(key), normalize(value)}
    end)
  end

  defp normalize(list) when is_list(list), do: Enum.map(list, &normalize/1)
  defp normalize(value), do: value

  defp normalize_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_key(key), do: key

  defp bootstrap_paths do
    %{
      "/api/v1/{owner_slug}/workspaces/{slug}/bootstrap" => bootstrap_path_item()
    }
  end

  defp bootstrap_path_item do
    %{
      "get" => %{
        "summary" => "Get workspace bootstrap payload",
        "description" =>
          "Returns the authenticated shell bootstrap payload for an accessible workspace.",
        "parameters" => [
          %{
            "name" => "owner_slug",
            "in" => "path",
            "required" => true,
            "schema" => %{"type" => "string"}
          },
          %{
            "name" => "slug",
            "in" => "path",
            "required" => true,
            "schema" => %{"type" => "string"}
          }
        ],
        "responses" => %{
          "200" => %{
            "description" => "Workspace bootstrap payload",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/WorkspaceBootstrap"}
              }
            }
          },
          "404" => %{
            "description" => "Workspace not found"
          }
        }
      }
    }
  end

  defp bootstrap_components do
    %{
      "schemas" => %{
        "WorkspaceSummary" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string"},
            "name" => %{"type" => "string"},
            "slug" => %{"type" => "string"},
            "full_path" => %{"type" => "string", "nullable" => true},
            "visibility" => %{"type" => "string", "nullable" => true},
            "owner_type" => %{"type" => "string"},
            "owner_id" => %{"type" => "string"},
            "owner_slug" => %{"type" => "string"},
            "owner_display_name" => %{"type" => "string"},
            "dashboard_path" => %{"type" => "string"},
            "current?" => %{"type" => "boolean"}
          },
          "required" => [
            "id",
            "name",
            "slug",
            "owner_type",
            "owner_id",
            "owner_slug",
            "owner_display_name",
            "dashboard_path"
          ]
        },
        "OwnerSummary" => %{
          "type" => "object",
          "properties" => %{
            "type" => %{"type" => "string"},
            "id" => %{"type" => "string"},
            "slug" => %{"type" => "string"},
            "display_name" => %{"type" => "string"}
          },
          "required" => ["type", "id", "slug", "display_name"]
        },
        "UserSummary" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string"},
            "email" => %{"type" => "string"},
            "username" => %{"type" => "string"},
            "role" => %{"type" => "string"}
          },
          "required" => ["id", "email", "username", "role"]
        },
        "WorkspaceCapabilities" => %{
          "type" => "object",
          "properties" => %{
            "read_workspace" => %{"type" => "boolean"},
            "manage_workspace" => %{"type" => "boolean"},
            "read_folio" => %{"type" => "boolean"},
            "manage_folio" => %{"type" => "boolean"}
          },
          "required" => ["read_workspace", "manage_workspace", "read_folio", "manage_folio"]
        },
        "WorkspaceAppCapabilities" => %{
          "type" => "object",
          "properties" => %{
            "read" => %{"type" => "boolean"},
            "manage" => %{"type" => "boolean"}
          },
          "required" => ["read", "manage"]
        },
        "WorkspaceApp" => %{
          "type" => "object",
          "properties" => %{
            "key" => %{"type" => "string"},
            "label" => %{"type" => "string"},
            "default_path" => %{"type" => "string"},
            "enabled" => %{"type" => "boolean"},
            "capabilities" => %{"$ref" => "#/components/schemas/WorkspaceAppCapabilities"}
          },
          "required" => ["key", "label", "default_path", "enabled", "capabilities"]
        },
        "WorkspaceBootstrap" => %{
          "type" => "object",
          "properties" => %{
            "current_user" => %{"$ref" => "#/components/schemas/UserSummary"},
            "workspace" => %{"$ref" => "#/components/schemas/WorkspaceSummary"},
            "owner" => %{"$ref" => "#/components/schemas/OwnerSummary"},
            "capabilities" => %{"$ref" => "#/components/schemas/WorkspaceCapabilities"},
            "apps" => %{
              "type" => "object",
              "additionalProperties" => %{"$ref" => "#/components/schemas/WorkspaceApp"}
            },
            "accessible_workspaces" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/WorkspaceSummary"}
            }
          },
          "required" => [
            "current_user",
            "workspace",
            "owner",
            "capabilities",
            "apps",
            "accessible_workspaces"
          ]
        }
      }
    }
  end

  defp folio_app_paths do
    %{
      "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/bootstrap" =>
        folio_bootstrap_path_item(),
      "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/projects" => folio_projects_path_item(),
      "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/projects/{project_id}" =>
        folio_project_path_item(),
      "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/tasks" => folio_tasks_path_item(),
      "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/tasks/{task_id}" =>
        folio_task_path_item(),
      "/api/v1/{owner_slug}/workspaces/{slug}/apps/folio/activity" => folio_activity_path_item()
    }
  end

  defp folio_bootstrap_path_item do
    %{
      "get" => %{
        "summary" => "Get workspace-scoped Folio app bootstrap payload",
        "description" =>
          "Returns the authenticated Folio app scope derived from workspace bootstrap for a workspace.",
        "parameters" => workspace_path_parameters(),
        "responses" => %{
          "200" => %{
            "description" => "Folio bootstrap payload",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/FolioAppBootstrap"}
              }
            }
          },
          "401" => %{"description" => "Authentication required"},
          "403" => %{"description" => "Workspace access is forbidden"},
          "404" => %{"description" => "Workspace not found"}
        }
      }
    }
  end

  defp folio_projects_path_item do
    %{
      "get" => %{
        "summary" => "List workspace-scoped Folio projects",
        "description" =>
          "Returns a workspace-scoped read-only list of project summaries for the Folio app.",
        "parameters" => workspace_path_parameters(),
        "responses" => %{
          "200" => %{
            "description" => "Folio projects list payload",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/FolioProjectsResponse"}
              }
            }
          },
          "401" => %{"description" => "Authentication required"},
          "403" => %{"description" => "Workspace access is forbidden"},
          "404" => %{"description" => "Workspace not found"}
        }
      },
      "post" => %{
        "summary" => "Create a workspace-scoped Folio project",
        "description" =>
          "Creates a new Folio project for the workspace. Returns the created project summary.",
        "parameters" => workspace_path_parameters(),
        "requestBody" => %{
          "required" => true,
          "content" => %{
            "application/json" => %{
              "schema" => %{"$ref" => "#/components/schemas/FolioProjectCreateRequest"}
            }
          }
        },
        "responses" => %{
          "201" => %{
            "description" => "Folio project created",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/FolioProjectCreateResponse"}
              }
            }
          },
          "400" => %{"description" => "Invalid payload"},
          "401" => %{"description" => "Authentication required"},
          "403" => %{"description" => "Workspace access is forbidden"},
          "404" => %{"description" => "Workspace not found"}
        }
      }
    }
  end

  defp folio_project_path_item do
    %{
      "patch" => %{
        "summary" => "Update workspace-scoped Folio project details",
        "description" =>
          "Updates editable project detail fields for a workspace-scoped Folio project.",
        "parameters" => workspace_project_path_parameters(),
        "requestBody" => %{
          "required" => true,
          "content" => %{
            "application/json" => %{
              "schema" => %{"$ref" => "#/components/schemas/FolioProjectUpdateRequest"}
            }
          }
        },
        "responses" => %{
          "200" => %{
            "description" => "Folio project updated",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/FolioProjectCreateResponse"}
              }
            }
          },
          "400" => %{"description" => "Invalid payload"},
          "401" => %{"description" => "Authentication required"},
          "403" => %{"description" => "Workspace access is forbidden"},
          "404" => %{"description" => "Workspace or project not found"}
        }
      }
    }
  end

  defp folio_tasks_path_item do
    %{
      "get" => %{
        "summary" => "List workspace-scoped Folio tasks",
        "description" =>
          "Returns a workspace-scoped read-only list of task summaries for the Folio app.",
        "parameters" => workspace_path_parameters(),
        "responses" => %{
          "200" => %{
            "description" => "Folio tasks list payload",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/FolioTasksResponse"}
              }
            }
          },
          "401" => %{"description" => "Authentication required"},
          "403" => %{"description" => "Workspace access is forbidden"},
          "404" => %{"description" => "Workspace not found"}
        }
      },
      "post" => %{
        "summary" => "Create a workspace-scoped Folio task",
        "description" =>
          "Creates a new Folio task for the workspace. Tasks may be created standalone or linked to a project.",
        "parameters" => workspace_path_parameters(),
        "requestBody" => %{
          "required" => true,
          "content" => %{
            "application/json" => %{
              "schema" => %{"$ref" => "#/components/schemas/FolioTaskCreateRequest"}
            }
          }
        },
        "responses" => %{
          "201" => %{
            "description" => "Folio task created",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/FolioTaskCreateResponse"}
              }
            }
          },
          "400" => %{"description" => "Invalid payload"},
          "401" => %{"description" => "Authentication required"},
          "403" => %{"description" => "Workspace access is forbidden"},
          "404" => %{"description" => "Workspace not found"}
        }
      }
    }
  end

  defp folio_task_path_item do
    %{
      "patch" => %{
        "summary" => "Transition workspace-scoped Folio task status",
        "description" =>
          "Transitions a Folio task to a supported status using the task workflow action model.",
        "parameters" => workspace_task_path_parameters(),
        "requestBody" => %{
          "required" => true,
          "content" => %{
            "application/json" => %{
              "schema" => %{"$ref" => "#/components/schemas/FolioTaskTransitionRequest"}
            }
          }
        },
        "responses" => %{
          "200" => %{
            "description" => "Folio task transitioned",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/FolioTaskCreateResponse"}
              }
            }
          },
          "400" => %{"description" => "Invalid payload or unsupported transition"},
          "401" => %{"description" => "Authentication required"},
          "403" => %{"description" => "Workspace access is forbidden"},
          "404" => %{"description" => "Workspace or task not found"}
        }
      }
    }
  end

  defp folio_activity_path_item do
    %{
      "get" => %{
        "summary" => "List workspace-scoped Folio activity events",
        "description" =>
          "Returns activity feed events sourced from Folio revision history for a workspace.",
        "parameters" => workspace_path_parameters(),
        "responses" => %{
          "200" => %{
            "description" => "Folio workspace activity feed response",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/FolioActivityResponse"}
              }
            }
          },
          "401" => %{"description" => "Authentication required"},
          "403" => %{"description" => "Workspace access is forbidden"},
          "404" => %{"description" => "Workspace not found"}
        }
      }
    }
  end

  defp workspace_path_parameters do
    [
      %{
        "name" => "owner_slug",
        "in" => "path",
        "required" => true,
        "schema" => %{"type" => "string"}
      },
      %{
        "name" => "slug",
        "in" => "path",
        "required" => true,
        "schema" => %{"type" => "string"}
      }
    ]
  end

  defp workspace_project_path_parameters do
    workspace_path_parameters() ++
      [
        %{
          "name" => "project_id",
          "in" => "path",
          "required" => true,
          "schema" => %{"type" => "string"}
        }
      ]
  end

  defp workspace_task_path_parameters do
    workspace_path_parameters() ++
      [
        %{
          "name" => "task_id",
          "in" => "path",
          "required" => true,
          "schema" => %{"type" => "string"}
        }
      ]
  end

  defp folio_app_components do
    %{
      "schemas" => %{
        "FolioAppScope" => %{
          "type" => "object",
          "properties" => %{
            "app_key" => %{"type" => "string", "enum" => ["folio"]},
            "workspace" => %{"$ref" => "#/components/schemas/WorkspaceSummary"},
            "owner" => %{"$ref" => "#/components/schemas/OwnerSummary"},
            "app" => %{"$ref" => "#/components/schemas/WorkspaceApp"},
            "capabilities" => %{"$ref" => "#/components/schemas/WorkspaceAppCapabilities"},
            "workspace_path" => %{"type" => "string"},
            "app_path" => %{"type" => "string"}
          },
          "required" => [
            "app_key",
            "workspace",
            "owner",
            "app",
            "capabilities",
            "app_path"
          ]
        },
        "FolioAppBootstrap" => %{
          "type" => "object",
          "properties" => %{
            "scope" => %{"$ref" => "#/components/schemas/FolioAppScope"},
            "summary_counts" => %{
              "type" => "object",
              "properties" => %{
                "projects" => %{"type" => "integer"},
                "tasks" => %{"type" => "integer"}
              },
              "required" => ["projects", "tasks"]
            }
          },
          "required" => ["scope", "summary_counts"]
        },
        "FolioProjectSummary" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string"},
            "title" => %{"type" => "string"},
            "description" => %{"type" => "string", "nullable" => true},
            "status" => %{"type" => "string"},
            "priority_position" => %{"type" => "integer", "nullable" => true},
            "due_at" => %{"type" => "string", "format" => "date-time", "nullable" => true},
            "review_at" => %{"type" => "string", "format" => "date-time", "nullable" => true},
            "notes" => %{"type" => "string", "nullable" => true},
            "metadata" => %{"type" => "object"}
          },
          "required" => ["id", "title", "status"]
        },
        "FolioProjectCreateRequest" => %{
          "type" => "object",
          "properties" => %{
            "title" => %{
              "type" => "string",
              "minLength" => 1,
              "description" => "Project title"
            },
            "status" => %{
              "type" => "string",
              "enum" => ["active", "on_hold", "completed", "canceled", "archived"],
              "description" => "Initial project status"
            },
            "description" => %{
              "type" => "string",
              "nullable" => true
            },
            "due_at" => %{
              "type" => "string",
              "format" => "date-time",
              "nullable" => true
            },
            "review_at" => %{
              "type" => "string",
              "format" => "date-time",
              "nullable" => true
            }
          },
          "required" => ["title"]
        },
        "FolioProjectUpdateRequest" => %{
          "type" => "object",
          "properties" => %{
            "title" => %{
              "type" => "string",
              "minLength" => 1,
              "description" => "Project title"
            },
            "description" => %{
              "type" => "string",
              "nullable" => true
            },
            "notes" => %{
              "type" => "string",
              "nullable" => true
            },
            "due_at" => %{
              "type" => "string",
              "format" => "date-time",
              "nullable" => true
            },
            "review_at" => %{
              "type" => "string",
              "format" => "date-time",
              "nullable" => true
            },
            "metadata" => %{
              "type" => "object"
            }
          }
        },
        "FolioTaskSummary" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string"},
            "title" => %{"type" => "string"},
            "status" => %{"type" => "string"},
            "project_id" => %{"type" => "string", "nullable" => true},
            "priority_position" => %{"type" => "integer", "nullable" => true},
            "due_at" => %{"type" => "string", "format" => "date-time", "nullable" => true},
            "review_at" => %{"type" => "string", "format" => "date-time", "nullable" => true}
          },
          "required" => ["id", "title", "status"]
        },
        "FolioTaskCreateRequest" => %{
          "type" => "object",
          "properties" => %{
            "title" => %{
              "type" => "string",
              "minLength" => 1,
              "description" => "Task title"
            },
            "project_id" => %{
              "type" => "string",
              "nullable" => true,
              "description" => "Optional workspace project identifier to link this task."
            }
          },
          "required" => ["title"]
        },
        "FolioTaskTransitionRequest" => %{
          "type" => "object",
          "properties" => %{
            "status" => %{
              "type" => "string",
              "enum" => [
                "inbox",
                "next_action",
                "waiting_for",
                "scheduled",
                "someday_maybe",
                "done",
                "canceled",
                "archived"
              ],
              "description" => "Target task status transition"
            }
          },
          "required" => ["status"]
        },
        "FolioProjectsResponse" => %{
          "type" => "object",
          "properties" => %{
            "scope" => %{"$ref" => "#/components/schemas/FolioAppScope"},
            "projects" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/FolioProjectSummary"}
            }
          },
          "required" => ["scope", "projects"]
        },
        "FolioProjectCreateResponse" => %{
          "type" => "object",
          "properties" => %{
            "scope" => %{"$ref" => "#/components/schemas/FolioAppScope"},
            "project" => %{"$ref" => "#/components/schemas/FolioProjectSummary"}
          },
          "required" => ["scope", "project"]
        },
        "FolioTasksResponse" => %{
          "type" => "object",
          "properties" => %{
            "scope" => %{"$ref" => "#/components/schemas/FolioAppScope"},
            "tasks" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/FolioTaskSummary"}
            }
          },
          "required" => ["scope", "tasks"]
        },
        "FolioTaskCreateResponse" => %{
          "type" => "object",
          "properties" => %{
            "scope" => %{"$ref" => "#/components/schemas/FolioAppScope"},
            "task" => %{"$ref" => "#/components/schemas/FolioTaskSummary"}
          },
          "required" => ["scope", "task"]
        },
        "FolioActivityEvent" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string"},
            "app_key" => %{"type" => "string"},
            "provider_key" => %{"type" => "string"},
            "provider_event_id" => %{"type" => "string"},
            "occurred_at" => %{"type" => "string", "format" => "date-time"},
            "actor" => %{
              "type" => "object",
              "properties" => %{
                "type" => %{"type" => "string"},
                "id" => %{"type" => "string", "nullable" => true},
                "label" => %{"type" => "string", "nullable" => true}
              },
              "required" => ["type"]
            },
            "action" => %{"type" => "string"},
            "summary" => %{"type" => "string"},
            "subject" => %{
              "type" => "object",
              "properties" => %{
                "type" => %{"type" => "string"},
                "id" => %{"type" => "string", "nullable" => true},
                "label" => %{"type" => "string", "nullable" => true}
              },
              "required" => ["type", "id"]
            },
            "details" => %{"type" => "string", "nullable" => true},
            "status" => %{"type" => "string", "nullable" => true},
            "changes" => %{"type" => "object", "nullable" => true},
            "metadata" => %{"type" => "object"},
            "resource_path" => %{"type" => "string", "nullable" => true}
          },
          "required" => [
            "id",
            "app_key",
            "provider_key",
            "provider_event_id",
            "occurred_at",
            "actor",
            "action",
            "summary",
            "subject"
          ]
        },
        "FolioActivityResponse" => %{
          "type" => "object",
          "properties" => %{
            "scope" => %{"$ref" => "#/components/schemas/FolioAppScope"},
            "events" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/FolioActivityEvent"}
            }
          },
          "required" => ["scope", "events"]
        }
      }
    }
  end
end
