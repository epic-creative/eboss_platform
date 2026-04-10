<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiTextarea from "./UiTextarea.vue"
</script>

<template>
  <Story
    title="UI/Textarea"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact', prompt: 'Summarize stalled agents and approvals.' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Composer">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="max-w-2xl">
            <UiTextarea v-model="state.prompt" label="Run prompt" hint="Long-form product inputs use the same field contract." />
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
