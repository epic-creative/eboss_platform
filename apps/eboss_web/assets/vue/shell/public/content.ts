import type { Component } from "vue"
import {
  Layers,
  Lock,
  Shield,
} from "lucide-vue-next"

export interface ProofCard {
  label: string
  desc: string
  icon: Component
}

export interface StoryMetric {
  label: string
  value: string
}

export interface StoryFrameItem {
  label: string
  detail: string
  meta: string
}

export interface StorySection {
  id: "continuity" | "tempo"
  eyebrow: string
  title: string
  description: string
  signals: string[]
  panelTitle: string
  panelIntro: string
  items: StoryFrameItem[]
  metrics: StoryMetric[]
  reverse?: boolean
}

export const heroSignals = [
  "Scoped access control",
  "Tenant-aware workspaces",
  "Operator-grade shell",
]

export const proofCards: ProofCard[] = [
  {
    label: "Workspace-scoped RBAC",
    desc: "Granular permissions stay attached to each workspace, team boundary, and operational surface.",
    icon: Shield,
  },
  {
    label: "Multi-tenant isolation",
    desc: "User and organization ownership models stay explicit from sign-up through workspace routing.",
    icon: Layers,
  },
  {
    label: "Auth-native launch surface",
    desc: "Registration, sign-in, recovery, and the dashboard handoff remain in one consistent route family.",
    icon: Lock,
  },
]

export const storySections: StorySection[] = [
  {
    id: "continuity",
    eyebrow: "Shell continuity",
    title: "One public frame from entry to authenticated work",
    description:
      "Landing, auth, recovery, and the dashboard handoff all stay inside the same shell language so the product reads as one system instead of a stitched set of pages.",
    signals: ["Shared header", "Shared footer", "Same route family"],
    panelTitle: "Route sequence",
    panelIntro: "The public shell stays intact while the user crosses the session boundary.",
    items: [
      {
        label: "Home",
        detail: "Product posture, operator framing, and the first action.",
        meta: "/",
      },
      {
        label: "Sign in",
        detail: "Password and magic-link entry share the same compact auth frame.",
        meta: "/sign-in",
      },
      {
        label: "Recovery",
        detail: "Password reset and confirmation stay in the same public shell instead of a detached flow.",
        meta: "/forgot-password",
      },
    ],
    metrics: [
      { label: "Route families", value: "1" },
      { label: "Theme controls", value: "Shared" },
      { label: "Context switch", value: "Direct" },
    ],
  },
  {
    id: "tempo",
    eyebrow: "Operator depth",
    title: "Runtime visibility stays close to the work",
    description:
      "The working shell keeps deployments, members, environments, and audit cues visible without flattening the workspace into a generic dashboard.",
    signals: ["Dense panels", "Inline signals", "Workspace-aware actions"],
    panelTitle: "Working surfaces",
    panelIntro: "The shell keeps high-frequency operations legible without breaking the visual system established on the public routes.",
    items: [
      {
        label: "Environment branching",
        detail: "Staging, production, and custom environments stay attached to the same workspace scope.",
        meta: "Deploy lanes",
      },
      {
        label: "API-first bootstrap",
        detail: "Canonical routes and bootstrap surfaces support future product entry points without shell drift.",
        meta: "Bootstrap + JSON",
      },
      {
        label: "Operator console",
        detail: "Dense navigation, inspector detail, and multi-panel review remain part of the runtime shell.",
        meta: "Workspace shell",
      },
    ],
    metrics: [
      { label: "Primary views", value: "Dashboard" },
      { label: "Access model", value: "Scoped" },
      { label: "Shell density", value: "Operator" },
    ],
    reverse: true,
  },
]

export const closingSignals = [
  "Canonical owner/workspace routes",
  "Shared tokens and surfaces",
  "Direct workspace creation handoff",
]

export const consoleLines = [
  "$ eboss workspace create acme-corp/production",
  "✓ Workspace created: acme-corp/production",
  "  Region: us-east-1 | Plan: Pro | Status: active",
  "",
  "$ eboss members add sarah@acme.com --role admin",
  "✓ Invited sarah@acme.com as admin",
  "",
  "$ eboss deploy --workspace acme-corp/production",
  "✓ Deployment #142 completed in 4.2s",
  "  3 services updated, 0 errors",
  "",
  "$ ▋",
]

export const consoleMeta = {
  title: "eboss-cli",
  kicker: "Workspace infrastructure",
  frameLabel: "Operator launch surface",
  highlightSignals: [
    { label: "Surface", value: "Shared shell" },
    { label: "Launch", value: "Create or sign in" },
    { label: "Runtime", value: "Operator-ready" },
  ],
}

export const closingPanel = {
  eyebrow: "Workspace handoff",
  title: "Ready to create your first workspace?",
  description:
    "Start with an account, stay inside the same shell, and move directly into the canonical owner/workspace route structure.",
}

export const proofBandHeading = {
  eyebrow: "Capabilities",
  title: "Built for disciplined workspace operations",
  description:
    "The public shell introduces the same product posture the runtime shell carries forward: access control, tenant separation, and operator visibility.",
}
