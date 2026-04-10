<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiSpinner from "./UiSpinner.vue"
</script>

<template>
  <Story
    title="UI/Spinner"
    :layout="{ type: 'grid', width: 180 }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Sizes">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="flex items-center gap-4">
            <UiSpinner size="sm" />
            <UiSpinner size="md" />
            <UiSpinner size="lg" />
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
