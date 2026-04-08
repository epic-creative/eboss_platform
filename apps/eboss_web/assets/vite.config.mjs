import { defineConfig } from "vite"
import { phoenixVitePlugin } from "phoenix_vite"
import tailwindcss from "@tailwindcss/vite"
import vue from "@vitejs/plugin-vue"
import liveVuePlugin from "live_vue/vitePlugin"

const publicHost = process.env.PUBLIC_HOST ?? "local.eboss.ai"
const viteHost = process.env.VITE_HOST ?? publicHost
const vitePort = Number(process.env.VITE_PORT ?? 5173)
const viteScheme = process.env.VITE_SCHEME ?? "http"
const allowedHosts = (process.env.VITE_ALLOWED_HOSTS ?? `.eboss.ai,${publicHost},${viteHost},localhost,127.0.0.1`)
  .split(",")
  .map(host => host.trim())
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
      host: viteHost,
      protocol: viteScheme === "https" ? "wss" : "ws",
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
