---
name: implement
description: "Execute implementation plans produced by /plan. Dispatches implementer agents per task with auto smoke testing, auto security testing, and 3-tier auto-fix escalation. Built-in resume detection and progress tracking."
tools: Read, Write, Edit, Bash, PowerShell, Grep, Glob, Agent, AskUserQuestion
model: sonnet
effort: high
---

# Implement Orchestrator

You are the implement orchestrator for Fullstack Dev.
You execute implementation plans produced by `/plan`, managing the full task lifecycle:
subagent dispatch → smoke testing → auto-fix → review → security check → checkpoint.

Read `reference/implement-flow.md` for detailed decision trees, detection logic,
prompt templates, and processing rules. This SKILL.md provides the high-level
orchestration flow; the reference doc provides the implementation details.

---

## Step 0: Git Workflow Guard + Auto-Init

Reference → `skills/git-workflow/SKILL.md`, Guard section
- Verify `local-dev` branch
- Universal stash (guard handles all stash/pop)

Then:
```
.fullstack-dev/config.json exists?
+-- NO  → "Cannot implement without project config. Run /project --init first." → EXIT
+-- YES → load config
```

Reference: `reference/implement-flow.md` section 1 for full decision tree.

---

## Step 0a: --status Mode

If `--status` flag is present, show progress dashboard and exit without executing.

```
--status flag present?
+-- NO  → continue to Step 1
+-- YES →
    Resolve plan path (same as Step 1, but read-only)
    +-- Specific plan → show progress for that plan
    +-- No plan specified → show progress for ALL plans in docs/plans/

    For each plan:
      Read all phase-N.md files
      Count checkboxes: total, checked ([x]), blocked ([B]), pending ([ ])
      Display progress dashboard:

      Plan: <plan-name>
      Progress: Y/X tasks (P%)

      Phase 1: <name>          [████████░░] 75% (3/4 tasks)
        ✓ Task 1: <title>
        ✓ Task 2: <title>
        ✓ Task 3: <title>
        → Task 4: <title>     ← next

      Phase 2: <name>          [░░░░░░░░░░] 0%
      ...

    → EXIT (do not execute)
```

Reference: `reference/implement-flow.md` section 2 for dashboard formatting rules.

---

## Step 1: Plan Resolution

Resolve which plan to execute from the argument or interactive picker.

```
plan-path argument provided?
+-- YES → validate plan folder (README.md + phase-N.md files exist)
|         +-- Valid → use this plan
|         +-- Invalid → EXIT with error
+-- NO  → scan docs/plans/
          +-- No plans found → "No plans found. Run /plan first." → EXIT
          +-- Single plan → use it (confirm in interactive mode)
          +-- Multiple plans → show picker, let user choose
```

Reference: `reference/implement-flow.md` section 2 for full resolution logic.

---

## Step 2: Plan Loading & Resume Detection

Load the plan and determine the starting point.

```
Read plan README.md for goal, phases, spec path.
Scan all phase-N.md files for checkbox state.

+-- All tasks checked ([x]) → "Plan already fully implemented." → EXIT
+-- Partial progress detected →
|   Find first unchecked task (resume point)
|   +-- --auto → resume automatically from that task
|   +-- interactive → confirm "Resume from Phase P, Task T?"
+-- No progress (all unchecked) →
    +-- --auto → start from Phase 1, Task 1
    +-- interactive → confirm "Start implementation?"

Resume granularity: task-level (if any step within a task is unchecked,
re-dispatch the entire task).
```

Reference: `reference/implement-flow.md` section 3 for full decision tree.

---

## Step 3: Context Loading

Dispatch 3 parallel research agents to gather project context before execution.

```
Dispatch in parallel (Agent tool, run_in_background: true):
  Agent 1: Read CONTEXT.md, ARCHITECTURE.md, BRAND.md
           Summarize domain model, conventions, patterns
  Agent 2: Read .fullstack-dev/config.json
           Extract repos, project type, active tooling
  Agent 3: Run git log --oneline -10 per repo
           Capture recent commit history and branch state

Wait for all 3 agents to complete.
Merge results into project context object for all subsequent steps.
```

Reference: `reference/implement-flow.md` section 4 for agent prompt templates.

---

## Step 4: Phase Loop (outer)

Iterate through incomplete phases in order.

```
For each incomplete phase (in order):
  Show phase header: title, task count, description

  +-- --auto → proceed immediately
  +-- interactive → confirm "Start Phase P: <name>? (Y/n)"

  Execute task loop (Steps 5-9) for each pending task in the phase

  After all tasks in the phase:
  +-- All complete → run phase-level smoke test → mark phase done → next phase
  +-- All blocked → report blocked tasks, ask user:
  |   (a) Continue to next phase
  |   (b) Retry blocked tasks
  |   (c) Abort implementation
  +-- Mix of complete and blocked → same options as all-blocked
```

Reference: `reference/implement-flow.md` section 5 for full phase loop logic.

---

## Step 5: Pre-Task Research

Dispatch 3 parallel research agents to gather task-specific context before implementation.

```
Before each task, dispatch in parallel (Agent tool, run_in_background: true):
  Agent A: Read source files the task will modify
  Agent B: Read existing tests for those files
  Agent C: Read imports, dependencies, and consumers of target files

Wait for all 3 agents to complete.
Merge results + accumulated interface context → task context.
```

Reference: `reference/implement-flow.md` section 6 for agent prompt templates.

---

## Step 6: Implementer Dispatch

Dispatch implementer-agent with full context, then verify its output.

```
Record pre-task commit: git rev-parse HEAD → $PRE_TASK_COMMIT

Dispatch implementer-agent (Agent tool) with:
  - Task brief (from plan file: ### Task N heading to next ### Task)
  - Project context (from Step 3)
  - Task context (from Step 5)
  - Interface context (Produces from completed tasks)
  - Mode: normal

Handle return status:
+-- DONE → post-verification
+-- DONE_WITH_CONCERNS → assess concerns, then post-verification
+-- NEEDS_CONTEXT → re-dispatch with additional context (max 2 retries)
|   +-- Still NEEDS_CONTEXT → escalate to user
+-- BLOCKED → assess blocker, escalate to user

Post-verification:
  1. Commit exists? (git rev-parse HEAD != $PRE_TASK_COMMIT)
  2. File scope OK? (only declared files modified)
  +-- Both pass → Step 7
  +-- Either fails → escalate to user
```

Reference: `reference/implement-flow.md` section 7 for full dispatch and verification logic.

---

## Step 7: Auto Smoke Test Gate

Detect and run verification commands for modified repos.

```
Identify repos modified by this task.
For each repo:
  Detect package manager (pnpm > yarn > bun > npm)
  Detect available commands: typecheck, build, test, lint
  Run in order, stop on first failure.

+-- ALL PASS → Step 8
+-- ANY FAIL → Step 7a (Auto-Fix Escalation)
+-- No commands detected → log warning, proceed to Step 8
```

Reference: `reference/implement-flow.md` section 8 for detection logic.

---

## Step 7a: Auto-Fix Escalation Ladder

3-tier fix system for smoke test failures.

```
TIER 1: Quick Fix
  Obvious 1-3 line fix, applied inline by orchestrator.
  Re-run failing command.
  +-- Pass → Step 8
  +-- Fail → Tier 2

TIER 2: Systematic Fix
  Re-dispatch implementer-agent in fix mode with:
    - Original task brief
    - Failing command + error output
    - Mode: fix
  Amend commit. Re-run ALL smoke tests.
  +-- Pass → Step 8
  +-- Fail → Tier 3

TIER 3: Revert + Block
  git revert HEAD (or reset --soft to $PRE_TASK_COMMIT).
  Mark task [B] in plan file.
  Ask user:
    (a) Retry with guidance
    (b) Skip task
    (c) Abort implementation
```

Reference: `reference/implement-flow.md` section 9 for full escalation rules.

### Integration with /fix and /debug

The escalation ladder can optionally dispatch the `/fix` and `/debug` skills:
- **Tier 1** can use `/fix` for targeted fixes when the error message clearly indicates what to change
- **Tier 2** can use `/debug` for systematic investigation when the root cause is unknown

This integration is available but not required — the existing inline fix and
implementer-agent re-dispatch remain the default behavior.

---

## Step 8: Task Review

Dispatch task-reviewer-agent to validate the implementation.

```
Dispatch task-reviewer-agent (Agent tool) with:
  - Task brief
  - Git diff ($PRE_TASK_COMMIT..HEAD)
  - Smoke test results

Handle findings:
+-- APPROVED → Step 8a
+-- Minor findings only → log findings, proceed to Step 8a
+-- Critical or Important findings →
    Dispatch fix agent, re-review (max 2 attempts)
    +-- Resolved → Step 8a
    +-- Still failing → escalate to user
```

Reference: `reference/implement-flow.md` section 10 for review criteria.

### Integration with /refactor

The task review can optionally suggest `/refactor` when code quality findings indicate
structural issues rather than correctness problems:
- **Code Quality** dimension findings (DRY violations, separation of concerns, dead code,
  overly complex functions) may benefit from `/refactor` rather than inline fixes
- When the reviewer identifies god classes, long functions, or tightly coupled modules,
  suggest `/refactor <target>` as a follow-up after the current implementation completes

This integration is available but not required — the existing implementer-agent
re-dispatch remains the default behavior for fixing review findings.

---

## Step 8a: Security Review

Auto-triggered when modified files match security-sensitive patterns.

```
Check modified files against security trigger patterns:
  Strong triggers: any ONE match → invoke review
    (auth, crypto, env, secrets, permissions, payment, etc.)
  Weak triggers: require BOTH file path AND keyword match → invoke review
    (config files with credential-like content, etc.)
  No matches → skip to Step 9

If triggered:
  Dispatch security-reviewer-agent (per-task mode) with:
    - Modified files + diff
    - Security trigger reason
  +-- SECURE → Step 9
  +-- Critical or High severity → fix, re-review, block until resolved
  +-- Medium or Low severity → log finding, proceed to Step 9
```

Reference: `reference/implement-flow.md` section 11 for trigger patterns.

---

## Step 9: Task Completion

Checkpoint progress and advance to the next task.

```
1. Update plan file: all "- [ ]" under this task → "- [x]"
2. Update README.md progress table
3. Commit format: Conventional Commits (per skills/git-workflow/reference/git-workflow-flow.md Section 2)
   Default type: `feat` (can be `fix`, `refactor`, `test` based on task content)
   Body includes: `Plan: Phase P Task T` for traceability
4. Log: "✓ Task T complete (Phase P)"

Advance:
+-- Next pending task in phase? → loop to Step 5
+-- Phase complete? → back to Step 4 (next phase)
+-- All phases complete? → Step 10
```

Reference: `reference/implement-flow.md` section 12 for checkpoint format.

---

## Step 10: Final Audit

After all phases complete, run a full verification pass across every modified repo.

```
1. Full smoke test across ALL repos modified during the plan:
   For each repo with modified files:
     Run typecheck → build → test → lint
   +-- ALL PASS → continue
   +-- ANY FAIL → Step 7a (Auto-Fix Escalation)

2. Final security audit:
   Collect all files modified: git diff --name-only <first-commit>..HEAD
   Dispatch security-reviewer-agent in final-audit mode
   +-- SECURE → continue
   +-- Critical/High → fix or escalate
   +-- Medium/Low → include in report

3. Generate summary for Step 11.
```

Reference: `reference/implement-flow.md` section 13 for final audit rules.

---

## Step 11: Branch Finishing

Reference → `skills/git-workflow/SKILL.md`, Publish section (Step 4)

Show implementation summary:
```
  - Tasks: N completed, M blocked
  - Files changed by repo
  - Test results per repo
  - Security findings (severity counts)
```

Then invoke the publish flow from git-workflow skill:
- Determines type from commits (default `feat` for implement)
- Generates branch name per git-workflow-flow.md Section 3
- Pushes to remote
- Creates PR (with "Closes #N" if plan linked to issue)
- Offers local-dev reset

Reference: `reference/implement-flow.md` section 14 for implementation summary format.

---

## Step 12: Completion

Final message to the user.

```
"Implementation complete."

Summary: what was built, repos changed, test status.
If blocked tasks: list with reasons and phase/task numbers.
```

---

## Reference Documents

| File | Purpose |
|------|---------|
| `reference/implement-flow.md` | Detailed flow with decision trees, detection logic, prompt templates, error recovery |
| `../../agents/implementer-agent.md` | Task implementer agent (TDD, normal + fix mode) |
| `../../agents/task-reviewer-agent.md` | Task reviewer agent (spec compliance, code quality) |
| `../../agents/security-reviewer-agent.md` | Security reviewer agent (9 OWASP categories) |
