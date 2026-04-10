<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StoryStateCard from "../../stories/StoryStateCard.vue"
import StorySurface from "../../stories/StorySurface.vue"
import { createPreviewState } from "../../stories/review"
import UiBadge from "./UiBadge.vue"
import UiTabs from "./UiTabs.vue"

const workspaceTabs = [
  { value: "runs", label: "Runs", copy: "Track queue health, execution results, and blocked branches." },
  { value: "agents", label: "Agents", copy: "Inspect agent health, policies, and assigned work." },
  { value: "audit", label: "Audit", copy: "Review approvals, overrides, and external side effects." },
]
</script>

<template>
  <Story
    title="UI/Tabs"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => createPreviewState({ activeTab: 'runs' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Workspace navigation">
        <StorySurface :theme="state.theme" :density="state.density">
          <StoryStateCard
            state="interactive"
            copy="Tab triggers and active content should feel like the same shell system as HEEx nav pills."
            stretch
          >
            <UiTabs v-model="state.activeTab" :items="workspaceTabs" />
          </StoryStateCard>
        </StorySurface>
      </Variant>

      <Variant title="Custom content slots">
        <StorySurface :theme="state.theme" :density="state.density">
          <StoryStateCard
            state="custom-content"
            copy="Use named slots when each tab needs richer framing than a single paragraph."
            stretch
          >
            <UiTabs model-value="agents" :items="workspaceTabs">
              <template #content-agents>
                <div class="space-y-3">
                  <div class="flex flex-wrap gap-2">
                    <UiBadge tone="success">Healthy</UiBadge>
                    <UiBadge tone="warning">1 needs review</UiBadge>
                  </div>
                  <p class="ui-text-body" data-tone="muted">
                    Operator rosters can add badges, lists, or compact metrics without changing the tab shell.
                  </p>
                </div>
              </template>
            </UiTabs>
          </StoryStateCard>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
