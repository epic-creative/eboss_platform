<script setup lang="ts">
defineProps<{
  username: string
  email: string
  workspaceLabel: string
  folioLabel: string
}>()
</script>

<template>
  <section class="relative overflow-hidden rounded-[1.75rem] bg-stone-950 px-6 py-7 text-white sm:px-8 sm:py-9">
    <div class="absolute inset-0 bg-[radial-gradient(circle_at_top_left,_rgba(56,189,248,0.22),_transparent_30%),radial-gradient(circle_at_bottom_right,_rgba(251,191,36,0.18),_transparent_32%)]" />

    <div class="relative space-y-7">
      <div class="space-y-3">
        <p class="text-xs font-semibold uppercase tracking-[0.28em] text-amber-300">Dashboard launchpad</p>
        <h2 class="text-3xl font-semibold tracking-tight">The authenticated edge is ready.</h2>
        <p class="max-w-2xl text-sm leading-7 text-stone-300">
          This is the first thin shell for signed-in users. It is intentionally calm so the next product surfaces can grow without reworking the session boundary again.
        </p>
      </div>

      <div class="grid gap-3">
        <article class="rounded-[1.35rem] border border-white/10 bg-white/8 px-4 py-4 backdrop-blur">
          <p class="text-[0.7rem] font-semibold uppercase tracking-[0.24em] text-sky-200">Current user</p>
          <p class="mt-2 text-lg font-semibold">{{ username }}</p>
          <p class="text-sm text-stone-300">{{ email }}</p>
        </article>
        <article class="rounded-[1.35rem] border border-white/10 bg-white/8 px-4 py-4 backdrop-blur">
          <p class="text-[0.7rem] font-semibold uppercase tracking-[0.24em] text-sky-200">Workspace surface</p>
          <p class="mt-2 text-sm leading-6 text-stone-200">{{ workspaceLabel }}</p>
        </article>
        <article class="rounded-[1.35rem] border border-white/10 bg-white/8 px-4 py-4 backdrop-blur">
          <p class="text-[0.7rem] font-semibold uppercase tracking-[0.24em] text-sky-200">Folio surface</p>
          <p class="mt-2 text-sm leading-6 text-stone-200">{{ folioLabel }}</p>
        </article>
      </div>
    </div>
  </section>
</template>
