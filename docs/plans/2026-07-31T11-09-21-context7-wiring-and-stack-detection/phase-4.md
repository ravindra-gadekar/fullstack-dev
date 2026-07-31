# Phase 4: Wire context7 — Batch B (5 agents)

**Repo:** fullstack-dev
**Depends on:** Phase 1 (`skills/project/reference/context7-usage.md` must exist); sequenced after Phase 3 as the second half of the same mechanical batch (no interface dependency on Phase 3's output beyond the shared doc).
**Delivers:** `task-reviewer-agent`, `plan-reviewer-agent`, and `grill-agent` gain the `context7` MCP grant plus a usage section; `init-agent` and `repo-agent` (which already hold the grant) get their first-ever usage section, so the existing grant stops being unused.

## File Structure

```
agents/
├── task-reviewer-agent.md   [MODIFY]
├── plan-reviewer-agent.md   [MODIFY]
├── grill-agent.md           [MODIFY]
├── init-agent.md            [MODIFY]  (section only — grant already present)
└── repo-agent.md            [MODIFY]  (section only — grant already present)
```

### Task 1: task-reviewer-agent

**Files:**
- Modify: `agents/task-reviewer-agent.md`

**Interfaces:**
- Consumes: `skills/project/reference/context7-usage.md` (Phase 1, Task 1).
- Produces: `agents/task-reviewer-agent.md` frontmatter with `mcpServers: [context7]`; a new `## Context7 MCP Usage` section.

**Acceptance Criteria:** AC2, AC3

**Steps:**

1. **Write content.** In `agents/task-reviewer-agent.md`, change the frontmatter from:

   ```yaml
   effort: high
   ---
   ```

   to:

   ```yaml
   effort: high
   mcpServers:
     - context7
   ---
   ```

   Then, immediately before the final `## Constraints` section, insert the new section. Change:

   ```markdown
   - Number findings sequentially across all severity groups (1, 2, 3... not restarting per group).

   ---

   ## Constraints
   ```

   to:

   ```markdown
   - Number findings sequentially across all severity groups (1, 2, 3... not restarting per group).

   ---

   ## Context7 MCP Usage

   Verify a completed task's implementation matches the current API/behavior of the library it targets.

   See `skills/project/reference/context7-usage.md` for the full call flow, query scoping, and budget discipline.

   ---

   ## Constraints
   ```

2. **Verify references.** Confirm the frontmatter grant is present and exactly one `## Context7 MCP Usage` heading sits between `### Rules` and `## Constraints`.

3. **Commit.**

   ```
   feat(task-reviewer-agent): wire context7 MCP grant and usage section
   ```

### Task 2: plan-reviewer-agent

**Files:**
- Modify: `agents/plan-reviewer-agent.md`

**Interfaces:**
- Consumes: `skills/project/reference/context7-usage.md` (Phase 1, Task 1).
- Produces: `agents/plan-reviewer-agent.md` frontmatter with `mcpServers: [context7]`; a new `## Context7 MCP Usage` section.

**Acceptance Criteria:** AC2, AC3

**Steps:**

1. **Write content.** In `agents/plan-reviewer-agent.md`, change the frontmatter from:

   ```yaml
   effort: high
   ---
   ```

   to:

   ```yaml
   effort: high
   mcpServers:
     - context7
   ---
   ```

   Then, immediately before the final `## Constraints` section, insert the new section. Change:

   ```markdown
   - Number findings sequentially across all priority groups (1, 2, 3... not restarting per group).

   ---

   ## Constraints
   ```

   to:

   ```markdown
   - Number findings sequentially across all priority groups (1, 2, 3... not restarting per group).

   ---

   ## Context7 MCP Usage

   Verify a plan's proposed approach is compatible with the current version of the library/framework it depends on.

   See `skills/project/reference/context7-usage.md` for the full call flow, query scoping, and budget discipline.

   ---

   ## Constraints
   ```

2. **Verify references.** Confirm the frontmatter grant is present and exactly one `## Context7 MCP Usage` heading sits between `### Rules` and `## Constraints`.

3. **Commit.**

   ```
   feat(plan-reviewer-agent): wire context7 MCP grant and usage section
   ```

### Task 3: grill-agent

**Files:**
- Modify: `agents/grill-agent.md`

**Interfaces:**
- Consumes: `skills/project/reference/context7-usage.md` (Phase 1, Task 1).
- Produces: `agents/grill-agent.md` frontmatter with `mcpServers: [context7]`; a new `## Context7 MCP Usage` section.

**Acceptance Criteria:** AC2, AC3

**Steps:**

1. **Write content.** In `agents/grill-agent.md`, change the frontmatter from:

   ```yaml
   effort: high
   ---
   ```

   to:

   ```yaml
   effort: high
   mcpServers:
     - context7
   ---
   ```

   Then, immediately before the final `## Constraints` section, insert the new section. Change:

   ```markdown
   - Number findings sequentially across all priority groups (1, 2, 3... not restarting per group).

   ---

   ## Constraints
   ```

   to:

   ```markdown
   - Number findings sequentially across all priority groups (1, 2, 3... not restarting per group).

   ---

   ## Context7 MCP Usage

   Verify a spec's claims about a library/framework's capabilities against current documentation.

   See `skills/project/reference/context7-usage.md` for the full call flow, query scoping, and budget discipline.

   ---

   ## Constraints
   ```

2. **Verify references.** Confirm the frontmatter grant is present and exactly one `## Context7 MCP Usage` heading sits between `### Rules` and `## Constraints`. Confirm the existing `WebFetch` tool grant and its "sparingly" constraint are untouched.

3. **Commit.**

   ```
   feat(grill-agent): wire context7 MCP grant and usage section
   ```

### Task 4: init-agent (use the existing grant)

**Files:**
- Modify: `agents/init-agent.md`

**Interfaces:**
- Consumes: `skills/project/reference/context7-usage.md` (Phase 1, Task 1); the existing `mcpServers: [context7]` frontmatter entry (already present — no change needed).
- Produces: a new `## Context7 MCP Usage` section in `agents/init-agent.md`.

**Acceptance Criteria:** AC3

**Steps:**

1. **Write content.** In `agents/init-agent.md`, frontmatter already declares `mcpServers: [context7]` — do not modify it. Immediately before the final `## Constraints` section, insert the new section. Change:

   ```markdown
   - If JSON parsing fails on an existing config file, report the corruption and offer to back up the file before regenerating.

   ---

   ## Constraints
   ```

   to:

   ```markdown
   - If JSON parsing fails on an existing config file, report the corruption and offer to back up the file before regenerating.

   ---

   ## Context7 MCP Usage

   Confirm framework/tooling conventions when generating or validating project setup during the init wizard.

   See `skills/project/reference/context7-usage.md` for the full call flow, query scoping, and budget discipline.

   ---

   ## Constraints
   ```

2. **Verify references.** Confirm the frontmatter is unchanged (still exactly one `mcpServers` block with `- context7`) and the new section sits between `## Error Handling` and `## Constraints`.

3. **Commit.**

   ```
   docs(init-agent): use the existing context7 MCP grant with a usage section
   ```

### Task 5: repo-agent (use the existing grant)

**Files:**
- Modify: `agents/repo-agent.md`

**Interfaces:**
- Consumes: `skills/project/reference/context7-usage.md` (Phase 1, Task 1); the existing `mcpServers: [context7]` frontmatter entry (already present — no change needed).
- Produces: a new `## Context7 MCP Usage` section in `agents/repo-agent.md`.

**Acceptance Criteria:** AC3

**Steps:**

1. **Write content.** In `agents/repo-agent.md`, frontmatter already declares `mcpServers: [context7]` — do not modify it. Immediately before the final `## Reference Documents` section, insert the new section. Change:

   ```markdown
   Adjust the summary to reflect what was actually done -- omit lines for skipped steps (e.g., CONTEXT.md if no domain changes, remote repo if user chose "Later").

   ---

   ## Reference Documents
   ```

   to:

   ```markdown
   Adjust the summary to reflect what was actually done -- omit lines for skipped steps (e.g., CONTEXT.md if no domain changes, remote repo if user chose "Later").

   ---

   ## Context7 MCP Usage

   Confirm current scaffolding conventions for the framework/runtime chosen in the add-repo wizard.

   See `skills/project/reference/context7-usage.md` for the full call flow, query scoping, and budget discipline.

   ---

   ## Reference Documents
   ```

2. **Verify references.** Confirm the frontmatter is unchanged (still exactly one `mcpServers` block with `- context7`) and the new section sits between `## Output` and `## Reference Documents`.

3. **Commit.**

   ```
   docs(repo-agent): use the existing context7 MCP grant with a usage section
   ```

---

## Phase 4 Complete

All 11 agents now hold the `context7` MCP grant, and all 10 non-`scanner-agent` agents point to `skills/project/reference/context7-usage.md` with a role-specific framing line. `scanner-agent` (Phase 2) has its own pointer section preserving its original framing.

**Next:** `phase-5.md`
