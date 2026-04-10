<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StoryStateCard from "../../stories/StoryStateCard.vue"
import StorySurface from "../../stories/StorySurface.vue"
import { createPreviewState } from "../../stories/review"
import UiButton from "./UiButton.vue"
import UiDialog from "./UiDialog.vue"
</script>

<template>
  <Story
    title="UI/Dialog"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => createPreviewState({ approvalOpen: false, destructiveOpen: false })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Review flows">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-2">
            <StoryStateCard
              state="approval"
              copy="Click the trigger to inspect the default open state and action stack."
            >
              <UiDialog
                v-model:open="state.approvalOpen"
                title="Approve sensitive step"
                description="Confirm that the agent can continue with external changes."
              >
                <template #trigger>
                  <UiButton>Open approval dialog</UiButton>
                </template>

                <div class="space-y-4">
                  <p class="ui-text-body" data-tone="soft">
                    This wrapper uses Reka UI for behavior while preserving the same first-party surface language.
                  </p>
                  <div class="flex gap-3">
                    <UiButton @click="state.approvalOpen = false">Approve</UiButton>
                    <UiButton variant="outline" tone="neutral" @click="state.approvalOpen = false">Cancel</UiButton>
                  </div>
                </div>
              </UiDialog>
            </StoryStateCard>

            <StoryStateCard
              state="destructive"
              copy="Use warning or danger action tone only when the dialog truly interrupts the workflow."
            >
              <UiDialog
                v-model:open="state.destructiveOpen"
                title="Remove saved workspace"
                description="This clears pinned filters and review notes for the whole operator group."
              >
                <template #trigger>
                  <UiButton variant="outline" tone="danger">Open destructive dialog</UiButton>
                </template>

                <div class="space-y-4">
                  <p class="ui-text-body" data-tone="soft">
                    Keep the panel shell the same even when the consequence changes. Urgency should come from tone and copy.
                  </p>
                  <div class="flex gap-3">
                    <UiButton tone="danger" @click="state.destructiveOpen = false">Remove workspace</UiButton>
                    <UiButton variant="outline" tone="neutral" @click="state.destructiveOpen = false">Keep it</UiButton>
                  </div>
                </div>
              </UiDialog>
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
