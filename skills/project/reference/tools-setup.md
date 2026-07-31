# Tools and MCP Setup Reference

Reference for the init-agent when configuring MCP servers and developer tools in a target project. This is the single reference for all optional MCP tools and integrations.

---

## What is context7?

context7 is an MCP server that provides up-to-date documentation for any technology (frameworks, libraries, SDKs, APIs, CLI tools). It is free to use, requires no API keys, and runs via npx.

Use it to fetch current docs for technologies like React, Next.js, Prisma, Tailwind, Django, Express, and hundreds more. It ensures the agent works with the latest API surfaces rather than relying on potentially stale training data.

---

## context7 Configuration

Add the following to `.mcp.json` in the project root:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

No API keys or environment variables required.

---

## Merge Rules for .mcp.json

**NEVER overwrite existing MCP configuration. Always merge.**

These merge rules apply to ALL tools configured via `.mcp.json` — context7, git platform servers, code-review-graph, Agentation, and any future additions.

If `.mcp.json` already exists in the project root, follow this procedure:

1. Read the existing `.mcp.json` file
2. Parse it as JSON
3. Add new servers (e.g., `context7`, `github`, `code-review-graph`, `agentation`) to the `mcpServers` object — only if they are not already present
4. Preserve ALL existing servers and their configuration unchanged
5. Write the merged result back to `.mcp.json`
6. Validate that the output is syntactically correct JSON

### Merge pseudocode

```
existing = readJSON(".mcp.json")
existing.mcpServers ??= {}

if (!existing.mcpServers["context7"]) {
  existing.mcpServers["context7"] = { ... }
}

if (!existing.mcpServers["github"]) {
  existing.mcpServers["github"] = { ... }
}

if (!existing.mcpServers["code-review-graph"]) {
  existing.mcpServers["code-review-graph"] = { ... }
}

if (!existing.mcpServers["agentation"]) {
  existing.mcpServers["agentation"] = { ... }
}

// Repeat for any other servers being added

writeJSON(".mcp.json", existing)
```

If `.mcp.json` does not exist, create it with the full configuration.

---

## Git Platform MCP Configuration

Detect the git platform from the project's remote URLs and configure the appropriate MCP server.

### Detection

```bash
git remote get-url origin
```

Match the URL against known platforms, then add the corresponding server to `.mcp.json` using the merge rules above.

---

### GitHub (github.com detected)

**Default: zero-install remote HTTP endpoint.** The previous `github-mcp-server` local-binary/stdio approach is deprecated upstream and requires a manual, separate binary install — do not generate it by default.

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp",
      "headers": {
        "Authorization": "Bearer ${GITHUB_TOKEN}"
      }
    }
  }
}
```

Required `.claude/settings.local.json` entry (user-scoped, never committed — see "Secrets Handling" below):

```json
{
  "env": {
    "GITHUB_TOKEN": "<personal-access-token>"
  }
}
```

Required `.env.example` entry: **none.** `GITHUB_TOKEN` is an MCP-server secret, not an application-runtime secret — it never appears in `.env`/`.env.example`.

**Trust boundary:** this sends `Authorization: Bearer ${GITHUB_TOKEN}` over HTTPS to `api.githubcopilot.com`, a GitHub-hosted proxy — not a fully local flow. For network-restricted environments, use the Docker fallback instead:

```bash
claude mcp add github -e GITHUB_OAUTH_CALLBACK_PORT=8085 -- docker run -i --rm -p 127.0.0.1:8085:8085 -e GITHUB_OAUTH_CALLBACK_PORT ghcr.io/github/github-mcp-server
```

The plugin does not auto-detect network reachability or auto-select between these two — remote HTTP is the generated default; the Docker command above is documented for the user to run manually if needed.

---

### Bitbucket (bitbucket.org detected)

Bitbucket MCP server support is pending. When detected:

1. Log a note that Bitbucket was detected
2. Add a placeholder entry to `.mcp.json`:

```json
{
  "mcpServers": {
    "bitbucket": {
      "_comment": "Bitbucket MCP server — not yet configured. See https://github.com/search?q=bitbucket+mcp+server for community options.",
      "command": "TODO",
      "args": []
    }
  }
}
```

3. Inform the user that Bitbucket MCP is not yet auto-configured and may require manual setup

---

### GitLab (gitlab.com detected)

GitLab MCP server support is pending. When detected:

1. Log a note that GitLab was detected
2. Add a placeholder entry to `.mcp.json`:

```json
{
  "mcpServers": {
    "gitlab": {
      "_comment": "GitLab MCP server — not yet configured. See https://github.com/search?q=gitlab+mcp+server for community options.",
      "command": "TODO",
      "args": []
    }
  }
}
```

3. Inform the user that GitLab MCP is not yet auto-configured and may require manual setup

---

### Azure DevOps (dev.azure.com detected)

Azure DevOps MCP server support is pending. When detected:

1. Log a note that Azure DevOps was detected
2. Add a placeholder entry to `.mcp.json`:

```json
{
  "mcpServers": {
    "azure-devops": {
      "_comment": "Azure DevOps MCP server — not yet configured. See https://github.com/search?q=azure+devops+mcp+server for community options.",
      "command": "TODO",
      "args": []
    }
  }
}
```

3. Inform the user that Azure DevOps MCP is not yet auto-configured and may require manual setup

---

### No Remotes (blank project)

If no git remotes are found:

1. Ask the user which git platform they plan to use (GitHub, Bitbucket, GitLab, Azure DevOps, or none)
2. Configure the corresponding MCP server based on their answer
3. If they say "none" or are unsure, skip git platform MCP configuration entirely

---

## code-review-graph MCP Configuration

code-review-graph is an MCP server that builds a persistent, incremental knowledge graph of the codebase using Tree-sitter. It enables token-efficient, context-aware code reviews and structural impact analysis. It requires no API keys and runs via uvx.

### MCP Server

Add the following to `.mcp.json` in the project root:

```json
{
  "mcpServers": {
    "code-review-graph": {
      "command": "uvx",
      "args": ["code-review-graph", "mcp", "--repo", "."]
    }
  }
}
```

No API keys or environment variables required.

### Hooks

Add the following hooks to `.claude/settings.json` in the project root:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write|Bash|PowerShell",
      "hooks": [{
        "type": "command",
        "command": "uvx code-review-graph update --skip-flows --repo .",
        "timeout": 30000
      }]
    }],
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "uvx code-review-graph status --repo .",
        "timeout": 10000
      }]
    }]
  }
}
```

### Hooks Merge Note

When code-review-graph hooks are added, they merge alongside the existing fullstack-dev PostToolUse hook. The result is two PostToolUse entries:

1. **Fullstack-dev hook** — matcher `Edit|Write`, echo reminder (1s timeout)
2. **code-review-graph hook** — matcher `Edit|Write|Bash|PowerShell`, graph update (30s timeout)

The code-review-graph hook has a broader matcher (includes Bash/PowerShell). Both fire on `Edit|Write` operations — this is intentional. The echo hook is instant, and the graph update runs in parallel.

---

## Agentation

Agentation provides agent orchestration and monitoring capabilities. It integrates via an MCP server and an optional frontend component for development-time visibility.

### MCP Server

Add the following to `.mcp.json` in the project root:

```json
{
  "mcpServers": {
    "agentation": {
      "command": "npx",
      "args": ["-y", "agentation-mcp@latest"]
    }
  }
}
```

> **Note:** The exact MCP server package name must be verified at implementation time. If Agentation does not provide an MCP server, use its webhook/endpoint integration instead and document the alternative configuration.

### npm Dependency (frontend repos)

In frontend repositories, install Agentation as a dev dependency:

```bash
npm install agentation -D
```

### Frontend Component

Add the `<Agentation />` component to the app's dev-only wrapper. This component provides development-time agent visibility and should only be included in development — exclude it from production builds.

---

## Secrets Handling

### Principles

Two distinct kinds of secret exist, and they never live in the same place:

**MCP server secrets** — consumed by Claude Code itself to authenticate an MCP server (e.g. `GITHUB_TOKEN` for the `github` server's `Authorization` header):
- `.mcp.json` uses `${VAR_NAME}` syntax to reference them — it NEVER contains actual secret values.
- The actual value goes in `.claude/settings.local.json`'s `env` block (user-scoped, never committed). Claude Code does **not** read `.env` for `${VAR}` expansion in `.mcp.json` — putting an MCP secret in `.env` silently fails to connect.
- The plugin never writes a real value into `.claude/settings.local.json` itself — it only prints the exact snippet for the user to fill in (see "No Agent-Authored Secret Writes" in the health-check flow).

**Application runtime secrets** — consumed by the target app at runtime (e.g. a database URL, a third-party API key the app's own code calls):
- These go in `.env` (which must be gitignored) as before.
- `.env.example` (tracked in git) documents required variable names with empty values.
- Unaffected by the MCP-secrets change above — this category of secret was already handled correctly.

### Example

`.mcp.json` (tracked in git):

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp",
      "headers": {
        "Authorization": "Bearer ${GITHUB_TOKEN}"
      }
    }
  }
}
```

`.claude/settings.local.json` (user-scoped, never committed):

```json
{
  "env": {
    "GITHUB_TOKEN": "<personal-access-token>"
  }
}
```

`.env.example` (tracked in git) — no `GITHUB_TOKEN` entry. It's an MCP-server secret, not an application-runtime one.

### Checklist

- [ ] `.env` is listed in `.gitignore`
- [ ] `.env.example` exists with all required variable names (no values)
- [ ] `.mcp.json` references secrets only via `${VAR_NAME}` syntax
- [ ] No actual tokens appear in any tracked file

---

## Project-Level Safety

### Scope

- The plugin only writes to project-level files (`.mcp.json` in the project root)
- The plugin NEVER modifies global/user-level Claude Code configuration (`~/.claude/settings.json`, `~/.claude/.mcp.json`, etc.)

### context7 layering

- context7 configured at the project level (`.mcp.json`) merges automatically with any user-level context7 configuration
- If the user already has context7 at the user level, the project-level entry does not conflict — both coexist safely
- Having context7 at both levels is harmless; the MCP client deduplicates

### Summary

| File | Scope | Plugin may modify? |
|------|-------|--------------------|
| `.mcp.json` (project root) | Project | Yes |
| `.claude/settings.json` (project root) | Project | Yes |
| `.claude/settings.local.json` (project root) | Project | Read-only — the plugin prints instructions for the user to edit this file directly; it never writes to it itself. |
| `~/.claude/.mcp.json` | User | No |
| `~/.claude/settings.json` | User | No |
| `~/.claude/settings.local.json` | User | No |
