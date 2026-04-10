<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiSelect from "./UiSelect.vue"
</script>

<template>
  <Story
    title="UI/Select"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact', value: 'prod' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Environment selector">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="max-w-md">
            <UiSelect
              v-model="state.value"
              label="Environment"
              hint="Select inputs reuse the same shared shell."
              :options="[
                { label: 'Production', value: 'prod' },
                { label: 'Staging', value: 'staging' },
                { label: 'Development', value: 'dev' },
              ]"
            />
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
