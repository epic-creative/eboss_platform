<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StoryStateCard from "../../stories/StoryStateCard.vue"
import StorySurface from "../../stories/StorySurface.vue"
import { createPreviewState } from "../../stories/review"
import UiButton from "./UiButton.vue"
import UiTooltip from "./UiTooltip.vue"

const placements = [
  { state: "top", side: "top" },
  { state: "right", side: "right" },
  { state: "bottom", side: "bottom" },
  { state: "left", side: "left" },
] as const
</script>

<template>
  <Story
    title="UI/Tooltip"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => createPreviewState()"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Placement review">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-2">
            <StoryStateCard
              v-for="placement in placements"
              :key="placement.state"
              :state="placement.state"
              copy="Use the same shell and arrow treatment regardless of placement."
            >
              <div class="flex min-h-32 items-center justify-center">
                <UiTooltip
                  open
                  :side="placement.side"
                  content="This queue contains runs that are waiting on human approval."
                >
                  <UiButton variant="outline" tone="neutral">Pending approvals</UiButton>
                </UiTooltip>
              </div>
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>

      <Variant title="Interactive default">
        <StorySurface :theme="state.theme" :density="state.density">
          <StoryStateCard
            state="hover"
            copy="Omit the controlled open prop in product use so hover and focus drive the tooltip."
          >
            <UiTooltip content="This queue contains runs that are waiting on human approval.">
              <UiButton variant="outline" tone="neutral">Pending approvals</UiButton>
            </UiTooltip>
          </StoryStateCard>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
