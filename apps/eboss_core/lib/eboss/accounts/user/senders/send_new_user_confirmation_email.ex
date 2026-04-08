defmodule EBoss.Accounts.User.Senders.SendNewUserConfirmationEmail do
  use AshAuthentication.Sender

  import Swoosh.Email

  alias EBoss.AuthLinks
  alias EBoss.Mailer

  @impl true
  def send(user, token, _) do
    new()
    |> from({"noreply", "noreply@example.com"})
    |> to(to_string(user.email))
    |> subject("Confirm your email address")
    |> html_body(body(token))
    |> Mailer.deliver!()
  end

  defp body(token) do
    confirmation_url = AuthLinks.confirm_url(token)

    """
    <p>Click this link to confirm your email:</p>
    <p><a href="#{confirmation_url}">#{confirmation_url}</a></p>
    """
  end
end
