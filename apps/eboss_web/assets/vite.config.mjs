import { defineConfig } from "vite"
import { phoenixVitePlugin } from "phoenix_vite"
import tailwindcss from "@tailwindcss/vite"
import vue from "@vitejs/plugin-vue"
import liveVuePlugin from "live_vue/vitePlugin"

const ebossEnv = process.env.EBOSS_ENV ?? "local"
const defaultHost = ebossEnv === "test" ? "localhost" : "local.eboss.ai"
const phxHost = process.env.PHX_HOST ?? defaultHost
const vitePort = Number(process.env.VITE_PORT ?? 5173)
const allowedHosts = [".eboss.ai", phxHost, "localhost", "127.0.0.1"]
  .map((host) => host.trim())
  .filter(Boolean)

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
  optimizeDeps: {
    include: ["live_vue", "phoenix", "phoenix_html", "phoenix_live_view"],
  },
  build: {
    outDir: "../priv/static/assets",
    emptyOutDir: true,
    rollupOptions: {
      input: ["js/app.js", "css/app.css"],
    },
  },
  resolve: {
    alias: {
      "@": ".",
      "phoenix-colocated": `${process.env.MIX_BUILD_PATH}/phoenix-colocated`,
    },
  },
  plugins: [
    tailwindcss(),
    phoenixVitePlugin({
      pattern: /\.(ex|heex)$/,
    }),
    vue(),
    liveVuePlugin(),
  ],
})
