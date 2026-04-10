<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StoryStateCard from "../../stories/StoryStateCard.vue"
import StorySurface from "../../stories/StorySurface.vue"
import { createPreviewState } from "../../stories/review"
import UiAlert from "./UiAlert.vue"

const alerts = [
  {
    state: "neutral",
    tone: "neutral",
    title: "Operator note",
    description: "Default feedback stays grounded in the same shell palette as the rest of the product.",
  },
  {
    state: "primary",
    tone: "primary",
    title: "Queue scheduled",
    description: "The next orchestration step is active and using the primary product signal.",
  },
  {
    state: "success",
    tone: "success",
    title: "Run approved",
    description: "Execution can continue because the latest policy checks have passed.",
  },
  {
    state: "warning",
    tone: "warning",
    title: "Human review requested",
    description: "A sensitive branch is waiting for operator input.",
  },
  {
    state: "danger",
    tone: "danger",
    title: "Delivery failed",
    description: "The external system did not acknowledge the previous step.",
  },
] as const
</script>

<template>
  <Story
    title="UI/Alert"
    :layout="{ type: 'grid', width: 960 }"
    :init-state="() => createPreviewState()"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Feedback tones">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-2">
            <StoryStateCard
              v-for="alert in alerts"
              :key="alert.state"
              :state="alert.state"
              stretch
            >
              <UiAlert :tone="alert.tone" :title="alert.title" :description="alert.description" />
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>

      <Variant title="Content contracts">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-3">
            <StoryStateCard
              state="description-only"
              copy="Use title and description when the message can stay compact."
              stretch
            >
              <UiAlert
                tone="primary"
                title="Queue scheduled"
                description="The next orchestration step is active and using the primary product signal."
              />
            </StoryStateCard>

            <StoryStateCard
              state="slotted-detail"
              copy="Use the default slot when the feedback needs richer supporting detail."
              stretch
            >
              <UiAlert tone="warning" title="Human review requested">
                Approval is blocked until an operator confirms the destination workspace and policy scope.
              </UiAlert>
            </StoryStateCard>

            <StoryStateCard
              state="escalation"
              copy="Reserve danger for hard failures that need immediate intervention."
              stretch
            >
              <UiAlert tone="danger" title="Delivery failed">
                The external system did not acknowledge the previous step, so the run has been halted.
              </UiAlert>
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
