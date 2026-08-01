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

1. **Path-read dispatch** (`project`, `plan`, `brainstorm`, `implement`): The SKILL.md instructs the LLM to read agent instructions from a file path (e.g., `<plugin-path>/agents/init-agent.md`) and dispatch with `subagent_type: "claude"`. Change the path to be relative to the SKILL.md's own directory (e.g., "Read `agents/init-agent.md` relative to this SKILL.md file").

2. **Named subagent dispatch** (`debug`, `refactor`): `subagent_type: "debugger-agent"` etc. relies on Claude Code agent auto-discovery from a directory that doesn't exist post-install → convert to the same path-read pattern as idiom 1.

Post-fix, all 6 affected skills use one idiom: the SKILL.md instructs the LLM to read agent instructions from `agents/<name>.md` relative to the SKILL.md file, then dispatch with `subagent_type: "claude"`.

### Path resolution convention

`<skill-base-dir>` is a prompt convention (not a runtime variable). The LLM resolves it from the SKILL.md file path it was loaded from — the runtime already provides this (e.g., "Base directory for this skill: .../.claude/skills/brainstorm"). Dispatch blocks should use concrete relative language: "Read `agents/<name>.md` relative to this SKILL.md file" rather than an abstract placeholder.

### Brainstorm grill-agent reconciliation

The brainstorm SKILL.md currently embeds grill-agent instructions inline (not reading from a file), while `brainstorm-flow.md` (the authoritative reference) dispatches via file-read. After the fix, both use file-read from `agents/grill-agent.md` relative to the skill directory — the SKILL.md inline prompt is replaced with the file-read pattern to match the reference doc.

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
    → SKILL.md says: "Read agents/init-agent.md relative to this SKILL.md file"
    → LLM resolves path from its known base directory
    → Reads .claude/skills/project/agents/init-agent.md (co-located, always present)
    → Dispatches agent with subagent_type: "claude" + full instructions inline
      → ✅ Agent executes, reads reference/ docs from same skill dir
```

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
| `skills/project/SKILL.md` | 3 dispatch blocks: replace `<plugin-path>/agents/{init,repo,refresh}-agent.md` with "Read `agents/<name>.md` relative to this SKILL.md file" |
| `skills/plan/SKILL.md` | 1 dispatch block: replace `<plugin-path>/agents/plan-reviewer-agent.md` with skill-relative path |
| `skills/plan/reference/plan-flow.md` | Mirror the same path change for the plan-reviewer dispatch example |
| `skills/brainstorm/SKILL.md` | Replace inline grill-agent prompt with file-read pattern (matching the authoritative reference doc) |
| `skills/brainstorm/reference/brainstorm-flow.md` | 1 dispatch block: replace `<plugin-path>/agents/grill-agent.md` with skill-relative path |
| `skills/debug/reference/debug-flow.md` | Convert `subagent_type: "debugger-agent"` to path-read + `subagent_type: "claude"` pattern |
| `skills/refactor/SKILL.md` | Convert `subagent_type: "refactor-agent"` to path-read + `subagent_type: "claude"` pattern |
| `skills/implement/SKILL.md` | Update prose dispatch to use skill-relative agent paths; update Reference Documents table (`../../agents/*.md` → `agents/*.md`) |
| `skills/implement/reference/implement-flow.md` | Update dispatch instructions to use skill-relative agent paths |

### Files edited — doc/reference updates

| File | Change |
|---|---|
| `skills/project/reference/refresh-flow.md` | Line 52: remove claim that `scripts/pre-commit.sh` is "copied to .git/hooks" — the hook is generated inline by the init-agent per `init-flow.md` §9.8 |
| `skills/project/agents/init-agent.md` | Health-check table: remove "; commands installed" from the Claude Config row (it already says "skills installed") |
| `skills/project/reference/context7-usage.md` | Update agent name references to include their skill location (e.g., "the debugger-agent in `skills/debug/agents/`") |
| `CLAUDE.md` | Update repo structure: remove `agents/`, `hooks/`, `scripts/` as top-level dirs; note agents live under `skills/<name>/agents/` |
| `CONTEXT.md` | Update domain model, naming conventions, relationships |
| `ARCHITECTURE.md` | Update directory tree and module table |
| `docs/project/architecture.md` | Update service map table: agents under `skills/*/agents/`, remove Scripts and Hooks rows |
| `docs/project/tech-stack.md` | Remove `scripts/pre-commit.sh` and `hooks/hooks.json` references |

### Files NOT changed

- `skills-lock.json` — auto-generated by external CLI; regenerated after structural change
- `commands/*.md` — unaffected; invoke skills via the Skill tool
- `.fullstack-dev/config.json` — no structural fields affected

## Error Handling

### Agent file not found post-install

**Before fix:** `Read` tool fails when `<plugin-path>/agents/X.md` doesn't exist. The user sees a cryptic file-not-found or "no such subagent type" message with no recovery path.

**After fix:** Agent files are co-located with the SKILL.md that dispatches them. The failure mode is eliminated rather than caught.

### Stale skills-lock.json after restructure

After moving files, existing `skills-lock.json` hashes will be stale. Running `npx skills add` on this repo regenerates correct hashes. The fix commit should include a regenerated `skills-lock.json`.

### Existing target project installations

Users who already installed the plugin need to re-run `npx skills add` to pick up the new structure. This is the normal upgrade path. The PR description must include a prominent migration note: "If you previously installed this plugin, re-run `npx skills add https://github.com/ravindra-gadekar/fullstack-dev-plugin.git --skill '*'` to pick up the restructured agent files."

## Known Limitations

### Agent frontmatter not applied at dispatch time

Agent `.md` files have YAML frontmatter declaring `tools`, `model`, `maxTurns`, `effort`, and `mcpServers`. When dispatched via `subagent_type: "claude"` (the path-read pattern), Claude Code ignores this frontmatter — the agent inherits the parent session's tools, model, and settings.

This is a **pre-existing limitation**, not introduced by this fix. The path-read agents (`project`, `plan`, `brainstorm`, `implement`) already dispatch as `subagent_type: "claude"` today, so their frontmatter was never applied either. Converting `debug` and `refactor` from named subagent dispatch to path-read does extend this limitation to those two agents (their `tools` restrictions — e.g., debugger-agent is intended as read-only — will no longer be enforced by the runtime).

**Decision:** Preserve frontmatter as documentation of intended constraints. Converting frontmatter to Agent() call parameters (which does support `model`) or to prose-level tool restrictions in the agent prompt is a separate enhancement — out of scope for this packaging fix, which focuses on making skills installable, not on changing agent behavior.

## Testing Strategy

### Smoke test (primary)

1. **Fresh install test:** In a clean test project, run `npx skills add <repo> --skill '*'` after pushing the fix branch. Verify `.claude/skills/<name>/agents/*.md` files exist.

2. **Command dispatch test:** Run `/project --init` in the test project and confirm the init-agent executes without file-not-found errors.

3. **Dogfood test:** Re-run `npx skills add` on this repo itself. Confirm `.claude/skills/<name>/agents/*.md` files exist in the installed mirror.

### Static checks (pre-push)

1. **Dangling reference scan:** `grep -r "agents/" skills/ --include="*.md"` — every match resolves within `skills/<name>/agents/`.

2. **Old relative path scan:** `grep -r "../../agents/" skills/` returns zero matches (no relative paths to the old top-level agents directory).

3. **Orphan check:** No files in top-level `agents/`, `scripts/`, or `hooks/`.

4. **Health-check table:** `skills/project/agents/init-agent.md` Claude Config row says "skills installed" without "; commands installed".

### Not tested

No unit/integration tests or CI — this is a markdown/JSON plugin. Verification is by exercising commands in a live Claude Code session (dogfooding), per `CLAUDE.md`.

## Acceptance Criteria

- [ ] All 11 agent files relocated from top-level `agents/` to `skills/<owning-skill>/agents/<name>.md` per the relocation map
- [ ] Top-level `agents/`, `scripts/`, and `hooks/` directories deleted (no files remain)
- [ ] All SKILL.md and reference doc dispatch blocks use skill-relative agent paths (e.g., "Read `agents/<name>.md` relative to this SKILL.md file") instead of `<plugin-path>/agents/`
- [ ] Named `subagent_type` dispatches in `debug` and `refactor` converted to path-read + `subagent_type: "claude"` pattern
- [ ] Brainstorm SKILL.md grill-agent dispatch converted from inline prompt to file-read pattern (matching the authoritative reference doc)
- [ ] `grep -r "<plugin-path>/agents/" skills/` returns zero matches
- [ ] `grep -r "../../agents/" skills/` returns zero matches
- [ ] `grep -r "subagent_type.*-agent" skills/` returns zero matches (no named agent dispatch remaining)
- [ ] `skills/project/reference/refresh-flow.md` no longer claims `scripts/pre-commit.sh` is copied to `.git/hooks`
- [ ] Health-check table in init-agent (now at `skills/project/agents/init-agent.md`) has "; commands installed" removed from the Claude Config row
- [ ] `skills/project/reference/context7-usage.md` updated with skill-relative agent locations
- [ ] `skills/implement/SKILL.md` Reference Documents table paths updated from `../../agents/*.md` to `agents/*.md`
- [ ] `CLAUDE.md`, `CONTEXT.md`, `ARCHITECTURE.md`, `docs/project/architecture.md`, `docs/project/tech-stack.md` updated to reflect new structure
- [ ] `skills-lock.json` regenerated with correct hashes after structural change
- [ ] Fresh `npx skills add --skill '*'` install in a test project includes agent files under `.claude/skills/<name>/agents/`
- [ ] `/project --init` executes successfully in a freshly installed test project (no file-not-found or "no such subagent type" errors)
- [ ] PR description includes migration note for existing users to re-run `npx skills add`
