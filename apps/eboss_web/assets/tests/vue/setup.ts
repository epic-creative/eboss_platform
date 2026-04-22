import { enableAutoUnmount } from "@vue/test-utils"
import { afterEach, vi } from "vitest"

enableAutoUnmount(afterEach)

afterEach(() => {
  delete (globalThis as typeof globalThis & { __liveVueEventReply?: unknown }).__liveVueEventReply
  delete (globalThis as typeof globalThis & { __liveVueEventHandlers?: unknown }).__liveVueEventHandlers
})

vi.mock("live_vue", async () => {
  const { computed, defineComponent, h, ref } = await import("vue")

  const navigateTo = (href: string, replace = false) => {
    if (typeof window === "undefined") return

    if (replace) {
      window.history.replaceState({}, "", href)
    } else {
      window.history.pushState({}, "", href)
    }
  }

  return {
    Link: defineComponent({
      name: "LiveVueLink",
      props: {
        href: { type: String, default: null },
        patch: { type: String, default: null },
        navigate: { type: String, default: null },
        replace: { type: Boolean, default: false },
      },
      setup(props, { attrs, slots }) {
        const callAttrClick = (event: MouseEvent) => {
          const onClick = attrs.onClick

          if (Array.isArray(onClick)) {
            onClick.forEach(handler => {
              if (typeof handler === "function") handler(event)
            })
          } else if (typeof onClick === "function") {
            onClick(event)
          }
        }

        return () =>
          h(
            "a",
            {
              ...attrs,
              href: props.href || props.patch || props.navigate || "#",
              "data-phx-link": props.patch ? "patch" : props.navigate ? "redirect" : undefined,
              "data-phx-link-state": props.replace ? "replace" : "push",
              onClick: (event: MouseEvent) => {
                if (props.patch || props.navigate) {
                  event.preventDefault()
                  navigateTo((props.patch || props.navigate) as string, props.replace)
                }

                callAttrClick(event)
              },
            },
            slots.default?.(),
          )
      },
    }),
    useEventReply: (eventName: string) => ({
      data: ref(null),
      isLoading: ref(false),
      execute: vi.fn(async (params: Record<string, unknown> = {}) => {
        const reply = (globalThis as typeof globalThis & {
          __liveVueEventReply?: (eventName: string, params: Record<string, unknown>) => unknown
        }).__liveVueEventReply

        return reply ? reply(eventName, params) : { ok: true }
      }),
      cancel: vi.fn(),
    }),
    useLiveConnection: () => ({
      connectionState: ref("open"),
      isConnected: computed(() => true),
    }),
    useLiveEvent: (eventName: string, callback: (payload: unknown) => void) => {
      const global = globalThis as typeof globalThis & {
        __liveVueEventHandlers?: Record<string, Array<(payload: unknown) => void>>
      }

      global.__liveVueEventHandlers ||= {}
      global.__liveVueEventHandlers[eventName] ||= []
      global.__liveVueEventHandlers[eventName].push(callback)
    },
    useLiveForm: vi.fn(),
    useLiveNavigation: () => ({
      patch: vi.fn((href: string, opts: { replace?: boolean } = {}) => navigateTo(href, opts.replace)),
      navigate: vi.fn((href: string, opts: { replace?: boolean } = {}) =>
        navigateTo(href, opts.replace),
      ),
    }),
    useLiveUpload: vi.fn(),
    useLiveVue: () => ({
      pushEvent: vi.fn(),
      handleEvent: vi.fn(),
      removeHandleEvent: vi.fn(),
      liveSocket: {},
    }),
  }
})
