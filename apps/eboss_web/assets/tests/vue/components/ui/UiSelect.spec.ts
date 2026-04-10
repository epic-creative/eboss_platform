import { describe, expect, it } from "vitest"
import UiSelect from "@/vue/components/ui/UiSelect.vue"
import { mountComponent } from "@/tests/vue/support/mount"

const environmentOptions = [
  { label: "Production", value: "prod" },
  { label: "Staging", value: "staging" },
  { label: "Archived", value: "archived", disabled: true },
]

describe("UiSelect", () => {
  it("renders prompt and disabled options, then emits model updates on selection", async () => {
    const wrapper = mountComponent(UiSelect, {
      props: {
        id: "environment",
        label: "Environment",
        hint: "Select inputs share the same shell as other field primitives.",
        modelValue: "",
        prompt: "Choose an environment",
        options: environmentOptions,
      },
    })

    const select = wrapper.get("select")
    const options = wrapper.findAll("option")

    expect(select.attributes("aria-describedby")).toBe("environment-hint")
    expect(options.map((option) => option.text())).toEqual([
      "Choose an environment",
      "Production",
      "Staging",
      "Archived",
    ])
    expect(options[0].attributes("value")).toBe("")
    expect(options[3].attributes("disabled")).toBeDefined()

    await select.setValue("staging")

    expect(wrapper.emitted("update:modelValue")).toEqual([["staging"]])
  })

  it("marks the field invalid when errors are present and merges described-by ids", () => {
    const wrapper = mountComponent(UiSelect, {
      attrs: {
        "aria-describedby": "external-help",
      },
      props: {
        id: "approval-route",
        label: "Approval route",
        hint: "Choose a route before continuing.",
        error: "A route is required.",
        modelValue: "",
        prompt: "Select a route",
        options: [
          { label: "Human review", value: "human" },
          { label: "Auto-approve", value: "auto" },
        ],
      },
    })

    const select = wrapper.get("select")

    expect(select.attributes("aria-describedby")).toBe(
      "external-help approval-route-hint approval-route-error",
    )
    expect(select.attributes("aria-invalid")).toBe("true")
    expect(wrapper.get(".ui-field-control").attributes("data-invalid")).toBe("true")
    expect(wrapper.get("#approval-route-error").text()).toContain("A route is required.")
  })
})
