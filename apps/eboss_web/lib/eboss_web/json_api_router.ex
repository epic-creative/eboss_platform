defmodule EBossWeb.JsonApiRouter do
  use AshJsonApi.Router,
    domains: [EBoss.Workspaces],
    prefix: "/api/v1",
    open_api_title: "EBoss API",
    open_api_version: "1.0.0",
    phoenix_endpoint: EBossWeb.Endpoint
end
