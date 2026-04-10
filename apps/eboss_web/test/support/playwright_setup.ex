defmodule EBossWeb.PlaywrightSetup do
  @moduledoc false

  import Phoenix.ConnTest

  alias EBoss.Accounts
  alias EBoss.Repo
  alias EBossWeb.AuthForms

  @endpoint EBossWeb.Endpoint

  @default_base_url "http://localhost:4002"
  @default_email "playwright-auth@localhost"
  @default_username "playwright_auth_user"
  @default_password "playwright-pass-123"
  @default_state_dir Path.expand("../../assets/tests/playwright/.auth", __DIR__)
  @session_cookie_key "_eboss_web_key"

  def prepare!(opts \\ []) do
    state_dir = Keyword.get(opts, :state_dir, @default_state_dir)
    base_url = Keyword.get(opts, :base_url, default_base_url())
    credentials = browser_test_credentials()

    File.mkdir_p!(state_dir)

    user = ensure_browser_test_user!(credentials)

    public_storage_state_path = Path.join(state_dir, "public.json")
    authenticated_storage_state_path = Path.join(state_dir, "authenticated.json")
    metadata_path = Path.join(state_dir, "prepared-state.json")

    public_storage_state = %{cookies: [], origins: []}
    authenticated_storage_state = authenticated_storage_state!(credentials, base_url)

    write_json!(public_storage_state_path, public_storage_state)
    write_json!(authenticated_storage_state_path, authenticated_storage_state)

    metadata = %{
      base_url: base_url,
      storage_state: %{
        public: public_storage_state_path,
        authenticated: authenticated_storage_state_path
      },
      user: Map.take(credentials, [:email, :username])
    }

    write_json!(metadata_path, metadata)

    %{
      base_url: base_url,
      credentials: credentials,
      metadata_path: metadata_path,
      public_storage_state_path: public_storage_state_path,
      authenticated_storage_state_path: authenticated_storage_state_path,
      user: user
    }
  end

  def default_base_url do
    System.get_env("PLAYWRIGHT_BASE_URL") || @default_base_url
  end

  def browser_test_credentials do
    %{
      email: System.get_env("EBOSS_PLAYWRIGHT_EMAIL") || @default_email,
      username: System.get_env("EBOSS_PLAYWRIGHT_USERNAME") || @default_username,
      password: System.get_env("EBOSS_PLAYWRIGHT_PASSWORD") || @default_password
    }
  end

  defp ensure_browser_test_user!(credentials) do
    {:ok, hashed_password} = AshAuthentication.BcryptProvider.hash(credentials.password)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert_all(
      "users",
      [
        %{
          email: credentials.email,
          username: credentials.username,
          hashed_password: hashed_password,
          confirmed_at: now,
          role: "user",
          is_suspended: false,
          is_deleted: false,
          inserted_at: now,
          updated_at: now
        }
      ],
      conflict_target: :email,
      on_conflict: [
        set: [
          username: credentials.username,
          hashed_password: hashed_password,
          confirmed_at: now,
          role: "user",
          is_suspended: false,
          is_deleted: false,
          updated_at: now
        ]
      ]
    )

    Accounts.get_user_by_email!(credentials.email, authorize?: false)
  end

  defp authenticated_storage_state!(credentials, base_url) do
    signed_in_user =
      Accounts.sign_in_with_password!(
        %{email: credentials.email, password: credentials.password},
        authorize?: false
      )

    sign_in_path =
      Path.join([
        AuthForms.auth_routes_prefix(),
        AuthForms.subject_name_string(),
        "password",
        "sign_in_with_token"
      ])

    conn =
      build_conn()
      |> init_test_session(%{})
      |> dispatch(@endpoint, :get, sign_in_path, %{token: signed_in_user.__metadata__.token})

    conn
    |> Map.fetch!(:resp_cookies)
    |> Map.fetch!(@session_cookie_key)
    |> cookie_to_storage_state(base_url)
    |> then(fn cookie -> %{cookies: [cookie], origins: []} end)
  end

  defp cookie_to_storage_state(cookie, base_url) do
    uri = URI.parse(base_url)

    %{
      name: @session_cookie_key,
      value: cookie.value,
      domain: cookie[:domain] || uri.host || "localhost",
      path: cookie[:path] || "/",
      expires: cookie_expires(cookie),
      httpOnly: Map.get(cookie, :http_only, true),
      secure: Map.get(cookie, :secure, uri.scheme == "https"),
      sameSite: normalize_same_site(cookie[:same_site])
    }
  end

  defp cookie_expires(cookie) do
    cond do
      cookie[:max_age] ->
        DateTime.utc_now()
        |> DateTime.add(cookie.max_age, :second)
        |> DateTime.to_unix()

      true ->
        -1
    end
  end

  defp normalize_same_site(nil), do: "Lax"

  defp normalize_same_site(value) when is_atom(value),
    do: value |> Atom.to_string() |> String.capitalize()

  defp normalize_same_site(value) when is_binary(value), do: value

  defp write_json!(path, data) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(path, Jason.encode_to_iodata!(data, pretty: true))
  end
end
