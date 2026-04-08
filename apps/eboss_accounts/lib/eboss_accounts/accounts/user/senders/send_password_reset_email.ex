defmodule EBoss.Accounts.User.Senders.SendPasswordResetEmail do
  use AshAuthentication.Sender

  import Swoosh.Email

  alias EBoss.AuthLinks
  alias EBoss.Mailer

  @impl true
  def send(user, token, _) do
    new()
    |> from({"noreply", "noreply@example.com"})
    |> to(to_string(user.email))
    |> subject("Reset your password")
    |> html_body(body(token))
    |> Mailer.deliver!()
  end

  defp body(token) do
    reset_url = AuthLinks.reset_url(token)

    """
    <p>Click this link to reset your password:</p>
    <p><a href="#{reset_url}">#{reset_url}</a></p>
    """
  end
end
