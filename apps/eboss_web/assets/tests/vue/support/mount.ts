import { mount, type MountingOptions } from "@vue/test-utils"
import type { Component } from "vue"

export const mountComponent = (component: Component, options: MountingOptions<any> = {}) =>
  mount(component, {
    attachTo: document.body,
    ...options,
  })
