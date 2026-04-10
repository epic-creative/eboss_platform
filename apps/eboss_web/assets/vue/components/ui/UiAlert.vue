<script setup lang="ts">
import { computed } from "vue"

const props = withDefaults(
  defineProps<{
    tone?: "primary" | "neutral" | "success" | "warning" | "danger"
    title?: string
    description?: string
    role?: "status" | "alert"
    live?: "polite" | "assertive" | "off"
  }>(),
  {
    tone: "neutral",
    title: undefined,
    description: undefined,
    role: undefined,
    live: undefined,
  },
)

const alertRole = computed(() => props.role ?? (["warning", "danger"].includes(props.tone) ? "alert" : "status"))
const alertLive = computed(() => props.live ?? (alertRole.value === "alert" ? "assertive" : "polite"))
</script>

<template>
  <div class="ui-alert" :data-tone="tone" :role="alertRole" :aria-live="alertLive" aria-atomic="true">
    <div class="ui-alert__content">
      <p v-if="title" class="ui-alert__title">{{ title }}</p>
      <p v-if="description" class="ui-alert__description">{{ description }}</p>
      <div v-if="$slots.default" class="ui-alert__description">
        <slot />
      </div>
    </div>
  </div>
</template>
