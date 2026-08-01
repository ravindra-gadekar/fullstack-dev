# Fullstack Dev

**Claude Code plugin for managing fullstack projects.**

## What It Does

Fullstack Dev manages project structure, documentation, and tooling configuration across mono-repo and multi-repo projects of any tech stack. It generates a living knowledge layer (CONTEXT.md, ARCHITECTURE.md, CLAUDE.md) that keeps Claude Code grounded in your project's domain model, conventions, and decisions — and auto-refreshes it as code changes.

## Features

### v8 — Auto Gitignore

**Command:** `/gitignore <scan|rebuild|cleanup> [--all] [--dry-run] [repo-name]`

- Built-in pattern catalog with 16 categories (OS, IDE, framework, tooling, MCP, deployment)
- Tech-stack-aware `.gitignore` generation from `config.json`
- Pre-commit hook auto-enforces gitignore rules on every commit
- `/gitignore scan` — check tracked files for violations
- `/gitignore rebuild` — regenerate `.gitignore` and hook from catalog
- `/gitignore cleanup` — find and untrack already-committed violations (`--dry-run` to preview)
- Standardized marker block format (`fullstack-dev:gitignore`)
- Init integration: generates `.gitignore` + installs hook during `/project --init`
- Health check: verifies coverage and hook installation

### v7 — Git Workflow

- **`/git <setup|sync|status|publish> [--all] [repo-name]`** — Unified Git workflow management. Sets up `local-dev` as the persistent working branch, auto-detects target branches from CI/CD config, syncs with rebase (merge fallback), and publishes to remote with auto-generated PRs.
- **Universal Git Guard** — Every command (`/implement`, `/fix`, `/debug`, `/refactor`, `/brainstorm`, `/plan`) now gets a Step 0 guard that verifies the `local-dev` branch, stashes uncommitted work, and pops on exit. Replaces inconsistent per-command stash logic.
- **Conventional Commits** — All commands now use `<type>(<scope>): <summary>` format with type auto-mapped per command (`feat` for implement, `fix` for fix/debug, `refactor` for refactor, `docs` for brainstorm/plan).
- **Per-Repo Target Branches** — Multi-repo projects configure target branches per repo via CI/CD auto-detection. Each repo syncs and publishes independently against its own target.
- **Dynamic CLAUDE.md** — The Git Workflow section in CLAUDE.md is now generated from config, not hardcoded.

### v6: Refactor

- **`/refactor [--auto] [--parallel] [--verbose] [--scope <path>] [<target> [-- <reason>]]`** — Graph-powered refactoring with discovery mode (scan + rank candidates) and targeted mode (specific file/folder). Atomic one-change-at-a-time execution with test-verify-commit safety loop and before/after metrics.
- **Refactor Agent** — Parallel analysis with `--parallel` spawning 4 investigation agents (metrics, dependencies, tests, patterns)
- Discovery scoring: weighted composite of severity, change frequency, blast radius, and test gaps
- Safety: stash uncommitted work, establish test baseline before changes, revert on any failure
- Multi-repo: atomic operations across repos with coordinated commit/revert

### v5: Debug & Fix

- **`/debug [--auto] [--parallel] [--verbose] <symptoms>`** — Systematic root-cause investigation with mandatory feedback loop, 3-5 ranked hypotheses, tagged instrumentation, and auto-verified fix
- **`/fix [--auto] [--verbose] <directive>`** — Apply a known fix directly with verification, multi-file support, and `/debug` escalation
- **Debugger Agent** — Parallel investigation with `--parallel` spawning 5 evidence-gathering agents (stack trace, git blame, tests, patterns, dependencies)
- Safety: stash uncommitted work before debugging, auto-revert on failure
- Anti-rationalization system preventing guess-and-check debugging

### v4 — Implement

- **`/implement [--auto] [--status] [plan-path]`** — Execute implementation plans produced by `/plan`. Dispatches implementer agents per task with auto smoke testing (typecheck, build, test, lint), auto security testing (9 OWASP categories), and 3-tier auto-fix escalation. Built-in resume detection and progress tracking.
- **Implementer Agent** — Implements plan tasks with TDD workflow, supports normal mode and fix mode.
- **Task-Reviewer Agent** — Reviews completed tasks across 4 dimensions: spec compliance, code quality, test quality, interface contract. Read-only.
- **Security-Reviewer Agent** — Reviews code changes for 9 OWASP-aligned vulnerability categories. Auto-triggered on security-sensitive files. Read-only.

### v3 — Plan

- **`/plan [--auto] [--parallel] <spec-path>`** — Convert a design spec into a multi-phase implementation plan. Uses code-review-graph (with filesystem fallback) for accurate file paths, cross-task interfaces, and spec traceability. Produces plans in `docs/plans/` with checkbox tracking.
- **Plan-Reviewer Agent** — Built-in plan stress-tester that challenges plans across 8 dimensions (dependency chains, file path accuracy, spec coverage, interface consistency, etc.). Dispatched from `/plan` or usable independently.

### v2 — Brainstorm & Tools

- **`/brainstorm [--auto] <feature>`** — Brainstorm a feature into a design spec. Explores project context, dispatches parallel research agents, asks clarifying questions, proposes approaches, writes and optionally grills the spec.
- **Grill Agent** — Built-in spec stress-tester that challenges designs across 8 dimensions (edge cases, contradictions, scope creep, security blind spots, etc.). Dispatched from `/brainstorm` or usable independently.
- **code-review-graph support** — Optional MCP tool for structural codebase understanding. Configured during `/project --init` or manually via `reference/tools-setup.md`.
- **Agentation support** — Optional MCP tool for visual UI feedback during development. Configured during init for frontend projects.

### v1 — Project Management

- **`/project --init`** — Interactive wizard that scaffolds project-level docs, config files, and tooling settings from scratch.
- **`/project --add-repo`** — Adds a new repository to a multi-repo project via an interactive wizard.
- **`/project --refresh`** — Manually refreshes all documentation across all repos.

## Installation

```bash
npx skills add https://github.com/ravindra-gadekar/fullstack-dev-plugin.git --skill '*'
```

### Naming Collision Warning

If you have an existing `/brainstorm` command (e.g., from Superpowers or local overrides), remove it before installing:

```bash
rm .claude/commands/brainstorm.md
rm -rf .claude/skills/brainstorming/
```

Alternatively, the init agent will detect the conflict and offer to remove the old skill automatically.

## Update

```bash
npx skills update -y
```

## Remove

```bash
npx skills remove fullstack-dev-plugin --skill '*'
```

## Quick Start

After installation, run `/project --init` in your workspace root and follow the interactive wizard. It will ask about your repos, tech stack, domain concepts, and conventions, then generate everything in one pass.

## What Gets Generated

| File | Location | Purpose |
|------|----------|---------|
| `CONTEXT.md` | Workspace root | Domain model, glossary, data flow, conventions |
| `docs/project/architecture.md` | Workspace root | Unified system architecture |
| `docs/project/tech-stack.md` | Workspace root | Languages, frameworks, databases |
| `docs/project/brand.md` | Workspace root | Design tokens, colors, fonts (if frontend) |
| `CLAUDE.md` | Workspace root | Top-level instructions for Claude Code |
| `ARCHITECTURE.md` | Each repo | Repo-specific structure, catalogs, patterns |
| `.gitignore` | Workspace root | Plugin marker block + user entries |
| `.mcp.json` | Workspace root | MCP server configuration (context7, git platform) |
| `.claude/settings.json` | Workspace root | Claude Code hooks (PostToolUse refresh reminder) |
| `.fullstack-dev/config.json` | Workspace root | Plugin state, repo list, project metadata |

## Commands Reference

| Command | Flags | Description |
|---------|-------|-------------|
| `/project` | `--init` | Initialize project (first run) or health check (subsequent runs) |
| `/project` | `--add-repo` | Add a new repo to a multi-repo project |
| `/project` | `--refresh` | Manually refresh all documentation |
| `/brainstorm` | `[--auto] <feature>` | Brainstorm a feature into a design spec |
| `/plan` | `[--auto] [--parallel] <spec-path>` | Convert a design spec into a multi-phase implementation plan |
| `/implement` | `[--auto] [--status] [plan-path]` | Execute implementation plans with auto smoke testing, security testing, and 3-tier auto-fix |
| `/refactor` | `[--auto] [--parallel] [--verbose] [--scope <path>] [<target> [-- <reason>]]` | Refactor code with graph-powered discovery, atomic changes, and before/after metrics |
| `/fix` | `[--auto] [--verbose] <directive>` | Apply a known fix directly with verification |
| `/debug` | `[--auto] [--parallel] [--verbose] <symptoms>` | Investigate and fix unknown bugs — systematic root-cause analysis |
| `/gitignore` | `<scan\|rebuild\|cleanup> [--all] [--dry-run] [repo-name]` | Auto-manage .gitignore — scan violations, rebuild from tech stack, cleanup tracked files |
| `/git` | `<setup\|sync\|status\|publish> [--all] [repo-name]` | Git workflow — local-dev branch, sync, status, publish with PR |

## How Auto-Refresh Works

A **PostToolUse hook** echoes a reminder after every `Edit|Write` operation, prompting Claude to update relevant docs. A **pre-commit hook** stages any already-refreshed doc files into the current commit so they're never left as orphaned changes. The two layers complement each other: the hook keeps docs current during Claude sessions, while the pre-commit ensures they ship with the code.

## Technology Agnostic

Tech stack inputs are free-text — type whatever you use (Next.js, Django, Rails, Spring Boot, etc.). When framework-specific knowledge is needed, the plugin queries context7 for up-to-date documentation rather than relying on baked-in assumptions.

## Future

Additional workflow skills will be added as composable skill modules in future versions.

## License

[MIT](LICENSE)
