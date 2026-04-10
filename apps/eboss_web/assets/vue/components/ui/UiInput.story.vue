<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StoryStateCard from "../../stories/StoryStateCard.vue"
import StorySurface from "../../stories/StorySurface.vue"
import { createPreviewState } from "../../stories/review"
import UiInput from "./UiInput.vue"
</script>

<template>
  <Story
    title="UI/Input"
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
            <StoryStateCard state="valid" copy="Baseline field shell with hint text.">
              <UiInput
                label="Run label"
                model-value="agent-run-001"
                hint="Stable labels keep orchestration views scan-friendly."
                prefix="run/"
              />
            </StoryStateCard>

            <StoryStateCard state="invalid" copy="Error text and invalid chrome stay attached to the field shell.">
              <UiInput
                label="Validation"
                model-value="x"
                error="A more descriptive label is required."
              />
            </StoryStateCard>

            <StoryStateCard state="disabled" copy="Disabled fields keep context while stepping out of the focus order.">
              <UiInput
                label="Locked identifier"
                model-value="ops-production"
                hint="Assigned automatically from the workspace slug."
                disabled
              />
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>

      <Variant title="Decorators and scale">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-3 lg:grid-cols-3">
            <StoryStateCard state="sm" copy="Dense controls for compact operator surfaces.">
              <UiInput
                size="sm"
                label="Search"
                model-value="policy"
                placeholder="Search"
              />
            </StoryStateCard>

            <StoryStateCard state="md" copy="Default shell rhythm for most form layouts.">
              <UiInput
                label="Access key"
                model-value="orchestrator"
                suffix=".ai"
              />
            </StoryStateCard>

            <StoryStateCard state="lg" copy="Larger input footprint for high-focus entry points.">
              <UiInput
                size="lg"
                label="Workspace slug"
                model-value="platform-ops"
                prefix="team/"
              />
            </StoryStateCard>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
