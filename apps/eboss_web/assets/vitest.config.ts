import vue from "@vitejs/plugin-vue"
import { defineConfig } from "vitest/config"
import { sharedOptimizeDeps, sharedResolve } from "./vite.shared.mjs"

export default defineConfig({
  plugins: [vue()],
  optimizeDeps: sharedOptimizeDeps,
  resolve: sharedResolve,
  test: {
    environment: "jsdom",
    include: ["tests/vue/**/*.spec.ts"],
    setupFiles: ["./tests/vue/setup.ts"],
  },
})
