defmodule EBossWeb.Router do
  use EBossWeb, :router
  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EBossWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]

    plug AshAuthentication.Strategy.ApiKey.Plug,
      resource: EBoss.Accounts.User,
      required?: false

    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/", EBossWeb do
    pipe_through :browser

    get "/", PageController, :home

    sign_out_route(AuthController, "/logout")

    reset_route(auth_routes_prefix: "/auth", path: "/reset")

    confirm_route(EBoss.Accounts.User, :confirm_new_user,
      path: "/confirm",
      auth_routes_prefix: "/auth"
    )

    magic_sign_in_route(EBoss.Accounts.User, :magic_link,
      path: "/magic_link",
      auth_routes_prefix: "/auth"
    )

    auth_routes(AuthController, EBoss.Accounts.User, path: "/auth")
  end

  # Other scopes may use custom stacks.
  # scope "/api", EBossWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:eboss_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EBossWeb.Telemetry
      live "/live_vue", EBossWeb.LiveVueDemoLive
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
