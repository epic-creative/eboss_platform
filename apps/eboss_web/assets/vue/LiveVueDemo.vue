<script setup lang="ts">
import { computed, ref } from "vue"

const props = defineProps<{
  count: number
  headline: string
  subhead: string
}>()

const detailsOpen = ref(true)

const countParity = computed(() => (props.count % 2 === 0 ? "even" : "odd"))
</script>

<template>
  <section class="rounded-[2rem] border border-base-300 bg-base-100 p-6 shadow-sm shadow-base-content/5">
    <div class="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
      <div class="space-y-2">
        <p class="text-xs font-semibold uppercase tracking-[0.24em] text-primary">Frontend Foundation</p>
        <h2 class="text-3xl font-semibold tracking-tight">{{ headline }}</h2>
        <p class="max-w-2xl text-sm leading-6 text-base-content/70">{{ subhead }}</p>
      </div>

      <button class="btn btn-ghost btn-sm self-start" @click="detailsOpen = !detailsOpen">
        {{ detailsOpen ? "Hide details" : "Show details" }}
      </button>
    </div>

    <div v-if="detailsOpen" class="mt-6 grid gap-4 lg:grid-cols-[1.15fr_0.85fr]">
      <article class="rounded-[1.5rem] bg-base-200 p-5">
        <p class="text-sm text-base-content/60">LiveView state over LiveVue props</p>

        <div class="mt-4 flex items-end gap-3">
          <span class="text-5xl font-semibold leading-none">{{ count }}</span>
          <span class="badge badge-outline badge-lg">{{ countParity }}</span>
        </div>

        <div class="mt-5 flex flex-wrap gap-3">
          <button class="btn btn-primary" @click="$live.pushEvent('increment', {})">Increment</button>
          <button class="btn btn-outline" @click="$live.pushEvent('reset', {})">Reset</button>
        </div>
      </article>

      <article class="rounded-[1.5rem] border border-dashed border-base-300 p-5">
        <p class="text-sm text-base-content/60">Client-only Vue state</p>
        <p class="mt-3 text-sm leading-6 text-base-content/75">
          This panel toggle stays entirely in Vue. The count card updates from LiveView through the same mounted component.
        </p>
      </article>
    </div>
  </section>
</template>
