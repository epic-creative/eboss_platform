defmodule EBossWeb.LiveVueDemoLive do
  use EBossWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       count: 2,
       headline: "LiveVue + Vite are wired up",
       page_title: "LiveVue Demo",
       subhead:
         "This page verifies the new frontend baseline in eboss_web before we layer on the API surface."
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-secondary">
            Development Surface
          </p>
          <h1 class="text-4xl font-semibold tracking-tight">LiveVue is active in `eboss_web`</h1>
          <p class="max-w-3xl text-sm leading-6 text-base-content/70">
            Visit this page in development to confirm Vite, LiveView, and Vue component mounting are all functioning together.
          </p>
        </div>

        <.LiveVueDemo
          count={@count}
          headline={@headline}
          subhead={@subhead}
          v-socket={@socket}
        />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply, assign(socket, :count, 0)}
  end
end
