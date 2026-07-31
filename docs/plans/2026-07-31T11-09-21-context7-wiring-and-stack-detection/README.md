# Context7 Wiring & Deep Stack Detection — Implementation Plan

> **For agentic workers:** Use `/implement --auto <path>` to execute this plan
> phase-by-phase, task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire context7 MCP access and real usage instructions into all 11 agents (only 3 hold the grant today, only 1 uses it), and extend `scanner-agent`'s stack-detection tables to full depth for six non-JS ecosystems (Django, Flask, Rails, Spring/Spring Boot, Laravel, ASP.NET/.NET).

**Architecture:** A new canonical reference doc (`skills/project/reference/context7-usage.md`) centralizes the resolve-library-id → query-docs call flow, query scoping, call-budget discipline, and a falsifiable skip heuristic — mirroring the existing `skills/git/SKILL.md` shared-doc pattern. `scanner-agent`'s four detection tables (Package & Dependency Files, Configuration Files, Entry Points, Models & Schemas) gain rows for the six new ecosystems at the same depth already given to Next.js/Nuxt/Prisma. The other 10 agents each get a short agent-specific framing line plus a pointer to the shared doc, rather than duplicating the discipline inline.

**Tech Stack:** Markdown (agent/reference-doc definitions), no compiled runtime.

**Repo:** `fullstack-dev` (single repo, path `.`) — all 5 phases target this repo.

**Spec:** `docs/specs/2026-07-31T10-54-47-context7-wiring-and-stack-detection-design.md`

---

## Global Constraints

- This repo ships as markdown + JSON with no compiled runtime or test suite (per `CLAUDE.md`). All tasks are Documentation-type: write content, verify references, commit. There is no "run tests" step.
- No task modifies `.mcp.json`, `skills/project/reference/tools-setup.md`, or any target-project generation logic — context7 is already correctly configured at the project level; this plan is agent-level tool access, usage instructions, and detection depth only.
- Since there are no compiled interfaces in this repo, "Consumes"/"Produces" in each task refer to file paths and section headings (e.g. "the Context7 Usage doc at `skills/project/reference/context7-usage.md`"), not TypeScript signatures.
- Every agent gaining a new "Context7 MCP Usage" section places it as a new section immediately before that file's final section (`## Constraints` for most agents; `## Reference`/`## Reference Documents` for `refresh-agent`/`repo-agent`), matching where `scanner-agent` already carries its own version of this section.
- `debugger-agent` and `refactor-agent` are read-only, dimension-scoped, evidence-only subagents (their Constraints sections forbid forming hypotheses or suggesting changes) — their Context7 framing lines must stay observation-only, never action-oriented. Use the exact framing lines from the spec's table (reproduced per-task below); do not paraphrase.
- Acceptance criteria below were synthesized from the spec's Testing Strategy, File Changes table, and Error Handling sections (the spec has no dedicated `## Acceptance Criteria` checklist) — confirmed with the user before plan generation.

### Acceptance Criteria (synthesized)

- [x] AC1: `skills/project/reference/context7-usage.md` exists as the new canonical doc covering the resolve-library-id → query-docs flow, one-concept query scoping, call-budget discipline (including debugger-agent/refactor-agent per-instance reservation guidance), and a concrete, falsifiable skip heuristic.
- [x] AC2: All 11 agent files (`agents/*.md`) declare `mcpServers: [context7]` in frontmatter.
- [x] AC3: All 10 non-scanner-agent context7-using agents each carry a short "Context7 MCP Usage" section with their exact spec-defined framing line, pointing to `context7-usage.md`.
- [x] AC4: `debugger-agent`'s and `refactor-agent`'s framing lines are observation/evidence-only, never action-oriented — consistent with their existing read-only Constraints.
- [x] AC5: `scanner-agent.md`'s inline Context7 MCP Usage section is replaced with a shorter pointer to `context7-usage.md`, preserving its own existing framing.
- [x] AC6: `scanner-agent.md`'s Package & Dependency Files table gains Django/Flask/Rails/Spring/Laravel/.NET rows using the exact content-check signals specified in the spec's Data Flow table.
- [x] AC7: `scanner-agent.md`'s Configuration Files, Entry Points, and Models & Schemas tables are extended to the same depth for the same six ecosystems (Django and Flask kept as separate rows throughout).
- [x] AC8: `docs/project/architecture.md` is updated to reflect context7 wired into all 11 agents.
- [x] AC9: `docs/project/tech-stack.md` is updated to reflect full context7 wiring and deepened non-JS stack detection.
- [x] AC10: No changes are made to `.mcp.json`, `skills/project/reference/tools-setup.md`, or any target-project generation logic.
- [x] AC11: A grep of `mcpServers` across all `agents/*.md` frontmatters confirms all 11 agents hold the context7 grant; a grep for `context7-usage.md` confirms all 10 non-scanner agents reference it.
- [x] AC12: Ambiguous/conflicting ecosystem signals (e.g. Django + Flask both present in one repo) are recorded via the existing `<!-- VERIFY: ... -->` comment convention rather than forcing a single choice.

## Phases

| Phase | Repo | Name | Tasks | Delivers |
|-------|------|------|-------|----------|
| 1 | fullstack-dev | Foundation: context7-usage.md | 1 | The canonical shared context7 usage doc every other phase points to |
| 2 | fullstack-dev | scanner-agent: deepen detection + switch to shared doc | 2 | 6 new ecosystems detected at full depth; scanner-agent's own section shortened |
| 3 | fullstack-dev | Wire context7 — batch A (5 agents) | 5 | implementer/refactor/debugger/refresh/security-reviewer gain the grant + usage section |
| 4 | fullstack-dev | Wire context7 — batch B (5 agents) | 5 | task-reviewer/plan-reviewer/grill gain the grant + section; init/repo-agent's existing grant gets used |
| 5 | fullstack-dev | Update this repo's own docs | 2 | architecture.md and tech-stack.md reflect the completed wiring and detection depth |

## Execution Order

Phases MUST be executed in order. Each phase depends on the previous phase being complete — every phase after Phase 1 consumes `skills/project/reference/context7-usage.md`, and Phase 5 documents the end state produced by Phases 2–4.

Start with: `docs/plans/2026-07-31T11-09-21-context7-wiring-and-stack-detection/phase-1.md`
