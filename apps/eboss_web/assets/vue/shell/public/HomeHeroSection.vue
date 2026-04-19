<script setup lang="ts">
import { ArrowRight } from "lucide-vue-next"

import UiBadge from "../../components/ui/UiBadge.vue"
import UiButton from "../../components/ui/UiButton.vue"
import UiPanel from "../../components/ui/UiPanel.vue"
import { consoleLines, consoleMeta, heroSignals } from "./content"
</script>

<template>
  <section class="ui-home-hero" data-home-hero data-testid="home-hero">
    <div class="ui-home-hero__copy">
      <div class="ui-home-hero__narrative">
        <UiBadge tone="neutral">{{ consoleMeta.kicker }}</UiBadge>
        <div class="space-y-3">
          <h1 class="ui-text-title" data-size="xl">
            Infrastructure for teams that ship with precision
          </h1>
          <p class="ui-text-body" data-size="lg" data-tone="soft">
            Workspace-aware platform with scoped access control, multi-tenant isolation, and an operator console designed for depth.
          </p>
        </div>
      </div>

      <div class="ui-home-hero__actions">
        <UiButton href="/register" size="sm" icon-position="trailing">
          Get started
          <template #icon>
            <ArrowRight class="h-3.5 w-3.5" />
          </template>
        </UiButton>
        <UiButton href="/sign-in" variant="outline" tone="neutral" size="sm">Sign in</UiButton>
      </div>

      <div class="ui-home-hero__signals">
        <UiBadge v-for="signal in heroSignals" :key="signal" tone="neutral">
          {{ signal }}
        </UiBadge>
      </div>
    </div>

    <UiPanel class="ui-home-hero__frame ui-home-console" surface="floating" padding="lg">
      <div class="ui-home-console__header">
        <div class="space-y-1">
          <p class="ui-text-meta" data-tone="soft">{{ consoleMeta.frameLabel }}</p>
          <p class="ui-text-body" data-size="sm">{{ consoleMeta.title }}</p>
        </div>

        <div class="ui-home-console__signals">
          <div
            v-for="signal in consoleMeta.highlightSignals"
            :key="signal.label"
            class="ui-home-console__signal"
          >
            <span class="ui-text-meta" data-tone="soft">{{ signal.label }}</span>
            <span class="ui-text-body" data-size="sm">{{ signal.value }}</span>
          </div>
        </div>
      </div>

      <div class="ui-home-console__body">
        <p
          v-for="(line, index) in consoleLines"
          :key="`console-line-${index}`"
          class="ui-home-console__line"
          :data-tone="line.startsWith('$') ? 'accent' : line.startsWith('✓') ? 'strong' : 'muted'"
        >
          {{ line || " " }}
        </p>
      </div>
    </UiPanel>
  </section>
</template>
