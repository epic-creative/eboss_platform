<script setup lang="ts">
import AuthScene from "../auth/AuthScene.vue"
import UiBadge from "../components/ui/UiBadge.vue"
import UiButton from "../components/ui/UiButton.vue"
import UiPanel from "../components/ui/UiPanel.vue"
import StoryControls from "./StoryControls.vue"
import StorySurface from "./StorySurface.vue"

const visualDnaRules = [
  {
    title: "Shell-first clarity",
    copy: "Lead with frames, borders, panels, and reading order before adding decorative moments.",
  },
  {
    title: "Restrained typography",
    copy: "Display marks key moments, body carries most work, and mono handles labels and operator context.",
  },
  {
    title: "Cool surface discipline",
    copy: "Slate, stone, ink, and canvas do the heavy lifting; accent is reserved for signal, not wallpaper.",
  },
  {
    title: "Utility-led emphasis",
    copy: "Hierarchy comes from spacing, density, contrast, and state treatment before illustration or saturated fill.",
  },
  {
    title: "Branded precision",
    copy: "Corners, shadows, highlights, and motion should feel engineered, not playful or inflated.",
  },
] as const

const dashboardSignals = [
  {
    label: "Queue health",
    value: "14 active runs",
    copy: "Status is visible immediately without turning the shell into a neon analytics wall.",
  },
  {
    label: "Escalations",
    value: "2 waiting",
    copy: "Warnings stand out through tone and placement, not through decorative alarm styling.",
  },
  {
    label: "Shell rhythm",
    value: "Stable sections",
    copy: "Navigation, metrics, and next actions read as one system instead of isolated widgets.",
  },
] as const

const publicProofPoints = [
  {
    label: "Narrative",
    copy: "Larger display moments can appear here, but they still sit inside a precise shell.",
  },
  {
    label: "Proof",
    copy: "Metrics and framed content blocks keep the page grounded in product reality.",
  },
  {
    label: "Tone",
    copy: "Public does not mean lifestyle marketing, soft gradients, or generic startup hero patterns.",
  },
  {
    label: "Continuity",
    copy: "A visitor should feel the same product family when they reach sign-in or the dashboard.",
  },
] as const
</script>

<template>
  <Story
    title="Foundations/Visual DNA"
    :layout="{ type: 'grid', width: 1120 }"
    :init-state="() => ({ theme: 'dark' as 'dark' | 'light', density: 'default' as 'default' | 'compact' })"
  >
    <template #controls="{ state }">
      <StoryControls v-model:theme="state.theme" v-model:density="state.density" />
    </template>

    <template #default="{ state }">
      <Variant title="Shared DNA">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-4 xl:grid-cols-[1.1fr_0.9fr]">
            <UiPanel tone="inverse" surface="solid" class="space-y-6">
              <div class="space-y-3">
                <UiBadge tone="warning">Shared thesis</UiBadge>
                <h2 class="ui-text-display" data-size="xl">
                  Operator console first, marketing polish second.
                </h2>
                <p class="ui-text-body max-w-3xl" data-size="lg" data-tone="soft">
                  The shell, borders, panels, and type hierarchy should do most of the brand work.
                  Accent and motion stay secondary. If a design needs loud color, playful type, or
                  floating fragments to feel interesting, it is drifting off-brand.
                </p>
              </div>

              <div class="grid gap-4 sm:grid-cols-2">
                <div class="rounded-[1.35rem] border border-ui-border-subtle bg-ui-panel-muted/70 p-4">
                  <p class="ui-text-meta" data-tone="soft">Lean on</p>
                  <p class="ui-text-body mt-3" data-tone="muted">
                    cool surfaces, stable shell chrome, restrained type, mono metadata, and
                    utility-led emphasis
                  </p>
                </div>
                <div class="rounded-[1.35rem] border border-ui-border-subtle bg-ui-panel-muted/70 p-4">
                  <p class="ui-text-meta" data-tone="soft">Reject</p>
                  <p class="ui-text-body mt-3" data-tone="muted">
                    neon gradients, borderless cards, pitch-deck heroes, and decorative motion that
                    competes with state clarity
                  </p>
                </div>
              </div>
            </UiPanel>

            <div class="grid gap-4">
              <UiPanel
                v-for="rule in visualDnaRules"
                :key="rule.title"
                surface="floating"
                padding="sm"
                class="space-y-2"
              >
                <p class="ui-text-meta" data-tone="soft">{{ rule.title }}</p>
                <p class="ui-text-body" data-tone="muted">{{ rule.copy }}</p>
              </UiPanel>
            </div>
          </div>
        </StorySurface>
      </Variant>

      <Variant title="Surface expression">
        <StorySurface :theme="state.theme" :density="state.density">
          <div class="grid gap-4 xl:grid-cols-3">
            <UiPanel surface="floating" class="space-y-5">
              <div class="space-y-3">
                <UiBadge tone="warning">Dashboard surfaces</UiBadge>
                <h3 class="ui-text-title" data-size="xl">Strong chrome, compact hierarchy, status-first emphasis.</h3>
                <p class="ui-text-body" data-tone="soft">
                  This is the clearest expression of the system: framed navigation, dense groupings,
                  and signal-rich panels that stay calm under load.
                </p>
              </div>

              <div class="flex flex-wrap gap-2">
                <a class="ui-nav-pill" data-active="true" href="#">Queue</a>
                <a class="ui-nav-pill" href="#">Agents</a>
                <a class="ui-nav-pill" href="#">Audit</a>
              </div>

              <div class="grid gap-3">
                <div
                  v-for="item in dashboardSignals"
                  :key="item.label"
                  class="rounded-[1.35rem] border border-ui-border-subtle bg-ui-panel-muted/70 p-4"
                >
                  <p class="ui-text-meta" data-tone="soft">{{ item.label }}</p>
                  <p class="ui-text-title mt-2" data-size="md">{{ item.value }}</p>
                  <p class="ui-text-body mt-1" data-tone="muted">{{ item.copy }}</p>
                </div>
              </div>
            </UiPanel>

            <UiPanel surface="floating" padding="sm">
              <AuthScene
                eyebrow="Auth surfaces"
                title="Same shell, less noise, higher trust."
                subtitle="Entry flows keep the dashboard materials and typography, but reduce simultaneous choices and put the primary action in sharper focus."
                detailOne="One dominant action per step, with calm feedback and clear validation."
                detailTwo="Reassurance comes from control, not from consumer-app friendliness theater."
                detailThree="The transition into the private shell should feel inevitable, not stylistically disconnected."
              />
            </UiPanel>

            <UiPanel tone="primary" surface="floating" class="space-y-5">
              <div class="space-y-3">
                <UiBadge tone="primary">Public surfaces</UiBadge>
                <h3 class="ui-text-display" data-size="lg">Narrative rhythm, still anchored in product infrastructure.</h3>
                <p class="ui-text-body" data-size="lg" data-tone="soft">
                  Public pages can stretch out and sell the system, but they should stay rooted in
                  the same cool palette, precise shell framing, and proof-first content blocks.
                </p>
              </div>

              <div class="flex flex-wrap gap-3">
                <UiButton>Request access</UiButton>
                <UiButton variant="outline" tone="neutral">Inspect the shell</UiButton>
              </div>

              <div class="grid gap-4 sm:grid-cols-2">
                <div
                  v-for="item in publicProofPoints"
                  :key="item.label"
                  class="rounded-[1.35rem] border border-ui-border-subtle bg-ui-panel-muted/70 p-4"
                >
                  <p class="ui-text-meta" data-tone="soft">{{ item.label }}</p>
                  <p class="ui-text-body mt-2" data-tone="muted">{{ item.copy }}</p>
                </div>
              </div>
            </UiPanel>
          </div>
        </StorySurface>
      </Variant>
    </template>
  </Story>
</template>
