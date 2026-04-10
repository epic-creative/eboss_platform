<script setup lang="ts">
withDefaults(
  defineProps<{
    theme?: "light" | "dark"
    density?: "default" | "compact"
  }>(),
  {
    theme: "dark",
    density: "default",
  },
)
</script>

<template>
  <div
    :data-theme="theme"
    :data-density="density === 'compact' ? 'compact' : undefined"
    class="ui-preview-frame"
  >
    <slot />
  </div>
</template>
