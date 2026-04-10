<script setup lang="ts">
withDefaults(
  defineProps<{
    tone?: "neutral" | "primary" | "success" | "warning" | "danger"
  }>(),
  {
    tone: "neutral",
  },
)
</script>

<template>
  <span class="ui-badge" :data-tone="tone">
    <slot />
  </span>
</template>
