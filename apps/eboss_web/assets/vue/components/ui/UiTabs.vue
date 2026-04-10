<script setup lang="ts">
import { computed } from "vue"
import { TabsContent, TabsList, TabsRoot, TabsTrigger } from "reka-ui"

type TabItem = {
  value: string
  label: string
  copy?: string
}

const props = defineProps<{
  modelValue?: string
  items: TabItem[]
}>()

const emit = defineEmits<{
  (event: "update:modelValue", value: string): void
}>()

const activeValue = computed(() => props.modelValue ?? props.items[0]?.value ?? "")
</script>

<template>
  <TabsRoot :model-value="activeValue" class="space-y-4" @update:model-value="emit('update:modelValue', $event)">
    <TabsList class="flex flex-wrap gap-2">
      <TabsTrigger
        v-for="item in items"
        :key="item.value"
        :value="item.value"
        class="ui-nav-pill"
        :data-active="String(activeValue === item.value)"
      >
        {{ item.label }}
      </TabsTrigger>
    </TabsList>

    <TabsContent v-for="item in items" :key="item.value" :value="item.value" class="focus:outline-none">
      <div class="ui-panel p-6" data-surface="solid">
        <slot :name="`content-${item.value}`" :item="item">
          <p class="ui-text-body" data-size="lg" data-tone="soft">{{ item.copy }}</p>
        </slot>
      </div>
    </TabsContent>
  </TabsRoot>
</template>
