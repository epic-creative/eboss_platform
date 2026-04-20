<script setup lang="ts">
import { computed, ref, watch } from "vue"
import {
  AlertTriangle,
  ExternalLink,
  FolderKanban,
  LoaderCircle,
  PenLine,
  Plus,
  Search,
} from "lucide-vue-next"

import InspectorField from "../InspectorField.vue"
import InspectorPane from "../InspectorPane.vue"
import InspectorSection from "../InspectorSection.vue"
import WorkspaceEmptyState from "../WorkspaceEmptyState.vue"
import WorkspacePageHeader from "../WorkspacePageHeader.vue"
import WorkspacePanel from "../WorkspacePanel.vue"
import type { FolioProjectUpdatePayload } from "../folio/types"
import { formatFolioDate, projectStatusClass, statusLabel } from "../presenters"
import type { Project, ProjectFilter } from "../types"

const props = defineProps<{
  workspaceReference: string
  projectFilters: readonly ProjectFilter[]
  projectFilter: ProjectFilter
  projects: Project[]
  selectedProject: Project | null
  loading: boolean
  error: string | null
  canCreateProject: boolean
  canUpdateProject: boolean
  creatingProject: boolean
  updatingProject: boolean
  refresh: () => Promise<void>
  createProject: (title: string) => Promise<void>
  updateProject: (projectId: string, payload: FolioProjectUpdatePayload) => Promise<void>
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
const hasProjects = computed(() => props.projects.length > 0)
const canInspectProject = computed(
  () =>
    !props.loading &&
    props.error === null &&
    !!props.selectedProject &&
    filteredProjects.value.some((project) => project.id === props.selectedProject?.id),
)

const priorityLabel = (value: number | null): string => (value === null ? "—" : String(value))
const createFormOpen = ref(false)
const createProjectTitle = ref("")
const createProjectError = ref<string | null>(null)
const editFormOpen = ref(false)
const updateProjectError = ref<string | null>(null)
const editProjectTitle = ref("")
const editProjectDescription = ref("")
const editProjectNotes = ref("")
const editProjectDueAt = ref("")
const editProjectReviewAt = ref("")
const editProjectMetadata = ref("{}")

const toggleProject = (project: Project) => {
  emit("update:selectedProject", props.selectedProject?.id === project.id ? null : project)
}

const openCreateProjectForm = () => {
  if (!props.canCreateProject) return

  createProjectError.value = null
  createFormOpen.value = true
}

const closeCreateProjectForm = () => {
  createProjectTitle.value = ""
  createProjectError.value = null
  createFormOpen.value = false
}

const toDateInputValue = (value: string | null): string => {
  if (!value) return ""

  const prefix = value.match(/^(\d{4}-\d{2}-\d{2})/)
  if (prefix) return prefix[1]

  const parsed = new Date(value)
  return Number.isNaN(parsed.valueOf()) ? "" : parsed.toISOString().slice(0, 10)
}

const toMetadataInputValue = (metadata: Record<string, unknown>): string => {
  try {
    return JSON.stringify(metadata || {}, null, 2)
  } catch (_cause) {
    return "{}"
  }
}

const populateEditForm = (project: Project | null) => {
  editProjectTitle.value = project?.name ?? ""
  editProjectDescription.value = project?.description ?? ""
  editProjectNotes.value = project?.notes ?? ""
  editProjectDueAt.value = toDateInputValue(project?.dueAt ?? null)
  editProjectReviewAt.value = toDateInputValue(project?.reviewAt ?? null)
  editProjectMetadata.value = toMetadataInputValue(project?.metadata ?? {})
}

watch(
  () => props.selectedProject?.id,
  () => {
    editFormOpen.value = false
    updateProjectError.value = null
    populateEditForm(props.selectedProject)
  },
  { immediate: true },
)

watch(
  () => props.selectedProject,
  (project) => {
    if (!editFormOpen.value) {
      populateEditForm(project)
    }
  },
)

const openEditProjectForm = () => {
  if (!props.canUpdateProject || !props.selectedProject) return

  populateEditForm(props.selectedProject)
  updateProjectError.value = null
  editFormOpen.value = true
}

const closeEditProjectForm = () => {
  populateEditForm(props.selectedProject)
  updateProjectError.value = null
  editFormOpen.value = false
}

const submitCreateProject = async () => {
  if (!props.canCreateProject || props.creatingProject) return

  const title = createProjectTitle.value.trim()

  if (!title) {
    createProjectError.value = "Project title is required."
    return
  }

  createProjectError.value = null

  try {
    await props.createProject(title)
    closeCreateProjectForm()
  } catch (cause) {
    createProjectError.value =
      cause instanceof Error ? cause.message : "Project creation failed."
  }
}

const normalizeOptionalText = (value: string): string | null => {
  const trimmed = value.trim()
  return trimmed === "" ? null : trimmed
}

const normalizeOptionalDate = (value: string): string | null => {
  const trimmed = value.trim()
  return trimmed === "" ? null : trimmed
}

const detailValue = (value: string | null): string => {
  if (!value) return "—"

  const trimmed = value.trim()
  return trimmed === "" ? "—" : trimmed
}

const formatMetadata = (value: Record<string, unknown>): string => {
  try {
    return JSON.stringify(value || {}, null, 2)
  } catch (_cause) {
    return "{}"
  }
}

const submitProjectUpdate = async () => {
  if (!props.canUpdateProject || props.updatingProject || !props.selectedProject) return

  const title = editProjectTitle.value.trim()

  if (!title) {
    updateProjectError.value = "Project title is required."
    return
  }

  let parsedMetadata: Record<string, unknown> = {}
  const metadataRaw = editProjectMetadata.value.trim()

  if (metadataRaw !== "") {
    try {
      const decoded: unknown = JSON.parse(metadataRaw)

      if (!decoded || typeof decoded !== "object" || Array.isArray(decoded)) {
        updateProjectError.value = "Planning metadata must be a JSON object."
        return
      }

      parsedMetadata = decoded as Record<string, unknown>
    } catch (_cause) {
      updateProjectError.value = "Planning metadata must be valid JSON."
      return
    }
  }

  const payload: FolioProjectUpdatePayload = {
    title,
    description: normalizeOptionalText(editProjectDescription.value),
    notes: normalizeOptionalText(editProjectNotes.value),
    due_at: normalizeOptionalDate(editProjectDueAt.value),
    review_at: normalizeOptionalDate(editProjectReviewAt.value),
    metadata: parsedMetadata,
  }

  updateProjectError.value = null

  try {
    await props.updateProject(props.selectedProject.id, payload)
    closeEditProjectForm()
  } catch (cause) {
    updateProjectError.value =
      cause instanceof Error ? cause.message : "Project details could not be saved."
  }
}
</script>

<template>
  <div class="ui-workspace-page" data-testid="workspace-page-projects">
    <WorkspacePageHeader title="Projects" :subtitle="workspaceReference">
      <template #actions>
        <button
          v-if="canCreateProject"
          type="button"
          class="so-button-primary"
          data-testid="projects-create-open"
          @click="openCreateProjectForm"
        >
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

    <WorkspacePanel
      v-if="createFormOpen"
      title="Create project"
      subtitle="Add a project to this workspace."
      data-testid="projects-create-form"
    >
      <form class="space-y-3" data-testid="projects-create-form-element" @submit.prevent="submitCreateProject">
        <div class="space-y-1">
          <label
            for="folio-project-title"
            class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
          >
            Project title
          </label>
          <input
            id="folio-project-title"
            v-model="createProjectTitle"
            class="so-input-field"
            type="text"
            autocomplete="off"
            placeholder="Example: Atlas migration"
            data-testid="projects-create-title-input"
            :disabled="creatingProject"
            @input="createProjectError = null"
          />
        </div>

        <div
          v-if="createProjectError"
          class="so-alert-panel so-alert-panel-error"
          data-testid="projects-create-error"
        >
          <p class="text-xs text-[hsl(var(--so-destructive))]">{{ createProjectError }}</p>
        </div>

        <div class="flex flex-wrap items-center justify-end gap-2">
          <button
            type="button"
            class="so-button-secondary"
            :disabled="creatingProject"
            data-testid="projects-create-cancel"
            @click="closeCreateProjectForm"
          >
            Cancel
          </button>

          <button
            type="submit"
            class="so-button-primary"
            :disabled="creatingProject"
            data-testid="projects-create-submit"
          >
            <LoaderCircle v-if="creatingProject" class="h-3 w-3 animate-spin" />
            <Plus v-else class="h-3 w-3" />
            {{ creatingProject ? "Creating..." : "Create project" }}
          </button>
        </div>
      </form>
    </WorkspacePanel>

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

        <WorkspaceEmptyState
          v-if="loading"
          :icon="LoaderCircle"
          title="Loading projects"
          copy="Updating the project list from Folio."
          data-testid="projects-state-loading"
        />

        <div
          v-else-if="error"
          class="so-alert-panel so-alert-panel-error m-4"
          data-testid="projects-state-error"
        >
          <div class="mb-2 flex items-center gap-2">
            <AlertTriangle class="h-4 w-4 text-[hsl(var(--so-destructive))]" />
            <h3 class="text-sm font-medium text-[hsl(var(--so-destructive))]">Unable to load projects</h3>
          </div>
          <p class="mb-3 text-xs text-[hsl(var(--so-muted-foreground))]">{{ error }}</p>
          <button type="button" class="so-button-secondary text-[hsl(var(--so-destructive))]" @click="refresh">
            Retry
          </button>
        </div>

        <WorkspaceEmptyState
          v-else-if="!hasProjects"
          title="No projects yet"
          copy="No Folio projects have been created for this workspace yet."
          data-testid="projects-state-empty"
        />

        <div
          v-else-if="!filteredProjects.length"
          class="so-font-mono px-4 py-8 text-center text-sm text-[hsl(var(--so-muted-foreground))]"
          data-testid="projects-state-empty-filtered"
        >
          No projects match this view.
        </div>

        <div v-else class="divide-y divide-[hsl(var(--so-border))]">
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

        <div
          v-if="filteredProjects.length"
          class="so-font-mono border-t border-[hsl(var(--so-border))] px-4 py-2 text-[11px] text-[hsl(var(--so-muted-foreground))]"
        >
          {{ filteredProjects.length }} project<span v-if="filteredProjects.length !== 1">s</span>
        </div>
      </div>

      <InspectorPane
        :open="canInspectProject"
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

          <InspectorSection title="Details" with-divider>
            <div class="space-y-2.5">
              <div>
                <p class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Description</p>
                <p
                  class="mt-1 whitespace-pre-wrap break-words text-xs text-[hsl(var(--so-muted-foreground))]"
                  data-testid="project-description-value"
                >
                  {{ detailValue(selectedProject.description) }}
                </p>
              </div>

              <div>
                <p class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Notes</p>
                <p
                  class="mt-1 whitespace-pre-wrap break-words text-xs text-[hsl(var(--so-muted-foreground))]"
                  data-testid="project-notes-value"
                >
                  {{ detailValue(selectedProject.notes) }}
                </p>
              </div>
            </div>
          </InspectorSection>

          <InspectorSection title="Planning metadata" with-divider>
            <pre
              class="max-h-36 overflow-auto whitespace-pre-wrap break-all rounded border border-[hsl(var(--so-border))] bg-[hsl(var(--so-surface-2))] p-2 so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]"
              data-testid="project-metadata-value"
            >{{ formatMetadata(selectedProject.metadata) }}</pre>
          </InspectorSection>

          <InspectorSection v-if="canUpdateProject" title="Edit details" with-divider>
            <button
              v-if="!editFormOpen"
              type="button"
              class="so-button-secondary w-full justify-start"
              data-testid="project-edit-open"
              @click="openEditProjectForm"
            >
              <PenLine class="h-3 w-3" />
              Edit project details
            </button>

            <form
              v-else
              class="space-y-3"
              data-testid="project-edit-form"
              @submit.prevent="submitProjectUpdate"
            >
              <div class="space-y-1">
                <label
                  for="folio-project-edit-title"
                  class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
                >
                  Project title
                </label>
                <input
                  id="folio-project-edit-title"
                  v-model="editProjectTitle"
                  class="so-input-field"
                  type="text"
                  autocomplete="off"
                  placeholder="Example: Atlas migration"
                  data-testid="project-edit-title-input"
                  :disabled="updatingProject"
                  @input="updateProjectError = null"
                />
              </div>

              <div class="space-y-1">
                <label
                  for="folio-project-edit-description"
                  class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
                >
                  Description
                </label>
                <textarea
                  id="folio-project-edit-description"
                  v-model="editProjectDescription"
                  class="so-input-field h-20 resize-none py-2"
                  placeholder="What outcome does this project drive?"
                  data-testid="project-edit-description-input"
                  :disabled="updatingProject"
                  @input="updateProjectError = null"
                />
              </div>

              <div class="grid gap-2 sm:grid-cols-2">
                <div class="space-y-1">
                  <label
                    for="folio-project-edit-due"
                    class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
                  >
                    Due date
                  </label>
                  <input
                    id="folio-project-edit-due"
                    v-model="editProjectDueAt"
                    class="so-input-field"
                    type="date"
                    data-testid="project-edit-due-input"
                    :disabled="updatingProject"
                    @input="updateProjectError = null"
                  />
                </div>

                <div class="space-y-1">
                  <label
                    for="folio-project-edit-review"
                    class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
                  >
                    Review date
                  </label>
                  <input
                    id="folio-project-edit-review"
                    v-model="editProjectReviewAt"
                    class="so-input-field"
                    type="date"
                    data-testid="project-edit-review-input"
                    :disabled="updatingProject"
                    @input="updateProjectError = null"
                  />
                </div>
              </div>

              <div class="space-y-1">
                <label
                  for="folio-project-edit-notes"
                  class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
                >
                  Notes
                </label>
                <textarea
                  id="folio-project-edit-notes"
                  v-model="editProjectNotes"
                  class="so-input-field h-20 resize-none py-2"
                  placeholder="Optional planning notes..."
                  data-testid="project-edit-notes-input"
                  :disabled="updatingProject"
                  @input="updateProjectError = null"
                />
              </div>

              <div class="space-y-1">
                <label
                  for="folio-project-edit-metadata"
                  class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
                >
                  Planning metadata (JSON)
                </label>
                <textarea
                  id="folio-project-edit-metadata"
                  v-model="editProjectMetadata"
                  class="so-input-field so-font-mono h-28 resize-y py-2 text-[11px]"
                  placeholder='{"cadence":"weekly-review"}'
                  data-testid="project-edit-metadata-input"
                  :disabled="updatingProject"
                  @input="updateProjectError = null"
                />
              </div>

              <div
                v-if="updateProjectError"
                class="so-alert-panel so-alert-panel-error"
                data-testid="project-edit-error"
              >
                <p class="text-xs text-[hsl(var(--so-destructive))]">{{ updateProjectError }}</p>
              </div>

              <div class="flex flex-wrap items-center justify-end gap-2">
                <button
                  type="button"
                  class="so-button-secondary"
                  data-testid="project-edit-cancel"
                  :disabled="updatingProject"
                  @click="closeEditProjectForm"
                >
                  Cancel
                </button>

                <button
                  type="submit"
                  class="so-button-primary"
                  data-testid="project-edit-submit"
                  :disabled="updatingProject"
                >
                  <LoaderCircle v-if="updatingProject" class="h-3 w-3 animate-spin" />
                  <PenLine v-else class="h-3 w-3" />
                  {{ updatingProject ? "Saving..." : "Save updates" }}
                </button>
              </div>
            </form>
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
