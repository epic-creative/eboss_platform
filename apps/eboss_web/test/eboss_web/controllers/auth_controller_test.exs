defmodule EBossWeb.AuthControllerTest do
  use EBossWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  setup :set_swoosh_global

  test "password registration redirects home and sends confirmation email", %{conn: conn} do
    conn =
      post(conn, ~p"/auth/user/password/register", %{
        "user" => %{
          "email" => "register@example.com",
          "username" => "register_user",
          "password" => "supersecret123",
          "password_confirmation" => "supersecret123"
        }
      })

    assert redirected_to(conn) == "/"
    assert Phoenix.Flash.get(conn.assigns.flash, :info) == "You are now signed in"

    assert_received {:email, email}
    assert email.html_body =~ "/confirm/"
  end

  test "password sign in redirects home for valid credentials", %{conn: conn} do
    user = register_user(%{email: "signin@example.com", username: "signin_user"})
    flush_emails()

    conn =
      post(conn, ~p"/auth/user/password/sign_in", %{
        "user" => %{"email" => user.email, "password" => "supersecret123"}
      })

    assert redirected_to(conn) == "/"
    assert Phoenix.Flash.get(conn.assigns.flash, :info) == "You are now signed in"
  end

  test "confirm, reset, and magic link routes mount their LiveViews", %{conn: conn} do
    user = register_user()
    confirm_token = extract_token_from_latest_email("confirm")

    EBoss.Accounts.User
    |> Ash.ActionInput.for_action(:request_password_reset_token, %{email: user.email})
    |> Ash.ActionInput.set_context(%{private: %{ash_authentication?: true}})
    |> Ash.run_action!(authorize?: false)

    reset_token = extract_token_from_latest_email("reset")

    EBoss.Accounts.User
    |> Ash.ActionInput.for_action(:request_magic_link, %{email: user.email})
    |> Ash.ActionInput.set_context(%{private: %{ash_authentication?: true}})
    |> Ash.run_action!(authorize?: false)

    magic_link_token = extract_token_from_latest_email("magic_link")

    assert {:ok, confirm_view, _html} = live(conn, "/confirm/#{confirm_token}")
    assert confirm_view.module == AshAuthentication.Phoenix.ConfirmLive

    assert {:ok, reset_view, _html} = live(conn, "/reset/#{reset_token}")
    assert reset_view.module == AshAuthentication.Phoenix.ResetLive

    assert {:ok, magic_view, _html} = live(conn, "/magic_link/#{magic_link_token}")
    assert magic_view.module == AshAuthentication.Phoenix.MagicSignInLive
  end

  defp register_user(overrides \\ %{}) do
    params =
      Map.merge(
        %{
          email: "user#{System.unique_integer([:positive])}@example.com",
          username: "user#{System.unique_integer([:positive])}",
          password: "supersecret123",
          password_confirmation: "supersecret123"
        },
        overrides
      )

    EBoss.Accounts.User
    |> Ash.Changeset.for_create(:register_with_password, params)
    |> Ash.Changeset.set_context(%{private: %{ash_authentication?: true}})
    |> Ash.create!(authorize?: false)
  end

  defp extract_token_from_latest_email(path) do
    assert_received {:email, email}

    Regex.run(~r{/#{path}/([^"<]+)}, email.html_body, capture: :all_but_first)
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
