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
      <div
        role="alert"
        aria-live="assertive"
        aria-atomic="true"
        class="ui-alert w-80 max-w-80 sm:w-96 sm:max-w-96"
        data-tone={@tone}
      >
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
    button_disabled = assigns.loading || !!rest[:disabled]
    is_link = !!(rest[:href] || rest[:navigate] || rest[:patch])

    assigns =
      assigns
      |> assign(:button_class, button_class)
      |> assign(:button_state, state)
      |> assign(:is_link, is_link)
      |> assign(:button_disabled, button_disabled)
      |> assign(:button_rest, strip_button_accessibility_attrs(rest))
      |> assign(:disabled_link_rest, strip_disabled_link_attrs(rest))

    cond do
      assigns.is_link && assigns.button_disabled ->
        ~H"""
        <span
          class={@button_class}
          data-variant={@variant}
          data-tone={@tone}
          data-size={@size}
          data-state={@button_state}
          aria-busy={busy_attr(@loading)}
          aria-disabled="true"
          tabindex="-1"
          {@disabled_link_rest}
        >
          <.button_inner loading={@loading} icon={@icon} icon_position={@icon_position}>
            {render_slot(@inner_block)}
          </.button_inner>
        </span>
        """

      assigns.is_link ->
        ~H"""
        <.link
          class={@button_class}
          data-variant={@variant}
          data-tone={@tone}
          data-size={@size}
          data-state={@button_state}
          aria-busy={busy_attr(@loading)}
          {@button_rest}
        >
          <.button_inner loading={@loading} icon={@icon} icon_position={@icon_position}>
            {render_slot(@inner_block)}
          </.button_inner>
        </.link>
        """

      true ->
        ~H"""
        <button
          class={@button_class}
          data-variant={@variant}
          data-tone={@tone}
          data-size={@size}
          data-state={@button_state}
          aria-busy={busy_attr(@loading)}
          disabled={@button_disabled}
          {@button_rest}
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
    |> assign(:value, normalize_form_value(field.value))
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
      |> with_input_a11y()

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
          aria-describedby={@describedby}
          aria-invalid={invalid_attr(@invalid_state)}
          {@rest}
        />
        <span class="ui-checkbox-label">
          <span :if={@label} class="ui-field-label">{@label}</span>
          <span :if={@hint} id={@hint_id} class="ui-checkbox-caption">{@hint}</span>
        </span>
      </label>
      <div :if={@errors != []} id={@error_id} class="grid gap-2" aria-live="polite">
        <.error :for={msg <- @errors} class={@error_class}>{msg}</.error>
      </div>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    assigns = with_input_a11y(assigns)

    ~H"""
    <div class="ui-field">
      <label :if={@label} for={@id} class="ui-field-label">{@label}</label>
      <div class="ui-field-control" data-size={@size} data-invalid={to_string(@invalid_state)}>
        <span :if={@prefix} class="ui-field-affix">{@prefix}</span>
        <select
          id={@id}
          name={@name}
          class={["ui-select", @class]}
          multiple={@multiple}
          aria-describedby={@describedby}
          aria-invalid={invalid_attr(@invalid_state)}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
        <span :if={@suffix} class="ui-field-affix">{@suffix}</span>
      </div>
      <p :if={@hint} id={@hint_id} class="ui-field-hint">{@hint}</p>
      <div :if={@errors != []} id={@error_id} class="grid gap-2" aria-live="polite">
        <.error :for={msg <- @errors} class={@error_class}>{msg}</.error>
      </div>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    assigns = with_input_a11y(assigns)

    ~H"""
    <div class="ui-field">
      <label :if={@label} for={@id} class="ui-field-label">{@label}</label>
      <div class="ui-field-control" data-size={@size} data-invalid={to_string(@invalid_state)}>
        <span :if={@prefix} class="ui-field-affix">{@prefix}</span>
        <textarea
          id={@id}
          name={@name}
          class={["ui-textarea", @class]}
          aria-describedby={@describedby}
          aria-invalid={invalid_attr(@invalid_state)}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
        <span :if={@suffix} class="ui-field-affix">{@suffix}</span>
      </div>
      <p :if={@hint} id={@hint_id} class="ui-field-hint">{@hint}</p>
      <div :if={@errors != []} id={@error_id} class="grid gap-2" aria-live="polite">
        <.error :for={msg <- @errors} class={@error_class}>{msg}</.error>
      </div>
    </div>
    """
  end

  def input(assigns) do
    assigns = with_input_a11y(assigns)

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
          aria-describedby={@describedby}
          aria-invalid={invalid_attr(@invalid_state)}
          {@rest}
        />
        <span :if={@suffix} class="ui-field-affix">{@suffix}</span>
      </div>
      <p :if={@hint} id={@hint_id} class="ui-field-hint">{@hint}</p>
      <div :if={@errors != []} id={@error_id} class="grid gap-2" aria-live="polite">
        <.error :for={msg <- @errors} class={@error_class}>{msg}</.error>
      </div>
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

  defp normalize_form_value(value) when is_list(value) do
    Enum.map(value, &normalize_form_value/1)
  end

  defp normalize_form_value(value) do
    if String.Chars.impl_for(value) && !is_binary(value) do
      to_string(value)
    else
      value
    end
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

  defp busy_attr(true), do: "true"
  defp busy_attr(false), do: nil

  defp invalid_attr(true), do: "true"
  defp invalid_attr(false), do: nil

  defp with_input_a11y(assigns) do
    id = assigns[:id] || input_id_from_name(assigns[:name])
    hint_id = if id && present?(assigns[:hint]), do: "#{id}-hint", else: nil
    error_id = if id && assigns[:errors] != [], do: "#{id}-error", else: nil

    assigns
    |> assign(:id, id)
    |> assign(:invalid_state, field_invalid?(assigns.errors, assigns.invalid))
    |> assign(:hint_id, hint_id)
    |> assign(:error_id, error_id)
    |> assign(:describedby, described_by_attr(assigns.rest, [hint_id, error_id]))
    |> assign(:rest, drop_accessibility_attrs(assigns.rest))
  end

  defp described_by_attr(rest, ids) do
    existing = rest[:"aria-describedby"] || rest["aria-describedby"]

    [existing | ids]
    |> Enum.reject(&(is_nil(&1) || &1 == ""))
    |> Enum.join(" ")
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp drop_accessibility_attrs(rest) do
    Map.drop(rest, [:"aria-describedby", "aria-describedby", :"aria-invalid", "aria-invalid"])
  end

  defp strip_button_accessibility_attrs(rest) do
    Map.drop(rest, [
      :"aria-busy",
      "aria-busy",
      :"aria-disabled",
      "aria-disabled",
      :tabindex,
      "tabindex"
    ])
  end

  defp strip_disabled_link_attrs(rest) do
    rest
    |> strip_button_accessibility_attrs()
    |> Map.drop([
      :disabled,
      "disabled",
      :download,
      "download",
      :href,
      "href",
      :method,
      "method",
      :name,
      "name",
      :navigate,
      "navigate",
      :patch,
      "patch",
      :type,
      "type",
      :value,
      "value"
    ])
  end

  defp input_id_from_name(nil), do: nil

  defp input_id_from_name(name) do
    name
    |> to_string()
    |> String.replace(~r/[^a-zA-Z0-9_-]+/, "_")
    |> String.trim("_")
  end

  defp present?(value), do: value not in [nil, ""]

  defp tone_from_kind(:info), do: "primary"
  defp tone_from_kind(:error), do: "danger"

  defp flash_icon(:info), do: "hero-information-circle"
  defp flash_icon(:error), do: "hero-exclamation-circle"
end
