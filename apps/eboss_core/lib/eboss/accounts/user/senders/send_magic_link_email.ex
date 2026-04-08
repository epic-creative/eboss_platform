defmodule EBoss.Accounts.User.Senders.SendMagicLinkEmail do
  use AshAuthentication.Sender

  import Swoosh.Email

  alias EBoss.AuthLinks
  alias EBoss.Mailer

  @impl true
  def send(user_or_email, token, _) do
    email =
      case user_or_email do
        %{email: email} -> email
        email -> email
      end

    new()
    |> from({"noreply", "noreply@example.com"})
    |> to(to_string(email))
    |> subject("Your login link")
    |> html_body(body(token, email))
    |> Mailer.deliver!()
  end

  defp body(token, email) do
    magic_link_url = AuthLinks.magic_link_url(token)

    """
    <p>Hello, #{email}! Click this link to sign in:</p>
    <p><a href="#{magic_link_url}">#{magic_link_url}</a></p>
    """
  end
end
