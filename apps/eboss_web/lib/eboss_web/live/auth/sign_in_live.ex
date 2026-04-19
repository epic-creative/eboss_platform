defmodule EBossWeb.Auth.SignInLive do
  use EBossWeb, :live_view

  alias EBossWeb.Auth.{MagicLinkRequestComponent, PasswordSignInComponent}
  alias EBossWeb.AuthComponents
  import AuthComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sign in")
     |> assign(:mode, "password")}
  end

  @impl true
  def handle_event("set_mode", %{"mode" => mode}, socket) when mode in ["password", "magic"] do
    {:noreply, assign(socket, :mode, mode)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={assigns[:current_user]}
      shell_mode="workspace"
      current_path="/sign-in"
    >
      <.auth_shell current_path="/sign-in">
        <.auth_page title="Sign in to EBoss" subtitle="Enter your workspace">
          <section class="so-auth-card">
            <div class="flex border-b border-[hsl(var(--so-border))] px-1 pt-1">
              <button
                type="button"
                phx-click="set_mode"
                phx-value-mode="password"
                class="so-underline-tab flex-1 justify-center text-xs"
                data-active={@mode == "password"}
              >
                Password
              </button>
              <button
                type="button"
                phx-click="set_mode"
                phx-value-mode="magic"
                class="so-underline-tab flex-1 justify-center text-xs"
                data-active={@mode == "magic"}
              >
                Magic link
              </button>
            </div>

            <div class="p-4">
              <div
                class={if(@mode == "password", do: "block", else: "hidden")}
                data-sign-in-panel="password"
              >
                <.live_component
                  module={PasswordSignInComponent}
                  id="password-sign-in"
                  compact
                />
              </div>

              <div
                class={if(@mode == "magic", do: "block", else: "hidden")}
                data-sign-in-panel="magic"
              >
                <.live_component
                  module={MagicLinkRequestComponent}
                  id="magic-link-request"
                  compact
                />
              </div>
            </div>
          </section>

          <:footer>
            <.auth_page_footer
              prompt="New to EBoss?"
              link_text="Create an account"
              link_href={~p"/register"}
            />
          </:footer>
        </.auth_page>
      </.auth_shell>
    </Layouts.app>
    """
  end
end
