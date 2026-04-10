defmodule EBossWeb.AuthForms do
  @moduledoc false

  alias Ash.Resource
  alias AshAuthentication.Info
  alias AshAuthentication.Jwt
  alias AshAuthentication.Strategy
  alias AshAuthentication.Phoenix.Components.Helpers
  alias AshPhoenix.Form
  alias AshPhoenix.FormData.Error

  @resource EBoss.Accounts.User
  @auth_routes_prefix "/auth"

  def auth_routes_prefix, do: @auth_routes_prefix
  def subject_name, do: Info.authentication_subject_name!(@resource)
  def subject_name_string, do: subject_name() |> to_string()
  def resource, do: @resource
  def domain, do: Info.authentication_domain!(@resource)

  def password_strategy!, do: Info.strategy!(@resource, :password)
  def magic_link_strategy!, do: Info.strategy!(@resource, :magic_link)
  def confirmation_strategy!, do: Info.strategy!(@resource, :confirm_new_user)

  def auth_path(socket, strategy, phase, params \\ %{}) do
    Helpers.auth_path(socket, subject_name(), @auth_routes_prefix, strategy, phase, params)
  end

  def password_sign_in_form(current_tenant \\ nil, context \\ %{}, opts \\ []) do
    strategy = password_strategy!()
    as = Keyword.get(opts, :as, subject_name_string())

    Form.for_action(strategy.resource, strategy.sign_in_action_name,
      domain: domain(),
      as: as,
      id: "#{subject_name_string()}-password-sign-in",
      tenant: current_tenant,
      transform_errors: &transform_errors/2,
      context: password_sign_in_context(strategy, context)
    )
  end

  def register_form(current_tenant \\ nil, context \\ %{}) do
    strategy = password_strategy!()

    Form.for_action(strategy.resource, strategy.register_action_name,
      domain: domain(),
      as: subject_name_string(),
      id: "#{subject_name_string()}-password-register",
      tenant: current_tenant,
      transform_errors: &transform_errors/2,
      context: register_context(strategy, context)
    )
  end

  def forgot_password_form(current_tenant \\ nil, context \\ %{}) do
    strategy = password_strategy!()

    Form.for_action(strategy.resource, strategy.resettable.request_password_reset_action_name,
      domain: domain(),
      as: subject_name_string(),
      id: "#{subject_name_string()}-password-reset-request",
      tenant: current_tenant,
      transform_errors: &transform_errors/2,
      context: auth_context(strategy, context)
    )
  end

  def reset_password_form(token, current_tenant \\ nil) do
    strategy = password_strategy!()

    strategy.resource
    |> Form.for_action(strategy.resettable.password_reset_action_name,
      domain: domain(),
      as: subject_name_string(),
      id: "#{subject_name_string()}-password-reset",
      tenant: current_tenant,
      transform_errors: &transform_errors/2,
      context: auth_context(strategy)
    )
    |> Form.validate(%{"reset_token" => token}, errors: false)
  end

  def magic_link_request_form(current_tenant \\ nil, context \\ %{}, opts \\ []) do
    strategy = magic_link_strategy!()
    as = Keyword.get(opts, :as, subject_name_string())

    Form.for_action(strategy.resource, strategy.request_action_name,
      domain: domain(),
      as: as,
      id: "#{subject_name_string()}-magic-link-request",
      tenant: current_tenant,
      transform_errors: &transform_errors/2,
      context: auth_context(strategy, context)
    )
  end

  def confirm_form(token, current_tenant \\ nil) do
    strategy = confirmation_strategy!()

    strategy.resource
    |> Form.for_action(strategy.confirm_action_name,
      domain: domain(),
      as: subject_name_string(),
      id: "#{subject_name_string()}-confirm",
      tenant: current_tenant,
      transform_errors: &transform_errors/2,
      context: auth_context(strategy)
    )
    |> Form.validate(%{"confirm" => token}, errors: false)
  end

  def magic_link_consume_form(token, current_tenant \\ nil) do
    strategy = magic_link_strategy!()

    strategy.resource
    |> Form.for_action(strategy.sign_in_action_name,
      domain: domain(),
      as: subject_name_string(),
      id: "#{subject_name_string()}-magic-link-sign-in",
      tenant: current_tenant,
      transform_errors: &transform_errors/2,
      context: auth_context(strategy)
    )
    |> Form.validate(%{"token" => token}, errors: false)
  end

  def reset_password(params, opts \\ []) when is_map(params) do
    strategy = password_strategy!()
    opts = with_auth_context(strategy, opts)

    with {:ok, user} <- Strategy.action(strategy, :reset, params, opts),
         {:ok, sign_in_token, _claims} <-
           Jwt.token_for_user(
             user,
             %{"purpose" => "sign_in"},
             sign_in_token_opts(strategy, opts),
             Keyword.get(opts, :context, %{})
           ) do
      {:ok, Resource.put_metadata(user, :token, sign_in_token)}
    end
  end

  defp password_sign_in_context(strategy, context) do
    context =
      context
      |> Map.put(:token_type, :sign_in)
      |> Map.update(
        :private,
        %{skip_remember_me_token_generation: true},
        &Map.put(&1, :skip_remember_me_token_generation, true)
      )

    auth_context(strategy, context)
  end

  defp register_context(strategy, context) do
    context =
      context
      |> Map.put(:token_type, :sign_in)

    auth_context(strategy, context)
  end

  defp auth_context(strategy, context \\ %{}) do
    context
    |> Map.put(:strategy, strategy)
    |> Map.update(
      :private,
      %{ash_authentication?: true},
      &Map.put(&1, :ash_authentication?, true)
    )
  end

  defp with_auth_context(strategy, opts) do
    Keyword.update(opts, :context, auth_context(strategy), &auth_context(strategy, &1))
  end

  defp sign_in_token_opts(strategy, opts) do
    opts
    |> Keyword.take([:tenant, :signing_algorithm, :signing_secret])
    |> Keyword.merge(
      purpose: :sign_in,
      token_lifetime: strategy.sign_in_token_lifetime
    )
  end

  defp transform_errors(_source, error) do
    if Error.impl_for(error) do
      Error.to_form_error(error)
    else
      error
    end
  end
end
