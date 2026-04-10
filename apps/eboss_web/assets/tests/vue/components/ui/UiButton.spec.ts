import { describe, expect, it } from "vitest"
import UiButton from "@/vue/components/ui/UiButton.vue"
import { mountComponent } from "@/tests/vue/support/mount"

describe("UiButton", () => {
  it("renders a native button with slot content by default", () => {
    const wrapper = mountComponent(UiButton, {
      slots: {
        default: "Run checks",
      },
    })

    expect(wrapper.element.tagName).toBe("BUTTON")
    expect(wrapper.attributes("type")).toBe("button")
    expect(wrapper.text()).toContain("Run checks")
  })

  it("falls back to a non-focusable element when disabled links are rendered", () => {
    const wrapper = mountComponent(UiButton, {
      props: {
        disabled: true,
        href: "/review",
        tone: "neutral",
        variant: "outline",
      },
      slots: {
        default: "Open report",
      },
    })

    expect(wrapper.element.tagName).toBe("SPAN")
    expect(wrapper.attributes("aria-disabled")).toBe("true")
    expect(wrapper.attributes("href")).toBeUndefined()
    expect(wrapper.attributes("tabindex")).toBe("-1")
  })
})
