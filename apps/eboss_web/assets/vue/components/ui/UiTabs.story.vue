<script setup lang="ts">
import StoryControls from "../../stories/StoryControls.vue"
import StorySurface from "../../stories/StorySurface.vue"
import UiTabs from "./UiTabs.vue"
</script>

<template>
  <Story
    title="UI/Tabs"
    :layout="{ type: 'single', iframe: false }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact', activeTab: 'runs' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Workspace tabs">
        <StorySurface :theme="state.theme" :density="state.density">
          <UiTabs
            v-model="state.activeTab"
            :items="[
              { value: 'runs', label: 'Runs', copy: 'Track queue health, execution results, and blocked branches.' },
              { value: 'agents', label: 'Agents', copy: 'Inspect agent health, policies, and assigned work.' },
              { value: 'audit', label: 'Audit', copy: 'Review approvals, overrides, and external side effects.' },
            ]"
          />
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
