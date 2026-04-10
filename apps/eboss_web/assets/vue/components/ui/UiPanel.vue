<script setup lang="ts">
import { computed, useAttrs } from "vue"

defineOptions({ inheritAttrs: false })

const props = withDefaults(
  defineProps<{
    as?: string
    surface?: "default" | "floating" | "solid"
    tone?: "neutral" | "primary" | "inverse"
    padding?: "sm" | "md" | "lg"
  }>(),
  {
    as: "section",
    surface: "default",
    tone: "neutral",
    padding: "md",
  },
)

const attrs = useAttrs()

const paddingClass = computed(() => {
  switch (props.padding) {
    case "sm":
      return "p-4"
    case "lg":
      return "p-8 sm:p-10"
    default:
      return "p-6"
  }
})
</script>

<template>
  <component
    :is="as"
    v-bind="attrs"
    class="ui-panel"
    :class="paddingClass"
    :data-surface="surface === 'default' ? undefined : surface"
    :data-tone="tone === 'neutral' ? undefined : tone"
  >
    <slot />
  </component>
</template>
