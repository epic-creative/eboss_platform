<script setup lang="ts">
import UiPanel from "../components/ui/UiPanel.vue"

withDefaults(
  defineProps<{
    state: string
    copy?: string
    stretch?: boolean
  }>(),
  {
    copy: undefined,
    stretch: false,
  },
)
</script>

<template>
  <UiPanel as="div" surface="solid" padding="sm" class="flex h-full flex-col gap-3">
    <div class="space-y-1">
      <p class="ui-text-meta" data-tone="soft">{{ state }}</p>
      <p v-if="copy" class="ui-text-body" data-size="sm" data-tone="muted">{{ copy }}</p>
    </div>

    <div :class="stretch ? 'flex-1' : undefined">
      <slot />
    </div>
  </UiPanel>
</template>
