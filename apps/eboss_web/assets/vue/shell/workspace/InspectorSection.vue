<script setup lang="ts">
defineProps<{
  title?: string
  withDivider?: boolean
}>()
</script>

<template>
  <section class="space-y-2.5" :class="withDivider ? 'border-t border-[hsl(var(--so-border))] pt-3' : ''">
    <h4
      v-if="title"
      class="so-font-mono mb-2 text-[11px] text-[hsl(var(--so-muted-foreground))]"
    >
      {{ title }}
    </h4>
    <slot />
  </section>
</template>
