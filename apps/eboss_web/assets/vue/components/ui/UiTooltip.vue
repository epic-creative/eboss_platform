<script setup lang="ts">
import {
  TooltipArrow,
  TooltipContent,
  TooltipPortal,
  TooltipProvider,
  TooltipRoot,
  TooltipTrigger,
} from "reka-ui"

withDefaults(
  defineProps<{
    content: string
    side?: "top" | "right" | "bottom" | "left"
  }>(),
  {
    side: "top",
  },
)
</script>

<template>
  <TooltipProvider :delay-duration="120">
    <TooltipRoot>
      <TooltipTrigger as-child>
        <slot />
      </TooltipTrigger>
      <TooltipPortal>
        <TooltipContent
          :side="side"
          :side-offset="10"
          class="rounded-2xl border border-ui-border-subtle bg-ui-surface-elevated px-3 py-2 text-sm text-ui-text shadow-[0_20px_60px_rgba(2,10,23,0.28)] backdrop-blur"
        >
          {{ content }}
          <TooltipArrow class="fill-ui-surface-elevated" />
        </TooltipContent>
      </TooltipPortal>
    </TooltipRoot>
  </TooltipProvider>
</template>
