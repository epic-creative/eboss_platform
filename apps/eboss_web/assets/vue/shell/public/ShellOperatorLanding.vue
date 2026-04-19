<script setup lang="ts">
import {
  ArrowRight,
  GitBranch,
  Globe,
  Layers,
  Lock,
  Server,
  Shield,
  Terminal,
} from "lucide-vue-next"

import ThemeToggleButton from "../workspace/ThemeToggleButton.vue"

const specs = [
  { label: "Workspace-scoped RBAC", desc: "Granular permissions per workspace, team, and resource.", icon: Shield },
  { label: "Multi-tenant isolation", desc: "User and org-owned workspaces with fully isolated data contexts.", icon: Layers },
  { label: "Auth-native flows", desc: "Password, magic link, and token-based auth with first-party routes.", icon: Lock },
  { label: "Environment branching", desc: "Staging, production, and custom environments per workspace.", icon: GitBranch },
  { label: "API-first design", desc: "Canonical APIs for product bootstrap and future app surfaces.", icon: Globe },
  { label: "Operator console", desc: "Dense workspace shell for operators who need full visibility.", icon: Server },
]
</script>

<template>
  <div class="so-theme flex min-h-screen flex-col bg-[hsl(var(--so-background))] text-[hsl(var(--so-foreground))]">
    <header class="so-header-bar sticky top-0 z-50 border-b border-[hsl(var(--so-header-border))]">
      <div class="mx-auto flex h-12 max-w-7xl items-center gap-4 px-4 sm:px-6 lg:px-8">
        <a href="/" class="flex shrink-0 items-center gap-2">
          <div class="flex h-6 w-6 items-center justify-center rounded bg-[hsl(var(--so-header-foreground))]">
            <span class="so-font-mono text-[10px] font-bold text-[hsl(var(--so-header-bg))]">E</span>
          </div>
          <span class="hidden text-sm font-semibold text-[hsl(var(--so-header-foreground))] sm:inline">EBoss</span>
        </a>

        <nav class="ml-4 hidden items-center gap-1 md:flex" aria-label="Public routes">
          <a
            href="#product"
            class="px-3 py-1 text-sm text-[hsl(var(--so-header-muted))] transition-colors hover:text-[hsl(var(--so-header-foreground))]"
          >
            Product
          </a>
        </nav>

        <div class="ml-auto flex items-center gap-2">
          <ThemeToggleButton />
          <div class="hidden items-center gap-2 md:flex">
            <a
              href="/sign-in"
              class="so-button-ghost h-8 px-3 text-xs text-[hsl(var(--so-header-foreground))] hover:bg-[hsl(var(--so-header-input-bg))] hover:text-[hsl(var(--so-header-foreground))]"
            >
              Sign in
            </a>
            <a href="/register" class="so-button-primary h-8 px-3 text-xs">Sign up</a>
          </div>
        </div>
      </div>
    </header>

    <main class="flex-1">
      <section class="border-b border-[hsl(var(--so-border))]" data-testid="home-hero">
        <div class="mx-auto grid max-w-7xl items-center gap-10 px-4 py-16 sm:px-6 md:grid-cols-2 md:py-20 lg:px-8">
          <div class="space-y-5">
            <p class="so-font-mono text-xs uppercase tracking-widest text-[hsl(var(--so-muted-foreground))]">
              Workspace infrastructure
            </p>
            <h1 class="text-2xl font-semibold leading-tight tracking-tight md:text-3xl">
              Infrastructure for teams
              <br />
              that ship with precision
            </h1>
            <p class="max-w-md text-sm leading-relaxed text-[hsl(var(--so-muted-foreground))]">
              Workspace-aware platform with scoped access control, multi-tenant isolation, and an operator console designed for depth.
            </p>
            <div class="flex items-center gap-3 pt-1">
              <a href="/register" class="so-button-primary h-8 px-3 text-xs">
                Get started
                <ArrowRight class="h-3.5 w-3.5" />
              </a>
              <a href="/sign-in" class="so-button-secondary h-8 px-3 text-xs">Sign in</a>
            </div>
          </div>

          <div class="overflow-hidden rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]">
            <div class="so-surface-1 flex items-center gap-2 border-b border-[hsl(var(--so-border))] px-4 py-2">
              <Terminal class="h-3.5 w-3.5 text-[hsl(var(--so-muted-foreground))]" />
              <span class="so-font-mono text-xs text-[hsl(var(--so-muted-foreground))]">eboss-cli</span>
            </div>
            <div class="so-font-mono space-y-1.5 p-4 text-xs text-[hsl(var(--so-muted-foreground))]">
              <p><span class="text-[hsl(var(--so-success))]">$</span> eboss workspace create acme-corp/production</p>
              <p class="text-[hsl(var(--so-foreground))]">✓ Workspace created: acme-corp/production</p>
              <p class="text-[hsl(var(--so-foreground))]">  Region: us-east-1 | Plan: Pro | Status: active</p>
              <p>&nbsp;</p>
              <p><span class="text-[hsl(var(--so-success))]">$</span> eboss members add sarah@acme.com --role admin</p>
              <p class="text-[hsl(var(--so-foreground))]">✓ Invited sarah@acme.com as admin</p>
              <p>&nbsp;</p>
              <p><span class="text-[hsl(var(--so-success))]">$</span> eboss deploy --workspace acme-corp/production</p>
              <p class="text-[hsl(var(--so-foreground))]">✓ Deployment #142 completed in 4.2s</p>
              <p class="text-[hsl(var(--so-muted-foreground))]">  3 services updated, 0 errors</p>
              <p>&nbsp;</p>
              <p><span class="text-[hsl(var(--so-success))]">$</span> ▋</p>
            </div>
          </div>
        </div>
      </section>

      <section id="product" class="border-b border-[hsl(var(--so-border))]">
        <div class="mx-auto max-w-7xl px-4 py-12 sm:px-6 md:py-16 lg:px-8">
          <div class="mb-8">
            <p class="so-font-mono mb-1 text-xs uppercase tracking-widest text-[hsl(var(--so-muted-foreground))]">
              Capabilities
            </p>
            <h2 class="text-xl font-semibold tracking-tight">Built for workspace discipline</h2>
          </div>

          <div class="grid gap-px overflow-hidden rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-border))] md:grid-cols-2">
            <div
              v-for="spec in specs"
              :key="spec.label"
              class="space-y-1.5 bg-[hsl(var(--so-background))] p-5 transition-colors hover:bg-[hsl(var(--so-surface-1))]"
            >
              <div class="flex items-center gap-2">
                <component :is="spec.icon" class="h-4 w-4 text-[hsl(var(--so-muted-foreground))]" />
                <span class="text-sm font-medium">{{ spec.label }}</span>
              </div>
              <p class="pl-6 text-xs leading-relaxed text-[hsl(var(--so-muted-foreground))]">{{ spec.desc }}</p>
            </div>
          </div>
        </div>
      </section>

      <section>
        <div class="mx-auto max-w-7xl space-y-4 px-4 py-12 text-center sm:px-6 md:py-16 lg:px-8">
          <h2 class="text-xl font-semibold tracking-tight">Ready to operate?</h2>
          <p class="mx-auto max-w-sm text-sm text-[hsl(var(--so-muted-foreground))]">
            Create your workspace and start building with precision.
          </p>
          <a href="/register" class="so-button-primary h-8 px-3 text-xs">
            Create your workspace
            <ArrowRight class="h-3.5 w-3.5" />
          </a>
        </div>
      </section>
    </main>

    <footer class="border-t border-[hsl(var(--so-border))]" aria-label="Public shell footer" role="contentinfo">
      <div class="mx-auto flex max-w-7xl flex-col items-center justify-between gap-4 px-4 py-6 sm:flex-row sm:px-6 lg:px-8">
        <div class="flex items-center gap-2">
          <div class="flex h-5 w-5 items-center justify-center rounded bg-[hsl(var(--so-muted))]">
            <span class="so-font-mono text-[9px] font-bold text-[hsl(var(--so-muted-foreground))]">E</span>
          </div>
          <span class="text-xs text-[hsl(var(--so-muted-foreground))]">© 2026 EBoss</span>
        </div>
        <div class="flex items-center gap-4">
          <a href="/" class="text-xs text-[hsl(var(--so-muted-foreground))] transition-colors hover:text-[hsl(var(--so-foreground))]">Terms</a>
          <a href="/" class="text-xs text-[hsl(var(--so-muted-foreground))] transition-colors hover:text-[hsl(var(--so-foreground))]">Privacy</a>
          <a href="mailto:support@eboss.dev" class="text-xs text-[hsl(var(--so-muted-foreground))] transition-colors hover:text-[hsl(var(--so-foreground))]">Contact</a>
        </div>
      </div>
    </footer>
  </div>
</template>
