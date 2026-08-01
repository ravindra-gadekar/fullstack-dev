# Architecture

## System Overview

Fullstack Dev is a Claude Code plugin, not a running application. It ships as a set of markdown-defined **commands**, **agents**, and **skills** that Claude Code loads at session time. When a user runs a slash command (e.g. `/project --init`) inside a *target* project, the plugin's agents read reference docs from this repo, then read/write files in the target project's working directory (config, docs, hooks, MCP config). There are no servers, ports, or databases — the "architecture" is a prompt/instruction pipeline plus file-generation logic.

### Service Map

| Module | Directory | Tech | Role |
|---|---|---|---|
| Commands | `commands/` | Markdown | Slash-command entry points (`/project`, `/brainstorm`, `/plan`, `/implement`, `/debug`, `/fix`, `/refactor`, `/git`, `/gitignore`) |
| Skills | `skills/` | Markdown (`SKILL.md` + `reference/`) | Orchestration layer + authoritative decision trees/templates per command |
| Agents | `skills/*/agents/` | Markdown | Specialized subagents dispatched by their owning skill (init, scanner, refresh, repo, implementer, task-reviewer, security-reviewer, plan-reviewer, debugger, refactor, grill) |

## Services

### Commands (`commands/`)

- **Repo:** `commands/`
- **Purpose:** Each `.md` file is a slash command definition (frontmatter + prompt) that Claude Code registers. Commands are thin — they point to the corresponding skill for the real logic.
- **Tech:** Markdown with YAML frontmatter
- **Communication:** Invoked directly by the user; dispatches to a `Skill` tool call and/or an `Agent` tool call

### Skills (`skills/`)

- **Repo:** `skills/<name>/SKILL.md` + `skills/<name>/reference/*.md`
- **Purpose:** Each skill packages the full behavior for one command area (project, brainstorm, plan, implement, debug, fix, refactor, git, gitignore). `SKILL.md` is the orchestrator; `reference/` holds decision trees, templates, and merge rules the dispatched agent must follow.
- **Tech:** Markdown
- **Communication:** Loaded by the `Skill` tool when a command invokes it; references are read directly by agents via the `Read` tool

### Agents (`skills/*/agents/`)

- **Repo:** `skills/<owning-skill>/agents/*.md`
- **Purpose:** Specialized, tool-scoped subagents (e.g. `init-agent`, `scanner-agent`, `refresh-agent`, `debugger-agent`, `implementer-agent`) that execute a flow end-to-end inside a target project's working directory. All 11 agents hold the `context7` MCP grant for version-accurate library/framework lookups — see `skills/project/reference/context7-usage.md`.
- **Tech:** Markdown with YAML frontmatter (`tools`, `model`, `maxTurns`, `effort`, `mcpServers`)
- **Communication:** Dispatched via the `Agent` tool by a skill or command; reads reference docs, then reads/writes files in the target project

## Data Storage

### Databases

_None._

### Caches (if applicable)

_None — no runtime process to cache for._

### File Storage (if applicable)

All persistent state lives as plain files: this repo's own `agents/`, `commands/`, `skills/` markdown, plus (in each *managed* target project) `.fullstack-dev/config.json`, `CONTEXT.md`, `docs/project/*.md`, per-repo `ARCHITECTURE.md`, `CLAUDE.md`.

## External Integrations

| Integration | Type | Purpose |
|---|---|---|
| context7 | MCP server | Up-to-date library/framework documentation for agents working in target projects — wired into all 11 agents per `skills/project/reference/context7-usage.md` |
| GitHub / GitLab / Bitbucket / Azure DevOps MCP servers | MCP server | Git-platform operations (issues, PRs, branches) in target projects, auto-detected from remotes |
| code-review-graph | MCP server | Structural codebase understanding for token-efficient reviews in target projects |
| Agentation | MCP server (optional) | Visual UI feedback for frontend target projects |

## Authentication & Authorization

Not applicable to this repo directly — this plugin has no auth surface of its own. MCP servers it configures in target projects (e.g. `github`) use `${GITHUB_TOKEN}`-style environment variable references, never hardcoded secrets, per `skills/project/reference/tools-setup.md`.

## Deployment

Distributed via `npx skills add https://github.com/ravindra-gadekar/fullstack-dev-plugin.git --skill '*'`. There is no build or deploy pipeline — the repo's markdown/JSON content is consumed directly by Claude Code at install/session time.
