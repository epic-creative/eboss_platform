<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StoryStateCard from "../../stories/StoryStateCard.vue"
import StorySurface from "../../stories/StorySurface.vue"
import { createPreviewState } from "../../stories/review"
import UiButton from "./UiButton.vue"
</script>

<template>
  <Story
    title="UI/Button"
    :layout="{ type: 'grid', width: 1120 }"
    :init-state="() => createPreviewState()"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Variant vocabulary">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-4">
            <StoryStateCard state="solid" copy="Primary commitment and shell-leading actions.">
              <UiButton>Open workspace</UiButton>
            </StoryStateCard>
            <StoryStateCard state="outline" copy="Secondary actions that still need a visible frame.">
              <UiButton variant="outline" tone="neutral">Inspect shell</UiButton>
            </StoryStateCard>
            <StoryStateCard state="ghost" copy="Inline actions that should stay quiet until hover or focus.">
              <UiButton variant="ghost" tone="neutral">View details</UiButton>
            </StoryStateCard>
            <StoryStateCard state="subtle" copy="Muted contextual actions that still read as interactive.">
              <UiButton variant="subtle" tone="neutral">Save draft</UiButton>
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>

      <Variant title="State coverage">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-4">
            <StoryStateCard state="default" copy="Baseline button treatment.">
              <UiButton>Run checks</UiButton>
            </StoryStateCard>
            <StoryStateCard state="loading" copy="Busy actions keep their footprint while the spinner replaces the icon slot.">
              <UiButton loading>Running checks</UiButton>
            </StoryStateCard>
            <StoryStateCard state="disabled" copy="Disabled controls keep the same shape without inviting action.">
              <UiButton disabled variant="outline" tone="neutral">Awaiting approval</UiButton>
            </StoryStateCard>
            <StoryStateCard state="disabled-link" copy="Disabled links fall back to a non-focusable shell-safe element.">
              <UiButton disabled href="/review" variant="outline" tone="neutral">Open report</UiButton>
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>

      <Variant title="Scale and semantic tones">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3">
            <div class="flex flex-wrap gap-3">
              <UiButton size="sm">Small</UiButton>
              <UiButton>Medium</UiButton>
              <UiButton size="lg">Large</UiButton>
            </div>

            <div class="flex flex-wrap gap-3">
              <UiButton tone="primary">Primary</UiButton>
              <UiButton tone="neutral">Neutral</UiButton>
              <UiButton tone="success">Success</UiButton>
              <UiButton tone="warning">Warning</UiButton>
              <UiButton tone="danger">Danger</UiButton>
            </div>

            <div class="flex flex-wrap gap-3">
              <UiButton variant="outline" tone="primary">Primary outline</UiButton>
              <UiButton variant="outline" tone="neutral">Neutral outline</UiButton>
              <UiButton variant="outline" tone="success">Success outline</UiButton>
              <UiButton variant="outline" tone="warning">Warning outline</UiButton>
              <UiButton variant="outline" tone="danger">Danger outline</UiButton>
            </div>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
