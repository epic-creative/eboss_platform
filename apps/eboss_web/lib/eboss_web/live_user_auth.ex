defmodule EBossWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  alias Phoenix.LiveView

  use EBossWeb, :verified_routes

  def on_mount(:live_user_optional, _params, _session, socket) do
    {:cont, normalize_socket(socket)}
  end

  def on_mount(:live_user_required, _params, _session, socket) do
    socket = normalize_socket(socket)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    socket = normalize_socket(socket)

    if socket.assigns.current_user do
      {:halt, LiveView.redirect(socket, to: ~p"/dashboard")}
    else
      {:cont, socket}
    end
  end

  defp normalize_socket(socket) do
    socket
    |> assign_new(:current_user, fn -> nil end)
    |> assign_new(:current_scope, fn -> nil end)
  end
end
