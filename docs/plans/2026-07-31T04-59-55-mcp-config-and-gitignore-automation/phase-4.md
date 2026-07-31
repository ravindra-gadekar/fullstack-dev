# Phase 4: Live Validation on This Repo

**Repo:** fullstack-dev
**Depends on:** Phase 3 (applies the templates/categories all three prior phases defined to this repo's own live config — the first real validation of everything built)
**Delivers:** This repo's own `.mcp.json`, `.env.example`, `.env`, and `.gitignore` corrected to match the new templates; `config.json` updated; `/gitignore cleanup` run; GitHub MCP connectivity verified end to end.

## File Structure

```
(this repo's own root-level config files)
├── .mcp.json                    # modify: github entry -> remote HTTP form
├── .env.example                 # modify: remove GITHUB_TOKEN block
├── .env                         # modify: remove stale GITHUB_TOKEN line (local, gitignored)
├── .gitignore                   # regenerate: skills-cli, ide, secrets additions
└── .fullstack-dev/config.json   # regenerate: activeCategories, categoriesEverActivated
```

### Task 1: Apply the named merge-rule exception to this repo's .mcp.json

**Files:**
- Modify: `.mcp.json`

**Interfaces:**
- Consumes: the HTTP snippet from Phase 1 Task 1, the named merge-rule exception from Phase 2 Task 3
- Produces: this repo's corrected `github` entry, verified live in Task 5

**Acceptance Criteria:** "This repo's own live .mcp.json... corrected to match the new templates, serving as the first real validation of every criterion above."

**Steps (Config: Create-and-verify):**

- [x] 1. **Create config.** Current `.mcp.json` `github` entry:

   ```json
   "github": {
     "command": "github-mcp-server",
     "args": ["stdio"],
     "env": {
       "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
     }
   }
   ```

   matches the deprecated shape byte-for-byte — replace it, per the named exception, with:

   ```json
   "github": {
     "type": "http",
     "url": "https://api.githubcopilot.com/mcp",
     "headers": {
       "Authorization": "Bearer ${GITHUB_TOKEN}"
     }
   }
   ```

   Leave the `context7` entry completely untouched — the exception applies to this one deprecated `github` shape only.

- [x] 2. **Run verification.** Confirm `.mcp.json` is syntactically valid JSON (`node -e "JSON.parse(require('fs').readFileSync('.mcp.json'))"` or equivalent) and that `context7` is byte-for-byte unchanged from before this edit.

- [x] 3. **Commit:** `fix(mcp): switch this repo's github MCP entry to remote HTTP endpoint`

---

### Task 2: Remove GITHUB_TOKEN from .env.example and .env; instruct settings.local.json setup

**Files:**
- Modify: `.env.example`
- Modify: `.env` (local, gitignored — not committed)

**Interfaces:**
- Consumes: the `.env.example` template from Phase 1 Task 5
- Produces: none

**Acceptance Criteria:** "This repo's own live... .env.example... corrected to match the new templates"; enforces "Init-agent never writes a literal secret value to any file" — this task removes a misplaced secret reference, it does not write a new one.

**Steps (Config: Create-and-verify):**

- [x] 1. **Create config.** In `.env.example`, remove the `# Git platform token (required for MCP tools)` comment and `GITHUB_TOKEN=` line, leaving:

   ```env
   # ============================================
   # Required Environment Variables
   # Copy this file to .env and fill in values
   # ============================================

   # Anthropic API key (only needed if using the Claude API directly,
   # outside of Claude Code's built-in authentication)
   ANTHROPIC_API_KEY=
   ```

   In `.env` (gitignored, not committed — this is a local cleanup, not a secret write), remove the now-stale `GITHUB_TOKEN=ghp_...` line the same way. This does **not** write a secret anywhere new — it only removes a reference to a file MCP servers don't read, and does not touch the token's value.

- [x] 2. **Run verification.** `grep -n "GITHUB_TOKEN" .env.example` returns no matches. Print the exact instruction block for the user (do not execute it — this is the one place in this plan where a human, not the agent, performs the write):

   ```
   Add your GitHub token to .claude/settings.local.json (create the file if it doesn't exist):

   {
     "env": {
       "GITHUB_TOKEN": "<your-personal-access-token>"
     }
   }

   Then restart your Claude Code session so it picks up the new value.
   ```

- [x] 3. **Commit:** `chore(env): remove stale GITHUB_TOKEN reference from .env.example` (only `.env.example` is committed — `.env` is gitignored and never enters git history)

---

### Task 3: Run /gitignore rebuild on this repo

**Files:**
- Modify: `.gitignore`
- Modify: `.fullstack-dev/config.json`

**Interfaces:**

- Consumes: the `skills-cli` category and updated `secrets`/`ide` categories from Phase 3, the `categoriesEverActivated` schema field from Phase 1 Task 5 (schema only — this task does not populate it; that happens in Task 4)
- Produces: this repo's corrected `.gitignore` and `config.json` (`activeCategories` only), verified by Task 4 (cleanup) and by the acceptance-criteria checklist

**Acceptance Criteria:** "Running /gitignore rebuild on this repo produces a .gitignore with .claude/skills/, .agents/, *.code-workspace, and .claude/settings.local.json patterns correctly categorized, and updates config.json accordingly."

**Steps (Config: Create-and-verify):**

- [x] 1. **Create config.** Run `/gitignore rebuild` (per `skills/gitignore/SKILL.md` Step 3, using the now-updated catalog and flow docs from Phase 3). This detects `skills-lock.json` at the workspace root (present — confirmed earlier in this session), activates `skills-cli` alongside whatever else the existing detection finds (`universal`, `secrets`, `node`, `build`, `cache`, `ide`, `macos`, `windows`, `linux`, and `mcp-tooling` since `.mcp.json` has server entries), and regenerates the marker block accordingly. Per Phase 3 Task 6's design, `rebuild` only ever touches `activeCategories` — `categoriesEverActivated` is written exclusively by `cleanup`'s first-activation check (Task 4), not by this task.

- [x] 2. **Run verification.** Confirm `.gitignore`'s marker block includes a `# Skills CLI` section with `.claude/skills/` and `.agents/`; confirm the `# Secrets` section includes `.claude/settings.local.json`; confirm the `# IDE` section includes `*.code-workspace`. Confirm `.fullstack-dev/config.json`'s `gitIgnore.activeCategories` includes `skills-cli`. Do **not** expect `gitIgnore.categoriesEverActivated` to change yet — it's still whatever it was before this task ran (Task 4 is what updates it).

- [x] 3. **Commit:** `chore(gitignore): rebuild with skills-cli, settings.local.json, and code-workspace patterns`

---

### Task 4: Run /gitignore cleanup on this repo

**Files:**
- Modify: (untracks files via `git rm --cached`; may modify `.gitignore` if any pattern was missing — none expected after Task 3)

**Interfaces:**
- Consumes: the `.gitignore` and `config.json` from Task 3, the first-activation mirror-diff/mtime logic from Phase 3 Task 6
- Produces: this repo's corrected tracked-file set, the final piece of live validation

**Acceptance Criteria:** "Running /gitignore cleanup on this repo untracks .claude/skills/, .agents/, and fullstack-dev.code-workspace, while .claude/settings.json remains tracked throughout."

**Steps (Config: Create-and-verify):**

- [x] 1. **Create config.** Run `/gitignore cleanup` (per `skills/gitignore/SKILL.md` Step 4). Per Phase 3 Task 6's design, this is the step that checks `categoriesEverActivated`: since `skills-cli` was only just added to `activeCategories` by Task 3 and has never appeared in `categoriesEverActivated` before, this is a first activation. The self-hosting branch applies (this repo has a root `skills/` directory): compare `.claude/skills/` against `skills/` — expected identical (confirmed earlier via research: byte-identical mirrors modulo line endings), so no warning fires. Untrack `.claude/skills/`, `.agents/`, and `fullstack-dev.code-workspace` via `git rm --cached`, then add `skills-cli` to `categoriesEverActivated`.

- [x] 2. **Run verification.** `git ls-files | grep -c "^\.claude/skills/"` returns `0`. `git ls-files | grep -c "^\.agents/"` returns `0`. `git ls-files | grep -c "fullstack-dev.code-workspace"` returns `0`. `git ls-files | grep -c "^\.claude/settings\.json$"` returns `1` (still tracked). `.fullstack-dev/config.json`'s `gitIgnore.categoriesEverActivated` now includes `skills-cli`, added by this cleanup run's first-activation check — not by Task 3's rebuild.

- [x] 3. **Commit:** `chore(gitignore): untrack ignored files` (per the standard cleanup commit message convention in `gitignore-flow.md` § Commit After Cleanup)

---

### Task 5: Verify GitHub MCP connectivity end to end

**Files:**
- None (verification-only task; the human performs the one write this plan never delegates to an agent)

**Interfaces:**
- Consumes: everything from Tasks 1-4, plus the human manually completing the instruction printed in Task 2
- Produces: none (terminal task)

**Acceptance Criteria:** "This repo's own live .mcp.json, .env/.env.example, and .gitignore are corrected to match the new templates, serving as the first real validation of every criterion above." Closes the loop on the original problem this whole plan exists to fix.

**Steps (Documentation: Write-and-review, since this is a verification checklist rather than a file edit):**

- [x] 1. **Write content.** Present this checklist to the user (do not attempt to fill in the token or restart the session on their behalf):
   - [ ] Add `GITHUB_TOKEN` to `.claude/settings.local.json` per the instruction printed in Task 2.
   - [ ] Restart the Claude Code session.
   - [ ] Run `claude mcp list`.
   - [ ] Confirm the `github` server shows connected — no `Missing environment variables` or `Pending approval` warning.

- [x] 2. **Verify references.** If `claude mcp list` still reports an issue, cross-check against Phase 2 Task 4's connectivity-check branches (missing var not yet in settings.local.json vs. present-but-not-picked-up vs. pending approval) to diagnose which case applies.

- [x] 3. **Commit:** None — this is a manual verification task with no file changes of its own.

## Phase 4 Complete

This repo's own GitHub MCP connection now uses the corrected remote HTTP config, its secrets live in the right place, its `.gitignore` reflects the new `skills-cli`/`ide`/`secrets` categories, `.claude/skills/`, `.agents/`, and `fullstack-dev.code-workspace` are untracked while `.claude/settings.json` remains tracked, and connectivity has been verified end to end — closing the loop on the exact problem that motivated this plan.

**Next:** Plan complete.
