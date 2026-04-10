<script setup lang="ts">
import { computed, useAttrs } from "vue"
import UiSpinner from "./UiSpinner.vue"

defineOptions({ inheritAttrs: false })

const props = withDefaults(
  defineProps<{
    as?: string
    href?: string
    variant?: "solid" | "outline" | "ghost" | "subtle"
    tone?: "primary" | "neutral" | "success" | "warning" | "danger"
    size?: "sm" | "md" | "lg"
    loading?: boolean
    disabled?: boolean
    type?: "button" | "submit" | "reset"
    iconPosition?: "leading" | "trailing"
  }>(),
  {
    as: "button",
    href: undefined,
    variant: "solid",
    tone: "primary",
    size: "md",
    loading: false,
    disabled: false,
    type: "button",
    iconPosition: "leading",
  },
)

const attrs = useAttrs()
const tagName = computed(() => (props.href ? "a" : props.as))
const disabledState = computed(() => props.disabled || props.loading)
</script>

<template>
  <component
    :is="tagName"
    v-bind="attrs"
    :href="href"
    :type="tagName === 'button' ? type : undefined"
    :disabled="tagName === 'button' ? disabledState : undefined"
    :aria-disabled="tagName !== 'button' ? String(disabledState) : undefined"
    class="ui-button"
    :data-variant="variant"
    :data-tone="tone"
    :data-size="size"
    :data-state="loading ? 'loading' : 'default'"
  >
    <span class="ui-button__label">
      <span v-if="loading || $slots.icon" class="inline-flex items-center">
        <UiSpinner v-if="loading" size="sm" :label="''" />
        <slot v-else-if="iconPosition === 'leading'" name="icon" />
      </span>
      <span><slot /></span>
      <span v-if="$slots.icon && iconPosition === 'trailing' && !loading" class="inline-flex items-center">
        <slot name="icon" />
      </span>
    </span>
  </component>
</template>
