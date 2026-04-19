import type { Member, ProjectStatus, TaskStatus } from "./types"

export const memberInitials = (name: string) =>
  name
    .split(" ")
    .map(part => part[0] || "")
    .join("")

export const roleBadgeClass = (role: Member["role"]) => {
  if (role === "owner") return "border-[hsl(var(--so-primary))] text-[hsl(var(--so-primary))]"
  if (role === "admin") return "border-[hsl(var(--so-warning))] text-[hsl(var(--so-warning))]"
  return "border-[hsl(var(--so-border))] text-[hsl(var(--so-muted-foreground))]"
}

const formatDate = (value: string): string =>
  Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  }).format(new Date(value))

export const formatFolioDate = (value: string | null): string => {
  if (!value) return "—"

  const parsed = new Date(value)
  return Number.isNaN(parsed.valueOf()) ? value : formatDate(value)
}

export const statusLabel = (status: string): string =>
  status.replace(/_/g, " ").replace(/\b\w/g, char => char.toUpperCase())

export const projectStatusClass = (status: ProjectStatus): string => {
  if (status === "active") return "text-[hsl(var(--so-success))]"
  if (status === "on_hold") return "text-[hsl(var(--so-warning))]"
  if (status === "completed") return "text-[hsl(var(--so-primary))]"
  if (status === "canceled") return "text-[hsl(var(--so-destructive))]"

  return "text-[hsl(var(--so-muted-foreground))]"
}

export const taskStatusClass = (status: TaskStatus): string => {
  if (status === "done") return "text-[hsl(var(--so-success))]"
  if (status === "canceled" || status === "archived") return "text-[hsl(var(--so-destructive))]"
  if (status === "waiting_for" || status === "scheduled") return "text-[hsl(var(--so-warning))]"

  return "text-[hsl(var(--so-primary))]"
}
