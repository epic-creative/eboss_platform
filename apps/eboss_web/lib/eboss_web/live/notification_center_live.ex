defmodule EBossWeb.NotificationCenterLive do
  use EBossWeb, :live_view

  alias EBossNotify
  alias EBossWeb.AppScope
  alias EBossWeb.NotificationController

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if connected?(socket) do
      :ok = EBossNotify.subscribe(current_user)
    end

    {:ok,
     socket
     |> assign(:current_scope, AppScope.empty(current_user))
     |> assign(:current_path, ~p"/notifications")
     |> assign(:page_title, "Notifications")
     |> assign(:current_user_props, user_props(current_user))
     |> assign(:notification_bootstrap, notification_bootstrap(current_user))}
  end

  @impl true
  def handle_info({:notification_created, _recipient}, socket), do: refresh_notifications(socket)
  def handle_info({:notification_updated, _recipient}, socket), do: refresh_notifications(socket)
  def handle_info({:notifications_read_all, _user_id}, socket), do: refresh_notifications(socket)

  def handle_info({:notification_preferences_updated, _user_id}, socket),
    do: refresh_notifications(socket)

  def handle_info({:notification_channels_updated, _user_id}, socket),
    do: refresh_notifications(socket)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_user={@current_user}
      current_path={@current_path}
    >
      <.NotificationCenterApp
        currentUser={@current_user_props}
        notificationBootstrap={@notification_bootstrap}
        dashboardPath={AppScope.default_dashboard_path(@current_user)}
        signOutPath={~p"/logout"}
        csrfToken={Plug.CSRFProtection.get_csrf_token()}
      />
    </Layouts.app>
    """
  end

  defp refresh_notifications(socket) do
    {:noreply,
     assign(
       socket,
       :notification_bootstrap,
       notification_bootstrap(socket.assigns.current_user)
     )}
  end

  defp notification_bootstrap(current_user) do
    case EBossNotify.bootstrap(current_user) do
      {:ok, bootstrap} -> NotificationController.bootstrap_payload(bootstrap)
      {:error, _reason} -> empty_bootstrap()
    end
  end

  defp empty_bootstrap do
    %{
      unread_count: 0,
      recent: [],
      preferences: [],
      channels: [],
      supported_channels: Enum.map(EBossNotify.supported_channels(), &to_string/1),
      inactive_external_channels: Enum.map(EBossNotify.inactive_external_channels(), &to_string/1)
    }
  end

  defp user_props(user) do
    %{
      username: to_string(Map.get(user, :username)),
      email: to_string(Map.get(user, :email))
    }
  end
end
