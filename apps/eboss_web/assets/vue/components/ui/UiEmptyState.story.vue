<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StoryStateCard from "../../stories/StoryStateCard.vue"
import StorySurface from "../../stories/StorySurface.vue"
import { createPreviewState } from "../../stories/review"
import UiButton from "./UiButton.vue"
import UiEmptyState from "./UiEmptyState.vue"
</script>

<template>
  <Story
    title="UI/Empty State"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => createPreviewState()"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Fallback states">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-2">
            <StoryStateCard
              state="with-actions"
              copy="Use actions when the empty state has a clear next move."
              stretch
            >
              <UiEmptyState
                title="No active runs"
                copy="This queue is quiet. Start a run, sync an integration, or open a saved orchestration plan."
              >
                <template #actions>
                  <UiButton>Start a run</UiButton>
                  <UiButton variant="outline" tone="neutral">Import plan</UiButton>
                </template>
              </UiEmptyState>
            </StoryStateCard>

            <StoryStateCard
              state="without-actions"
              copy="Keep the shell and copy hierarchy when the user only needs context."
              stretch
            >
              <UiEmptyState
                title="No review notes yet"
                copy="Notes will appear here after an operator captures remediation detail during a blocked run."
              />
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
