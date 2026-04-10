<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    modelValue?: string
    label?: string
    hint?: string
    error?: string
    prefix?: string
    suffix?: string
    placeholder?: string
    size?: "sm" | "md" | "lg"
    disabled?: boolean
    name?: string
    id?: string
    rows?: number
  }>(),
  {
    modelValue: "",
    label: undefined,
    hint: undefined,
    error: undefined,
    prefix: undefined,
    suffix: undefined,
    placeholder: undefined,
    size: "md",
    disabled: false,
    name: undefined,
    id: undefined,
    rows: 4,
  },
)

const emit = defineEmits<{
  (event: "update:modelValue", value: string): void
}>()
</script>

<template>
  <label class="ui-field">
    <span v-if="label" class="ui-field-label">{{ label }}</span>
    <div class="ui-field-control" :data-size="size" :data-invalid="String(Boolean(error))">
      <span v-if="prefix" class="ui-field-affix">{{ prefix }}</span>
      <textarea
        :id="id"
        class="ui-textarea"
        :name="name"
        :rows="rows"
        :disabled="disabled"
        :placeholder="placeholder"
        :value="modelValue"
        @input="emit('update:modelValue', ($event.target as HTMLTextAreaElement).value)"
      />
      <span v-if="suffix" class="ui-field-affix">{{ suffix }}</span>
    </div>
    <p v-if="hint" class="ui-field-hint">{{ hint }}</p>
    <p v-if="error" class="ui-field-error">
      <span>{{ error }}</span>
    </p>
  </label>
</template>
