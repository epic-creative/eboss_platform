<script setup lang="ts">
import UiBadge from "../../components/ui/UiBadge.vue"
import UiPanel from "../../components/ui/UiPanel.vue"
import { proofBandHeading, proofCards } from "./content"
</script>

<template>
  <section class="ui-home-proof-strip" data-home-proof-strip>
    <div class="space-y-3">
      <UiBadge tone="neutral">{{ proofBandHeading.eyebrow }}</UiBadge>
      <div class="space-y-2">
        <h2 class="ui-text-title" data-size="lg">{{ proofBandHeading.title }}</h2>
        <p class="ui-text-body" data-tone="soft">{{ proofBandHeading.description }}</p>
      </div>
    </div>

    <div class="ui-home-proof-grid">
      <UiPanel
        v-for="card in proofCards"
        :key="card.label"
        class="ui-home-proof-card"
        surface="solid"
        padding="md"
      >
        <div class="ui-home-proof-card__header">
          <component :is="card.icon" class="ui-home-proof-card__icon" />
          <p class="ui-text-body" data-size="sm">{{ card.label }}</p>
        </div>
        <p class="ui-text-body" data-size="sm" data-tone="soft">{{ card.desc }}</p>
      </UiPanel>
    </div>
  </section>
</template>
