defmodule EBossNotify do
  @moduledoc """
  System-wide, multi-channel notification domain.
  """

  use Ash.Domain, otp_app: :eboss_notify

  import Ash.Expr
  require Ash.Query

  alias EBoss.Accounts.User
  alias EBoss.Organizations.Membership, as: OrganizationMembership
  alias EBoss.Workspaces.Workspace
  alias EBossNotify.Notification
  alias EBossNotify.NotificationChannelEndpoint
  alias EBossNotify.NotificationDelivery
  alias EBossNotify.NotificationPreference
  alias EBossNotify.NotificationRecipient

  @channels [:in_app, :email, :sms, :telegram, :webhook, :push]
  @inactive_external_channels [:email, :sms, :telegram, :webhook, :push]
  @notification_attr_keys [
    :scope_type,
    :scope_id,
    :workspace_id,
    :organization_id,
    :app_key,
    :notification_key,
    :title,
    :body,
    :severity,
    :actor_type,
    :actor_id,
    :subject_type,
    :subject_id,
    :subject_label,
    :action_url,
    :metadata,
    :idempotency_key,
    :occurred_at
  ]
  @preference_attr_keys [
    :scope_type,
    :scope_id,
    :app_key,
    :notification_key,
    :channel,
    :enabled,
    :cadence
  ]
  @channel_endpoint_create_keys [
    :channel,
    :address,
    :external_id,
    :status,
    :primary,
    :verified_at,
    :metadata
  ]
  @channel_endpoint_user_update_keys [
    :address,
    :external_id,
    :status,
    :primary,
    :metadata
  ]
  @recipient_statuses [:unread, :read, :archived]
  @scope_types [:system, :user, :organization, :workspace, :app]
  @known_atoms [
    :system,
    :user,
    :organization,
    :workspace,
    :app,
    :info,
    :success,
    :warning,
    :error,
    :api_key,
    :agent,
    :bot,
    :in_app,
    :email,
    :sms,
    :telegram,
    :webhook,
    :push,
    :unverified,
    :verified,
    :disabled,
    :immediate,
    :digest
  ]
  @known_atom_lookup Map.new(@known_atoms, &{to_string(&1), &1})

  resources do
    resource Notification do
      define(:create_notification, action: :create)
      define(:get_notification, action: :read, get_by: [:id])
    end

    resource NotificationRecipient do
      define(:create_notification_recipient, action: :create)
      define(:mark_notification_read, action: :mark_read)
      define(:archive_notification, action: :archive)
      define(:get_notification_recipient, action: :read, get_by: [:id])
    end

    resource NotificationChannelEndpoint do
      define(:create_channel_endpoint, action: :create)
      define(:update_channel_endpoint, action: :update)
      define(:disable_channel_endpoint, action: :disable)
      define(:verify_channel_endpoint, action: :verify)
      define(:get_channel_endpoint, action: :read, get_by: [:id])
    end

    resource NotificationPreference do
      define(:create_notification_preference, action: :create)
      define(:update_notification_preference, action: :update)
      define(:get_notification_preference, action: :read, get_by: [:id])
    end

    resource NotificationDelivery do
      define(:create_notification_delivery, action: :create)
      define(:update_notification_delivery_status, action: :update_status)
    end
  end

  @type audience ::
          :system
          | {:system}
          | {:user, String.t() | map()}
          | {:users, [String.t() | map()]}
          | {:organization, String.t()}
          | {:workspace, String.t()}
          | {:app, String.t(), String.t()}

  @spec supported_channels() :: [atom()]
  def supported_channels, do: @channels

  @spec inactive_external_channels() :: [atom()]
  def inactive_external_channels, do: @inactive_external_channels

  @spec notify(map(), audience(), keyword()) :: {:ok, map()} | {:error, term()}
  def notify(attrs, audience, opts \\ []) when is_map(attrs) do
    attrs = normalize_notification_attrs(attrs, audience)

    case EBoss.Repo.transaction(fn ->
           with {:ok, recipient_user_ids} <- resolve_recipient_user_ids(audience, attrs),
                {:ok, notification, _existing?} <- get_or_create_notification(attrs),
                {:ok, recipients, deliveries, created_recipients} <-
                  create_recipient_state(notification, recipient_user_ids, opts) do
             %{
               notification: notification,
               recipients: recipients,
               deliveries: deliveries,
               created_recipients: created_recipients
             }
           else
             {:error, reason} -> EBoss.Repo.rollback(reason)
             reason -> EBoss.Repo.rollback(reason)
           end
         end) do
      {:ok, result} ->
        Enum.each(
          result.created_recipients,
          &broadcast_user(&1.user_id, {:notification_created, &1})
        )

        {:ok,
         %{
           notification: result.notification,
           recipients: result.recipients,
           deliveries: result.deliveries
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def notify!(attrs, audience, opts \\ []) do
    case notify(attrs, audience, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise inspect(reason)
    end
  end

  def notify_account_security(user, notification_key, attrs \\ []) do
    user_id = user_id!(user)

    attrs
    |> Map.new()
    |> Map.merge(%{
      scope_type: :user,
      scope_id: user_id,
      notification_key: to_string(notification_key),
      severity: :info
    })
    |> notify({:user, user_id})
  end

  def notify_workspace(workspace_id, notification_key, attrs \\ []) do
    attrs
    |> Map.new()
    |> Map.merge(%{
      scope_type: :workspace,
      scope_id: workspace_id,
      workspace_id: workspace_id,
      notification_key: to_string(notification_key)
    })
    |> notify({:workspace, workspace_id})
  end

  def notify_organization(organization_id, notification_key, attrs \\ []) do
    attrs
    |> Map.new()
    |> Map.merge(%{
      scope_type: :organization,
      scope_id: organization_id,
      organization_id: organization_id,
      notification_key: to_string(notification_key)
    })
    |> notify({:organization, organization_id})
  end

  def notify_app(workspace_id, app_key, notification_key, attrs \\ []) do
    attrs
    |> Map.new()
    |> Map.merge(%{
      scope_type: :app,
      scope_id: workspace_id,
      workspace_id: workspace_id,
      app_key: app_key,
      notification_key: to_string(notification_key)
    })
    |> notify({:app, workspace_id, app_key})
  end

  def notify_folio(workspace_id, notification_key, attrs \\ []),
    do: notify_app(workspace_id, "folio", notification_key, attrs)

  def notify_chat(workspace_id, notification_key, attrs \\ []),
    do: notify_app(workspace_id, "chat", notification_key, attrs)

  def subscribe(%{id: user_id}), do: subscribe(user_id)

  def subscribe(user_id) when is_binary(user_id) do
    Phoenix.PubSub.subscribe(EBoss.PubSub, topic(user_id))
  end

  def bootstrap(user, opts \\ [])

  def bootstrap(%{id: user_id} = user, opts) do
    limit = Keyword.get(opts, :limit, 5)

    with {:ok, unread_count} <- unread_count(user),
         {:ok, recent} <- list_notifications(user, %{status: "active", limit: limit}),
         {:ok, preferences} <- list_preferences(user),
         {:ok, channels} <- list_channel_endpoints(user) do
      {:ok,
       %{
         unread_count: unread_count,
         recent: recent,
         preferences: preferences,
         channels: channels,
         supported_channels: @channels,
         inactive_external_channels: @inactive_external_channels,
         user_id: user_id,
         current_user: user
       }}
    end
  end

  def bootstrap(_user, _opts), do: {:error, :unauthorized}

  def list_notifications(%{id: user_id} = user, filters \\ %{}, opts \\ []) do
    limit =
      normalize_limit(
        Map.get(filters, :limit) || Map.get(filters, "limit") || Keyword.get(opts, :limit)
      )

    status_filter = Map.get(filters, :status) || Map.get(filters, "status")
    scope_type_filter = Map.get(filters, :scope_type) || Map.get(filters, "scope_type")
    workspace_id_filter = Map.get(filters, :workspace_id) || Map.get(filters, "workspace_id")
    app_key_filter = Map.get(filters, :app_key) || Map.get(filters, "app_key")

    query =
      NotificationRecipient
      |> Ash.Query.for_read(:read)
      |> Ash.Query.filter(expr(user_id == ^user_id))
      |> filter_recipient_status(status_filter)
      |> filter_recipient_scope_type(scope_type_filter)
      |> filter_recipient_workspace(workspace_id_filter)
      |> filter_recipient_app(app_key_filter)
      |> Ash.Query.load([:notification, :deliveries])
      |> Ash.Query.sort(inserted_at: :desc)
      |> maybe_limit(limit)

    Ash.read(query, actor: user, domain: __MODULE__)
  end

  def unread_count(%{id: user_id} = user) do
    NotificationRecipient
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(expr(user_id == ^user_id and status == :unread))
    |> Ash.count(actor: user, domain: __MODULE__)
  end

  def mark_read(%{id: user_id} = user, recipient_id) when is_binary(recipient_id) do
    with {:ok, recipient} <- get_recipient_for_user(user, recipient_id),
         {:ok, recipient} <-
           recipient
           |> Ash.Changeset.for_update(:mark_read, %{})
           |> Ash.update(actor: user, domain: __MODULE__) do
      broadcast_user(user_id, {:notification_updated, recipient})
      {:ok, recipient}
    end
  end

  def archive(%{id: user_id} = user, recipient_id) when is_binary(recipient_id) do
    with {:ok, recipient} <- get_recipient_for_user(user, recipient_id),
         {:ok, recipient} <-
           recipient
           |> Ash.Changeset.for_update(:archive, %{})
           |> Ash.update(actor: user, domain: __MODULE__) do
      broadcast_user(user_id, {:notification_updated, recipient})
      {:ok, recipient}
    end
  end

  def mark_all_read(%{id: user_id} = user) do
    with {:ok, recipients} <- list_notifications(user, %{status: "unread"}) do
      updated =
        Enum.map(recipients, fn recipient ->
          {:ok, recipient} =
            recipient
            |> Ash.Changeset.for_update(:mark_read, %{})
            |> Ash.update(actor: user, domain: __MODULE__)

          recipient
        end)

      broadcast_user(user_id, {:notifications_read_all, user_id})
      {:ok, updated}
    end
  end

  def list_preferences(%{id: user_id} = user) do
    NotificationPreference
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(expr(user_id == ^user_id))
    |> Ash.Query.sort(channel: :asc, notification_key: :asc)
    |> Ash.read(actor: user, domain: __MODULE__)
  end

  def put_preferences(%{id: user_id} = user, entries) when is_list(entries) do
    with {:ok, existing} <- list_preferences(user) do
      preferences =
        Enum.map(entries, fn entry ->
          attrs = normalize_preference_attrs(entry, user_id)

          case Enum.find(existing, &same_preference?(&1, attrs)) do
            nil ->
              create_notification_preference!(attrs, authorize?: false)

            preference ->
              update_notification_preference!(
                preference,
                Map.take(attrs, [:enabled, :cadence]),
                actor: user
              )
          end
        end)

      broadcast_user(user_id, {:notification_preferences_updated, user_id})
      {:ok, preferences}
    end
  end

  def list_channel_endpoints(%{id: user_id} = user) do
    NotificationChannelEndpoint
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(expr(user_id == ^user_id))
    |> Ash.Query.sort(channel: :asc, inserted_at: :asc)
    |> Ash.read(actor: user, domain: __MODULE__)
  end

  def put_channel_endpoint(%{id: user_id}, attrs) when is_map(attrs) do
    attrs =
      attrs
      |> atomize_keys(@channel_endpoint_create_keys)
      |> Map.put(:user_id, user_id)
      |> Map.update(:channel, :in_app, &normalize_atom/1)
      |> Map.update(:status, :unverified, &normalize_atom/1)

    endpoint = create_channel_endpoint!(attrs, authorize?: false)
    broadcast_user(user_id, {:notification_channels_updated, user_id})
    {:ok, endpoint}
  end

  def update_channel_endpoint_for_user(%{id: user_id} = user, endpoint_id, attrs)
      when is_binary(endpoint_id) and is_map(attrs) do
    attrs =
      attrs
      |> atomize_keys(@channel_endpoint_user_update_keys)
      |> normalize_channel_update_attrs()

    with {:ok, endpoint} <- get_channel_endpoint_for_user(user, endpoint_id),
         {:ok, endpoint} <- apply_channel_endpoint_user_update(endpoint, attrs, user) do
      broadcast_user(user_id, {:notification_channels_updated, user_id})
      {:ok, endpoint}
    end
  end

  def create_seed_notification_for_user(user, attrs \\ %{}) do
    notify(
      Map.merge(
        %{
          scope_type: :system,
          notification_key: "system.welcome",
          title: "Welcome to EBoss",
          body: "Notifications are now active for this account.",
          severity: :info,
          idempotency_key: "system.welcome:#{user_id!(user)}"
        },
        Map.new(attrs)
      ),
      {:user, user}
    )
  end

  defp get_or_create_notification(%{idempotency_key: key} = attrs)
       when is_binary(key) and key != "" do
    case notification_by_idempotency_key(key) do
      {:ok, nil} ->
        create_new_notification(attrs)

      {:ok, notification} ->
        {:ok, notification, true}

      error ->
        error
    end
  end

  defp get_or_create_notification(attrs), do: create_new_notification(attrs)

  defp create_new_notification(attrs) do
    case create_notification(attrs, authorize?: false, return_notifications?: true)
         |> unwrap_record() do
      {:ok, notification} -> {:ok, notification, false}
      error -> error
    end
  end

  defp notification_by_idempotency_key(key) do
    Notification
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(expr(idempotency_key == ^key))
    |> Ash.read_one(authorize?: false, domain: __MODULE__)
  end

  defp create_recipient_state(notification, recipient_user_ids, opts) do
    excluded_user_ids =
      opts
      |> Keyword.get(:exclude_user_ids, [])
      |> List.wrap()
      |> Enum.map(&user_id!/1)

    result =
      recipient_user_ids
      |> Enum.uniq()
      |> Enum.reject(&(&1 in excluded_user_ids))
      |> Enum.reduce_while({:ok, {[], [], []}}, fn user_id,
                                                   {:ok,
                                                    {recipients, deliveries, created_recipients}} ->
        enabled_channels = enabled_channels_for_user(user_id, notification)

        if enabled_channels == [] do
          {:cont, {:ok, {recipients, deliveries, created_recipients}}}
        else
          in_app_enabled? = :in_app in enabled_channels

          with {:ok, recipient, created?} <-
                 get_or_create_recipient(notification, user_id, in_app_enabled?),
               {:ok, recipient_deliveries} <-
                 ensure_deliveries(notification, recipient, user_id, enabled_channels),
               {:ok, recipient} <- load_recipient(recipient) do
            created_recipients =
              if created?, do: [recipient | created_recipients], else: created_recipients

            {:cont,
             {:ok,
              {[recipient | recipients], recipient_deliveries ++ deliveries, created_recipients}}}
          else
            {:error, reason} -> {:halt, {:error, reason}}
            reason -> {:halt, {:error, reason}}
          end
        end
      end)

    case result do
      {:ok, {recipients, deliveries, created_recipients}} ->
        {:ok, Enum.reverse(recipients), Enum.reverse(deliveries),
         Enum.reverse(created_recipients)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_or_create_recipient(notification, user_id, in_app_enabled?) do
    query =
      NotificationRecipient
      |> Ash.Query.for_read(:read)
      |> Ash.Query.filter(expr(notification_id == ^notification.id and user_id == ^user_id))

    case Ash.read_one(query, authorize?: false, domain: __MODULE__) do
      {:ok, nil} ->
        attrs =
          %{
            notification_id: notification.id,
            user_id: user_id,
            status: if(in_app_enabled?, do: :unread, else: :read)
          }
          |> maybe_put_read_at(in_app_enabled?)

        case create_notification_recipient(attrs, authorize?: false, return_notifications?: true)
             |> unwrap_record() do
          {:ok, recipient} -> {:ok, recipient, true}
          error -> error
        end

      {:ok, recipient} ->
        {:ok, recipient, false}

      error ->
        error
    end
  end

  defp maybe_put_read_at(attrs, true), do: attrs
  defp maybe_put_read_at(attrs, false), do: Map.put(attrs, :read_at, DateTime.utc_now())

  defp ensure_deliveries(notification, recipient, user_id, enabled_channels) do
    with {:ok, existing_deliveries} <- deliveries_for_recipient(recipient.id),
         {:ok, _created_deliveries} <-
           create_missing_deliveries(
             notification,
             recipient,
             user_id,
             enabled_channels,
             existing_deliveries
           ),
         {:ok, deliveries} <- deliveries_for_recipient(recipient.id) do
      {:ok, sort_deliveries(deliveries)}
    end
  end

  defp create_missing_deliveries(
         notification,
         recipient,
         user_id,
         enabled_channels,
         existing_deliveries
       ) do
    existing_channels = MapSet.new(existing_deliveries, & &1.channel)

    enabled_channels
    |> Enum.reject(&MapSet.member?(existing_channels, &1))
    |> Enum.reduce_while({:ok, []}, fn channel, {:ok, created} ->
      case create_delivery(notification, recipient, user_id, channel) do
        {:ok, delivery} -> {:cont, {:ok, [delivery | created]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp deliveries_for_recipient(recipient_id) do
    NotificationDelivery
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(expr(recipient_id == ^recipient_id))
    |> Ash.read(authorize?: false, domain: __MODULE__)
  end

  defp create_delivery(notification, recipient, user_id, :in_app) do
    create_notification_delivery(
      %{
        notification_id: notification.id,
        recipient_id: recipient.id,
        user_id: user_id,
        channel: :in_app,
        status: :delivered,
        delivered_at: DateTime.utc_now(),
        metadata: %{runtime: "in_app"}
      },
      authorize?: false,
      return_notifications?: true
    )
    |> unwrap_record()
  end

  defp create_delivery(notification, recipient, user_id, channel) do
    endpoint = endpoint_for_user_channel(user_id, channel)

    status =
      cond do
        channel == :email and endpoint == nil and user_email(user_id) != nil -> :pending
        endpoint == nil -> :not_configured
        endpoint.status == :disabled -> :not_configured
        true -> :pending
      end

    create_notification_delivery(
      %{
        notification_id: notification.id,
        recipient_id: recipient.id,
        user_id: user_id,
        channel: channel,
        endpoint_id: endpoint && endpoint.id,
        status: status,
        metadata: %{
          inactive_channel: channel in @inactive_external_channels,
          delivery_deferred: true
        }
      },
      authorize?: false,
      return_notifications?: true
    )
    |> unwrap_record()
  end

  defp enabled_channels_for_user(user_id, notification) do
    Enum.filter(@channels, &channel_enabled?(user_id, notification, &1))
  end

  defp channel_enabled?(user_id, notification, channel) do
    preference =
      user_id
      |> preferences_for_user()
      |> Enum.filter(&(&1.channel == channel))
      |> Enum.filter(&preference_matches?(&1, notification))
      |> Enum.sort_by(&preference_score(&1), :desc)
      |> List.first()

    case preference do
      nil -> channel == :in_app
      %{cadence: :disabled} -> false
      %{enabled: enabled} -> enabled
    end
  end

  defp preferences_for_user(user_id) do
    NotificationPreference
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(expr(user_id == ^user_id))
    |> Ash.read!(authorize?: false, domain: __MODULE__)
  end

  defp preference_matches?(preference, notification) do
    scope_matches? =
      preference.scope_type == notification.scope_type and
        (is_nil(preference.scope_id) or preference.scope_id == notification.scope_id)

    key_matches? =
      is_nil(preference.notification_key) or
        preference.notification_key == notification.notification_key

    app_matches? = is_nil(preference.app_key) or preference.app_key == notification.app_key

    scope_matches? and key_matches? and app_matches?
  end

  defp preference_score(preference) do
    Enum.count(
      [
        preference.scope_id,
        preference.app_key,
        preference.notification_key
      ],
      &(!is_nil(&1))
    )
  end

  defp endpoint_for_user_channel(user_id, channel) do
    NotificationChannelEndpoint
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(expr(user_id == ^user_id and channel == ^channel))
    |> Ash.Query.sort(primary: :desc, inserted_at: :asc)
    |> Ash.read!(authorize?: false, domain: __MODULE__)
    |> Enum.reject(&(&1.status == :disabled))
    |> List.first()
  end

  defp user_email(user_id) do
    case EBoss.Accounts.get_user(user_id, authorize?: false) do
      {:ok, %{email: email}} -> to_string(email)
      _ -> nil
    end
  end

  defp resolve_recipient_user_ids(:system, _attrs), do: all_user_ids()
  defp resolve_recipient_user_ids({:system}, _attrs), do: all_user_ids()
  defp resolve_recipient_user_ids({:user, user}, _attrs), do: {:ok, [user_id!(user)]}

  defp resolve_recipient_user_ids({:users, users}, _attrs),
    do: {:ok, Enum.map(users, &user_id!/1)}

  defp resolve_recipient_user_ids({:organization, organization_id}, _attrs),
    do: organization_user_ids(organization_id)

  defp resolve_recipient_user_ids({:workspace, workspace_id}, _attrs),
    do: workspace_user_ids(workspace_id)

  defp resolve_recipient_user_ids({:app, workspace_id, _app_key}, _attrs),
    do: workspace_user_ids(workspace_id)

  defp resolve_recipient_user_ids(_audience, _attrs), do: {:error, :unsupported_audience}

  defp all_user_ids do
    users =
      User
      |> Ash.Query.for_read(:admin_index)
      |> Ash.read!(authorize?: false, domain: EBoss.Accounts)

    {:ok, Enum.map(users, & &1.id)}
  end

  defp organization_user_ids(organization_id) do
    memberships =
      OrganizationMembership
      |> Ash.Query.for_read(:read)
      |> Ash.Query.filter(organization_id == ^organization_id)
      |> Ash.read!(authorize?: false, domain: EBoss.Organizations)

    {:ok, Enum.map(memberships, & &1.user_id)}
  end

  defp workspace_user_ids(workspace_id) do
    case EBoss.Workspaces.get_workspace(workspace_id,
           load: [:workspace_memberships],
           authorize?: false
         ) do
      {:ok, %{owner_type: :user, owner_id: owner_id, workspace_memberships: memberships}} ->
        {:ok, Enum.uniq([owner_id | Enum.map(memberships, & &1.user_id)])}

      {:ok, %{owner_type: :organization, owner_id: organization_id}} ->
        organization_user_ids(organization_id)

      {:ok, %Workspace{owner_id: owner_id}} ->
        {:ok, [owner_id]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_recipient_for_user(user, recipient_id) do
    case NotificationRecipient
         |> Ash.Query.for_read(:read)
         |> Ash.Query.filter(expr(id == ^recipient_id))
         |> Ash.Query.load([:notification, :deliveries])
         |> Ash.read_one(actor: user, domain: __MODULE__) do
      {:ok, nil} -> {:error, :not_found}
      result -> result
    end
  end

  defp get_channel_endpoint_for_user(user, endpoint_id) do
    case NotificationChannelEndpoint
         |> Ash.Query.for_read(:read)
         |> Ash.Query.filter(expr(id == ^endpoint_id))
         |> Ash.read_one(actor: user, domain: __MODULE__) do
      {:ok, nil} -> {:error, :not_found}
      result -> result
    end
  end

  defp normalize_notification_attrs(attrs, audience) do
    attrs
    |> atomize_keys(@notification_attr_keys)
    |> Map.put_new(:scope_type, scope_type_for_audience(audience))
    |> Map.put_new(:notification_key, "system.notice")
    |> Map.put_new(:title, "Notification")
    |> Map.put_new(:severity, :info)
    |> Map.put_new(:actor_type, :system)
    |> Map.put_new(:metadata, %{})
    |> Map.put_new(:occurred_at, DateTime.utc_now())
    |> normalize_notification_atoms()
  end

  defp normalize_notification_atoms(attrs) do
    attrs
    |> Map.update(:scope_type, :system, &normalize_atom/1)
    |> Map.update(:severity, :info, &normalize_atom/1)
    |> Map.update(:actor_type, :system, &normalize_atom/1)
  end

  defp normalize_preference_attrs(entry, user_id) do
    entry
    |> atomize_keys(@preference_attr_keys)
    |> Map.put(:user_id, user_id)
    |> Map.put_new(:scope_type, :system)
    |> Map.put_new(:scope_id, nil)
    |> Map.put_new(:app_key, nil)
    |> Map.put_new(:notification_key, nil)
    |> Map.put_new(:enabled, true)
    |> Map.put_new(:cadence, :immediate)
    |> Map.update(:scope_type, :system, &normalize_atom/1)
    |> Map.update(:channel, :in_app, &normalize_atom/1)
    |> Map.update(:cadence, :immediate, &normalize_atom/1)
  end

  defp same_preference?(preference, attrs) do
    preference.scope_type == attrs.scope_type and
      preference.scope_id == attrs.scope_id and
      preference.app_key == attrs.app_key and
      preference.notification_key == attrs.notification_key and
      preference.channel == attrs.channel
  end

  defp scope_type_for_audience(:system), do: :system
  defp scope_type_for_audience({:system}), do: :system
  defp scope_type_for_audience({:user, _user}), do: :user
  defp scope_type_for_audience({:users, _users}), do: :user
  defp scope_type_for_audience({:organization, _organization_id}), do: :organization
  defp scope_type_for_audience({:workspace, _workspace_id}), do: :workspace
  defp scope_type_for_audience({:app, _workspace_id, _app_key}), do: :app
  defp scope_type_for_audience(_audience), do: :system

  defp filter_recipient_status(query, nil), do: Ash.Query.filter(query, expr(status != :archived))
  defp filter_recipient_status(query, ""), do: Ash.Query.filter(query, expr(status != :archived))
  defp filter_recipient_status(query, "all"), do: query
  defp filter_recipient_status(query, :all), do: query

  defp filter_recipient_status(query, "active"),
    do: Ash.Query.filter(query, expr(status != :archived))

  defp filter_recipient_status(query, :active),
    do: Ash.Query.filter(query, expr(status != :archived))

  defp filter_recipient_status(query, status) do
    case normalize_enum_filter(status, @recipient_statuses) do
      {:ok, status} -> Ash.Query.filter(query, expr(status == ^status))
      :error -> Ash.Query.filter(query, expr(false))
    end
  end

  defp filter_recipient_scope_type(query, nil), do: query
  defp filter_recipient_scope_type(query, ""), do: query
  defp filter_recipient_scope_type(query, "all"), do: query
  defp filter_recipient_scope_type(query, :all), do: query

  defp filter_recipient_scope_type(query, scope_type) do
    case normalize_enum_filter(scope_type, @scope_types) do
      {:ok, scope_type} -> Ash.Query.filter(query, expr(notification.scope_type == ^scope_type))
      :error -> Ash.Query.filter(query, expr(false))
    end
  end

  defp filter_recipient_workspace(query, nil), do: query
  defp filter_recipient_workspace(query, ""), do: query

  defp filter_recipient_workspace(query, workspace_id),
    do: Ash.Query.filter(query, expr(notification.workspace_id == ^workspace_id))

  defp filter_recipient_app(query, nil), do: query
  defp filter_recipient_app(query, ""), do: query

  defp filter_recipient_app(query, app_key),
    do: Ash.Query.filter(query, expr(notification.app_key == ^app_key))

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: Ash.Query.limit(query, limit)

  defp normalize_limit(nil), do: nil
  defp normalize_limit(value) when is_integer(value) and value > 0, do: value

  defp normalize_limit(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer > 0 -> integer
      _ -> nil
    end
  end

  defp normalize_limit(_value), do: nil

  defp user_id!(%{id: id}) when is_binary(id), do: id
  defp user_id!(id) when is_binary(id), do: id

  defp normalize_enum_filter(value, allowed_values) when is_atom(value) do
    if value in allowed_values, do: {:ok, value}, else: :error
  end

  defp normalize_enum_filter(value, allowed_values) when is_binary(value) do
    allowed_lookup = Map.new(allowed_values, &{to_string(&1), &1})

    case Map.fetch(allowed_lookup, value) do
      {:ok, atom} -> {:ok, atom}
      :error -> :error
    end
  end

  defp normalize_enum_filter(_value, _allowed_values), do: :error

  defp unwrap_record({:ok, record, _notifications}), do: {:ok, record}
  defp unwrap_record(result), do: result

  defp load_recipient(recipient) do
    Ash.load(recipient, [:notification, :deliveries], authorize?: false, domain: __MODULE__)
  end

  defp sort_deliveries(deliveries) do
    Enum.sort_by(deliveries, fn delivery ->
      Enum.find_index(@channels, &(&1 == delivery.channel)) || length(@channels)
    end)
  end

  defp apply_channel_endpoint_user_update(endpoint, %{status: :disabled} = attrs, user) do
    safe_attrs = Map.drop(attrs, [:status])

    with {:ok, endpoint} <- update_channel_endpoint_attrs(endpoint, safe_attrs, user),
         {:ok, endpoint} <- disable_channel_endpoint(endpoint, actor: user) do
      {:ok, endpoint}
    end
  end

  defp apply_channel_endpoint_user_update(_endpoint, %{status: status}, _user)
       when status in [:verified, :unverified],
       do: {:error, :invalid_channel_status}

  defp apply_channel_endpoint_user_update(_endpoint, %{status: _status}, _user),
    do: {:error, :invalid_channel_status}

  defp apply_channel_endpoint_user_update(endpoint, attrs, user) do
    update_channel_endpoint_attrs(endpoint, Map.delete(attrs, :status), user)
  end

  defp update_channel_endpoint_attrs(endpoint, attrs, _user) when attrs == %{},
    do: {:ok, endpoint}

  defp update_channel_endpoint_attrs(endpoint, attrs, user),
    do: update_channel_endpoint(endpoint, attrs, actor: user)

  defp normalize_channel_update_attrs(attrs) do
    if Map.has_key?(attrs, :status) do
      Map.update!(attrs, :status, &normalize_atom/1)
    else
      attrs
    end
  end

  defp atomize_keys(map, allowed_keys) when is_map(map) do
    allowed_lookup = Map.new(allowed_keys, &{to_string(&1), &1})

    Enum.reduce(map, %{}, fn
      {key, value}, acc when is_atom(key) ->
        if key in allowed_keys, do: Map.put(acc, key, value), else: acc

      {key, value}, acc when is_binary(key) ->
        case Map.fetch(allowed_lookup, key) do
          {:ok, atom_key} -> Map.put(acc, atom_key, value)
          :error -> acc
        end

      _pair, acc ->
        acc
    end)
  end

  defp normalize_atom(value) when is_atom(value), do: value
  defp normalize_atom(value) when is_binary(value), do: Map.get(@known_atom_lookup, value, value)

  defp topic(user_id), do: "notifications:user:#{user_id}"

  defp broadcast_user(user_id, message) do
    Phoenix.PubSub.broadcast(EBoss.PubSub, topic(user_id), message)
  end
end
