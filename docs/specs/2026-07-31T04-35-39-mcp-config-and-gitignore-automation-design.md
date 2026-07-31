# MCP Config & Gitignore Automation — Design Spec

**Project:** Fullstack Dev
**Repo(s):** `fullstack-dev` (mono-repo — this is the plugin's own source repo, dogfooded on itself)
**Scope:** Fix two self-inflicted gaps discovered while dogfooding: (1) the plugin generates GitHub MCP config that silently fails to connect because it puts the token in the wrong place and points at a deprecated local binary, with no verification step anywhere; (2) the plugin's own `/gitignore` catalog has no category for the `.claude/skills/`/`.agents/` install-artifact mirrors created by `npx skills add`, nor for stray `*.code-workspace` files, so they get tracked as if hand-authored.
**Approach:** Extend existing reference docs in place (tools-setup.md, doc-templates.md, init-flow.md, gitignore-catalog.md, gitignore-flow.md) — no new agents, commands, or files.

---

## 1. Overview

This plugin's entire purpose is automating dev tooling and configuration so users don't have to debug it themselves — but a live dogfooding session surfaced exactly the kind of gap it's meant to prevent. The generated `.mcp.json` told users to put `GITHUB_TOKEN` in `.env`, but Claude Code never reads `.env` for `${VAR}` expansion in MCP config; it only reads the process environment or a `settings.json`/`settings.local.json` `env` block. Compounding this, the generated config pointed at a `github-mcp-server` local binary that isn't auto-installed and is now deprecated upstream in favor of a zero-install remote HTTP endpoint. Every project this plugin initializes has been generating a GitHub MCP connection that doesn't work until the user manually discovers and fixes both problems.

Separately, this repo's own `/gitignore` tooling — built specifically to keep tracked files clean — has a blind spot for its own install mechanism: `npx skills add` mirrors the authored `skills/` content into `.claude/skills/` and `.agents/` (which currently holds nothing but a `skills/` mirror), and nothing in the gitignore catalog knows these are generated artifacts. They've been tracked in git as if hand-written, creating pure duplication with no lockfile-backed way to tell generated from authored content. `*.code-workspace` files (IDE workspace files, often containing machine-specific absolute paths) have the same untracked gap for the same reason — no catalog category covers them.

This spec fixes both by correcting where and how secrets get written (GitHub MCP moves to the recommended remote HTTP endpoint; secrets never get auto-written by an agent, only surfaced as exact instructions), by adding a connectivity-verification step to the existing health-check flow so future breakage surfaces immediately instead of silently, and by adding a new `skills-cli` gitignore category scoped precisely enough to never touch hand-authored `.claude/` content like `settings.json` or `settings.local.json`.

---

## 2. Architecture

Two independent sub-features, both implemented as edits to existing reference docs — no new agents, commands, or files, consistent with the project's existing "reference-doc-driven agents" convention.

### 1. MCP Secrets & GitHub Server Correctness

- `skills/project/reference/tools-setup.md` — GitHub section rewritten to generate the remote HTTP endpoint config instead of the local `github-mcp-server` binary; the Docker-based local run stays documented as a fallback for network-restricted environments, not deleted. **Both** places this file currently shows a GitHub `.mcp.json` snippet are updated: the "GitHub (github.com detected)" section itself, and the separate "Secrets Handling → Example" subsection later in the file, which embeds its own now-stale stdio example — left alone, the file would end up self-contradicting with two different `github` configs. The "Secrets Handling" section is split into two previously-conflated concerns: **MCP server secrets** (consumed by Claude Code itself — must live in `.claude/settings.local.json`) and **application runtime secrets** (consumed by the target app at runtime — stay in `.env`/`.env.example`, unaffected by this change). The "Project-Level Safety → Summary" table gains a row for the project-level `.claude/settings.local.json` (marked "read-only" for the plugin — the file is never written by an agent, only referenced in instructions).
- `skills/project/reference/doc-templates.md` — `.mcp.json` GitHub template updated to the HTTP form. `.env.example` loses its `GITHUB_TOKEN` reference in **both** places it currently appears: the template code block, and the "Rules" bullet list ("GitHub projects: `GITHUB_TOKEN=`") — both must change together or the file ends up internally contradictory.
- `skills/project/reference/init-flow.md` — the existing "MCP" health-check category gains three report-only checks: a **config-shape check** extended to flag the deprecated local-stdio `github` shape (not just presence/absence of an entry), plus the two new checks (connectivity, settings.local.json presence).
- `agents/init-agent.md` — health-check mode executes the three checks and formats findings per the secret-reporting rules (variable names and file paths only, never values); never auto-writes a secret value in any mode. Gains one **explicit, named exception** to the general `.mcp.json` merge rule ("never remove or modify existing server entries"): when the `github` entry matches the deprecated shape exactly (`command: "github-mcp-server"`, `args: ["stdio"]`), init-agent replaces it with the HTTP form and reports the change — this is the only server/shape combination allowed to be modified rather than left untouched. No other merge behavior changes.

### 2. Skills-cli Install-Artifact Gitignore Category

- `skills/gitignore/reference/gitignore-catalog.md` — new category `skills-cli` (detect: `skills-lock.json` exists at the **workspace root only** — see Data Flow for the multi-repo rationale; patterns: `.claude/skills/` and `.agents/` — `.agents/` is ignored as a whole directory, not just `.agents/skills/`, since it currently holds nothing but the skills mirror and a wholesale pattern stays correct if `npx skills add` ever mirrors other content there too; `.claude/skills/` stays precisely scoped rather than matching all of `.claude/`, since `.claude/` can and does hold hand-authored content like `settings.json`. Patterns apply to the workspace-root `.gitignore` regardless of `repoStructure`. Unlike every other catalog category, this one has no file-detection fallback — that's an intentional deviation, not an oversight: `skills-lock.json` is the one reliable, unambiguous signal that `npx skills add` manages this workspace, and a heuristic fallback (e.g. guessing from directory contents) risks false positives on hand-authored `.claude/` trees. Also adds `.claude/settings.local.json` to the always-active `secrets` category, since it's user-local, can hold live tokens, and currently isn't covered by any pattern at all. Also adds `*.code-workspace` to the always-active `ide` category (alongside `.vscode/*`) — this is a general IDE-artifact fix, not gated on `skills-lock.json`, since these files commonly contain machine-specific absolute paths regardless of whether this plugin is installed.
- `skills/gitignore/reference/gitignore-flow.md` — Section 4 detection heuristics gain a `skills-lock.json → skills-cli` rule (workspace-root check, explicitly not per-sub-repo). Category sort order gains `skills-cli` (placed after `mcp-tooling`, before `deployment`). Section 7 (Cleanup Logic) gains the first-activation mirror-diff warning rule, scoped correctly for both the self-hosting case and the general target-project case (see Data Flow). `config.json`'s schema gains a new persistent field, `gitIgnore.categoriesEverActivated` (an array, distinct from the live-detected `activeCategories` snapshot), so "first activation" can be determined reliably even if `skills-cli` ever drops out of `activeCategories` between runs (e.g. `skills-lock.json` briefly absent).

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

   *Verified:* embedding `${VAR}` inside a larger string value (e.g. `"Bearer ${GITHUB_TOKEN}"`) is officially supported — Claude Code's own `.mcp.json` docs give this exact `Authorization: Bearer ${API_KEY}` pattern as a worked example, alongside mid-string expansion in `url`. This isn't a novel assumption; it's the documented mechanism.

2. `/project --init` (health-check mode, existing repos) → init-agent runs the extended "MCP" health-check category (three checks total):
   - **Config-shape check** (existing category, extended): in addition to the existing "does `.mcp.json` have the expected entries?" check, now also flags the deprecated local-stdio `github` shape (`command: "github-mcp-server"`, `args: ["stdio"]`) as a named FAIL — not just silence until the connectivity check happens to catch it. When this exact deprecated shape is found, init-agent applies the one named exception to the `.mcp.json` merge rule (see Architecture) and replaces the entry with the HTTP form, reporting the change explicitly rather than silently.
   - **Connectivity check** (new): attempt `claude mcp list`, parse output for `Missing environment variables: <VAR>` or `Pending approval` per server; catch-all branch for any other/unrecognized failure text (reported verbatim rather than dropped).
     - CLI call fails or isn't invokable in this context → skip gracefully, report: "Could not verify connectivity in this session — run `claude mcp list` manually."
     - A variable is reported missing → check whether it's already present in `.claude/settings.local.json`'s `env` block.
       - Not present at all → report the exact variable name and the snippet to add it (never the value).
       - Present but still reported missing → report: "Found in settings.local.json but Claude Code hasn't picked it up yet — restart your session."
     - `Pending approval` → report: "Run `claude` interactively once to approve the `<server>` server."
     - Unrecognized warning text → report it verbatim with a pointer to `claude mcp list` for full detail, rather than swallowing it silently.

   Rendered in the existing `init-flow.md` §10.2 health-check table format (`Category | Check | Auto-fix?`), this reads as three rows under the "MCP" category:

   ```text
   | MCP | .mcp.json has expected entries       | Yes (add missing)         |
   | MCP | github entry is not deprecated shape | Yes (replace, see note)   |
   | MCP | claude mcp list reports no warnings   | No (report only)          |
   ```

3. This flow doubles as a live test case on this exact repo: right now `GITHUB_TOKEN` sits only in `.env` (the wrong place — a leftover from before this fix), so a health-check run here should surface exactly that mismatch once implemented.

**Skills-cli gitignore category:**

1. `/gitignore scan|rebuild|cleanup` → the detection step (Section 4 of `gitignore-flow.md`) now also checks for `skills-lock.json` at the **workspace root** (not per sub-repo — see rationale below) → if present, `skills-cli` activates alongside whatever else was detected, and its patterns apply to the workspace-root `.gitignore` only.
   - *Why workspace-root-only:* `.claude/skills/` and `.agents/` are Claude Code session artifacts, not per-repo source-code artifacts — a Claude Code session (and therefore `npx skills add`) operates from the workspace root regardless of `repoStructure`, the same way `.mcp.json` and `.claude/settings.json` are already workspace-root-level singletons in this plugin's model, not duplicated per sub-repo. This differs from tech-stack categories (`node`, `python`, etc.), which genuinely vary per sub-repo and are detected accordingly.
2. `rebuild` → adds `.claude/skills/` and `.agents/` (whole directory) to the marker block under a `# Skills CLI` header — never touches `.claude/settings.json` or `.claude/settings.local.json`, since neither is matched by any pattern in this category, and `.agents/` currently holds nothing but the skills mirror so ignoring it wholesale carries no risk of catching hand-authored content today.
3. `cleanup` → determines first-time activation from a new **persistent** `config.json` field, `gitIgnore.categoriesEverActivated` (an array that only ever grows, unlike the live-redetected `activeCategories` snapshot which can drop `skills-cli` back out if `skills-lock.json` is briefly absent). If `skills-cli` is not yet in `categoriesEverActivated`:
   - **Self-hosting case** (a root `skills/` directory of authored content literally exists — true for this plugin's own repo, not for a typical downstream target project): compare `.claude/skills/` content against root `skills/` before untracking. If they differ (a possible manual edit to a mirror instead of the source), warn the user instead of silently untracking.
   - **General target-project case** (no root `skills/` directory to compare against — the normal case for every project that installs this plugin): skip the content-diff entirely (there is no source of truth to diff against in the target project), and instead warn only if any file under `.claude/skills/` has an mtime newer than `skills-lock.json`'s own mtime — a signal of a possible post-install manual edit, without requiring a comparison directory that doesn't exist in this scenario.
   - Either way, once evaluated, add `skills-cli` to `categoriesEverActivated` so subsequent runs skip the diff/mtime check and untrack directly.

---

## 4. File Changes

Since this repo *is* the plugin's own source (dogfooding), all changes land directly here — there's no separate "target project" to distinguish.

| File | Change |
| --- | --- |
| `skills/project/reference/tools-setup.md` | Rewrite GitHub MCP section: remote HTTP as default, Docker kept as documented fallback. Update the second, separate stale example in "Secrets Handling → Example". Split "Secrets Handling" into MCP-secrets (settings.local.json) vs app-secrets (.env) subsections. Add a project-level `.claude/settings.local.json` row to the "Project-Level Safety → Summary" table. |
| `skills/project/reference/doc-templates.md` | Update `.mcp.json` GitHub template to the HTTP form. Remove `GITHUB_TOKEN` from **both** the `.env.example` template code block and the "Rules" bullet list. |
| `skills/project/reference/init-flow.md` | Extend the existing "MCP" health-check category with three checks: the extended config-shape check (flags deprecated `github` stdio shape), the connectivity check, and the settings.local.json presence check. |
| `agents/init-agent.md` | Health-check mode: execute the three checks, format findings per the reporting rules (never echo secret values, only variable names and file paths). Add the one named exception to the `.mcp.json` merge rule (deprecated `github` stdio shape only). |
| `skills/gitignore/reference/gitignore-catalog.md` | Add `skills-cli` category (detect: `skills-lock.json` at workspace root only; patterns: `.claude/skills/`, `.agents/` — whole directory; no file-detection fallback, by design). Add `.claude/settings.local.json` to the always-active `secrets` category. Add `*.code-workspace` to the always-active `ide` category. |
| `skills/gitignore/reference/gitignore-flow.md` | Add `skills-lock.json → skills-cli` (workspace-root-only) to Section 4 detection heuristics. Add `skills-cli` to the category sort order (after `mcp-tooling`, before `deployment`). Add the first-activation mirror-diff/mtime warning rule (self-hosting vs general-target-project branches) to Section 7 (Cleanup Logic). |
| `skills/project/reference/doc-templates.md` (config.json schema) | Add `gitIgnore.categoriesEverActivated: []` to the `config.json` template — a persistent array distinct from the live-redetected `activeCategories`, used to determine true first-activation for the mirror-diff/mtime check. |
| `.mcp.json` (this repo) | Regenerate the `github` entry via `/project --init` health-check once the doc changes land — the one case where an existing `.mcp.json` entry is intentionally replaced, per the named merge-rule exception. |
| `.env.example` / `.env` (this repo) | Remove the stale `GITHUB_TOKEN` line from `.env.example`; move the real value out of `.env` into `.claude/settings.local.json` manually (per the never-auto-write decision). |
| `.gitignore` / `.fullstack-dev/config.json` (this repo) | Regenerate via `/gitignore rebuild` once the `skills-cli` category exists — adds the `skills-cli` patterns (`.claude/skills/`, `.agents/`), the `*.code-workspace` addition to `ide`, and the `.claude/settings.local.json` addition to `secrets`; updates `activeCategories` and `categoriesEverActivated`. |
| `fullstack-dev.code-workspace` (this repo) | Currently tracked; untracked by `/gitignore cleanup` once `*.code-workspace` is added to the `ide` category. |

**Note:** `.claude/skills/` and `.agents/` mirrors already tracked in this repo's git history won't disappear from history — `/gitignore cleanup` stops tracking them going forward, it doesn't purge past commits. Same for `fullstack-dev.code-workspace`.

---

## 5. Error Handling

| Failure mode | Handling |
| --- | --- |
| `claude mcp list` isn't invokable from within the agent's execution context (nested CLI call, sandboxing) | Catch the failure, skip the connectivity check, report: "Could not run connectivity check in this session — run `claude mcp list` manually to verify." Never treat this as a hard error that blocks the rest of health-check. |
| `skills-lock.json` exists but `.claude/`/`.agents/` don't exist yet (fresh project, plugin not yet installed via `npx skills add`) | `skills-cli` category still activates — patterns just have nothing to match yet. No error; a no-op until skills are actually installed. |
| `.claude/skills/` content differs from root `skills/` (self-hosting repo, possible manual edit to a mirror instead of the source) | On first-time category activation (per `categoriesEverActivated`), warn explicitly before untracking rather than silently dropping the file from git — surfaces possible in-progress work instead of hiding it. |
| A file under `.claude/skills/` has an mtime newer than `skills-lock.json` (general target-project case, no root `skills/` to diff against) | Same warn-before-untrack behavior, using the mtime signal instead of a content diff since there's no source-of-truth directory to compare in a normal target project. |
| Remote HTTP GitHub MCP endpoint (`api.githubcopilot.com`) unreachable — corporate proxy, offline dev, restrictive egress policy | Documented as a known trust-boundary/network requirement in `tools-setup.md`. The Docker fallback stays fully documented as the answer for this case; init-agent doesn't attempt to auto-detect network reachability — that's a user call. |
| `.claude/settings.local.json` already exists with unrelated content (other env vars, other local settings) | This is a **user-performed** edit, not an agent file operation — init-agent never writes to this file at all (per "No Agent-Authored Secret Writes"). The instructions it prints describe merging into the existing `env` block by hand; this is conceptually similar to, but not an instance of, the marker-block/merge convention used for agent-written files elsewhere in this plugin. |
| Health-check finds `GITHUB_TOKEN` in `.env` instead of `.claude/settings.local.json` (exactly this repo's current state) | Reported as a specific, named finding — "GITHUB_TOKEN found in .env; MCP servers don't read .env, move it to .claude/settings.local.json" — not lumped into a generic warning. |
| `git rm --cached` on `.claude/skills/`/`.agents/` hits staged changes | Falls through to the existing cleanup error handling already defined in `gitignore-flow.md` Section 7 — skip, warn, continue. No new behavior needed. |
| `.agents/` gains non-skills content in the future (e.g. `npx skills add` starts mirroring something else there) | Since the pattern ignores `.agents/` wholesale, any future content placed there by the install tool is covered automatically with no catalog change needed — this is the deliberate benefit of the whole-directory pattern over a narrower `.agents/skills/`-only one. If a user ever hand-authors content directly under `.agents/`, it would be unexpectedly ignored; this is called out as a known trade-off in Security Requirements. |

---

## 6. Testing Strategy

No automated test suite exists for this plugin — it's a prompt/markdown plugin verified via manual dogfooding. Verification here is manual, exercised against this repo itself since it's both the plugin source and a live dogfood target:

1. **GitHub MCP regeneration** — run `/project --init` health-check mode after the doc changes land; confirm it reports `GITHUB_TOKEN` as misplaced in `.env` (the exact live state right now) and prints correct instructions pointing at `.claude/settings.local.json`, without ever printing the token value itself.
2. **Fresh-project init** — simulate a first-run `/project --init` (e.g. in a scratch directory) and confirm the generated `.mcp.json` uses the HTTP form for `github`, and `.env.example` has no `GITHUB_TOKEN` line.
3. **End-to-end connectivity** — manually add `GITHUB_TOKEN` to `.claude/settings.local.json` in this repo, restart the session, run `claude mcp list`, confirm `github` shows connected (not "Missing environment variables" / "Pending approval").
4. **Gitignore category** — run `/gitignore rebuild` on this repo after the catalog change; confirm `.gitignore` gains `.claude/skills/` and `.agents/` under a new `# Skills CLI` header, `*.code-workspace` under `ide`, `.claude/settings.local.json` under `secrets`, and `config.json`'s `activeCategories` includes `skills-cli`.
5. **Cleanup dry-run** — run `/gitignore cleanup --dry-run`; confirm it lists `.claude/skills/`, `.agents/`, and `fullstack-dev.code-workspace` as would-untrack, and explicitly does not list `.claude/settings.json`.
6. **Cleanup live + mirror-diff warning (self-hosting branch)** — run `/gitignore cleanup` for real on this repo (which has a root `skills/` to compare against); confirm the two mirror dirs are untracked, `.claude/settings.json` remains tracked, `categoriesEverActivated` gains `skills-cli`, and (as a negative test on a scratch copy) hand-edit one file inside `.claude/skills/` before first activation to confirm the content-diff warning path fires rather than silently untracking.
7. **Mirror-diff warning (general target-project branch)** — in a scratch project with no root `skills/` directory, confirm cleanup uses the mtime-vs-`skills-lock.json` check instead of a content diff, and that a second `cleanup` run (with `skills-cli` already in `categoriesEverActivated`) skips the check entirely and untracks directly.
8. **Deprecated-shape migration** — restore a scratch `.mcp.json` to the old stdio `github` shape, run health-check, confirm it's flagged as a named FAIL and replaced with the HTTP form with the change reported explicitly (not silent) — the one intentional exception to the "never modify existing entries" merge rule.

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

`skills-cli` matches `.claude/skills/` (precisely scoped) and `.agents/` (whole directory) — never a wildcard on `.claude/*`. The asymmetry is deliberate: `.claude/` is known to hold hand-authored content (`settings.json`, `settings.local.json`) alongside generated content, so it must stay narrowly scoped to the one confirmed-generated subpath; `.agents/` currently holds nothing but the generated skills mirror, so a whole-directory pattern is safe today and self-extends if `npx skills add` mirrors more into `.agents/` later. The accepted trade-off: if a user ever hand-authors content directly under `.agents/` outside of `skills/`, it would be unexpectedly ignored — a real but narrow risk, worth accepting for the self-extension benefit, and distinct from the zero-tolerance stance on `.claude/*` where hand-authored content is the norm, not an edge case. `*.code-workspace` in the `ide` category is a plain glob pattern like the existing `.vscode/*` entries — no scoping concern, since workspace files are inherently machine-local IDE config with no legitimate case for being committed.

### Scoped Merge-Rule Exception

The `.mcp.json` merge rule ("never remove or modify existing server entries") gets exactly one named exception: a `github` entry matching the deprecated shape byte-for-byte (`command: "github-mcp-server"`, `args: ["stdio"]`). This exception is intentionally narrow — it does not open the door to modifying arbitrary existing entries, and every other server (`context7`, any user-added server) remains fully protected by the unmodified general rule. The replacement is always reported to the user explicitly; it is never a silent rewrite.

---

## 8. Out of Scope

- **GitLab, Bitbucket, Azure DevOps MCP server correctness.** This spec only fixes GitHub's MCP config; the other git platforms are already stubbed as "pending support" in `tools-setup.md` and are not touched here.
- **Auto-detecting network reachability** to `api.githubcopilot.com` and auto-selecting the Docker fallback. The user chooses the transport explicitly; the plugin does not attempt connectivity probing beyond the existing `claude mcp list` health check.
- **Purging `.claude/skills/`, `.agents/`, or `fullstack-dev.code-workspace` from this repo's past git history.** Cleanup stops future tracking; it does not rewrite history.
- **A general "detect and fix any misplaced secret" system.** This spec only closes the specific `GITHUB_TOKEN`/`.env`/MCP gap found during dogfooding — it does not build a generic secret-location linter for arbitrary future secrets.
- **Extending `skills-cli` detection to installed *commands* mirrors** (e.g. `.claude/commands/`), if `npx skills add` ever starts mirroring commands the same way it mirrors skills. Only `.claude/skills/` and `.agents/` are in scope now, since those are the only mirrors confirmed to exist today.
- **A `/project --init` wizard question for the skills-mirror commit-vs-ignore choice.** The "ignore, like node_modules" default applies unconditionally; a per-project override wizard question was explicitly considered and declined during brainstorming.
- **Narrowing `.agents/` to `.agents/skills/` specifically.** Explicitly considered and declined in favor of the whole-directory pattern — see "Gitignore Category Precision" in Security Requirements for the accepted trade-off.
- **Other IDE workspace-file formats** beyond `*.code-workspace` (e.g. JetBrains `.idea/workspace.xml`, already covered by the existing `ide` category's `.idea/` pattern). No new formats are added beyond what was specifically requested.

---

## 9. Acceptance Criteria

- [ ] `.mcp.json`'s `github` entry uses the remote HTTP form (`type: "http"`, `url: "https://api.githubcopilot.com/mcp"`, `Authorization: Bearer ${GITHUB_TOKEN}` header) instead of the deprecated local stdio binary form.
- [ ] `.env.example` no longer references `GITHUB_TOKEN` in either the template code block or the "Rules" bullet list in `doc-templates.md`.
- [ ] `tools-setup.md`'s "Secrets Handling" section clearly separates MCP server secrets (`.claude/settings.local.json`) from application runtime secrets (`.env`/`.env.example`), and both GitHub `.mcp.json` example locations in the file are updated consistently (no stale stdio example remains).
- [ ] `init-flow.md`'s "MCP" health-check category includes three checks: config-shape (including deprecated-shape detection), connectivity, and settings.local.json presence.
- [ ] `init-agent.md` health-check mode flags a deprecated `github` stdio shape (`command: "github-mcp-server"`, `args: ["stdio"]`) as a named FAIL and replaces it via the one explicitly-named exception to the `.mcp.json` merge rule, reporting the change to the user rather than applying it silently.
- [ ] `init-agent.md` health-check mode runs the connectivity check (parses `claude mcp list` for missing-variable/pending-approval/unrecognized warnings) and degrades gracefully (reports "run manually") if the CLI call isn't invokable in-session.
- [ ] Init-agent never writes a literal secret value to any file, in any mode (first-run or health-check) — only variable names, file paths, and copy-pasteable snippets/commands with empty placeholders.
- [ ] `gitignore-catalog.md` has a new `skills-cli` category, detected by `skills-lock.json` at the workspace root only, covering `.claude/skills/` (precisely scoped) and `.agents/` (whole directory), with no file-detection fallback.
- [ ] `gitignore-catalog.md`'s `secrets` category includes `.claude/settings.local.json`; its `ide` category includes `*.code-workspace`.
- [ ] `gitignore-flow.md` documents the `skills-cli` detection rule, its position in category sort order, and the first-activation mirror-diff (self-hosting) / mtime (general target-project) warning logic in Section 7.
- [ ] `config.json`'s schema includes the new persistent `gitIgnore.categoriesEverActivated` field, distinct from the live-redetected `activeCategories`.
- [ ] Running `/gitignore rebuild` on this repo produces a `.gitignore` with `.claude/skills/`, `.agents/`, `*.code-workspace`, and `.claude/settings.local.json` patterns correctly categorized, and updates `config.json` accordingly.
- [ ] Running `/gitignore cleanup` on this repo untracks `.claude/skills/`, `.agents/`, and `fullstack-dev.code-workspace`, while `.claude/settings.json` remains tracked throughout.
- [ ] This repo's own live `.mcp.json`, `.env`/`.env.example`, and `.gitignore` are corrected to match the new templates, serving as the first real validation of every criterion above.
