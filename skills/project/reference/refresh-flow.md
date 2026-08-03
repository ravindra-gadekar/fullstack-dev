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

## Layer 1: PostToolUse Hook (Primary Refresh)

After every `Edit` or `Write` operation, a PostToolUse hook fires:

```
echo 'FULLSTACK_DEV: Files changed. Update relevant docs (architecture, brand, tech-stack) if needed.'
```

This is a **simple echo reminder** — it does not run a script or programmatically regenerate anything. The actual analysis and doc-writing is performed by Claude using the refresh-agent logic:

1. Hook echoes the reminder after a file write/edit.
2. Claude (as the refresh-agent) reads the reminder.
3. Claude analyzes which files changed and determines which docs are affected.
4. Claude updates the relevant docs surgically — only the sections that need it.

This is the primary mechanism that keeps docs current during active development sessions.

### Hook Coexistence

Two PostToolUse hooks fire during Claude sessions in managed projects:

1. **Fullstack-dev doc-staging hook** — matcher `Edit|Write`, echoes a reminder to update docs (instant, ~1s timeout)
2. **code-review-graph update hook** — matcher `Edit|Write|Bash|PowerShell`, runs `uvx code-review-graph update --skip-flows --repo .` to keep the graph current (30s timeout)

The code-review-graph hook has a broader matcher (includes `Bash` and `PowerShell`). Both fire on `Edit`/`Write` operations — this is intentional. The echo hook is instant, and the graph update runs in parallel. Neither hook depends on or interferes with the other.

This coexistence is a documentation note for the refresh mechanism. Health checks for both hooks are defined in `init-flow.md` §10.2 (doc-staging under Claude Config, code-review-graph under MCP).

---

## Layer 2: Pre-commit Hook (Staging)

The pre-commit hook is generated inline by the init-agent (see `init-flow.md` §9.8) and written directly to `.git/hooks/pre-commit` during project init. Its only job is to stage already-refreshed doc files into the current commit.

### What it stages

These 3 root-level docs:

- `CONTEXT.md`
- `docs/project/architecture.md`
- `docs/project/tech-stack.md`

Plus, per repo:

- `*/ARCHITECTURE.md`
- `*/BRAND.md` (only present in repos whose `type` is `frontend`/`fullstack`)

Per-repo `ARCHITECTURE.md` and `BRAND.md` files are committed in their own repos, not staged by this hook.

`.code-review-graphignore` is a managed config file (root, plus one per repo in multi-repo projects) and should be auto-staged on commit the same way — if the init-agent health check regenerates it (e.g. stack drift), the refreshed file should be staged alongside the other managed docs so it ships with the commit that triggered the regeneration, not left dangling as an unstaged change.

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
