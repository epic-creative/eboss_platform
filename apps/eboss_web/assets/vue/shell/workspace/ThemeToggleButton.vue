<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { Moon, Sun } from "lucide-vue-next"

const theme = ref<"light" | "dark">("light")

const icon = computed(() => (theme.value === "dark" ? Sun : Moon))
const label = computed(() => (theme.value === "dark" ? "Use light theme" : "Use dark theme"))

const readTheme = () => {
  const root = document.documentElement
  const stored = localStorage.getItem("phx:theme")
  const current =
    root.getAttribute("data-theme") ||
    stored ||
    (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")

  theme.value = current === "dark" ? "dark" : "light"
}

const applyTheme = (nextTheme: "light" | "dark") => {
  const root = document.documentElement

  localStorage.setItem("phx:theme", nextTheme)
  root.setAttribute("data-theme", nextTheme)
  theme.value = nextTheme
}

const toggleTheme = () => {
  applyTheme(theme.value === "dark" ? "light" : "dark")
}

onMounted(readTheme)
</script>

<template>
  <button type="button" class="so-icon-button" :aria-label="label" @click="toggleTheme">
    <component :is="icon" class="h-4 w-4" />
  </button>
</template>
