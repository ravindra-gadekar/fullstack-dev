# Skill Self-Contained Packaging — Design Spec

**Created:** 2026-08-01T13:30:00
**Status:** Draft
**Author:** AI + Ravindra Gadekar

## Overview

The fullstack-dev-plugin's installation process (`npx skills add <repo> --skill '*'`) only copies files within each `skills/<name>/` directory. Top-level sibling directories (`agents/`, `scripts/`, `hooks/`) are never installed into target projects, but multiple SKILL.md flows dispatch to agent files under `agents/` at runtime — causing every command that needs an agent (6 of 9 skills) to break with file-not-found or "no such subagent type" errors in any project that installed the plugin.

The `vercel-labs/skills` CLI scopes each skill's install to the directory containing its `SKILL.md` (confirmed via upstream issue #1469). There is no frontmatter field or repo-level manifest for declaring external dependencies (upstream issue #515, open/unresolved). The fix must make every skill fully self-contained by nesting all runtime dependencies inside the skill's own directory tree.

This spec also addresses two secondary issues with the same root cause: orphaned top-level files (`scripts/pre-commit.sh`, `hooks/hooks.json`) whose content is already inlined in reference docs, and a health-check table that references "commands installed" when commands are not a separate install artifact.

## Architecture

### Agent relocation map

Every agent file moves from the top-level `agents/` directory into the `agents/` subdirectory of its owning skill. Each agent maps to exactly one skill — no sharing.

| Agent file | New location |
|---|---|
| `init-agent.md` | `skills/project/agents/init-agent.md` |
| `repo-agent.md` | `skills/project/agents/repo-agent.md` |
| `refresh-agent.md` | `skills/project/agents/refresh-agent.md` |
| `scanner-agent.md` | `skills/project/agents/scanner-agent.md` |
| `plan-reviewer-agent.md` | `skills/plan/agents/plan-reviewer-agent.md` |
| `grill-agent.md` | `skills/brainstorm/agents/grill-agent.md` |
| `implementer-agent.md` | `skills/implement/agents/implementer-agent.md` |
| `task-reviewer-agent.md` | `skills/implement/agents/task-reviewer-agent.md` |
| `security-reviewer-agent.md` | `skills/implement/agents/security-reviewer-agent.md` |
| `debugger-agent.md` | `skills/debug/agents/debugger-agent.md` |
| `refactor-agent.md` | `skills/refactor/agents/refactor-agent.md` |

### Orphan cleanup

| File | Action | Reason |
|---|---|---|
| `scripts/pre-commit.sh` | Delete | Content already inlined in `init-flow.md` §9.8; never read at runtime |
| `hooks/hooks.json` | Delete | Content already inlined in `init-flow.md` §9.7; never read at runtime |
| Top-level `agents/` dir | Delete (empty after moves) | No longer needed |
| Top-level `scripts/` dir | Delete (empty after removal) | No longer needed |
| Top-level `hooks/` dir | Delete (empty after removal) | No longer needed |

### Dispatch mechanism unification

Two dispatch idioms exist today — both broken post-install:

1. **Path-read dispatch** (`project`, `plan`, `brainstorm`): `<plugin-path>/agents/X.md` → change to `<skill-base-dir>/agents/X.md` using the skill's own base directory (already provided by the runtime at load time).

2. **Named subagent dispatch** (`debug`, `refactor`, `implement`): `subagent_type: "debugger-agent"` etc. relies on Claude Code agent auto-discovery from a directory that doesn't exist post-install → convert to path-read + `subagent_type: "claude"` pattern.

Post-fix, all 6 affected skills use one idiom: read agent instructions from `<skill-base-dir>/agents/<name>.md`, dispatch with `subagent_type: "claude"`.

## Data Flow

### Current flow (broken post-install)

```
User invokes /project --init
  → Claude Code loads .claude/skills/project/SKILL.md
    → SKILL.md says: "Read from <plugin-path>/agents/init-agent.md"
      → <plugin-path>/agents/ doesn't exist in target project
        → ❌ File not found / "no such subagent type"
```

### Fixed flow

```
User invokes /project --init
  → Claude Code loads .claude/skills/project/SKILL.md
    → SKILL.md resolves its own base directory (provided by runtime)
    → Reads <skill-base-dir>/agents/init-agent.md (co-located, always present)
    → Dispatches agent with subagent_type: "claude" + full instructions inline
      → ✅ Agent executes, reads reference/ docs from same skill dir
```

### Path resolution

Skills already receive their base directory at load time. SKILL.md prompt templates use `<skill-base-dir>` instead of `<plugin-path>` to construct agent file paths. No new resolution mechanism needed.

### Agent-to-agent dispatch (scanner-agent)

`scanner-agent.md` is reached transitively when `init-agent` or `repo-agent` delegates to it. All three now live in `skills/project/agents/`, so the delegation path stays internal to one skill directory.

## File Changes

### Files moved (11)

All `agents/*.md` → `skills/<owning-skill>/agents/*.md` per the relocation map. Content unchanged; only file path changes.

### Files deleted (3)

- `agents/` — empty directory after moves
- `scripts/pre-commit.sh` — orphaned duplicate of inline content in `init-flow.md` §9.8
- `hooks/hooks.json` — orphaned duplicate of inline content in `init-flow.md` §9.7

### Files edited — dispatch path references

| File | Change |
|---|---|
| `skills/project/SKILL.md` | 3 dispatch blocks: replace `<plugin-path>/agents/{init,repo,refresh}-agent.md` with `<skill-base-dir>/agents/` relative paths |
| `skills/plan/SKILL.md` | 1 dispatch block: replace `<plugin-path>/agents/plan-reviewer-agent.md` with skill-relative path |
| `skills/plan/reference/plan-flow.md` | Mirror the same path change for the plan-reviewer dispatch example |
| `skills/brainstorm/reference/brainstorm-flow.md` | 1 dispatch block: replace `<plugin-path>/agents/grill-agent.md` with skill-relative path |
| `skills/debug/reference/debug-flow.md` | Convert `subagent_type: "debugger-agent"` to path-read + `subagent_type: "claude"` pattern |
| `skills/refactor/SKILL.md` | Convert `subagent_type: "refactor-agent"` to path-read + `subagent_type: "claude"` pattern |
| `skills/implement/SKILL.md` | Convert `subagent_type: "implementer-agent"` / `"task-reviewer-agent"` / `"security-reviewer-agent"` to path-read + `subagent_type: "claude"` pattern |
| `skills/implement/reference/implement-flow.md` | Mirror the same dispatch conversion + update the agent path table |

### Files edited — doc/reference updates

| File | Change |
|---|---|
| `skills/project/reference/refresh-flow.md` | Line 52: remove claim that `scripts/pre-commit.sh` is "copied to .git/hooks" — the hook is generated inline by the init-agent per `init-flow.md` §9.8 |
| `skills/project/agents/init-agent.md` | Health-check table: change "commands installed" to "skills installed" |
| `CLAUDE.md` | Update repo structure: remove `agents/`, `hooks/`, `scripts/` as top-level dirs; note agents live under `skills/<name>/agents/` |
| `CONTEXT.md` | Update domain model, naming conventions, relationships |
| `ARCHITECTURE.md` | Update directory tree and module table |
| `docs/project/architecture.md` | Update service map table: agents under `skills/*/agents/`, remove Scripts and Hooks rows |
| `docs/project/tech-stack.md` | Remove `scripts/pre-commit.sh` and `hooks/hooks.json` references |

### Files NOT changed

- `skills-lock.json` — auto-generated by external CLI; regenerated after structural change
- `commands/*.md` — unaffected; invoke skills via the Skill tool
- `skills/*/reference/*.md` (except those listed above) — no agent path references
- `.fullstack-dev/config.json` — no structural fields affected

## Error Handling

### Agent file not found post-install

**Before fix:** `Read` tool fails when `<plugin-path>/agents/X.md` doesn't exist. The user sees a cryptic file-not-found or "no such subagent type" message with no recovery path.

**After fix:** Agent files are co-located with the SKILL.md that dispatches them. The failure mode is eliminated rather than caught.

### Stale skills-lock.json after restructure

After moving files, existing `skills-lock.json` hashes will be stale. Running `npx skills add` on this repo regenerates correct hashes. The fix commit should include a regenerated `skills-lock.json`.

### Existing target project installations

Users who already installed the plugin need to re-run `npx skills add` to pick up the new structure. This is the normal upgrade path — no migration script needed, just a note in the PR description.

## Testing Strategy

### Smoke test (primary)

1. **Fresh install test:** In a clean test project, run `npx skills add <repo> --skill '*'` after pushing the fix branch. Verify `.claude/skills/<name>/agents/*.md` files exist.

2. **Command dispatch test:** Run `/project --init` in the test project and confirm the init-agent executes without file-not-found errors.

3. **Dogfood test:** Re-run `npx skills add` on this repo itself. Confirm `.agents/skills/` and `.claude/skills/` mirrors include agent files.

### Static checks (pre-push)

4. **Dangling reference scan:** `grep -r "agents/" skills/ --include="*.md"` — every match resolves within `skills/<name>/agents/`.

5. **Orphan check:** No files in top-level `agents/`, `scripts/`, or `hooks/`.

6. **Health-check table:** `skills/project/agents/init-agent.md` says "skills installed" not "commands installed".

### Not tested

No unit/integration tests or CI — this is a markdown/JSON plugin. Verification is by exercising commands in a live Claude Code session (dogfooding), per `CLAUDE.md`.

## Acceptance Criteria

- [ ] All 11 agent files relocated from top-level `agents/` to `skills/<owning-skill>/agents/<name>.md` per the relocation map
- [ ] Top-level `agents/`, `scripts/`, and `hooks/` directories deleted (no files remain)
- [ ] All SKILL.md and reference doc dispatch blocks use `<skill-base-dir>/agents/` paths instead of `<plugin-path>/agents/`
- [ ] All named `subagent_type` dispatches (`debugger-agent`, `refactor-agent`, `implementer-agent`, `task-reviewer-agent`, `security-reviewer-agent`) converted to path-read + `subagent_type: "claude"` pattern
- [ ] `grep -r "<plugin-path>/agents/" skills/` returns zero matches
- [ ] `grep -r "subagent_type.*-agent" skills/` returns zero matches (no named agent dispatch remaining)
- [ ] `skills/project/reference/refresh-flow.md` no longer claims `scripts/pre-commit.sh` is copied to `.git/hooks`
- [ ] Health-check table in init-agent (now at `skills/project/agents/init-agent.md`) says "skills installed" instead of "commands installed"
- [ ] `CLAUDE.md`, `CONTEXT.md`, `ARCHITECTURE.md`, `docs/project/architecture.md`, `docs/project/tech-stack.md` updated to reflect new structure (no references to top-level `agents/`, `scripts/`, or `hooks/` directories)
- [ ] `skills-lock.json` regenerated with correct hashes after structural change
- [ ] Fresh `npx skills add --skill '*'` install in a test project includes agent files under `.claude/skills/<name>/agents/`
- [ ] `/project --init` executes successfully in a freshly installed test project (no file-not-found or "no such subagent type" errors)
