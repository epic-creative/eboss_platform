<script setup lang="ts">
import { computed } from "vue"
import { ExternalLink, FolderKanban, Plus, Search } from "lucide-vue-next"

import InspectorField from "../InspectorField.vue"
import InspectorPane from "../InspectorPane.vue"
import InspectorSection from "../InspectorSection.vue"
import WorkspacePageHeader from "../WorkspacePageHeader.vue"
import { formatFolioDate, projectStatusClass, statusLabel } from "../presenters"
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

const priorityLabel = (value: number | null): string => (value === null ? "—" : String(value))
</script>

<template>
  <div class="ui-workspace-page" data-testid="workspace-page-projects">
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
          <span class="hidden w-40 text-center sm:block">Status</span>
          <span class="hidden w-28 text-right sm:block">Due</span>
          <span class="hidden w-20 text-center lg:block">Priority</span>
        </div>

        <div class="divide-y divide-[hsl(var(--so-border))]">
          <button
            v-for="project in filteredProjects"
            :key="project.id"
            type="button"
            class="flex w-full items-center gap-4 px-4 py-3 text-left transition-colors"
            :class="selectedProject?.id === project.id ? 'so-row-selected' : 'hover:bg-[hsl(var(--so-accent))/0.3]'"
            :data-testid="`project-row-${project.id}`"
            @click="toggleProject(project)"
          >
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2">
                <FolderKanban class="h-3.5 w-3.5 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
                <span class="truncate text-sm font-medium">{{ project.name }}</span>
                <span class="so-font-mono hidden text-[11px] text-[hsl(var(--so-muted-foreground))] sm:inline">
                  {{ project.id }}
                </span>
              </div>
            </div>

            <span class="hidden w-40 text-center sm:block">
              <span class="inline-flex items-center gap-1.5 text-[11px]" :class="projectStatusClass(project.status)">
                <span class="h-1.5 w-1.5 rounded-full bg-current" />
                {{ statusLabel(project.status) }}
              </span>
            </span>

            <span class="so-font-mono hidden w-28 text-right text-[11px] text-[hsl(var(--so-muted-foreground))] sm:block">
              {{ formatFolioDate(project.dueAt) }}
            </span>
            <span class="so-font-mono hidden w-20 text-center text-[11px] text-[hsl(var(--so-muted-foreground))] lg:block">
              {{ priorityLabel(project.priorityPosition) }}
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
        :subtitle="selectedProject?.id"
        data-testid="project-inspector"
        @close="emit('update:selectedProject', null)"
      >
        <template #actions>
          <button type="button" class="so-icon-button">
            <ExternalLink class="h-3 w-3" />
          </button>
        </template>

        <div v-if="selectedProject" class="space-y-4">
          <InspectorSection title="Status">
            <InspectorField label="Current status" :valueClass="projectStatusClass(selectedProject.status)">
              <span class="flex items-center gap-1.5">
                <span class="h-1.5 w-1.5 rounded-full bg-current" />
                {{ statusLabel(selectedProject.status) }}
              </span>
            </InspectorField>

            <InspectorField label="Project ID" :value="selectedProject.id" mono />
            <InspectorField label="Priority position" :value="priorityLabel(selectedProject.priorityPosition)" mono />
          </InspectorSection>

          <InspectorSection title="Schedule" with-divider>
            <InspectorField label="Due date" :value="formatFolioDate(selectedProject.dueAt)" mono />
            <InspectorField label="Review date" :value="formatFolioDate(selectedProject.reviewAt)" mono />
          </InspectorSection>

          <InspectorSection title="Actions" with-divider>
            <button type="button" class="so-button-secondary w-full justify-start">
              <ExternalLink class="h-3 w-3" />
              Open project
            </button>
          </InspectorSection>
        </div>
      </InspectorPane>
    </div>
  </div>
</template>
