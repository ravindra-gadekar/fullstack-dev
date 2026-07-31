# Code-Review-Graph Always-On with Smart Scoping — Design Spec

**Created:** 2026-07-31T15:30:00
**Status:** Draft
**Author:** AI + Ravindra Gadekar

## Overview

Promote `code-review-graph` from an optional developer tool (boolean opt-in during init) to a standard, always-on MCP server — configured automatically alongside `context7` and the git-platform MCP during `/project --init`. Additionally, generate a `.code-review-graphignore` file with marker blocks, derived from the project's tech stack, so the graph indexes only relevant source code.

This change aligns code-review-graph's treatment with the plugin's core value proposition: "AI reads your codebase better." A structural knowledge graph is core to that, not optional.

**Verified:** code-review-graph auto-discovers `.code-review-graphignore` at the repo root (same syntax as `.gitignore`). No CLI flag needed — the MCP args `["code-review-graph", "mcp", "--repo", "."]` remain unchanged. Source: upstream README and docs/USAGE.md.

## Architecture

### Layer 1: Init Flow (first run)

Merge current Section 9.5 (context7 + git platform) and Section 9.6 (optional tools) into a single **"Section 9.5: MCP Setup"** phase:

- **context7** — always configured (unchanged).
- **Git platform MCP** — auto-detected from remotes (unchanged).
- **code-review-graph** — always configured (NEW: promoted from optional).
  - Adds `.mcp.json` entry, `PostToolUse` + `SessionStart` hooks, and generates `.code-review-graphignore`.
- **Section 9.6** shrinks to **"Optional Tools"** covering only Agentation (frontend projects only).

The `optionalTools.codeReviewGraph` boolean is removed from `config.json`. code-review-graph's presence in `.mcp.json` is the source of truth (same as context7). `optionalTools.agentation` stays as-is.

### Layer 2: Health Check (subsequent runs)

Move the existing code-review-graph rows from the `Developer Tools` category in Section 10.2 into the `MCP` category (they are no longer optional). Add new `.code-review-graphignore` rows alongside them. The `Developer Tools` category retains only the Agentation row.

Updated MCP health-check rows (Section 10.2):

| Category | Check | Auto-fix? |
|----------|-------|-----------|
| MCP | code-review-graph entry in `.mcp.json` | Yes (add entry) |
| MCP | code-review-graph PostToolUse hook in `settings.json` | Yes (merge hook) |
| MCP | code-review-graph SessionStart hook in `settings.json` | Yes (merge hook) |
| MCP | `.code-review-graphignore` exists with marker block | Yes (generate) |
| MCP | `.code-review-graphignore` patterns match current tech stack | Yes (regenerate marker block) |
| Developer Tools | Agentation in `.mcp.json` (if frontend) | Yes (add entry) |

Update `refresh-flow.md` Layer 1 to document the code-review-graph PostToolUse hook (`Edit|Write|Bash|PowerShell` matcher, graph update) coexisting alongside the doc-staging PostToolUse hook (`Edit|Write` matcher, echo reminder). This is a documentation update — refresh-flow.md describes the refresh mechanism, not health checks. Health checks remain in init-flow.md Section 10.2.

### Layer 3: Reference Docs

- `tools-setup.md` — add "`.code-review-graphignore` Configuration" section.
- `doc-templates.md` Section 7 — remove `optionalTools.codeReviewGraph`, add `.code-review-graphignore` to generated-files list.
- `init-flow.md` — restructure Sections 9.5/9.6.

### Boundaries

- The init-agent generates the ignore file but does NOT run `uvx code-review-graph build` or trigger initial indexing. Indexing happens naturally when the MCP server starts in the next Claude Code session.
- The plugin writes project-level files only. No global/user-level config is touched.
- Downstream skills (`/brainstorm`, `/plan`, `/refactor`) retain their code-review-graph availability checks and filesystem fallback. These serve projects not managed by `/project --init`. No changes to those skills are required.
- Users who want to disable code-review-graph post-init can remove its `.mcp.json` entry and hooks manually. The health check will re-add them on next `/project --init` run. To permanently suppress, the user should also remove the `.code-review-graphignore` file — the health check treats its absence as a FAIL and regenerates it.

## Data Flow

### First-run flow

```text
/project --init
  │
  ├─ Wizard Steps 1-6 (unchanged)
  │
  ├─ Section 9.2: .gitignore generation
  │   └─ Populates gitIgnore.activeCategories in config.json
  │
  ├─ Section 9.5: MCP Setup (unified)
  │   ├─ context7 → merge into .mcp.json (unchanged)
  │   ├─ Git platform → merge into .mcp.json (unchanged)
  │   │   └─ Secret Prompt & Write Flow (unchanged)
  │   └─ code-review-graph (NEW: always-on)
  │       ├─ Merge into .mcp.json:
  │       │   {"command":"uvx","args":["code-review-graph","mcp","--repo","."]}
  │       ├─ Merge hooks into .claude/settings.json:
  │       │   PostToolUse: uvx code-review-graph update --skip-flows --repo .
  │       │   SessionStart: uvx code-review-graph status --repo .
  │       └─ Generate .code-review-graphignore:
  │           ├─ Read repos[].stack + gitIgnore.activeCategories
  │           ├─ Filter to extras NOT covered by built-in defaults
  │           └─ Write file with marker block
  │
  ├─ Section 9.6: Optional Tools (Agentation only, if frontend)
  │
  └─ Sections 9.7+ (unchanged)
```

### .code-review-graphignore generation logic

code-review-graph has built-in defaults that already exclude: `node_modules/**`, `.git/**`, `__pycache__/**`, `*.pyc`, `.venv/**`, `venv/**`, `dist/**`, `build/**`, `.next/**`, `target/**`, `*.min.js`, `*.min.css`, `*.map`, `*.lock`, `package-lock.json`, `yarn.lock`, `*.db`, `*.sqlite`, `*.db-journal`, `.code-review-graph/**`.

It also auto-respects `.gitignore` in git repos.

The plugin generates only **project-specific extras** not covered by the above:

**Always included (minimal defaults):**

```gitignore
docs/
.fullstack-dev/
```

**Stack-derived extras (added when tech stack matches):**

| Stack signal | Signal source | Extra patterns |
|--------------|---------------|----------------|
| `node` or `typescript` | `repos[].stack` contains `"node"` or `"typescript"` | `coverage/`, `.nyc_output/` |
| `nextjs` | `repos[].stack` contains `"next.js"` | `storybook-static/` |
| `astro` | `repos[].stack` contains `"astro"` | `.astro/` |
| `python` | `repos[].stack` contains `"python"` | `.mypy_cache/`, `.pytest_cache/`, `.ruff_cache/`, `htmlcov/` |
| `iiidev` | `repos[].stack` contains `"iii.dev"` or `"motia"` | `.motia/`, `data/` |
| `frontend` (any) | `hasFrontend == true` | `storybook-static/`, `.storybook/` |
| Infrastructure | File-presence: `*.tf` or `docker-compose*` in repo | `.terraform/`, `terraform.tfstate*` |

This mapping lives in `tools-setup.md` and is independently maintained from the gitignore catalog (the two serve different purposes — gitignore excludes from git, this excludes from graph indexing).

### Subsequent-run flow (health check)

```text
/project --init (config exists)
  │
  ├─ Health Check Table
  │   ├─ Existing MCP checks (unchanged)
  │   ├─ code-review-graph checks (NEW):
  │   │   ✓ .mcp.json entry present
  │   │   ✓ PostToolUse hook present
  │   │   ✓ SessionStart hook present
  │   │   ✓ .code-review-graphignore exists with marker block
  │   │   ✓ Marker block patterns match current tech stack
  │   └─ Auto-fix for any FAIL → regenerate missing pieces
  │
  └─ refresh-flow.md Layer 1 updated to document hook coexistence
```

**Data dependency:** `.code-review-graphignore` generation runs AFTER `.gitignore` generation (Section 9.2) because it reads `gitIgnore.activeCategories`. This ordering is already natural in the init flow.

## File Changes

| File | Action | What changes |
|------|--------|--------------|
| `skills/project/reference/init-flow.md` | Edit | Restructure §9.5 (unified MCP setup); shrink §9.6 (Agentation only); remove `optionalTools.codeReviewGraph` from §9.1 schema; add `.code-review-graphignore` after `.gitignore` in §9.13 completion report; move code-review-graph rows from `Developer Tools` to `MCP` category in §10.2; add `.code-review-graphignore` rows to §10.2; `Developer Tools` category retains only Agentation; bump config version to `1.1.0` in §12 |
| `skills/project/reference/tools-setup.md` | Edit | Add "`.code-review-graphignore` Configuration" section with marker-block format, minimal defaults, stack-derived extras, and merge rules |
| `skills/project/reference/refresh-flow.md` | Edit | Add paragraph to Layer 1 documenting the code-review-graph PostToolUse hook coexisting alongside the doc-staging echo hook (documentation update, not health checks — health checks remain in init-flow.md §10.2) |
| `skills/project/reference/doc-templates.md` | Edit | Add `optionalTools.agentation` (boolean) to config schema Field Reference table (was previously missing); do NOT add `codeReviewGraph` (removed); add `.code-review-graphignore` to generated-files list |
| `agents/init-agent.md` | Edit | Remove code-review-graph opt-in prompt; add always-on MCP setup + `.code-review-graphignore` generation step; update health-check section to match init-flow.md changes (move code-review-graph from Developer Tools to MCP category) |
| `CONTEXT.md` | Edit | Add `fullstack-dev:code-review-graph` to the marker naming convention row (line 56) |
| `docs/project/architecture.md` | Edit | Remove "(optional)" from code-review-graph description |
| `docs/project/tech-stack.md` | Edit | Remove "(optional)" from code-review-graph description |
| `.fullstack-dev/config.json` (this repo) | Edit | Remove `optionalTools.codeReviewGraph` field; `optionalTools` object remains with only `agentation: boolean` |

**New file generated in target projects:**

| File | Format | Ownership |
|------|--------|-----------|
| `.code-review-graphignore` | Gitignore syntax with `fullstack-dev` marker block | Plugin owns marker block; user owns content outside markers |

### Marker block format

```gitignore
# >>> fullstack-dev:code-review-graph (do not edit this block) >>>

# Project metadata
docs/
.fullstack-dev/

# Node/TypeScript (stack-derived)
coverage/
.nyc_output/

# <<< fullstack-dev:code-review-graph <<<

# --- User entries below ---
```

### Multi-repo handling

A single `.code-review-graphignore` is generated at the workspace root. Patterns are the UNION of stack-derived extras across all `repos[].stack` entries. code-review-graph's `--repo .` indexes from the workspace root, so root-relative patterns apply to all sub-repos (e.g., `docs/` matches both root `docs/` and `sub-repo/docs/`). No per-sub-repo ignore files are generated.

### Migration (init-flow.md §12)

- Config version bumps from `1.0.0` to `1.1.0`.
- Migration adds code-review-graph `.mcp.json` entry + hooks + `.code-review-graphignore` to existing projects.
- `optionalTools.codeReviewGraph` is removed from config.json regardless of its prior value. The `optionalTools` object remains with only `agentation: boolean`.
- Projects that previously had `codeReviewGraph: false` get code-review-graph added — intentional, since it's now always-on.
- Completion report notes: "Added code-review-graph (now standard)."

## Error Handling

### uvx not installed

Init generates all code-review-graph files regardless. No pre-check for `uvx`. When Claude Code starts, if `uvx` is missing, the MCP server simply doesn't connect. The existing health-check row "claude mcp list reports no connectivity warnings" covers this (report only, no auto-fix). The user sees a clear MCP connection error.

### .code-review-graphignore generation failures

- If `gitIgnore.activeCategories` is empty or missing, fall back to hardcoded minimal defaults: `docs/`, `.fullstack-dev/`.
- If `.code-review-graphignore` exists with a marker block, replace marker block content only.
- If the file exists without a marker block, prepend marker block and preserve existing user content.
- Identical merge semantics to `.gitignore`.

### Migration edge cases

- **Had `codeReviewGraph: true`:** `.code-review-graphignore` is added. `.mcp.json` entry and hooks already present — health check confirms, no double-write.
- **Had `codeReviewGraph: false`:** Everything is added. Intentional — tool is now always-on.
- **Hand-edited `.code-review-graphignore` without markers:** Marker block is prepended, hand-written patterns survive below.

### Hooks merge conflict

- If `PostToolUse` hook with matcher `Edit|Write|Bash|PowerShell` already exists, skip (already present).
- If only the fullstack-dev echo hook (`Edit|Write`) exists, add code-review-graph as a second `PostToolUse` entry. Both coexist per the existing "Hooks Merge Note" in tools-setup.md.

## Testing Strategy

Verification through dogfooding (exercising commands in a Claude Code session).

### First-run verification

- Run `/project --init` on a fresh directory. Confirm:
  - `.mcp.json` has `context7`, git-platform, and `code-review-graph` entries
  - `.claude/settings.json` has fullstack-dev echo hook, code-review-graph PostToolUse hook, code-review-graph SessionStart hook
  - `.code-review-graphignore` exists with marker block and project-specific extras
  - No `optionalTools.codeReviewGraph` in config.json
  - Agentation prompt appears for frontend projects only
  - Completion report lists `.code-review-graphignore`

### Health-check verification

- Delete `.code-review-graphignore` → re-run init → confirm regenerated
- Remove `code-review-graph` from `.mcp.json` → re-run init → confirm restored
- Remove hooks from `.claude/settings.json` → re-run init → confirm re-merged

### Migration verification

- Config with `optionalTools.codeReviewGraph: false` → run init → confirm everything added, boolean removed, report says "Added code-review-graph (now standard)"
- Config with `optionalTools.codeReviewGraph: true` → run init → confirm `.code-review-graphignore` added without duplicating existing `.mcp.json`/hooks

### Merge-safety verification

- `.code-review-graphignore` with no marker block → init → confirm marker block prepended, user patterns survive
- `.code-review-graphignore` with marker block + user patterns → init → confirm only marker block replaced

### Stack-derived scoping verification

- Node.js + React project → confirm `coverage/`, `storybook-static/` in ignore file
- Python project → confirm `.mypy_cache/`, `.pytest_cache/` in ignore file
- Bare CLI project → confirm only `docs/`, `.fullstack-dev/` (minimal defaults)
