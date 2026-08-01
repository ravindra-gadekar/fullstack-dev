# Fullstack Dev Architecture

## Purpose

This repo is the source of the **Fullstack Dev** Claude Code plugin itself — the commands, agents, and skills that get installed into other people's projects via `npx skills add`. It is not an application; it is a library of markdown-defined prompts, decision trees, and templates that Claude Code loads and executes.

## Directory Structure

```
fullstack-dev/
├── commands/         # Slash command entry points (/project, /brainstorm, /plan, /implement, /debug, /fix, /refactor, /git, /gitignore)
├── skills/           # SKILL.md orchestrators + reference/ decision trees & templates + agents/ subdirectory (init, scanner, refresh, repo, implementer, task-reviewer, security-reviewer, plan-reviewer, debugger, refactor, grill), one directory per command area
├── .agents/          # Local skills-add installed copy of agents (managed by the skills CLI)
├── .claude/          # Local skills-add installed copy of skills (managed by the skills CLI)
├── docs/             # This project's own generated docs (project/, specs/, plans/) — dogfooding the plugin on itself
├── LICENSE
├── README.md
└── skills-lock.json  # Lockfile for `npx skills add` installs
```

## Key Patterns

### Command → Skill → Agent dispatch

Each slash command in `commands/*.md` is a thin entry point that loads the matching `skills/<name>/SKILL.md`. The skill orchestrates flow (mode detection, argument parsing) and dispatches a specialized agent from `agents/*.md` via the `Agent` tool for the actual work.

**Example:**
```
commands/project.md  -->  skills/project/SKILL.md  -->  Agent(init-agent)
                                                     -->  skills/project/agents/init-agent.md reads skills/project/reference/*.md
```

### Reference-doc-driven agents

Agent definitions stay short; the authoritative logic (decision trees, exact prompt text, JSON schemas, merge rules) lives in `skills/<name>/reference/*.md`. Agents are explicitly instructed to read these before acting, keeping a single source of truth per concern (e.g. gitignore patterns live only in `gitignore-catalog.md`).

**Example:**
```
skills/project/reference/init-flow.md      # wizard questions, decision tree
skills/project/reference/doc-templates.md  # file templates + merge rules
skills/project/reference/tools-setup.md    # MCP server configuration
```

### Marker-block merging

Any file this plugin generates that might coexist with user-owned content uses a `# >>> fullstack-dev... >>>` / `# <<< fullstack-dev... <<<` (or HTML-comment equivalent for `CLAUDE.md`) marker pair. Regeneration only ever touches content between the markers.

## Entry Points

| Entry Point | Type | Purpose |
|---|---|---|
| `commands/project.md` | Slash command | `/project --init`, `--refresh`, `--add-repo` |
| `commands/brainstorm.md` | Slash command | `/brainstorm` — spec generation |
| `commands/plan.md` | Slash command | `/plan` — implementation planning |
| `commands/implement.md` | Slash command | `/implement` — plan execution |
| `commands/debug.md` | Slash command | `/debug` — root-cause investigation |
| `commands/fix.md` | Slash command | `/fix` — apply a known fix |
| `commands/refactor.md` | Slash command | `/refactor` — codebase refactoring |
| `commands/git.md` | Slash command | `/git setup\|sync\|status\|publish` |
| `commands/gitignore.md` | Slash command | `/gitignore scan\|rebuild\|cleanup` |

## Dependencies

### Internal (other repos in workspace)

_None — this is a mono-repo with no sub-repos._

### External

| Dependency | Purpose |
|---|---|
| Claude Code | Runtime host that loads and executes this plugin's agents/commands/skills |
| `npx skills` CLI | Installs this plugin's skills into a target project (`skills-lock.json` tracks installed versions) |
| context7 MCP server | Documentation lookups used by agents when working in target projects |
| Git platform MCP servers (GitHub, GitLab, Bitbucket, Azure DevOps) | Git operations in target projects |

## Testing

| Type | Framework | Location |
|---|---|---|
| — | None (no automated test suite; this is a prompt/markdown plugin, verified via manual dogfooding and agent review passes) | — |
