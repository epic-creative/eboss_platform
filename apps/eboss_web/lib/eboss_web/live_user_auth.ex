defmodule EBossWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  alias Phoenix.LiveView
  alias EBossWeb.AppScope

  use EBossWeb, :verified_routes

  def on_mount(:live_user_optional, _params, _session, socket) do
    {:cont, normalize_socket(socket, current_scope: nil)}
  end

  def on_mount(:live_user_required, _params, _session, socket) do
    socket = normalize_socket(socket, current_scope: :app_scope)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    socket = normalize_socket(socket, current_scope: nil)

    if socket.assigns.current_user do
      {:halt,
       LiveView.redirect(socket, to: AppScope.default_dashboard_path(socket.assigns.current_user))}
    else
      {:cont, socket}
    end
  end

  defp normalize_socket(socket, opts) do
    socket = assign_new(socket, :current_user, fn -> nil end)

    case Keyword.get(opts, :current_scope, nil) do
      :app_scope ->
        assign_new(socket, :current_scope, fn -> AppScope.empty(socket.assigns.current_user) end)

      scope ->
        assign_new(socket, :current_scope, fn -> scope end)
    end
  end
end
