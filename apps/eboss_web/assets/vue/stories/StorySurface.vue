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
    class="min-h-[18rem] rounded-[28px] border border-ui-border-subtle bg-ui-canvas p-6 text-ui-text shadow-[0_24px_80px_rgba(2,10,23,0.16)]"
  >
    <slot />
  </div>
</template>
