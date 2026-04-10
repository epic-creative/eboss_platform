import { describe, expect, it } from "vitest"
import UiInput from "@/vue/components/ui/UiInput.vue"
import { mountComponent } from "@/tests/vue/support/mount"

describe("UiInput", () => {
  it("links hint and error copy into the input contract and emits model updates", async () => {
    const wrapper = mountComponent(UiInput, {
      attrs: {
        "aria-describedby": "external-help",
      },
      props: {
        id: "workspace-slug",
        label: "Workspace slug",
        hint: "Use the same slug shown in review links.",
        errors: ["Use lowercase characters only.", "Separate words with hyphens."],
        modelValue: "ops-prod",
        prefix: "team/",
      },
    })

    const input = wrapper.get("input")

    expect(input.attributes("id")).toBe("workspace-slug")
    expect(input.attributes("aria-describedby")).toBe(
      "external-help workspace-slug-hint workspace-slug-error",
    )
    expect(input.attributes("aria-invalid")).toBe("true")
    expect(wrapper.get(".ui-field-control").attributes("data-invalid")).toBe("true")
    expect(wrapper.get("#workspace-slug-hint").text()).toContain("Use the same slug shown in review links.")
    expect(wrapper.get("#workspace-slug-error").text()).toContain("Use lowercase characters only.")
    expect(wrapper.get("#workspace-slug-error").text()).toContain("Separate words with hyphens.")

    await input.setValue("ops-staging")

    expect(wrapper.emitted("update:modelValue")).toEqual([["ops-staging"]])
  })
})
