<script setup lang="ts">
import type { Component, PropType } from "vue"

defineProps({
  title: {
    type: String,
    required: true,
  },
  copy: {
    type: String,
    required: true,
  },
  icon: {
    type: Object as PropType<Component | null>,
    default: null,
  },
  dashed: {
    type: Boolean,
    default: false,
  },
  compact: {
    type: Boolean,
    default: false,
  },
})
</script>

<template>
  <div
    class="ui-workspace-empty-state"
    :class="{
      'ui-workspace-empty-state--dashed': dashed,
      'ui-workspace-empty-state--compact': compact,
    }"
  >
    <component :is="icon" v-if="icon" class="ui-workspace-empty-state__icon" />
    <h3 class="ui-workspace-empty-state__title">{{ title }}</h3>
    <p class="ui-workspace-empty-state__copy">{{ copy }}</p>

    <div v-if="$slots.actions" class="ui-workspace-empty-state__actions">
      <slot name="actions" />
    </div>
  </div>
</template>
