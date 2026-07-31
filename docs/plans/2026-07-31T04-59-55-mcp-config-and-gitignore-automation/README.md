# MCP Config & Gitignore Automation — Implementation Plan

> **For agentic workers:** Use `/implement --auto <path>` to execute this plan
> phase-by-phase, task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the plugin's own broken GitHub MCP setup (wrong secret location, deprecated binary) and close the gitignore gap for its `npx skills add` install artifacts — both discovered live while dogfooding this repo.

**Architecture:** Two independent reference-doc fixes (MCP secrets/GitHub server correctness; skills-cli gitignore category) implemented entirely as edits to existing `skills/*/reference/*.md` and `agents/*.md` files — no new agents, commands, or code. A final phase applies the corrected templates to this repo's own live config as validation, since this plugin dogfoods itself.

**Tech Stack:** Markdown (agent/skill/reference docs), JSON (`.mcp.json`, `config.json`, `.env.example`), Bash (pre-commit hook, unaffected by this plan)

**Repo:** `fullstack-dev` (mono-repo — single repo, all phases target it)

**Spec:** `docs/specs/2026-07-31T04-35-39-mcp-config-and-gitignore-automation-design.md`

## Global Constraints

- No agent may write a literal secret value to any file, in any phase or task. Secrets are always surfaced as instructions/snippets with empty placeholders — this was verified as a hard operational constraint during brainstorming (a direct write attempt was blocked by the permission classifier).
- The `.mcp.json` merge rule ("never remove or modify existing server entries") gains exactly one named exception (deprecated `github` stdio shape only) — every other server entry remains fully protected.
- `.claude/settings.json` and `.claude/settings.local.json` must never be matched by the new `skills-cli` gitignore category — only `.claude/skills/` (precisely scoped) and `.agents/` (whole directory) are matched.
- No automated test suite exists for this plugin; every task's verification step is a manual/inspection step (read the file back, run the relevant `/command`, check output), not a unit test run.

## Phases

| Phase | Repo | Name | Tasks | Delivers |
|-------|------|------|-------|----------|
| 1 | fullstack-dev | MCP Secrets & GitHub Server Docs | 5 | `tools-setup.md` + `doc-templates.md` corrected: remote HTTP GitHub config, secrets split, new config schema field |
| 2 | fullstack-dev | MCP Health-Check & Merge-Rule Exception | 4 | `init-flow.md` + `init-agent.md` gain the 3 new health checks and the named merge-rule exception, kept in sync across both tables |
| 3 | fullstack-dev | Skills-CLI & IDE/Secrets Gitignore Categories | 6 | `gitignore-catalog.md` + `gitignore-flow.md` gain the `skills-cli` category, `.claude/settings.local.json`, `*.code-workspace` |
| 4 | fullstack-dev | Live Validation on This Repo | 5 | This repo's own `.mcp.json`, `.env.example`, `.gitignore` regenerated; `/gitignore cleanup` run; connectivity verified |

## Execution Order

Phases MUST be executed in order. Each phase depends on the previous phase.
Start with: `docs/plans/2026-07-31T04-59-55-mcp-config-and-gitignore-automation/phase-1.md`

## Spec Traceability

All 14 acceptance criteria from the spec map to tasks below:

| Spec Acceptance Criterion | Phase.Task |
|---|---|
| `.mcp.json`'s `github` entry uses remote HTTP form | 1.1, 4.1 |
| `.env.example` no longer references `GITHUB_TOKEN` | 1.5, 4.2 |
| Secrets Handling split; both `.mcp.json` examples updated | 1.1, 1.2, 1.3 |
| Health-check "MCP" category has 3 checks | 2.1, 2.2 |
| Deprecated shape flagged + replaced via named exception | 2.3, 2.4, 4.1 |
| Connectivity check runs and degrades gracefully | 2.4 |
| Init-agent never writes literal secret values | 2.4 (enforced), 4.2 (manual instruction only) |
| `skills-cli` category added, workspace-root detection | 3.1, 3.3 |
| `.claude/settings.local.json` in `secrets`; `*.code-workspace` in `ide` | 3.2 |
| `gitignore-flow.md` documents detection + warning logic | 3.4, 3.5, 3.6 |
| `config.json` schema has `categoriesEverActivated` | 1.5 |
| `/gitignore rebuild` produces correct `.gitignore` + config | 4.3 |
| `/gitignore cleanup` untracks mirrors, preserves settings.json | 4.4 |
| This repo's own config corrected as live validation | 4.1, 4.2, 4.3, 4.4, 4.5 |
