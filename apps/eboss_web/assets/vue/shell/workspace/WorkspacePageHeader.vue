<script setup lang="ts">
defineProps<{
  title: string
  subtitle?: string
}>()
</script>

<template>
  <div class="ui-workspace-page__header">
    <div class="ui-workspace-page__heading">
      <h1 class="ui-workspace-page__title">{{ title }}</h1>
      <p v-if="subtitle" class="ui-workspace-page__subtitle so-font-mono">
        {{ subtitle }}
      </p>
    </div>

    <div v-if="$slots.actions" class="ui-workspace-page__actions">
      <slot name="actions" />
    </div>
  </div>
</template>
