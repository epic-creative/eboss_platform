import { defineConfig } from "vite"
import { phoenixVitePlugin } from "phoenix_vite"
import tailwindcss from "@tailwindcss/vite"
import vue from "@vitejs/plugin-vue"
import liveVuePlugin from "live_vue/vitePlugin"
import { sharedOptimizeDeps, sharedResolve } from "./vite.shared.mjs"

const ebossEnv = process.env.EBOSS_ENV ?? "local"
const defaultHost = ebossEnv === "test" ? "localhost" : "local.eboss.ai"
const phxHost = process.env.PHX_HOST ?? defaultHost
const vitePort = Number(process.env.VITE_PORT ?? 5173)
const allowedHosts = [".eboss.ai", phxHost, "localhost", "127.0.0.1"].map((host) => host.trim()).filter(Boolean)

export default defineConfig({
  server: {
    host: "127.0.0.1",
    port: vitePort,
    strictPort: true,
    allowedHosts,
    cors: true,
    hmr: {
      clientPort: vitePort,
      host: phxHost,
      protocol: "ws",
    },
  },
  optimizeDeps: sharedOptimizeDeps,
  build: {
    outDir: "../priv/static/assets",
    emptyOutDir: true,
    rollupOptions: {
      input: ["js/app.js", "css/app.css"],
    },
  },
  resolve: sharedResolve,
  plugins: [
    tailwindcss(),
    phoenixVitePlugin({
      pattern: /\.(ex|heex)$/,
    }),
    vue(),
    liveVuePlugin(),
  ],
})
