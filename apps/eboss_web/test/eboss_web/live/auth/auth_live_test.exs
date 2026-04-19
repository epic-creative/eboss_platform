defmodule EBossWeb.AuthLiveTest do
  use EBossWeb.ConnCase, async: false

  import LiveVue.Test
  import Swoosh.TestAssertions

  alias EBossWeb.BrowserTestContracts

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

  test "auth routes share the same shell hierarchy", %{conn: conn} do
    user = register_user(%{email: "shared-shell@example.com", username: "shared-shell-user"})
    confirm_token = extract_token_from_latest_email("confirm")

    EBoss.Accounts.request_password_reset_token!(%{email: user.email}, authorize?: false)
    reset_token = extract_token_from_latest_email("reset")

    EBoss.Accounts.request_magic_link!(%{email: user.email}, authorize?: false)
    magic_token = extract_token_from_latest_email("magic_link")

    routes = [
      ~p"/sign-in",
      ~p"/register",
      ~p"/forgot-password",
      "/reset/#{reset_token}",
      "/confirm/#{confirm_token}",
      "/magic_link/#{magic_token}"
    ]

    for route <- routes do
      assert {:ok, view, _html} = live(conn, route)
      assert_auth_shell(view)
    end
  end

  test "anonymous auth routes expose stable browser form and shell contracts", %{conn: conn} do
    routes = [
      {~p"/sign-in",
       [
         BrowserTestContracts.password_sign_in_form_label(),
         BrowserTestContracts.magic_link_request_form_label()
       ]},
      {~p"/register", [BrowserTestContracts.register_form_label()]},
      {~p"/forgot-password", [BrowserTestContracts.forgot_password_form_label()]}
    ]

    for {route, form_labels} <- routes do
      assert {:ok, view, _html} = live(conn, route)
      assert has_element?(view, ~s([data-testid="#{BrowserTestContracts.auth_shell()}"]))

      for form_label <- form_labels do
        assert has_element?(view, ~s(form[aria-label="#{form_label}"]))
      end
    end
  end

  test "auth routes use the dedicated auth shell while home keeps the landing content surface", %{
    conn: conn
  } do
    user = register_user(%{email: "public-shell@example.com", username: "public-shell-user"})
    confirm_token = extract_token_from_latest_email("confirm")

    EBoss.Accounts.request_password_reset_token!(%{email: user.email}, authorize?: false)
    reset_token = extract_token_from_latest_email("reset")

    EBoss.Accounts.request_magic_link!(%{email: user.email}, authorize?: false)
    magic_token = extract_token_from_latest_email("magic_link")

    routes = [
      ~p"/sign-in",
      ~p"/register",
      ~p"/forgot-password",
      "/reset/#{reset_token}",
      "/confirm/#{confirm_token}",
      "/magic_link/#{magic_token}"
    ]

    for route <- routes do
      assert {:ok, view, _html} = live(conn, route)
      assert_auth_shell(view)
    end

    assert {:ok, home, _html} = live(conn, ~p"/")
    assert has_element?(home, ".ui-shell[data-shell-mode='public']")
    assert has_element?(home, "[data-public-shell-nav]")
    assert has_element?(home, "[data-public-shell-footer]")
    refute has_element?(home, ~s([data-testid="#{BrowserTestContracts.auth_shell()}"]))

    landing = get_vue(home, name: "ShellOperatorLanding")
    assert landing.component == "ShellOperatorLanding"
    assert landing.ssr == false
  end

  test "signed-in visitors are redirected away from home and anonymous-only auth pages",
       context do
    %{conn: conn} = register_and_log_in_user(context)

    assert {:error, {:redirect, %{to: "/dashboard"}}} = live(conn, ~p"/")
    assert {:error, {:redirect, %{to: "/dashboard"}}} = live(conn, ~p"/sign-in")
    assert {:error, {:redirect, %{to: "/dashboard"}}} = live(conn, ~p"/register")
    assert {:error, {:redirect, %{to: "/dashboard"}}} = live(conn, ~p"/forgot-password")
  end

  test "signed-in visitors with an accessible workspace are redirected to the canonical workspace route",
       %{conn: conn} do
    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "canonical-auth@example.com",
        username: "canonical-auth-user"
      })

    workspace =
      create_user_workspace(context.current_user, %{
        name: "Canonical Auth Workspace"
      })

    dashboard_path = dashboard_path(context.current_user.owner_slug, workspace.slug)

    assert {:error, {:redirect, %{to: ^dashboard_path}}} = live(context.conn, ~p"/")
    assert {:error, {:redirect, %{to: ^dashboard_path}}} = live(context.conn, ~p"/sign-in")
    assert {:error, {:redirect, %{to: ^dashboard_path}}} = live(context.conn, ~p"/register")

    assert {:error, {:redirect, %{to: ^dashboard_path}}} =
             live(context.conn, ~p"/forgot-password")
  end

  test "signed-in visitors without owned or member workspaces stay on /dashboard even when public workspaces exist",
       %{conn: conn} do
    owner =
      register_user(%{
        email: "public-home-owner@example.com",
        username: "public-home-owner"
      })

    _public_workspace =
      create_user_workspace(owner, %{
        name: "Public Home Workspace",
        visibility: :public
      })

    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "public-home-outsider@example.com",
        username: "public-home-outsider"
      })

    assert {:error, {:redirect, %{to: "/dashboard"}}} = live(context.conn, ~p"/")
    assert {:error, {:redirect, %{to: "/dashboard"}}} = live(context.conn, ~p"/sign-in")
  end

  test "anonymous visitors are redirected to sign-in for the dashboard", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/dashboard")
  end

  test "dashboard mounts the workspace shell without public footer chrome", context do
    %{conn: conn} = register_and_log_in_user(context)

    assert {:ok, dashboard, _html} = live(conn, ~p"/dashboard")
    assert has_element?(dashboard, ".ui-shell[data-shell-mode='workspace']")
    refute has_element?(dashboard, "[data-public-shell-nav]")
    refute has_element?(dashboard, "[data-public-shell-footer]")
    refute has_element?(dashboard, "[data-public-cta-frame]")

    workspace_shell = get_vue(dashboard, name: "ShellOperatorWorkspaceApp")

    assert workspace_shell.component == "ShellOperatorWorkspaceApp"
    assert workspace_shell.props["currentScope"]["empty"] == true
  end

  test "custom pages render the shared LiveVue shell", %{conn: conn} do
    {:ok, sign_in, _html} = live(conn, ~p"/sign-in")
    assert_auth_shell(sign_in)
    assert render(sign_in) =~ "Sign in to EBoss"
    refute render(sign_in) =~ ~s(data-name="AuthScene")

    context =
      register_and_log_in_user(%{conn: conn}, %{
        email: "dashboard-vue@example.com",
        username: "dashboard-vue-user"
      })

    workspace =
      create_user_workspace(context.current_user, %{
        name: "Dashboard Vue Workspace"
      })

    {:ok, dashboard, _html} =
      live(context.conn, dashboard_path(context.current_user.owner_slug, workspace.slug))

    dashboard_shell = get_vue(dashboard, name: "ShellOperatorWorkspaceApp")

    assert dashboard_shell.component == "ShellOperatorWorkspaceApp"
    assert dashboard_shell.props["currentPage"] == "dashboard"
    assert dashboard_shell.props["currentUser"]["username"] == context.current_user.username
    assert dashboard_shell.props["currentScope"]["currentWorkspace"]["slug"] == workspace.slug
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

  test "sign-in page routes password and magic-link flows through separate component targets", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/sign-in")
    html = render(view)

    password_target = form_target(html, "sign-in-password-form")
    magic_link_target = form_target(html, "sign-in-magic-link-form")

    refute is_nil(password_target)
    refute is_nil(magic_link_target)
    refute password_target == magic_link_target
  end

  test "auth forms expose shared hints and submit-state markup", %{conn: conn} do
    {:ok, sign_in, _html} = live(conn, ~p"/sign-in")
    sign_in_html = render(sign_in)

    assert has_element?(sign_in, ".ui-auth-form")
    assert sign_in_html =~ "Forgot password?"
    assert sign_in_html =~ "Send magic link"
    assert sign_in_html =~ "Password"
    assert sign_in_html =~ "Magic link"
    assert sign_in_html =~ ~s(phx-disable-with="Signing in...")
    assert sign_in_html =~ ~s(phx-disable-with="Sending link...")

    {:ok, register, _html} = live(conn, ~p"/register")
    register_html = render(register)

    assert register_html =~ "This becomes your workspace identifier."
    assert register_html =~ "At least 15 characters, or 8 with a number and letter."
    assert register_html =~ "Repeat the same password exactly."
    assert register_html =~ ~s(phx-disable-with="Creating account...")
  end

  test "registration succeeds, signs the user in, and sends confirmation email", %{conn: conn} do
    params = %{
      "email" => "register-live@example.com",
      "username" => "register-live-user",
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
    assert_workspace_shell_html(html_response(dashboard_conn, 200), "register-live-user")

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

    assert html =~ "Review the highlighted fields."
    assert html =~ "must"
    assert html =~ ~s(data-feedback="danger")
    assert html =~ ~s(role="alert")
    assert html =~ ~s(aria-invalid="true")
    assert html =~ ~s(aria-live="polite")
    assert html =~ ~r/aria-describedby="[^"]+-error"/
  end

  test "password sign-in succeeds from the custom page", %{conn: conn} do
    user = register_user(%{email: "signin-live@example.com", username: "signin-live-user"})
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
    assert_workspace_shell_html(html_response(dashboard_conn, 200), "signin-live-user")
  end

  test "invalid password sign-in stays on the page", %{conn: conn} do
    user = register_user(%{email: "bad-signin@example.com", username: "bad-signin"})
    flush_emails()

    {:ok, view, _html} = live(conn, ~p"/sign-in")

    html =
      view
      |> form("#sign-in-password-form",
        password_user: %{"email" => to_string(user.email), "password" => "wrong-password"}
      )
      |> render_submit()

    assert html =~ "Review the highlighted fields."
    assert html =~ ~s(data-feedback="danger")
    assert html =~ ~s(role="alert")
    assert html =~ ~s(aria-live="assertive")
  end

  test "password typing survives magic-link typing", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/sign-in")
    password_email = "retained-password@example.com"
    magic_email = "retained-magic@example.com"

    _ =
      view
      |> form("#sign-in-password-form",
        password_user: %{"email" => password_email, "password" => "supersecret123"}
      )
      |> render_change()

    _ =
      view
      |> form("#sign-in-magic-link-form", magic_link_user: %{"email" => magic_email})
      |> render_change()

    html = render(view)

    assert form_field_value(html, "sign-in-password-form", "password_user[email]") ==
             password_email

    assert form_field_value(html, "sign-in-magic-link-form", "magic_link_user[email]") ==
             magic_email
  end

  test "magic-link typing survives password typing", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/sign-in")
    magic_email = "keep-me@example.com"
    password_email = "password-owner@example.com"

    _ =
      view
      |> form("#sign-in-magic-link-form", magic_link_user: %{"email" => magic_email})
      |> render_change()

    _ =
      view
      |> form("#sign-in-password-form",
        password_user: %{"email" => password_email, "password" => "wrong-password"}
      )
      |> render_change()

    html = render(view)

    assert form_field_value(html, "sign-in-password-form", "password_user[email]") ==
             password_email

    assert form_field_value(html, "sign-in-magic-link-form", "magic_link_user[email]") ==
             magic_email
  end

  test "forgot password sends a reset email", %{conn: conn} do
    user = register_user(%{email: "reset-request@example.com", username: "reset-request"})
    flush_emails()

    {:ok, view, _html} = live(conn, ~p"/forgot-password")

    html =
      view
      |> form("#forgot-password-form", user: %{"email" => to_string(user.email)})
      |> render_submit()

    assert html =~ "Check your email"
    assert html =~ "We sent a link to reset your password."
    assert html =~ "Check spam if you don&#39;t see it."
    assert html =~ "so-alert-panel-success"
    assert html =~ "Return to sign in"
    refute html =~ ~s(id="flash-info")

    assert_received {:email, email}
    assert email.html_body =~ "/reset/"
  end

  test "magic-link request sends an email for an existing user", %{conn: conn} do
    user = register_user(%{email: "magic-link@example.com", username: "magic-link-user"})
    flush_emails()

    {:ok, view, _html} = live(conn, ~p"/sign-in")

    html =
      view
      |> form("#sign-in-magic-link-form", magic_link_user: %{"email" => to_string(user.email)})
      |> render_submit()

    assert html =~ "Request received."
    assert html =~ "If the account exists, a sign-in link is on the way."
    assert html =~ ~s(data-feedback="success")
    refute html =~ ~s(id="flash-info")

    assert_received {:email, email}
    assert email.html_body =~ "/magic_link/"
  end

  test "reset token flow updates the password and lands on the dashboard", %{conn: conn} do
    user = register_user(%{email: "reset-token@example.com", username: "reset-token-user"})
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
    assert_workspace_shell_html(html_response(dashboard_conn, 200), "reset-token-user")
  end

  test "confirmation token flow redirects to the dashboard", %{conn: conn} do
    _user = register_user(%{email: "confirm-token@example.com", username: "confirm-token-user"})
    confirm_token = extract_token_from_latest_email("confirm")

    {:ok, view, _html} = live(conn, "/confirm/#{confirm_token}")

    form = form(view, "#confirm-form", user: %{"confirm" => confirm_token})

    assert render_submit(form) =~ "phx-trigger-action"

    token_conn = follow_trigger_action(form, conn)
    assert redirected_to(token_conn) == "/dashboard"

    dashboard_conn = get(recycle(token_conn), ~p"/dashboard")
    assert_workspace_shell_html(html_response(dashboard_conn, 200), "confirm-token-user")
  end

  test "magic-link token flow redirects to the dashboard", %{conn: conn} do
    user = register_user(%{email: "magic-token@example.com", username: "magic-token-user"})
    flush_emails()

    EBoss.Accounts.request_magic_link!(%{email: user.email}, authorize?: false)
    magic_token = extract_token_from_latest_email("magic_link")

    {:ok, view, _html} = live(conn, "/magic_link/#{magic_token}")

    form = form(view, "#magic-link-form", user: %{"token" => magic_token})

    assert render_submit(form) =~ "phx-trigger-action"

    token_conn = follow_trigger_action(form, conn)
    assert redirected_to(token_conn) == "/dashboard"

    dashboard_conn = get(recycle(token_conn), ~p"/dashboard")
    assert_workspace_shell_html(html_response(dashboard_conn, 200), "magic-token-user")
  end

  test "logout clears the session and returns to the public flow", context do
    context = register_and_log_in_user(context)
    %{conn: conn} = context

    dashboard_conn = get(conn, ~p"/dashboard")
    assert_workspace_shell_html(html_response(dashboard_conn, 200), context.current_user.username)

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

  defp assert_workspace_shell_html(html, username) do
    assert html =~ ~s(data-shell-mode="workspace")
    assert html =~ ~s(data-name="ShellOperatorWorkspaceApp")
    assert html =~ username
    assert html =~ "currentScope"
  end

  defp assert_auth_shell(view) do
    assert has_element?(view, ".ui-shell[data-shell-mode='auth']")
    assert has_element?(view, ~s([data-testid="#{BrowserTestContracts.auth_shell()}"]))
    assert has_element?(view, ".ui-auth-shell__frame")
    assert has_element?(view, ".so-auth-page")

    assert has_element?(
             view,
             ~s(nav[aria-label="#{BrowserTestContracts.authentication_routes_nav_label()}"])
           )

    refute has_element?(view, "[data-public-shell-nav]")
    refute has_element?(view, "[data-public-shell-footer]")
  end

  defp form_target(html, form_id) do
    regex = ~r/id="#{Regex.escape(form_id)}"[^>]*phx-target="([^"]+)"/

    case Regex.run(regex, html, capture: :all_but_first) do
      [target] -> target
      _ -> nil
    end
  end

  defp form_field_value(html, form_id, field_name) do
    regex =
      ~r/id="#{Regex.escape(form_id)}".*?name="#{Regex.escape(field_name)}".*?value="([^"]*)"/s

    case Regex.run(regex, html, capture: :all_but_first) do
      [value] -> value
      _ -> nil
    end
  end
end
