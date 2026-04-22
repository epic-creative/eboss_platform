# Chat Rulebook

This file names the core chat invariants for the workspace chat app.

## Rule Set

### CR-001 Workspace scope is absolute

Every chat session and chat message belongs to exactly one workspace. Shared chat access is workspace-scoped.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_chat/lib/eboss_chat/chat_session.ex`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_chat/lib/eboss_chat/chat_message.ex`

### CR-002 Sessions are shared, not private

Any member who can access the workspace can open and continue any active chat session in that workspace.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_chat/lib/eboss_chat/chat_session.ex`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_chat/lib/eboss_chat/chat_message.ex`

### CR-003 Session archive is restricted

Only the session creator or a workspace admin may archive a session.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_chat/lib/eboss_chat/checks/actor_can_manage_session.ex`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_chat/lib/eboss_chat/chat_session.ex`

### CR-004 Only one assistant run may be active per session

At most one pending assistant message may exist for a session at a time.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_data/priv/repo/migrations/20260420110000_add_eboss_chat_v1.exs`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_chat/lib/eboss_chat/service.ex`

### CR-005 Session titles derive from the first user turn

New sessions default their title from the first draft message seed. Users do not manually rename sessions in v1.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_chat/lib/eboss_chat/changes/derive_session_title.ex`

### CR-006 Assistant usage is persisted for future billing

Assistant replies persist provider/model metadata and token usage on the assistant message record.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_chat/lib/eboss_chat/chat_message.ex`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_chat/lib/eboss_chat/service.ex`

### CR-007 Model selection is catalog-bound

Chat requests may select only a model key exposed by the workspace chat model catalog. Unsupported keys fail before an assistant run starts.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_chat/lib/eboss_chat/model_catalog.ex`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/lib/eboss_web/controllers/chat_controller.ex`
