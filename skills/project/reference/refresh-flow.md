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

## Layer 2: Pre-commit Hook (Auto-stage + Doc-freshness Gate)

The pre-commit hook (see `init-flow.md` §9.8) is the **primary
enforcement mechanism** for doc freshness. It does two things at commit
time:

### Part 1: Auto-stage already-refreshed docs

If docs were updated during the session (by Claude following a Layer 1
hint or via `/project --refresh`), the hook auto-stages them so they
ship with the code commit.

Root-level docs and managed config:

- `CONTEXT.md`
- `docs/project/architecture.md`
- `docs/project/tech-stack.md`
- `ARCHITECTURE.md`, `BRAND.md` (mono-repo)
- `.code-review-graphignore`

Plus, per directory (mono-repo only — sub-repo paths are skipped):

- `*/ARCHITECTURE.md`
- `*/BRAND.md`
- `*/.code-review-graphignore`

**Not staged:** `CLAUDE.md` — it is user-owned and never auto-refreshed.

### Part 2: Doc-freshness gate

After auto-staging, the hook checks if staged code changes affect docs
that were **not** updated. If so, it blocks the commit with a targeted
message listing exactly which docs need refreshing.

| Staged code pattern | Doc that must also be staged |
|---|---|
| `*.css`, `*.scss`, `*.tsx`, `tailwind.config.*` | `BRAND.md` |
| New/deleted `*.ts`, `*.js` files | `docs/project/architecture.md`, `ARCHITECTURE.md` |
| `package.json`, `*.config.(ts\|js\|mjs\|cjs)` | `docs/project/tech-stack.md` |
| `schema/*`, `*.model.*` | `CONTEXT.md` |

**How it works in a Claude session:**

1. Claude commits code changes.
2. Pre-commit hook auto-stages any already-refreshed docs (Part 1).
3. Hook checks remaining staged code against the rules above (Part 2).
4. If docs are missing → hook exits 1 with a targeted message.
5. Claude reads the message, refreshes the listed docs, stages them.
6. Claude retries the commit → hook passes → commit succeeds with
   fresh docs.

**Outside Claude sessions:**

The developer sees the failure message and updates docs manually or
runs `/project --refresh` before committing again.

### Multi-repo: per-repo hooks (§9.8a)

In multi-repo projects, per-repo docs live inside sub-repos with their
own `.git/`. The root hook skips sub-repo paths (detected by checking
for `<dir>/.git/`). Each sub-repo gets its own hook with the same
two-part logic (auto-stage + gate) for that repo's own
`ARCHITECTURE.md`, `BRAND.md`, and `.code-review-graphignore`.

### JS/TS false-positive mitigation

The gate only triggers for **new or deleted** `.ts`/`.js` files
(`git diff --diff-filter=AD`), not modifications. A simple bugfix in a
`.ts` file does not require an architecture doc update. CSS/design,
dependency, and schema changes trigger on all modifications since those
are more likely to affect their corresponding docs.

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
