<script setup lang="ts">
defineProps<{
  title: string
  copy: string
}>()
</script>

<template>
  <div class="ui-empty-state">
    <div class="space-y-2">
      <p class="ui-empty-state__title">{{ title }}</p>
      <p class="ui-empty-state__copy">{{ copy }}</p>
    </div>
    <div v-if="$slots.actions" class="flex flex-wrap gap-3">
      <slot name="actions" />
    </div>
  </div>
</template>
