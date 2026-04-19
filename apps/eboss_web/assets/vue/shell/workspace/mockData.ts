import {
  Activity,
  FolderKanban,
  Key,
  Shield,
  Users,
} from "lucide-vue-next"

import type {
  AccessAuditRecord,
  ActivityEvent,
  ApiKeyRecord,
  Member,
  OverviewEvent,
  PostureItem,
  Project,
  ProjectFilter,
  RoleRecord,
} from "./types"

export const postureItems = [
  { label: "Members", value: "8", icon: Users, status: "ok" },
  { label: "Projects", value: "12", icon: FolderKanban, status: "ok" },
  { label: "Roles", value: "3", icon: Shield, status: "ok" },
  { label: "API keys", value: "4", icon: Key, status: "warn" },
] satisfies PostureItem[]

export const overviewEvents = [
  { hash: "a3f2c1d", action: "Project 'api-gateway' created", time: "2 min ago", user: "jdoe", status: "success" },
  { hash: "b7e4a9f", action: "Member 'sarah@acme.com' invited as admin", time: "15 min ago", user: "jdoe", status: "pending" },
  { hash: "c9d1e3b", action: "Deployment #142 completed", time: "1 hour ago", user: "system", status: "success" },
  { hash: "d2f5g8h", action: "API key rotated for production", time: "3 hours ago", user: "system", status: "success" },
  { hash: "e4h6j2k", action: "Billing plan upgraded to Pro", time: "5 hours ago", user: "jdoe", status: "success" },
] satisfies OverviewEvent[]

export const projectFilters = ["all", "active", "on_hold", "completed", "canceled", "archived"] satisfies ProjectFilter[]

export const projects = [
  { id: "1", name: "API Gateway", status: "active", dueAt: "2026-01-10T00:00:00Z", reviewAt: "2026-01-09T00:00:00Z", priorityPosition: 1 },
  { id: "2", name: "Dashboard UI", status: "active", dueAt: null, reviewAt: null, priorityPosition: 2 },
  { id: "3", name: "Auth Service", status: "completed", dueAt: "2026-01-15T00:00:00Z", reviewAt: "2026-01-14T00:00:00Z", priorityPosition: 3 },
  { id: "4", name: "Billing Engine", status: "on_hold", dueAt: "2026-01-20T00:00:00Z", reviewAt: null, priorityPosition: 4 },
  { id: "5", name: "Legacy Importer", status: "archived", dueAt: null, reviewAt: null, priorityPosition: null },
] satisfies Project[]

export const members = [
  { id: "1", name: "John Doe", email: "john@acme.com", role: "owner", status: "active", joinedAt: "2024-01-15", lastSeen: "Just now", projects: 12, teams: ["Engineering", "Platform"], permissions: 24, twoFactor: true },
  { id: "2", name: "Sarah Chen", email: "sarah@acme.com", role: "admin", status: "active", joinedAt: "2024-02-01", lastSeen: "2 hours ago", projects: 8, teams: ["Engineering"], permissions: 18, twoFactor: true },
  { id: "3", name: "Mike Torres", email: "mike@acme.com", role: "member", status: "active", joinedAt: "2024-02-15", lastSeen: "1 day ago", projects: 5, teams: ["Design"], permissions: 12, twoFactor: false },
  { id: "4", name: "Emma Wilson", email: "emma@acme.com", role: "member", status: "active", joinedAt: "2024-03-01", lastSeen: "3 days ago", projects: 3, teams: ["Engineering"], permissions: 12, twoFactor: true },
  { id: "5", name: "Alex Kim", email: "alex@acme.com", role: "viewer", status: "invited", joinedAt: "—", lastSeen: "—", projects: 0, teams: [], permissions: 6, twoFactor: false },
] satisfies Member[]

export const roles = [
  { id: "r1", name: "Owner", description: "Full workspace access", members: 1, permissions: 24, canDelete: false, created: "2024-01-15" },
  { id: "r2", name: "Admin", description: "Manage members, projects, and settings", members: 2, permissions: 18, canDelete: false, created: "2024-01-15" },
  { id: "r3", name: "Member", description: "Access assigned projects", members: 4, permissions: 12, canDelete: true, created: "2024-01-15" },
  { id: "r4", name: "Viewer", description: "Read-only access to assigned projects", members: 1, permissions: 6, canDelete: true, created: "2024-02-01" },
] satisfies RoleRecord[]

export const apiKeys = [
  { id: "k1", name: "Production API", prefix: "eboss_prod_", created: "2024-01-20", lastUsed: "2 min ago", status: "active", scopes: ["read", "write", "deploy"], expiresAt: "2025-01-20" },
  { id: "k2", name: "Staging API", prefix: "eboss_stg_", created: "2024-02-15", lastUsed: "1 day ago", status: "active", scopes: ["read", "write"], expiresAt: "2025-02-15" },
  { id: "k3", name: "CI/CD Pipeline", prefix: "eboss_ci_", created: "2024-03-01", lastUsed: "3 hours ago", status: "active", scopes: ["deploy"], expiresAt: "2025-03-01" },
  { id: "k4", name: "Legacy Key", prefix: "eboss_leg_", created: "2023-11-01", lastUsed: "30 days ago", status: "expiring", scopes: ["read"], expiresAt: "2024-05-01" },
] satisfies ApiKeyRecord[]

export const accessAudit = [
  { id: "a1", time: "2 min ago", actor: "jdoe", action: "Rotated API key", resource: "Production API", severity: "info", details: "Key prefix eboss_prod_ was regenerated", ip: "192.168.1.1" },
  { id: "a2", time: "1 hour ago", actor: "sarah", action: "Updated role permissions", resource: "Member role", severity: "warn", details: "Added 'deploy' permission to Member role", ip: "10.0.0.42" },
  { id: "a3", time: "3 hours ago", actor: "system", action: "Key expiry warning", resource: "Legacy Key", severity: "warn", details: "Key eboss_leg_ expires in 30 days", ip: "—" },
  { id: "a4", time: "1 day ago", actor: "jdoe", action: "Created API key", resource: "CI/CD Pipeline", severity: "info", details: "New key with deploy scope created", ip: "192.168.1.1" },
  { id: "a5", time: "2 days ago", actor: "mike", action: "Accessed workspace settings", resource: "Settings", severity: "info", details: "Viewed general workspace settings", ip: "172.16.0.5" },
] satisfies AccessAuditRecord[]

export const activityEvents = [
  { id: "1", hash: "a3f2c1d", action: "Project 'api-gateway' created", time: "2 min ago", user: "jdoe", type: "project", status: "success", resource: "api-gateway", details: "New project created with production environment", ip: "192.168.1.1" },
  { id: "2", hash: "b7e4a9f", action: "Member 'sarah@acme.com' invited as admin", time: "15 min ago", user: "jdoe", type: "member", status: "pending", resource: "sarah@acme.com", details: "Invitation sent with admin role", ip: "192.168.1.1", changes: [{ field: "role", from: "—", to: "admin" }] },
  { id: "3", hash: "c9d1e3b", action: "Deployment #142 completed", time: "1 hour ago", user: "system", type: "deploy", status: "success", resource: "api-gateway", details: "Deployed commit a3f2c1d to production us-east-1", ip: "—" },
  { id: "4", hash: "d2f5g8h", action: "API key rotated for production", time: "3 hours ago", user: "system", type: "access", status: "success", resource: "Production API", details: "Key prefix eboss_prod_ regenerated, old key invalidated", ip: "—" },
  { id: "5", hash: "e4h6j2k", action: "Billing plan upgraded to Pro", time: "5 hours ago", user: "jdoe", type: "billing", status: "success", resource: "Billing", details: "Plan changed from Starter to Pro ($49/mo)", ip: "192.168.1.1", changes: [{ field: "plan", from: "Starter", to: "Pro" }, { field: "price", from: "$19/mo", to: "$49/mo" }] },
  { id: "6", hash: "f1g3h5j", action: "Role 'Viewer' permissions updated", time: "8 hours ago", user: "sarah", type: "access", status: "success", resource: "Viewer role", details: "Added read access to activity logs", ip: "10.0.0.42", changes: [{ field: "permissions", from: "5", to: "6" }] },
  { id: "7", hash: "g2h4j6k", action: "Member 'mike@acme.com' role changed to member", time: "1 day ago", user: "jdoe", type: "member", status: "success", resource: "mike@acme.com", details: "Role downgraded from admin to member", ip: "192.168.1.1", changes: [{ field: "role", from: "admin", to: "member" }] },
  { id: "8", hash: "h3j5k7l", action: "Project 'legacy-importer' archived", time: "2 days ago", user: "jdoe", type: "project", status: "success", resource: "legacy-importer", details: "Project moved to archived state", ip: "192.168.1.1", changes: [{ field: "status", from: "active", to: "archived" }] },
  { id: "9", hash: "j4k6l8m", action: "API key 'Legacy Key' expiry warning", time: "3 days ago", user: "system", type: "access", status: "warning", resource: "Legacy Key", details: "Key eboss_leg_ expires in 30 days", ip: "—" },
] satisfies ActivityEvent[]
