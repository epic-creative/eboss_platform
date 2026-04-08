defmodule EBossWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use EBossWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate
  @endpoint EBossWeb.Endpoint
  using do
    quote do
      # The default endpoint for testing
      @endpoint EBossWeb.Endpoint

      use EBossWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import EBossWeb.ConnCase
    end
  end

  setup tags do
    EBoss.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def register_user(overrides \\ %{}) do
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

    EBoss.Accounts.register_with_password!(params, authorize?: false)
  end

  def log_in_user(%{conn: conn} = context, user) do
    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Phoenix.ConnTest.dispatch(
        @endpoint,
        :get,
        "/auth/user/password/sign_in_with_token",
        %{token: user.__metadata__.token}
      )
      |> Phoenix.ConnTest.recycle()

    Map.put(context, :conn, conn)
  end

  def register_and_log_in_user(context, overrides \\ %{}) do
    strategy = AshAuthentication.Info.strategy!(EBoss.Accounts.User, :password)

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

    {:ok, user} =
      AshAuthentication.Strategy.action(strategy, :register, params,
        context: %{token_type: :sign_in, private: %{ash_authentication?: true}}
      )

    Map.put(log_in_user(context, user), :current_user, user)
  end
end
