<script setup lang="ts">
import type { Component, PropType } from "vue"

defineProps({
  title: {
    type: String,
    default: "",
  },
  subtitle: {
    type: String,
    default: "",
  },
  icon: {
    type: [Object, Function] as PropType<Component | null>,
    default: null,
  },
  bodyClass: {
    type: String,
    default: "",
  },
})
</script>

<template>
  <section class="ui-workspace-panel">
    <header
      v-if="$slots.header || title || subtitle || icon || $slots.actions"
      class="ui-workspace-panel__header"
    >
      <slot name="header">
        <div class="ui-workspace-panel__header-main">
          <component :is="icon" v-if="icon" class="ui-workspace-panel__icon" />

          <div v-if="title || subtitle" class="ui-workspace-panel__heading">
            <h2 v-if="title" class="ui-workspace-panel__title">{{ title }}</h2>
            <p v-if="subtitle" class="ui-workspace-panel__subtitle">{{ subtitle }}</p>
          </div>
        </div>
      </slot>

      <div v-if="$slots.actions" class="ui-workspace-panel__actions">
        <slot name="actions" />
      </div>
    </header>

    <div class="ui-workspace-panel__body" :class="bodyClass">
      <slot />
    </div>

    <footer v-if="$slots.footer" class="ui-workspace-panel__footer">
      <slot name="footer" />
    </footer>
  </section>
</template>
