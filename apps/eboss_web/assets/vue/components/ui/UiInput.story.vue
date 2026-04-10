<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiInput from "./UiInput.vue"
</script>

<template>
  <Story
    title="UI/Input"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact', value: 'agent-run-001', invalid: '' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Field states">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid max-w-xl gap-4">
            <UiInput v-model="state.value" label="Run label" hint="Stable labels keep orchestration views scan-friendly." prefix="run/" />
            <UiInput label="Access key" value="orchestrator" suffix=".ai" />
            <UiInput label="Validation" error="A more descriptive label is required." value="x" />
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
