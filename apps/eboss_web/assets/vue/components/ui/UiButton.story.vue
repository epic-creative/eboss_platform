<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiButton from "./UiButton.vue"
</script>

<template>
  <Story
    title="UI/Button"
    :layout="{ type: 'grid', width: 300 }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Variants">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="flex flex-wrap gap-3">
            <UiButton>Primary</UiButton>
            <UiButton variant="outline" tone="neutral">Outline</UiButton>
            <UiButton variant="ghost" tone="neutral">Ghost</UiButton>
            <UiButton variant="subtle" tone="neutral">Subtle</UiButton>
          </div>
        </StorySurface>
      </Variant>

      <Variant title="States">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="flex flex-wrap gap-3">
            <UiButton size="sm">Small</UiButton>
            <UiButton>Medium</UiButton>
            <UiButton size="lg">Large</UiButton>
            <UiButton loading>Loading</UiButton>
            <UiButton disabled variant="outline" tone="neutral">Disabled</UiButton>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
