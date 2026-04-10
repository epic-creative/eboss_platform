<script setup lang="ts">
import { computed, useAttrs, useId } from "vue"

defineOptions({ inheritAttrs: false })

const props = withDefaults(
  defineProps<{
    modelValue?: string | number
    label?: string
    hint?: string
    error?: string
    errors?: string[]
    invalid?: boolean
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
    errors: () => [],
    invalid: false,
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
const errorMessages = computed(() => {
  if (props.errors.length > 0) return props.errors
  if (props.error) return [props.error]
  return []
})
const invalidState = computed(() => props.invalid || errorMessages.value.length > 0)
const fieldId = computed(() => props.id ?? `${generatedId}-field`)
const hintId = computed(() => (props.hint ? `${fieldId.value}-hint` : undefined))
const errorId = computed(() => (errorMessages.value.length > 0 ? `${fieldId.value}-error` : undefined))
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
    <div v-if="errorMessages.length" :id="errorId" class="grid gap-2" aria-live="polite">
      <p
        v-for="(message, index) in errorMessages"
        :key="`${fieldId}-error-${index}`"
        class="ui-field-error"
      >
        <span>{{ message }}</span>
      </p>
    </div>
  </label>
</template>
