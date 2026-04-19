<script setup lang="ts">
import { computed } from "vue"
import {
  CheckCircle2,
  Clock,
  ExternalLink,
  FolderKanban,
  GitBranch,
  Globe,
  Plus,
  Rocket,
  Search,
  Settings,
  Users,
} from "lucide-vue-next"

import InspectorPane from "../InspectorPane.vue"
import WorkspacePageHeader from "../WorkspacePageHeader.vue"
import type { Project, ProjectFilter } from "../types"

const props = defineProps<{
  workspaceReference: string
  projectFilters: readonly ProjectFilter[]
  projectFilter: ProjectFilter
  projects: Project[]
  selectedProject: Project | null
}>()

const emit = defineEmits<{
  "update:projectFilter": [value: ProjectFilter]
  "update:selectedProject": [value: Project | null]
}>()

const filteredProjects = computed(() =>
  props.projectFilter === "all"
    ? props.projects
    : props.projects.filter(project => project.status === props.projectFilter),
)

const toggleProject = (project: Project) => {
  emit("update:selectedProject", props.selectedProject?.id === project.id ? null : project)
}
</script>

<template>
  <div class="ui-workspace-page">
    <WorkspacePageHeader title="Projects" :subtitle="workspaceReference">
      <template #actions>
        <button type="button" class="so-button-primary">
          <Plus class="h-3 w-3" />
          New project
        </button>
      </template>
    </WorkspacePageHeader>

    <div class="flex items-center gap-2">
      <div class="relative max-w-xs flex-1">
        <Search class="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[hsl(var(--so-muted-foreground))]" />
        <input placeholder="Filter projects..." class="so-input-field pl-8" />
      </div>

      <div class="flex items-center gap-1 rounded-md border border-[hsl(var(--so-border))] p-0.5">
        <button
          v-for="filter in projectFilters"
          :key="filter"
          type="button"
          class="rounded px-2.5 py-1 text-xs capitalize transition-colors"
          :class="
            projectFilter === filter
              ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
              : 'text-[hsl(var(--so-muted-foreground))] hover:text-[hsl(var(--so-foreground))]'
          "
          @click="emit('update:projectFilter', filter)"
        >
          {{ filter }}
        </button>
      </div>
    </div>

    <div class="flex gap-0">
      <div
        class="min-w-0 flex-1 rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]"
        :class="selectedProject ? 'rounded-r-none border-r-0' : ''"
      >
        <div class="so-font-mono flex items-center gap-4 border-b border-[hsl(var(--so-border))] px-4 py-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">
          <span class="flex-1">Name</span>
          <span class="hidden w-16 text-center sm:block">Status</span>
          <span class="hidden w-24 text-right md:block">Last deploy</span>
          <span class="hidden w-16 text-center lg:block">Members</span>
        </div>

        <div class="divide-y divide-[hsl(var(--so-border))]">
          <button
            v-for="project in filteredProjects"
            :key="project.id"
            type="button"
            class="flex w-full items-center gap-4 px-4 py-3 text-left transition-colors"
            :class="selectedProject?.id === project.id ? 'so-row-selected' : 'hover:bg-[hsl(var(--so-accent))/0.3]'"
            @click="toggleProject(project)"
          >
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2">
                <FolderKanban class="h-3.5 w-3.5 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
                <span class="truncate text-sm font-medium">{{ project.name }}</span>
                <span class="so-font-mono hidden text-[11px] text-[hsl(var(--so-muted-foreground))] sm:inline">
                  {{ project.slug }}
                </span>
              </div>
              <p class="ml-[22px] mt-0.5 truncate text-[11px] text-[hsl(var(--so-muted-foreground))]">
                {{ project.description }}
              </p>
            </div>

            <span class="hidden w-16 text-center sm:block">
              <CheckCircle2
                v-if="project.status === 'active'"
                class="mx-auto h-3.5 w-3.5 text-[hsl(var(--so-success))]"
              />
              <Clock
                v-else-if="project.status === 'paused'"
                class="mx-auto h-3.5 w-3.5 text-[hsl(var(--so-warning))]"
              />
              <FolderKanban
                v-else
                class="mx-auto h-3.5 w-3.5 text-[hsl(var(--so-muted-foreground))]"
              />
            </span>

            <span class="so-font-mono hidden w-24 text-right text-[11px] text-[hsl(var(--so-muted-foreground))] md:block">
              {{ project.lastDeploy }}
            </span>
            <span class="so-font-mono hidden w-16 text-center text-[11px] text-[hsl(var(--so-muted-foreground))] lg:block">
              {{ project.members }}
            </span>
          </button>
        </div>

        <div class="so-font-mono border-t border-[hsl(var(--so-border))] px-4 py-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">
          {{ filteredProjects.length }} project<span v-if="filteredProjects.length !== 1">s</span>
        </div>
      </div>

      <InspectorPane
        :open="!!selectedProject"
        :title="selectedProject?.name || ''"
        :subtitle="selectedProject?.slug"
        @close="emit('update:selectedProject', null)"
      >
        <template #actions>
          <button type="button" class="so-icon-button">
            <ExternalLink class="h-3 w-3" />
          </button>
        </template>

        <div v-if="selectedProject" class="space-y-4">
          <p class="text-xs text-[hsl(var(--so-muted-foreground))]">{{ selectedProject.description }}</p>

          <div class="space-y-2.5">
            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Status</span>
              <span
                class="flex items-center gap-1.5 capitalize"
                :class="
                  selectedProject.status === 'active'
                    ? 'text-[hsl(var(--so-success))]'
                    : selectedProject.status === 'paused'
                      ? 'text-[hsl(var(--so-warning))]'
                      : 'text-[hsl(var(--so-muted-foreground))]'
                "
              >
                <span class="h-1.5 w-1.5 rounded-full bg-current" />
                {{ selectedProject.status }}
              </span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Environment</span>
              <span class="so-font-mono text-xs capitalize">{{ selectedProject.environment }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Region</span>
              <span class="flex items-center gap-1 text-xs">
                <Globe class="h-3 w-3 text-[hsl(var(--so-muted-foreground))]" />
                {{ selectedProject.region }}
              </span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Uptime</span>
              <span class="so-font-mono text-xs">{{ selectedProject.uptime }}</span>
            </div>
          </div>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Last deploy</span>
              <span class="so-font-mono text-xs">{{ selectedProject.lastDeploy }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Last commit</span>
              <span class="so-font-mono text-xs text-[hsl(var(--so-primary))]">{{ selectedProject.lastCommit }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Created</span>
              <span class="so-font-mono text-xs">{{ selectedProject.created }}</span>
            </div>
          </div>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <div class="flex items-center gap-2 text-xs text-[hsl(var(--so-muted-foreground))]">
              <Users class="h-3.5 w-3.5" />
              <span>{{ selectedProject.members }} members</span>
            </div>

            <div class="flex items-center gap-2 text-xs text-[hsl(var(--so-muted-foreground))]">
              <GitBranch class="h-3.5 w-3.5" />
              <span>{{ selectedProject.branches }} branches</span>
            </div>
          </div>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <h4 class="so-font-mono mb-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">Recent activity</h4>

            <div class="flex items-center gap-2 text-xs">
              <Rocket class="h-3 w-3 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
              <span class="flex-1 truncate">Deployed to production</span>
              <span class="so-font-mono shrink-0 text-[10px] text-[hsl(var(--so-muted-foreground))]">2h ago</span>
            </div>

            <div class="flex items-center gap-2 text-xs">
              <Settings class="h-3 w-3 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
              <span class="flex-1 truncate">Config updated</span>
              <span class="so-font-mono shrink-0 text-[10px] text-[hsl(var(--so-muted-foreground))]">1d ago</span>
            </div>

            <div class="flex items-center gap-2 text-xs">
              <Users class="h-3 w-3 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
              <span class="flex-1 truncate">Member added</span>
              <span class="so-font-mono shrink-0 text-[10px] text-[hsl(var(--so-muted-foreground))]">3d ago</span>
            </div>
          </div>

          <div class="space-y-2 border-t border-[hsl(var(--so-border))] pt-3">
            <button type="button" class="so-button-secondary w-full justify-start">
              <ExternalLink class="h-3 w-3" />
              Open project
            </button>

            <button type="button" class="so-button-secondary w-full justify-start">
              <Settings class="h-3 w-3" />
              Project settings
            </button>
          </div>
        </div>
      </InspectorPane>
    </div>
  </div>
</template>
