<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StoryStateCard from "../../stories/StoryStateCard.vue"
import StorySurface from "../../stories/StorySurface.vue"
import { createPreviewState } from "../../stories/review"
import UiTextarea from "./UiTextarea.vue"
</script>

<template>
  <Story
    title="UI/Textarea"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => createPreviewState()"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Field states">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-3">
            <StoryStateCard state="valid" copy="Baseline long-form field with hint text.">
              <UiTextarea
                label="Run prompt"
                model-value="Summarize stalled agents and approvals."
                hint="Long-form product inputs use the same field contract."
              />
            </StoryStateCard>

            <StoryStateCard state="invalid" copy="Error treatment should match the shared input shell.">
              <UiTextarea
                label="Escalation summary"
                model-value="Need help"
                error="Add the triggering run, owner, and current blocker."
              />
            </StoryStateCard>

            <StoryStateCard state="disabled" copy="Disabled textareas preserve copy hierarchy without implying editability.">
              <UiTextarea
                label="Imported summary"
                model-value="Generated from the upstream audit package."
                hint="This field is locked because the source of truth is external."
                disabled
              />
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>

      <Variant title="Rows and scale">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-2">
            <StoryStateCard state="compact" copy="Short multi-line notes for dense layouts.">
              <UiTextarea
                size="sm"
                :rows="3"
                label="Review note"
                model-value="Pending confirmation from the workspace owner."
              />
            </StoryStateCard>

            <StoryStateCard state="expanded" copy="Roomier drafting surface for high-focus entry moments.">
              <UiTextarea
                size="lg"
                :rows="6"
                label="Remediation plan"
                model-value="1. Confirm destination policy scope. 2. Retry the sync with dry-run disabled. 3. Capture the approval ID for audit."
              />
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
