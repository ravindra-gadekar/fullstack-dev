# /implement Flow Reference

Detailed flow documentation for the `/implement` command orchestrator.
This file is read by the orchestrator (SKILL.md) for decision trees,
detection logic, prompt templates, and processing rules.

---

## Table of Contents

1. [Auto-Init Guard](#1-auto-init-guard)
2. [Plan Resolution](#2-plan-resolution)
3. [Plan Loading & Resume Detection](#3-plan-loading--resume-detection)
4. [Context Loading](#4-context-loading)
5. [Phase Loop](#5-phase-loop)
6. [Pre-Task Research](#6-pre-task-research)
7. [Implementer Dispatch & Post-Verification](#7-implementer-dispatch--post-verification)
8. [Smoke Test Detection & Execution](#8-smoke-test-detection--execution)
9. [Auto-Fix Escalation Ladder](#9-auto-fix-escalation-ladder)
10. [Task Review](#10-task-review)
11. [Security Review & Trigger Detection](#11-security-review--trigger-detection)
12. [Task Completion & Checkpointing](#12-task-completion--checkpointing)
13. [Final Audit](#13-final-audit)
14. [Branch Finishing & Completion](#14-branch-finishing--completion)
15. [Prompt Templates](#15-prompt-templates)
16. [Error Recovery Matrix](#16-error-recovery-matrix)

---

## 1. Auto-Init Guard

**Purpose:** Verify project is initialized and git state is clean before execution.

### Decision Tree

```
.fullstack-dev/config.json exists?
+-- NO  -> "Cannot implement without project config. Run /project --init first." -> EXIT
+-- YES -> load config, continue

For each repo in config.repos:
  repo directory exists?
  +-- NO  -> "Repo directory <path> not found." -> EXIT
  +-- YES -> check git state

  Git workflow guard (Reference -> skills/git/SKILL.md, Guard section):
  +-- Verifies local-dev branch
  +-- Universal stash (guard handles all stash/pop)
  +-- Not a git repo -> "Repo <name> is not a git repository." -> EXIT
```

### Behavior by Mode

| Condition | `--auto` | Interactive |
|-----------|----------|-------------|
| Config missing | Exit with error | Exit with error |
| Repo dir missing | Exit with error | Exit with error |
| Uncommitted changes | Guard auto-stashes | Guard auto-stashes |
| Not a git repo | Exit with error | Exit with error |
| Clean state | Continue | Continue |

---

## 2. Plan Resolution

**Purpose:** Resolve the plan path from argument or let user pick.

### Decision Tree

```
plan-path argument provided?
+-- YES -> is it a directory path?
|   +-- YES -> validate: folder exists AND has README.md AND has at least one phase-N.md
|   |   +-- Valid   -> load plan from this directory
|   |   +-- Invalid -> "Plan not found or incomplete at <path>. Needs README.md and phase-N.md files."
|   +-- NO -> is it a file path (phase-N.md)?
|       +-- YES -> extract directory, validate same as above, set starting phase
|       +-- NO  -> "Invalid plan path: <path>"
+-- NO  -> scan docs/plans/ for all subdirectories containing README.md
    +-- 0 found -> "No plans found. Create one with /plan first."
    +-- 1 found ->
    |   +-- --auto       -> use it automatically
    |   +-- interactive  -> "Found plan: <name>. Use it? (Y/n)"
    +-- N found -> show numbered picker:
        "Multiple plans found:
         1. <name-1> (progress: X%)
         2. <name-2> (progress: Y%)
         ...
         Select a plan:"
        Use AskUserQuestion with plan options
```

### Progress Percentage Calculation (for picker)

```
Read all phase-N.md files in the plan directory
Count total checkboxes:  lines matching "^- \[" across all phase files
Count checked:           lines matching "^- \[x\]" across all phase files
Progress = (checked / total) * 100, rounded to nearest integer
```

### Behavior by Mode

| Condition | `--auto` | Interactive |
|-----------|----------|-------------|
| Path provided, valid | Load plan | Load plan |
| Path provided, invalid | Exit with error | Exit with error |
| No path, 0 plans | Exit with error | Exit with error |
| No path, 1 plan | Auto-select | Confirm with user |
| No path, N plans | Not supported (exit with error) | Show numbered picker |

---

## 3. Plan Loading & Resume Detection

**Purpose:** Load the plan, detect existing progress, find resume point.

### Decision Tree

```
Read README.md -> extract:
  - Goal (from **Goal:** field)
  - Phases table
  - Spec path (from **Spec:** field)

Scan all phase-N.md files -> count checkboxes:
  Total steps: X   (count all "- [ ]" and "- [x]" and "- [B]" lines)
  Checked steps: Y  (count "- [x]" lines)
  Blocked steps: Z  (count "- [B]" lines)

+-- Y == X -> "This plan is already fully implemented. Nothing to do."
|   +-- Z > 0 -> "Note: Z tasks were blocked. Review them manually."
|   -> EXIT
+-- Y > 0  -> partial progress detected
|   Progress: Y/X = P%
|   Find first unchecked task:
|     Scan phase files in order (phase-1.md, phase-2.md, ...)
|     In each file, find first "### Task N:" heading where
|     any step below it is "- [ ]" (not "- [x]" or "- [B]")
|   Resume point: Phase P, Task T
|   +-- --auto       -> auto-resume from Phase P, Task T
|   +-- interactive  -> "Plan is P% complete (Y/X tasks).
|       Resume from Phase P, Task T: <task-title>?"
|       +-- Yes -> resume
|       +-- No  -> "Aborting. Re-run /implement to try again."
+-- Y == 0 -> fresh start
    +-- --auto       -> auto-start Phase 1
    +-- interactive  -> "Start implementing Phase 1: <phase-name>? (X total tasks)"
        +-- Yes -> start
        +-- No  -> "Aborting."
```

### Resume Granularity Rules

- Resume operates at the **task level**, not the step level
- If any step within a task is unchecked (`- [ ]`), the entire task is re-dispatched
- The implementer receives the full task brief and re-implements from scratch
- Steps within a task are the implementer's internal checklist
- After the implementer completes, ALL steps in the task are marked `- [x]`

### Behavior by Mode

| Condition | `--auto` | Interactive |
|-----------|----------|-------------|
| Fully complete | Exit | Exit |
| Partial progress | Auto-resume from first unchecked task | Confirm resume point |
| Fresh start | Auto-start Phase 1 | Confirm start |

---

## 4. Context Loading

**Purpose:** Load project-wide context that all tasks need.

### Parallel Research Agents

Dispatch 3 parallel research agents (always — not gated by any flag):

| # | Agent Task | Reads | Returns |
|---|-----------|-------|---------|
| 1 | Architecture context | `CONTEXT.md`, per-repo `ARCHITECTURE.md`, per-repo `BRAND.md` (if they exist) | Domain model, architecture patterns, naming conventions |
| 2 | Project config | `.fullstack-dev/config.json` | Repo list, paths, tech stack, available commands |
| 3 | Recent changes | `git log --oneline -10` per repo | Recent commit summaries for awareness |

### Merge Strategy

Merge results into a **project context object** (plain text) passed to all subsequent agents.

The project context object contains:
- Domain model and terminology from CONTEXT.md
- Architecture patterns and conventions from ARCHITECTURE.md files
- Brand guidelines from BRAND.md files (when doing UI work)
- Repo paths, tech stack, and available commands from config
- Recent commit history for change awareness

This context is loaded once at the start and reused for every task dispatch.

---

## 5. Phase Loop

**Purpose:** Iterate through phases in order, executing tasks within each.

### Decision Tree

```
For each phase file (phase-1.md, phase-2.md, ...) in numeric order:
  Read phase file
  Count tasks: total, completed (all steps [x]), blocked ([B]), pending

  +-- All tasks completed -> skip this phase, move to next
  +-- Has pending tasks ->
      Show: "Phase P: <name> -- T tasks remaining (C completed, B blocked)"
      +-- --auto       -> proceed
      +-- interactive  -> "Start Phase P? (Y/n)"
          +-- Yes -> proceed
          +-- No  -> "Pausing. Re-run /implement to continue."

      Execute task loop (Steps 5-9 in SKILL.md) for each pending task

      After all tasks in this phase:
      +-- All complete (- [x]) -> run phase-level smoke test
      |   +-- Pass -> log "Phase P complete"
      |   +-- Fail -> enter auto-fix (same as Step 7a)
      +-- All remaining blocked (- [B]) ->
      |   Log: "Phase P blocked -- B tasks blocked, C completed"
      |   +-- --auto       -> continue to next phase
      |   +-- interactive  -> AskUserQuestion:
      |       (a) Continue to next phase
      |       (b) Retry blocked tasks
      |       (c) Abort
      +-- Mix of complete and blocked -> same as all-blocked handling

  +-- Last phase completed -> proceed to Final Audit (Step 10)
```

### Task Ordering

- Tasks within a phase are executed in the order they appear in the phase file
- A blocked task does not prevent subsequent tasks from executing
- Dependencies between tasks are assumed to be captured by phase ordering

### Behavior by Mode

| Condition | `--auto` | Interactive |
|-----------|----------|-------------|
| Phase fully complete | Skip silently | Skip silently |
| Phase has pending tasks | Proceed automatically | Confirm before starting |
| Phase ends with blocked tasks | Continue to next phase | Offer: continue / retry / abort |
| All phases complete | Proceed to Final Audit | Proceed to Final Audit |

---

## 6. Pre-Task Research

**Purpose:** Gather context about the specific files a task will touch.

### Parallel Research Agents

Dispatch 3 parallel research agents per task (always — pre-task research is always-on):

| # | Agent Task | Reads | Returns |
|---|-----------|-------|---------|
| A | Source files | Files listed in the task's **Files:** section (Create/Modify entries) — read current content | Current state of target files, or "file does not exist" for Create entries |
| B | Existing tests | Test files listed in the task's **Files:** section, plus any test files in the same directories | What tests already exist for these modules |
| C | Dependencies | Imports/exports of target files, package.json dependencies, consumers (files that import from target files) | What depends on these files, what these files depend on |

### Merge Strategy

Merge results into a **task context object** (plain text) passed to the implementer.

The task context includes:
- Current content of all files the task will create or modify
- Existing test coverage for the affected modules
- Dependency graph: what imports from and what is imported by target files
- Interface context from previously completed tasks (see below)

### Interface Context Accumulation

```
For each previously completed task (all steps "- [x]") in earlier phases
and the current phase:
  Extract the **Produces** section from the task brief
  Append to interface context

Pass accumulated interface context to the implementer so it knows
what types/functions are available from earlier tasks.
```

This ensures later tasks can reference types, functions, and interfaces
created by earlier tasks without re-reading the entire codebase.

### What the Implementer Receives

The implementer agent is dispatched with:
1. **Project context** (from Section 4 — shared across all tasks)
2. **Task context** (from this section — specific to this task)
3. **Task brief** (the raw task content from the phase file)
4. **Interface context** (accumulated Produces from completed tasks)

---

## 7. Implementer Dispatch & Post-Verification

**Purpose:** Dispatch the implementer agent and verify its work.

### Implementer Dispatch

```
Record pre-task commit: git rev-parse HEAD → $PRE_TASK_COMMIT

Dispatch implementer-agent with:
  - Task brief (full text from ### Task N heading to next ### Task or end of file)
  - Project context (from Step 3 / Section 4)
  - Pre-task research (from Step 5 / Section 6)
  - Interface context (accumulated Produces from completed tasks)
  - Mode: normal

Implementer returns status:
+-- DONE → proceed to post-verification
+-- DONE_WITH_CONCERNS:<description>
|   Assess concern:
|   +-- Correctness/scope concern → address before post-verification
|   +-- Observational concern → note in log, proceed to post-verification
+-- NEEDS_CONTEXT:<what>
|   +-- Re-dispatch count < 2 → provide missing context, re-dispatch implementer
|   +-- Re-dispatch count >= 2 → escalate to user:
|       "Implementer needs context after 2 attempts: <what>"
|       AskUserQuestion:
|       (a) Provide context (text input) → re-dispatch with user's context
|       (b) Skip this task → mark [B], move to next
|       (c) Abort → stop execution
+-- BLOCKED:<reason>
    Assess:
    +-- Can provide more context? → provide, re-dispatch once
    +-- Can break task smaller? → suggest to user, mark [B]
    +-- Otherwise → escalate to user with reason + recommendations
```

### Post-Implementer Verification

```
After DONE or DONE_WITH_CONCERNS:

1. Commit check:
   git rev-parse HEAD → $POST_TASK_COMMIT
   +-- $POST_TASK_COMMIT != $PRE_TASK_COMMIT → new commit exists → continue
   +-- $POST_TASK_COMMIT == $PRE_TASK_COMMIT → no commit
       Treat as BLOCKED: "Implementer completed but failed to commit"

2. File scope check:
   git diff --name-only $PRE_TASK_COMMIT..HEAD → $MODIFIED_FILES
   Compare $MODIFIED_FILES against task's declared Files section
   +-- Only declared files (+ test files) modified → continue
   +-- Unexpected files modified →
       +-- --auto → log warning: "Unexpected files modified: <list>"
       +-- interactive → "Implementer modified unexpected files: <list>
           (a) Accept and continue
           (b) Revert unexpected changes
           (c) Abort"
```

### Behavior by Mode

| Condition | `--auto` | Interactive |
|-----------|----------|-------------|
| DONE | Proceed to smoke tests | Proceed to smoke tests |
| DONE_WITH_CONCERNS | Assess and proceed or fix | Assess and proceed or fix |
| NEEDS_CONTEXT (< 2 retries) | Re-dispatch with context | Re-dispatch with context |
| NEEDS_CONTEXT (>= 2 retries) | Escalate to user | Escalate to user |
| BLOCKED | Assess and escalate | Assess and escalate |
| No commit after DONE | Treat as BLOCKED | Treat as BLOCKED |
| Unexpected files modified | Log warning, continue | Prompt user for action |

---

## 8. Smoke Test Detection & Execution

**Purpose:** Auto-detect and run verification commands for each modified repo.

### Package Manager Detection (for JS/TS repos)

```
In repo directory:
+-- pnpm-lock.yaml exists → PM=pnpm, PMX="pnpm exec"
+-- yarn.lock exists      → PM=yarn,  PMX="yarn exec"
+-- bun.lockb exists      → PM=bun,   PMX=bunx
+-- Otherwise             → PM=npm,   PMX=npx
```

### Command Detection (per repo)

```
Read package.json (or equivalent for non-JS):

Typecheck:
+-- package.json has "typecheck" in scripts → $PM run typecheck
+-- devDependencies has "typescript"        → $PMX tsc --noEmit
+-- pyproject.toml has "mypy" dep           → mypy .
+-- pyproject.toml has "pyright" dep        → pyright
+-- Otherwise                               → null (skip)

Build:
+-- package.json has "build" in scripts     → $PM run build
+-- Cargo.toml exists                       → cargo build
+-- go.mod exists                           → go build ./...
+-- Otherwise                               → null (skip)

Test:
+-- package.json has "test" in scripts      → $PM test
+-- devDependencies has "vitest"            → $PMX vitest run
+-- devDependencies has "jest"              → $PMX jest
+-- pyproject.toml has "pytest" dep         → pytest
+-- Cargo.toml exists                       → cargo test
+-- go.mod exists                           → go test ./...
+-- Otherwise                               → null (skip)

Lint:
+-- package.json has "lint" in scripts      → $PM run lint
+-- devDependencies has "eslint"            → $PMX eslint .
+-- pyproject.toml has "ruff" dep           → ruff check .
+-- Otherwise                               → null (skip)
```

### Execution

```
Identify repos modified by this task (from task's Files section paths)

For each modified repo:
  Detect package manager (if JS/TS)
  Detect available commands

  Run in order (stop on first failure):
  1. Typecheck (if available) → capture stdout+stderr, timeout 120s
  2. Build (if available)     → capture stdout+stderr, timeout 300s
  3. Test suite (if available) → capture stdout+stderr, timeout 300s
  4. Lint (if available)      → capture stdout+stderr, timeout 120s

  +-- ALL PASS → proceed to Task Review (Step 8)
  +-- ANY FAIL → record which command failed + output → Auto-Fix (Section 9)
  +-- No commands available → log "No verification tools detected for <repo>" → proceed
```

### Behavior by Mode

| Condition | `--auto` | Interactive |
|-----------|----------|-------------|
| All commands pass | Proceed to Task Review | Proceed to Task Review |
| Any command fails | Enter Auto-Fix (Section 9) | Enter Auto-Fix (Section 9) |
| No commands available | Log and proceed | Log and proceed |

---

## 9. Auto-Fix Escalation Ladder

**Purpose:** Fix failing smoke tests with escalating strategies.

### Key Rules

- Never retry without changing strategy (each tier is a different approach)
- Each tier's fix is verified by re-running the exact failing command
- Revert uses `git revert HEAD` or `git reset --soft $PRE_TASK_COMMIT` (NOT `git checkout` on individual files — that clobbers changes from earlier tasks)
- Tier 1 fixes are applied inline by the orchestrator (simple 1-3 line fixes)
- Tier 2 re-dispatches the implementer-agent in fix mode (amend commit)
- After any revert (Tier 3), verify clean state via `git status`

### Decision Tree

```
TIER 1: Quick Fix (max 1 attempt)
  Condition: error message points to obvious cause
  Examples: missing import, typo, wrong file path, simple type mismatch,
            unused variable (lint), missing semicolon

  Action:
    1. Read the error output
    2. Identify the obvious fix (1-3 lines)
    3. Apply the fix using Edit tool
    4. Re-run the exact failing command
    +-- Pass → amend the task commit (git add + git commit --amend)
    |         → proceed to Task Review (Step 8)
    +-- Fail → escalate to Tier 2

TIER 2: Systematic Fix (max 1 attempt)
  Action:
    1. Re-dispatch implementer-agent in FIX MODE with:
       - Error output (full stdout+stderr from failing command)
       - Which command failed (typecheck/build/test/lint)
       - Files the task modified
       - Root cause hypothesis (if any)
    2. Implementer analyzes, fixes, amends previous commit
    3. Implementer returns FIX_APPLIED or FIX_FAILED

    +-- FIX_APPLIED → re-run ALL smoke test commands (not just the failing one)
    |   +-- ALL PASS → proceed to Task Review (Step 8)
    |   +-- ANY FAIL → escalate to Tier 3
    +-- FIX_FAILED → escalate to Tier 3

TIER 3: Revert + Block (terminal)
  Action:
    1. Revert to pre-task state:
       git revert HEAD --no-edit
       OR if multiple commits: git reset --soft $PRE_TASK_COMMIT
    2. Verify clean state: git status
    3. Mark task as blocked in plan file:
       Change all "- [ ]" steps under this task to "- [B]"
       Add blockquote below the task heading:
       > BLOCKED: <error summary>. Tier 1 tried: <what>. Tier 2 tried: <what>.
    4. Surface to user:
       "Task <N> failed all auto-fix attempts.
        Error: <error output summary>
        Tier 1 tried: <what was attempted>
        Tier 2 tried: <what was attempted>"

    AskUserQuestion:
    (a) Retry with guidance → user provides hint text → re-enter Step 6 with hint
    (b) Skip this task → proceed to next task
    (c) Abort → stop execution entirely
```

### Behavior by Mode

| Condition | `--auto` | Interactive |
|-----------|----------|-------------|
| Tier 1 fix succeeds | Proceed to Task Review | Proceed to Task Review |
| Tier 2 fix succeeds | Proceed to Task Review | Proceed to Task Review |
| Tier 3 (all tiers fail) | Revert, mark [B], escalate to user | Revert, mark [B], escalate to user |

### Integration with /fix and /debug

The escalation ladder can optionally dispatch the `/fix` and `/debug` skills:
- **Tier 1** can use `/fix` for targeted fixes when the error message clearly indicates what to change
- **Tier 2** can use `/debug` for systematic investigation when the root cause is unknown

This integration is available but not required — the existing inline fix and
implementer-agent re-dispatch remain the default behavior.

---

## 10. Task Review

**Purpose:** Review the completed task for spec compliance and code quality.

### Decision Tree

```
Dispatch task-reviewer-agent with:
  - Task brief (same text the implementer received)
  - Git diff: git diff $PRE_TASK_COMMIT..HEAD
  - Smoke test results (command outputs from Section 8)

Reviewer returns findings:

+-- "APPROVED — no issues found." → proceed to Security Review (Section 11)
+-- Findings list:
    Categorize by severity:
    +-- Minor findings only →
    |   Log: "Review found N minor issues (not blocking)"
    |   List findings in log
    |   → proceed to Security Review
    +-- Critical or Important findings →
        Fix attempt 1:
          Dispatch implementer-agent with findings as fix instructions
          (normal mode, not fix mode — these are spec/quality issues, not test failures)
          Re-dispatch task-reviewer-agent on the new diff
          +-- APPROVED → proceed to Security Review
          +-- Still has Critical/Important findings →
              Fix attempt 2:
                Same as attempt 1
                +-- APPROVED → proceed
                +-- Still failing → escalate to user:
                    "Reviewer found persistent issues after 2 fix attempts:
                     <findings>"
                    AskUserQuestion:
                    (a) Accept as-is and continue
                    (b) Provide guidance for another fix attempt
                    (c) Abort
```

### Behavior by Mode

| Condition | `--auto` | Interactive |
|-----------|----------|-------------|
| APPROVED | Proceed to Security Review | Proceed to Security Review |
| Minor findings only | Log and proceed | Log and proceed |
| Critical/Important (fix succeeds) | Proceed after fix | Proceed after fix |
| Critical/Important (fix fails 2x) | Escalate to user | Escalate to user |

### Integration with /refactor

When the task reviewer returns `[Code Quality]` dimension findings that indicate
structural issues (god class, long function, tightly coupled modules, DRY violations),
the orchestrator may suggest `/refactor <target>` as a follow-up rather than
re-dispatching the implementer for a generic fix. This is a suggestion to the user,
not an automatic dispatch — structural refactoring should be a deliberate choice.

Relevant finding types for /refactor suggestion:

- Separation of concerns violations → `/refactor <file> -- mixed responsibilities`
- Dead code detected → `/refactor <file> -- remove dead code`
- Overly complex functions → `/refactor <file> -- function too long`
- High coupling → `/refactor <directory> -- tightly coupled`

---

## 11. Security Review & Trigger Detection

**Purpose:** Auto-detect security-sensitive changes and trigger security review.

### Trigger Detection

Applied to the task's modified files:

**Strong triggers** (any ONE match triggers security review):

```
File path patterns:
  **/auth/**
  **/middleware/**
  *.env*
  **/crypto/**
  **/.env*
  **/secrets/**

Keyword patterns (in file content or task brief):
  authentication, authorization, JWT, password, API key,
  secret, encryption, payment, OAuth, session management,
  bcrypt, hash, salt, certificate, private key
```

**Weak triggers** (require BOTH a file path match AND a keyword match):

```
File path patterns:
  **/api/**
  **/routes/**
  **/security/**
  **/controllers/**
  **/handlers/**

Keyword patterns:
  token, session, validation, sanitization, CORS, CSP,
  permissions, roles, billing, webhook, file upload,
  cookie, header, origin, credential
```

### Decision Tree

```
Check task's modified files against trigger patterns:

+-- No triggers matched → skip security review → proceed to Task Completion
+-- Strong trigger matched →
|   Log: "Security-sensitive change detected (strong trigger: <which>)"
|   Dispatch security-reviewer-agent in per-task mode
+-- Weak trigger matched (both file path AND keyword) →
    Log: "Security-relevant change detected (weak trigger: <which>)"
    Dispatch security-reviewer-agent in per-task mode

Security reviewer returns findings:

+-- "SECURE — no vulnerabilities found." → proceed to Task Completion
+-- Findings list:
    +-- Critical or High findings →
    |   Dispatch implementer-agent with security findings as fix instructions
    |   Re-dispatch security-reviewer-agent
    |   +-- Clean → proceed
    |   +-- Still Critical/High → escalate to user:
    |       "Security issues remain after fix attempt: <findings>"
    |       AskUserQuestion:
    |       (a) Accept risk and continue
    |       (b) Provide guidance for another fix
    |       (c) Abort
    +-- Medium or Low findings only →
        Log: "Security review found N medium/low issues (not blocking)"
        List findings in log
        → proceed to Task Completion
```

### Behavior by Mode

| Condition | `--auto` | Interactive |
|-----------|----------|-------------|
| No triggers matched | Skip review | Skip review |
| Strong trigger matched | Auto-dispatch reviewer | Auto-dispatch reviewer |
| Weak trigger matched | Auto-dispatch reviewer | Auto-dispatch reviewer |
| SECURE (no issues) | Proceed | Proceed |
| Critical/High (fix succeeds) | Proceed after fix | Proceed after fix |
| Critical/High (fix fails) | Escalate to user | Escalate to user |
| Medium/Low findings | Log and proceed | Log and proceed |

---

## 12. Task Completion & Checkpointing

**Purpose:** Update plan files to reflect completed task, advance to next.

### Completion Flow

```
After a task passes all gates (smoke test, review, security):

1. Update plan file checkboxes:
   For each step "- [ ]" under the completed task heading:
     Replace "- [ ]" with "- [x]"

2. Update README.md progress table:
   Read current progress table
   Recalculate: count [x], [ ], [B] across all phase files
   Update the row for the current phase
   Write updated README.md

3. Log completion:
   "✓ Task T complete (Phase P) — [Y/X tasks total]"

4. Advance:
   +-- Next pending task in this phase? → loop back to Pre-Task Research (Section 6)
   +-- Phase complete (all tasks [x] or [B])? → back to Phase Loop (Section 5)
   +-- All phases complete? → proceed to Final Audit (Section 13)
```

### Blocked Task Marking

```
When a task hits Tier 3 (revert + block) or is manually skipped:

1. Change all "- [ ]" steps under the task to "- [B]"
2. Add blockquote below the task heading:
   > BLOCKED: <reason>
3. Update README.md progress table (increment Blocked column)
4. Skip to next task
```

---

## 13. Final Audit

**Purpose:** Run comprehensive verification after all phases are complete.

### Audit Flow

```
After all phases complete:

1. Full smoke test across ALL repos that had files modified during the plan:
   For each repo that appears in any task's Files section:
     Run the full smoke test suite (typecheck → build → test → lint)
   +-- ALL PASS → continue
   +-- ANY FAIL → enter auto-fix ladder (same as Section 9)
       (Tier 3 here means the final build is broken — critical escalation)

2. Final security audit:
   Collect ALL files modified across the entire plan:
     git diff --name-only <first-task-commit>..HEAD
   Dispatch security-reviewer-agent in final-audit mode with all modified files
   +-- "SECURE" → continue
   +-- Critical/High → fix or escalate to user (same as Section 11)
   +-- Medium/Low → include in completion report

3. Generate completion summary (see Section 14)
```

---

## 14. Branch Finishing & Completion

**Purpose:** Offer to push and create a PR, then show final summary.

### Git Workflow Detection

```
How to push and create a PR:

1. Check project's CLAUDE.md for git workflow instructions
   +-- Found → follow those instructions (branch naming, push rules, PR tool)
2. Check .fullstack-dev/config.json for gitWorkflow config
   +-- Found → follow config (branch naming convention, default base branch)
3. Fall back to standard workflow:
   → Create a feature branch: git push origin main:feature/<plan-slug>
   → Create PR via available tools (GitHub MCP, gh CLI, or manual)
```

### Finishing Options

```
Show implementation summary:
  - Tasks: N completed, M blocked (out of T total)
  - Files changed: list by repo
  - Test results: pass/fail per repo
  - Security findings: severity counts

AskUserQuestion:
(a) Push branch and create PR
    → Detect git workflow (above)
    → Push to remote
    → Create PR with title from plan goal
    → PR body: ## Summary (bullet points) + ## Test plan (checklist)
    → CRITICAL: body must use real newlines, NEVER \n escapes
      (MCP tool passes body verbatim; \n renders as literal text)
    → If plan linked to GitHub issue (spec has issue #N): include "Closes #N" in PR body
(b) Just commit locally
    → Ensure all changes are committed
    → "All changes committed locally."
(c) Review the diff first
    → Show: git diff <first-task-commit>..HEAD --stat
    → Then re-offer options (a) and (b)
```

### Completion Message

```
"Implementation complete."

Summary:
  Plan: <plan-name>
  Tasks: N completed, M blocked
  Repos modified: <list>
  Test status: <pass/fail per repo>
  Security: <X findings (Y critical, Z high, ...)>

If blocked tasks exist:
  "Blocked tasks:"
  - Phase P, Task T: <reason>
  - ...
```

---

## 15. Prompt Templates

**Purpose:** Exact prompt templates passed to each agent type.

### 15.1 Implementer Prompt (Normal Mode)

```
## Your Role
You are implementing a single task from an implementation plan.
Implement exactly what the task describes — nothing more, nothing less.

## Project Context
- Project type: {config.projectType}
- Repos: {config.repos with paths}
- Tech stack: {config.techStack}
- Domain context: {CONTEXT.md excerpt if exists}

## Pre-Task Research
{merged output from parallel research agents}
- Source files you'll modify: {content summaries}
- Existing tests: {what tests exist for these files}
- Related code: {imports, dependencies, consumers}

## Task Brief
{extracted task text from plan file — everything from ### Task N: to the next ### Task or end of file}

## Interface Context
{Produces declarations from all previously completed tasks, concatenated}

## Instructions
1. For code tasks — follow TDD:
   - Write a failing test → run it → verify RED
   - Implement minimal code to pass → run it → verify GREEN
   - Refactor if needed → run tests → verify still GREEN
2. For config/schema tasks: create → verify → commit
3. For documentation tasks: write → verify references → commit
4. Commit after completing the task (atomic commit)
5. Run the full test suite once before your final commit
6. Self-review: completeness, test quality, no TODOs left
7. Commit message format: "Phase P Task T: <description>"

## Return Format
Return EXACTLY one status line as your final message:
- DONE
- DONE_WITH_CONCERNS:<description>
- NEEDS_CONTEXT:<what you need>
- BLOCKED:<reason>
```

### 15.2 Implementer Prompt (Fix Mode)

```
## Your Role
You are fixing a smoke test failure from a previous implementation.
The task was implemented but verification failed.

## Error Context
- Failing command: {typecheck|build|test|lint}
- Error output:
{full stdout+stderr from the failing command}

## Root Cause Hypothesis
{orchestrator's hypothesis if any, or "No hypothesis — analyze the error output"}

## Files Modified by the Task
{list of files from the task's Files section}

## Instructions
1. Analyze the full error output
2. Form 2-3 hypotheses for the root cause
3. Test the most likely hypothesis by reading the relevant code
4. Apply a targeted fix
5. Amend the previous commit: git add <files> && git commit --amend --no-edit
6. Re-run the failing command to verify

## Return Format
Return EXACTLY one status line as your final message:
- FIX_APPLIED
- FIX_FAILED:<reason the fix did not work>
```

### 15.3 Task-Reviewer Prompt

```
## Your Role
Review this completed task for spec compliance and code quality.
Be specific — cite file paths and line numbers. No vague findings.

## Task Brief
{same task text the implementer received}

## Changes Made
{git diff output for the task's commits}

## Smoke Test Results
{output from typecheck/build/test/lint — or "all passed" summary}

## Review Dimensions
1. Spec Compliance: nothing missing, nothing extra, nothing misunderstood
2. Code Quality: separation of concerns, error handling, naming, DRY
3. Test Quality: tests verify real behavior, cover edge cases
4. Interface Contract: Produces declarations match implementation

## Report Format
For each finding:
- Severity: Critical | Important | Minor
- Dimension: spec | quality | tests | interface
- File:line — exact location
- Issue: what's wrong
- Fix: suggested fix approach

If no findings: "APPROVED — no issues found."
```

### 15.4 Security-Reviewer Prompt

```
## Your Role
Review these code changes for security vulnerabilities.
Only report real, exploitable issues — not theoretical concerns.

## Task Context
{task brief summary — what was implemented and why}

## Changes Made
{git diff or full file content for modified files}

## Mode
{per-task | final-audit}

## Security Checklist
Check for:
- Injection (SQL/NoSQL/command) — parameterized queries? string concatenation?
- XSS — output encoding? dangerouslySetInnerHTML? CSP headers?
- Auth bypass — every protected route checks auth? IDOR?
- Sensitive data exposure — secrets in source? verbose errors? PII in logs?
- Input validation — user input sanitized? schema validation?
- Token storage — tokens in localStorage? cookie attributes?
- Rate limiting — public endpoints throttled? brute-force protection?
- CORS — overly permissive origins? wildcard with credentials?
- Secrets — API keys, passwords, tokens in code or logs?

## Report Format
For each finding:
- Severity: Critical | High | Medium | Low
- Category: injection | xss | auth | data-exposure | validation | token | rate-limit | cors | secrets
- File:line — exact location
- Vulnerability: what's exploitable and how
- Fix: specific remediation

If no findings: "SECURE — no vulnerabilities found."
```

---

## 16. Error Recovery Matrix

**Purpose:** Map failure scenarios to recovery actions.

| # | Scenario | Detection | Recovery |
|---|----------|-----------|----------|
| 1 | Agent crashes mid-task | Agent tool returns error or times out | Checkboxes unchanged (`- [ ]`). Re-invoke `/implement` to resume from this task. |
| 2 | Context window compacts | Orchestrator loses in-memory state | Re-read plan files and checkbox state. All progress is in files, not memory. Re-derive project context (Step 3) and continue. |
| 3 | User aborts mid-phase | User cancels or closes session | All completed tasks have checkboxes marked `- [x]`. Re-invoke `/implement` to resume from next pending task. |
| 4 | Smoke test fails all 3 tiers | Tier 3 reached | Task changes reverted via `git revert`. Task marked `- [B]` with reason. User decides: retry with guidance / skip / abort. |
| 5 | Reviewer finds persistent issues | 2 fix attempts fail | Escalate to user with findings. User decides: accept as-is / provide guidance / abort. |
| 6 | Security reviewer finds Critical/High | Fix attempt fails | Escalate to user. Blocks progression until user accepts risk or provides fix guidance. |
| 7 | No test framework available | Smoke test detection finds zero commands | Log "no verification tools detected for <repo>". Continue without blocking. Task still gets review and security check. |
| 8 | Plan file becomes corrupted | Malformed checkboxes, missing headings, broken markdown | Report: "Plan file <path> appears corrupted: <what's wrong>". Do not attempt to fix plan files — ask user to repair. |

### Recovery Principles

- Progress lives in plan files (checkboxes) — never in memory
- Any interrupted session can be resumed by re-running `/implement`
- Reverts use `git revert` to preserve history, not `git reset --hard`
- Blocked tasks are explicitly marked `- [B]` — never silently skipped
- Users always have the final say on blocked/failed tasks
