<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StoryStateCard from "../../stories/StoryStateCard.vue"
import StorySurface from "../../stories/StorySurface.vue"
import { createPreviewState } from "../../stories/review"
import UiPanel from "./UiPanel.vue"
</script>

<template>
  <Story
    title="UI/Panel"
    :layout="{ type: 'grid', width: 1120 }"
    :init-state="() => createPreviewState()"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Surface vocabulary">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-4 lg:grid-cols-3">
            <UiPanel class="space-y-3">
              <p class="ui-text-meta" data-tone="soft">Default surface</p>
              <p class="ui-text-title" data-size="md">Anchored section chrome.</p>
              <p class="ui-text-body" data-tone="muted">
                Use this for standard panels that sit directly in the shell and should feel grounded rather than lifted.
              </p>
            </UiPanel>
            <UiPanel surface="floating" class="space-y-3">
              <p class="ui-text-meta" data-tone="soft">Floating surface</p>
              <p class="ui-text-title" data-size="md">Raised shell-leading chrome.</p>
              <p class="ui-text-body" data-tone="muted">
                Use this for dialogs, featured panels, and moments that should visibly lift above the default shell plane.
              </p>
            </UiPanel>
            <UiPanel surface="solid" class="space-y-3">
              <p class="ui-text-meta" data-tone="soft">Solid surface</p>
              <p class="ui-text-title" data-size="md">Dense inset chrome.</p>
              <p class="ui-text-body" data-tone="muted">
                Use this for grouped content nested inside another panel or scene so the hierarchy tightens without adding extra lift.
              </p>
            </UiPanel>
          </div>
        </StorySurface>
      </Variant>

      <Variant title="Tone and padding states">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-3">
            <StoryStateCard state="neutral" copy="Default neutral shell treatment.">
              <UiPanel class="space-y-2">
                <p class="ui-text-title" data-size="md">Shell summary</p>
                <p class="ui-text-body" data-tone="muted">Neutral panels carry most dashboard sections.</p>
              </UiPanel>
            </StoryStateCard>

            <StoryStateCard state="primary" copy="Primary tone highlights a featured or active surface.">
              <UiPanel tone="primary" class="space-y-2">
                <p class="ui-text-title" data-size="md">Live signal</p>
                <p class="ui-text-body" data-tone="soft">Use sparingly when the panel itself should carry the product accent.</p>
              </UiPanel>
            </StoryStateCard>

            <StoryStateCard state="inverse" copy="Inverse panels tighten contrast for nested review moments.">
              <UiPanel tone="inverse" class="space-y-2">
                <p class="ui-text-title" data-size="md">Contrast review</p>
                <p class="ui-text-body" data-tone="soft">Useful for shell callouts that need more density without more elevation.</p>
              </UiPanel>
            </StoryStateCard>
          </div>

          <div class="mt-3 grid gap-3 lg:grid-cols-3">
            <StoryStateCard state="padding-sm" copy="Dense inset grouping.">
              <UiPanel padding="sm">
                <p class="ui-text-body" data-tone="muted">Small padding keeps nested metrics compact.</p>
              </UiPanel>
            </StoryStateCard>

            <StoryStateCard state="padding-md" copy="Default shell spacing.">
              <UiPanel padding="md">
                <p class="ui-text-body" data-tone="muted">Medium padding is the baseline panel rhythm.</p>
              </UiPanel>
            </StoryStateCard>

            <StoryStateCard state="padding-lg" copy="Expanded framing for featured or entry surfaces.">
              <UiPanel padding="lg">
                <p class="ui-text-body" data-tone="muted">Large padding gives breathing room without changing the panel family.</p>
              </UiPanel>
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
