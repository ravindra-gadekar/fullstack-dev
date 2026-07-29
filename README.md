# Fullstack Dev

**Claude Code plugin for managing fullstack projects.**

## What It Does

Fullstack Dev manages project structure, documentation, and tooling configuration across mono-repo and multi-repo projects of any tech stack. It generates a living knowledge layer (CONTEXT.md, ARCHITECTURE.md, CLAUDE.md) that keeps Claude Code grounded in your project's domain model, conventions, and decisions — and auto-refreshes it as code changes.

## Features

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

Install all skills (recommended):

```bash
npx skills add https://github.com/ravindra-gadekar/fullstack-dev.git --skill '*'
```

Or install individual skills:

```bash
npx skills add https://github.com/ravindra-gadekar/fullstack-dev.git --skill fullstack-dev
npx skills add https://github.com/ravindra-gadekar/fullstack-dev.git --skill brainstorm
```

### Naming Collision Warning

If you have an existing `/brainstorm` command (e.g., from Superpowers or local overrides), remove it before installing v2:

```bash
rm .claude/commands/brainstorm.md
rm -rf .claude/skills/brainstorming/
```

Alternatively, the init agent will detect the conflict and offer to remove the old skill automatically.

## Update

```bash
npx skills update fullstack-dev
```

## Remove

```bash
npx skills remove fullstack-dev
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

## How Auto-Refresh Works

A **PostToolUse hook** echoes a reminder after every `Edit|Write` operation, prompting Claude to update relevant docs. A **pre-commit hook** stages any already-refreshed doc files into the current commit so they're never left as orphaned changes. The two layers complement each other: the hook keeps docs current during Claude sessions, while the pre-commit ensures they ship with the code.

## Technology Agnostic

Tech stack inputs are free-text — type whatever you use (Next.js, Django, Rails, Spring Boot, etc.). When framework-specific knowledge is needed, the plugin queries context7 for up-to-date documentation rather than relying on baked-in assumptions.

## Future (v3+)

Workflow skills (`/plan`, `/implement`, `/debug`, `/refactor`) will be added as composable skill modules in future versions.

## License

[MIT](LICENSE)
