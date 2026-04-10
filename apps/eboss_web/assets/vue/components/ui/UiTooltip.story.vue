<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiButton from "./UiButton.vue"
import UiTooltip from "./UiTooltip.vue"
</script>

<template>
  <Story
    title="UI/Tooltip"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Assistive copy">
        <StorySurface :theme="state.theme" :density="state.density">
          <UiTooltip content="This queue contains runs that are waiting on human approval.">
            <UiButton variant="outline" tone="neutral">Pending approvals</UiButton>
          </UiTooltip>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
