# Phase 1: Reference Documentation & Agent Updates

**Repo:** fullstack-dev (`.`)
**Depends on:** None
**Delivers:** All reference docs and the init-agent definition updated to describe code-review-graph as always-on with `.code-review-graphignore` support. After this phase, the plugin's instructions are internally consistent and describe the new behavior — but this repo's own docs/config still reflect the old state.

## File Structure

```
skills/project/reference/
├── tools-setup.md          (modify — add .code-review-graphignore section)
├── init-flow.md            (modify — restructure §9.5/§9.6, update §10.2, add §12 migration)
├── doc-templates.md        (modify — update config schema, generated-files list)
└── refresh-flow.md         (modify — add hook coexistence paragraph)
agents/
└── init-agent.md           (modify — remove opt-in, add always-on setup, update health-check)
```

---

### Task 1: Add `.code-review-graphignore` Configuration to tools-setup.md

**Files:**
- Modify: `skills/project/reference/tools-setup.md`

**Interfaces:**
- Consumes: Existing "code-review-graph MCP Configuration" section and "Hooks Merge Note" in `tools-setup.md` (lines 213-267)
- Produces: New "`.code-review-graphignore` Configuration" section that `init-flow.md` §9.5 will reference for generation logic (Task 2)

**Acceptance Criteria:** Spec § "`.code-review-graphignore` generation logic", § "Marker block format", § "Multi-repo handling", § "Error Handling → `.code-review-graphignore` generation failures"

**Steps:**

- [ ] Read `skills/project/reference/tools-setup.md` to confirm current structure and insertion point (after the Hooks Merge Note, before the Agentation section)
- [ ] Insert a new section titled **"`.code-review-graphignore` Configuration"** after the Hooks Merge Note horizontal rule (after line 267) and before the Agentation section. Include these subsections:

  **Purpose paragraph:** code-review-graph has built-in defaults and auto-respects `.gitignore`, but project-specific extras (docs, plugin metadata, framework caches) need an explicit ignore file. The plugin generates only patterns not covered by the built-in defaults.

  **Built-in defaults list** (what code-review-graph already excludes — for reference, not generated):
  `node_modules/**`, `.git/**`, `__pycache__/**`, `*.pyc`, `.venv/**`, `venv/**`, `dist/**`, `build/**`, `.next/**`, `target/**`, `*.min.js`, `*.min.css`, `*.map`, `*.lock`, `package-lock.json`, `yarn.lock`, `*.db`, `*.sqlite`, `*.db-journal`, `.code-review-graph/**`

  **Minimal defaults** (always included in generated file):
  ```gitignore
  docs/
  .fullstack-dev/
  ```

  **Stack-derived extras table:**

  | Stack signal | Signal source | Extra patterns |
  |---|---|---|
  | `node` or `typescript` | `repos[].stack` contains `"node"` or `"typescript"` | `coverage/`, `.nyc_output/` |
  | `nextjs` | `repos[].stack` contains `"next.js"` | `storybook-static/` |
  | `astro` | `repos[].stack` contains `"astro"` | `.astro/` |
  | `python` | `repos[].stack` contains `"python"` | `.mypy_cache/`, `.pytest_cache/`, `.ruff_cache/`, `htmlcov/` |
  | `iiidev` | `repos[].stack` contains `"iii.dev"` or `"motia"` | `.motia/`, `data/` |
  | `frontend` (any) | `hasFrontend == true` | `storybook-static/`, `.storybook/` |
  | Infrastructure | File-presence: `*.tf` or `docker-compose*` in repo | `.terraform/`, `terraform.tfstate*` |

  **Marker block format:**
  ```gitignore
  # >>> fullstack-dev:code-review-graph (do not edit this block) >>>

  # Project metadata
  docs/
  .fullstack-dev/

  # Node/TypeScript (stack-derived)
  coverage/
  .nyc_output/

  # <<< fullstack-dev:code-review-graph <<<

  # --- User entries below ---
  ```

  **Multi-repo handling:** A single `.code-review-graphignore` is generated at the workspace root. Patterns are the UNION of stack-derived extras across all `repos[].stack` entries. Root-relative patterns apply to all sub-repos. No per-sub-repo ignore files.

  **Data dependency:** Generation runs AFTER `.gitignore` generation (§9.2) because it reads `gitIgnore.activeCategories`.

  **Merge rules** (identical to `.gitignore` merge semantics):
  - No `.code-review-graphignore` exists → create with full marker block
  - File exists without marker block → prepend marker block, preserve existing content below
  - Marker block exists → replace content between markers only, preserve user content outside
  - If `gitIgnore.activeCategories` is empty or missing → fall back to minimal defaults only

- [ ] Verify the new section does not duplicate content already in the "code-review-graph MCP Configuration" section (MCP entry and hooks stay in the existing section; ignore file config is new)
- [ ] Commit: `docs(tools-setup): add .code-review-graphignore configuration section`

---

### Task 2: Restructure init-flow.md §9.5, §9.6, and §9.13

**Files:**
- Modify: `skills/project/reference/init-flow.md`

**Interfaces:**
- Consumes: `.code-review-graphignore` Configuration section in `tools-setup.md` (Task 1)
- Consumes: Existing §9.5 `.mcp.json` content (lines 425-449), §9.6 Optional Developer Tools content (lines 452-489), §9.13 completion report (lines 598-626)
- Produces: Restructured §9.5 "MCP Setup" and §9.6 "Optional Tools" sections that `init-agent.md` will follow (Task 7)

**Acceptance Criteria:** Spec § "Architecture → Layer 1: Init Flow", § "Data Flow → First-run flow", § "File Changes → init-flow.md" (restructure §9.5/§9.6, completion report)

**Steps:**

- [ ] Read `skills/project/reference/init-flow.md` lines 425-489 (§9.5 and §9.6) and lines 598-626 (§9.13)
- [ ] Replace §9.5 titled `### 9.5 \`.mcp.json\`` with a new section titled `### 9.5 MCP Setup`. The new section keeps the existing context7 and git platform MCP subsections unchanged, then adds a **code-review-graph** subsection with three sub-steps:

  1. **Merge into `.mcp.json`:**
     ```json
     {"command":"uvx","args":["code-review-graph","mcp","--repo","."]}
     ```
  2. **Merge hooks into `.claude/settings.json`:**
     - PostToolUse: `uvx code-review-graph update --skip-flows --repo .` (matcher: `Edit|Write|Bash|PowerShell`, timeout: 30000)
     - SessionStart: `uvx code-review-graph status --repo .` (timeout: 10000)
  3. **Generate `.code-review-graphignore`:**
     - Read `repos[].stack` + `gitIgnore.activeCategories` from config
     - Filter to extras NOT covered by built-in defaults (per `reference/tools-setup.md` § "`.code-review-graphignore` Configuration")
     - Write file with `fullstack-dev:code-review-graph` marker block
     - Data dependency note: runs AFTER §9.2 `.gitignore` generation

  Note the Hooks Merge Note reference: code-review-graph PostToolUse hook (matcher `Edit|Write|Bash|PowerShell`) coexists alongside the fullstack-dev doc-staging PostToolUse hook (matcher `Edit|Write`).

- [ ] Replace §9.6 titled `### 9.6 Optional Developer Tools` with `### 9.6 Optional Tools`. Remove the code-review-graph option entirely. Keep only the Agentation prompt, shown only when `projectType` is `fullstack` or `frontend`. The store instruction becomes: `optionalTools.agentation` (boolean). Remove `optionalTools.codeReviewGraph` from the store instructions.
- [ ] In §9.13 completion report (the "Files created:" list), add `.code-review-graphignore` as a new line after `.gitignore`:
  ```
    .code-review-graphignore
  ```
- [ ] Verify: §9.5 references `reference/tools-setup.md` for code-review-graph MCP config details and `.code-review-graphignore` generation details. §9.6 no longer mentions code-review-graph. §9.13 lists the new file.
- [ ] Commit: `docs(init-flow): restructure §9.5 as unified MCP setup, shrink §9.6 to Agentation only`

---

### Task 3: Update init-flow.md §10.2 Health Check Table

**Files:**
- Modify: `skills/project/reference/init-flow.md`

**Interfaces:**
- Consumes: Updated §9.5 MCP Setup section (Task 2) — health checks must match the init flow
- Produces: Updated health check table that `init-agent.md` health-check section will follow (Task 7)

**Acceptance Criteria:** Spec § "Architecture → Layer 2: Health Check", § "Data Flow → Subsequent-run flow"

**Steps:**

- [ ] Read `skills/project/reference/init-flow.md` lines 648-683 (§10.2 health check table)
- [ ] Move the two code-review-graph rows from the `Developer Tools` category into the `MCP` category (after the existing MCP rows). Split the hooks check into two separate rows (PostToolUse and SessionStart). Add two new rows for `.code-review-graphignore`. The new MCP rows (appended after `Required MCP env vars present in settings.local.json`):

  ```
  MCP               | code-review-graph entry in .mcp.json              | Yes (add entry)
                    | code-review-graph PostToolUse hook in settings.json | Yes (merge hook)
                    | code-review-graph SessionStart hook in settings.json | Yes (merge hook)
                    | .code-review-graphignore exists with marker block  | Yes (generate)
                    | .code-review-graphignore patterns match current tech stack | Yes (regenerate marker block)
  ```

- [ ] Reduce the `Developer Tools` category to a single row:
  ```
  Developer Tools   | Agentation in .mcp.json (if frontend)            | Yes (add entry)
  ```
- [ ] Verify the table is well-formed (aligned columns, no orphaned rows from the old Developer Tools section)
- [ ] Commit: `docs(init-flow): move code-review-graph to MCP category in §10.2 health check`

---

### Task 4: Add Version 1.1.0 Migration to init-flow.md §12

**Files:**
- Modify: `skills/project/reference/init-flow.md`

**Interfaces:**
- Consumes: Updated §10.2 health check table (Task 3) — migration must produce state that passes the new checks
- Produces: Version 1.1.0 migration logic for `init-agent.md` to follow (Task 7)

**Acceptance Criteria:** Spec § "Migration (init-flow.md §12)", § "Testing Strategy → Migration verification"

**Steps:**

- [ ] Read `skills/project/reference/init-flow.md` lines 770-806 (§12 Version Migration)
- [ ] After the existing §12.2 Migration report subsection, add a new subsection `### 12.3 Version-Specific Migrations` with a `1.0.0 → 1.1.0` entry:

  **1.0.0 → 1.1.0: code-review-graph always-on**
  - Add code-review-graph `.mcp.json` entry (merge, skip if already present)
  - Add code-review-graph PostToolUse and SessionStart hooks to `.claude/settings.json` (merge alongside existing hooks)
  - Generate `.code-review-graphignore` with marker block (per `reference/tools-setup.md`)
  - Remove `optionalTools.codeReviewGraph` from `config.json` regardless of its prior value (`true` or `false`). The `optionalTools` object remains with only `agentation: boolean`.
  - Projects that previously had `codeReviewGraph: false` get code-review-graph added — intentional, since it is now always-on.
  - Completion report note: "Added code-review-graph (now standard)."

- [ ] Verify the migration steps align with the §10.2 health check rows (Task 3) — after migration, all new MCP checks should PASS
- [ ] Commit: `docs(init-flow): add version 1.1.0 migration for code-review-graph always-on`

---

### Task 5: Update doc-templates.md Config Schema and Generated-Files List

**Files:**
- Modify: `skills/project/reference/doc-templates.md`

**Interfaces:**
- Consumes: Updated §9.5/§9.6 from `init-flow.md` (Task 2) — config schema must reflect the removal of `codeReviewGraph` and retention of `agentation`
- Produces: Updated Field Reference table and generated-files list that serve as the authoritative schema documentation

**Acceptance Criteria:** Spec § "File Changes → doc-templates.md"

**Steps:**

- [ ] Read `skills/project/reference/doc-templates.md` lines 519-604 (Section 7: `.fullstack-dev/config.json` schema and Field Reference table)
- [ ] Add `optionalTools.agentation` to the Field Reference table (it was previously missing). Insert after the `gitIgnore.categoriesEverActivated` row:

  | `optionalTools` | object | no | Optional developer tool configuration. |
  | `optionalTools.agentation` | boolean | -- | Whether Agentation was configured during init. Only relevant when `projectType` includes frontend. |

  Do NOT add `optionalTools.codeReviewGraph` — it is removed from the schema.

- [ ] In the Template File Creation Order (Section 9, lines 706-719), add `.code-review-graphignore` after `.gitignore` (item 3). Renumber subsequent items:

  ```
  3. `.gitignore` -- before any git operations
  4. `.code-review-graphignore` -- after .gitignore (needs gitIgnore.activeCategories)
  5. `*.code-workspace` -- workspace file (multi-repo only)
  ...
  ```

- [ ] Verify no stale references to `optionalTools.codeReviewGraph` remain in the file
- [ ] Commit: `docs(doc-templates): add optionalTools.agentation field, add .code-review-graphignore to creation order`

---

### Task 6: Add Hook Coexistence Paragraph to refresh-flow.md

**Files:**
- Modify: `skills/project/reference/refresh-flow.md`

**Interfaces:**
- Consumes: Hooks Merge Note in `tools-setup.md` (existing, lines 260-267) — the two PostToolUse hooks with different matchers
- Produces: Documentation of hook coexistence in the refresh mechanism context

**Acceptance Criteria:** Spec § "File Changes → refresh-flow.md"

**Steps:**

- [ ] Read `skills/project/reference/refresh-flow.md` lines 18-36 (Layer 1: PostToolUse Hook section)
- [ ] Add a new paragraph after the existing Layer 1 section content (after line 36, before the `---` separator leading to Layer 2). Title it **"Hook Coexistence"** and explain:

  Two PostToolUse hooks fire during Claude sessions in managed projects:
  1. **Fullstack-dev doc-staging hook** — matcher `Edit|Write`, echoes a reminder to update docs (instant, ~1s timeout)
  2. **code-review-graph update hook** — matcher `Edit|Write|Bash|PowerShell`, runs `uvx code-review-graph update --skip-flows --repo .` to keep the graph current (30s timeout)

  The code-review-graph hook has a broader matcher (includes `Bash` and `PowerShell`). Both fire on `Edit`/`Write` operations — this is intentional. The echo hook is instant, and the graph update runs in parallel. Neither hook depends on or interferes with the other.

  This coexistence is a documentation note for the refresh mechanism. Health checks for both hooks are defined in `init-flow.md` §10.2 (doc-staging under Claude Config, code-review-graph under MCP).

- [ ] Verify the paragraph does not duplicate the Hooks Merge Note in `tools-setup.md` — that note covers merge mechanics; this paragraph covers runtime coexistence in the refresh context
- [ ] Commit: `docs(refresh-flow): document code-review-graph hook coexistence in Layer 1`

---

### Task 7: Update init-agent.md for Always-On Behavior

**Files:**
- Modify: `agents/init-agent.md`

**Interfaces:**
- Consumes: Updated §9.5 MCP Setup in `init-flow.md` (Task 2)
- Consumes: Updated §10.2 health check table in `init-flow.md` (Task 3)
- Consumes: Updated §12 migration in `init-flow.md` (Task 4)
- Produces: Agent definition that implements the new always-on init flow and health-check behavior

**Acceptance Criteria:** Spec § "File Changes → init-agent.md", § "Testing Strategy → First-run verification", § "Testing Strategy → Health-check verification"

**Steps:**

- [ ] Read `agents/init-agent.md` lines 73-87 (Phase 3a: Optional Developer Tools)
- [ ] Replace Phase 3a. Remove the code-review-graph opt-in prompt entirely. Rename the section to **"Phase 3a: Optional Tools"**. Keep only the Agentation prompt (shown only for `projectType` `fullstack` or `frontend`). Update the store instruction to only store `optionalTools.agentation` (boolean). Remove point 4 about storing `optionalTools.codeReviewGraph`.
- [ ] In Phase 5: Configuration — Generate All Files, update the subsection that handles `.mcp.json` (§5.11, lines 195-197). After the git platform MCP merge step, add a new step for code-review-graph as always-on:

  **5.11b code-review-graph (always-on)**
  - Merge code-review-graph entry into `.mcp.json` per `reference/tools-setup.md` § "code-review-graph MCP Configuration"
  - Merge PostToolUse and SessionStart hooks into `.claude/settings.json` per `reference/tools-setup.md` § "Hooks" and "Hooks Merge Note"
  - Generate `.code-review-graphignore` per `reference/tools-setup.md` § "`.code-review-graphignore` Configuration":
    - Read `repos[].stack` + `gitIgnore.activeCategories` from config
    - Compute stack-derived extras from the stack table
    - Write file with `fullstack-dev:code-review-graph` marker block
    - Apply merge rules (create / prepend / replace within markers)
  - Data dependency: runs AFTER §5.3 `.gitignore` generation

- [ ] In the Health Check Flow section (Step 3, lines 295-303), update the health check table summary. Replace the `Optional Tools` category:

  Old:
  ```
  | **Optional Tools** | code-review-graph: `.mcp.json` entry exists, `.claude/settings.json` has PostToolUse hook...; Agentation: ... |
  ```

  New — move code-review-graph checks into the **MCP** category row:
  ```
  | **MCP** | ...existing MCP checks...; code-review-graph entry in `.mcp.json`; code-review-graph PostToolUse hook in `settings.json`; code-review-graph SessionStart hook in `settings.json`; `.code-review-graphignore` exists with marker block; `.code-review-graphignore` patterns match current tech stack |
  | **Developer Tools** | Agentation: `.mcp.json` entry exists (only check if `projectType` is `fullstack` or `frontend`). Auto-fix: offer to configure if not present |
  ```

- [ ] Verify no remaining references to `optionalTools.codeReviewGraph` in the agent definition
- [ ] Commit: `feat(init-agent): promote code-review-graph to always-on, add .code-review-graphignore generation`

---

## Phase 1 Complete

After this phase, all reference documentation and the init-agent definition describe code-review-graph as always-on:
- `tools-setup.md` has the `.code-review-graphignore` Configuration section with marker format, stack table, and merge rules
- `init-flow.md` §9.5 configures code-review-graph as part of MCP Setup (not optional), §9.6 offers only Agentation, §10.2 health checks cover code-review-graph under MCP, §12 has the 1.1.0 migration
- `doc-templates.md` has `optionalTools.agentation` in the Field Reference and `.code-review-graphignore` in the creation order
- `refresh-flow.md` documents hook coexistence
- `init-agent.md` implements the new flow end-to-end

**Next:** `phase-2.md`
