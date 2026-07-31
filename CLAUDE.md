# CLAUDE.md

## Project Overview

**Fullstack Dev** is a Claude Code plugin that manages project structure, documentation, and tooling configuration across mono-repo and multi-repo codebases of any tech stack.

## Repository Structure

This is a mono-repo — there are no sub-repos. It is itself the source of the Fullstack Dev plugin (dogfooded via its own `/project --init`).

<!-- fullstack-dev:start -->

### Repos

This is a mono-repo. Key directories:
- **`agents/`** -- Subagent definitions dispatched by skills/commands
- **`commands/`** -- Slash command entry points
- **`skills/`** -- SKILL.md orchestrators + reference docs, one directory per command area
- **`hooks/`** -- Hook definitions shipped with the plugin
- **`scripts/`** -- Template scripts (e.g. pre-commit hook) installed into managed projects
- **`docs/`** -- This project's own generated docs (project/, specs/, plans/)

### Tech Stack

Markdown (agent/command/skill definitions), Bash (pre-commit hooks), JSON (hook/MCP config, plugin state). No compiled runtime, no package.json — see `docs/project/tech-stack.md` for the full breakdown.

### Build & Development Commands

#### Fullstack Dev (`.`)

```bash
# No install/build/test step — this is a markdown + JSON plugin.
# Verify changes by exercising the relevant command/skill in a
# Claude Code session (dogfooding) rather than a build pipeline.
npx skills add https://github.com/ravindra-gadekar/fullstack-dev.git --skill '*'   # install into a target project
```

### Git Workflow

1. Work on `local-dev` branch -- never commit directly to `main`
2. Commit using Conventional Commits: `<type>(<scope>): <summary>`
3. When pushing: `git push origin local-dev:<type>/<name>`
4. Create PR targeting `main` using MCP tools
5. Never push `local-dev` to remote
6. Never create local feature/fix branches
7. Use `/git sync` to pull latest from `main`

### GitHub Operations

**ALWAYS use `mcp__github__*` MCP tools for GitHub operations** (issues, PRs, repos, branches, search). Never use the CLI -- the MCP server is configured per-workspace with its own auth token.

### Architecture Reference -- Lookup Order

When you need to understand the codebase:

1. **Read CONTEXT.md** -- cross-repo domain model, data flow, decisions, conventions
2. **Read docs/project/architecture.md** -- unified system architecture
3. **Read the relevant ARCHITECTURE.md** -- repo-specific structure, catalogs, patterns
4. **Read source files** -- only when the above don't have what you need

### Documentation Structure

```text
docs/
├── project/     # Architecture, tech stack, brand
├── specs/       # Design specs from brainstorming
└── plans/       # Implementation plans
```

<!-- fullstack-dev:end -->
