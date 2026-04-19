import type { Member } from "./types"

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
