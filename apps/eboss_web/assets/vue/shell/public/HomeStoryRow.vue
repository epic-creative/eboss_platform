<script setup lang="ts">
import UiBadge from "../../components/ui/UiBadge.vue"
import UiPanel from "../../components/ui/UiPanel.vue"
import type { StorySection } from "./content"

defineProps<{
  story: StorySection
}>()
</script>

<template>
  <section
    class="ui-home-story"
    :class="{ 'ui-home-story--reverse': story.reverse }"
    :data-home-story="story.id"
  >
    <div class="ui-home-story__copy">
      <div class="space-y-3">
        <UiBadge tone="neutral">{{ story.eyebrow }}</UiBadge>
        <div class="space-y-2">
          <h2 class="ui-text-title" data-size="lg">{{ story.title }}</h2>
          <p class="ui-text-body" data-tone="soft">{{ story.description }}</p>
        </div>
      </div>

      <div class="ui-home-hero__signals">
        <UiBadge v-for="signal in story.signals" :key="signal" tone="neutral">
          {{ signal }}
        </UiBadge>
      </div>
    </div>

    <UiPanel class="ui-home-story__frame ui-home-story-board" surface="floating" padding="lg">
      <div class="space-y-2">
        <p class="ui-text-meta" data-tone="soft">{{ story.panelTitle }}</p>
        <p class="ui-text-body" data-size="sm" data-tone="soft">{{ story.panelIntro }}</p>
      </div>

      <div class="ui-home-story-board__list">
        <div
          v-for="item in story.items"
          :key="`${story.id}-${item.label}`"
          class="ui-home-story-board__item"
        >
          <div class="ui-home-story-board__item-head">
            <p class="ui-text-body" data-size="sm">{{ item.label }}</p>
            <span class="ui-home-step-index">{{ item.meta }}</span>
          </div>
          <p class="ui-text-body" data-size="sm" data-tone="soft">{{ item.detail }}</p>
        </div>
      </div>

      <div class="ui-home-story-board__metrics">
        <div
          v-for="metric in story.metrics"
          :key="`${story.id}-${metric.label}`"
          class="ui-home-story-board__metric"
        >
          <span class="ui-text-meta" data-tone="soft">{{ metric.label }}</span>
          <span class="ui-text-body" data-size="sm">{{ metric.value }}</span>
        </div>
      </div>
    </UiPanel>
  </section>
</template>
