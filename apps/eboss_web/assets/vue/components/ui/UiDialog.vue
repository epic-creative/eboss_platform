<script setup lang="ts">
import {
  DialogContent,
  DialogDescription,
  DialogOverlay,
  DialogPortal,
  DialogRoot,
  DialogTitle,
  DialogTrigger,
} from "reka-ui"

withDefaults(
  defineProps<{
    open?: boolean
    title: string
    description?: string
  }>(),
  {
    open: false,
    description: undefined,
  },
)

const emit = defineEmits<{
  (event: "update:open", value: boolean): void
}>()
</script>

<template>
  <DialogRoot :open="open" @update:open="emit('update:open', $event)">
    <DialogTrigger as-child>
      <slot name="trigger" />
    </DialogTrigger>

    <DialogPortal>
      <DialogOverlay class="fixed inset-0 z-40 bg-slate-950/72 backdrop-blur-sm" />
      <DialogContent class="fixed inset-x-4 top-1/2 z-50 mx-auto w-full max-w-xl -translate-y-1/2 focus:outline-none">
        <div class="ui-panel p-6 sm:p-8" data-surface="floating">
          <div class="flex items-start justify-between gap-4">
            <div class="space-y-2">
              <DialogTitle class="ui-text-title" data-size="lg">
                {{ title }}
              </DialogTitle>
              <DialogDescription v-if="description" class="ui-text-body" data-tone="soft">
                {{ description }}
              </DialogDescription>
            </div>
            <button
              type="button"
              class="ui-button"
              data-variant="ghost"
              data-tone="neutral"
              data-size="sm"
              @click="emit('update:open', false)"
            >
              Close
            </button>
          </div>

          <div class="mt-6">
            <slot />
          </div>
        </div>
      </DialogContent>
    </DialogPortal>
  </DialogRoot>
</template>
