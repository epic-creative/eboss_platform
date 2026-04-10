<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StoryStateCard from "../../stories/StoryStateCard.vue"
import StorySurface from "../../stories/StorySurface.vue"
import { createPreviewState } from "../../stories/review"
import UiBadge from "./UiBadge.vue"

const badges = [
  { state: "neutral", tone: "neutral", label: "Queued" },
  { state: "primary", tone: "primary", label: "In progress" },
  { state: "success", tone: "success", label: "Healthy" },
  { state: "warning", tone: "warning", label: "Needs review" },
  { state: "danger", tone: "danger", label: "Blocked" },
] as const
</script>

<template>
  <Story
    title="UI/Badge"
    :layout="{ type: 'grid', width: 960 }"
    :init-state="() => createPreviewState()"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Operational tones">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-5">
            <StoryStateCard
              v-for="badge in badges"
              :key="badge.state"
              :state="badge.state"
              copy="Compact queue status"
            >
              <UiBadge :tone="badge.tone">{{ badge.label }}</UiBadge>
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
