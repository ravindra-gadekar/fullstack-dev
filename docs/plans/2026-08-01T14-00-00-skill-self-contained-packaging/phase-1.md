# Phase 1: Relocate Agent Files & Delete Orphans

**Repo:** fullstack-dev (path `.`)
**Depends on:** None
**Delivers:** All 11 agent `.md` files exist at `skills/<owning-skill>/agents/<name>.md` with byte-identical content to their prior top-level location; the top-level `agents/`, `scripts/`, and `hooks/` directories no longer exist.

## File Structure

```
skills/
├── project/agents/          [create] init-agent.md, repo-agent.md, refresh-agent.md, scanner-agent.md
├── plan/agents/              [create] plan-reviewer-agent.md
├── brainstorm/agents/        [create] grill-agent.md
├── implement/agents/         [create] implementer-agent.md, task-reviewer-agent.md, security-reviewer-agent.md
├── debug/agents/             [create] debugger-agent.md
└── refactor/agents/          [create] refactor-agent.md
agents/                       [delete] (empty after moves)
scripts/pre-commit.sh         [delete]
scripts/                      [delete] (empty after removal)
hooks/hooks.json              [delete]
hooks/                        [delete] (empty after removal)
```

Each task below is a content-preserving move: read the full current file, write an identical copy at the new path, verify byte-identical, delete the old file. This is a **Config** task type (create-and-verify), not TDD — there is no code behavior to test, only path correctness.

---

### Task 1: Relocate project-skill agents (init, repo, refresh, scanner)

**Files:**
- Create: `skills/project/agents/init-agent.md`
- Create: `skills/project/agents/repo-agent.md`
- Create: `skills/project/agents/refresh-agent.md`
- Create: `skills/project/agents/scanner-agent.md`
- Delete: `agents/init-agent.md`
- Delete: `agents/repo-agent.md`
- Delete: `agents/refresh-agent.md`
- Delete: `agents/scanner-agent.md`

**Interfaces:**
- Consumes: existing content of `agents/init-agent.md`, `agents/repo-agent.md`, `agents/refresh-agent.md`, `agents/scanner-agent.md` (confirmed present in `agents/` at plan time)
- Produces: `skills/project/agents/{init,repo,refresh,scanner}-agent.md` — new co-located paths consumed by Phase 2 Task 1 (`skills/project/SKILL.md` dispatch blocks) and Phase 3 Task 2 (`init-agent.md` health-check table edit)

**Acceptance Criteria:** Spec checkbox "All 11 agent files relocated from top-level `agents/` to `skills/<owning-skill>/agents/<name>.md` per the relocation map" (project-skill subset).

**Steps:**
1. Read `agents/init-agent.md`, `agents/repo-agent.md`, `agents/refresh-agent.md`, `agents/scanner-agent.md` in full.
2. Write each file's full content, unchanged, to `skills/project/agents/init-agent.md`, `skills/project/agents/repo-agent.md`, `skills/project/agents/refresh-agent.md`, `skills/project/agents/scanner-agent.md` respectively.
3. Verify each new file's content matches the corresponding old file's content exactly (no diff beyond the path).
4. Delete `agents/init-agent.md`, `agents/repo-agent.md`, `agents/refresh-agent.md`, `agents/scanner-agent.md`.
5. Commit: `chore(skills): relocate project-skill agents into skills/project/agents/`

---

### Task 2: Relocate plan-skill agent (plan-reviewer)

**Files:**
- Create: `skills/plan/agents/plan-reviewer-agent.md`
- Delete: `agents/plan-reviewer-agent.md`

**Interfaces:**
- Consumes: existing content of `agents/plan-reviewer-agent.md`
- Produces: `skills/plan/agents/plan-reviewer-agent.md` — consumed by Phase 2 Task 2 (`skills/plan/SKILL.md` and `plan-flow.md` dispatch blocks)

**Acceptance Criteria:** Spec checkbox "All 11 agent files relocated..." (plan-skill subset).

**Steps:**
1. Read `agents/plan-reviewer-agent.md` in full.
2. Write its full content, unchanged, to `skills/plan/agents/plan-reviewer-agent.md`.
3. Verify content matches exactly.
4. Delete `agents/plan-reviewer-agent.md`.
5. Commit: `chore(skills): relocate plan-reviewer agent into skills/plan/agents/`

---

### Task 3: Relocate brainstorm-skill agent (grill)

**Files:**
- Create: `skills/brainstorm/agents/grill-agent.md`
- Delete: `agents/grill-agent.md`

**Interfaces:**
- Consumes: existing content of `agents/grill-agent.md`
- Produces: `skills/brainstorm/agents/grill-agent.md` — consumed by Phase 2 Task 3 (`skills/brainstorm/SKILL.md` inline-to-file-read conversion) and Phase 2 Task 4 (`brainstorm-flow.md` dispatch path)

**Acceptance Criteria:** Spec checkbox "All 11 agent files relocated..." (brainstorm-skill subset).

**Steps:**
1. Read `agents/grill-agent.md` in full.
2. Write its full content, unchanged, to `skills/brainstorm/agents/grill-agent.md`.
3. Verify content matches exactly.
4. Delete `agents/grill-agent.md`.
5. Commit: `chore(skills): relocate grill agent into skills/brainstorm/agents/`

---

### Task 4: Relocate implement-skill agents (implementer, task-reviewer, security-reviewer)

**Files:**
- Create: `skills/implement/agents/implementer-agent.md`
- Create: `skills/implement/agents/task-reviewer-agent.md`
- Create: `skills/implement/agents/security-reviewer-agent.md`
- Delete: `agents/implementer-agent.md`
- Delete: `agents/task-reviewer-agent.md`
- Delete: `agents/security-reviewer-agent.md`

**Interfaces:**
- Consumes: existing content of `agents/implementer-agent.md`, `agents/task-reviewer-agent.md`, `agents/security-reviewer-agent.md`
- Produces: `skills/implement/agents/{implementer,task-reviewer,security-reviewer}-agent.md` — consumed by Phase 2 Task 7 (`skills/implement/SKILL.md` reference table) and Phase 2 Task 8 (`implement-flow.md` agent pointers)

**Acceptance Criteria:** Spec checkbox "All 11 agent files relocated..." (implement-skill subset).

**Steps:**
1. Read `agents/implementer-agent.md`, `agents/task-reviewer-agent.md`, `agents/security-reviewer-agent.md` in full.
2. Write each file's full content, unchanged, to `skills/implement/agents/implementer-agent.md`, `skills/implement/agents/task-reviewer-agent.md`, `skills/implement/agents/security-reviewer-agent.md` respectively.
3. Verify each new file's content matches the corresponding old file's content exactly.
4. Delete `agents/implementer-agent.md`, `agents/task-reviewer-agent.md`, `agents/security-reviewer-agent.md`.
5. Commit: `chore(skills): relocate implement-skill agents into skills/implement/agents/`

---

### Task 5: Relocate debug-skill agent (debugger)

**Files:**
- Create: `skills/debug/agents/debugger-agent.md`
- Delete: `agents/debugger-agent.md`

**Interfaces:**
- Consumes: existing content of `agents/debugger-agent.md`
- Produces: `skills/debug/agents/debugger-agent.md` — consumed by Phase 2 Task 5 (`debug-flow.md` named-subagent-to-path-read conversion)

**Acceptance Criteria:** Spec checkbox "All 11 agent files relocated..." (debug-skill subset).

**Steps:**
1. Read `agents/debugger-agent.md` in full.
2. Write its full content, unchanged, to `skills/debug/agents/debugger-agent.md`.
3. Verify content matches exactly.
4. Delete `agents/debugger-agent.md`.
5. Commit: `chore(skills): relocate debugger agent into skills/debug/agents/`

---

### Task 6: Relocate refactor-skill agent (refactor)

**Files:**
- Create: `skills/refactor/agents/refactor-agent.md`
- Delete: `agents/refactor-agent.md`

**Interfaces:**
- Consumes: existing content of `agents/refactor-agent.md`
- Produces: `skills/refactor/agents/refactor-agent.md` — consumed by Phase 2 Task 6 (`skills/refactor/SKILL.md` named-subagent-to-path-read conversion)

**Acceptance Criteria:** Spec checkbox "All 11 agent files relocated..." (refactor-skill subset).

**Steps:**
1. Read `agents/refactor-agent.md` in full.
2. Write its full content, unchanged, to `skills/refactor/agents/refactor-agent.md`.
3. Verify content matches exactly.
4. Delete `agents/refactor-agent.md`.
5. Commit: `chore(skills): relocate refactor agent into skills/refactor/agents/`

---

### Task 7: Delete orphaned top-level files and empty directories

**Files:**
- Delete: `scripts/pre-commit.sh`
- Delete: `hooks/hooks.json`
- Delete: `agents/` (directory, empty after Tasks 1-6)
- Delete: `scripts/` (directory, empty after removing `pre-commit.sh`)
- Delete: `hooks/` (directory, empty after removing `hooks.json`)

**Interfaces:**
- Consumes: Tasks 1-6's Produces (confirms `agents/` is empty before deletion)
- Produces: repo root free of `agents/`, `scripts/`, `hooks/` — a precondition Phase 4 Task 1's orphan-check static verification (`grep`-based) relies on

**Acceptance Criteria:** Spec checkboxes "Top-level `agents/`, `scripts/`, and `hooks/` directories deleted (no files remain)".

**Steps:**
1. Confirm `agents/` contains zero files (Tasks 1-6 complete) via directory listing.
2. Delete `scripts/pre-commit.sh` — its content is already inlined in `skills/project/reference/init-flow.md` §9.8 and never read at runtime post-fix.
3. Delete `hooks/hooks.json` — its content is already inlined in `skills/project/reference/init-flow.md` §9.7 and never read at runtime post-fix.
4. Delete the now-empty `agents/`, `scripts/`, `hooks/` directories.
5. Verify via directory listing that none of `agents/`, `scripts/`, `hooks/` exist at repo root.
6. Commit: `chore: remove orphaned top-level agents/, scripts/, hooks/ directories`

## Phase 1 Complete

All 11 agent files now live under their owning skill's `agents/` subdirectory with unchanged content. The top-level `agents/`, `scripts/`, and `hooks/` directories are gone. No dispatch blocks have been updated yet — that is Phase 2's job. Until Phase 2 completes, `SKILL.md`/reference-doc dispatch blocks still reference the old `<plugin-path>/agents/*.md` paths; this is an expected, git-history-only transient state (per README Global Constraints, phases run sequentially and only the final state after Phase 2 is expected to be internally consistent).

**Next:** `phase-2.md`
