<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiButton from "./UiButton.vue"
import UiDialog from "./UiDialog.vue"
</script>

<template>
  <Story
    title="UI/Dialog"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact', open: false })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Approval modal">
        <StorySurface :theme="state.theme" :density="state.density">
          <UiDialog
            v-model:open="state.open"
            title="Approve sensitive step"
            description="Confirm that the agent can continue with external changes."
          >
            <template #trigger>
              <UiButton>Open dialog</UiButton>
            </template>

            <div class="space-y-4">
              <p class="ui-copy-muted">
                This wrapper uses Reka UI for behavior while preserving the same first-party surface language.
              </p>
              <div class="flex gap-3">
                <UiButton @click="state.open = false">Approve</UiButton>
                <UiButton variant="outline" tone="neutral" @click="state.open = false">Cancel</UiButton>
              </div>
            </div>
          </UiDialog>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
