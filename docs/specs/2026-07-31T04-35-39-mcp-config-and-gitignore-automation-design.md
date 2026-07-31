# MCP Config & Gitignore Automation — Design Spec

**Project:** Fullstack Dev
**Repo(s):** `fullstack-dev` (mono-repo — this is the plugin's own source repo, dogfooded on itself)
**Scope:** Fix two self-inflicted gaps discovered while dogfooding: (1) the plugin generates GitHub MCP config that silently fails to connect because it puts the token in the wrong place and points at a deprecated local binary, with no verification step anywhere; (2) the plugin's own `/gitignore` catalog has no category for the `.claude/skills/`/`.agents/skills/` install-artifact mirrors created by `npx skills add`, so they get tracked as if hand-authored.
**Approach:** Extend existing reference docs in place (tools-setup.md, doc-templates.md, init-flow.md, gitignore-catalog.md, gitignore-flow.md) — no new agents, commands, or files.

---

## 1. Overview

This plugin's entire purpose is automating dev tooling and configuration so users don't have to debug it themselves — but a live dogfooding session surfaced exactly the kind of gap it's meant to prevent. The generated `.mcp.json` told users to put `GITHUB_TOKEN` in `.env`, but Claude Code never reads `.env` for `${VAR}` expansion in MCP config; it only reads the process environment or a `settings.json`/`settings.local.json` `env` block. Compounding this, the generated config pointed at a `github-mcp-server` local binary that isn't auto-installed and is now deprecated upstream in favor of a zero-install remote HTTP endpoint. Every project this plugin initializes has been generating a GitHub MCP connection that doesn't work until the user manually discovers and fixes both problems.

Separately, this repo's own `/gitignore` tooling — built specifically to keep tracked files clean — has a blind spot for its own install mechanism: `npx skills add` mirrors the authored `skills/` content into `.claude/skills/` and `.agents/skills/`, and nothing in the gitignore catalog knows these are generated artifacts. They've been tracked in git as if hand-written, creating pure duplication with no lockfile-backed way to tell generated from authored content.

This spec fixes both by correcting where and how secrets get written (GitHub MCP moves to the recommended remote HTTP endpoint; secrets never get auto-written by an agent, only surfaced as exact instructions), by adding a connectivity-verification step to the existing health-check flow so future breakage surfaces immediately instead of silently, and by adding a new `skills-cli` gitignore category scoped precisely enough to never touch hand-authored `.claude/` content like `settings.json` or `settings.local.json`.

---

## 2. Architecture

Two independent sub-features, both implemented as edits to existing reference docs — no new agents, commands, or files, consistent with the project's existing "reference-doc-driven agents" convention.

### 1. MCP Secrets & GitHub Server Correctness

- `skills/project/reference/tools-setup.md` — GitHub section rewritten to generate the remote HTTP endpoint config instead of the local `github-mcp-server` binary; the Docker-based local run stays documented as a fallback for network-restricted environments, not deleted. The "Secrets Handling" section is split into two previously-conflated concerns: **MCP server secrets** (consumed by Claude Code itself — must live in `.claude/settings.local.json`) and **application runtime secrets** (consumed by the target app at runtime — stay in `.env`/`.env.example`, unaffected by this change).
- `skills/project/reference/doc-templates.md` — `.mcp.json` GitHub template updated to the HTTP form; `.env.example` template drops the `GITHUB_TOKEN` line, since it was never an application secret.
- `skills/project/reference/init-flow.md` — the existing "MCP" health-check category gains two new report-only checks (connectivity, settings.local.json presence).
- `agents/init-agent.md` — health-check mode executes the two new checks and formats findings per the secret-reporting rules (variable names and file paths only, never values); never auto-writes a secret value in any mode.

### 2. Skills-cli Install-Artifact Gitignore Category

- `skills/gitignore/reference/gitignore-catalog.md` — new category `skills-cli` (detect: `skills-lock.json` exists at repo root; patterns: `.claude/skills/`, `.agents/skills/`). Also adds `.claude/settings.local.json` to the always-active `secrets` category, since it's user-local, can hold live tokens, and currently isn't covered by any pattern at all.
- `skills/gitignore/reference/gitignore-flow.md` — Section 4 detection heuristics gain a `skills-lock.json → skills-cli` rule; category sort order gains `skills-cli` (placed after `mcp-tooling`, before `deployment`); Section 7 (Cleanup Logic) gains a first-activation mirror-diff warning rule.

---

## 3. Data Flow

**MCP secrets & GitHub server (init/health-check flow):**

1. `/project --init` (first-run) → init-agent reads the rewritten `tools-setup.md` → generates `.mcp.json` with the GitHub server as a remote HTTP entry:

   ```json
   {
     "mcpServers": {
       "github": {
         "type": "http",
         "url": "https://api.githubcopilot.com/mcp",
         "headers": { "Authorization": "Bearer ${GITHUB_TOKEN}" }
       }
     }
   }
   ```

   → generates `.env.example` without a `GITHUB_TOKEN` line → prints a copy-pasteable instruction block telling the user to add `GITHUB_TOKEN` to `.claude/settings.local.json`'s `env` block themselves, with the exact JSON snippet shown and no value filled in.

2. `/project --init` (health-check mode, existing repos) → init-agent runs the two new MCP checks:
   - **Config-shape check** (existing pattern, unchanged): does `.mcp.json` have the expected entries?
   - **Connectivity check** (new): attempt `claude mcp list`, parse output for `Missing environment variables: <VAR>` or `Pending approval` per server.
     - CLI call fails or isn't invokable in this context → skip gracefully, report: "Could not verify connectivity in this session — run `claude mcp list` manually."
     - A variable is reported missing → check whether it's already present in `.claude/settings.local.json`'s `env` block.
       - Not present at all → report the exact variable name and the snippet to add it (never the value).
       - Present but still reported missing → report: "Found in settings.local.json but Claude Code hasn't picked it up yet — restart your session."
     - `Pending approval` → report: "Run `claude` interactively once to approve the `<server>` server."

3. This flow doubles as a live test case on this exact repo: right now `GITHUB_TOKEN` sits only in `.env` (the wrong place — a leftover from before this fix), so a health-check run here should surface exactly that mismatch once implemented.

**Skills-cli gitignore category:**

1. `/gitignore scan|rebuild|cleanup` → the detection step (Section 4 of `gitignore-flow.md`) now also checks for `skills-lock.json` at repo root → if present, `skills-cli` activates alongside whatever else was detected.
2. `rebuild` → adds `.claude/skills/` and `.agents/skills/` to the marker block under a `# Skills CLI` header — never touches `.claude/settings.json` or `.claude/settings.local.json`, since neither is matched by any pattern in this category.
3. `cleanup` → determines first-time activation by checking whether `skills-cli` is already present in `config.json`'s `gitIgnore.activeCategories` (the existing mechanism this plugin already uses to track which categories have been applied before). If `skills-cli` is not yet listed, this is the first activation: before untracking, compare `.claude/skills/` content against root `skills/`. If they differ (a possible manual edit to a mirror instead of the source), warn the user instead of silently untracking. If identical (the normal case) — or if `skills-cli` was already listed from a prior run — untrack as usual with no comparison.

---

## 4. File Changes

Since this repo *is* the plugin's own source (dogfooding), all changes land directly here — there's no separate "target project" to distinguish.

| File | Change |
| --- | --- |
| `skills/project/reference/tools-setup.md` | Rewrite GitHub MCP section: remote HTTP as default, Docker kept as documented fallback. Split "Secrets Handling" into MCP-secrets (settings.local.json) vs app-secrets (.env) subsections. |
| `skills/project/reference/doc-templates.md` | Update `.mcp.json` GitHub template to the HTTP form. Remove `GITHUB_TOKEN` from the `.env.example` template. |
| `skills/project/reference/init-flow.md` | Extend the existing "MCP" health-check category with the connectivity check and settings.local.json presence check (both report-only, not auto-fixable). |
| `agents/init-agent.md` | Health-check mode: execute the two new checks, format findings per the reporting rules (never echo secret values, only variable names and file paths). |
| `skills/gitignore/reference/gitignore-catalog.md` | Add `skills-cli` category (detect: `skills-lock.json` at repo root; patterns: `.claude/skills/`, `.agents/skills/`). Add `.claude/settings.local.json` to the always-active `secrets` category. |
| `skills/gitignore/reference/gitignore-flow.md` | Add `skills-lock.json → skills-cli` to Section 4 detection heuristics. Add `skills-cli` to the category sort order (after `mcp-tooling`, before `deployment`). Add the first-activation mirror-diff warning rule to Section 7 (Cleanup Logic). |
| `.mcp.json` (this repo) | Regenerate the `github` entry via `/project --init` health-check once the doc changes land. |
| `.env.example` / `.env` (this repo) | Remove the stale `GITHUB_TOKEN` line from `.env.example`; move the real value out of `.env` into `.claude/settings.local.json` manually (per the never-auto-write decision). |
| `.gitignore` / `.fullstack-dev/config.json` (this repo) | Regenerate via `/gitignore rebuild` once the `skills-cli` category exists — adds the two new patterns, updates `activeCategories`. |

**Note:** `.claude/skills/` and `.agents/skills/` mirrors already tracked in this repo's git history won't disappear from history — `/gitignore cleanup` stops tracking them going forward, it doesn't purge past commits.

---

## 5. Error Handling

| Failure mode | Handling |
| --- | --- |
| `claude mcp list` isn't invokable from within the agent's execution context (nested CLI call, sandboxing) | Catch the failure, skip the connectivity check, report: "Could not run connectivity check in this session — run `claude mcp list` manually to verify." Never treat this as a hard error that blocks the rest of health-check. |
| `skills-lock.json` exists but `.claude/`/`.agents/` don't exist yet (fresh project, plugin not yet installed via `npx skills add`) | `skills-cli` category still activates — patterns just have nothing to match yet. No error; a no-op until skills are actually installed. |
| `.claude/skills/` content differs from root `skills/` (possible manual edit to a mirror instead of the source) | On first-time category activation, warn explicitly before untracking rather than silently dropping the file from git — surfaces possible in-progress work instead of hiding it. |
| Remote HTTP GitHub MCP endpoint (`api.githubcopilot.com`) unreachable — corporate proxy, offline dev, restrictive egress policy | Documented as a known trust-boundary/network requirement in `tools-setup.md`. The Docker fallback stays fully documented as the answer for this case; init-agent doesn't attempt to auto-detect network reachability — that's a user call. |
| `.claude/settings.local.json` already exists with unrelated content (other env vars, other local settings) | Instructions describe a merge into the existing `env` block, not an overwrite — consistent with the marker-block/merge convention used elsewhere in this plugin. |
| Health-check finds `GITHUB_TOKEN` in `.env` instead of `.claude/settings.local.json` (exactly this repo's current state) | Reported as a specific, named finding — "GITHUB_TOKEN found in .env; MCP servers don't read .env, move it to .claude/settings.local.json" — not lumped into a generic warning. |
| `git rm --cached` on `.claude/skills/`/`.agents/skills/` hits staged changes | Falls through to the existing cleanup error handling already defined in `gitignore-flow.md` Section 7 — skip, warn, continue. No new behavior needed. |

---

## 6. Testing Strategy

No automated test suite exists for this plugin — it's a prompt/markdown plugin verified via manual dogfooding. Verification here is manual, exercised against this repo itself since it's both the plugin source and a live dogfood target:

1. **GitHub MCP regeneration** — run `/project --init` health-check mode after the doc changes land; confirm it reports `GITHUB_TOKEN` as misplaced in `.env` (the exact live state right now) and prints correct instructions pointing at `.claude/settings.local.json`, without ever printing the token value itself.
2. **Fresh-project init** — simulate a first-run `/project --init` (e.g. in a scratch directory) and confirm the generated `.mcp.json` uses the HTTP form for `github`, and `.env.example` has no `GITHUB_TOKEN` line.
3. **End-to-end connectivity** — manually add `GITHUB_TOKEN` to `.claude/settings.local.json` in this repo, restart the session, run `claude mcp list`, confirm `github` shows connected (not "Missing environment variables" / "Pending approval").
4. **Gitignore category** — run `/gitignore rebuild` on this repo after the catalog change; confirm `.gitignore` gains `.claude/skills/` and `.agents/skills/` under a new `# Skills CLI` header, and `config.json`'s `activeCategories` includes `skills-cli`.
5. **Cleanup dry-run** — run `/gitignore cleanup --dry-run`; confirm it lists `.claude/skills/` and `.agents/skills/` as would-untrack, and explicitly does not list `.claude/settings.json`.
6. **Cleanup live + mirror-diff warning** — run `/gitignore cleanup` for real; confirm the two mirror dirs are untracked, `.claude/settings.json` remains tracked, and (as a negative test) hand-edit one file inside `.claude/skills/` before a hypothetical second activation to confirm the diff-warning path fires rather than silently untracking.

---

## 7. Security Requirements

### Secret Storage Boundary

Only `.claude/settings.local.json` (user-scoped, never committed) holds MCP-consumed tokens like `GITHUB_TOKEN`. `.env`/`.env.example` are reserved exclusively for application-runtime secrets going forward — the two are no longer conflated in either docs or generated templates.

### No Agent-Authored Secret Writes

Init-agent never writes a literal secret value into any file, in any mode (first-run or health-check). It only ever prints variable names, file paths, and copy-pasteable snippets/commands with empty placeholders. This removes by design — not by luck — the failure mode observed directly during this brainstorm session, where a direct attempt to write a raw token into `.claude/settings.local.json` was blocked by the permission classifier.

### No Secret Echoing in Reports

Health-check output and chat-facing summaries report presence/absence and variable names only — never the token value, even partially. This applies whether the check runs interactively or the result gets relayed to the user afterward.

### Transport Trust Boundary

The remote HTTP GitHub MCP option sends `Authorization: Bearer ${GITHUB_TOKEN}` over HTTPS to `api.githubcopilot.com` — a GitHub-hosted proxy, not a fully local flow. This is documented explicitly in `tools-setup.md` as a stated trust boundary, so users with restrictive network/security policies can consciously choose the Docker fallback instead of discovering the network dependency by surprise.

### Gitignore Category Precision

`skills-cli` matches only `.claude/skills/` and `.agents/skills/` — directory-anchored literal patterns, never a wildcard on `.claude/*`. This is a hard requirement, not just a convention: an over-broad pattern could silently stop tracking `.claude/settings.json` (hand-authored hook config) or a future `.claude/settings.local.json`, which would be a silent, hard-to-notice regression rather than a loud error.

---

## 8. Out of Scope

- **GitLab, Bitbucket, Azure DevOps MCP server correctness.** This spec only fixes GitHub's MCP config; the other git platforms are already stubbed as "pending support" in `tools-setup.md` and are not touched here.
- **Auto-detecting network reachability** to `api.githubcopilot.com` and auto-selecting the Docker fallback. The user chooses the transport explicitly; the plugin does not attempt connectivity probing beyond the existing `claude mcp list` health check.
- **Purging `.claude/skills/`/`.agents/skills/` from this repo's past git history.** Cleanup stops future tracking; it does not rewrite history.
- **A general "detect and fix any misplaced secret" system.** This spec only closes the specific `GITHUB_TOKEN`/`.env`/MCP gap found during dogfooding — it does not build a generic secret-location linter for arbitrary future secrets.
- **Extending `skills-cli` detection to installed *commands* mirrors** (e.g. `.claude/commands/`), if `npx skills add` ever starts mirroring commands the same way it mirrors skills. Only `.claude/skills/` and `.agents/skills/` are in scope now, since those are the only mirrors confirmed to exist today.
- **A `/project --init` wizard question for the skills-mirror commit-vs-ignore choice.** The "ignore, like node_modules" default applies unconditionally; a per-project override wizard question was explicitly considered and declined during brainstorming.
