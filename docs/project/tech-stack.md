# Tech Stack

## Languages & Frameworks

| Technology | Version | Used In | Purpose |
|---|---|---|---|
| Markdown | — | `agents/`, `commands/`, `skills/` | Agent prompts, command definitions, skill instructions/reference docs |
| Bash / POSIX sh | — | `scripts/pre-commit.sh`, `.git/hooks/pre-commit` | Pre-commit hooks (doc staging, gitignore enforcement) |
| JSON | — | `hooks/hooks.json`, `.claude/settings.json`, `.mcp.json`, `.fullstack-dev/config.json` | Hook configuration, MCP server configuration, plugin state |
| Node.js (via `npx`) | — | Installation (`npx skills add ...`), MCP servers (`context7`, git platform servers) | Package runner used to install the plugin and launch MCP servers |

## Databases

_None — this is a prompt/documentation-based Claude Code plugin with no runtime datastore._

## DevOps & Infrastructure

| Tool | Purpose |
|---|---|
| GitHub | Source hosting for `ravindra-gadekar/fullstack-dev` |
| `npx skills add` | Installation/distribution mechanism for the plugin's skills |
| Git hooks (`pre-commit`) | Auto-stage refreshed docs; enforce essential `.gitignore` patterns |

## AI/LLM Integration

| Provider/Tool | Purpose |
|---|---|
| Claude (Anthropic) / Claude Code | This plugin *is* a Claude Code plugin — all agents and commands run inside Claude Code sessions |
| context7 (MCP) | Up-to-date library/framework documentation lookups for agents |
| code-review-graph (MCP) | Structural codebase understanding for `/plan`, `/refactor`, `/implement` in managed target projects |

## Key Libraries

_None — no package.json / compiled dependencies. The plugin ships as markdown agent/command/skill definitions plus small bash scripts and JSON config templates._
