<script setup lang="ts">
import { computed } from "vue"

const props = defineProps<{
  label: string
  value?: string
  valueClass?: string
  mono?: boolean
}>()

const valueClasses = computed(() => [
  "text-xs",
  props.mono ? "so-font-mono" : "",
  props.valueClass ?? "text-[hsl(var(--so-muted-foreground))]",
])
</script>

<template>
  <div class="flex items-center justify-between gap-2">
    <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">{{ label }}</span>
    <span :class="valueClasses">
      <slot>{{ value }}</slot>
    </span>
  </div>
</template>
