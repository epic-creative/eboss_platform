defmodule EBossWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use EBossWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :current_user, :map,
    default: nil,
    doc: "the authenticated user when present"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="relative min-h-screen overflow-hidden bg-stone-950 text-stone-900">
      <div class="absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(251,191,36,0.16),_transparent_32%),radial-gradient(circle_at_bottom_right,_rgba(14,165,233,0.16),_transparent_26%),linear-gradient(180deg,_#f8fafc_0%,_#f5f5f4_46%,_#f8fafc_100%)]" />
      <div class="absolute inset-x-0 top-0 h-px bg-white/70" />

      <div class="relative">
        <header class="border-b border-stone-200/70 bg-white/70 backdrop-blur">
          <div class="mx-auto flex max-w-7xl items-center justify-between gap-4 px-4 py-4 sm:px-6 lg:px-8">
            <a href={~p"/"} class="flex items-center gap-3">
              <div class="flex size-11 items-center justify-center rounded-2xl bg-stone-950 text-sm font-semibold text-white shadow-sm">
                EB
              </div>
              <div class="space-y-1">
                <p class="text-[0.7rem] font-semibold uppercase tracking-[0.28em] text-amber-600">
                  EBoss Platform
                </p>
                <p class="text-sm font-medium text-stone-600">Operations calm for a growing system</p>
              </div>
            </a>

            <nav class="flex items-center gap-3 text-sm">
              <.theme_toggle />

              <%= if @current_user do %>
                <a
                  href={~p"/dashboard"}
                  class="rounded-full border border-stone-300 bg-white px-4 py-2 font-medium text-stone-700 transition hover:border-stone-400 hover:text-stone-950"
                >
                  Dashboard
                </a>
                <div class="hidden rounded-full border border-stone-200 bg-stone-100 px-4 py-2 text-stone-600 sm:block">
                  @{Map.get(@current_user, :username)}
                </div>
                <form action={~p"/logout"} method="post">
                  <input type="hidden" name="_method" value="delete" />
                  <button
                    type="submit"
                    class="rounded-full bg-stone-950 px-4 py-2 font-medium text-white transition hover:bg-stone-800"
                  >
                    Sign out
                  </button>
                </form>
              <% else %>
                <a
                  href={~p"/sign-in"}
                  class="rounded-full border border-stone-300 bg-white px-4 py-2 font-medium text-stone-700 transition hover:border-stone-400 hover:text-stone-950"
                >
                  Sign in
                </a>
                <a
                  href={~p"/register"}
                  class="rounded-full bg-stone-950 px-4 py-2 font-medium text-white transition hover:bg-stone-800"
                >
                  Create account
                </a>
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

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
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
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center rounded-full border border-stone-300 bg-white p-1 shadow-sm">
      <div class="absolute left-1 h-9 w-9 rounded-full bg-stone-950/6 transition-[left] [[data-theme=light]_&]:left-10 [[data-theme=dark]_&]:left-[4.75rem]" />

      <button
        class="relative z-10 flex h-9 w-9 items-center justify-center rounded-full text-stone-500 transition hover:text-stone-950"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4" />
      </button>

      <button
        class="relative z-10 flex h-9 w-9 items-center justify-center rounded-full text-stone-500 transition hover:text-stone-950"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4" />
      </button>

      <button
        class="relative z-10 flex h-9 w-9 items-center justify-center rounded-full text-stone-500 transition hover:text-stone-950"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4" />
      </button>
    </div>
    """
  end
end
