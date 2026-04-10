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
  <section class="ui-dashboard-launchpad">
    <div class="ui-dashboard-launchpad__hero">
      <div class="space-y-3">
        <div class="flex flex-wrap items-center gap-2">
          <UiBadge tone="neutral">Dashboard route</UiBadge>
          <UiBadge tone="neutral">Shell adopted</UiBadge>
        </div>
        <div class="space-y-2">
          <h2 class="ui-text-display" data-size="lg">The operator shell now frames the real dashboard.</h2>
          <p class="ui-text-body max-w-3xl" data-size="lg" data-tone="soft">
            The main signed-in route keeps its launch surface, summaries, and next steps inside the shared EBoss shell so new authenticated pages can reuse the same product frame.
          </p>
        </div>
      </div>

      <div class="ui-dashboard-launchpad__signals">
        <div class="ui-dashboard-launchpad__signal">
          <p class="ui-text-meta" data-tone="primary">Signed in as</p>
          <p class="ui-text-title mt-2" data-size="sm">@{{ username }}</p>
          <p class="ui-text-body" data-size="sm" data-tone="soft">{{ email }}</p>
        </div>
        <div class="ui-dashboard-launchpad__signal">
          <p class="ui-text-meta" data-tone="primary">Session frame</p>
          <p class="ui-text-body mt-2" data-size="sm" data-tone="soft">
            Navigation, theme controls, and sign-out stay pinned to the shell chrome.
          </p>
        </div>
      </div>
    </div>

    <div class="ui-dashboard-launchpad__grid">
      <UiPanel class="ui-dashboard-launchpad__tile" surface="solid" padding="sm">
        <p class="ui-text-meta" data-tone="primary">Workspace surface</p>
        <p class="ui-text-body mt-2" data-tone="muted">{{ workspaceLabel }}</p>
      </UiPanel>
      <UiPanel class="ui-dashboard-launchpad__tile" surface="solid" padding="sm">
        <p class="ui-text-meta" data-tone="primary">Folio surface</p>
        <p class="ui-text-body mt-2" data-tone="muted">{{ folioLabel }}</p>
      </UiPanel>
      <UiPanel class="ui-dashboard-launchpad__tile" surface="solid" padding="sm">
        <p class="ui-text-meta" data-tone="primary">Route behavior</p>
        <p class="ui-text-body mt-2" data-tone="muted">
          Working panels stay in the dashboard body while operator identity remains in the shell.
        </p>
      </UiPanel>
      <UiPanel class="ui-dashboard-launchpad__tile" surface="solid" padding="sm">
        <p class="ui-text-meta" data-tone="primary">Next authenticated surfaces</p>
        <p class="ui-text-body mt-2" data-tone="muted">
          Additional signed-in routes can plug into this layout without resetting the surrounding frame.
        </p>
      </UiPanel>
    </div>
  </section>
</template>
