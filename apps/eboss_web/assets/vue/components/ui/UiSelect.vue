<script setup lang="ts">
type SelectOption = {
  label: string
  value: string
  disabled?: boolean
}

const props = withDefaults(
  defineProps<{
    modelValue?: string
    label?: string
    hint?: string
    error?: string
    prefix?: string
    suffix?: string
    size?: "sm" | "md" | "lg"
    disabled?: boolean
    name?: string
    id?: string
    prompt?: string
    options: SelectOption[]
  }>(),
  {
    modelValue: "",
    label: undefined,
    hint: undefined,
    error: undefined,
    prefix: undefined,
    suffix: undefined,
    size: "md",
    disabled: false,
    name: undefined,
    id: undefined,
    prompt: undefined,
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
      <select
        :id="id"
        class="ui-select"
        :name="name"
        :disabled="disabled"
        :value="modelValue"
        @change="emit('update:modelValue', ($event.target as HTMLSelectElement).value)"
      >
        <option v-if="prompt" value="">{{ prompt }}</option>
        <option v-for="option in options" :key="option.value" :value="option.value" :disabled="option.disabled">
          {{ option.label }}
        </option>
      </select>
      <span v-if="suffix" class="ui-field-affix">{{ suffix }}</span>
    </div>
    <p v-if="hint" class="ui-field-hint">{{ hint }}</p>
    <p v-if="error" class="ui-field-error">
      <span>{{ error }}</span>
    </p>
  </label>
</template>
