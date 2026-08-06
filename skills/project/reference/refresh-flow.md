# Auto-Refresh Mechanism

How documentation stays in sync with code changes. Referenced by the refresh-agent and the SKILL.md orchestrator.

---

## Two-Layer Refresh System

Documentation freshness is maintained by two independent layers that work together:

| Layer | Trigger | What it does |
|---|---|---|
| **Layer 1: PostToolUse Hook** | Every `Edit` or `Write` during a Claude session | Reminds Claude to update relevant docs |
| **Layer 2: Pre-commit Hook** | Every `git commit` | Stages already-refreshed docs into the commit |

Neither layer alone is sufficient. Layer 1 keeps docs fresh; Layer 2 ensures they ship with the code.

---

## Layer 1: PostToolUse Hook (Targeted Refresh Hint)

After every `Edit` or `Write` operation, a PostToolUse hook runs the
targeted refresh-hint script (`.fullstack-dev/refresh-hint.sh`, defined
in `init-flow.md` §9.7a):

```
sh .fullstack-dev/refresh-hint.sh
```

The script reads the changed file path from PostToolUse JSON on stdin,
matches it against the Smart Refresh Rules (§ below), and outputs a
**targeted reminder** naming the specific doc to update — or nothing if
the file doesn't match any rule. Example output:

```
>> You modified src/app/globals.css. Update app.rankme.top/BRAND.md (colors/tokens section) if design tokens changed.
```

This replaces the old bare `echo` approach that listed all 5 doc types
generically regardless of what changed. The targeted approach reduces
noise (no output for non-doc-affecting changes) and gives Claude a
specific, actionable prompt.

**Important:** the script is advisory — Claude reads the hint but is not
obligated to act on it. When Claude is focused on a complex
implementation, it may skip the update. The hint makes skipping a
conscious choice (Claude sees exactly which doc is affected) rather than
an oversight (generic reminder is easy to ignore). For guaranteed
freshness, use `/project --refresh`.

### How it works

1. Hook fires after every `Edit`/`Write` tool call.
2. Script parses `tool_input.file_path` from stdin JSON.
3. Script matches the file against extension/path patterns (see Smart
   Refresh Rules below).
4. If matched: outputs a one-line reminder naming the specific doc.
5. If no match: outputs nothing (silent — no noise).
6. Claude reads the hint and decides whether to update the doc now.

### Layout awareness

The script is layout-agnostic. In mono-repo, per-repo docs resolve to
root (`BRAND.md`, `ARCHITECTURE.md`). In multi-repo, the script detects
the repo from the first path component that has its own `.git/` and
resolves to `<repo>/BRAND.md`, `<repo>/ARCHITECTURE.md`.

### Hook Coexistence

Two PostToolUse hooks fire during Claude sessions in managed projects:

1. **Fullstack-dev doc-refresh hook** — matcher `Edit|Write`, runs the
   targeted refresh-hint script (instant, ~1s)
2. **code-review-graph update hook** — matcher `Edit|Write|Bash|PowerShell`,
   runs `uvx code-review-graph update --skip-flows --repo .` (30s timeout)

Both fire on `Edit`/`Write` operations — this is intentional. The
refresh-hint script is instant, and the graph update runs in parallel.
Neither hook depends on or interferes with the other.

Health checks for both hooks are defined in `init-flow.md` §10.2
(doc-refresh under Claude Config, code-review-graph under MCP).

---

## Layer 2: Pre-commit Hook (Staging)

The pre-commit hook is generated inline by the init-agent (see `init-flow.md` §9.8) and written directly to `.git/hooks/pre-commit` during project init. Its only job is to stage already-refreshed doc files into the current commit.

### What it stages

Root-level docs and managed config:

- `CONTEXT.md`
- `docs/project/architecture.md`
- `docs/project/tech-stack.md`
- `.code-review-graphignore`

Plus, per repo (via glob):

- `*/ARCHITECTURE.md`
- `*/BRAND.md` (only present in repos whose `type` is `frontend`/`fullstack`)
- `*/.code-review-graphignore`

**Not staged:** `CLAUDE.md` — it is user-owned and never auto-refreshed
(see `doc-templates.md` §6). Staging a file that never changes is
misleading.

### Multi-repo: per-repo hooks (§9.8a)

In multi-repo projects, per-repo docs live inside sub-repos with their
own `.git/`. The root hook cannot `git add` across `.git/` boundaries.
Each sub-repo gets its own lightweight pre-commit hook (installed during
init, verified during health checks) that stages only that repo's own
`ARCHITECTURE.md`, `BRAND.md`, and `.code-review-graphignore`.

### Behavior

- Checks if any of the files above have been modified (`git diff` check).
- If modified, runs `git add` on them so they are included in the current commit.
- Runs silently — no output on success.
- Does **NOT** perform any refresh logic. It only stages what was already updated by Layer 1 or a manual refresh.

---

## Smart Refresh Rules

When a file changes, only the relevant docs are refreshed. The refresh-agent uses this mapping to decide what to update:

```
File changed                    -> Docs refreshed
--------------------------------------------------------------------------------
*.css, *.scss, *.tsx,           -> <repo>/BRAND.md (the BRAND.md inside the
  tailwind.config.*                same repo the change happened in)

*.ts, *.js (routes,             -> docs/project/architecture.md
  controllers, steps)              + per-repo ARCHITECTURE.md

package.json, *config.*         -> docs/project/tech-stack.md

schema/models, *.model.*        -> CONTEXT.md (domain model)

New .git/ directory found       -> .gitignore
                                   + docs/project/architecture.md
                                   + .fullstack-dev/config.json
                                   + *.code-workspace
```

If a change does not match any row, no docs are refreshed.

---

## Manual Refresh (`/project --refresh`)

Forces a full refresh of all docs across all repos. Use when:

- You want to force-update everything to current state.
- After major refactoring that touched many files.
- After pulling latest changes from team members.
- Docs feel stale or out of sync.

The manual refresh uses the scanner-agent approach but **updates existing docs** rather than generating from scratch. It preserves manual edits and structure while updating facts and catalogs.

---

## Incremental vs Full Refresh

### Incremental (PostToolUse trigger)

- Triggered automatically after every file edit/write.
- Only updates docs relevant to the changed files (see mapping table above).
- Surgical — does not rewrite entire documents for a single change.
- Touches only the specific sections within a doc that are affected.
- This is the normal mode during development.

### Full (`/project --refresh`)

- Triggered manually by the user.
- Scans all repos in the workspace.
- Regenerates all docs end-to-end.
- Preserves document structure but updates all content.

---

## How the Layers Work Together

### During a Claude session

```
1. Developer edits code
2. PostToolUse hook fires -> echoes reminder
3. Claude (refresh-agent) analyzes the change
4. Claude updates the relevant docs
5. Developer commits
6. Pre-commit hook stages the updated docs into the commit
7. Commit includes both code changes and fresh docs
```

### Manual commits outside Claude

```
1. Developer commits outside a Claude session
2. Pre-commit hook stages any previously-refreshed docs
3. If docs are stale (no Claude session updated them), they remain stale
4. On next Claude session, `/project --refresh` catches everything up
```

### Key principle

The pre-commit hook never refreshes docs — it only stages them. All intelligence lives in the refresh-agent (Claude), not in scripts.
