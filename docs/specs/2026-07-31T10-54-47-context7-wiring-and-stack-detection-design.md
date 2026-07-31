# Context7 Wiring & Deep Stack Detection — Design Spec

**Created:** 2026-07-31T10:54:47Z
**Status:** Draft
**Author:** AI + Ravindra Gadekar

## Overview

Fullstack Dev configures the context7 MCP server in every managed project, but only 3 of 11 agents (`init-agent`, `repo-agent`, `scanner-agent`) hold the MCP grant, and only `scanner-agent` has real dispatch instructions for it — `init-agent`/`repo-agent`'s grants are unused today. Meanwhile, `scanner-agent`'s stack-detection tables (config files, entry points, models/schemas) are deep for JS/TS ecosystems but shallow for everything else — Django, Rails, Spring, Laravel, and .NET projects only get the first-layer dependency-file glob.

This spec closes both gaps in one pass: (1) wire context7 access and real usage instructions into all remaining agents via one shared, canonical reference doc, and (2) extend scanner-agent's existing detection tables to the same depth for the five major non-JS ecosystems. This is the first of two related sub-projects; a follow-up brainstorm will separately cover cloud-platform and database-specific MCP auto-wiring, which is out of scope here.

## Architecture

**New file:**
- `skills/project/reference/context7-usage.md` — the canonical, single-source-of-truth doc for how any agent should use context7: the `resolve-library-id` → `query-docs` flow, scoping each query to one concept, respecting environments that cap calls (e.g. 3 per question), and when to skip context7 entirely (stable/slow-moving APIs, trivial tasks). Every agent that uses context7 points to this doc rather than repeating the discipline inline — mirroring the existing pattern where `skills/git/SKILL.md` is referenced from other skills as shared behavior.

**Modified — scanner-agent (deepens detection, and switches to the shared doc):**
- `agents/scanner-agent.md` — extend the existing Package & Dependency Files, Configuration Files, Entry Points, and Models & Schemas tables with rows for Django/Flask (Python), Rails (Ruby), Spring/Spring Boot (Java/Kotlin), Laravel (PHP), and ASP.NET/.NET, at the same depth already given to Next.js/Nuxt/Astro/Prisma. Replace the existing inline "Context7 MCP Usage" section with a one-line pointer to `context7-usage.md`.

**Modified — agents gaining context7 (grant + real instructions):**
- `agents/init-agent.md`, `agents/repo-agent.md` — already hold the `mcpServers: [context7]` grant; add the pointer section so the grant is actually used.
- `agents/implementer-agent.md`, `agents/refactor-agent.md`, `agents/debugger-agent.md`, `agents/refresh-agent.md`, `agents/security-reviewer-agent.md`, `agents/task-reviewer-agent.md`, `agents/plan-reviewer-agent.md`, `agents/grill-agent.md` — add `mcpServers: [context7]` to frontmatter (currently absent) plus a short "Context7 MCP Usage" section with one line of agent-specific framing, then the pointer to `context7-usage.md` for the full discipline. Exact framing per agent:

  | Agent | Framing line |
  |---|---|
  | `implementer-agent` | Confirm the current API signature before writing code against an unfamiliar library version. |
  | `refactor-agent` | Confirm current idioms/APIs for the target library/framework version before transforming code. |
  | `debugger-agent` | Verify the documented behavior of a library/API when forming a root-cause hypothesis. |
  | `refresh-agent` | Confirm current framework conventions when refreshing docs for a detected library/framework. |
  | `security-reviewer-agent` | Check current, version-specific security guidance/hardening recommendations for a library or framework in scope. |
  | `task-reviewer-agent` | Verify a completed task's implementation matches the current API/behavior of the library it targets. |
  | `plan-reviewer-agent` | Verify a plan's proposed approach is compatible with the current version of the library/framework it depends on. |
  | `grill-agent` | Verify a spec's claims about a library/framework's capabilities against current documentation. |

**Modified — this repo's own docs (dogfooded via `/project --init`):**
- `docs/project/architecture.md`, `docs/project/tech-stack.md` — update to reflect that context7 is now wired into all 11 agents (not 3), and that stack detection covers Django/Rails/Spring/Laravel/.NET at full depth.

No changes to `.mcp.json`, `skills/project/reference/tools-setup.md`, or any target-project generation logic — context7 is already correctly configured at the project level (`tools-setup.md`); this spec is purely about agent-level tool access, usage instructions, and detection depth.

## Data Flow

1. Any of the 11 agents, mid-task, hits a point where it needs current, version-accurate information about a specific framework/library/API (writing code, refactoring, forming a debugging hypothesis, reviewing a plan/task/spec for feasibility, or refreshing docs for a detected framework).
2. The agent consults `context7-usage.md`'s decision rule: is this a fast-moving/versioned API where correctness depends on matching the target project's pinned dependency version? If yes, proceed; if it's a stable API or a trivial task, skip context7 entirely.
3. The agent calls `mcp__context7__resolve-library-id` for the library in question, then `mcp__context7__query-docs` scoped to one concept (not a broad/multi-topic query), staying within the call budget the doc specifies.
4. The agent incorporates the returned documentation into its output (code written, root-cause hypothesis, review finding, refreshed doc content) and continues its normal flow — this is a knowledge lookup step embedded in existing agent behavior, not a new orchestration path.

For stack detection specifically:
1. During `/project --init` or `/project --refresh`, `scanner-agent`'s Package & Dependency Files step now also matches: Django/Flask (`requirements.txt`/`pyproject.toml` + `manage.py` or `app.py`), Rails (`Gemfile` + `config/routes.rb`), Spring/Spring Boot (`pom.xml`/`build.gradle*` with a `spring-boot` dependency), Laravel (`composer.json` with `laravel/framework`), .NET (`*.csproj` with `Microsoft.AspNetCore.*` references).
2. Once an ecosystem is identified, the scanner proceeds through the now-extended Configuration Files, Entry Points, and Models & Schemas tables for that ecosystem — exactly the same mechanism already used for Next.js/Nuxt/Prisma today, just with new table rows for the new ecosystems.
3. Output generation (`CONTEXT.md`, `docs/project/architecture.md`, `ARCHITECTURE.md`) is unchanged — it already consumes whatever the scanner extracts, regardless of ecosystem.

## File Changes

| File | Change |
|---|---|
| `skills/project/reference/context7-usage.md` | **New.** Canonical context7 usage doc: call flow, query scoping, budget discipline, skip conditions. |
| `agents/scanner-agent.md` | Extend 4 detection tables with Django/Rails/Spring/Laravel/.NET rows; replace inline Context7 section with a pointer to the shared doc. |
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

- **context7 unavailable or declined in a target project** (e.g. user opted out during `/project --init`, or the MCP server is unreachable): the agent falls back to `WebSearch`. If neither is available, it proceeds on best-effort existing knowledge and flags the gap with a note in its output — it never blocks the task on a missing MCP tool.
- **Library not resolvable via `resolve-library-id`**: fall back to `WebSearch` for that specific library; note the fallback as a known limitation in the agent's output rather than silently guessing.
- **Call-budget constraints** (some environments cap context7 calls per question, e.g. at 3): agents scope each query tightly and narrowly up front rather than issuing broad queries and retrying. If the budget is exhausted before the agent has enough information, it proceeds with what it gathered and explicitly notes the incompleteness rather than looping or stalling.
- **Ambiguous/conflicting stack signals** (e.g. both Django and Flask dependency markers present in the same repo): the scanner records both findings rather than forcing a single choice, using the existing `<!-- VERIFY: ... -->` comment convention so the user confirms during review.
- **No ecosystem match at all**: detection falls back to today's generic language-only identification (unchanged) — this is strictly additive, so no regression for stacks not covered by the new deep-detection tables.

## Testing Strategy

This repo ships as markdown + JSON with no compiled runtime or automated test suite (per `CLAUDE.md`), so verification is dogfooding plus targeted manual review:

1. **Agent-level dogfooding**: manually invoke each modified agent through its normal skill flow (e.g. dispatch `implementer-agent` via `/implement` on a task touching an external library) against a small stack-diverse fixture, and confirm context7 is called only when the task genuinely warrants it — not spuriously on trivial changes — and that the agent's output correctly reflects `context7-usage.md`'s discipline.
2. **Stack-detection dogfooding**: run `/project --init` (or `/project --refresh` on an existing config) against a synthetic or real Django, Rails, Spring, Laravel, or .NET repository; confirm `CONTEXT.md`, `docs/project/architecture.md`, and the per-repo `ARCHITECTURE.md` populate config/entry-point/model data correctly for that ecosystem, matching the depth already produced for a Next.js/Prisma fixture today.
3. **Consistency review**: grep `mcpServers` across all 11 `agents/*.md` frontmatters to confirm every agent that should have context7 access does; grep for `context7-usage.md` references to confirm all 9 non-`scanner-agent` context7-using agents point to the shared doc rather than duplicating instructions inline.
4. No unit/integration test framework applies — there is no compiled code to exercise.
