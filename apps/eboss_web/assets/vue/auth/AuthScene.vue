<script setup lang="ts">
defineProps<{
  eyebrow: string
  title: string
  subtitle: string
  detailOne: string
  detailTwo: string
  detailThree: string
}>()
</script>

<template>
  <section class="relative overflow-hidden rounded-[1.75rem] bg-stone-950 px-6 py-7 text-white sm:px-8 sm:py-9">
    <div class="absolute inset-0 bg-[radial-gradient(circle_at_top_right,_rgba(56,189,248,0.22),_transparent_34%),radial-gradient(circle_at_bottom_left,_rgba(251,191,36,0.18),_transparent_32%)]" />

    <div class="relative space-y-7">
      <div class="space-y-4">
        <p class="text-xs font-semibold uppercase tracking-[0.28em] text-amber-300">{{ eyebrow }}</p>
        <div class="space-y-3">
          <h2 class="text-3xl font-semibold tracking-tight sm:text-4xl">{{ title }}</h2>
          <p class="max-w-2xl text-sm leading-7 text-stone-300 sm:text-base">{{ subtitle }}</p>
        </div>
      </div>

      <div class="grid gap-3">
        <article class="rounded-[1.35rem] border border-white/10 bg-white/8 px-4 py-4 backdrop-blur">
          <p class="text-[0.7rem] font-semibold uppercase tracking-[0.24em] text-sky-200">Flow one</p>
          <p class="mt-2 text-sm leading-6 text-stone-200">{{ detailOne }}</p>
        </article>
        <article class="rounded-[1.35rem] border border-white/10 bg-white/8 px-4 py-4 backdrop-blur">
          <p class="text-[0.7rem] font-semibold uppercase tracking-[0.24em] text-sky-200">Flow two</p>
          <p class="mt-2 text-sm leading-6 text-stone-200">{{ detailTwo }}</p>
        </article>
        <article class="rounded-[1.35rem] border border-white/10 bg-white/8 px-4 py-4 backdrop-blur">
          <p class="text-[0.7rem] font-semibold uppercase tracking-[0.24em] text-sky-200">Flow three</p>
          <p class="mt-2 text-sm leading-6 text-stone-200">{{ detailThree }}</p>
        </article>
      </div>
    </div>
  </section>
</template>
