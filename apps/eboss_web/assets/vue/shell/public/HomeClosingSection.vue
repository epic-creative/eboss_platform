<script setup lang="ts">
import { ArrowRight } from "lucide-vue-next"

import UiBadge from "../../components/ui/UiBadge.vue"
import UiButton from "../../components/ui/UiButton.vue"
import UiPanel from "../../components/ui/UiPanel.vue"
import { closingPanel, closingSignals } from "./content"
</script>

<template>
  <section class="ui-public-closing-section" data-home-closing>
    <UiPanel class="ui-public-cta" surface="floating" padding="lg">
      <div class="ui-public-cta__copy">
        <UiBadge tone="neutral">{{ closingPanel.eyebrow }}</UiBadge>
        <div class="space-y-2">
          <h2 class="ui-text-title" data-size="lg">{{ closingPanel.title }}</h2>
          <p class="ui-text-body" data-tone="soft">{{ closingPanel.description }}</p>
        </div>
      </div>

      <div class="ui-public-cta__actions">
        <UiButton href="/register" size="sm" icon-position="trailing">
          Create your workspace
          <template #icon>
            <ArrowRight class="h-3.5 w-3.5" />
          </template>
        </UiButton>
        <UiButton href="/sign-in" variant="outline" tone="neutral" size="sm">Sign in</UiButton>
      </div>

      <div class="ui-public-cta__details">
        <UiBadge v-for="signal in closingSignals" :key="signal" tone="neutral">
          {{ signal }}
        </UiBadge>
      </div>
    </UiPanel>
  </section>
</template>
