import { fileURLToPath } from "node:url"

const assetsRoot = fileURLToPath(new URL(".", import.meta.url))

/** @type {import("vite").OptimizeDepsOptions} */
export const sharedOptimizeDeps = {
  include: ["live_vue", "phoenix", "phoenix_html", "phoenix_live_view"],
}

/** @type {import("vite").ResolveOptions} */
export const sharedResolve = {
  alias: {
    "@": assetsRoot,
    "phoenix-colocated": `${process.env.MIX_BUILD_PATH}/phoenix-colocated`,
  },
}
