# Phase 3: Update Documentation & Reference Content

**Repo:** fullstack-dev (path `.`)
**Depends on:** Phase 1 (Task 2 of this phase edits the agent file at its new location); Phase 2 (dispatch mechanism is stable before docs describe it)
**Delivers:** `refresh-flow.md` no longer claims the deleted `scripts/pre-commit.sh` is copied at init; the init-agent health-check table no longer double-counts "commands installed"; `context7-usage.md`, `CLAUDE.md`, `CONTEXT.md`, `ARCHITECTURE.md`, `docs/project/architecture.md`, and `docs/project/tech-stack.md` all describe the new `skills/*/agents/` structure.

## File Structure

```
skills/project/reference/refresh-flow.md      [modify] remove stale pre-commit.sh copy claim
skills/project/agents/init-agent.md            [modify] health-check table
skills/project/reference/context7-usage.md     [modify] agent name references + skill location
CLAUDE.md                                      [modify] repo structure list
CONTEXT.md                                     [modify] domain model + naming convention
ARCHITECTURE.md                                [modify] directory tree + module table
docs/project/architecture.md                   [modify] service map table
docs/project/tech-stack.md                     [modify] remove scripts/hooks references
```

---

### Task 1: Remove stale pre-commit.sh copy claim from refresh-flow.md

**Files:**
- Modify: `skills/project/reference/refresh-flow.md`

**Interfaces:**
- Consumes: `scripts/pre-commit.sh`'s deletion in Phase 1 Task 7 (the claim being removed describes a file that no longer exists at that path)
- Produces: corrected prose, consumed by Phase 4 Task 1 verification

**Acceptance Criteria:** Spec checkbox "`skills/project/reference/refresh-flow.md` no longer claims `scripts/pre-commit.sh` is copied to `.git/hooks`".

**Steps:**
1. In `skills/project/reference/refresh-flow.md` line 52, replace:
   ```
   `scripts/pre-commit.sh` is copied to `.git/hooks/pre-commit` during project init. Its only job is to stage already-refreshed doc files into the current commit.
   ```
   with:
   ```
   The pre-commit hook is generated inline by the init-agent (see `init-flow.md` §9.8) and written directly to `.git/hooks/pre-commit` during project init. Its only job is to stage already-refreshed doc files into the current commit.
   ```
2. Verify: `grep -n "scripts/pre-commit.sh" skills/project/reference/refresh-flow.md` returns zero matches.
3. Commit: `docs(project): remove stale pre-commit.sh copy claim from refresh-flow`

---

### Task 2: Fix init-agent.md health-check table

**Files:**
- Modify: `skills/project/agents/init-agent.md`

**Interfaces:**
- Consumes: Phase 1 Task 1 Produces (`skills/project/agents/init-agent.md` exists at its new path)
- Produces: corrected Claude Config health-check row, consumed by Phase 4 Task 1 verification

**Acceptance Criteria:** Spec checkbox "Health-check table in init-agent (now at `skills/project/agents/init-agent.md`) has \"; commands installed\" removed from the Claude Config row".

**Steps:**
1. In `skills/project/agents/init-agent.md`, replace:
   ```
   | **Claude Config** | .claude/settings.json exists; PostToolUse hooks configured; skills installed; commands installed |
   ```
   with:
   ```
   | **Claude Config** | .claude/settings.json exists; PostToolUse hooks configured; skills installed |
   ```
   (commands are not a separate install artifact — they are invoked via the `Skill` tool, not installed as standalone files.)
2. Verify: `grep -n "commands installed" skills/project/agents/init-agent.md` returns zero matches.
3. Commit: `fix(project): remove redundant commands-installed check from health table`

---

### Task 3: Update context7-usage.md agent references with skill locations

**Files:**
- Modify: `skills/project/reference/context7-usage.md`

**Interfaces:**
- Consumes: Phase 1 Tasks 5, 6, 3 Produces (`skills/debug/agents/debugger-agent.md`, `skills/refactor/agents/refactor-agent.md`, `skills/brainstorm/agents/grill-agent.md` exist)
- Produces: agent references annotated with their new skill directory, consumed by Phase 4 Task 1 verification

**Acceptance Criteria:** Spec checkbox "`skills/project/reference/context7-usage.md` updated with skill-relative agent locations".

**Steps:**
1. In the "### Per-Instance Budgets for Parallel Dispatch" section, replace:
   ```
   `debugger-agent` and `refactor-agent` are dispatched once per investigation
   dimension (up to 5 and 4 parallel instances respectively) as part of
   `/debug` and `/refactor`'s normal parallel-evidence-gathering flow. A single
   user question can therefore fan out to several times the per-instance
   budget in aggregate. To avoid this:

   - `debugger-agent` reserves context7 calls for the `dependencies` dimension
     only. Do not query context7 when investigating `stack-trace`,
     `git-blame`, `tests`, or `patterns`.
   - `refactor-agent` reserves context7 calls for the `dependencies` and
     `patterns` dimensions only. Do not query context7 when investigating
     `metrics` or `tests`.
   ```
   with:
   ```
   `debugger-agent` (in `skills/debug/agents/`) and `refactor-agent` (in
   `skills/refactor/agents/`) are dispatched once per investigation
   dimension (up to 5 and 4 parallel instances respectively) as part of
   `/debug` and `/refactor`'s normal parallel-evidence-gathering flow. A single
   user question can therefore fan out to several times the per-instance
   budget in aggregate. To avoid this:

   - `debugger-agent` (in `skills/debug/agents/`) reserves context7 calls for
     the `dependencies` dimension only. Do not query context7 when
     investigating `stack-trace`, `git-blame`, `tests`, or `patterns`.
   - `refactor-agent` (in `skills/refactor/agents/`) reserves context7 calls
     for the `dependencies` and `patterns` dimensions only. Do not query
     context7 when investigating `metrics` or `tests`.
   ```
2. In the "When context7 Is Unavailable or Insufficient" section, replace:
   ```
   No agent has a
   `WebSearch` grant to fall back to (only `grill-agent` has `WebFetch`,
   scoped to a specific known URL) -- do not suggest general web search as
   a substitute.
   ```
   with:
   ```
   No agent has a
   `WebSearch` grant to fall back to (only `grill-agent`, in
   `skills/brainstorm/agents/`, has `WebFetch`, scoped to a specific known
   URL) -- do not suggest general web search as a substitute.
   ```
3. Verify: `grep -n "skills/debug/agents/\|skills/refactor/agents/\|skills/brainstorm/agents/" skills/project/reference/context7-usage.md` returns three matches.
4. Commit: `docs(project): annotate context7-usage agent references with skill locations`

---

### Task 4: Update CLAUDE.md repo structure

**Files:**
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: Phase 1 Task 7 Produces (top-level `agents/`, `hooks/`, `scripts/` no longer exist)
- Produces: accurate repo structure list, consumed by Phase 4 Task 1 verification

**Acceptance Criteria:** Spec checkbox "`CLAUDE.md`, `CONTEXT.md`, `ARCHITECTURE.md`, `docs/project/architecture.md`, `docs/project/tech-stack.md` updated to reflect new structure" (CLAUDE.md subset).

**Steps:**
1. Within the `<!-- fullstack-dev:start -->` / `<!-- fullstack-dev:end -->` marker block, in the "### Repos" section, replace:
   ```
   ### Repos

   This is a mono-repo. Key directories:
   - **`agents/`** -- Subagent definitions dispatched by skills/commands
   - **`commands/`** -- Slash command entry points
   - **`skills/`** -- SKILL.md orchestrators + reference docs, one directory per command area
   - **`hooks/`** -- Hook definitions shipped with the plugin
   - **`scripts/`** -- Template scripts (e.g. pre-commit hook) installed into managed projects
   - **`docs/`** -- This project's own generated docs (project/, specs/, plans/)
   ```
   with:
   ```
   ### Repos

   This is a mono-repo. Key directories:
   - **`commands/`** -- Slash command entry points
   - **`skills/`** -- SKILL.md orchestrators + reference docs + `agents/` subdirectory (subagent definitions dispatched by that skill), one directory per command area
   - **`docs/`** -- This project's own generated docs (project/, specs/, plans/)
   ```
2. Verify: `grep -n '`agents/`\|`hooks/`\|`scripts/`' CLAUDE.md` returns zero matches (the bare top-level bullets are gone; `skills/*/agents/`-style mentions elsewhere in the file, if any, are unaffected since they don't match this exact bullet pattern).
3. Commit: `docs: update CLAUDE.md repo structure for self-contained skill packaging`

---

### Task 5: Update CONTEXT.md domain model and naming conventions

**Files:**
- Modify: `CONTEXT.md`

**Interfaces:**
- Consumes: Phase 1 Produces (all `skills/*/agents/*.md` paths now exist)
- Produces: accurate Entities and Naming tables, consumed by Phase 4 Task 1 verification

**Acceptance Criteria:** Spec checkbox "...updated to reflect new structure" (CONTEXT.md subset).

**Steps:**
1. In the "### Entities" table, replace:
   ```
   | Agent | A specialized Claude Code subagent (e.g. `init-agent`, `debugger-agent`) with its own tools, model, and prompt | `agents/*.md` |
   ```
   with:
   ```
   | Agent | A specialized Claude Code subagent (e.g. `init-agent`, `debugger-agent`) with its own tools, model, and prompt | `skills/<owning-skill>/agents/*.md` |
   ```
2. In the "### Naming" table, replace:
   ```
   | Agent files | `<role>-agent.md` in `agents/` | `init-agent.md`, `debugger-agent.md` |
   ```
   with:
   ```
   | Agent files | `<role>-agent.md` in `skills/<owning-skill>/agents/` | `skills/project/agents/init-agent.md`, `skills/debug/agents/debugger-agent.md` |
   ```
3. Verify: `grep -n '`agents/\*\.md`\|in .agents/.' CONTEXT.md` returns zero matches for the old bare-`agents/` form.
4. Commit: `docs: update CONTEXT.md domain model for self-contained skill packaging`

---

### Task 6: Update ARCHITECTURE.md directory tree and dispatch example

**Files:**
- Modify: `ARCHITECTURE.md`

**Interfaces:**
- Consumes: Phase 1 Produces (all relocations and deletions complete)
- Produces: accurate directory tree and dispatch example, consumed by Phase 4 Task 1 verification

**Acceptance Criteria:** Spec checkbox "...updated to reflect new structure" (ARCHITECTURE.md subset).

**Steps:**
1. In the "## Directory Structure" fenced tree, replace:
   ```
   fullstack-dev/
   ├── agents/          # Subagent definitions (init, scanner, refresh, repo, implementer, task-reviewer, security-reviewer, plan-reviewer, debugger, refactor, grill)
   ├── commands/         # Slash command entry points (/project, /brainstorm, /plan, /implement, /debug, /fix, /refactor, /git, /gitignore)
   ├── skills/           # SKILL.md orchestrators + reference/ decision trees & templates, one directory per command area
   ├── hooks/            # hooks.json — hook definitions shipped with the plugin
   ├── scripts/          # pre-commit.sh — template pre-commit hook installed into managed projects
   ├── .agents/          # Local skills-add installed copy of agents (managed by the skills CLI)
   ├── .claude/          # Local skills-add installed copy of skills (managed by the skills CLI)
   ├── docs/             # This project's own generated docs (project/, specs/, plans/) — dogfooding the plugin on itself
   ├── LICENSE
   ├── README.md
   └── skills-lock.json  # Lockfile for `npx skills add` installs
   ```
   with:
   ```
   fullstack-dev/
   ├── commands/         # Slash command entry points (/project, /brainstorm, /plan, /implement, /debug, /fix, /refactor, /git, /gitignore)
   ├── skills/           # SKILL.md orchestrators + reference/ decision trees & templates + agents/ subdirectory (init, scanner, refresh, repo, implementer, task-reviewer, security-reviewer, plan-reviewer, debugger, refactor, grill), one directory per command area
   ├── .agents/          # Local skills-add installed copy of agents (managed by the skills CLI)
   ├── .claude/          # Local skills-add installed copy of skills (managed by the skills CLI)
   ├── docs/             # This project's own generated docs (project/, specs/, plans/) — dogfooding the plugin on itself
   ├── LICENSE
   ├── README.md
   └── skills-lock.json  # Lockfile for `npx skills add` installs
   ```
2. In the "Command → Skill → Agent dispatch" example, replace:
   ```
   commands/project.md  -->  skills/project/SKILL.md  -->  Agent(init-agent)
                                                        -->  agents/init-agent.md reads skills/project/reference/*.md
   ```
   with:
   ```
   commands/project.md  -->  skills/project/SKILL.md  -->  Agent(init-agent)
                                                        -->  skills/project/agents/init-agent.md reads skills/project/reference/*.md
   ```
3. Verify: `grep -n '^├── agents/\|^├── hooks/\|^├── scripts/' ARCHITECTURE.md` returns zero matches.
4. Commit: `docs: update ARCHITECTURE.md directory tree for self-contained skill packaging`

---

### Task 7: Update docs/project/architecture.md service map

**Files:**
- Modify: `docs/project/architecture.md`

**Interfaces:**
- Consumes: Phase 1 Produces (all relocations and deletions complete)
- Produces: accurate Service Map table and Agents section, consumed by Phase 4 Task 1 verification

**Acceptance Criteria:** Spec checkbox "...updated to reflect new structure" (docs/project/architecture.md subset); spec's File Changes note "Update service map table: agents under `skills/*/agents/`, remove Scripts and Hooks rows".

**Steps:**
1. In the "### Service Map" table, replace:
   ```
   | Module | Directory | Tech | Role |
   |---|---|---|---|
   | Commands | `commands/` | Markdown | Slash-command entry points (`/project`, `/brainstorm`, `/plan`, `/implement`, `/debug`, `/fix`, `/refactor`, `/git`, `/gitignore`) |
   | Skills | `skills/` | Markdown (`SKILL.md` + `reference/`) | Orchestration layer + authoritative decision trees/templates per command |
   | Agents | `agents/` | Markdown | Specialized subagents dispatched by skills/commands (init, scanner, refresh, repo, implementer, task-reviewer, security-reviewer, plan-reviewer, debugger, refactor, grill) |
   | Hooks | `hooks/hooks.json`, `.claude/settings.json` | JSON | PostToolUse/SessionStart hooks installed into managed projects |
   | Scripts | `scripts/pre-commit.sh` | Bash | Template for the doc-staging pre-commit hook installed into managed projects |
   ```
   with:
   ```
   | Module | Directory | Tech | Role |
   |---|---|---|---|
   | Commands | `commands/` | Markdown | Slash-command entry points (`/project`, `/brainstorm`, `/plan`, `/implement`, `/debug`, `/fix`, `/refactor`, `/git`, `/gitignore`) |
   | Skills | `skills/` | Markdown (`SKILL.md` + `reference/`) | Orchestration layer + authoritative decision trees/templates per command |
   | Agents | `skills/*/agents/` | Markdown | Specialized subagents dispatched by their owning skill (init, scanner, refresh, repo, implementer, task-reviewer, security-reviewer, plan-reviewer, debugger, refactor, grill) |
   ```
2. In the "### Agents (`agents/`)" subsection, replace the heading and **Repo:** line:
   ```
   ### Agents (`agents/`)

   - **Repo:** `agents/*.md`
   ```
   with:
   ```
   ### Agents (`skills/*/agents/`)

   - **Repo:** `skills/<owning-skill>/agents/*.md`
   ```
   (leave the **Purpose:**, **Tech:**, and **Communication:** lines beneath it unchanged — their content already describes behavior, not the old path.)
3. Verify: `grep -n "^| Hooks \|^| Scripts \|\`agents/\*\.md\`" docs/project/architecture.md` returns zero matches.
4. Commit: `docs(project): update service map for self-contained skill packaging`

---

### Task 8: Update docs/project/tech-stack.md

**Files:**
- Modify: `docs/project/tech-stack.md`

**Interfaces:**
- Consumes: Phase 1 Task 7 Produces (`scripts/pre-commit.sh` and `hooks/hooks.json` no longer exist)
- Produces: accurate tech-stack references, consumed by Phase 4 Task 1 verification

**Acceptance Criteria:** Spec checkbox "...updated to reflect new structure" (docs/project/tech-stack.md subset); spec's File Changes note "Remove `scripts/pre-commit.sh` and `hooks/hooks.json` references".

**Steps:**
1. In the "## Languages & Frameworks" table, replace:
   ```
   | Markdown | — | `agents/`, `commands/`, `skills/` | Agent prompts, command definitions, skill instructions/reference docs |
   | Bash / POSIX sh | — | `scripts/pre-commit.sh`, `.git/hooks/pre-commit` | Pre-commit hooks (doc staging, gitignore enforcement) |
   | JSON | — | `hooks/hooks.json`, `.claude/settings.json`, `.mcp.json`, `.fullstack-dev/config.json` | Hook configuration, MCP server configuration, plugin state |
   ```
   with:
   ```
   | Markdown | — | `commands/`, `skills/` (including `skills/*/agents/`) | Agent prompts, command definitions, skill instructions/reference docs |
   | Bash / POSIX sh | — | `.git/hooks/pre-commit` | Pre-commit hooks (doc staging, gitignore enforcement), generated inline by the init-agent |
   | JSON | — | `.claude/settings.json`, `.mcp.json`, `.fullstack-dev/config.json` | Hook configuration, MCP server configuration, plugin state |
   ```
2. In the "## AI/LLM Integration" section, replace:
   ```
   `scanner-agent`'s stack-detection tables cover Django, Flask, Rails, Spring/Spring Boot, Laravel, and ASP.NET/.NET at the same depth as the JS/TS ecosystems (Next.js, Nuxt, Prisma) it already detected — see `agents/scanner-agent.md`.
   ```
   with:
   ```
   `scanner-agent`'s stack-detection tables cover Django, Flask, Rails, Spring/Spring Boot, Laravel, and ASP.NET/.NET at the same depth as the JS/TS ecosystems (Next.js, Nuxt, Prisma) it already detected — see `skills/project/agents/scanner-agent.md`.
   ```
3. Verify: `grep -n "scripts/pre-commit.sh\|hooks/hooks.json\|see \`agents/scanner-agent.md\`" docs/project/tech-stack.md` returns zero matches.
4. Commit: `docs: update tech-stack.md for self-contained skill packaging`

## Phase 3 Complete

All project documentation (`CLAUDE.md`, `CONTEXT.md`, `ARCHITECTURE.md`, `docs/project/architecture.md`, `docs/project/tech-stack.md`) and the two flagged reference docs (`refresh-flow.md`, `context7-usage.md`) accurately describe the post-restructure layout. The init-agent's own health-check table no longer double-counts commands. Only lockfile regeneration and end-to-end verification remain.

**Next:** `phase-4.md`
