import { HstVue } from "@histoire/plugin-vue"
import { defineConfig } from "histoire"

export default defineConfig({
  plugins: [HstVue()],
  setupFile: "./histoire.setup.ts",
  viteIgnorePlugins: ["phoenix-vite", "live-vue"],
  vite: (config) => {
    if (config.build?.rollupOptions?.input) {
      delete config.build.rollupOptions.input
    }

    return {}
  },
  theme: {
    title: "EBoss Design System",
    hideColorSchemeSwitch: false,
  },
  responsivePresets: [
    { label: "Desktop", width: 1440, height: 900 },
    { label: "Tablet", width: 1024, height: 768 },
    { label: "Mobile", width: 430, height: 932 },
  ],
  backgroundPresets: [
    { label: "Shell", color: "var(--color-shell)" },
    { label: "Canvas", color: "var(--color-canvas)" },
  ],
})
