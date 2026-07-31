# Phase 5: Update This Repo's Own Docs

**Repo:** fullstack-dev
**Depends on:** Phase 4 (needs the final state of all 11 agents to accurately describe the completed wiring)
**Delivers:** `docs/project/architecture.md` and `docs/project/tech-stack.md` (this plugin's own dogfooded docs, generated originally via `/project --init`) reflect that context7 is wired into all 11 agents and that stack detection covers the six new ecosystems at full depth. The final task also runs the plan's consistency-check verification across all 11 agent files.

## File Structure

```
docs/project/
├── architecture.md   [MODIFY]
└── tech-stack.md     [MODIFY]
```

### Task 1: Update docs/project/architecture.md

**Files:**
- Modify: `docs/project/architecture.md`

**Interfaces:**
- Consumes: the completed state of all 11 `agents/*.md` files (Phases 2–4) — this task only describes that end state, it does not re-verify it (verification happens in Task 2, Step 2).
- Produces: an updated External Integrations row and Agents service description reflecting full context7 wiring.

**Acceptance Criteria:** AC8, AC10

**Steps:**

1. **Write content.** In `docs/project/architecture.md`, update the `### Agents (agents/)` service description. Change:

   ```markdown
   - **Purpose:** Specialized, tool-scoped subagents (e.g. `init-agent`, `scanner-agent`, `refresh-agent`, `debugger-agent`, `implementer-agent`) that execute a flow end-to-end inside a target project's working directory.
   ```

   to:

   ```markdown
   - **Purpose:** Specialized, tool-scoped subagents (e.g. `init-agent`, `scanner-agent`, `refresh-agent`, `debugger-agent`, `implementer-agent`) that execute a flow end-to-end inside a target project's working directory. All 11 agents hold the `context7` MCP grant for version-accurate library/framework lookups — see `skills/project/reference/context7-usage.md`.
   ```

   Then, in the `## External Integrations` table, change the context7 row from:

   ```markdown
   | context7 | MCP server | Up-to-date library/framework documentation for agents working in target projects |
   ```

   to:

   ```markdown
   | context7 | MCP server | Up-to-date library/framework documentation for agents working in target projects — wired into all 11 agents per `skills/project/reference/context7-usage.md` |
   ```

2. **Verify references.** Confirm `docs/project/architecture.md` contains the literal string `skills/project/reference/context7-usage.md` and the phrase "all 11 agents", and that no other row or section of the External Integrations table was altered.

3. **Commit.**

   ```
   docs(architecture): document full context7 wiring across all 11 agents
   ```

### Task 2: Update docs/project/tech-stack.md and run the consistency check

**Files:**
- Modify: `docs/project/tech-stack.md`

**Interfaces:**
- Consumes: the completed state of all 11 `agents/*.md` files (Phases 2–4) and `skills/project/reference/context7-usage.md` (Phase 1) — verified directly in Step 2 below.
- Produces: an updated AI/LLM Integration row and a new note on deepened stack detection, plus a verified consistency report across all 11 agent files.

**Acceptance Criteria:** AC9, AC10, AC11

**Steps:**

1. **Write content.** In `docs/project/tech-stack.md`, change the context7 row in the `## AI/LLM Integration` table from:

   ```markdown
   | context7 (MCP) | Up-to-date library/framework documentation lookups for agents |
   ```

   to:

   ```markdown
   | context7 (MCP) | Up-to-date library/framework documentation lookups, wired into all 11 agents via `skills/project/reference/context7-usage.md` |
   ```

   Immediately after the `## AI/LLM Integration` table, add one new line of prose:

   ```markdown
   `scanner-agent`'s stack-detection tables cover Django, Flask, Rails, Spring/Spring Boot, Laravel, and ASP.NET/.NET at the same depth as the JS/TS ecosystems (Next.js, Nuxt, Prisma) it already detected — see `agents/scanner-agent.md`.
   ```

2. **Verify references (plan-wide consistency check).** This is the plan's final verification step — it checks the cumulative result of Phases 2–4, not just this task's own edit:

   - Run `grep -l "mcpServers:" agents/*.md` and confirm all 11 files are listed.
   - Run `grep -A2 "mcpServers:" agents/*.md | grep -c "context7"` and confirm the count is 11 (one `context7` entry per agent file).
   - Run `grep -L "context7-usage.md" agents/*.md` (files that do NOT reference it) and confirm the only file listed is `agents/scanner-agent.md`'s peers are all absent from this list except none — i.e. confirm every agent file references `context7-usage.md` (since even `scanner-agent.md` now points to it per Phase 2, Task 2, this list should be empty).
   - Confirm `docs/project/tech-stack.md` contains the literal string `skills/project/reference/context7-usage.md`.

   If any check fails, identify which agent file is missing the grant or the pointer and fix it before committing — do not commit with a failing consistency check.

3. **Commit.**

   ```
   docs(tech-stack): document context7 wiring and deepened stack detection
   ```

---

## Phase 5 Complete

This repo's own dogfooded docs (`docs/project/architecture.md`, `docs/project/tech-stack.md`) accurately describe the finished state: all 11 agents hold the `context7` grant and point to the shared usage doc, and `scanner-agent` detects six additional ecosystems at full depth. The plan-wide consistency check (Task 2, Step 2) confirms no agent was missed.

**Next:** Plan complete.
