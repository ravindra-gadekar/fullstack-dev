# Phase 2: MCP Health-Check & Merge-Rule Exception

**Repo:** fullstack-dev
**Depends on:** Phase 1 (references the remote-HTTP shape and MCP-secrets/app-secrets split established there)
**Delivers:** `init-flow.md` and `init-agent.md` health-check flows detect the deprecated `github` shape, replace it via one named merge-rule exception, run a `claude mcp list` connectivity check, and report findings without ever echoing secret values — with both the authoritative table and its condensed mirror kept in sync.

## File Structure

```
skills/project/reference/
└── init-flow.md         # modify: health-check table (§10.2)
agents/
└── init-agent.md        # modify: condensed table, merge rules, health-check narrative, constraints
```

### Task 1: Extend init-flow.md §10.2 health-check table — MCP category

**Files:**
- Modify: `skills/project/reference/init-flow.md`

**Interfaces:**
- Consumes: none
- Produces: the three-row MCP check definition, mirrored by Task 2 into `init-agent.md`

**Acceptance Criteria:** "init-flow.md's MCP health-check category includes three checks: config-shape (including deprecated-shape detection), connectivity, and settings.local.json presence."

**Steps (Documentation: Write-and-review):**

- [x] 1. **Write content.** In the health-check table (current lines 648-681), the `MCP` category currently reads:

   ```
   MCP               | .mcp.json exists                                 | Yes (create)
                     | context7 configured                              | Yes (add entry)
                     | Git platform MCP configured                      | Yes (add entry)
   ```

   Replace with:

   ```
   MCP               | .mcp.json exists                                 | Yes (create)
                     | context7 configured                              | Yes (add entry)
                     | Git platform MCP configured                      | Yes (add entry)
                     | github entry is not deprecated stdio shape       | Yes (replace, named exception — see Merge Rules)
                     | claude mcp list reports no connectivity warnings | No (report only)
                     | Required MCP env vars present in settings.local.json | No (report only)
   ```

- [x] 2. **Verify references.** Table column alignment stays consistent with the rest of the table (pipe-delimited, not a strict markdown table — matches existing formatting in this section).

- [x] 3. **Commit:** `docs(init-flow): add deprecated-shape, connectivity, and settings.local.json checks to MCP health-check category`

---

### Task 2: Mirror the same MCP rows into init-agent.md's condensed health-check table

**Files:**
- Modify: `agents/init-agent.md`

**Interfaces:**
- Consumes: the three-row check definition produced by Task 1
- Produces: none

**Acceptance Criteria:** "init-flow.md's MCP health-check category includes three checks..." (this task closes the drift risk identified during codebase research — the condensed table must not fall out of sync with the authoritative one).

**Steps (Documentation: Write-and-review):**

- [ ] 1. **Write content.** In the "Step 3: Health Check Table" summary (current lines 288-301), the `MCP` row currently reads:

   ```markdown
   | **MCP** | .mcp.json exists; context7 configured; git platform MCP configured |
   ```

   Replace with:

   ```markdown
   | **MCP** | .mcp.json exists; context7 configured; git platform MCP configured; github entry is not deprecated stdio shape (auto-fix: replace via named merge exception); claude mcp list reports no connectivity warnings (report only); required MCP env vars present in settings.local.json (report only) |
   ```

- [ ] 2. **Verify references.** `grep -n "context7 configured" skills/project/reference/init-flow.md agents/init-agent.md` shows both files' MCP rows contain the same set of checks (same substrings present in both), confirming the mirror stays accurate.

- [ ] 3. **Commit:** `docs(init-agent): mirror the extended MCP health-check checks into the condensed table`

---

### Task 3: Add the named .mcp.json merge-rule exception

**Files:**
- Modify: `agents/init-agent.md`

**Interfaces:**
- Consumes: none
- Produces: the exception clause, consumed by Task 4 (execution logic references it) and by Phase 4 Task 1 (applying it live to this repo)

**Acceptance Criteria:** "init-agent.md health-check mode flags a deprecated github stdio shape... and replaces it via the one explicitly-named exception to the .mcp.json merge rule, reporting the change to the user rather than applying it silently."

**Steps (Documentation: Write-and-review):**

- [ ] 1. **Write content.** In the "Merge Rules — CRITICAL" table (current lines 330-336), the `.mcp.json` row currently reads:

   ```markdown
   | `.mcp.json` | Parse existing JSON. Add new server entries to `mcpServers` only if not already present. Never remove or modify existing server entries. |
   ```

   Replace with:

   ```markdown
   | `.mcp.json` | Parse existing JSON. Add new server entries to `mcpServers` only if not already present. Never remove or modify existing server entries — **with exactly one named exception:** a `github` entry matching the deprecated shape byte-for-byte (`command: "github-mcp-server"`, `args: ["stdio"]`) is replaced with the remote HTTP form from `tools-setup.md`, and the replacement is always reported to the user explicitly, never applied silently. No other server or shape is ever modified. |
   ```

- [ ] 2. **Verify references.** The bullet immediately below the table ("When merging JSON files...") still applies unchanged — the named exception is a scoped addition to step 3 ("Add new servers...") of that merge, not a change to the merge procedure itself; no further edit needed there.

- [ ] 3. **Commit:** `docs(init-agent): add named exception for deprecated github mcp.json shape`

---

### Task 4: Add connectivity-check execution logic and secret-reporting rules

**Files:**
- Modify: `agents/init-agent.md`

**Interfaces:**
- Consumes: the merge-rule exception from Task 3, the MCP-secrets/app-secrets split from Phase 1 Task 3
- Produces: the connectivity-check algorithm, which Phase 4 Task 5 exercises live on this repo

**Acceptance Criteria:** "init-agent.md health-check mode runs the connectivity check... and degrades gracefully... if the CLI call isn't invokable in-session"; "Init-agent never writes a literal secret value to any file, in any mode."

**Steps (Documentation: Write-and-review):**

- [ ] 1. **Write content, part A.** In the "Health Check Flow" section, after "### Step 3: Health Check Table" (current lines 288-302) and before "### Step 4: Results and Auto-Fix" (current line 304), insert:

   ```markdown
   ### Step 3a: MCP Connectivity Check

   For each configured MCP server, attempt `claude mcp list` and parse its output:

   - **CLI call fails or isn't invokable in this execution context** (e.g. sandboxing prevents a nested CLI call) — skip this check gracefully. Report: "Could not verify connectivity in this session — run `claude mcp list` manually."
   - **`Missing environment variables: <VAR>`** reported for a server — check whether `<VAR>` is already present in `.claude/settings.local.json`'s `env` block (read-only check, per the Merge Rules table — this agent never writes to that file):
     - Not present at all — report the exact variable name and the snippet to add it (from `tools-setup.md` § Secrets Handling), with **no value filled in**.
     - Present but still reported missing — report: "Found in settings.local.json but Claude Code hasn't picked it up yet — restart your session."
   - **`Pending approval`** reported for a server — report: "Run `claude` interactively once to approve the `<server>` server."
   - **Any other/unrecognized warning text** — report it verbatim with a pointer to `claude mcp list` for full detail, rather than dropping it silently.
   ```

- [ ] 2. **Write content, part B.** In the "## Constraints" section (current lines 378-384), the existing bullet:

   ```markdown
   - Never include actual secrets or tokens in any tracked file. Use `${VAR_NAME}` references in `.mcp.json` and empty values in `.env.example`.
   ```

   gets a second bullet added directly after it:

   ```markdown
   - Never write a literal secret value into any file, in any mode (first-run or health-check) — including `.claude/settings.local.json`. Only print variable names, file paths, and copy-pasteable snippets/commands with empty placeholders for the user to fill in themselves. Health-check output and chat-facing summaries report presence/absence and variable names only — never the value, even partially.
   ```

- [ ] 3. **Verify references.** The new "Step 3a" section correctly precedes "Step 4: Results and Auto-Fix" in document order, and both new bullets in "Constraints" read consistently with the "No Agent-Authored Secret Writes" principle established in Phase 1.

- [ ] 4. **Commit:** `docs(init-agent): add MCP connectivity-check execution logic and secret-reporting constraints`

## Phase 2 Complete

`init-flow.md` and `init-agent.md` (both the authoritative table and its condensed mirror) now detect the deprecated `github` shape, replace it via the one narrowly-scoped merge-rule exception, run a connectivity check against `claude mcp list` with graceful degradation, and are constrained to never write a literal secret value anywhere.

**Next:** `phase-3.md`
