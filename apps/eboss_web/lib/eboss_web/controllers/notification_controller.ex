defmodule EBossWeb.NotificationController do
  use EBossWeb, :controller

  alias Ash.PlugHelpers
  alias EBossNotify

  def bootstrap(conn, _params) do
    with {:ok, current_user} <- current_user(conn),
         {:ok, bootstrap} <- EBossNotify.bootstrap(current_user) do
      json(conn, bootstrap_payload(bootstrap))
    else
      {:error, :unauthorized} ->
        error_json(conn, :unauthorized, "authentication_required", "Authentication is required")

      {:error, reason} ->
        error_json(conn, :bad_request, "invalid_notifications_request", format_error(reason))
    end
  end

  def index(conn, params) do
    with {:ok, current_user} <- current_user(conn),
         {:ok, recipients} <- EBossNotify.list_notifications(current_user, params) do
      json(conn, %{notifications: Enum.map(recipients, &recipient_payload/1)})
    else
      {:error, :unauthorized} ->
        error_json(conn, :unauthorized, "authentication_required", "Authentication is required")

      {:error, reason} ->
        error_json(conn, :bad_request, "invalid_notifications_request", format_error(reason))
    end
  end

  def update(conn, %{"recipient_id" => recipient_id}) do
    with {:ok, current_user} <- current_user(conn),
         {:ok, action} <- parse_recipient_action(conn.body_params),
         {:ok, recipient} <- apply_recipient_action(current_user, recipient_id, action) do
      json(conn, %{notification: recipient_payload(recipient)})
    else
      {:error, :unauthorized} ->
        error_json(conn, :unauthorized, "authentication_required", "Authentication is required")

      {:error, :not_found} ->
        error_json(conn, :not_found, "notification_not_found", "Notification not found")

      {:error, :invalid_action} ->
        error_json(
          conn,
          :bad_request,
          "invalid_notification_action",
          "Notification action is not supported"
        )

      {:error, reason} ->
        error_json(conn, :bad_request, "invalid_notification_update", format_error(reason))
    end
  end

  def read_all(conn, _params) do
    with {:ok, current_user} <- current_user(conn),
         {:ok, recipients} <- EBossNotify.mark_all_read(current_user),
         {:ok, unread_count} <- EBossNotify.unread_count(current_user) do
      json(conn, %{
        unread_count: unread_count,
        notifications: Enum.map(recipients, &recipient_payload/1)
      })
    else
      {:error, :unauthorized} ->
        error_json(conn, :unauthorized, "authentication_required", "Authentication is required")

      {:error, reason} ->
        error_json(conn, :bad_request, "invalid_notifications_request", format_error(reason))
    end
  end

  def preferences(conn, _params) do
    with {:ok, current_user} <- current_user(conn),
         {:ok, preferences} <- EBossNotify.list_preferences(current_user) do
      json(conn, %{preferences: Enum.map(preferences, &preference_payload/1)})
    else
      {:error, :unauthorized} ->
        error_json(conn, :unauthorized, "authentication_required", "Authentication is required")

      {:error, reason} ->
        error_json(conn, :bad_request, "invalid_notifications_request", format_error(reason))
    end
  end

  def update_preferences(conn, _params) do
    entries =
      Map.get(conn.body_params, "preferences") || Map.get(conn.body_params, :preferences) || []

    with {:ok, current_user} <- current_user(conn),
         true <- is_list(entries),
         {:ok, preferences} <- EBossNotify.put_preferences(current_user, entries) do
      json(conn, %{preferences: Enum.map(preferences, &preference_payload/1)})
    else
      {:error, :unauthorized} ->
        error_json(conn, :unauthorized, "authentication_required", "Authentication is required")

      false ->
        error_json(
          conn,
          :bad_request,
          "invalid_notification_preferences",
          "Notification preferences payload is invalid"
        )

      {:error, reason} ->
        error_json(conn, :bad_request, "invalid_notification_preferences", format_error(reason))
    end
  end

  def channels(conn, _params) do
    with {:ok, current_user} <- current_user(conn),
         {:ok, endpoints} <- EBossNotify.list_channel_endpoints(current_user) do
      json(conn, channel_payload(current_user, endpoints))
    else
      {:error, :unauthorized} ->
        error_json(conn, :unauthorized, "authentication_required", "Authentication is required")

      {:error, reason} ->
        error_json(conn, :bad_request, "invalid_notification_channels", format_error(reason))
    end
  end

  def update_channel(conn, %{"endpoint_id" => endpoint_id}) do
    with {:ok, current_user} <- current_user(conn),
         {:ok, endpoint} <-
           EBossNotify.update_channel_endpoint_for_user(
             current_user,
             endpoint_id,
             conn.body_params
           ) do
      json(conn, %{channel: endpoint_payload(endpoint)})
    else
      {:error, :unauthorized} ->
        error_json(conn, :unauthorized, "authentication_required", "Authentication is required")

      {:error, :not_found} ->
        error_json(
          conn,
          :not_found,
          "notification_channel_not_found",
          "Channel endpoint not found"
        )

      {:error, reason} ->
        error_json(conn, :bad_request, "invalid_notification_channel", format_error(reason))
    end
  end

  defp apply_recipient_action(current_user, recipient_id, :read),
    do: EBossNotify.mark_read(current_user, recipient_id)

  defp apply_recipient_action(current_user, recipient_id, :archived),
    do: EBossNotify.archive(current_user, recipient_id)

  defp parse_recipient_action(%{"status" => "read"}), do: {:ok, :read}
  defp parse_recipient_action(%{"status" => "archived"}), do: {:ok, :archived}
  defp parse_recipient_action(%{status: :read}), do: {:ok, :read}
  defp parse_recipient_action(%{status: :archived}), do: {:ok, :archived}
  defp parse_recipient_action(_params), do: {:error, :invalid_action}

  defp current_user(conn) do
    case conn.assigns[:current_user] || PlugHelpers.get_actor(conn) do
      nil -> {:error, :unauthorized}
      current_user -> {:ok, current_user}
    end
  end

  def bootstrap_payload(bootstrap) do
    %{
      unread_count: bootstrap.unread_count,
      recent: Enum.map(bootstrap.recent, &recipient_payload/1),
      preferences: Enum.map(bootstrap.preferences, &preference_payload/1),
      channels:
        channel_payload(
          Map.get(bootstrap, :current_user, %{id: bootstrap.user_id}),
          bootstrap.channels
        ).channels,
      supported_channels: Enum.map(bootstrap.supported_channels, &to_string/1),
      inactive_external_channels: Enum.map(bootstrap.inactive_external_channels, &to_string/1)
    }
  end

  def recipient_payload(recipient) do
    notification = recipient.notification

    %{
      recipient_id: recipient.id,
      notification_id: recipient.notification_id,
      status: to_string(recipient.status),
      read_at: iso8601(recipient.read_at),
      archived_at: iso8601(recipient.archived_at),
      last_seen_at: iso8601(recipient.last_seen_at),
      title: notification.title,
      body: notification.body,
      severity: to_string(notification.severity),
      scope: %{
        type: to_string(notification.scope_type),
        id: notification.scope_id,
        workspace_id: notification.workspace_id,
        organization_id: notification.organization_id
      },
      app_key: notification.app_key,
      actor: %{
        type: to_string(notification.actor_type),
        id: notification.actor_id
      },
      subject: %{
        type: notification.subject_type,
        id: notification.subject_id,
        label: notification.subject_label
      },
      action_url: notification.action_url,
      metadata: notification.metadata || %{},
      occurred_at: iso8601(notification.occurred_at),
      deliveries: Enum.map(Map.get(recipient, :deliveries, []), &delivery_payload/1)
    }
  end

  def preference_payload(preference) do
    %{
      id: preference.id,
      scope_type: to_string(preference.scope_type),
      scope_id: preference.scope_id,
      app_key: preference.app_key,
      notification_key: preference.notification_key,
      channel: to_string(preference.channel),
      enabled: preference.enabled,
      cadence: to_string(preference.cadence)
    }
  end

  def channel_payload(current_user, endpoints) do
    endpoint_payloads = Enum.map(endpoints, &endpoint_payload/1)

    synthesized =
      EBossNotify.supported_channels()
      |> Enum.map(fn channel ->
        existing = Enum.find(endpoint_payloads, &(&1.channel == to_string(channel)))

        existing ||
          %{
            id: nil,
            channel: to_string(channel),
            address: default_channel_address(current_user, channel),
            external_id: nil,
            status: default_channel_status(channel),
            primary: channel == :in_app or channel == :email,
            verified_at: nil,
            metadata: %{},
            operational: channel == :in_app
          }
      end)

    %{channels: synthesized}
  end

  defp endpoint_payload(endpoint) do
    %{
      id: endpoint.id,
      channel: to_string(endpoint.channel),
      address: endpoint.address,
      external_id: endpoint.external_id,
      status: to_string(endpoint.status),
      primary: endpoint.primary,
      verified_at: iso8601(endpoint.verified_at),
      metadata: endpoint.metadata || %{},
      operational: endpoint.channel == :in_app
    }
  end

  defp delivery_payload(delivery) do
    %{
      id: delivery.id,
      channel: to_string(delivery.channel),
      endpoint_id: delivery.endpoint_id,
      status: to_string(delivery.status),
      provider: delivery.provider,
      provider_message_id: delivery.provider_message_id,
      attempt_count: delivery.attempt_count,
      last_attempt_at: iso8601(delivery.last_attempt_at),
      delivered_at: iso8601(delivery.delivered_at),
      error_message: delivery.error_message,
      metadata: delivery.metadata || %{}
    }
  end

  defp default_channel_address(%{email: email}, :email), do: to_string(email)
  defp default_channel_address(_current_user, _channel), do: nil

  defp default_channel_status(:in_app), do: "verified"
  defp default_channel_status(:email), do: "verified"
  defp default_channel_status(_channel), do: "unverified"

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp iso8601(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)

  defp error_json(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(%{error: %{code: code, message: message}})
  end

  defp format_error(error) when is_binary(error), do: error
  defp format_error(%Ash.Error.Forbidden{}), do: "Notification access is forbidden"
  defp format_error(%Ash.Error.Invalid{} = error), do: Exception.message(error)
  defp format_error(%Ash.Error.Unknown{} = error), do: Exception.message(error)
  defp format_error(error), do: inspect(error)
end
