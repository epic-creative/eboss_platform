<script setup lang="ts">
import { computed, useAttrs, useId } from "vue"

defineOptions({ inheritAttrs: false })

const props = withDefaults(
  defineProps<{
    modelValue?: string | number
    label?: string
    hint?: string
    error?: string
    prefix?: string
    suffix?: string
    type?: string
    placeholder?: string
    size?: "sm" | "md" | "lg"
    disabled?: boolean
    name?: string
    id?: string
  }>(),
  {
    modelValue: "",
    label: undefined,
    hint: undefined,
    error: undefined,
    prefix: undefined,
    suffix: undefined,
    type: "text",
    placeholder: undefined,
    size: "md",
    disabled: false,
    name: undefined,
    id: undefined,
  },
)

const emit = defineEmits<{
  (event: "update:modelValue", value: string): void
}>()

const attrs = useAttrs()
const generatedId = useId()
const invalidState = computed(() => Boolean(props.error))
const fieldId = computed(() => props.id ?? `${generatedId}-field`)
const hintId = computed(() => (props.hint ? `${fieldId.value}-hint` : undefined))
const errorId = computed(() => (props.error ? `${fieldId.value}-error` : undefined))
const describedBy = computed(() => {
  const ids = [attrs["aria-describedby"] as string | undefined, hintId.value, errorId.value].filter(Boolean)
  return ids.length > 0 ? ids.join(" ") : undefined
})
</script>

<template>
  <label class="ui-field">
    <span v-if="label" class="ui-field-label">{{ label }}</span>
    <div class="ui-field-control" :data-size="size" :data-invalid="String(invalidState)">
      <span v-if="prefix" class="ui-field-affix">{{ prefix }}</span>
      <input
        v-bind="attrs"
        :id="fieldId"
        class="ui-input"
        :name="name"
        :type="type"
        :disabled="disabled"
        :placeholder="placeholder"
        :value="modelValue"
        :aria-describedby="describedBy"
        :aria-invalid="invalidState || undefined"
        @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
      />
      <span v-if="suffix" class="ui-field-affix">{{ suffix }}</span>
    </div>
    <p v-if="hint" :id="hintId" class="ui-field-hint">{{ hint }}</p>
    <p v-if="error" :id="errorId" class="ui-field-error" aria-live="polite">
      <span>{{ error }}</span>
    </p>
  </label>
</template>
