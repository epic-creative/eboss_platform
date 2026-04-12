defmodule EBoss.Accounts do
  use Ash.Domain, otp_app: :eboss_accounts

  resources do
    resource(EBoss.Accounts.Token)
    resource(EBoss.Accounts.User)
    resource(EBoss.Accounts.ApiKey)
  end

  alias EBoss.Accounts.User

  defdelegate change_password(user, params \\ %{}, opts \\ []), to: User
  defdelegate change_password!(user, params \\ %{}, opts \\ []), to: User
  defdelegate list_users(opts \\ []), to: User
  defdelegate list_users!(opts \\ []), to: User
  defdelegate suspend_user(user, opts \\ []), to: User
  defdelegate suspend_user!(user, opts \\ []), to: User
  defdelegate undo_suspend_user(user, opts \\ []), to: User
  defdelegate undo_suspend_user!(user, opts \\ []), to: User
  defdelegate soft_delete_user(user, opts \\ []), to: User
  defdelegate soft_delete_user!(user, opts \\ []), to: User
  defdelegate undo_delete_user(user, opts \\ []), to: User
  defdelegate undo_delete_user!(user, opts \\ []), to: User
  defdelegate admin_update_user(user, params \\ %{}, opts \\ []), to: User
  defdelegate admin_update_user!(user, params \\ %{}, opts \\ []), to: User

  def register_with_password(attrs, opts \\ []) do
    User
    |> Ash.Changeset.for_create(:register_with_password, attrs)
    |> Ash.Changeset.set_context(authentication_context(opts))
    |> Ash.create(default_action_opts(opts))
  end

  def register_with_password!(attrs, opts \\ []) do
    case register_with_password(attrs, opts) do
      {:ok, user} -> user
      {:error, error} -> raise error
    end
  end

  def sign_in_with_password(attrs, opts \\ []) do
    User
    |> Ash.Query.for_read(:sign_in_with_password, attrs)
    |> Ash.Query.set_context(authentication_context(opts))
    |> Ash.read_one(default_action_opts(opts))
  end

  def sign_in_with_password!(attrs, opts \\ []) do
    case sign_in_with_password(attrs, opts) do
      {:ok, user} -> user
      {:error, error} -> raise error
    end
  end

  def sign_in_with_token(token, opts \\ []) when is_binary(token) do
    User
    |> Ash.Query.for_read(:sign_in_with_token, %{token: token})
    |> Ash.Query.set_context(authentication_context(opts))
    |> Ash.read_one(default_action_opts(opts))
  end

  def sign_in_with_token!(token, opts \\ []) do
    case sign_in_with_token(token, opts) do
      {:ok, user} -> user
      {:error, error} -> raise error
    end
  end

  def request_magic_link(attrs, opts \\ []) when is_map(attrs) do
    User
    |> Ash.ActionInput.for_action(:request_magic_link, attrs)
    |> Ash.ActionInput.set_context(authentication_context(opts))
    |> Ash.run_action(default_action_opts(opts))
  end

  def request_magic_link!(attrs, opts \\ []) do
    case request_magic_link(attrs, opts) do
      :ok -> :ok
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  def request_password_reset_token(attrs, opts \\ []) when is_map(attrs) do
    User
    |> Ash.ActionInput.for_action(:request_password_reset_token, attrs)
    |> Ash.ActionInput.set_context(authentication_context(opts))
    |> Ash.run_action(default_action_opts(opts))
  end

  def request_password_reset_token!(attrs, opts \\ []) do
    case request_password_reset_token(attrs, opts) do
      :ok -> :ok
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  def sign_in_with_api_key(api_key, opts \\ []) when is_binary(api_key) do
    User
    |> Ash.Query.for_read(:sign_in_with_api_key, %{api_key: api_key})
    |> Ash.Query.set_context(authentication_context(opts))
    |> Ash.read_one(default_action_opts(opts))
  end

  def sign_in_with_api_key!(api_key, opts \\ []) do
    case sign_in_with_api_key(api_key, opts) do
      {:ok, user} -> user
      {:error, error} -> raise error
    end
  end

  defdelegate get_user(id, opts \\ []), to: User
  defdelegate get_user!(id, opts \\ []), to: User
  defdelegate get_user_by_email(email, opts \\ []), to: User
  defdelegate get_user_by_email!(email, opts \\ []), to: User
  defdelegate get_user_by_username(username, opts \\ []), to: User
  defdelegate get_user_by_username!(username, opts \\ []), to: User

  defp default_action_opts(opts) do
    opts
    |> Keyword.put_new(:domain, __MODULE__)
  end

  defp authentication_context(opts) do
    opts
    |> Keyword.get(:context, %{})
    |> deep_merge(%{private: %{ash_authentication?: true}})
  end

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      deep_merge(left_value, right_value)
    end)
  end

  defp deep_merge(_left, right), do: right
end
