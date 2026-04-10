<script setup lang="ts">
withDefaults(
  defineProps<{
    label?: string
    size?: "sm" | "md" | "lg"
  }>(),
  {
    label: "Loading",
    size: "md",
  },
)
</script>

<template>
  <span class="inline-flex items-center gap-2">
    <span class="ui-spinner" :data-size="size" aria-hidden="true" />
    <span v-if="label" class="sr-only">{{ label }}</span>
  </span>
</template>
