defmodule EBossWeb.Layouts do
  @moduledoc """
  Layouts and shared application shell rendering.
  """

  use EBossWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true

  attr :current_scope, :map,
    default: nil,
    doc: "the current scope"

  attr :current_user, :map,
    default: nil,
    doc: "the authenticated user when present"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="ui-shell">
      <div class="ui-shell__topline" />
      <div class="ui-shell__inner">
        <header class="ui-shell-header">
          <div class="mx-auto flex max-w-7xl items-center justify-between gap-4 px-4 py-4 sm:px-6 lg:px-8">
            <a href={~p"/"} class="flex items-center gap-3">
              <div class="ui-brand-mark">EB</div>
              <div class="space-y-1">
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
                <.badge tone="primary" class="hidden sm:inline-flex">
                  @{Map.get(@current_user, :username)}
                </.badge>
                <form action={~p"/logout"} method="post">
                  <input type="hidden" name="_method" value="delete" />
                  <.button type="submit" tone="neutral" size="sm" icon="hero-arrow-left-on-rectangle">
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
          </div>
        </header>

        <main class="px-4 py-10 sm:px-6 lg:px-8">
          <div class="mx-auto max-w-7xl">
            {render_slot(@inner_block)}
          </div>
        </main>

        <.flash_group flash={@flash} />
      </div>
    </div>
    """
  end

  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

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
end
