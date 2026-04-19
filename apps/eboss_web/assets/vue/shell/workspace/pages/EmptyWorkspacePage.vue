<script setup lang="ts">
import WorkspaceEmptyState from "../WorkspaceEmptyState.vue"

defineProps<{
  dashboardPath: string
}>()
</script>

<template>
  <div data-testid="workspace-page-empty">
    <WorkspaceEmptyState
    title="No accessible workspaces yet"
    copy="The signed-in shell is active, but this account does not have a workspace route to mount yet."
    dashed
    >
      <template #actions>
        <a href="/" class="so-button-secondary">Back to home</a>
        <a :href="dashboardPath" class="so-button-primary">Refresh route</a>
      </template>
    </WorkspaceEmptyState>
  </div>
</template>
