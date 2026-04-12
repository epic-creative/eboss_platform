defmodule EBossWeb.AuthController do
  use EBossWeb, :controller
  use AshAuthentication.Phoenix.Controller

  alias AshAuthentication.Info
  alias EBossWeb.AppScope

  def success(conn, activity, user, token) do
    return_to = get_session(conn, :return_to) || AppScope.default_dashboard_path(user)

    message =
      case activity do
        {:confirm_new_user, :confirm} -> "Your email address has now been confirmed"
        {:password, :reset} -> "Your password has successfully been reset"
        _ -> "You are now signed in"
      end

    conn
    |> delete_session(:return_to)
    |> store_authenticated_session(user, token)
    |> assign(:current_user, user)
    |> put_flash(:info, message)
    |> redirect(to: return_to)
  end

  def failure(conn, activity, reason) do
    message =
      case {activity, reason} do
        {_,
         %AshAuthentication.Errors.AuthenticationFailed{
           caused_by: %Ash.Error.Forbidden{
             errors: [%AshAuthentication.Errors.CannotConfirmUnconfirmedUser{}]
           }
         }} ->
          """
          You have already signed in another way, but have not confirmed your account.
          You can confirm your account using the link we sent to you, or by resetting your password.
          """

        _ ->
          failure_message(activity)
      end

    conn
    |> put_flash(:error, message)
    |> redirect(to: failure_path(activity))
  end

  def sign_out(conn, _params) do
    conn
    |> clear_session(:eboss_accounts)
    |> put_flash(:info, "You are now signed out")
    |> redirect(to: ~p"/")
  end

  defp failure_path({:password, :register}), do: ~p"/register"
  defp failure_path({:password, :reset_request}), do: ~p"/forgot-password"
  defp failure_path({:password, :reset}), do: ~p"/forgot-password"
  defp failure_path({:confirm_new_user, :confirm}), do: ~p"/sign-in"
  defp failure_path({:magic_link, :request}), do: ~p"/sign-in"
  defp failure_path({:magic_link, :sign_in}), do: ~p"/sign-in"
  defp failure_path(_activity), do: ~p"/sign-in"

  defp failure_message({:password, :register}), do: "We could not create your account"
  defp failure_message({:password, :reset_request}), do: "We could not send reset instructions"
  defp failure_message({:password, :reset}), do: "We could not reset your password"

  defp failure_message({:confirm_new_user, :confirm}),
    do: "That confirmation link is invalid or expired"

  defp failure_message({:magic_link, :request}), do: "We could not send that magic link"
  defp failure_message({:magic_link, :sign_in}), do: "That magic link is invalid or expired"
  defp failure_message(_activity), do: "Incorrect email or password"

  defp store_authenticated_session(conn, user, token) do
    if token &&
         Info.authentication_tokens_require_token_presence_for_authentication?(user.__struct__) do
      subject_name = Info.authentication_subject_name!(user.__struct__)
      put_session(conn, "#{subject_name}_token", token)
    else
      store_in_session(conn, user)
    end
  end
end
