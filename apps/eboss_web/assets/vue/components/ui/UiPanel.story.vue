<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiPanel from "./UiPanel.vue"
</script>

<template>
  <Story
    title="UI/Panel"
    :layout="{ type: 'grid', width: 360 }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Surfaces">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-4">
            <UiPanel surface="default">Default panel chrome for standard sections.</UiPanel>
            <UiPanel surface="floating">Floating panel chrome for key surfaces.</UiPanel>
            <UiPanel tone="inverse" surface="solid">Inverse panel chrome for high-emphasis content.</UiPanel>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
