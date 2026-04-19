defmodule EBossWeb.HomeLive do
  use EBossWeb, :live_view

  alias EBossWeb.AppScope

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "EBoss")

    if socket.assigns.current_user do
      {:ok, redirect(socket, to: AppScope.default_dashboard_path(socket.assigns.current_user))}
    else
      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={assigns[:current_user]}
      shell_mode="public"
      current_path="/"
    >
      <.ShellOperatorLanding />
    </Layouts.app>
    """
  end
end
