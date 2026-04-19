<script setup lang="ts">
defineProps<{
  open: boolean
  title: string
  subtitle?: string
}>()

const emit = defineEmits<{
  close: []
}>()
</script>

<template>
  <div v-if="open">
    <div class="fixed inset-0 z-40 bg-black/30 backdrop-blur-sm md:hidden" @click="emit('close')" />

    <aside
      class="so-fade-in fixed inset-y-0 right-0 z-50 flex w-[320px] max-w-[85vw] flex-col border-l border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))] md:static md:z-auto md:max-h-[calc(100vh-7rem)] md:w-80 md:shrink-0 md:rounded-md md:rounded-l-none md:border md:border-l-0 md:shadow-none md:sticky md:top-0"
    >
      <div class="flex items-center justify-between border-b border-[hsl(var(--so-border))] px-4 py-2.5">
        <div class="min-w-0">
          <h3 class="truncate text-sm font-medium text-[hsl(var(--so-foreground))]">{{ title }}</h3>
          <p
            v-if="subtitle"
            class="so-font-mono truncate text-[11px] text-[hsl(var(--so-muted-foreground))]"
          >
            {{ subtitle }}
          </p>
        </div>

        <div class="flex items-center gap-1">
          <slot name="actions" />
          <button type="button" class="so-icon-button" aria-label="Close inspector" @click="emit('close')">
            <span class="text-sm leading-none">×</span>
          </button>
        </div>
      </div>

      <div class="flex-1 overflow-y-auto p-4">
        <slot />
      </div>
    </aside>
  </div>
</template>
