defmodule EBossWeb.AuthComponents do
  @moduledoc false
  use EBossWeb, :html

  alias AshPhoenix.Form

  attr :eyebrow, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :detail_one, :string, required: true
  attr :detail_two, :string, required: true
  attr :detail_three, :string, required: true
  attr :current_user, :map, default: nil
  slot :inner_block, required: true

  def auth_shell(assigns) do
    ~H"""
    <section class="grid gap-8 lg:grid-cols-[1.1fr_0.9fr]">
      <div class="rounded-[2rem] border border-white/70 bg-white/80 p-4 shadow-[0_24px_80px_rgba(15,23,42,0.08)] backdrop-blur">
        <.AuthScene
          eyebrow={@eyebrow}
          title={@title}
          subtitle={@subtitle}
          detailOne={@detail_one}
          detailTwo={@detail_two}
          detailThree={@detail_three}
        />
      </div>

      <div class="rounded-[2rem] border border-stone-200/80 bg-white/90 p-8 shadow-[0_24px_80px_rgba(15,23,42,0.08)] backdrop-blur sm:p-10">
        {render_slot(@inner_block)}
      </div>
    </section>
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
    <div
      :if={@messages != []}
      class="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800"
    >
      <div class="flex items-start gap-3">
        <.icon name="hero-exclamation-circle" class="mt-0.5 size-5 shrink-0" />
        <div class="space-y-1">
          <p class="font-semibold">We need a quick fix before continuing.</p>
          <p :for={message <- @messages}>{message}</p>
        </div>
      </div>
    </div>
    """
  end

  attr :current_path, :string, required: true

  def auth_nav(assigns) do
    ~H"""
    <nav class="flex flex-wrap gap-2 text-sm">
      <.auth_link to={~p"/sign-in"} active={@current_path == "/sign-in"}>
        Sign in
      </.auth_link>
      <.auth_link to={~p"/register"} active={@current_path == "/register"}>
        Register
      </.auth_link>
      <.auth_link to={~p"/forgot-password"} active={@current_path == "/forgot-password"}>
        Forgot password
      </.auth_link>
    </nav>
    """
  end

  attr :to, :string, required: true
  attr :active, :boolean, default: false
  slot :inner_block, required: true

  defp auth_link(assigns) do
    ~H"""
    <a
      href={@to}
      class={[
        "rounded-full px-3 py-1.5 font-medium transition",
        @active && "bg-stone-950 text-white",
        !@active && "bg-stone-100 text-stone-600 hover:bg-stone-200 hover:text-stone-950"
      ]}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end
end
