defmodule EBossWeb.HomeLive do
  use EBossWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "EBoss")

    if socket.assigns.current_user do
      {:ok, redirect(socket, to: ~p"/dashboard")}
    else
      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} current_user={@current_user}>
      <section class="grid gap-10 lg:grid-cols-[1.15fr_0.85fr] lg:items-center">
        <div class="space-y-8">
          <div class="space-y-4">
            <p class="text-xs font-semibold uppercase tracking-[0.28em] text-amber-700">
              Workspace-native operations
            </p>
            <h1 class="max-w-4xl text-5xl font-semibold tracking-tight text-stone-950 sm:text-6xl">
              Keep the platform sharp while the domains grow.
            </h1>
            <p class="max-w-2xl text-lg leading-8 text-stone-600">
              EBoss gives your workspaces, planning domains, and integrations one steady control surface without turning the codebase into a tangle.
            </p>
          </div>

          <div class="flex flex-wrap gap-4">
            <a
              href={~p"/register"}
              class="rounded-full bg-stone-950 px-6 py-3 text-sm font-semibold text-white transition hover:bg-stone-800"
            >
              Create your account
            </a>
            <a
              href={~p"/sign-in"}
              class="rounded-full border border-stone-300 bg-white px-6 py-3 text-sm font-semibold text-stone-700 transition hover:border-stone-400 hover:text-stone-950"
            >
              Sign in
            </a>
          </div>

          <dl class="grid gap-4 sm:grid-cols-3">
            <div class="rounded-[1.75rem] border border-white/80 bg-white/80 p-5 shadow-sm">
              <dt class="text-xs font-semibold uppercase tracking-[0.24em] text-stone-500">
                Identity
              </dt>
              <dd class="mt-3 text-sm leading-6 text-stone-700">
                Email confirmation, magic links, and password flows stay on AshAuthentication’s happy path.
              </dd>
            </div>
            <div class="rounded-[1.75rem] border border-white/80 bg-white/80 p-5 shadow-sm">
              <dt class="text-xs font-semibold uppercase tracking-[0.24em] text-stone-500">
                Workspaces
              </dt>
              <dd class="mt-3 text-sm leading-6 text-stone-700">
                Owner-aware routing and API-ready boundaries are already in place for the larger application to come.
              </dd>
            </div>
            <div class="rounded-[1.75rem] border border-white/80 bg-white/80 p-5 shadow-sm">
              <dt class="text-xs font-semibold uppercase tracking-[0.24em] text-stone-500">Folio</dt>
              <dd class="mt-3 text-sm leading-6 text-stone-700">
                Planning primitives, audit history, and strict workspace scoping are ready for the next layer.
              </dd>
            </div>
          </dl>
        </div>

        <div class="rounded-[2rem] border border-white/70 bg-white/80 p-4 shadow-[0_24px_80px_rgba(15,23,42,0.08)] backdrop-blur">
          <.AuthScene
            eyebrow="Authentication foundation"
            title="Custom pages, standard auth engine"
            subtitle="The web layer stays first-party and branded while Ash handles strategy rules, token lifecycles, and sessions."
            detailOne="Custom LiveView pages with LiveVue-backed presentation"
            detailTwo="Password, reset, confirm, and magic-link flows on existing auth routes"
            detailThree="A private dashboard gate for authenticated users only"
          />
        </div>
      </section>
    </Layouts.app>
    """
  end
end
