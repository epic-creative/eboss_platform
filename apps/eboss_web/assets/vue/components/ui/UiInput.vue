<script setup lang="ts">
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
</script>

<template>
  <label class="ui-field">
    <span v-if="label" class="ui-field-label">{{ label }}</span>
    <div class="ui-field-control" :data-size="size" :data-invalid="String(Boolean(error))">
      <span v-if="prefix" class="ui-field-affix">{{ prefix }}</span>
      <input
        :id="id"
        class="ui-input"
        :name="name"
        :type="type"
        :disabled="disabled"
        :placeholder="placeholder"
        :value="modelValue"
        @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
      />
      <span v-if="suffix" class="ui-field-affix">{{ suffix }}</span>
    </div>
    <p v-if="hint" class="ui-field-hint">{{ hint }}</p>
    <p v-if="error" class="ui-field-error">
      <span>{{ error }}</span>
    </p>
  </label>
</template>
