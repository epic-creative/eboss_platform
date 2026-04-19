import { describe, expect, it } from "vitest"

import { mountComponent } from "@/tests/vue/support/mount"
import WorkspaceSidebar from "@/vue/shell/workspace/WorkspaceSidebar.vue"
import type { WorkspaceScope } from "@/vue/shell/workspace/types"

const emptyScope = (): WorkspaceScope => ({
  empty: true,
  dashboardPath: "/dashboard",
  currentWorkspace: null,
  owner: null,
  capabilities: {
    readWorkspace: false,
    manageWorkspace: false,
    readFolio: false,
    manageFolio: false,
  },
  accessibleWorkspaces: [],
})

describe("WorkspaceSidebar", () => {
  it("renders a stable empty-state summary when no workspace is selected", () => {
    const wrapper = mountComponent(WorkspaceSidebar, {
      props: {
        currentUser: {
          username: "operator",
          email: "operator@example.com",
        },
        currentScope: emptyScope(),
        currentPage: "dashboard",
        basePath: "/dashboard",
      },
    })

    expect(wrapper.get('[data-testid="workspace-sidebar"]').text()).toContain("No workspace")
    expect(wrapper.text()).toContain("No workspace selected")
    expect(wrapper.text()).toContain("No workspaces available yet.")
    expect(wrapper.text().includes("undefined/undefined")).toBe(false)
  })
})
