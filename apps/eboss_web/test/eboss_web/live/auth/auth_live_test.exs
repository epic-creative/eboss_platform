defmodule EBossWeb.AuthLiveTest do
  use EBossWeb.ConnCase, async: false

  import LiveVue.Test
  import Swoosh.TestAssertions

  setup :set_swoosh_global

  test "anonymous visitors can access the public auth pages", %{conn: conn} do
    assert {:ok, home, _html} = live(conn, ~p"/")
    assert home.module == EBossWeb.HomeLive

    assert {:ok, sign_in, _html} = live(conn, ~p"/sign-in")
    assert sign_in.module == EBossWeb.Auth.SignInLive

    assert {:ok, register, _html} = live(conn, ~p"/register")
    assert register.module == EBossWeb.Auth.RegisterLive

    assert {:ok, forgot_password, _html} = live(conn, ~p"/forgot-password")
    assert forgot_password.module == EBossWeb.Auth.ForgotPasswordLive
  end

  test "signed-in visitors are redirected away from home and anonymous-only auth pages",
       context do
    %{conn: conn} = register_and_log_in_user(context)

    assert {:error, {:redirect, %{to: "/dashboard"}}} = live(conn, ~p"/")
    assert {:error, {:redirect, %{to: "/dashboard"}}} = live(conn, ~p"/sign-in")
    assert {:error, {:redirect, %{to: "/dashboard"}}} = live(conn, ~p"/register")
    assert {:error, {:redirect, %{to: "/dashboard"}}} = live(conn, ~p"/forgot-password")
  end

  test "anonymous visitors are redirected to sign-in for the dashboard", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/dashboard")
  end

  test "custom pages render the shared LiveVue shell", %{conn: conn} do
    {:ok, sign_in, _html} = live(conn, ~p"/sign-in")
    sign_in_shell = get_vue(sign_in, name: "AuthScene")

    assert sign_in_shell.component == "AuthScene"
    assert sign_in_shell.props["title"] == "Sign in without leaving the product"

    context = register_and_log_in_user(%{conn: conn})
    {:ok, dashboard, _html} = live(context.conn, ~p"/dashboard")
    dashboard_shell = get_vue(dashboard, name: "DashboardLaunchpad")

    assert dashboard_shell.component == "DashboardLaunchpad"
    assert dashboard_shell.props["username"] == context.current_user.username
  end

  test "sign-in page isolates password and magic-link field names for browser autofill", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/sign-in")
    html = render(view)

    assert html =~ ~s(name="password_user[email]")
    assert html =~ ~s(name="password_user[password]")
    assert html =~ ~s(autocomplete="section-password email")
    assert html =~ ~s(autocomplete="section-password current-password")

    assert html =~ ~s(name="magic_link_user[email]")
    assert html =~ ~s(autocomplete="section-magic-link email")
  end

  test "registration succeeds, signs the user in, and sends confirmation email", %{conn: conn} do
    params = %{
      "email" => "register-live@example.com",
      "username" => "register_live_user",
      "password" => "supersecret123",
      "password_confirmation" => "supersecret123"
    }

    {:ok, view, _html} = live(conn, ~p"/register")

    {:ok, token_conn} =
      view
      |> form("#register-form", user: params)
      |> render_submit()
      |> follow_redirect(conn)

    assert redirected_to(token_conn) == "/dashboard"

    dashboard_conn = get(recycle(token_conn), ~p"/dashboard")
    assert html_response(dashboard_conn, 200) =~ "@register_live_user"

    assert_received {:email, email}
    assert email.html_body =~ "/confirm/"
  end

  test "registration validation errors stay on the page", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/register")

    html =
      view
      |> form("#register-form",
        user: %{
          "email" => "invalid",
          "username" => "ab",
          "password" => "short",
          "password_confirmation" => "mismatch"
        }
      )
      |> render_submit()

    assert html =~ "We need a quick fix before continuing."
    assert html =~ "must"
  end

  test "password sign-in succeeds from the custom page", %{conn: conn} do
    user = register_user(%{email: "signin-live@example.com", username: "signin_live_user"})
    flush_emails()

    {:ok, view, _html} = live(conn, ~p"/sign-in")

    {:ok, token_conn} =
      view
      |> form("#sign-in-password-form",
        password_user: %{"email" => to_string(user.email), "password" => "supersecret123"}
      )
      |> render_submit()
      |> follow_redirect(conn)

    assert redirected_to(token_conn) == "/dashboard"

    dashboard_conn = get(recycle(token_conn), ~p"/dashboard")
    assert html_response(dashboard_conn, 200) =~ "@signin_live_user"
  end

  test "invalid password sign-in stays on the page", %{conn: conn} do
    user = register_user(%{email: "bad-signin@example.com", username: "bad_signin"})
    flush_emails()

    {:ok, view, _html} = live(conn, ~p"/sign-in")

    html =
      view
      |> form("#sign-in-password-form",
        password_user: %{"email" => to_string(user.email), "password" => "wrong-password"}
      )
      |> render_submit()

    assert html =~ "We need a quick fix before continuing."
  end

  test "forgot password sends a reset email", %{conn: conn} do
    user = register_user(%{email: "reset-request@example.com", username: "reset_request"})
    flush_emails()

    {:ok, view, _html} = live(conn, ~p"/forgot-password")

    html =
      view
      |> form("#forgot-password-form", user: %{"email" => to_string(user.email)})
      |> render_submit()

    assert html =~ "Reset instructions are on the way"

    assert_received {:email, email}
    assert email.html_body =~ "/reset/"
  end

  test "magic-link request sends an email for an existing user", %{conn: conn} do
    user = register_user(%{email: "magic-link@example.com", username: "magic_link_user"})
    flush_emails()

    {:ok, view, _html} = live(conn, ~p"/sign-in")

    html =
      view
      |> form("#sign-in-magic-link-form", magic_link_user: %{"email" => to_string(user.email)})
      |> render_submit()

    assert html =~ "Check your email for the sign-in link."

    assert_received {:email, email}
    assert email.html_body =~ "/magic_link/"
  end

  test "reset token flow updates the password and lands on the dashboard", %{conn: conn} do
    user = register_user(%{email: "reset-token@example.com", username: "reset_token_user"})
    flush_emails()

    EBoss.Accounts.request_password_reset_token!(%{email: user.email}, authorize?: false)
    reset_token = extract_token_from_latest_email("reset")

    {:ok, view, _html} = live(conn, "/reset/#{reset_token}")

    {:ok, token_conn} =
      view
      |> form("#reset-password-form",
        user: %{
          "reset_token" => reset_token,
          "password" => "anothersupersecret123",
          "password_confirmation" => "anothersupersecret123"
        }
      )
      |> render_submit()
      |> follow_redirect(conn)

    assert redirected_to(token_conn) == "/dashboard"

    dashboard_conn = get(recycle(token_conn), ~p"/dashboard")
    assert html_response(dashboard_conn, 200) =~ "@reset_token_user"
  end

  test "confirmation token flow redirects to the dashboard", %{conn: conn} do
    _user = register_user(%{email: "confirm-token@example.com", username: "confirm_token_user"})
    confirm_token = extract_token_from_latest_email("confirm")

    {:ok, view, _html} = live(conn, "/confirm/#{confirm_token}")

    form = form(view, "#confirm-form", user: %{"confirm" => confirm_token})

    assert render_submit(form) =~ "phx-trigger-action"

    token_conn = follow_trigger_action(form, conn)
    assert redirected_to(token_conn) == "/dashboard"

    dashboard_conn = get(recycle(token_conn), ~p"/dashboard")
    assert html_response(dashboard_conn, 200) =~ "@confirm_token_user"
  end

  test "magic-link token flow redirects to the dashboard", %{conn: conn} do
    user = register_user(%{email: "magic-token@example.com", username: "magic_token_user"})
    flush_emails()

    EBoss.Accounts.request_magic_link!(%{email: user.email}, authorize?: false)
    magic_token = extract_token_from_latest_email("magic_link")

    {:ok, view, _html} = live(conn, "/magic_link/#{magic_token}")

    form = form(view, "#magic-link-form", user: %{"token" => magic_token})

    assert render_submit(form) =~ "phx-trigger-action"

    token_conn = follow_trigger_action(form, conn)
    assert redirected_to(token_conn) == "/dashboard"

    dashboard_conn = get(recycle(token_conn), ~p"/dashboard")
    assert html_response(dashboard_conn, 200) =~ "@magic_token_user"
  end

  test "logout clears the session and returns to the public flow", context do
    %{conn: conn} = register_and_log_in_user(context)

    dashboard_conn = get(conn, ~p"/dashboard")
    assert html_response(dashboard_conn, 200) =~ "Welcome back"

    sign_out_conn = delete(recycle(dashboard_conn), ~p"/logout")
    assert redirected_to(sign_out_conn) == "/"

    assert {:error, {:redirect, %{to: "/sign-in"}}} = live(recycle(sign_out_conn), ~p"/dashboard")
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
