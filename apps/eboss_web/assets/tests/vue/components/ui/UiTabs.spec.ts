import { defineComponent, nextTick, ref } from "vue"
import { describe, expect, it } from "vitest"
import UiTabs from "@/vue/components/ui/UiTabs.vue"
import { mountComponent } from "@/tests/vue/support/mount"

const workspaceTabs = [
  { value: "runs", label: "Runs", copy: "Track queue health, execution results, and blocked branches." },
  { value: "agents", label: "Agents", copy: "Inspect agent health, policies, and assigned work." },
  { value: "audit", label: "Audit", copy: "Review approvals, overrides, and external side effects." },
]

const activePanel = (wrapper: ReturnType<typeof mountComponent>) =>
  wrapper.findAll('[role="tabpanel"]').find((panel) => panel.attributes("hidden") === undefined)

describe("UiTabs", () => {
  it("defaults to the first tab when no model value is supplied", () => {
    const wrapper = mountComponent(UiTabs, {
      props: {
        items: workspaceTabs,
      },
    })

    const triggers = wrapper.findAll('[role="tab"]')

    expect(triggers).toHaveLength(3)
    expect(triggers.map((trigger) => trigger.attributes("aria-selected"))).toEqual(["true", "false", "false"])
    expect(activePanel(wrapper)?.text()).toContain(workspaceTabs[0].copy)
  })

  it("supports click and arrow-key updates through the v-model contract", async () => {
    const wrapper = mountComponent(
      defineComponent({
        components: { UiTabs },
        setup() {
          const activeTab = ref("runs")
          return { activeTab, items: workspaceTabs }
        },
        template: `
          <div>
            <UiTabs v-model="activeTab" :items="items">
              <template #content-agents="{ item }">
                <p data-testid="agents-panel">{{ item.label }} custom panel</p>
              </template>
            </UiTabs>
            <output data-testid="active-tab">{{ activeTab }}</output>
          </div>
        `,
      }),
    )

    const tabs = wrapper.getComponent(UiTabs)

    await wrapper.findAll('[role="tab"]')[1].trigger("mousedown", { button: 0 })

    expect(wrapper.get('[data-testid="active-tab"]').text()).toBe("agents")
    expect(tabs.emitted("update:modelValue")).toEqual([["agents"]])
    expect(activePanel(wrapper)?.text()).toContain("Agents custom panel")

    const agentsTrigger = wrapper.findAll('[role="tab"]')[1]
    ;(agentsTrigger.element as HTMLElement).focus()
    await agentsTrigger.trigger("keydown", { key: "ArrowRight", code: "ArrowRight" })
    await nextTick()

    expect(wrapper.get('[data-testid="active-tab"]').text()).toBe("audit")
    expect(tabs.emitted("update:modelValue")).toEqual([["agents"], ["audit"]])
    expect(activePanel(wrapper)?.text()).toContain(workspaceTabs[2].copy)
  })
})
