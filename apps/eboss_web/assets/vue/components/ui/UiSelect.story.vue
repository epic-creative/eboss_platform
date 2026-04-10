<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StoryStateCard from "../../stories/StoryStateCard.vue"
import StorySurface from "../../stories/StorySurface.vue"
import { createPreviewState } from "../../stories/review"
import UiSelect from "./UiSelect.vue"

const environmentOptions = [
  { label: "Production", value: "prod" },
  { label: "Staging", value: "staging" },
  { label: "Development", value: "dev" },
  { label: "Archived", value: "archived", disabled: true },
]
</script>

<template>
  <Story
    title="UI/Select"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => createPreviewState()"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Field states">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-2">
            <StoryStateCard state="valid" copy="Default select shell with supporting hint text.">
              <UiSelect
                model-value="prod"
                label="Environment"
                hint="Select inputs reuse the same shared shell."
                :options="environmentOptions"
              />
            </StoryStateCard>

            <StoryStateCard state="prompt" copy="Prompt mode keeps the shell stable before a choice exists.">
              <UiSelect
                model-value=""
                label="Region"
                prompt="Choose a region"
                :options="[
                  { label: 'US Central', value: 'us-central' },
                  { label: 'US East', value: 'us-east' },
                  { label: 'EU West', value: 'eu-west' },
                ]"
              />
            </StoryStateCard>

            <StoryStateCard state="invalid" copy="Error copy attaches to the same field contract used by input and textarea.">
              <UiSelect
                model-value=""
                label="Approval route"
                invalid
                :errors="['Choose a route before continuing.']"
                prompt="Select a route"
                :options="[
                  { label: 'Human review', value: 'human' },
                  { label: 'Auto-approve', value: 'auto' },
                ]"
              />
            </StoryStateCard>

            <StoryStateCard state="disabled" copy="Disabled selects retain context without implying that the option list is interactive.">
              <UiSelect
                model-value="archived"
                label="Archived environment"
                hint="Readonly after workspace retirement."
                :options="environmentOptions"
                disabled
              />
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
