# CONTEXT.md

## Domain Model

### Entities

| Entity | Description | Source |
|---|---|---|
| Agent | A specialized Claude Code subagent (e.g. `init-agent`, `debugger-agent`) with its own tools, model, and prompt | `skills/<owning-skill>/agents/*.md` |
| Command | A slash command (`/project`, `/brainstorm`, `/plan`, `/implement`, `/debug`, `/fix`, `/refactor`, `/git`, `/gitignore`) exposed to the user | `commands/*.md` |
| Skill | A packaged workflow (`SKILL.md` + `reference/*.md`) that a command or agent loads for detailed instructions | `skills/*/SKILL.md` |
| Config | The target project's `.fullstack-dev/config.json` — drives all generation decisions for a given project this plugin manages | `skills/project/reference/doc-templates.md` Section 7 |
| Reference Doc | A markdown file under `skills/*/reference/` containing decision trees, templates, and merge rules that agents read before acting | `skills/*/reference/*.md` |

### Relationships

- A **Command** dispatches to one or more **Agents** (e.g. `/project --init` dispatches to `init-agent`), often via a **Skill**'s `SKILL.md` orchestration layer.
- An **Agent** reads one or more **Reference Docs** before executing a flow, and writes/updates a **Config** file plus generated documentation in the target project it is managing.
- A **Skill** groups a command's reference material so it can be installed independently via `npx skills add`.

### Glossary

| Term | Meaning |
|---|---|
| Target project | The user's codebase that this plugin manages (creates docs/config for) — distinct from this plugin's own repo |
| Meta-repo | The root repo tracking project-level docs/config in a multi-repo setup |
| local-dev | The persistent working branch convention enforced across all commands |
| Marker block | A `# >>> fullstack-dev... >>> ... # <<< fullstack-dev... <<<` delimited region used to make generated content mergeable with user content |

## Data Flow

This is a documentation/prompt-based Claude Code plugin — there is no runtime service or database. "Data flow" here means how instructions and generated artifacts move through the system.

### Request Lifecycle

1. User invokes a slash command (e.g. `/project --init`) in Claude Code inside a target project.
2. The command's `SKILL.md` orchestrator determines mode (first-run vs. health-check) and dispatches an agent (e.g. `init-agent`).
3. The agent reads the relevant `reference/*.md` docs for exact templates, decision trees, and merge rules.
4. The agent writes/merges config and documentation files into the target project's working directory, never overwriting user content outside marker blocks.
5. The agent reports a structured summary back to the user.

### Event Flow (if applicable)

`.claude/settings.json` PostToolUse hooks fire after `Edit`/`Write` tool calls in a managed project, running a targeted refresh-hint script (`.fullstack-dev/refresh-hint.sh`) that matches the changed file against the refresh-agent's mapping table and outputs a specific reminder naming which doc to update — or nothing if the file doesn't match any rule. No other event-driven communication exists — this is a self-contained plugin, not a running service.

## Conventions

### Naming

| Context | Convention | Example |
|---|---|---|
| Agent files | `<role>-agent.md` in `skills/<owning-skill>/agents/` | `skills/project/agents/init-agent.md`, `skills/debug/agents/debugger-agent.md` |
| Command files | `<verb>.md` in `commands/`, matches the skill name | `project.md` -> `skills/project/` |
| Skill directories | kebab-case matching the command name | `skills/gitignore/` |
| Reference docs | descriptive kebab-case under `skills/<skill>/reference/` | `init-flow.md`, `doc-templates.md` |
| Marker blocks | `fullstack-dev` (docs) / `fullstack-dev:gitignore` (gitignore) / `fullstack-dev:code-review-graph` (graph ignore) — distinct, coexisting markers | `.git/hooks/pre-commit`, `.code-review-graphignore` |

### Patterns

- **Reference-doc-driven agents**: agent `.md` files are thin orchestration layers; the authoritative decision trees, templates, and validation rules live in `skills/*/reference/*.md`, which agents are instructed to read before executing.
- **Marker-block merging**: every generated file that may coexist with user content (`.gitignore`, `CLAUDE.md`, `.claude/settings.json`, `.mcp.json`, pre-commit hooks) uses append/replace-within-markers semantics, never blind overwrite.
- **Wizard + health-check duality**: `/project --init` behaves as a first-run wizard when no config exists, and as an idempotent health check with auto-fix when config already exists.

### Decisions

- The plugin is distributed as markdown + JSON (no compiled runtime) so it can be installed via `npx skills add` without a build step.
- `local-dev` is enforced as the single persistent working branch across all commands to avoid branch sprawl and simplify the stash/sync safety net.
