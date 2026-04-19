import { computed, ref, toValue, type Ref, type UnwrapRef, watch } from "vue"

import {
  fetchFolioActivity,
  fetchFolioBootstrap,
  fetchFolioProjects,
  fetchFolioTasks,
} from "./queries"
import { folioWorkspaceRef } from "./paths"
import type {
  FolioActivityResponse,
  FolioBootstrapResponse,
  FolioProjectsResponse,
  FolioTasksResponse,
  FolioWorkspaceRef,
} from "./types"

import type { WorkspaceScope } from "../types"

export interface UseFolioReadOptions {
  autoFetch?: boolean
  enabled?: boolean | Ref<boolean>
}

export interface UseFolioResourceState<TData> {
  data: Ref<TData | UnwrapRef<TData> | null>
  loading: Ref<boolean>
  error: Ref<string | null>
  refresh: () => Promise<void>
}

const createResourceState = <TData>(
  scope: Ref<FolioWorkspaceRef | null>,
  load: (scope: FolioWorkspaceRef) => Promise<TData>,
  options: UseFolioReadOptions = {},
): UseFolioResourceState<TData> => {
  const data = ref<TData | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const enabled = computed(() => toValue(options.enabled ?? true))
  const autoFetch = options.autoFetch ?? false

  const refresh = async () => {
    if (!scope.value) return

    loading.value = true
    error.value = null

    try {
      data.value = await load(scope.value)
    } catch (cause) {
      error.value = cause instanceof Error ? cause.message : "Unexpected Folio fetch error"
    } finally {
      loading.value = false
    }
  }

  if (autoFetch) {
    watch(
      () => [scope.value?.ownerSlug, scope.value?.workspaceSlug, enabled.value],
      () => {
        if (!enabled.value) return
        void refresh()
      },
      { immediate: true },
    )
  }

  return { data, loading, error, refresh }
}

export const useFolioWorkspaceScope = (scope: WorkspaceScope): Ref<FolioWorkspaceRef | null> =>
  computed(() => folioWorkspaceRef(scope))

export const useFolioBootstrap = (
  scope: Ref<FolioWorkspaceRef | null>,
  options: UseFolioReadOptions = {},
) => {
  const state = createResourceState<FolioBootstrapResponse>(scope, fetchFolioBootstrap, options)

  return {
    ...state,
    summaryCounts: computed(() => state.data.value?.summary_counts ?? null),
    scope: computed(() => state.data.value?.scope ?? null),
  }
}

export const useFolioProjects = (
  scope: Ref<FolioWorkspaceRef | null>,
  options: UseFolioReadOptions = {},
) => {
  const state = createResourceState<FolioProjectsResponse>(scope, fetchFolioProjects, options)

  return {
    ...state,
    projects: computed(() => state.data.value?.projects ?? []),
    scope: computed(() => state.data.value?.scope ?? null),
  }
}

export const useFolioTasks = (
  scope: Ref<FolioWorkspaceRef | null>,
  options: UseFolioReadOptions = {},
) => {
  const state = createResourceState<FolioTasksResponse>(scope, fetchFolioTasks, options)

  return {
    ...state,
    tasks: computed(() => state.data.value?.tasks ?? []),
    scope: computed(() => state.data.value?.scope ?? null),
  }
}

export const useFolioActivity = (
  scope: Ref<FolioWorkspaceRef | null>,
  options: UseFolioReadOptions = {},
) => {
  const state = createResourceState<FolioActivityResponse>(scope, fetchFolioActivity, options)

  return {
    ...state,
    events: computed(() => state.data.value?.events ?? []),
    scope: computed(() => state.data.value?.scope ?? null),
  }
}
