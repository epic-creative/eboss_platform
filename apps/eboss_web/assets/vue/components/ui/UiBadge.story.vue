<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiBadge from "./UiBadge.vue"
</script>

<template>
  <Story
    title="UI/Badge"
    :layout="{ type: 'grid', width: 220 }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Tones">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="flex flex-wrap gap-3">
            <UiBadge>Neutral</UiBadge>
            <UiBadge tone="primary">Primary</UiBadge>
            <UiBadge tone="success">Success</UiBadge>
            <UiBadge tone="warning">Warning</UiBadge>
            <UiBadge tone="danger">Danger</UiBadge>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
