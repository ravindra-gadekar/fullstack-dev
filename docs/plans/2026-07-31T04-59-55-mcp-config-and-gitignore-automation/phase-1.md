# Phase 1: MCP Secrets & GitHub Server Docs

**Repo:** fullstack-dev
**Depends on:** None
**Delivers:** `tools-setup.md` and `doc-templates.md` corrected so that a fresh `/project --init` generates a working, zero-local-install GitHub MCP config and correctly separates MCP-server secrets from application-runtime secrets.

## File Structure

```
skills/project/reference/
├── tools-setup.md       # modify: GitHub section, stale example, safety table
└── doc-templates.md     # modify: .env.example template, config.json schema
```

### Task 1: Rewrite tools-setup.md GitHub MCP section to remote HTTP

**Files:**
- Modify: `skills/project/reference/tools-setup.md`

**Interfaces:**
- Consumes: none (first task in the plan)
- Produces: the canonical GitHub `.mcp.json` HTTP snippet, reused verbatim by Task 2 (fixing the stale duplicate example) and by Phase 4 Task 1 (applying it to this repo's live `.mcp.json`):
  ```json
  {
    "mcpServers": {
      "github": {
        "type": "http",
        "url": "https://api.githubcopilot.com/mcp",
        "headers": {
          "Authorization": "Bearer ${GITHUB_TOKEN}"
        }
      }
    }
  }
  ```

**Acceptance Criteria:** ".mcp.json's github entry uses the remote HTTP form... instead of the deprecated local stdio binary form."

**Steps (Documentation: Write-and-review):**

- [x] 1. **Write content.** In `tools-setup.md`, replace the `### GitHub (github.com detected)` section (current lines 94-119) with:

   ````markdown
   ### GitHub (github.com detected)

   **Default: zero-install remote HTTP endpoint.** The previous `github-mcp-server` local-binary/stdio approach is deprecated upstream and requires a manual, separate binary install — do not generate it by default.

   ```json
   {
     "mcpServers": {
       "github": {
         "type": "http",
         "url": "https://api.githubcopilot.com/mcp",
         "headers": {
           "Authorization": "Bearer ${GITHUB_TOKEN}"
         }
       }
     }
   }
   ```

   Required `.claude/settings.local.json` entry (user-scoped, never committed — see "Secrets Handling" below):
   ```json
   {
     "env": {
       "GITHUB_TOKEN": "<personal-access-token>"
     }
   }
   ```

   Required `.env.example` entry: **none.** `GITHUB_TOKEN` is an MCP-server secret, not an application-runtime secret — it never appears in `.env`/`.env.example`.

   **Trust boundary:** this sends `Authorization: Bearer ${GITHUB_TOKEN}` over HTTPS to `api.githubcopilot.com`, a GitHub-hosted proxy — not a fully local flow. For network-restricted environments, use the Docker fallback instead:

   ```bash
   claude mcp add github -e GITHUB_OAUTH_CALLBACK_PORT=8085 -- docker run -i --rm -p 127.0.0.1:8085:8085 -e GITHUB_OAUTH_CALLBACK_PORT ghcr.io/github/github-mcp-server
   ```

   The plugin does not auto-detect network reachability or auto-select between these two — remote HTTP is the generated default; the Docker command above is documented for the user to run manually if needed.
   ````

- [x] 2. **Verify references.** Confirm no other section of `tools-setup.md` still shows the old `command: "github-mcp-server"` / `args: ["stdio"]` shape (Task 2 fixes the one known remaining instance in "Secrets Handling → Example" — after this task, only that one instance should remain, confirmable via `grep -n "github-mcp-server" skills/project/reference/tools-setup.md`).

- [x] 3. **Commit:** `docs(tools-setup): switch GitHub MCP config to remote HTTP endpoint`

---

### Task 2: Update the stale GitHub example in "Secrets Handling → Example" and merge-rule note

**Files:**
- Modify: `skills/project/reference/tools-setup.md`

**Interfaces:**
- Consumes: the HTTP snippet produced by Task 1
- Produces: none (leaf edit within the same file)

**Acceptance Criteria:** "Secrets Handling section clearly separates MCP server secrets... and application runtime secrets... and both GitHub .mcp.json example locations in the file are updated consistently (no stale stdio example remains)."

**Steps (Documentation: Write-and-review):**

- [x] 1. **Write content.** Replace the `### Example` subsection under `## Secrets Handling` (current lines 302-327) with:

   ````markdown
   ### Example

   `.mcp.json` (tracked in git):
   ```json
   {
     "mcpServers": {
       "github": {
         "type": "http",
         "url": "https://api.githubcopilot.com/mcp",
         "headers": {
           "Authorization": "Bearer ${GITHUB_TOKEN}"
         }
       }
     }
   }
   ```

   `.claude/settings.local.json` (user-scoped, never committed):
   ```json
   {
     "env": {
       "GITHUB_TOKEN": "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
     }
   }
   ```

   `.env.example` (tracked in git) — no `GITHUB_TOKEN` entry. It's an MCP-server secret, not an application-runtime one.
   ````

- [x] 2. **Verify references.** `grep -n "github-mcp-server" skills/project/reference/tools-setup.md` returns no matches — confirms both examples are now consistent.

- [x] 3. **Commit:** `docs(tools-setup): fix stale duplicate GitHub example in Secrets Handling`

---

### Task 3: Split Secrets Handling into MCP-secrets vs app-secrets subsections

**Files:**
- Modify: `skills/project/reference/tools-setup.md`

**Interfaces:**
- Consumes: none
- Produces: the "MCP Server Secrets" / "Application Runtime Secrets" distinction, referenced by Task 4 (Project-Level Safety table) and by Phase 2 Task 4 (init-agent secret-reporting rules)

**Acceptance Criteria:** "tools-setup.md's Secrets Handling section clearly separates MCP server secrets (.claude/settings.local.json) from application runtime secrets (.env/.env.example)."

**Steps (Documentation: Write-and-review):**

- [x] 1. **Write content.** Replace the `## Secrets Handling` → `### Principles` subsection (current lines 296-300) with:

   ```markdown
   ### Principles

   Two distinct kinds of secret exist, and they never live in the same place:

   **MCP server secrets** — consumed by Claude Code itself to authenticate an MCP server (e.g. `GITHUB_TOKEN` for the `github` server's `Authorization` header):
   - `.mcp.json` uses `${VAR_NAME}` syntax to reference them — it NEVER contains actual secret values.
   - The actual value goes in `.claude/settings.local.json`'s `env` block (user-scoped, never committed). Claude Code does **not** read `.env` for `${VAR}` expansion in `.mcp.json` — putting an MCP secret in `.env` silently fails to connect.
   - The plugin never writes a real value into `.claude/settings.local.json` itself — it only prints the exact snippet for the user to fill in (see "No Agent-Authored Secret Writes" in the health-check flow).

   **Application runtime secrets** — consumed by the target app at runtime (e.g. a database URL, a third-party API key the app's own code calls):
   - These go in `.env` (which must be gitignored) as before.
   - `.env.example` (tracked in git) documents required variable names with empty values.
   - Unaffected by the MCP-secrets change above — this category of secret was already handled correctly.
   ```

- [x] 2. **Verify references.** Confirm the "Checklist" subsection immediately below (current lines 329-334) still makes sense given the split — it does, since it only discusses `.env`/`.env.example`/`.mcp.json`, which remain accurate for application secrets; no edit needed there.

- [x] 3. **Commit:** `docs(tools-setup): split Secrets Handling into MCP-secrets vs app-secrets`

---

### Task 4: Add project-level settings.local.json row to Project-Level Safety table

**Files:**
- Modify: `skills/project/reference/tools-setup.md`

**Interfaces:**
- Consumes: the MCP-secrets/app-secrets split from Task 3
- Produces: none

**Acceptance Criteria:** (supports the Secrets Storage Boundary security requirement — not a standalone checklist item, but required for consistency with Task 1-3.)

**Steps (Documentation: Write-and-review):**

- [ ] 1. **Write content.** In the `### Summary` table under `## Project-Level Safety` (current lines 351-359), add a row after the `.claude/settings.json` row:

   ```markdown
   | `.claude/settings.local.json` (project root) | Project | Read-only — the plugin prints instructions for the user to edit this file directly; it never writes to it itself. |
   ```

   The full table after this edit:

   ```markdown
   | File | Scope | Plugin may modify? |
   |------|-------|--------------------|
   | `.mcp.json` (project root) | Project | Yes |
   | `.claude/settings.json` (project root) | Project | Yes |
   | `.claude/settings.local.json` (project root) | Project | Read-only — the plugin prints instructions for the user to edit this file directly; it never writes to it itself. |
   | `~/.claude/.mcp.json` | User | No |
   | `~/.claude/settings.json` | User | No |
   | `~/.claude/settings.local.json` | User | No |
   ```

- [ ] 2. **Verify references.** Table renders correctly (consistent column count with the header separator row).

- [ ] 3. **Commit:** `docs(tools-setup): document settings.local.json as read-only for the plugin`

---

### Task 5: Remove GITHUB_TOKEN from .env.example template; add categoriesEverActivated to config.json schema

**Files:**
- Modify: `skills/project/reference/doc-templates.md`

**Interfaces:**
- Consumes: the MCP-secrets/app-secrets split from Task 3 (rationale for removing `GITHUB_TOKEN` from `.env.example`)
- Produces: the `gitIgnore.categoriesEverActivated` field, consumed by Phase 3 Task 6 (cleanup logic, which is what actually writes to it) and Phase 4 Task 4 (the live `/gitignore cleanup` run that populates it on this repo — not Task 3's `/gitignore rebuild`, which only touches `activeCategories`)

**Acceptance Criteria:** "`.env.example` no longer references GITHUB_TOKEN in either the template code block or the Rules bullet list"; "config.json's schema includes the new persistent gitIgnore.categoriesEverActivated field."

**Steps (Documentation: Write-and-review):**

- [ ] 1. **Write content, part A — `.env.example` template (Section 8, current lines 615-643).** Replace the template code block:

   ```env
   # ============================================
   # Required Environment Variables
   # Copy this file to .env and fill in values
   # ============================================
   ```

   (drop the `# Git platform token (required for MCP tools)` / `GITHUB_TOKEN=` lines entirely — it was never an application-runtime secret).

   Replace the "Rules" bullet list's platform-specific line:

   ```markdown
   - The specific variables included depend on the project's `aiIntegration` settings (application-runtime secrets only — MCP-server secrets like `GITHUB_TOKEN` never appear here, see `tools-setup.md` § Secrets Handling):
     - AI integrations: `OPENAI_API_KEY=`, `ANTHROPIC_API_KEY=`, etc. (one per detected provider)
   ```

   (This removes the `GitHub projects: GITHUB_TOKEN=` and `Bitbucket projects: BITBUCKET_TOKEN=` bullets — git-platform tokens are always MCP-server secrets, never `.env` entries, regardless of platform.)

- [ ] 2. **Write content, part B — `config.json` schema (Section 7, current lines 526-568) and field reference table (569-604).** In the JSON schema block, change:

   ```json
   "gitIgnore": {
     "activeCategories": ["universal", "secrets", "node", "nextjs", "typescript", "windows", "macos", "linux", "ide", "build", "cache"],
     "hookInstalled": true
   }
   ```

   to:

   ```json
   "gitIgnore": {
     "activeCategories": ["universal", "secrets", "node", "nextjs", "typescript", "windows", "macos", "linux", "ide", "build", "cache"],
     "hookInstalled": true,
     "categoriesEverActivated": []
   }
   ```

   In the Field Reference table, add a row directly after the `gitIgnore.hookInstalled` row:

   ```markdown
   | `gitIgnore.categoriesEverActivated` | string[] | -- | Persistent record of every category ever activated for this project. Unlike `activeCategories` (a live, re-detected snapshot that can drop a category if its detection signal briefly disappears), this array only ever grows. Used to distinguish true first-activation from re-detection. |
   ```

- [ ] 3. **Verify references.** `grep -n "GITHUB_TOKEN" skills/project/reference/doc-templates.md` returns no matches. `grep -n "categoriesEverActivated" skills/project/reference/doc-templates.md` returns two matches (schema block + field table).

- [ ] 4. **Commit:** `docs(doc-templates): remove GITHUB_TOKEN from .env.example, add categoriesEverActivated to config schema`

## Phase 1 Complete

`tools-setup.md` generates a working, zero-local-install GitHub MCP config by default, with a single consistent example throughout and a clear MCP-secrets-vs-app-secrets split. `doc-templates.md`'s `.env.example` template no longer misdirects `GITHUB_TOKEN` into the wrong file, and `config.json`'s schema has the new field Phase 3 needs.

**Next:** `phase-2.md`
