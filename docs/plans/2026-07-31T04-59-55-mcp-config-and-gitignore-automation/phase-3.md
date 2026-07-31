# Phase 3: Skills-CLI & IDE/Secrets Gitignore Categories

**Repo:** fullstack-dev
**Depends on:** Phase 2 (sequential plan ordering; this phase's content is independent of Phases 1-2's MCP work, but executes after per the plan's dependency convention)
**Delivers:** `gitignore-catalog.md` gains a new `skills-cli` category (workspace-root `skills-lock.json` detection, `.claude/skills/` + `.agents/` patterns, no fallback by design) plus `.claude/settings.local.json` in `secrets` and `*.code-workspace` in `ide`. `gitignore-flow.md` documents the detection rule, sort-order position, and the first-activation mirror-diff/mtime warning logic for both the self-hosting and general target-project cases.

## File Structure

```
skills/gitignore/reference/
├── gitignore-catalog.md   # modify: new category, secrets/ide patterns, selection logic, sort order
└── gitignore-flow.md      # modify: structural rules order, detection heuristics, cleanup logic
```

### Task 1: Add the Skills CLI category section to gitignore-catalog.md

**Files:**
- Modify: `skills/gitignore/reference/gitignore-catalog.md`

**Interfaces:**
- Consumes: none
- Produces: the `skills-cli` category definition (Key/Detect/Always-active/Patterns), consumed by Task 3 (selection logic + sort order) and by Phase 4 Task 3 (live rebuild on this repo)

**Acceptance Criteria:** "gitignore-catalog.md has a new skills-cli category, detected by skills-lock.json at the workspace root only, covering .claude/skills/ (precisely scoped) and .agents/ (whole directory), with no file-detection fallback."

**Steps (Documentation: Write-and-review):**

1. **Write content.** Insert a new category section immediately after `## MCP Tooling` (current lines 263-278) and before `## Deployment` (current line 281):

   ````markdown
   ---

   ## Skills CLI

   **Key:** `skills-cli`
   **Detect:** `skills-lock.json` exists at the **workspace root only** (not per sub-repo — `.claude/skills/` and `.agents/` are Claude Code session artifacts, not per-repo source artifacts; a Claude Code session, and therefore `npx skills add`, operates from the workspace root regardless of `repoStructure`, the same way `.mcp.json` and `.claude/settings.json` are already workspace-root-level singletons in this plugin's model)
   **Always active:** No
   **Fallback:** None — unlike every other category, this one has no file-detection fallback. `skills-lock.json` is the one reliable, unambiguous signal that `npx skills add` manages this workspace; a heuristic fallback (e.g. guessing from directory contents) risks false positives on hand-authored `.claude/` trees. This is an intentional deviation from the catalog's usual config-plus-fallback pattern, not an oversight.

   **Patterns:**

   ```gitignore
   .claude/skills/
   .agents/
   ```

   `.claude/skills/` is precisely scoped to that one subpath — never a wildcard on `.claude/*` — because `.claude/` is known to hold hand-authored content (`settings.json`, `settings.local.json`) alongside generated content. `.agents/` is ignored as a whole directory because it currently holds nothing but the generated skills mirror; a wholesale pattern self-extends if `npx skills add` ever mirrors other content there, at the accepted trade-off that any future hand-authored content placed directly under `.agents/` would be unexpectedly ignored too.

   ---
   ````

2. **Verify references.** The new section sits between `## MCP Tooling` and `## Deployment`, matching the intended catalog position (Task 3 will confirm this also matches the numbered sort order).

3. **Commit:** `docs(gitignore-catalog): add Skills CLI category`

---

### Task 2: Add settings.local.json to secrets category; add *.code-workspace to ide category

**Files:**
- Modify: `skills/gitignore/reference/gitignore-catalog.md`

**Interfaces:**
- Consumes: none
- Produces: none

**Acceptance Criteria:** "gitignore-catalog.md's secrets category includes .claude/settings.local.json; its ide category includes *.code-workspace."

**Steps (Documentation: Write-and-review):**

1. **Write content, part A — `## Secrets` (current lines 27-43).** Add `.claude/settings.local.json` to the patterns block:

   ```gitignore
   .env
   .env.local
   .env.*.local
   .env.production
   *.pem
   credentials.json
   serviceAccountKey.json
   .claude/settings.local.json
   ```

2. **Write content, part B — `## IDE` (current lines 188-207).** Add `*.code-workspace` to the patterns block, alongside the existing `.vscode/*` entries:

   ```gitignore
   .idea/
   *.iws
   *.iml
   *.ipr
   .vscode/*
   !.vscode/settings.json
   !.vscode/tasks.json
   !.vscode/launch.json
   !.vscode/extensions.json
   *.vsix
   *.code-workspace
   ```

3. **Verify references.** Both categories remain `Always active: Yes` (no change to their `Detect`/`Always active` fields — only new pattern lines added).

4. **Commit:** `docs(gitignore-catalog): add settings.local.json to secrets, *.code-workspace to ide`

---

### Task 3: Update Pattern Selection Logic and Category Sort Order for skills-cli

**Files:**
- Modify: `skills/gitignore/reference/gitignore-catalog.md`

**Interfaces:**
- Consumes: the `skills-cli` category from Task 1
- Produces: the finalized sort position, consumed by Task 4 (mirrors this same ordering in `gitignore-flow.md` Section 1)

**Acceptance Criteria:** (supports the `skills-cli` category acceptance criterion above — this task wires the category into the two ordering/logic sections that reference every category by name.)

**Steps (Documentation: Write-and-review):**

1. **Write content, part A — `## Pattern Selection Logic` (current lines 297-311).** Add a new tier after tier 5 (MCP tooling), renumbering the existing tier 6 (Deployment) to 7:

   ```markdown
   5. **MCP tooling** — If `.mcp.json` exists and contains server entries, activate the `mcp-tooling` category. Add per-server data directories dynamically based on declared servers.

   6. **Skills CLI** — If `skills-lock.json` exists at the workspace root, activate the `skills-cli` category. No fallback — see the category's own `Fallback` field for why.

   7. **Deployment** — Detect deployment platform config files (`vercel.json`, `serverless.yml`, `firebase.json`) and activate the `deployment` category if any are present.
   ```

2. **Write content, part B — `## Category Sort Order` (current lines 315-331).** Insert `skills-cli` between `mcp-tooling` (9) and `deployment` (10), renumbering the rest:

   ```markdown
   1. `universal`
   2. `secrets`
   3. `node`
   4. Framework-specific (`typescript`, `nextjs`, `astro`, `python`, `iiidev`) — in the order they appear in this catalog
   5. `build`
   6. `cache`
   7. `ide`
   8. OS categories (`macos`, `windows`, `linux`)
   9. `mcp-tooling`
   10. `skills-cli`
   11. `deployment`
   12. Sub-repositories (managed separately, listed last)
   ```

3. **Verify references.** `grep -n "^[0-9]" skills/gitignore/reference/gitignore-catalog.md` (or a manual read) confirms both numbered lists are sequential with no gaps or duplicate numbers after the edit.

4. **Commit:** `docs(gitignore-catalog): wire skills-cli into pattern selection logic and sort order`

---

### Task 4: Update Structural Rules category sort order in gitignore-flow.md

**Files:**
- Modify: `skills/gitignore/reference/gitignore-flow.md`

**Interfaces:**
- Consumes: the sort position from Phase 3 Task 3
- Produces: none

**Acceptance Criteria:** "gitignore-flow.md documents... its position in category sort order."

**Steps (Documentation: Write-and-review):**

1. **Write content.** In "## 1. Marker Block Format" → "### Structural Rules" (current lines 41-52), the category sort order list mirrors the catalog's — apply the identical renumbering from Phase 3 Task 3:

   ```markdown
   - **Category sort order** follows the catalog's canonical order:
     1. Universal
     2. Secrets
     3. Node
     4. Framework-specific (TypeScript, Next.js, Astro, Python, iii.dev) -- in catalog order
     5. Build
     6. Cache
     7. IDE
     8. macOS, Windows, Linux
     9. MCP Tooling
     10. Skills CLI
     11. Deployment
     12. Sub-repositories
   ```

2. **Verify references.** This list now matches Phase 3 Task 3's catalog list item-for-item (same order, same 12 entries).

3. **Commit:** `docs(gitignore-flow): sync structural-rules sort order with skills-cli category`

---

### Task 5: Add Skills CLI Detection subsection and update Full Detection Decision Tree

**Files:**
- Modify: `skills/gitignore/reference/gitignore-flow.md`

**Interfaces:**
- Consumes: the category detection rule from Phase 3 Task 1
- Produces: the detection decision tree entry, consumed by Phase 4 Task 3 (live rebuild on this repo)

**Acceptance Criteria:** "gitignore-flow.md documents the skills-cli detection rule... in Section 7." (detection rule itself lives in Section 4, referenced by the same criterion's "documents the detection rule" clause.)

**Steps (Documentation: Write-and-review):**

1. **Write content, part A.** In "## 4. Tech-Stack Detection Heuristics", insert a new subsection after "### MCP Tooling Detection" (current lines 313-327) and before "### Deployment Detection" (current line 329):

   ```markdown
   ### Skills CLI Detection

   ```
   skills-lock.json exists at the workspace root?
   +-- NO --> Skip skills-cli category
   +-- YES --> Activate skills-cli category
       (workspace-root check only — never per sub-repo, since .claude/skills/
        and .agents/ are Claude Code session artifacts, not per-repo source)
   ```

   No fallback heuristic exists for this category — see `gitignore-catalog.md`'s Skills CLI section for why.
   ```

2. **Write content, part B.** In "### Full Detection Decision Tree" (current lines 340-359), add a line after the MCP tooling check:

   ```markdown
   Start
   |
   +-- Read config.json repos[].stack
   |   +-- Stack entries found? --> Map to category keys
   |   +-- No stack / no config --> Fall back to file detection
   |
   +-- Always include: universal, secrets, build, cache, ide
   +-- Always include: macos, windows, linux
   |
   +-- Check .mcp.json for MCP tooling
   +-- Check skills-lock.json at workspace root for Skills CLI
   +-- Check for deployment config files
   |
   +-- Merge all activated categories
   +-- Remove duplicates (same pattern from multiple categories)
   +-- Sort by catalog order
   +-- Output final pattern list
   ```

3. **Verify references.** The new subsection's placement (after MCP Tooling Detection, before Deployment Detection) matches the sort-order position established in Phase 3 Task 3/4.

4. **Commit:** `docs(gitignore-flow): add Skills CLI detection heuristics and update decision tree`

---

### Task 6: Add first-activation mirror-diff/mtime warning logic to Cleanup Logic

**Files:**
- Modify: `skills/gitignore/reference/gitignore-flow.md`

**Interfaces:**
- Consumes: the `gitIgnore.categoriesEverActivated` field from Phase 1 Task 5
- Produces: the two-branch warning logic, exercised live in Phase 4 Task 4

**Acceptance Criteria:** "gitignore-flow.md documents... the first-activation mirror-diff (self-hosting) / mtime (general target-project) warning logic in Section 7."

**Steps (Documentation: Write-and-review):**

1. **Write content.** In "## 7. Cleanup Logic" → "### Cleanup Steps" (current lines 555-596), insert a new step between "Step 1: Verify .gitignore" and "Step 2: Group by pattern type":

   ```markdown
   Step 1a: Skills-CLI first-activation check (only when the skills-cli category is part of this cleanup run)
     Determine first-time activation from config.json's gitIgnore.categoriesEverActivated
     (a persistent array that only ever grows — distinct from the live-redetected
     activeCategories snapshot, which can drop skills-cli back out if skills-lock.json
     is briefly absent between runs).

     +-- skills-cli already in categoriesEverActivated?
     |   +-- YES --> Skip the diff/mtime check below. Untrack directly (Step 3).
     |   +-- NO  --> This is the first activation. Branch on repo shape:
     |
     +-- Self-hosting case (a root skills/ directory of authored content
     |   literally exists -- true for this plugin's own repo, not for a
     |   typical downstream target project):
     |       Compare .claude/skills/ content against root skills/.
     |       +-- Differ --> Warn the user before untracking (possible
     |       |   manual edit to a mirror instead of the source) instead
     |       |   of silently dropping the file from git.
     |       +-- Identical --> Untrack as usual (Step 3).
     |
     +-- General target-project case (no root skills/ directory to
         compare against -- the normal case for every project that
         installs this plugin):
             Skip the content-diff entirely (no source of truth to diff
             against). Instead, warn only if any file under .claude/skills/
             has an mtime newer than skills-lock.json's own mtime -- a
             signal of a possible post-install manual edit, without
             requiring a comparison directory that doesn't exist here.

     Either way, once evaluated, add skills-cli to categoriesEverActivated
     so subsequent runs skip straight to Step 3.
   ```

2. **Verify references.** The renumbered "Step 2" through "Step 5" below still read correctly with "Step 1a" inserted between "Step 1" and what was "Step 2" (no numbering collision — "1a" is intentionally non-sequential to avoid renumbering the rest of the list).

3. **Commit:** `docs(gitignore-flow): add first-activation mirror-diff/mtime warning logic to cleanup`

## Phase 3 Complete

`gitignore-catalog.md` and `gitignore-flow.md` fully define the `skills-cli` category end to end: detection (workspace-root `skills-lock.json`, no fallback), patterns (`​.claude/skills/` precisely scoped, `.agents/` wholesale), sort position, and the two-branch first-activation warning logic that protects against silently untracking manually-edited mirror content. `.claude/settings.local.json` and `*.code-workspace` are also now covered by the catalog.

**Next:** `phase-4.md`
