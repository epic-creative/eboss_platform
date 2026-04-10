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
        <UiBadge tone="warning">Dashboard launchpad</UiBadge>
        <h2 class="ui-heading text-3xl">The authenticated edge is ready.</h2>
        <p class="max-w-2xl text-sm leading-7 text-ui-text-soft">
          This is the first thin shell for signed-in users. It is intentionally calm so the next product surfaces can grow without reworking the session boundary again.
        </p>
      </div>

      <div class="grid gap-3">
        <UiPanel class="ui-auth-scene__tile p-4" surface="solid">
          <p class="ui-kicker text-ui-accent">Current user</p>
          <p class="mt-2 text-lg font-semibold">{{ username }}</p>
          <p class="text-sm text-ui-text-soft">{{ email }}</p>
        </UiPanel>
        <UiPanel class="ui-auth-scene__tile p-4" surface="solid">
          <p class="ui-kicker text-ui-accent">Workspace surface</p>
          <p class="mt-2 text-sm leading-6 text-ui-text-muted">{{ workspaceLabel }}</p>
        </UiPanel>
        <UiPanel class="ui-auth-scene__tile p-4" surface="solid">
          <p class="ui-kicker text-ui-accent">Folio surface</p>
          <p class="mt-2 text-sm leading-6 text-ui-text-muted">{{ folioLabel }}</p>
        </UiPanel>
      </div>
    </div>
  </section>
</template>
