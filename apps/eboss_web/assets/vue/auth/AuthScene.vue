<script setup lang="ts">
import UiBadge from "../components/ui/UiBadge.vue"
import UiPanel from "../components/ui/UiPanel.vue"

defineProps<{
  eyebrow: string
  title: string
  subtitle: string
  detailOne: string
  detailTwo: string
  detailThree: string
}>()
</script>

<template>
  <section class="ui-auth-scene">
    <div class="space-y-7">
      <div class="space-y-4">
        <UiBadge tone="warning">{{ eyebrow }}</UiBadge>
        <div class="space-y-3">
          <h2 class="ui-text-display" data-size="xl">{{ title }}</h2>
          <p class="ui-text-body max-w-2xl" data-size="lg" data-tone="soft">{{ subtitle }}</p>
        </div>
      </div>

      <div class="grid gap-3">
        <UiPanel class="ui-auth-scene__tile p-4" surface="solid">
          <p class="ui-text-meta" data-tone="accent">Flow one</p>
          <p class="ui-text-body mt-2" data-tone="muted">{{ detailOne }}</p>
        </UiPanel>
        <UiPanel class="ui-auth-scene__tile p-4" surface="solid">
          <p class="ui-text-meta" data-tone="accent">Flow two</p>
          <p class="ui-text-body mt-2" data-tone="muted">{{ detailTwo }}</p>
        </UiPanel>
        <UiPanel class="ui-auth-scene__tile p-4" surface="solid">
          <p class="ui-text-meta" data-tone="accent">Flow three</p>
          <p class="ui-text-body mt-2" data-tone="muted">{{ detailThree }}</p>
        </UiPanel>
      </div>
    </div>
  </section>
</template>
