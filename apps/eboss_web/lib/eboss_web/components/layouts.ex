defmodule EBossWeb.Layouts do
  @moduledoc """
  Layouts and shared application shell rendering.
  """

  use EBossWeb, :html

  alias EBossWeb.BrowserTestContracts

  embed_templates("layouts/*")

  attr(:flash, :map, required: true)

  attr(:current_scope, :map,
    default: nil,
    doc: "the current scope"
  )

  attr(:current_user, :map,
    default: nil,
    doc: "the authenticated user when present"
  )

  attr(:shell_mode, :string, values: ~w(product public), default: "product")
  attr(:current_path, :string, default: nil)

  slot(:inner_block, required: true)
  slot(:shell_footer)

  def app(assigns) do
    assigns =
      assigns
      |> assign(:public_shell?, assigns.shell_mode == "public" && is_nil(assigns.current_user))
      |> assign(
        :shell_mode_attr,
        if(assigns.shell_mode == "public", do: "public", else: "product")
      )

    ~H"""
    <div class="ui-shell" data-shell-mode={@shell_mode_attr}>
      <div class="ui-shell__topline" />
      <div class="ui-shell__inner">
        <header class="ui-shell-header" data-public-shell-header={@public_shell?}>
          <div class="ui-shell-header__inner">
            <%= if @public_shell? do %>
              <div class="ui-public-shell__masthead">
                <a href={~p"/"} class="ui-shell-brand">
                  <div class="ui-brand-mark">EB</div>
                  <div class="ui-shell-brand__lockup">
                    <p class="ui-kicker">EBoss Platform</p>
                    <p class="ui-text-body" data-size="sm" data-tone="soft">
                      Product-native access, recovery, and launch surfaces.
                    </p>
                  </div>
                </a>

                <.panel
                  as="div"
                  surface="solid"
                  padding="sm"
                  class="ui-public-shell__route-frame"
                >
                  <div class="ui-public-shell__route-meta">
                    <p class="ui-text-meta" data-tone="soft">Public routes</p>
                    <.badge tone="neutral">Shared shell</.badge>
                  </div>

                  <nav
                    class="ui-public-shell__nav"
                    aria-label={BrowserTestContracts.public_routes_nav_label()}
                    data-public-shell-nav
                  >
                    <.nav_pill to={~p"/"} active={public_nav_active?(:home, @current_path)}>
                      Home
                    </.nav_pill>
                    <.nav_pill to={~p"/sign-in"} active={public_nav_active?(:sign_in, @current_path)}>
                      Sign in
                    </.nav_pill>
                    <.nav_pill
                      to={~p"/register"}
                      active={public_nav_active?(:register, @current_path)}
                    >
                      Register
                    </.nav_pill>
                    <.nav_pill
                      to={~p"/forgot-password"}
                      active={public_nav_active?(:forgot_password, @current_path)}
                    >
                      Forgot password
                    </.nav_pill>
                  </nav>
                </.panel>
              </div>

              <div class="ui-public-shell__controls">
                <.theme_toggle />
                <.button
                  navigate={public_context_action(@current_path).to}
                  size="sm"
                  variant={public_context_action(@current_path).variant}
                  tone={public_context_action(@current_path).tone}
                  data-testid={BrowserTestContracts.public_shell_context_action()}
                >
                  {public_context_action(@current_path).label}
                </.button>
              </div>
            <% else %>
              <a href={~p"/"} class="ui-shell-brand">
                <div class="ui-brand-mark">EB</div>
                <div class="ui-shell-brand__lockup">
                  <p class="ui-kicker">EBoss Platform</p>
                  <p class="ui-text-body" data-size="sm" data-tone="soft">
                    Precision control for agent orchestration.
                  </p>
                </div>
              </a>

              <nav class="ui-control-cluster">
                <.theme_toggle />

                <%= if @current_user do %>
                  <.button navigate={~p"/dashboard"} variant="outline" tone="neutral" size="sm">
                    Dashboard
                  </.button>
                  <.badge tone="neutral" class="hidden sm:inline-flex">
                    @{Map.get(@current_user, :username)}
                  </.badge>
                  <form action={~p"/logout"} method="post">
                    <input type="hidden" name="_method" value="delete" />
                    <input
                      type="hidden"
                      name="_csrf_token"
                      value={Plug.CSRFProtection.get_csrf_token()}
                    />
                    <.button
                      type="submit"
                      tone="neutral"
                      size="sm"
                      icon="hero-arrow-left-on-rectangle"
                    >
                      Sign out
                    </.button>
                  </form>
                <% else %>
                  <.button navigate={~p"/sign-in"} variant="outline" tone="neutral" size="sm">
                    Sign in
                  </.button>
                  <.button navigate={~p"/register"} size="sm">
                    Create account
                  </.button>
                <% end %>
              </nav>
            <% end %>
          </div>
        </header>

        <main class="ui-shell-main">
          <div class="ui-shell-main__inner">
            {render_slot(@inner_block)}
          </div>
        </main>

        <section :if={@shell_footer != []} class="ui-shell-support">
          <div class="ui-shell-support__inner">
            {render_slot(@shell_footer)}
          </div>
        </section>

        <.public_footer :if={@public_shell?} current_path={@current_path} />

        <.flash_group flash={@flash} />
      </div>
    </div>
    """
  end

  attr(:flash, :map, required: true)
  attr(:id, :string, default: "flash-group")

  def flash_group(assigns) do
    ~H"""
    <div
      id={@id}
      aria-live="polite"
      class="pointer-events-none fixed inset-x-0 top-4 z-50 px-4 sm:px-6 lg:px-8"
    >
      <div class="mx-auto flex max-w-7xl justify-end">
        <div class="ui-toast-stack">
          <.flash kind={:info} flash={@flash} />
          <.flash kind={:error} flash={@flash} />

          <.flash
            id="client-error"
            kind={:error}
            title={gettext("We can't find the internet")}
            phx-disconnected={
              show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")
            }
            phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
            hidden
          >
            {gettext("Attempting to reconnect")}
            <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
          </.flash>

          <.flash
            id="server-error"
            kind={:error}
            title={gettext("Something went wrong!")}
            phx-disconnected={
              show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")
            }
            phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
            hidden
          >
            {gettext("Attempting to reconnect")}
            <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
          </.flash>
        </div>
      </div>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="ui-theme-toggle">
      <div class="ui-theme-toggle__indicator" />

      <button
        type="button"
        class="ui-theme-toggle__button"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        aria-label="Use system theme"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4" />
      </button>

      <button
        type="button"
        class="ui-theme-toggle__button"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        aria-label="Use light theme"
      >
        <.icon name="hero-sun-micro" class="size-4" />
      </button>

      <button
        type="button"
        class="ui-theme-toggle__button"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        aria-label="Use dark theme"
      >
        <.icon name="hero-moon-micro" class="size-4" />
      </button>
    </div>
    """
  end

  attr(:current_path, :string, default: nil)

  def public_footer(assigns) do
    ~H"""
    <footer
      class="ui-public-footer"
      aria-label={BrowserTestContracts.public_footer_label()}
      data-public-shell-footer
    >
      <div class="ui-public-footer__inner">
        <.panel surface="floating" padding="lg" class="ui-public-footer__frame">
          <div class="ui-public-footer__grid">
            <section class="space-y-4">
              <div class="space-y-3">
                <p class="ui-kicker" data-tone="primary">Public shell</p>
                <h2 class="ui-text-title" data-size="md">
                  One route family, one product frame.
                </h2>
                <p class="ui-text-body" data-tone="soft">
                  Navigation, auth entry, recovery, and the dashboard handoff all stay inside the same operator-grade shell.
                </p>
              </div>

              <div class="flex flex-wrap gap-2">
                <.badge tone="neutral">Shared panels</.badge>
                <.badge tone="neutral">Same tokens</.badge>
                <.badge tone="neutral">Direct dashboard handoff</.badge>
              </div>
            </section>

            <section class="space-y-4">
              <div class="space-y-2">
                <p class="ui-text-meta" data-tone="soft">Route family</p>
                <p class="ui-text-body" data-size="sm" data-tone="muted">
                  Public links stay close to the session boundary instead of drifting into a separate marketing shell.
                </p>
              </div>

              <div class="ui-public-footer__links">
                <a
                  :for={route <- public_footer_routes()}
                  href={route.to}
                  class="ui-public-footer__link"
                  data-active={to_string(public_nav_active?(route.key, @current_path))}
                >
                  <span class="ui-text-body" data-size="sm">{route.label}</span>
                  <span class="ui-text-body" data-size="sm" data-tone="muted">{route.copy}</span>
                </a>
              </div>
            </section>

            <section class="space-y-4">
              <div class="space-y-2">
                <p class="ui-text-meta" data-tone="soft">Shell posture</p>
                <p class="ui-text-body" data-size="sm" data-tone="muted">
                  Light and dark themes, default and compact density, and auth-state transitions all ride on the same system tokens.
                </p>
              </div>

              <div class="ui-public-footer__signals">
                <.panel
                  :for={signal <- public_shell_signals()}
                  as="div"
                  surface="solid"
                  padding="sm"
                  class="ui-public-footer__signal"
                >
                  <p class="ui-text-meta" data-tone="soft">{signal.title}</p>
                  <p class="ui-text-body" data-size="sm" data-tone="muted">{signal.copy}</p>
                </.panel>
              </div>
            </section>
          </div>
        </.panel>
      </div>
    </footer>
    """
  end

  attr(:eyebrow, :string, required: true)
  attr(:title, :string, required: true)
  attr(:subtitle, :string, required: true)
  attr(:primary_label, :string, required: true)
  attr(:primary_to, :string, required: true)
  attr(:secondary_label, :string, default: nil)
  attr(:secondary_to, :string, default: nil)
  attr(:section_pattern, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:details)

  def public_cta_frame(assigns) do
    ~H"""
    <.panel
      surface="floating"
      padding="lg"
      class={["ui-public-cta", @class]}
      data-public-cta-frame
      data-public-section-pattern={@section_pattern}
    >
      <div class="ui-public-cta__copy">
        <p class="ui-kicker" data-tone="primary">{@eyebrow}</p>
        <h2 class="ui-section-header__title" data-size="md">{@title}</h2>
        <p class="ui-section-header__subtitle">{@subtitle}</p>
      </div>

      <div class="ui-public-cta__actions">
        <.button navigate={@primary_to} size="lg">{@primary_label}</.button>
        <.button
          :if={@secondary_label && @secondary_to}
          navigate={@secondary_to}
          variant="outline"
          tone="neutral"
          size="lg"
        >
          {@secondary_label}
        </.button>
      </div>

      <div :if={@details != []} class="ui-public-cta__details">
        {render_slot(@details)}
      </div>
    </.panel>
    """
  end

  defp public_context_action(current_path) do
    case current_path do
      "/register" ->
        %{label: "Sign in", to: ~p"/sign-in", variant: "outline", tone: "neutral"}

      "/forgot-password" ->
        %{label: "Sign in", to: ~p"/sign-in", variant: "outline", tone: "neutral"}

      "/reset" ->
        %{
          label: "Request another link",
          to: ~p"/forgot-password",
          variant: "outline",
          tone: "neutral"
        }

      "/confirm" ->
        %{label: "Sign in", to: ~p"/sign-in", variant: "outline", tone: "neutral"}

      "/magic-link" ->
        %{label: "Sign in", to: ~p"/sign-in", variant: "outline", tone: "neutral"}

      _ ->
        %{label: "Create account", to: ~p"/register", variant: "solid", tone: "primary"}
    end
  end

  defp public_nav_active?(:home, current_path), do: current_path == "/"

  defp public_nav_active?(:sign_in, current_path),
    do: current_path in ["/sign-in", "/confirm", "/magic-link"]

  defp public_nav_active?(:register, current_path), do: current_path == "/register"

  defp public_nav_active?(:forgot_password, current_path),
    do: current_path in ["/forgot-password", "/reset"]

  defp public_footer_routes do
    [
      %{key: :home, label: "Home", to: ~p"/", copy: "Overview and launch surface"},
      %{
        key: :sign_in,
        label: "Sign in",
        to: ~p"/sign-in",
        copy: "Password and magic-link access"
      },
      %{key: :register, label: "Register", to: ~p"/register", copy: "First-party account setup"},
      %{
        key: :forgot_password,
        label: "Forgot password",
        to: ~p"/forgot-password",
        copy: "Recovery without leaving the shell"
      }
    ]
  end

  defp public_shell_signals do
    [
      %{
        title: "Same materials",
        copy:
          "Header, auth cards, CTA framing, and footer panels all use the shared shell surface stack."
      },
      %{
        title: "Theme parity",
        copy:
          "The public frame follows the same light and dark theme toggle used across the rest of the product."
      },
      %{
        title: "Density-safe rhythm",
        copy:
          "Shell spacing compresses with the shared compact density tokens instead of fragmenting route by route."
      }
    ]
  end
end
