# context7 and MCP Setup Reference

Reference for the init-agent when configuring MCP servers in a target project.

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

If `.mcp.json` already exists in the project root, follow this procedure:

1. Read the existing `.mcp.json` file
2. Parse it as JSON
3. Add new servers (e.g., `context7`, `github`) to the `mcpServers` object — only if they are not already present
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

```json
{
  "mcpServers": {
    "github": {
      "command": "github-mcp-server",
      "args": ["stdio"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

Required `.env` entry:
```
GITHUB_TOKEN=<personal-access-token>
```

Required `.env.example` entry:
```
GITHUB_TOKEN=
```

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

## Secrets Handling

### Principles

- `.mcp.json` uses `${VAR_NAME}` syntax to reference environment variables — it NEVER contains actual secret values
- Actual tokens and secrets go in `.env` (which must be gitignored)
- `.env.example` (tracked in git) documents required variables with empty values so collaborators know what to set up

### Example

`.mcp.json` (tracked in git):
```json
{
  "mcpServers": {
    "github": {
      "command": "github-mcp-server",
      "args": ["stdio"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

`.env` (gitignored):
```
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

`.env.example` (tracked in git):
```
GITHUB_TOKEN=
```

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
| `~/.claude/.mcp.json` | User | No |
| `~/.claude/settings.json` | User | No |
| `~/.claude/settings.local.json` | User | No |
