# Context7 Wiring & Deep Stack Detection — Design Spec

**Created:** 2026-07-31T10:54:47Z
**Status:** Draft
**Author:** AI + Ravindra Gadekar

## Overview

Fullstack Dev configures the context7 MCP server in every managed project, but only 3 of 11 agents (`init-agent`, `repo-agent`, `scanner-agent`) hold the MCP grant, and only `scanner-agent` has real dispatch instructions for it — `init-agent`/`repo-agent`'s grants are unused today. Meanwhile, `scanner-agent`'s stack-detection tables (config files, entry points, models/schemas) are deep for JS/TS ecosystems but shallow for everything else — Django, Rails, Spring, Laravel, and .NET projects only get the first-layer dependency-file glob.

This spec closes both gaps in one pass: (1) wire context7 access and real usage instructions into all remaining agents via one shared, canonical reference doc, and (2) extend scanner-agent's existing detection tables to the same depth for six major non-JS ecosystems (Django and Flask treated separately, plus Rails, Spring, Laravel, .NET). This is the first of two related sub-projects; a follow-up brainstorm will separately cover cloud-platform and database-specific MCP auto-wiring, which is out of scope here.

## Architecture

**New file:**
- `skills/project/reference/context7-usage.md` — the canonical, single-source-of-truth doc for how any agent should use context7: the `resolve-library-id` → `query-docs` flow, scoping each query to one concept, respecting environments that cap calls (e.g. 3 per question), and when to skip context7 entirely (stable/slow-moving APIs, trivial tasks). Every agent that uses context7 points to this doc rather than repeating the discipline inline — mirroring the existing pattern where `skills/git/SKILL.md` is referenced from other skills as shared behavior.

**Modified — scanner-agent (deepens detection, and switches to the shared doc):**
- `agents/scanner-agent.md` — extend the existing Package & Dependency Files, Configuration Files, Entry Points, and Models & Schemas tables with rows for Django, Flask (Python — kept as two distinct rows, see Data Flow), Rails (Ruby), Spring/Spring Boot (Java/Kotlin), Laravel (PHP), and ASP.NET/.NET, at the same depth already given to Next.js/Nuxt/Astro/Prisma. Replace the existing inline "Context7 MCP Usage" section with a short pointer to `context7-usage.md`, preserving its existing framing (see table below) rather than reducing it to a bare link.

**Modified — agents gaining context7 (grant + real instructions):**
- `agents/implementer-agent.md`, `agents/refactor-agent.md`, `agents/debugger-agent.md`, `agents/refresh-agent.md`, `agents/security-reviewer-agent.md`, `agents/task-reviewer-agent.md`, `agents/plan-reviewer-agent.md`, `agents/grill-agent.md` — add `mcpServers: [context7]` to frontmatter (currently absent) plus a short "Context7 MCP Usage" section with one line of agent-specific framing, then the pointer to `context7-usage.md` for the full discipline.
- `agents/init-agent.md`, `agents/repo-agent.md` — already hold the `mcpServers: [context7]` grant; add the same pointer-section pattern so the grant is actually used.
- `agents/scanner-agent.md` — keep its context7 access as-is; only the wording of its usage section changes (see above).

Exact framing per agent — **`debugger-agent` and `refactor-agent` are read-only, dimension-scoped, evidence-only subagents** (their own charters explicitly forbid forming hypotheses or suggesting changes — see `agents/debugger-agent.md`/`agents/refactor-agent.md` Constraints), so their framing must stay observation-only, not action-oriented:

  | Agent | Framing line |
  |---|---|
  | `scanner-agent` | Confirm framework conventions, config schemas, and default directory structures for a detected ecosystem. |
  | `implementer-agent` | Confirm the current API signature before writing code against an unfamiliar library version. |
  | `refactor-agent` | When investigating the `dependencies` or `patterns` dimension, confirm current documented idioms/APIs to report as evidence — do not use this to suggest a refactoring operation. |
  | `debugger-agent` | When investigating the `dependencies` dimension, confirm a library's documented API/behavior to report as evidence — do not use this to form or imply a root-cause hypothesis. |
  | `refresh-agent` | Confirm current framework conventions when refreshing docs for a detected library/framework. |
  | `security-reviewer-agent` | Check current, version-specific security guidance/hardening recommendations for a library or framework in scope. |
  | `task-reviewer-agent` | Verify a completed task's implementation matches the current API/behavior of the library it targets. |
  | `plan-reviewer-agent` | Verify a plan's proposed approach is compatible with the current version of the library/framework it depends on. |
  | `grill-agent` | Verify a spec's claims about a library/framework's capabilities against current documentation. |
  | `init-agent` | Confirm framework/tooling conventions when generating or validating project setup during the init wizard. |
  | `repo-agent` | Confirm current scaffolding conventions for the framework/runtime chosen in the add-repo wizard. |

**Modified — this repo's own docs (dogfooded via `/project --init`):**
- `docs/project/architecture.md`, `docs/project/tech-stack.md` — update to reflect that context7 is now wired into all 11 agents (not 3), and that stack detection covers Django/Flask/Rails/Spring/Laravel/.NET at full depth.

No changes to `.mcp.json`, `skills/project/reference/tools-setup.md`, or any target-project generation logic — context7 is already correctly configured at the project level (`tools-setup.md`); this spec is purely about agent-level tool access, usage instructions, and detection depth.

**Note on `context7-usage.md`'s location:** placing it under `skills/project/reference/` while it's read by agents belonging to 7 different skills (debug, refactor, implement, brainstorm, plan, project, and scanner's own project skill) is an intentional cross-skill shared doc, mirroring the existing precedent where `skills/git/SKILL.md` is referenced from six other `SKILL.md` files. This is a deliberate choice, not an oversight — flagged here so future maintainers don't "fix" it by duplicating the doc per skill.

## Data Flow

1. Any of the 11 agents, mid-task, hits a point where it needs current, version-accurate information about a specific framework/library/API (writing code, refactoring, forming a debugging hypothesis, reviewing a plan/task/spec for feasibility, or refreshing docs for a detected framework).
2. The agent consults `context7-usage.md`'s decision rule: is this a fast-moving/versioned API where correctness depends on matching the target project's pinned dependency version? If yes, proceed; if it's a stable API or a trivial task, skip context7 entirely.
3. The agent calls `mcp__context7__resolve-library-id` for the library in question, then `mcp__context7__query-docs` scoped to one concept (not a broad/multi-topic query), staying within the call budget the doc specifies.
4. The agent incorporates the returned documentation into its output (code written, root-cause hypothesis, review finding, refreshed doc content) and continues its normal flow — this is a knowledge lookup step embedded in existing agent behavior, not a new orchestration path.

For stack detection specifically, during `/project --init` or `/project --refresh`, `scanner-agent`'s Package & Dependency Files step now also matches, using these concrete signals (filename glob plus, where noted, a content check — existing rows in the table are glob-only; these are the first rows requiring a content check, so the signal is spelled out explicitly to avoid two implementers writing different, differently-fragile patterns):

| Ecosystem | Signal |
|---|---|
| Django | `manage.py` present, **and** `requirements.txt`/`pyproject.toml` contains `django` or `settings.py` contains `INSTALLED_APPS` |
| Flask | `requirements.txt`/`pyproject.toml` contains `flask`, **and** a Python file greps for `from flask import Flask` (never inferred from `app.py` alone — that filename is shared with FastAPI, Streamlit, and plain scripts) |
| Rails | `Gemfile` present **and** `config/routes.rb` present |
| Spring / Spring Boot | `pom.xml` contains `spring-boot-starter` or `org.springframework.boot`, **or** `build.gradle*` contains `org.springframework.boot` |
| Laravel | `composer.json` contains `"laravel/framework"` |
| ASP.NET / .NET | `*.csproj` contains `Microsoft.AspNetCore` |

Once an ecosystem is identified, the scanner proceeds through the now-extended Configuration Files, Entry Points, and Models & Schemas tables for that ecosystem — exactly the same mechanism already used for Next.js/Nuxt/Prisma today, just with new table rows (Django and Flask get separate rows throughout, since their config/entry-point/ORM conventions are unrelated). Output generation (`CONTEXT.md`, `docs/project/architecture.md`, `ARCHITECTURE.md`) is unchanged — it already consumes whatever the scanner extracts, regardless of ecosystem.

**Known limitation (unchanged by this spec):** a single scanned repo path is treated as one ecosystem. A polyglot mono-repo subdirectory containing more than one ecosystem (e.g. a Rails API and a separate Next.js frontend under different paths) is handled correctly today because each is a separate entry in `repos[]`; a single directory mixing ecosystems is a pre-existing scanner limitation this spec does not attempt to fix.

## File Changes

| File | Change |
|---|---|
| `skills/project/reference/context7-usage.md` | **New.** Canonical context7 usage doc: call flow, query scoping, budget discipline, skip conditions. |
| `agents/scanner-agent.md` | Extend 4 detection tables with Django/Flask/Rails/Spring/Laravel/.NET rows; replace inline Context7 section with a shorter pointer to the shared doc, keeping its own framing line. |
| `agents/init-agent.md` | Add pointer section (grant already present, currently unused). |
| `agents/repo-agent.md` | Add pointer section (grant already present, currently unused). |
| `agents/implementer-agent.md` | Add `mcpServers: [context7]` + pointer section with agent-specific framing. |
| `agents/refactor-agent.md` | Add `mcpServers: [context7]` + pointer section with agent-specific framing. |
| `agents/debugger-agent.md` | Add `mcpServers: [context7]` + pointer section with agent-specific framing. |
| `agents/refresh-agent.md` | Add `mcpServers: [context7]` + pointer section with agent-specific framing. |
| `agents/security-reviewer-agent.md` | Add `mcpServers: [context7]` + pointer section with agent-specific framing. |
| `agents/task-reviewer-agent.md` | Add `mcpServers: [context7]` + pointer section with agent-specific framing. |
| `agents/plan-reviewer-agent.md` | Add `mcpServers: [context7]` + pointer section with agent-specific framing. |
| `agents/grill-agent.md` | Add `mcpServers: [context7]` + pointer section with agent-specific framing. |
| `docs/project/architecture.md` | Update to reflect full context7 wiring across all 11 agents. |
| `docs/project/tech-stack.md` | Update to reflect full context7 wiring and deepened non-JS stack detection. |

This is a single-repo change (this plugin's own repo, `fullstack-dev`) — no per-repo split applies.

## Error Handling

- **context7 unavailable or declined in a target project** (e.g. user opted out during `/project --init`, or the MCP server is unreachable): none of the 11 agents hold a `WebSearch` grant today (only `grill-agent` has `WebFetch`, scoped to fetching a specific known URL, not general search) and this spec does not add one — expanding tool access is a separate decision with its own review surface. The agent proceeds on best-effort existing knowledge and flags the gap with a note in its output; it never blocks the task on a missing MCP tool.
- **Library not resolvable via `resolve-library-id`**: proceed on best-effort existing knowledge for that library; note the fallback as a known limitation in the agent's output rather than silently guessing.
- **Call-budget constraints** (some environments cap context7 calls per question, e.g. at 3): agents scope each query tightly and narrowly up front rather than issuing broad queries and retrying. If the budget is exhausted before the agent has enough information, it proceeds with what it gathered and explicitly notes the incompleteness rather than looping or stalling. This budget is per agent *instance* — `debugger-agent` and `refactor-agent` are dispatched once per investigation dimension (up to 5 and 4 parallel instances respectively) as part of `/debug` and `/refactor`'s normal parallel-evidence-gathering flow, so a single user question can fan out to several times the per-instance budget in aggregate. `context7-usage.md` must call this out explicitly and instruct these two agents to reserve context7 calls for their most relevant dimension only (`dependencies` for debugger-agent, `dependencies`/`patterns` for refactor-agent) rather than querying on every dimension.
- **Ambiguous/conflicting stack signals** (e.g. both Django and Flask markers present in the same repo — plausible since a Django project can bundle a small Flask-based tool): the scanner records both findings rather than forcing a single choice, using the existing `<!-- VERIFY: ... -->` comment convention so the user confirms during review.
- **No ecosystem match at all**: detection falls back to today's generic language-only identification (unchanged) — this is strictly additive, so no regression for stacks not covered by the new deep-detection tables.

## Testing Strategy

This repo ships as markdown + JSON with no compiled runtime or automated test suite (per `CLAUDE.md`), so verification is dogfooding plus targeted manual review:

1. **Agent-level dogfooding**: manually invoke each modified agent through its normal skill flow (e.g. dispatch `implementer-agent` via `/implement` on a task touching an external library) against a small stack-diverse fixture, and confirm context7 is called only when the task genuinely warrants it — not spuriously on trivial changes — and that the agent's output correctly reflects `context7-usage.md`'s discipline. `context7-usage.md` must give a concrete skip heuristic (not just "trivial task"/"stable API" as subjective labels) — e.g. skip for language built-ins and any API unchanged across the library's last two major versions; query only for APIs introduced or changed within the target project's currently pinned major version — so this check has a falsifiable bar to verify against, not a judgment call that varies run to run.
2. **Stack-detection dogfooding**: run `/project --init` (or `/project --refresh` on an existing config) against a synthetic or real Django, Flask, Rails, Spring, Laravel, or .NET repository; confirm `CONTEXT.md`, `docs/project/architecture.md`, and the per-repo `ARCHITECTURE.md` populate config/entry-point/model data correctly for that ecosystem, matching the depth already produced for a Next.js/Prisma fixture today. Include one Django+Flask-in-one-repo fixture to confirm the two are correctly distinguished rather than conflated.
3. **Consistency review**: grep `mcpServers` across all 11 `agents/*.md` frontmatters to confirm every agent that should have context7 access does (all 11); grep for `context7-usage.md` references to confirm all 10 non-`scanner-agent` context7-using agents point to the shared doc rather than duplicating instructions inline, plus `scanner-agent` itself retains its own framing.
4. No unit/integration test framework applies — there is no compiled code to exercise.

**Forward note (not required for this pass):** the four detection tables gain 6 new rows each in this pass (Django, Flask, Rails, Spring, Laravel, .NET). If future work adds several more ecosystems, consider splitting each table into per-ecosystem subsections rather than continuing to grow flat tables — not a concern at the current scale.
