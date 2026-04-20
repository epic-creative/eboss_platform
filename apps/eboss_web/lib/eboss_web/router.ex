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
    plug :load_from_session, otp_app: :eboss_accounts
  end

  pipeline :api do
    plug :accepts, ["json", "json-api"]

    plug AshAuthentication.Strategy.ApiKey.Plug,
      resource: EBoss.Accounts.User,
      required?: false

    plug :load_from_bearer, otp_app: :eboss_accounts
    plug :set_actor, :user
  end

  scope "/", EBossWeb do
    pipe_through :browser

    sign_out_route(AuthController, "/logout")

    auth_routes(AuthController, EBoss.Accounts.User, path: "/auth")

    ash_authentication_live_session :public_routes,
      otp_app: :eboss_accounts,
      on_mount: {EBossWeb.LiveUserAuth, :live_user_optional} do
      live "/", HomeLive
      live "/reset/:token", Auth.ResetPasswordLive
      live "/confirm/:token", Auth.ConfirmLive
      live "/magic_link/:token", Auth.MagicLinkLive
    end

    ash_authentication_live_session :anonymous_routes,
      otp_app: :eboss_accounts,
      on_mount: {EBossWeb.LiveUserAuth, :live_no_user} do
      live "/sign-in", Auth.SignInLive
      live "/register", Auth.RegisterLive
      live "/forgot-password", Auth.ForgotPasswordLive
    end

    ash_authentication_live_session :authenticated_routes,
      otp_app: :eboss_accounts,
      on_mount: {EBossWeb.LiveUserAuth, :live_user_required} do
      live "/dashboard", DashboardRedirectLive
    end
  end

  # Other scopes may use custom stacks.
  scope "/api/v1" do
    pipe_through :browser

    forward "/swaggerui", OpenApiSpex.Plug.SwaggerUI,
      path: "/api/v1/open_api",
      default_model_expand_depth: 4
  end

  scope "/api/v1", EBossWeb do
    pipe_through :api

    get "/open_api", OpenApiController, :show

    get "/:owner_slug/workspaces/:slug/bootstrap", WorkspaceBootstrapController, :show
    get "/:owner_slug/workspaces/:slug/apps/folio/bootstrap", FolioBootstrapController, :show

    post "/:owner_slug/workspaces/:slug/apps/folio/projects",
         FolioBootstrapController,
         :create_project

    patch "/:owner_slug/workspaces/:slug/apps/folio/projects/:project_id",
          FolioBootstrapController,
          :update_project

    patch "/:owner_slug/workspaces/:slug/apps/folio/tasks/:task_id",
          FolioBootstrapController,
          :update_task

    get "/:owner_slug/workspaces/:slug/apps/folio/projects", FolioBootstrapController, :projects
    post "/:owner_slug/workspaces/:slug/apps/folio/tasks", FolioBootstrapController, :create_task
    get "/:owner_slug/workspaces/:slug/apps/folio/tasks", FolioBootstrapController, :tasks
    get "/:owner_slug/workspaces/:slug/apps/folio/activity", FolioBootstrapController, :activity
    forward "/", JsonApiRouter
  end

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
      live "/design-system", EBossWeb.Dev.DesignSystemLive
      live "/live_vue", EBossWeb.LiveVueDemoLive
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", EBossWeb do
    pipe_through :browser

    ash_authentication_live_session :canonical_workspace_routes,
      otp_app: :eboss_accounts,
      on_mount: {EBossWeb.LiveUserAuth, :live_user_required} do
      live "/:owner_slug/:workspace_slug", DashboardLive, :workspace_root
      live "/:owner_slug/:workspace_slug/apps/:app_key", DashboardLive, :workspace_app

      live "/:owner_slug/:workspace_slug/apps/:app_key/:app_surface",
           DashboardLive,
           :workspace_app

      live "/:owner_slug/:workspace_slug/:workspace_surface", DashboardLive, :workspace_surface
    end
  end
end
