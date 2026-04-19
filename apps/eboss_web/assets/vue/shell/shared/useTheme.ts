import { onBeforeUnmount, onMounted, ref } from "vue"

export type ThemeMode = "system" | "light" | "dark"

declare global {
  interface Window {
    EBossTheme?: {
      getTheme: () => ThemeMode
      setTheme: (theme: ThemeMode) => void
      subscribe: (listener: (theme: ThemeMode) => void) => () => void
    }
  }
}

const readFallbackTheme = (): ThemeMode => {
  if (typeof window === "undefined") return "system"

  const stored = window.localStorage.getItem("phx:theme")

  if (stored === "light" || stored === "dark") {
    return stored
  }

  return "system"
}

export const useTheme = () => {
  const theme = ref<ThemeMode>(readFallbackTheme())
  let unsubscribe: (() => void) | undefined

  const syncTheme = () => {
    theme.value = window.EBossTheme?.getTheme() ?? readFallbackTheme()
  }

  const setTheme = (nextTheme: ThemeMode) => {
    window.EBossTheme?.setTheme(nextTheme)
    theme.value = nextTheme
  }

  onMounted(() => {
    syncTheme()
    unsubscribe = window.EBossTheme?.subscribe(themeMode => {
      theme.value = themeMode
    })
  })

  onBeforeUnmount(() => unsubscribe?.())

  return {
    theme,
    setTheme,
  }
}
