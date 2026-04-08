defmodule EBoss.AccountsTest do
  use EBoss.DataCase, async: false

  import Swoosh.TestAssertions

  setup :set_swoosh_global

  test "register normalizes usernames and sends confirmation email" do
    user = register_user(%{email: "case@example.com", username: "Case_User"})

    assert user.username == "case_user"

    assert_received {:email, email}
    assert email.subject == "Confirm your email address"
    assert email.html_body =~ "/confirm/"
  end

  test "duplicate usernames are rejected even when casing differs" do
    _user = register_user(%{username: "TakenName"})

    assert {:error, error} =
             EBoss.Accounts.User
             |> Ash.Changeset.for_create(:register_with_password, %{
               email: unique_email(),
               username: "takenname",
               password: password(),
               password_confirmation: password()
             })
             |> Ash.Changeset.set_context(%{private: %{ash_authentication?: true}})
             |> Ash.create(authorize?: false)

    assert Exception.message(error) =~ "has already been taken"
  end

  test "requesting a magic link sends an email and the token signs the user in" do
    magic_email = unique_email()
    flush_emails()

    EBoss.Accounts.User
    |> Ash.ActionInput.for_action(:request_magic_link, %{email: magic_email})
    |> Ash.ActionInput.set_context(%{private: %{ash_authentication?: true}})
    |> Ash.run_action!(authorize?: false)

    assert_received {:email, email}
    token = extract_token(email.html_body, "magic_link")

    signed_in_user =
      EBoss.Accounts.User
      |> Ash.Changeset.for_create(:sign_in_with_magic_link, %{
        token: token,
        username: "magic_user_#{System.unique_integer([:positive])}"
      })
      |> Ash.Changeset.set_context(%{private: %{ash_authentication?: true}})
      |> Ash.create!(authorize?: false)

    assert to_string(signed_in_user.email) == magic_email
    assert signed_in_user.confirmed_at
  end

  test "requesting a password reset sends a reset email" do
    user = register_user()
    flush_emails()

    EBoss.Accounts.User
    |> Ash.ActionInput.for_action(:request_password_reset_token, %{email: user.email})
    |> Ash.ActionInput.set_context(%{private: %{ash_authentication?: true}})
    |> Ash.run_action!(authorize?: false)

    assert_received {:email, email}
    assert email.subject == "Reset your password"
    assert email.html_body =~ "/reset/"
  end

  test "users can change their own password" do
    user = register_user()
    new_password = "an-even-better-secret123"

    changed_user =
      user
      |> Ash.Changeset.for_update(
        :change_password,
        %{
          current_password: password(),
          password: new_password,
          password_confirmation: new_password
        },
        actor: user
      )
      |> Ash.update!()

    signed_in_user =
      EBoss.Accounts.User
      |> Ash.Query.for_read(:sign_in_with_password, %{
        email: user.email,
        password: new_password
      })
      |> Ash.read_one!(authorize?: false)

    assert changed_user.id == user.id
    assert signed_in_user.id == user.id
  end

  test "api keys can be created and used to authenticate" do
    user = register_user()
    flush_emails()

    api_key =
      EBoss.Accounts.ApiKey
      |> Ash.Changeset.for_create(:create, %{
        user_id: user.id,
        expires_at: DateTime.add(DateTime.utc_now(), 3_600, :second)
      })
      |> Ash.create!(authorize?: false)

    plaintext_api_key = api_key.__metadata__.plaintext_api_key

    signed_in_user =
      EBoss.Accounts.User
      |> Ash.Query.for_read(:sign_in_with_api_key, %{api_key: plaintext_api_key})
      |> Ash.read_one!(authorize?: false)

    assert signed_in_user.id == user.id
    assert signed_in_user.__metadata__.using_api_key?
  end

  defp register_user(overrides \\ %{}) do
    params =
      Map.merge(
        %{
          email: unique_email(),
          username: "user#{System.unique_integer([:positive])}",
          password: password(),
          password_confirmation: password()
        },
        overrides
      )

    EBoss.Accounts.User
    |> Ash.Changeset.for_create(:register_with_password, params)
    |> Ash.Changeset.set_context(%{private: %{ash_authentication?: true}})
    |> Ash.create!(authorize?: false)
  end

  defp unique_email do
    "user#{System.unique_integer([:positive])}@example.com"
  end

  defp password, do: "supersecret123"

  defp extract_token(body, path) do
    Regex.run(~r{/#{path}/([^"<]+)}, body, capture: :all_but_first)
    |> List.first()
  end

  defp flush_emails do
    receive do
      {:email, _email} -> flush_emails()
    after
      0 -> :ok
    end
  end
end
