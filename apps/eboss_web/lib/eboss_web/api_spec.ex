defmodule EBossWeb.ApiSpec do
  @moduledoc false

  def spec do
    EBossWeb.JsonApiRouter.spec()
    |> normalize()
    |> merge_paths(bootstrap_paths())
    |> merge_components(bootstrap_components())
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
      "/api/v1/users/{owner_handle}/workspaces/{slug}/bootstrap" => bootstrap_path_item(),
      "/api/v1/orgs/{owner_handle}/workspaces/{slug}/bootstrap" => bootstrap_path_item()
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
            "name" => "owner_handle",
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
            "owner_handle" => %{"type" => "string"},
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
            "owner_handle",
            "owner_display_name",
            "dashboard_path"
          ]
        },
        "OwnerSummary" => %{
          "type" => "object",
          "properties" => %{
            "type" => %{"type" => "string"},
            "id" => %{"type" => "string"},
            "handle" => %{"type" => "string"},
            "display_name" => %{"type" => "string"}
          },
          "required" => ["type", "id", "handle", "display_name"]
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
        "WorkspaceBootstrap" => %{
          "type" => "object",
          "properties" => %{
            "current_user" => %{"$ref" => "#/components/schemas/UserSummary"},
            "workspace" => %{"$ref" => "#/components/schemas/WorkspaceSummary"},
            "owner" => %{"$ref" => "#/components/schemas/OwnerSummary"},
            "capabilities" => %{"$ref" => "#/components/schemas/WorkspaceCapabilities"},
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
            "accessible_workspaces"
          ]
        }
      }
    }
  end
end
