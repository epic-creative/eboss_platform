defmodule EBossWeb.ApiSpec do
  @moduledoc false

  def spec do
    EBossWeb.JsonApiRouter.spec()
    |> normalize()
    |> merge_paths(bootstrap_paths())
    |> merge_paths(folio_app_paths())
    |> merge_paths(chat_app_paths())
    |> merge_paths(notification_paths())
    |> merge_components(bootstrap_components())
    |> merge_components(folio_app_components())
    |> merge_components(chat_app_components())
    |> merge_components(notification_components())
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
            "manage_folio" => %{"type" => "boolean"},
            "read_chat" => %{"type" => "boolean"},
            "manage_chat" => %{"type" => "boolean"}
          },
          "required" => [
            "read_workspace",
            "manage_workspace",
            "read_folio",
            "manage_folio",
            "read_chat",
            "manage_chat"
          ]
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

  defp chat_app_paths do
    %{
      "/api/v1/{owner_slug}/workspaces/{slug}/apps/chat/bootstrap" => chat_bootstrap_path_item(),
      "/api/v1/{owner_slug}/workspaces/{slug}/apps/chat/sessions" => chat_sessions_path_item(),
      "/api/v1/{owner_slug}/workspaces/{slug}/apps/chat/sessions/{session_id}" =>
        chat_session_path_item(),
      "/api/v1/{owner_slug}/workspaces/{slug}/apps/chat/sessions/{session_id}/messages/stream" =>
        chat_stream_path_item()
    }
  end

  defp notification_paths do
    %{
      "/api/v1/notifications/bootstrap" => notification_bootstrap_path_item(),
      "/api/v1/notifications" => notification_index_path_item(),
      "/api/v1/notifications/{recipient_id}" => notification_recipient_path_item(),
      "/api/v1/notifications/read-all" => notification_read_all_path_item(),
      "/api/v1/notifications/preferences" => notification_preferences_path_item(),
      "/api/v1/notifications/channels" => notification_channels_path_item(),
      "/api/v1/notifications/channels/{endpoint_id}" => notification_channel_path_item()
    }
  end

  defp notification_bootstrap_path_item do
    %{
      "get" => %{
        "summary" => "Get notification bootstrap payload",
        "description" => "Returns unread count, recent notifications, preferences, and channels.",
        "responses" => notification_json_response("NotificationBootstrap")
      }
    }
  end

  defp notification_index_path_item do
    %{
      "get" => %{
        "summary" => "List notifications",
        "description" => "Returns recipient-scoped notifications for the authenticated user.",
        "parameters" => [
          query_parameter("status"),
          query_parameter("scope_type"),
          query_parameter("workspace_id"),
          query_parameter("app_key")
        ],
        "responses" => notification_json_response("NotificationListResponse")
      }
    }
  end

  defp notification_recipient_path_item do
    %{
      "patch" => %{
        "summary" => "Update notification recipient state",
        "description" => "Marks a notification recipient as read or archived.",
        "parameters" => [recipient_id_parameter()],
        "requestBody" => json_request_body("NotificationRecipientUpdateRequest"),
        "responses" => notification_json_response("NotificationUpdateResponse")
      }
    }
  end

  defp notification_read_all_path_item do
    %{
      "post" => %{
        "summary" => "Mark all notifications read",
        "description" => "Marks every unread notification for the authenticated user as read.",
        "responses" => notification_json_response("NotificationReadAllResponse")
      }
    }
  end

  defp notification_preferences_path_item do
    %{
      "get" => %{
        "summary" => "List notification preferences",
        "responses" => notification_json_response("NotificationPreferencesResponse")
      },
      "patch" => %{
        "summary" => "Upsert notification preferences",
        "requestBody" => json_request_body("NotificationPreferencesUpdateRequest"),
        "responses" => notification_json_response("NotificationPreferencesResponse")
      }
    }
  end

  defp notification_channels_path_item do
    %{
      "get" => %{
        "summary" => "List notification channel endpoints",
        "responses" => notification_json_response("NotificationChannelsResponse")
      }
    }
  end

  defp notification_channel_path_item do
    %{
      "patch" => %{
        "summary" => "Update a notification channel endpoint",
        "parameters" => [endpoint_id_parameter()],
        "requestBody" => json_request_body("NotificationChannelUpdateRequest"),
        "responses" => notification_json_response("NotificationChannelUpdateResponse")
      }
    }
  end

  defp chat_bootstrap_path_item do
    %{
      "get" => %{
        "summary" => "Get workspace-scoped chat app bootstrap payload",
        "description" =>
          "Returns the authenticated workspace chat scope, sessions, and token usage totals.",
        "parameters" => workspace_path_parameters(),
        "responses" => %{
          "200" => %{
            "description" => "Chat bootstrap payload",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/ChatBootstrapResponse"}
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

  defp chat_sessions_path_item do
    %{
      "get" => %{
        "summary" => "List workspace chat sessions",
        "description" => "Returns active chat sessions for the workspace.",
        "parameters" => workspace_path_parameters(),
        "responses" => %{
          "200" => %{
            "description" => "Chat sessions payload",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/ChatSessionsResponse"}
              }
            }
          }
        }
      },
      "post" => %{
        "summary" => "Create a workspace chat session",
        "description" => "Creates a new shared workspace chat session.",
        "parameters" => workspace_path_parameters(),
        "requestBody" => %{
          "required" => true,
          "content" => %{
            "application/json" => %{
              "schema" => %{"$ref" => "#/components/schemas/ChatSessionCreateRequest"}
            }
          }
        },
        "responses" => %{
          "201" => %{
            "description" => "Created chat session payload",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/ChatSessionResponse"}
              }
            }
          }
        }
      }
    }
  end

  defp chat_session_path_item do
    %{
      "get" => %{
        "summary" => "Get a workspace chat session with messages",
        "description" => "Returns a shared chat session and its persisted transcript.",
        "parameters" => workspace_path_parameters() ++ chat_session_parameters(),
        "responses" => %{
          "200" => %{
            "description" => "Chat session detail payload",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/ChatSessionDetailResponse"}
              }
            }
          }
        }
      },
      "patch" => %{
        "summary" => "Archive a workspace chat session",
        "description" => "Archives an existing shared chat session.",
        "parameters" => workspace_path_parameters() ++ chat_session_parameters(),
        "requestBody" => %{
          "required" => true,
          "content" => %{
            "application/json" => %{
              "schema" => %{"$ref" => "#/components/schemas/ChatSessionUpdateRequest"}
            }
          }
        },
        "responses" => %{
          "200" => %{
            "description" => "Updated chat session payload",
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/ChatSessionResponse"}
              }
            }
          }
        }
      }
    }
  end

  defp chat_stream_path_item do
    %{
      "post" => %{
        "summary" => "Stream a reply into a workspace chat session",
        "description" =>
          "Creates a new user turn and streams the assistant reply as server-sent events.",
        "parameters" => workspace_path_parameters() ++ chat_session_parameters(),
        "requestBody" => %{
          "required" => true,
          "content" => %{
            "application/json" => %{
              "schema" => %{"$ref" => "#/components/schemas/ChatStreamRequest"}
            }
          }
        },
        "responses" => %{
          "200" => %{
            "description" => "Chat stream response",
            "content" => %{
              "text/event-stream" => %{
                "schema" => %{"type" => "string"}
              }
            }
          }
        }
      }
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
        "summary" => "Update or transition a workspace-scoped Folio project",
        "description" =>
          "Updates editable project detail fields or applies a supported project status transition for a workspace-scoped Folio project.",
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
        "summary" => "Apply a workspace-scoped Folio task workflow mutation",
        "description" =>
          "Transitions a Folio task status or delegates the task using the existing contact/delegation workflow model.",
        "parameters" => workspace_task_path_parameters(),
        "requestBody" => %{
          "required" => true,
          "content" => %{
            "application/json" => %{
              "schema" => %{"$ref" => "#/components/schemas/FolioTaskMutationRequest"}
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

  defp chat_session_parameters do
    [
      %{
        "name" => "session_id",
        "in" => "path",
        "required" => true,
        "schema" => %{"type" => "string"}
      }
    ]
  end

  defp recipient_id_parameter do
    %{
      "name" => "recipient_id",
      "in" => "path",
      "required" => true,
      "schema" => %{"type" => "string"}
    }
  end

  defp endpoint_id_parameter do
    %{
      "name" => "endpoint_id",
      "in" => "path",
      "required" => true,
      "schema" => %{"type" => "string"}
    }
  end

  defp query_parameter(name) do
    %{
      "name" => name,
      "in" => "query",
      "required" => false,
      "schema" => %{"type" => "string"}
    }
  end

  defp json_request_body(schema_name) do
    %{
      "required" => true,
      "content" => %{
        "application/json" => %{
          "schema" => %{"$ref" => "#/components/schemas/#{schema_name}"}
        }
      }
    }
  end

  defp notification_json_response(schema_name) do
    %{
      "200" => %{
        "description" => schema_name,
        "content" => %{
          "application/json" => %{
            "schema" => %{"$ref" => "#/components/schemas/#{schema_name}"}
          }
        }
      },
      "401" => %{"description" => "Authentication required"}
    }
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
            "status" => %{
              "type" => "string",
              "enum" => ["active", "on_hold", "completed", "canceled", "archived"],
              "description" =>
                "Target project status transition. When provided, it must be the only field in the request body."
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
        "FolioTaskDelegationContactSummary" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string"},
            "name" => %{"type" => "string", "nullable" => true},
            "email" => %{"type" => "string", "nullable" => true}
          },
          "required" => ["id"]
        },
        "FolioTaskActiveDelegationSummary" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string"},
            "status" => %{"type" => "string", "enum" => ["active", "completed", "canceled"]},
            "delegated_at" => %{"type" => "string", "format" => "date-time"},
            "delegated_summary" => %{"type" => "string"},
            "quality_expectations" => %{"type" => "string", "nullable" => true},
            "deadline_expectations_at" => %{
              "type" => "string",
              "format" => "date-time",
              "nullable" => true
            },
            "follow_up_at" => %{
              "type" => "string",
              "format" => "date-time",
              "nullable" => true
            },
            "contact" => %{"$ref" => "#/components/schemas/FolioTaskDelegationContactSummary"}
          },
          "required" => ["id", "status", "delegated_at", "delegated_summary", "contact"]
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
            "review_at" => %{"type" => "string", "format" => "date-time", "nullable" => true},
            "active_delegation" => %{
              "nullable" => true,
              "allOf" => [%{"$ref" => "#/components/schemas/FolioTaskActiveDelegationSummary"}]
            }
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
            "intent" => %{
              "type" => "string",
              "enum" => ["transition"],
              "description" => "Optional explicit task workflow intent selector."
            },
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
        "FolioTaskDelegationRequest" => %{
          "type" => "object",
          "properties" => %{
            "intent" => %{
              "type" => "string",
              "enum" => ["delegate"],
              "description" => "Selects delegated-work workflow mutation."
            },
            "contact_id" => %{
              "type" => "string",
              "description" =>
                "Existing workspace contact identifier. Provide this or contact_name."
            },
            "contact_name" => %{
              "type" => "string",
              "description" => "Contact name to create and use for delegation."
            },
            "delegated_summary" => %{
              "type" => "string",
              "minLength" => 1,
              "description" => "Summary of delegated work."
            },
            "quality_expectations" => %{
              "type" => "string",
              "nullable" => true
            },
            "deadline_expectations_at" => %{
              "type" => "string",
              "format" => "date-time",
              "nullable" => true
            },
            "follow_up_at" => %{
              "type" => "string",
              "format" => "date-time",
              "nullable" => true
            }
          },
          "required" => ["intent", "delegated_summary"]
        },
        "FolioTaskMutationRequest" => %{
          "oneOf" => [
            %{"$ref" => "#/components/schemas/FolioTaskTransitionRequest"},
            %{"$ref" => "#/components/schemas/FolioTaskDelegationRequest"}
          ]
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

  defp chat_app_components do
    %{
      "schemas" => %{
        "ChatAppScope" => %{
          "type" => "object",
          "properties" => %{
            "app_key" => %{"type" => "string", "enum" => ["chat"]},
            "workspace" => %{"$ref" => "#/components/schemas/WorkspaceSummary"},
            "owner" => %{"$ref" => "#/components/schemas/OwnerSummary"},
            "app" => %{"$ref" => "#/components/schemas/WorkspaceApp"},
            "capabilities" => %{"$ref" => "#/components/schemas/WorkspaceAppCapabilities"},
            "workspace_path" => %{"type" => "string"},
            "app_path" => %{"type" => "string"}
          },
          "required" => ["app_key", "workspace", "owner", "app", "capabilities", "app_path"]
        },
        "ChatSessionUser" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string"},
            "username" => %{"type" => "string"},
            "email" => %{"type" => "string"}
          },
          "required" => ["id", "username", "email"]
        },
        "ChatUsageTotals" => %{
          "type" => "object",
          "properties" => %{
            "input_tokens" => %{"type" => "integer"},
            "output_tokens" => %{"type" => "integer"},
            "total_tokens" => %{"type" => "integer"}
          },
          "required" => ["input_tokens", "output_tokens", "total_tokens"]
        },
        "ChatWorkspaceUsageTotals" => %{
          "type" => "object",
          "properties" => %{
            "sessions" => %{"type" => "integer"},
            "input_tokens" => %{"type" => "integer"},
            "output_tokens" => %{"type" => "integer"},
            "total_tokens" => %{"type" => "integer"}
          },
          "required" => ["sessions", "input_tokens", "output_tokens", "total_tokens"]
        },
        "ChatSessionSummary" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string"},
            "title" => %{"type" => "string"},
            "status" => %{"type" => "string", "enum" => ["active", "archived"]},
            "last_message_at" => %{
              "type" => "string",
              "format" => "date-time",
              "nullable" => true
            },
            "last_activity_at" => %{
              "type" => "string",
              "format" => "date-time",
              "nullable" => true
            },
            "message_count" => %{"type" => "integer"},
            "usage_totals" => %{"$ref" => "#/components/schemas/ChatUsageTotals"},
            "created_by_user" => %{"$ref" => "#/components/schemas/ChatSessionUser"},
            "path" => %{"type" => "string"}
          },
          "required" => [
            "id",
            "title",
            "status",
            "message_count",
            "usage_totals",
            "created_by_user",
            "path"
          ]
        },
        "ChatMessageSummary" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string"},
            "role" => %{"type" => "string", "enum" => ["user", "assistant", "system"]},
            "body" => %{"type" => "string"},
            "status" => %{"type" => "string", "enum" => ["pending", "complete", "error"]},
            "sequence" => %{"type" => "integer"},
            "provider" => %{"type" => "string", "nullable" => true},
            "model" => %{"type" => "string", "nullable" => true},
            "input_tokens" => %{"type" => "integer"},
            "output_tokens" => %{"type" => "integer"},
            "total_tokens" => %{"type" => "integer"},
            "finish_reason" => %{"type" => "string", "nullable" => true},
            "error_message" => %{"type" => "string", "nullable" => true},
            "inserted_at" => %{"type" => "string", "format" => "date-time"},
            "author" => %{"$ref" => "#/components/schemas/ChatSessionUser", "nullable" => true}
          },
          "required" => [
            "id",
            "role",
            "body",
            "status",
            "sequence",
            "input_tokens",
            "output_tokens",
            "total_tokens",
            "inserted_at"
          ]
        },
        "ChatBootstrapResponse" => %{
          "type" => "object",
          "properties" => %{
            "scope" => %{"$ref" => "#/components/schemas/ChatAppScope"},
            "default_model_key" => %{"type" => "string"},
            "models" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/ChatModelOption"}
            },
            "usage_totals" => %{"$ref" => "#/components/schemas/ChatWorkspaceUsageTotals"},
            "sessions" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/ChatSessionSummary"}
            }
          },
          "required" => ["scope", "default_model_key", "models", "usage_totals", "sessions"]
        },
        "ChatModelOption" => %{
          "type" => "object",
          "properties" => %{
            "key" => %{"type" => "string"},
            "label" => %{"type" => "string"},
            "provider" => %{"type" => "string", "enum" => ["anthropic", "openai"]},
            "model" => %{"type" => "string"}
          },
          "required" => ["key", "label", "provider", "model"]
        },
        "ChatSessionsResponse" => %{
          "type" => "object",
          "properties" => %{
            "scope" => %{"$ref" => "#/components/schemas/ChatAppScope"},
            "sessions" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/ChatSessionSummary"}
            }
          },
          "required" => ["scope", "sessions"]
        },
        "ChatSessionResponse" => %{
          "type" => "object",
          "properties" => %{
            "scope" => %{"$ref" => "#/components/schemas/ChatAppScope"},
            "session" => %{"$ref" => "#/components/schemas/ChatSessionSummary"}
          },
          "required" => ["scope", "session"]
        },
        "ChatSessionDetailResponse" => %{
          "type" => "object",
          "properties" => %{
            "scope" => %{"$ref" => "#/components/schemas/ChatAppScope"},
            "session" => %{"$ref" => "#/components/schemas/ChatSessionSummary"},
            "messages" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/ChatMessageSummary"}
            }
          },
          "required" => ["scope", "session", "messages"]
        },
        "ChatSessionCreateRequest" => %{
          "type" => "object",
          "properties" => %{
            "title_seed" => %{"type" => "string", "nullable" => true}
          }
        },
        "ChatSessionUpdateRequest" => %{
          "type" => "object",
          "properties" => %{
            "status" => %{"type" => "string", "enum" => ["archived"]}
          },
          "required" => ["status"]
        },
        "ChatStreamRequest" => %{
          "type" => "object",
          "properties" => %{
            "body" => %{"type" => "string", "minLength" => 1},
            "model_key" => %{
              "type" => "string",
              "enum" => ["anthropic_haiku_4_5", "openai_gpt_4o_mini"],
              "nullable" => true
            }
          },
          "required" => ["body"]
        }
      }
    }
  end

  defp notification_components do
    %{
      "schemas" => %{
        "NotificationBootstrap" => %{
          "type" => "object",
          "properties" => %{
            "unread_count" => %{"type" => "integer"},
            "recent" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/NotificationSummary"}
            },
            "preferences" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/NotificationPreferenceSummary"}
            },
            "channels" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/NotificationChannelSummary"}
            },
            "supported_channels" => %{
              "type" => "array",
              "items" => %{"type" => "string"}
            },
            "inactive_external_channels" => %{
              "type" => "array",
              "items" => %{"type" => "string"}
            }
          },
          "required" => [
            "unread_count",
            "recent",
            "preferences",
            "channels",
            "supported_channels",
            "inactive_external_channels"
          ]
        },
        "NotificationSummary" => %{
          "type" => "object",
          "properties" => %{
            "recipient_id" => %{"type" => "string"},
            "notification_id" => %{"type" => "string"},
            "status" => %{"type" => "string", "enum" => ["unread", "read", "archived"]},
            "title" => %{"type" => "string"},
            "body" => %{"type" => "string", "nullable" => true},
            "severity" => %{
              "type" => "string",
              "enum" => ["info", "success", "warning", "error"]
            },
            "scope" => %{"type" => "object"},
            "app_key" => %{"type" => "string", "nullable" => true},
            "actor" => %{"type" => "object"},
            "subject" => %{"type" => "object"},
            "action_url" => %{"type" => "string", "nullable" => true},
            "metadata" => %{"type" => "object"},
            "occurred_at" => %{"type" => "string", "format" => "date-time", "nullable" => true},
            "deliveries" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/NotificationDeliverySummary"}
            }
          },
          "required" => ["recipient_id", "notification_id", "status", "title", "severity"]
        },
        "NotificationDeliverySummary" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string"},
            "channel" => %{"type" => "string"},
            "endpoint_id" => %{"type" => "string", "nullable" => true},
            "status" => %{"type" => "string"},
            "provider" => %{"type" => "string", "nullable" => true},
            "provider_message_id" => %{"type" => "string", "nullable" => true},
            "attempt_count" => %{"type" => "integer"},
            "last_attempt_at" => %{
              "type" => "string",
              "format" => "date-time",
              "nullable" => true
            },
            "delivered_at" => %{"type" => "string", "format" => "date-time", "nullable" => true},
            "error_message" => %{"type" => "string", "nullable" => true},
            "metadata" => %{"type" => "object"}
          },
          "required" => ["id", "channel", "status", "attempt_count"]
        },
        "NotificationPreferenceSummary" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string"},
            "scope_type" => %{"type" => "string"},
            "scope_id" => %{"type" => "string", "nullable" => true},
            "app_key" => %{"type" => "string", "nullable" => true},
            "notification_key" => %{"type" => "string", "nullable" => true},
            "channel" => %{"type" => "string"},
            "enabled" => %{"type" => "boolean"},
            "cadence" => %{"type" => "string", "enum" => ["immediate", "digest", "disabled"]}
          },
          "required" => ["id", "scope_type", "channel", "enabled", "cadence"]
        },
        "NotificationChannelSummary" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string", "nullable" => true},
            "channel" => %{"type" => "string"},
            "address" => %{"type" => "string", "nullable" => true},
            "external_id" => %{"type" => "string", "nullable" => true},
            "status" => %{"type" => "string", "enum" => ["unverified", "verified", "disabled"]},
            "primary" => %{"type" => "boolean"},
            "verified_at" => %{"type" => "string", "format" => "date-time", "nullable" => true},
            "metadata" => %{"type" => "object"},
            "operational" => %{"type" => "boolean"}
          },
          "required" => ["channel", "status", "primary", "operational"]
        },
        "NotificationListResponse" => %{
          "type" => "object",
          "properties" => %{
            "notifications" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/NotificationSummary"}
            }
          },
          "required" => ["notifications"]
        },
        "NotificationUpdateResponse" => %{
          "type" => "object",
          "properties" => %{
            "notification" => %{"$ref" => "#/components/schemas/NotificationSummary"}
          },
          "required" => ["notification"]
        },
        "NotificationReadAllResponse" => %{
          "type" => "object",
          "properties" => %{
            "unread_count" => %{"type" => "integer"},
            "notifications" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/NotificationSummary"}
            }
          },
          "required" => ["unread_count", "notifications"]
        },
        "NotificationPreferencesResponse" => %{
          "type" => "object",
          "properties" => %{
            "preferences" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/NotificationPreferenceSummary"}
            }
          },
          "required" => ["preferences"]
        },
        "NotificationChannelsResponse" => %{
          "type" => "object",
          "properties" => %{
            "channels" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/NotificationChannelSummary"}
            }
          },
          "required" => ["channels"]
        },
        "NotificationChannelUpdateResponse" => %{
          "type" => "object",
          "properties" => %{
            "channel" => %{"$ref" => "#/components/schemas/NotificationChannelSummary"}
          },
          "required" => ["channel"]
        },
        "NotificationRecipientUpdateRequest" => %{
          "type" => "object",
          "properties" => %{
            "status" => %{"type" => "string", "enum" => ["read", "archived"]}
          },
          "required" => ["status"]
        },
        "NotificationPreferencesUpdateRequest" => %{
          "type" => "object",
          "properties" => %{
            "preferences" => %{
              "type" => "array",
              "items" => %{"$ref" => "#/components/schemas/NotificationPreferenceSummary"}
            }
          },
          "required" => ["preferences"]
        },
        "NotificationChannelUpdateRequest" => %{
          "type" => "object",
          "properties" => %{
            "address" => %{"type" => "string", "nullable" => true},
            "external_id" => %{"type" => "string", "nullable" => true},
            "status" => %{"type" => "string", "enum" => ["unverified", "verified", "disabled"]},
            "primary" => %{"type" => "boolean"},
            "metadata" => %{"type" => "object"}
          }
        }
      }
    }
  end
end
