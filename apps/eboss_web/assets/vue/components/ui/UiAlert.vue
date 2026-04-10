<script setup lang="ts">
withDefaults(
  defineProps<{
    tone?: "primary" | "neutral" | "success" | "warning" | "danger"
    title?: string
    description?: string
  }>(),
  {
    tone: "neutral",
    title: undefined,
    description: undefined,
  },
)
</script>

<template>
  <div class="ui-alert" :data-tone="tone">
    <div class="ui-alert__content">
      <p v-if="title" class="ui-alert__title">{{ title }}</p>
      <p v-if="description" class="ui-alert__description">{{ description }}</p>
      <div v-if="$slots.default" class="ui-alert__description">
        <slot />
      </div>
    </div>
  </div>
</template>
