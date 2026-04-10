<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiPanel from "./UiPanel.vue"
</script>

<template>
  <Story
    title="UI/Panel"
    :layout="{ type: 'grid', width: 1120 }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact' })"
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
    </template>
  </Story>
</template>
