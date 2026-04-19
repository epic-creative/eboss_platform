<script setup lang="ts">
import { Monitor, Moon, Sun } from "lucide-vue-next"

import { useTheme, type ThemeMode } from "./useTheme"

const themeOptions: { value: ThemeMode; label: string; icon: typeof Monitor }[] = [
  { value: "system", label: "Use system theme", icon: Monitor },
  { value: "light", label: "Use light theme", icon: Sun },
  { value: "dark", label: "Use dark theme", icon: Moon },
]

const { theme, setTheme } = useTheme()
</script>

<template>
  <div class="ui-theme-toggle">
    <div class="ui-theme-toggle__indicator" />

    <button
      v-for="option in themeOptions"
      :key="option.value"
      type="button"
      class="ui-theme-toggle__button"
      :aria-label="option.label"
      :aria-pressed="theme === option.value ? 'true' : 'false'"
      @click="setTheme(option.value)"
    >
      <component :is="option.icon" class="h-4 w-4" />
    </button>
  </div>
</template>
