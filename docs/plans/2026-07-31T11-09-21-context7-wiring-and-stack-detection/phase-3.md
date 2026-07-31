# Phase 3: Wire context7 — Batch A (5 agents)

**Repo:** fullstack-dev
**Depends on:** Phase 1 (`skills/project/reference/context7-usage.md` must exist)
**Delivers:** `implementer-agent`, `refactor-agent`, `debugger-agent`, `refresh-agent`, and `security-reviewer-agent` each gain the `context7` MCP grant and a short agent-specific "Context7 MCP Usage" section pointing to the shared doc.

## File Structure

```
agents/
├── implementer-agent.md         [MODIFY]
├── refactor-agent.md            [MODIFY]
├── debugger-agent.md            [MODIFY]
├── refresh-agent.md             [MODIFY]
└── security-reviewer-agent.md   [MODIFY]
```

Each task below follows the same shape: (1) add `mcpServers: [context7]` to frontmatter, (2) insert a "## Context7 MCP Usage" section with the agent's exact framing line from the spec, placed immediately before the file's final section, using this two-line body in every case:

```markdown
## Context7 MCP Usage

<framing line>

See `skills/project/reference/context7-usage.md` for the full call flow, query scoping, and budget discipline.
```

### Task 1: implementer-agent

**Files:**
- Modify: `agents/implementer-agent.md`

**Interfaces:**
- Consumes: `skills/project/reference/context7-usage.md` (Phase 1, Task 1); the frontmatter pattern (`mcpServers:\n  - context7`) already established in `agents/scanner-agent.md`.
- Produces: `agents/implementer-agent.md` frontmatter with `mcpServers: [context7]`; a new `## Context7 MCP Usage` section.

**Acceptance Criteria:** AC2, AC3

**Steps:**

1. **Write content.** In `agents/implementer-agent.md`, change the frontmatter from:

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

   ````markdown
   FIX_APPLIED
   FIX_FAILED:<reason the fix did not work>
   ```

   ---

   ## Constraints
   ````

   to:

   ````markdown
   FIX_APPLIED
   FIX_FAILED:<reason the fix did not work>
   ```

   ---

   ## Context7 MCP Usage

   Confirm the current API signature before writing code against an unfamiliar library version.

   See `skills/project/reference/context7-usage.md` for the full call flow, query scoping, and budget discipline.

   ---

   ## Constraints
   ````

2. **Verify references.** Confirm `agents/implementer-agent.md` has `mcpServers:` with a `- context7` list item in its frontmatter, and contains exactly one `## Context7 MCP Usage` heading positioned after `## Output Format (Fix Mode)` and before `## Constraints`.

3. **Commit.**

   ```
   feat(implementer-agent): wire context7 MCP grant and usage section
   ```

### Task 2: refactor-agent

**Files:**
- Modify: `agents/refactor-agent.md`

**Interfaces:**
- Consumes: `skills/project/reference/context7-usage.md` (Phase 1, Task 1).
- Produces: `agents/refactor-agent.md` frontmatter with `mcpServers: [context7]`; a new `## Context7 MCP Usage` section with an evidence-only framing line.

**Acceptance Criteria:** AC2, AC3, AC4

**Steps:**

1. **Write content.** In `agents/refactor-agent.md`, change the frontmatter from:

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

   Then, immediately before the final `## Constraints` section, insert the new section. Note that `## Output Format` (the evidence-report template) sits between the `patterns` dimension steps and `## Constraints` — anchor on the end of that block, not on "4. Report differences...". Change:

   ````markdown
   ### Summary
   <2-3 sentence summary of key data from this dimension>
   ```

   ## Constraints
   ````

   to:

   ````markdown
   ### Summary
   <2-3 sentence summary of key data from this dimension>
   ```

   ## Context7 MCP Usage

   When investigating the `dependencies` or `patterns` dimension, confirm current documented idioms/APIs to report as evidence — do not use this to suggest a refactoring operation.

   See `skills/project/reference/context7-usage.md` for the full call flow, query scoping, and budget discipline.

   ## Constraints
   ````

2. **Verify references.** Confirm the frontmatter grant is present, the framing line contains no imperative/action verb aimed at changing code (e.g. no "fix", "refactor this", "apply"), and the section sits directly above `## Constraints` (after `## Output Format`'s closing code fence).

3. **Commit.**

   ```
   feat(refactor-agent): wire context7 MCP grant and evidence-only usage section
   ```

### Task 3: debugger-agent

**Files:**
- Modify: `agents/debugger-agent.md`

**Interfaces:**
- Consumes: `skills/project/reference/context7-usage.md` (Phase 1, Task 1).
- Produces: `agents/debugger-agent.md` frontmatter with `mcpServers: [context7]`; a new `## Context7 MCP Usage` section with an evidence-only framing line.

**Acceptance Criteria:** AC2, AC3, AC4

**Steps:**

1. **Write content.** In `agents/debugger-agent.md`, change the frontmatter from:

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

   ````markdown
   ### Summary
   <2-3 sentence summary of key evidence from this dimension>
   ```

   ## Constraints
   ````

   to:

   ````markdown
   ### Summary
   <2-3 sentence summary of key evidence from this dimension>
   ```

   ## Context7 MCP Usage

   When investigating the `dependencies` dimension, confirm a library's documented API/behavior to report as evidence — do not use this to form or imply a root-cause hypothesis.

   See `skills/project/reference/context7-usage.md` for the full call flow, query scoping, and budget discipline.

   ## Constraints
   ````

2. **Verify references.** Confirm the frontmatter grant is present, the framing line contains no hypothesis-forming language ("this is caused by", "root cause is"), and the section sits directly above `## Constraints`.

3. **Commit.**

   ```
   feat(debugger-agent): wire context7 MCP grant and evidence-only usage section
   ```

### Task 4: refresh-agent

**Files:**
- Modify: `agents/refresh-agent.md`

**Interfaces:**
- Consumes: `skills/project/reference/context7-usage.md` (Phase 1, Task 1).
- Produces: `agents/refresh-agent.md` frontmatter with `mcpServers: [context7]`; a new `## Context7 MCP Usage` section.

**Acceptance Criteria:** AC2, AC3

**Steps:**

1. **Write content.** In `agents/refresh-agent.md`, change the frontmatter from:

   ```yaml
   effort: medium
   ---
   ```

   to:

   ```yaml
   effort: medium
   mcpServers:
     - context7
   ---
   ```

   Then, immediately before the final `## Reference` section, insert the new section. Change:

   ```markdown
   Keep the summary concise -- a few bullet points, not a narrative.

   ---

   ## Reference
   ```

   to:

   ```markdown
   Keep the summary concise -- a few bullet points, not a narrative.

   ---

   ## Context7 MCP Usage

   Confirm current framework conventions when refreshing docs for a detected library/framework.

   See `skills/project/reference/context7-usage.md` for the full call flow, query scoping, and budget discipline.

   ---

   ## Reference
   ```

2. **Verify references.** Confirm the frontmatter grant is present and the new section sits between `## Output` and `## Reference`, separated by `---` on both sides matching this file's existing separator style.

3. **Commit.**

   ```
   feat(refresh-agent): wire context7 MCP grant and usage section
   ```

### Task 5: security-reviewer-agent

**Files:**
- Modify: `agents/security-reviewer-agent.md`

**Interfaces:**
- Consumes: `skills/project/reference/context7-usage.md` (Phase 1, Task 1).
- Produces: `agents/security-reviewer-agent.md` frontmatter with `mcpServers: [context7]`; a new `## Context7 MCP Usage` section.

**Acceptance Criteria:** AC2, AC3

**Steps:**

1. **Write content.** In `agents/security-reviewer-agent.md`, change the frontmatter from:

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
   | **Low** | Defense-in-depth improvements (missing headers, verbose errors) |

   ---

   ## Constraints
   ```

   to:

   ```markdown
   | **Low** | Defense-in-depth improvements (missing headers, verbose errors) |

   ---

   ## Context7 MCP Usage

   Check current, version-specific security guidance/hardening recommendations for a library or framework in scope.

   See `skills/project/reference/context7-usage.md` for the full call flow, query scoping, and budget discipline.

   ---

   ## Constraints
   ```

2. **Verify references.** Confirm the frontmatter grant is present and the new section sits between the Severity Definitions table and `## Constraints`, separated by `---` on both sides.

3. **Commit.**

   ```
   feat(security-reviewer-agent): wire context7 MCP grant and usage section
   ```

---

## Phase 3 Complete

5 of the 8 agents that needed a new `context7` grant now have it, each with a framing line matched to its role. `debugger-agent` and `refactor-agent` carry observation-only language consistent with their read-only Constraints.

**Next:** `phase-4.md`
