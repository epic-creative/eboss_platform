<script setup lang="ts">
import UiBadge from "../components/ui/UiBadge.vue"
import UiPanel from "../components/ui/UiPanel.vue"

defineProps<{
  username: string
  email: string
  workspaceLabel: string
  folioLabel: string
}>()
</script>

<template>
  <section class="ui-auth-scene">
    <div class="space-y-7">
      <div class="space-y-3">
        <UiBadge tone="neutral">Dashboard launchpad</UiBadge>
        <h2 class="ui-text-display" data-size="lg">The authenticated edge is ready.</h2>
        <p class="ui-text-body max-w-2xl" data-size="lg" data-tone="soft">
          This is the first thin shell for signed-in users. It is intentionally calm so the next product surfaces can grow without reworking the session boundary again.
        </p>
      </div>

      <div class="grid gap-3">
        <UiPanel class="ui-auth-scene__tile p-4" surface="solid">
          <p class="ui-text-meta" data-tone="primary">Current user</p>
          <p class="ui-text-title mt-2" data-size="md">{{ username }}</p>
          <p class="ui-text-body" data-size="sm" data-tone="soft">{{ email }}</p>
        </UiPanel>
        <UiPanel class="ui-auth-scene__tile p-4" surface="solid">
          <p class="ui-text-meta" data-tone="primary">Workspace surface</p>
          <p class="ui-text-body mt-2" data-tone="muted">{{ workspaceLabel }}</p>
        </UiPanel>
        <UiPanel class="ui-auth-scene__tile p-4" surface="solid">
          <p class="ui-text-meta" data-tone="primary">Folio surface</p>
          <p class="ui-text-body mt-2" data-tone="muted">{{ folioLabel }}</p>
        </UiPanel>
      </div>
    </div>
  </section>
</template>
