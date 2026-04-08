defmodule EBossWeb.DashboardLive do
  use EBossWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} current_user={@current_user}>
      <section class="space-y-8">
        <div class="space-y-3">
          <p class="text-xs font-semibold uppercase tracking-[0.28em] text-sky-700">
            Authenticated shell
          </p>
          <h1 class="text-4xl font-semibold tracking-tight text-stone-950">
            Welcome back, @{Map.get(@current_user, :username)}.
          </h1>
          <p class="max-w-3xl text-base leading-7 text-stone-600">
            This dashboard is intentionally lean. It confirms the session boundary, gives the authenticated user a stable landing page, and leaves room for workspace and Folio entry points.
          </p>
        </div>

        <div class="grid gap-8 lg:grid-cols-[1.1fr_0.9fr]">
          <div class="rounded-[2rem] border border-white/70 bg-white/85 p-4 shadow-[0_24px_80px_rgba(15,23,42,0.08)] backdrop-blur">
            <.DashboardLaunchpad
              username={Map.get(@current_user, :username)}
              email={to_string(Map.get(@current_user, :email))}
              workspaceLabel="Workspace routes and JSON:API are live"
              folioLabel="Folio remains workspace-scoped and boundary-driven"
            />
          </div>

          <div class="space-y-4 rounded-[2rem] border border-stone-200/80 bg-white/90 p-8 shadow-[0_24px_80px_rgba(15,23,42,0.08)]">
            <div class="space-y-2">
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-stone-500">
                Current account
              </p>
              <p class="text-2xl font-semibold text-stone-950">
                @{Map.get(@current_user, :username)}
              </p>
              <p class="text-sm text-stone-600">{to_string(Map.get(@current_user, :email))}</p>
            </div>

            <div class="rounded-[1.5rem] bg-stone-950 px-5 py-6 text-white">
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-amber-300">
                Next layer
              </p>
              <p class="mt-3 text-lg font-semibold">
                Attach workspaces, then bring Folio into the shell.
              </p>
              <p class="mt-2 text-sm leading-6 text-stone-300">
                This page is the authenticated anchor for the rest of the application. Everything else can grow outward from here.
              </p>
            </div>

            <form action={~p"/logout"} method="post">
              <input type="hidden" name="_method" value="delete" />
              <button
                type="submit"
                class="inline-flex items-center gap-2 rounded-full border border-stone-300 bg-white px-4 py-2 text-sm font-semibold text-stone-700 transition hover:border-stone-400 hover:text-stone-950"
              >
                <.icon name="hero-arrow-left-on-rectangle" class="size-4" /> Sign out
              </button>
            </form>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end
end
