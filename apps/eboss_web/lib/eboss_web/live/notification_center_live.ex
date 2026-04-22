defmodule EBossWeb.NotificationCenterLive do
  use EBossWeb, :live_view

  alias EBossNotify
  alias EBossWeb.AppScope
  alias EBossWeb.NotificationController

  @default_filters %{status: "active", scope: "all"}

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
     |> assign(:notification_filters, @default_filters)
     |> assign(:notification_bootstrap, notification_bootstrap(current_user))
     |> assign(:notifications, notification_list(current_user, @default_filters))}
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
  def handle_event("notifications:filter", params, socket) do
    filters = normalize_filters(params)
    socket = assign_notification_list(socket, filters)

    {:reply,
     %{
       ok: true,
       notifications: socket.assigns.notifications,
       filters: socket.assigns.notification_filters
     }, socket}
  end

  def handle_event("notifications:mark_read", %{"recipient_id" => recipient_id}, socket) do
    reply_with_notification_action(socket, fn current_user ->
      EBossNotify.mark_read(current_user, recipient_id)
    end)
  end

  def handle_event("notifications:archive", %{"recipient_id" => recipient_id}, socket) do
    reply_with_notification_action(socket, fn current_user ->
      EBossNotify.archive(current_user, recipient_id)
    end)
  end

  def handle_event("notifications:mark_all_read", _params, socket) do
    reply_with_notification_action(socket, &EBossNotify.mark_all_read/1)
  end

  def handle_event("notifications:set_preference", params, socket) do
    preference = %{
      scope_type: "system",
      scope_id: nil,
      app_key: nil,
      notification_key: nil,
      channel: Map.get(params, "channel"),
      enabled: Map.get(params, "enabled"),
      cadence: if(Map.get(params, "enabled"), do: "immediate", else: "disabled")
    }

    reply_with_notification_action(socket, fn current_user ->
      EBossNotify.put_preferences(current_user, [preference])
    end)
  end

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
        notifications={@notifications}
        activeStatus={@notification_filters.status}
        activeScope={@notification_filters.scope}
        dashboardPath={AppScope.default_dashboard_path(@current_user)}
        signOutPath={~p"/logout"}
        csrfToken={Plug.CSRFProtection.get_csrf_token()}
      />
    </Layouts.app>
    """
  end

  defp refresh_notifications(socket) do
    {:noreply, assign_notification_payloads(socket)}
  end

  defp reply_with_notification_action(socket, action) do
    case action.(socket.assigns.current_user) do
      {:ok, _result} ->
        socket = assign_notification_payloads(socket)

        {:reply,
         %{
           ok: true,
           bootstrap: socket.assigns.notification_bootstrap,
           notifications: socket.assigns.notifications,
           filters: socket.assigns.notification_filters
         }, socket}

      {:error, reason} ->
        {:reply, %{ok: false, error: notification_error(reason)}, socket}
    end
  end

  defp assign_notification_payloads(socket) do
    socket
    |> assign(:notification_bootstrap, notification_bootstrap(socket.assigns.current_user))
    |> assign_notification_list(socket.assigns.notification_filters)
  end

  defp assign_notification_list(socket, filters) do
    filters = normalize_filters(filters)

    socket
    |> assign(:notification_filters, filters)
    |> assign(:notifications, notification_list(socket.assigns.current_user, filters))
  end

  defp notification_bootstrap(current_user) do
    case EBossNotify.bootstrap(current_user) do
      {:ok, bootstrap} -> NotificationController.bootstrap_payload(bootstrap)
      {:error, _reason} -> empty_bootstrap()
    end
  end

  defp notification_list(current_user, filters) do
    filters =
      %{
        status: filters.status,
        scope_type: if(filters.scope == "all", do: nil, else: filters.scope)
      }

    case EBossNotify.list_notifications(current_user, filters) do
      {:ok, recipients} -> Enum.map(recipients, &NotificationController.recipient_payload/1)
      {:error, _reason} -> []
    end
  end

  defp normalize_filters(filters) do
    status = Map.get(filters, :status) || Map.get(filters, "status") || @default_filters.status
    scope = Map.get(filters, :scope) || Map.get(filters, "scope") || @default_filters.scope

    %{
      status: normalize_filter_value(status, ~w(active unread read archived all), "active"),
      scope:
        normalize_filter_value(
          scope,
          ~w(all system user organization workspace app),
          "all"
        )
    }
  end

  defp normalize_filter_value(value, allowed, fallback) when is_atom(value) do
    normalize_filter_value(to_string(value), allowed, fallback)
  end

  defp normalize_filter_value(value, allowed, fallback) when is_binary(value) do
    if value in allowed, do: value, else: fallback
  end

  defp normalize_filter_value(_value, _allowed, fallback), do: fallback

  defp notification_error(reason) when is_binary(reason), do: reason
  defp notification_error(reason), do: inspect(reason)

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
