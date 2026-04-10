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
          <h2 class="ui-heading text-3xl sm:text-4xl">{{ title }}</h2>
          <p class="max-w-2xl text-sm leading-7 text-ui-text-soft sm:text-base">{{ subtitle }}</p>
        </div>
      </div>

      <div class="grid gap-3">
        <UiPanel class="ui-auth-scene__tile p-4" surface="solid">
          <p class="ui-kicker text-ui-accent">Flow one</p>
          <p class="mt-2 text-sm leading-6 text-ui-text-muted">{{ detailOne }}</p>
        </UiPanel>
        <UiPanel class="ui-auth-scene__tile p-4" surface="solid">
          <p class="ui-kicker text-ui-accent">Flow two</p>
          <p class="mt-2 text-sm leading-6 text-ui-text-muted">{{ detailTwo }}</p>
        </UiPanel>
        <UiPanel class="ui-auth-scene__tile p-4" surface="solid">
          <p class="ui-kicker text-ui-accent">Flow three</p>
          <p class="mt-2 text-sm leading-6 text-ui-text-muted">{{ detailThree }}</p>
        </UiPanel>
      </div>
    </div>
  </section>
</template>
