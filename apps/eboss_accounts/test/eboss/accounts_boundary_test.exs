defmodule EBoss.AccountsBoundaryTest do
  use EBoss.DataCase, async: false

  import Swoosh.TestAssertions

  alias EBoss.Accounts

  @moduletag :boundary

  setup :set_swoosh_global

  test "registration, lookup, and password sign-in go through the accounts boundary" do
    user =
      Accounts.register_with_password!(
        %{
          email: unique_email(),
          username: "Case_User",
          password: password(),
          password_confirmation: password()
        },
        authorize?: false
      )

    assert user.username == "case_user"

    assert_received {:email, email}
    assert email.subject == "Confirm your email address"

    assert Accounts.get_user!(user.id, actor: user).id == user.id
    assert Accounts.get_user_by_email!(user.email, actor: user).id == user.id
    assert Accounts.get_user_by_username!(user.username, actor: user).id == user.id

    signed_in_user =
      Accounts.sign_in_with_password!(%{
        email: user.email,
        password: password()
      })

    assert signed_in_user.id == user.id
  end

  test "magic link and password reset requests go through the accounts boundary" do
    user = register_user()
    flush_emails()

    assert :ok = Accounts.request_password_reset_token!(%{email: user.email})

    assert_received {:email, reset_email}
    assert reset_email.subject == "Reset your password"
    assert reset_email.html_body =~ "/reset/"

    magic_email = unique_email()
    flush_emails()

    assert :ok = Accounts.request_magic_link!(%{email: magic_email})

    assert_received {:email, magic_link_email}
    assert magic_link_email.subject == "Your login link"
    assert magic_link_email.html_body =~ "/magic_link/"
  end

  test "admin lifecycle actions go through the accounts boundary" do
    admin = register_user() |> promote_to_admin()
    user = register_user()

    visible_users = Accounts.list_users!(actor: admin, page: [limit: 50])
    visible_user_ids = Enum.map(visible_users.results, & &1.id)

    assert admin.id in visible_user_ids
    assert user.id in visible_user_ids

    suspended_user = Accounts.suspend_user!(user, actor: admin)
    assert suspended_user.is_suspended

    restored_user = Accounts.undo_suspend_user!(suspended_user, actor: admin)
    refute restored_user.is_suspended

    renamed_user =
      Accounts.admin_update_user!(restored_user, %{username: "boundary_user"}, actor: admin)

    assert renamed_user.username == "boundary_user"
    assert Accounts.get_user_by_username!("boundary_user", actor: admin).id == user.id

    deleted_user = Accounts.soft_delete_user!(renamed_user, actor: admin)
    assert deleted_user.is_deleted

    undeleted_user = Accounts.undo_delete_user!(deleted_user, actor: admin)
    refute undeleted_user.is_deleted
  end

  test "non-bang boundary functions return expected tuples" do
    admin = register_user() |> promote_to_admin()

    assert {:ok, user} =
             Accounts.register_with_password(
               %{
                 email: unique_email(),
                 username: "Boundary_User",
                 password: password(),
                 password_confirmation: password()
               },
               authorize?: false
             )

    assert {:ok, fetched_user} = Accounts.get_user(user.id, actor: user)
    assert fetched_user.id == user.id

    assert {:ok, fetched_by_email} = Accounts.get_user_by_email(user.email, actor: user)
    assert fetched_by_email.id == user.id

    assert {:ok, fetched_by_username} = Accounts.get_user_by_username(user.username, actor: user)
    assert fetched_by_username.id == user.id

    assert {:ok, signed_in_user} =
             Accounts.sign_in_with_password(%{email: user.email, password: password()})

    assert signed_in_user.id == user.id

    sign_in_token_user =
      Accounts.sign_in_with_password!(%{email: user.email, password: password()},
        context: %{token_type: :sign_in}
      )

    assert {:ok, token_signed_in_user} =
             Accounts.sign_in_with_token(sign_in_token_user.__metadata__.token)

    assert token_signed_in_user.id == user.id

    assert :ok = Accounts.request_magic_link(%{email: user.email})
    assert :ok = Accounts.request_password_reset_token(%{email: user.email})

    assert {:ok, changed_user} =
             Accounts.change_password(
               user,
               %{
                 current_password: password(),
                 password: "brandnewsecret123",
                 password_confirmation: "brandnewsecret123"
               },
               actor: user
             )

    assert changed_user.id == user.id

    api_key =
      EBoss.Accounts.ApiKey
      |> Ash.Changeset.for_create(:create, %{
        user_id: user.id,
        expires_at: DateTime.add(DateTime.utc_now(), 3_600, :second)
      })
      |> Ash.create!(authorize?: false)

    assert {:ok, api_key_user} =
             Accounts.sign_in_with_api_key(api_key.__metadata__.plaintext_api_key)

    assert api_key_user.id == user.id
    assert Accounts.sign_in_with_api_key!(api_key.__metadata__.plaintext_api_key).id == user.id

    invalid_token = signed_in_user.__metadata__.token

    assert {:error, _error} = Accounts.sign_in_with_token(invalid_token)

    sign_in_token_user =
      Accounts.sign_in_with_password!(%{email: user.email, password: "brandnewsecret123"},
        context: %{token_type: :sign_in}
      )

    assert Accounts.sign_in_with_token!(sign_in_token_user.__metadata__.token).id == user.id

    assert {:ok, visible_users} = Accounts.list_users(actor: admin, page: [limit: 50])
    assert Enum.any?(visible_users.results, &(&1.id == user.id))

    assert {:ok, suspended_user} = Accounts.suspend_user(user, actor: admin)
    assert suspended_user.is_suspended

    assert {:ok, restored_user} = Accounts.undo_suspend_user(suspended_user, actor: admin)
    refute restored_user.is_suspended

    assert {:ok, renamed_user} =
             Accounts.admin_update_user(restored_user, %{username: "boundary_user_2"},
               actor: admin
             )

    assert renamed_user.username == "boundary_user_2"

    assert {:ok, deleted_user} = Accounts.soft_delete_user(renamed_user, actor: admin)
    assert deleted_user.is_deleted

    assert {:ok, undeleted_user} = Accounts.undo_delete_user(deleted_user, actor: admin)
    refute undeleted_user.is_deleted
  end

  test "bang boundary functions raise on invalid inputs" do
    admin = register_user() |> promote_to_admin()
    user = register_user()

    assert_raise Ash.Error.Invalid, fn ->
      Accounts.register_with_password!(
        %{
          email: unique_email(),
          username: user.username,
          password: password(),
          password_confirmation: password()
        },
        authorize?: false
      )
    end

    assert_raise Ash.Error.Forbidden, fn ->
      Accounts.sign_in_with_password!(%{email: user.email, password: "wrong-password"})
    end

    assert_raise Ash.Error.Forbidden, fn ->
      Accounts.sign_in_with_token!(
        Accounts.sign_in_with_password!(%{email: user.email, password: password()}).__metadata__.token
      )
    end

    assert_raise Ash.Error.Forbidden, fn ->
      Accounts.change_password!(
        user,
        %{
          current_password: "not-the-current-password",
          password: "brandnewsecret123",
          password_confirmation: "brandnewsecret123"
        },
        actor: user
      )
    end

    assert_raise Ash.Error.Invalid, fn ->
      Accounts.get_user!(Ecto.UUID.generate(), actor: user)
    end

    assert_raise Ash.Error.Invalid, fn ->
      Accounts.get_user_by_email!(nil, actor: admin)
    end

    assert_raise Ash.Error.Invalid, fn ->
      Accounts.get_user_by_username!(nil, actor: admin)
    end

    assert_raise FunctionClauseError, fn ->
      Accounts.sign_in_with_api_key!(nil)
    end
  end

  test "default-argument wrappers and authentication context merging are exercised" do
    assert {:ok, user} =
             Accounts.register_with_password(%{
               email: unique_email(),
               username: "defaults_user",
               password: password(),
               password_confirmation: password()
             })

    assert {:error, _error} = Accounts.get_user(user.id)
    assert_raise Ash.Error.Forbidden, fn -> Accounts.get_user!(user.id) end

    assert {:error, _error} = Accounts.get_user_by_email("missing@example.com")

    assert_raise Ash.Error.Forbidden, fn ->
      Accounts.get_user_by_email!("missing@example.com")
    end

    assert {:error, _error} = Accounts.get_user_by_username("missing_user_name")

    assert_raise Ash.Error.Forbidden, fn ->
      Accounts.get_user_by_username!("missing_user_name")
    end

    assert :ok =
             Accounts.request_magic_link(%{email: user.email},
               context: %{private: %{ash_authentication?: true, custom_flag: true}}
             )
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

    Accounts.register_with_password!(params, authorize?: false)
  end

  defp promote_to_admin(user) do
    user
    |> Ash.Changeset.for_update(:update, %{role: :admin})
    |> Ash.update!(authorize?: false)
  end

  defp unique_email do
    "user#{System.unique_integer([:positive])}@example.com"
  end

  defp password, do: "supersecret123"

  defp flush_emails do
    receive do
      {:email, _email} -> flush_emails()
    after
      0 -> :ok
    end
  end
end
