<script setup lang="ts">
import UiButton from "../components/ui/UiButton.vue"

const props = withDefaults(
  defineProps<{
    theme?: "light" | "dark"
    density?: "default" | "compact"
  }>(),
  {
    theme: "dark",
    density: "default",
  },
)

const emit = defineEmits<{
  (event: "update:theme", value: "light" | "dark"): void
  (event: "update:density", value: "default" | "compact"): void
}>()
</script>

<template>
  <div class="flex flex-wrap items-center gap-3">
    <div class="flex items-center gap-2">
      <span class="ui-kicker text-ui-text-soft">Theme</span>
      <UiButton
        size="sm"
        :variant="props.theme === 'dark' ? 'solid' : 'outline'"
        tone="neutral"
        @click="emit('update:theme', 'dark')"
      >
        Dark
      </UiButton>
      <UiButton
        size="sm"
        :variant="props.theme === 'light' ? 'solid' : 'outline'"
        tone="neutral"
        @click="emit('update:theme', 'light')"
      >
        Light
      </UiButton>
    </div>

    <div class="flex items-center gap-2">
      <span class="ui-kicker text-ui-text-soft">Density</span>
      <UiButton
        size="sm"
        :variant="props.density === 'default' ? 'solid' : 'outline'"
        tone="neutral"
        @click="emit('update:density', 'default')"
      >
        Default
      </UiButton>
      <UiButton
        size="sm"
        :variant="props.density === 'compact' ? 'solid' : 'outline'"
        tone="neutral"
        @click="emit('update:density', 'compact')"
      >
        Compact
      </UiButton>
    </div>
  </div>
</template>
