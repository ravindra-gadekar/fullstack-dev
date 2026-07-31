# Phase 2: Project Documentation & Config

**Repo:** fullstack-dev (`.`)
**Depends on:** Phase 1 (reference docs and agent definition updated to describe always-on behavior)
**Delivers:** This repo's own documentation and config updated to reflect that code-review-graph is no longer optional — completing the dogfood alignment.

## File Structure

```
CONTEXT.md                          (modify — add marker naming convention)
docs/project/
├── architecture.md                 (modify — remove "(optional)")
└── tech-stack.md                   (modify — remove "(optional)")
.fullstack-dev/
└── config.json                     (modify — remove optionalTools.codeReviewGraph)
```

---

### Task 1: Add Marker Naming Convention to CONTEXT.md

**Files:**
- Modify: `CONTEXT.md`

**Interfaces:**
- Consumes: Marker block format from `tools-setup.md` § "`.code-review-graphignore` Configuration" (Phase 1, Task 1) — the `fullstack-dev:code-review-graph` marker name
- Produces: Updated naming conventions table documenting the new marker

**Acceptance Criteria:** Spec § "File Changes → CONTEXT.md"

**Steps:**

- [x] Read `CONTEXT.md` line 56 (marker naming convention row in the Naming table)
- [x] Update the marker blocks row to add `fullstack-dev:code-review-graph` to the list. The current row reads:

  ```
  | Marker blocks | `fullstack-dev` (docs) / `fullstack-dev:gitignore` (gitignore) — distinct, coexisting markers | `.git/hooks/pre-commit` |
  ```

  Update to:

  ```
  | Marker blocks | `fullstack-dev` (docs) / `fullstack-dev:gitignore` (gitignore) / `fullstack-dev:code-review-graph` (graph ignore) — distinct, coexisting markers | `.git/hooks/pre-commit`, `.code-review-graphignore` |
  ```

- [x] Verify the example column includes `.code-review-graphignore` as a file that uses this marker
- [x] Commit: `docs(context): add fullstack-dev:code-review-graph marker naming convention`

---

### Task 2: Remove "(optional)" from architecture.md and tech-stack.md

**Files:**
- Modify: `docs/project/architecture.md`
- Modify: `docs/project/tech-stack.md`

**Interfaces:**
- Consumes: Decision from spec that code-review-graph is now standard, not optional
- Produces: Documentation that accurately describes code-review-graph's status

**Acceptance Criteria:** Spec § "File Changes → architecture.md", § "File Changes → tech-stack.md"

**Steps:**

- [x] Read `docs/project/architecture.md` and locate the code-review-graph row in the External Integrations table (line 60). Change:

  ```
  | code-review-graph | MCP server (optional) | Structural codebase understanding for token-efficient reviews in target projects |
  ```

  To:

  ```
  | code-review-graph | MCP server | Structural codebase understanding for token-efficient reviews in target projects |
  ```

- [x] Read `docs/project/tech-stack.md` and locate the code-review-graph row in the AI/LLM Integration table (line 30). Change:

  ```
  | code-review-graph (MCP, optional) | Structural codebase understanding for `/plan`, `/refactor`, `/implement` in managed target projects |
  ```

  To:

  ```
  | code-review-graph (MCP) | Structural codebase understanding for `/plan`, `/refactor`, `/implement` in managed target projects |
  ```

- [x] Verify no other occurrences of "optional" remain in either file that refer to code-review-graph
- [x] Commit: `docs(project): remove "(optional)" from code-review-graph descriptions`

---

### Task 3: Remove `optionalTools.codeReviewGraph` from config.json

**Files:**
- Modify: `.fullstack-dev/config.json`

**Interfaces:**
- Consumes: Updated config schema from `doc-templates.md` (Phase 1, Task 5) — `optionalTools` object retains only `agentation`
- Produces: Config file matching the 1.1.0 schema (no `codeReviewGraph` field)

**Acceptance Criteria:** Spec § "File Changes → config.json", § "Migration → `optionalTools.codeReviewGraph` is removed"

**Steps:**

- [x] Read `.fullstack-dev/config.json` and locate the `optionalTools` object. Current state:

  ```json
  "optionalTools": {
    "codeReviewGraph": false,
    "agentation": false
  }
  ```

- [x] Remove the `codeReviewGraph` field, leaving only `agentation`:

  ```json
  "optionalTools": {
    "agentation": false
  }
  ```

- [x] Verify the JSON remains valid after the edit (no trailing commas, correct structure)
- [x] Commit: `chore(config): remove optionalTools.codeReviewGraph (now always-on)`

---

## Phase 2 Complete

After this phase, the fullstack-dev repo is fully aligned with the always-on design:
- `CONTEXT.md` documents the `fullstack-dev:code-review-graph` marker naming convention
- `architecture.md` and `tech-stack.md` describe code-review-graph without the "(optional)" qualifier
- `config.json` no longer contains `optionalTools.codeReviewGraph`

The implementation plan is complete. All 10 tasks across 2 phases cover every file change listed in the spec.

**Next:** Plan complete
