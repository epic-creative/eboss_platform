import { readdir, readFile } from "node:fs/promises"
import { extname, join, relative } from "node:path"

import { describe, expect, it } from "vitest"

const shellRoot = join(process.cwd(), "vue/shell")

const externalClientModules = new Set([
  "notifications/http.ts",
  "workspace/chat/http.ts",
  "workspace/chat/queries.ts",
  "workspace/folio/http.ts",
  "workspace/folio/queries.ts",
])

const collectVueSourceFiles = async (directory: string): Promise<string[]> => {
  const entries = await readdir(directory, { withFileTypes: true })
  const files = await Promise.all(
    entries.map(async entry => {
      const path = `${directory}/${entry.name}`

      if (entry.isDirectory()) {
        return collectVueSourceFiles(path)
      }

      if (entry.isFile() && [".ts", ".vue"].includes(extname(entry.name))) {
        return [path]
      }

      return []
    }),
  )

  return files.flat()
}

const shellRelativePath = (path: string): string => relative(shellRoot, path)
const importsExternalClientModule =
  /\b(?:import|export)\b[^;\n]*(?:from\s+)?["'][^"']*(?:\/http|\/queries|\.\/http|\.\/queries)["']/

describe("LiveVue browser UI boundaries", () => {
  it("keeps REST/SSE helpers out of default workspace app barrels", async () => {
    const [chatIndex, folioIndex] = await Promise.all([
      readFile(`${shellRoot}/workspace/chat/index.ts`, "utf8"),
      readFile(`${shellRoot}/workspace/folio/index.ts`, "utf8"),
    ])

    expect(importsExternalClientModule.test(chatIndex)).toBe(false)
    expect(importsExternalClientModule.test(folioIndex)).toBe(false)
  })

  it("keeps shell Vue components on LiveVue-first state paths", async () => {
    const sourceFiles = await collectVueSourceFiles(shellRoot)
    const violations: string[] = []

    for (const sourceFile of sourceFiles) {
      const relativePath = shellRelativePath(sourceFile)

      if (externalClientModules.has(relativePath)) {
        continue
      }

      const source = await readFile(sourceFile, "utf8")

      if (importsExternalClientModule.test(source)) {
        violations.push(`${relativePath} imports an external REST/SSE helper`)
      }

      if (/\bfetch\s*\(/.test(source)) {
        violations.push(`${relativePath} calls fetch() directly`)
      }
    }

    expect(violations).toEqual([])
  })
})
