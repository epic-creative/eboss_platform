defmodule EBossWeb.AuthComponents do
  @moduledoc false
  use EBossWeb, :html

  alias AshPhoenix.Form
  alias EBossWeb.BrowserTestContracts

  attr :current_path, :string, required: true
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def auth_shell(assigns) do
    ~H"""
    <div
      class={[
        "so-theme so-auth-shell so-auth-surface flex min-h-screen flex-col text-[hsl(var(--so-foreground))]",
        @class
      ]}
      data-auth-shell
      data-testid={BrowserTestContracts.auth_shell()}
    >
      <header class="so-header-bar border-b border-[hsl(var(--so-header-border))]">
        <div class="mx-auto flex h-12 w-full max-w-7xl items-center px-4 sm:px-6 lg:px-8">
          <a href={~p"/"} class="flex shrink-0 items-center gap-2">
            <div class="flex h-6 w-6 items-center justify-center rounded bg-[hsl(var(--so-header-foreground))]">
              <span class="so-font-mono text-[10px] font-bold text-[hsl(var(--so-header-bg))]">
                E
              </span>
            </div>
            <span class="text-sm font-semibold text-[hsl(var(--so-header-foreground))]">EBoss</span>
          </a>

          <div class="ml-4 hidden items-center gap-1.5 text-xs sm:flex">
            <span class="text-[hsl(var(--so-header-muted))]">/</span>
            <span class="so-font-mono text-[hsl(var(--so-header-muted))]">
              {auth_route_label(@current_path)}
            </span>
          </div>

          <div class="ml-auto flex items-center gap-2">
            <.ThemeToggleButton />
          </div>
        </div>
      </header>

      <main class="flex flex-1 items-start justify-center px-4 pb-16 pt-16">
        <div class="w-full max-w-[360px]">
          {render_slot(@inner_block)}
        </div>
      </main>

      <footer class="border-t border-[hsl(var(--so-border))] py-4">
        <div class="mx-auto flex max-w-7xl items-center justify-center gap-6 px-4 sm:px-6 lg:px-8">
          <a
            href="#"
            class="text-xs text-[hsl(var(--so-muted-foreground))] transition-colors hover:text-[hsl(var(--so-foreground))]"
          >
            Terms
          </a>
          <a
            href="#"
            class="text-xs text-[hsl(var(--so-muted-foreground))] transition-colors hover:text-[hsl(var(--so-foreground))]"
          >
            Privacy
          </a>
          <a
            href="mailto:support@eboss.dev"
            class="text-xs text-[hsl(var(--so-muted-foreground))] transition-colors hover:text-[hsl(var(--so-foreground))]"
          >
            Contact
          </a>
        </div>
      </footer>
    </div>
    """
  end

  attr :eyebrow, :string, default: nil
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :class, :any, default: nil
  slot :inner_block, required: true
  slot :footer

  def auth_page(assigns) do
    ~H"""
    <div class={["ui-auth-page so-auth-page", @class]}>
      <header class="mb-6 text-center">
        <div class="mx-auto mb-3 flex h-10 w-10 items-center justify-center rounded-lg bg-[hsl(var(--so-foreground))]">
          <span class="so-font-mono text-sm font-bold text-[hsl(var(--so-background))]">E</span>
        </div>
        <p
          :if={@eyebrow}
          class="so-font-mono mb-2 text-[11px] uppercase tracking-[0.18em] text-[hsl(var(--so-muted-foreground))]"
        >
          {@eyebrow}
        </p>
        <h1 class="text-lg font-semibold tracking-tight">{@title}</h1>
        <p
          :if={@subtitle}
          class="mt-1 text-xs leading-relaxed text-[hsl(var(--so-muted-foreground))]"
        >
          {@subtitle}
        </p>
      </header>

      <div>
        {render_slot(@inner_block)}
      </div>

      <footer :if={@footer != []} class="mt-3">
        {render_slot(@footer)}
      </footer>
    </div>
    """
  end

  attr :prompt, :string, required: true
  attr :link_text, :string, required: true
  attr :link_href, :string, required: true
  attr :note, :string, default: nil

  def auth_page_footer(assigns) do
    ~H"""
    <div class="ui-auth-card-muted so-auth-card-muted text-center">
      <p class="text-xs text-[hsl(var(--so-muted-foreground))]">
        {@prompt}
        <a href={@link_href} class="font-medium text-[hsl(var(--so-primary))] hover:underline">
          {@link_text}
        </a>
        .
      </p>
      <p
        :if={@note}
        class="mt-2 text-[11px] leading-relaxed text-[hsl(var(--so-muted-foreground))]"
      >
        {@note}
      </p>
    </div>
    """
  end

  attr :form, :any, required: true

  def form_errors(assigns) do
    assigns =
      assign(assigns,
        messages:
          assigns.form
          |> Form.raw_errors(for_path: :all)
          |> Enum.flat_map(fn {_path, errors} -> List.wrap(errors) end)
          |> Enum.map(&Exception.message/1)
          |> Enum.uniq()
      )

    ~H"""
    <.auth_feedback
      :if={@messages != []}
      tone="danger"
      data-feedback="danger"
      role="alert"
      live="assertive"
      title="Review the highlighted fields."
      messages={@messages}
    />
    """
  end

  attr :tone, :string, values: ~w(success danger), required: true
  attr :title, :string, required: true
  attr :message, :string, default: nil
  attr :messages, :list, default: []
  attr :class, :any, default: nil
  attr :role, :string, default: nil
  attr :live, :string, default: nil
  attr :rest, :global

  def auth_feedback(assigns) do
    items = feedback_items(assigns.message, assigns.messages)

    assigns =
      assigns
      |> assign(:items, items)
      |> assign(:single_item, List.first(items))

    ~H"""
    <.alert
      :if={@items != []}
      class={["ui-auth-feedback", @class]}
      tone={@tone}
      title={@title}
      role={@role}
      live={@live}
      {@rest}
    >
      <p :if={length(@items) == 1}>{@single_item}</p>

      <ul :if={length(@items) > 1} class="ui-auth-feedback__list">
        <li :for={item <- @items} class="ui-auth-feedback__item">{item}</li>
      </ul>
    </.alert>
    """
  end

  attr :for, :any, required: true
  attr :id, :string, required: true
  attr :class, :any, default: nil
  attr :actions_layout, :string, values: ~w(end between), default: "end"

  attr :rest, :global,
    include:
      ~w(action autocomplete method novalidate phx-change phx-submit phx-target phx-trigger-action)

  slot :inner_block, required: true
  slot :actions, required: true

  def auth_form(assigns) do
    ~H"""
    <.form :let={form} for={@for} id={@id} class={["ui-auth-form", @class]} {@rest}>
      <fieldset class="ui-auth-form__fieldset">
        <div class="ui-auth-form__fields">
          {render_slot(@inner_block, form)}
        </div>

        <div class="ui-auth-form__actions" data-layout={@actions_layout}>
          {render_slot(@actions, form)}
        </div>
      </fieldset>
    </.form>
    """
  end

  attr :label, :string, required: true
  attr :busy_label, :string, required: true
  attr :variant, :string, values: ~w(solid outline ghost subtle), default: "solid"
  attr :tone, :string, values: ~w(primary neutral success warning danger), default: "primary"
  attr :size, :string, values: ~w(sm md lg), default: "md"
  attr :class, :any, default: nil

  def auth_submit(assigns) do
    ~H"""
    <.button
      type="submit"
      size="sm"
      variant={button_variant(@variant)}
      tone={button_tone(@tone)}
      class={["ui-auth-submit w-full justify-center", @class]}
      phx-disable-with={@busy_label}
    >
      {@label}
    </.button>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :autocomplete, :string, required: true
  attr :label, :string, default: "Email"
  attr :hint, :string, default: "Use the email address tied to this account."

  def auth_email_input(assigns) do
    ~H"""
    <.input
      field={@field}
      type="email"
      label={@label}
      hint={@hint}
      autocomplete={@autocomplete}
    />
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: "Username"

  attr :hint, :string,
    default: "4-30 characters. Use lowercase letters, numbers, hyphens, or underscores."

  def auth_username_input(assigns) do
    ~H"""
    <.input field={@field} type="text" label={@label} hint={@hint} autocomplete="username" />
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :autocomplete, :string, required: true
  attr :label, :string, default: "Password"
  attr :hint, :string, default: "Passwords are case sensitive."

  def auth_password_input(assigns) do
    ~H"""
    <.input
      field={@field}
      type="password"
      label={@label}
      hint={@hint}
      autocomplete={@autocomplete}
    />
    """
  end

  attr :current_path, :string, required: true

  def auth_nav(assigns) do
    ~H"""
    <nav
      class="ui-auth-nav flex flex-wrap gap-1 border-b border-[hsl(var(--so-border))] px-1 pt-1"
      aria-label={BrowserTestContracts.authentication_routes_nav_label()}
    >
      <a
        href={~p"/sign-in"}
        class="ui-underline-tab flex-1 justify-center text-xs"
        data-active={to_string(@current_path == "/sign-in")}
      >
        Sign in
      </a>
      <a
        href={~p"/register"}
        class="ui-underline-tab flex-1 justify-center text-xs"
        data-active={to_string(@current_path == "/register")}
      >
        Register
      </a>
      <a
        href={~p"/forgot-password"}
        class="ui-underline-tab flex-1 justify-center text-xs"
        data-active={to_string(@current_path == "/forgot-password")}
      >
        Forgot password
      </a>
    </nav>
    """
  end

  defp feedback_items(message, messages) do
    [message | List.wrap(messages)]
    |> Enum.reject(&(is_nil(&1) || &1 == ""))
  end

  defp auth_route_label("/sign-in"), do: "Sign in"
  defp auth_route_label("/register"), do: "Register"
  defp auth_route_label("/forgot-password"), do: "Reset password"
  defp auth_route_label("/reset"), do: "Reset password"
  defp auth_route_label("/confirm"), do: "Confirm email"
  defp auth_route_label("/magic-link"), do: "Magic link"
  defp auth_route_label(_), do: "Auth"

  defp button_variant("outline"), do: "outline"
  defp button_variant("ghost"), do: "ghost"
  defp button_variant("subtle"), do: "subtle"
  defp button_variant(_variant), do: "solid"

  defp button_tone("neutral"), do: "neutral"
  defp button_tone("warning"), do: "warning"
  defp button_tone("danger"), do: "danger"
  defp button_tone("success"), do: "success"
  defp button_tone(_tone), do: "success"
end
