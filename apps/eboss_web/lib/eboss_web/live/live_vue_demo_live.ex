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
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={assigns[:current_user]}
    >
      <div class="space-y-6">
        <.section_heading
          eyebrow="Development surface"
          title="LiveVue is active in `eboss_web`"
          subtitle="Visit this page in development to confirm Vite, LiveView, and Vue component mounting are all functioning together."
          title_size="lg"
        />

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
