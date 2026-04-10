import { h, type Component } from "vue"
import { createLiveVue, findComponent, type ComponentMap, type LiveHook } from "live_vue"

declare module "vue" {
  interface ComponentCustomProperties {
    $live: LiveHook
  }
}

export default createLiveVue({
  resolve: name => {
    const components = {
      ...import.meta.glob(["./**/*.vue", "!./**/*.story.vue"], { eager: true }),
      ...import.meta.glob(["../../lib/**/*.vue", "!../../lib/**/*.story.vue"], { eager: true }),
    } as ComponentMap

    return findComponent(components, name)
  },
  setup: ({ createApp, component, props, slots, plugin, el }) => {
    const app = createApp({ render: () => h(component as Component, props, slots) })

    app.use(plugin)
    app.mount(el)

    return app
  },
})
