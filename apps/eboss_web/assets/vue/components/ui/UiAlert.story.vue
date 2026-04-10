<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiAlert from "./UiAlert.vue"
</script>

<template>
  <Story
    title="UI/Alert"
    :layout="{ type: 'grid', width: 360 }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Feedback">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3">
            <UiAlert tone="neutral" title="Operator note" description="Shared defaults stay grounded in shell tones." />
            <UiAlert tone="primary" title="Agent queue healthy" description="Work continues without operator intervention." />
            <UiAlert tone="success" title="Run approved" description="Execution can resume with the latest policy checks." />
            <UiAlert tone="warning" title="Review requested" description="A human decision is needed before the next branch executes." />
            <UiAlert tone="danger" title="Delivery failed" description="The external step did not acknowledge the request." />
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
