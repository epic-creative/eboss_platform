defmodule EBoss.LogsTest do
  use EBoss.DataCase, async: false

  test "logs broadcast to pubsub and can be filtered by admins" do
    admin = admin_user()
    actor = register_user()
    organization = create_organization(admin, %{name: "Loggable"})

    :ok = EBoss.Logs.subscribe()

    assert {:ok, log} =
             EBoss.Logs.log(%{
               action: "organization.created",
               user: actor,
               org: organization,
               metadata: %{"source" => "test"}
             })

    assert_receive {:new_log, received_log}
    assert received_log.id == log.id

    assert {:ok, [filtered_log]} =
             EBoss.Logs.list_logs(%{action: "organization.created"}, actor: admin)

    assert filtered_log.id == log.id
  end

  test "non-admins cannot read logs and async logging still emits events" do
    user = register_user()

    assert {:error, error} = Ash.read(EBoss.Logs.Log, actor: user)
    assert Exception.message(error) =~ "forbidden"

    :ok = EBoss.Logs.subscribe()
    assert {:ok, pid} = EBoss.Logs.log_async(%{action: "user.login"})
    ref = Process.monitor(pid)
    assert_receive {:new_log, _log}
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
  end

  test "direct log creation remains forbidden outside the helper API" do
    assert {:error, error} =
             EBoss.Logs.Log
             |> Ash.Changeset.for_create(:create, %{action: "manual.log"})
             |> Ash.create()

    assert Exception.message(error) =~ "forbidden"
  end

  defp admin_user do
    user = register_user()

    user
    |> Ash.Changeset.for_update(:update, %{role: :admin})
    |> Ash.update!(authorize?: false)
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

  defp create_organization(actor, attrs) do
    EBoss.Organizations.Organization
    |> Ash.Changeset.for_create(:create, attrs, actor: actor)
    |> Ash.create!()
  end
end
