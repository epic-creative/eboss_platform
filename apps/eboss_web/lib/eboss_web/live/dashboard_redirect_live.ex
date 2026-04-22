defmodule EBossWeb.DashboardRedirectLive do
  use EBossWeb, :live_view

  alias EBossWeb.AppScope
  alias EBossWeb.DashboardLive

  @impl true
  def mount(_params, _session, socket) do
    case AppScope.resolve_default(socket.assigns.current_user) do
      {:redirect, dashboard_path} ->
        {:ok, redirect(socket, to: dashboard_path)}

      {:ok, scope} ->
        {:ok,
         socket
         |> assign(:current_scope, scope)
         |> assign(:page_title, "Dashboard")
         |> stream(:chat_sessions, [])
         |> stream(:chat_messages, [])}
    end
  end

  @impl true
  def render(assigns), do: DashboardLive.render(assigns)
end
