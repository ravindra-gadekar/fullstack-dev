# Skill Self-Contained Packaging — Implementation Plan

> **For agentic workers:** Use `/implement --auto docs/plans/2026-08-01T14-00-00-skill-self-contained-packaging/` to execute this plan
> phase-by-phase, task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every skill fully self-contained by relocating all 11 top-level `agents/*.md` files into the `agents/` subdirectory of their owning skill, unifying dispatch to a single skill-relative path-read idiom, and removing the orphaned top-level `agents/`, `scripts/`, and `hooks/` directories.

**Architecture:** This is a pure file-restructuring + prose-editing change to a markdown/JSON Claude Code plugin — no compiled code, no runtime service. Every task either (a) moves an agent `.md` file byte-for-byte to its new skill-owned location, (b) edits a dispatch block in a `SKILL.md`/`reference/*.md` file to point at the new skill-relative path, or (c) updates a project doc (`CLAUDE.md`, `CONTEXT.md`, `ARCHITECTURE.md`, `docs/project/*.md`) to reflect the new structure. A final phase regenerates `skills-lock.json` and smoke-tests a fresh install.

**Tech Stack:** Markdown, JSON, Bash (no build/compile step)

**Repo:** `fullstack-dev` (path `.`) — single repo, all phases target it

**Spec:** `docs/specs/2026-08-01T13-30-00-skill-self-contained-packaging-design.md`

## Global Constraints

- Single repo (`fullstack-dev`, path `.`) — every phase and task operates in this repo's root; there is no multi-repo split.
- Agent-file relocation must preserve content byte-for-byte — only the file path changes (spec: "Content unchanged; only file path changes").
- Edits to `CLAUDE.md`, `CONTEXT.md`, and `ARCHITECTURE.md` must stay within the existing `<!-- fullstack-dev:start -->` / `<!-- fullstack-dev:end -->` marker block — never edit outside it (see `CONTEXT.md` "Marker-block merging" convention).
- No automated test suite exists in this repo (per `ARCHITECTURE.md` Testing section) — every task's verification step is a `grep`/`Read`/manual dogfood check, not `npm test`.
- Follow `CLAUDE.md` Git Workflow: work on `local-dev`, Conventional Commits, one commit per task.
- The PR that ships this plan must include the migration note from the spec's "Existing target project installations" section: *"If you previously installed this plugin, re-run `npx skills add https://github.com/ravindra-gadekar/fullstack-dev-plugin.git --skill '*'` to pick up the restructured agent files."* This is a PR-description concern, not a file-edit task — apply it when `/implement`'s final branch-finishing step creates the PR.

## Phases
| Phase | Repo | Name | Tasks | Delivers |
|-------|------|------|-------|----------|
| 1 | fullstack-dev | Relocate Agent Files & Delete Orphans | 7 | All 11 agents co-located under `skills/<name>/agents/`; top-level `agents/`, `scripts/`, `hooks/` removed |
| 2 | fullstack-dev | Unify Dispatch Path References | 8 | Every SKILL.md / reference doc dispatches agents via skill-relative path-read + `subagent_type: "claude"` |
| 3 | fullstack-dev | Update Documentation & Reference Content | 8 | Refresh-flow, init-agent health check, context7-usage, and all project docs reflect the new structure |
| 4 | fullstack-dev | Regenerate Lockfile & Verify | 3 | Static checks pass, `skills-lock.json` regenerated, fresh install + `/project --init` smoke-tested |

## Execution Order

Phases MUST be executed in order. Each phase depends on the previous phase.
Start with: `docs/plans/2026-08-01T14-00-00-skill-self-contained-packaging/phase-1.md`
