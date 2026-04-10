<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiButton from "./UiButton.vue"
import UiEmptyState from "./UiEmptyState.vue"
</script>

<template>
  <Story
    title="UI/Empty State"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="No runs">
        <StorySurface :theme="state.theme" :density="state.density">
          <UiEmptyState
            title="No active runs"
            copy="This queue is quiet. Start a run, sync an integration, or open a saved orchestration plan."
          >
            <template #actions>
              <UiButton>Start a run</UiButton>
              <UiButton variant="outline" tone="neutral">Import plan</UiButton>
            </template>
          </UiEmptyState>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
