<script setup lang="ts">
import { computed, ref } from "vue"
import UiBadge from "./components/ui/UiBadge.vue"
import UiButton from "./components/ui/UiButton.vue"
import UiEmptyState from "./components/ui/UiEmptyState.vue"
import UiPanel from "./components/ui/UiPanel.vue"

const props = defineProps<{
  count: number
  headline: string
  subhead: string
}>()

const detailsOpen = ref(true)

const countParity = computed(() => (props.count % 2 === 0 ? "even" : "odd"))
</script>

<template>
  <UiPanel surface="floating" class="p-6">
    <div class="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
      <div class="space-y-2">
        <UiBadge tone="primary">Frontend foundation</UiBadge>
        <h2 class="ui-text-display" data-size="lg">{{ headline }}</h2>
        <p class="ui-text-body max-w-2xl" data-tone="soft">{{ subhead }}</p>
      </div>

      <UiButton variant="ghost" tone="neutral" size="sm" class="self-start" @click="detailsOpen = !detailsOpen">
        {{ detailsOpen ? "Hide details" : "Show details" }}
      </UiButton>
    </div>

    <div v-if="detailsOpen" class="mt-6 grid gap-4 lg:grid-cols-[1.15fr_0.85fr]">
      <UiPanel surface="solid" class="p-5">
        <p class="ui-text-body" data-size="sm" data-tone="soft">LiveView state over LiveVue props</p>

        <div class="mt-4 flex items-end gap-3">
          <span class="ui-text-display" data-size="hero">{{ count }}</span>
          <UiBadge tone="primary">{{ countParity }}</UiBadge>
        </div>

        <div class="mt-5 flex flex-wrap gap-3">
          <UiButton @click="$live.pushEvent('increment', {})">Increment</UiButton>
          <UiButton variant="outline" tone="neutral" @click="$live.pushEvent('reset', {})">
            Reset
          </UiButton>
        </div>
      </UiPanel>

      <UiEmptyState
        title="Client-only Vue state"
        copy="This panel toggle stays entirely in Vue. The count card updates from LiveView through the same mounted component."
      />
    </div>
  </UiPanel>
</template>
