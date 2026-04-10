<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StoryStateCard from "../../stories/StoryStateCard.vue"
import StorySurface from "../../stories/StorySurface.vue"
import { createPreviewState } from "../../stories/review"
import UiSpinner from "./UiSpinner.vue"
</script>

<template>
  <Story
    title="UI/Spinner"
    :layout="{ type: 'grid', width: 960 }"
    :init-state="() => createPreviewState()"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Sizes">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-3">
            <StoryStateCard state="sm" copy="Inline for compact buttons and metadata rows.">
              <UiSpinner size="sm" />
            </StoryStateCard>
            <StoryStateCard state="md" copy="Default shell loading feedback.">
              <UiSpinner size="md" />
            </StoryStateCard>
            <StoryStateCard state="lg" copy="High-focus loading state for roomy surfaces.">
              <UiSpinner size="lg" />
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
