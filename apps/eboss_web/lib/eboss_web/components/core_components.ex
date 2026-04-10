defmodule EBossWeb.CoreComponents do
  @moduledoc """
  Canonical HEEx UI primitives backed by the first-party design system.
  """

  use Phoenix.Component
  use Gettext, backend: EBossWeb.Gettext

  alias Phoenix.LiveView.JS

  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for flash lookup"
  attr :tone, :string, default: nil
  attr :dismissible, :boolean, default: true
  attr :rest, :global

  slot :inner_block

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)
    assigns = assign(assigns, :tone, assigns.tone || tone_from_kind(assigns.kind))
    assigns = assign(assigns, :icon_name, flash_icon(assigns.kind))

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      class="ui-toast-stack"
      {@rest}
    >
      <div role="alert" class="ui-alert w-80 max-w-80 sm:w-96 sm:max-w-96" data-tone={@tone}>
        <.icon name={@icon_name} class="mt-0.5 size-5 shrink-0" />
        <div class="ui-alert__content">
          <p :if={@title} class="ui-alert__title">{@title}</p>
          <p class="ui-alert__description">{msg}</p>
        </div>
        <button
          :if={@dismissible}
          type="button"
          class="ui-button shrink-0"
          data-variant="ghost"
          data-tone="neutral"
          data-size="sm"
          aria-label={gettext("close")}
          phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
        >
          <.icon name="hero-x-mark" class="size-4" />
        </button>
      </div>
    </div>
    """
  end

  attr :rest, :global, include: ~w(href navigate patch method download name value disabled type)
  attr :class, :any, default: nil
  attr :variant, :string, values: ~w(solid outline ghost subtle), default: "solid"
  attr :tone, :string, values: ~w(primary neutral success warning danger), default: "primary"
  attr :size, :string, values: ~w(sm md lg), default: "md"
  attr :loading, :boolean, default: false
  attr :icon, :string, default: nil
  attr :icon_position, :string, values: ~w(leading trailing), default: "leading"

  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    state = if assigns.loading, do: "loading", else: "default"
    button_class = ["ui-button", assigns.class]

    assigns =
      assigns
      |> assign(:button_class, button_class)
      |> assign(:button_state, state)
      |> assign(:is_link, !!(rest[:href] || rest[:navigate] || rest[:patch]))
      |> assign(:button_disabled, assigns.loading || !!rest[:disabled])

    if assigns.is_link do
      ~H"""
      <.link
        class={@button_class}
        data-variant={@variant}
        data-tone={@tone}
        data-size={@size}
        data-state={@button_state}
        aria-disabled={to_string(@button_disabled)}
        {@rest}
      >
        <.button_inner loading={@loading} icon={@icon} icon_position={@icon_position}>
          {render_slot(@inner_block)}
        </.button_inner>
      </.link>
      """
    else
      ~H"""
      <button
        class={@button_class}
        data-variant={@variant}
        data-tone={@tone}
        data-size={@size}
        data-state={@button_state}
        disabled={@button_disabled}
        {@rest}
      >
        <.button_inner loading={@loading} icon={@icon} icon_position={@icon_position}>
          {render_slot(@inner_block)}
        </.button_inner>
      </button>
      """
    end
  end

  attr :loading, :boolean, required: true
  attr :icon, :string, default: nil
  attr :icon_position, :string, values: ~w(leading trailing), required: true
  slot :inner_block, required: true

  defp button_inner(assigns) do
    ~H"""
    <span class="ui-button__label">
      <span :if={@loading || (@icon && @icon_position == "leading")} class="inline-flex items-center">
        <span :if={@loading} class="ui-spinner" data-size="sm" aria-hidden="true" />
        <.icon :if={@icon && !@loading} name={@icon} class="size-4" />
      </span>
      <span>{render_slot(@inner_block)}</span>
      <span :if={@icon && @icon_position == "trailing" && !@loading} class="inline-flex items-center">
        <.icon name={@icon} class="size-4" />
      </span>
    </span>
    """
  end

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any, default: nil

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField
  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil
  attr :options, :list
  attr :multiple, :boolean, default: false
  attr :class, :any, default: nil
  attr :error_class, :any, default: nil
  attr :size, :string, values: ~w(sm md lg), default: "md"
  attr :invalid, :boolean, default: false
  attr :hint, :string, default: nil
  attr :prefix, :string, default: nil
  attr :suffix, :string, default: nil

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assigns
      |> assign_new(:checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)
      |> assign(:invalid_state, field_invalid?(assigns.errors, assigns.invalid))

    ~H"""
    <div class="ui-field">
      <label class="ui-checkbox-field" for={@id}>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={["ui-checkbox", @class]}
          {@rest}
        />
        <span class="ui-checkbox-label">
          <span :if={@label} class="ui-field-label">{@label}</span>
          <span :if={@hint} class="ui-checkbox-caption">{@hint}</span>
        </span>
      </label>
      <.error :for={msg <- @errors} class={@error_class}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    assigns = assign(assigns, :invalid_state, field_invalid?(assigns.errors, assigns.invalid))

    ~H"""
    <div class="ui-field">
      <label :if={@label} for={@id} class="ui-field-label">{@label}</label>
      <div class="ui-field-control" data-size={@size} data-invalid={to_string(@invalid_state)}>
        <span :if={@prefix} class="ui-field-affix">{@prefix}</span>
        <select id={@id} name={@name} class={["ui-select", @class]} multiple={@multiple} {@rest}>
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
        <span :if={@suffix} class="ui-field-affix">{@suffix}</span>
      </div>
      <p :if={@hint} class="ui-field-hint">{@hint}</p>
      <.error :for={msg <- @errors} class={@error_class}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    assigns = assign(assigns, :invalid_state, field_invalid?(assigns.errors, assigns.invalid))

    ~H"""
    <div class="ui-field">
      <label :if={@label} for={@id} class="ui-field-label">{@label}</label>
      <div class="ui-field-control" data-size={@size} data-invalid={to_string(@invalid_state)}>
        <span :if={@prefix} class="ui-field-affix">{@prefix}</span>
        <textarea id={@id} name={@name} class={["ui-textarea", @class]} {@rest}>{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
        <span :if={@suffix} class="ui-field-affix">{@suffix}</span>
      </div>
      <p :if={@hint} class="ui-field-hint">{@hint}</p>
      <.error :for={msg <- @errors} class={@error_class}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    assigns = assign(assigns, :invalid_state, field_invalid?(assigns.errors, assigns.invalid))

    ~H"""
    <div class="ui-field">
      <label :if={@label} for={@id} class="ui-field-label">{@label}</label>
      <div class="ui-field-control" data-size={@size} data-invalid={to_string(@invalid_state)}>
        <span :if={@prefix} class="ui-field-affix">{@prefix}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={["ui-input", @class]}
          {@rest}
        />
        <span :if={@suffix} class="ui-field-affix">{@suffix}</span>
      </div>
      <p :if={@hint} class="ui-field-hint">{@hint}</p>
      <.error :for={msg <- @errors} class={@error_class}>{msg}</.error>
    </div>
    """
  end

  attr :class, :any, default: nil
  slot :inner_block, required: true

  defp error(assigns) do
    ~H"""
    <p class={["ui-field-error", @class]}>
      <.icon name="hero-exclamation-circle" class="size-4 shrink-0" />
      <span>{render_slot(@inner_block)}</span>
    </p>
    """
  end

  slot :inner_block, required: true
  slot :subtitle
  slot :actions
  attr :title_size, :string, values: ~w(md sm), default: "sm"

  def header(assigns) do
    ~H"""
    <header class={[
      "ui-section-header",
      @actions != [] && "flex items-end justify-between gap-6",
      "pb-4"
    ]}>
      <div class="space-y-2">
        <h1 class="ui-section-header__title" data-size={@title_size}>{render_slot(@inner_block)}</h1>
        <p :if={@subtitle != []} class="ui-section-header__subtitle">{render_slot(@subtitle)}</p>
      </div>
      <div :if={@actions != []} class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil
  attr :row_click, :any, default: nil

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="ui-table">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="ui-table-actions w-0">
            <div class="flex gap-3">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="ui-list">
      <li :for={item <- @item} class="ui-list-row">
        <div class="ui-list-title">{item.title}</div>
        <div class="ui-text-body" data-tone="soft">{render_slot(item)}</div>
      </li>
    </ul>
    """
  end

  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(EBossWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(EBossWeb.Gettext, "errors", msg, opts)
    end
  end

  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  defp field_invalid?(errors, invalid), do: invalid || errors != []

  defp tone_from_kind(:info), do: "primary"
  defp tone_from_kind(:error), do: "danger"

  defp flash_icon(:info), do: "hero-information-circle"
  defp flash_icon(:error), do: "hero-exclamation-circle"
end
