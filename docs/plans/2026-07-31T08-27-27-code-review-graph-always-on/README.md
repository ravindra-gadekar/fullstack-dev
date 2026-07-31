# Code-Review-Graph Always-On — Implementation Plan

> **For agentic workers:** Use `/implement --auto <path>` to execute this plan
> phase-by-phase, task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Promote code-review-graph from an optional developer tool to a standard, always-on MCP server configured automatically during `/project --init`, and generate a `.code-review-graphignore` file with tech-stack-derived patterns so the graph indexes only relevant source code.
**Architecture:** Update reference documentation (init-flow, tools-setup, doc-templates, refresh-flow) to describe the unified MCP setup phase and always-on behavior, update the init-agent to remove the opt-in prompt and add `.code-review-graphignore` generation, then update this repo's own docs/config to reflect the change.
**Tech Stack:** Markdown, JSON
**Repo:** fullstack-dev (`.`)
**Spec:** `docs/specs/2026-07-31T15-30-00-code-review-graph-always-on-design.md`

## Global Constraints
- No compiled runtime — all changes are markdown reference docs, agent definitions, and JSON config
- Marker-block merge semantics must be preserved for all generated file formats
- code-review-graph hooks coexist alongside existing fullstack-dev doc-staging hooks (two separate PostToolUse entries with different matchers)
- `.code-review-graphignore` uses `fullstack-dev:code-review-graph` marker naming, same syntax as `.gitignore` marker blocks
- Config version bumps from `1.0.0` to `1.1.0`; migration adds code-review-graph to existing projects regardless of prior `optionalTools.codeReviewGraph` value
- The init-agent generates the ignore file but does NOT run `uvx code-review-graph build` or trigger initial indexing

## Phases
| Phase | Repo | Name | Tasks | Delivers |
|-------|------|------|-------|----------|
| 1 | fullstack-dev | Reference Documentation & Agent Updates | 7 | Updated init-flow, tools-setup, doc-templates, refresh-flow reference docs and init-agent definition describing code-review-graph as always-on with `.code-review-graphignore` support |
| 2 | fullstack-dev | Project Documentation & Config | 3 | Updated CONTEXT.md, architecture.md, tech-stack.md, and config.json reflecting the always-on promotion for this repo |

## Execution Order
Phases MUST be executed in order. Each phase depends on the previous phase.
Start with: `docs/plans/2026-07-31T08-27-27-code-review-graph-always-on/phase-1.md`
