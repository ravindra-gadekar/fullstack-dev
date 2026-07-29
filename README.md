# Fullstack Dev

**Claude Code plugin for managing fullstack projects.**

## What It Does

Fullstack Dev manages project structure, documentation, and tooling configuration across mono-repo and multi-repo projects of any tech stack. It generates a living knowledge layer (CONTEXT.md, ARCHITECTURE.md, CLAUDE.md) that keeps Claude Code grounded in your project's domain model, conventions, and decisions — and auto-refreshes it as code changes.

## Features (v1)

- **`/project --init`** — Interactive wizard that scaffolds project-level docs, config files, and tooling settings from scratch.
- **`/project --add-repo <path>`** — Registers an existing repository into the project, generates its ARCHITECTURE.md, and wires up refresh hooks.
- **`/project --refresh`** — Regenerates all architecture docs and the cross-repo CONTEXT.md from current source code.

## Installation

```bash
npx skills add https://github.com/ravindra-gadekar/fullstack-dev.git --skill fullstack-dev
```

## Quick Start

After installation, run `/project --init` in your workspace root and follow the interactive wizard. It will ask about your repos, tech stack, domain concepts, and conventions, then generate everything in one pass.

## What Gets Generated

| File | Location | Purpose |
|------|----------|---------|
| `CONTEXT.md` | Workspace root | Cross-repo domain model, data flow, conventions |
| `docs/project/decisions.md` | Workspace root | Architecture Decision Records |
| `docs/project/scope.md` | Workspace root | Feature scope and boundaries |
| `CLAUDE.md` | Workspace root | Top-level instructions for Claude Code |
| `ARCHITECTURE.md` | Each repo | Repo-specific structure, catalogs, patterns |
| `.gitignore` | Workspace root | Sensible defaults for the detected stack |
| `.mcp.json` | Workspace root | MCP server configuration |
| `.claude/settings.json` | Workspace root | Claude Code permissions and hooks |
| `.fullstack-dev/config.json` | Workspace root | Plugin state and per-repo metadata |

## Commands Reference

| Command | Flags | Description |
|---------|-------|-------------|
| `/project` | `--init` | Run the setup wizard for a new or existing workspace |
| `/project` | `--add-repo <path>` | Add a repo to the project and generate its docs |
| `/project` | `--refresh` | Regenerate all docs from current source code |
| `/project` | `--refresh --repo <name>` | Regenerate docs for a single repo only |

## How Auto-Refresh Works

A **PostToolUse hook** watches for file edits during Claude Code sessions and triggers incremental doc regeneration. A **pre-commit hook** runs a full refresh before each commit, so docs never drift from code. The two layers complement each other: the PostToolUse hook keeps docs current in real time, while the pre-commit hook catches anything that slipped through.

## Technology Agnostic

Tech stack inputs are free-text — type whatever you use (Next.js, Django, Rails, Spring Boot, etc.). When framework-specific knowledge is needed, the plugin queries context7 for up-to-date documentation rather than relying on baked-in assumptions.

## Future (v2+)

Workflow skills (TDD, debugging, code review, deployment) will be added as composable skill modules in v2.

## License

[MIT](LICENSE)
