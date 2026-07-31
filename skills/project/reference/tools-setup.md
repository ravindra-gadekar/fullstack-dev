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
        "command": "uvx code-review-graph build --skip-flows --repo .",
        "timeout": 120000
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

## `.code-review-graphignore` Configuration

code-review-graph has built-in defaults and auto-respects `.gitignore`, but project-specific extras (docs, plugin metadata, framework caches) need an explicit ignore file. The plugin generates only patterns not covered by the built-in defaults.

### Built-in Defaults (for reference, not generated)

code-review-graph already excludes:
`node_modules/**`, `.git/**`, `__pycache__/**`, `*.pyc`, `.venv/**`, `venv/**`, `dist/**`, `build/**`, `.next/**`, `target/**`, `*.min.js`, `*.min.css`, `*.map`, `*.lock`, `package-lock.json`, `yarn.lock`, `*.db`, `*.sqlite`, `*.db-journal`, `.code-review-graph/**`

### Minimal Defaults (always included in generated file)

```gitignore
docs/
.fullstack-dev/
```

### Stack-Derived Extras

| Stack signal | Signal source | Extra patterns |
| --- | --- | --- |
| `node` or `typescript` | `repos[].stack` contains `"node"` or `"typescript"` | `coverage/`, `.nyc_output/` |
| `nextjs` | `repos[].stack` contains `"next.js"` | `storybook-static/` |
| `astro` | `repos[].stack` contains `"astro"` | `.astro/` |
| `python` | `repos[].stack` contains `"python"` | `.mypy_cache/`, `.pytest_cache/`, `.ruff_cache/`, `htmlcov/` |
| `iiidev` | `repos[].stack` contains `"iii.dev"` or `"motia"` | `.motia/`, `data/` |
| `frontend` (any) | `hasFrontend == true` | `storybook-static/`, `.storybook/` |
| Infrastructure | File-presence: `*.tf` or `docker-compose*` in repo | `.terraform/`, `terraform.tfstate*` |

### Marker Block Format

```gitignore
# >>> fullstack-dev:code-review-graph (do not edit this block) >>>

# Project metadata
docs/
.fullstack-dev/

# Node/TypeScript (stack-derived)
coverage/
.nyc_output/

# <<< fullstack-dev:code-review-graph <<<

# --- User entries below ---
```

### Multi-Repo Handling

A single `.code-review-graphignore` is generated at the workspace root. Patterns are the UNION of stack-derived extras across all `repos[].stack` entries. Root-relative patterns apply to all sub-repos. No per-sub-repo ignore files.

### Data Dependency

Generation runs AFTER `.gitignore` generation (§9.2) because it reads `gitIgnore.activeCategories`.

### Merge Rules (identical to `.gitignore` merge semantics)

- No `.code-review-graphignore` exists → create with full marker block
- File exists without marker block → prepend marker block, preserve existing content below
- Marker block exists → replace content between markers only, preserve user content outside
- If `gitIgnore.activeCategories` is empty or missing → fall back to minimal defaults only

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
- The plugin auto-creates `.claude/settings.local.json` with the correct structure whenever a required MCP secret is missing, asks the user directly for the value, and attempts to write it — falling back to printing the exact snippet only if the write is rejected. See "Secret Prompt & Write Flow" below.

**Application runtime secrets** — consumed by the target app at runtime (e.g. a database URL, a third-party API key the app's own code calls):
- These go in `.env` (which must be gitignored) as before.
- `.env.example` (tracked in git) documents required variable names with empty values.
- Unaffected by the MCP-secrets change above — this category of secret was already handled correctly.

### Secret Prompt & Write Flow

Whenever a required MCP-server secret (e.g. `GITHUB_TOKEN`) is missing from `.claude/settings.local.json`, follow this sequence — used identically by first-run generation and health-check.

**Split responsibility — this matters.** Steps 1 and 5-6 (skeleton creation, never-echo, never-overwrite) are safe to run inside a dispatched agent. Step 2 (asking the user) and step 4 (writing the real value) can **only** happen at the orchestrating conversation level — the top-level assistant loop, not a subagent dispatched via the Agent tool. Verified live: a dispatched `init-agent` cannot ask the user anything interactively, regardless of what tools its frontmatter grants — it runs to completion and returns a result, it cannot pause mid-task for a human reply. A dispatched agent that hits a missing secret must create the skeleton (step 1), then **report the missing variable name back to the orchestrator** instead of attempting to ask or write. The orchestrator picks up from there.

1. **Ensure the skeleton exists.** If `.claude/settings.local.json` doesn't exist, create it with an empty `env` block. If it exists but lacks the required key, merge the key in with an empty string value. This step never involves a secret value — it's always safe to automate, including inside a dispatched agent.
2. **Orchestrator asks the user directly**, as plain conversational text — **not** the `AskUserQuestion` tool, which requires ≥2 discrete choices and cannot represent open-ended free-text secret entry:
   ```
   ? GitHub Personal Access Token (for the github MCP server, stored only in
     .claude/settings.local.json — never committed): _______________
     (reply with the token, or say "skip" to leave it blank for now)
   ```
3. **Skipped** — leave the skeleton in place, print the exact snippet and file path for manual entry, and continue. This is not a failure.
4. **Value provided** — the orchestrator attempts to write it into the `env` block directly via the normal file-write path (not the dispatched agent — it already returned).
   - **Write succeeds** — confirm briefly ("Saved to `.claude/settings.local.json`") without echoing the value back.
   - **Write is rejected** (e.g. blocked by a permission policy) — do not retry with a different mechanism to work around the rejection. Fall back to printing the exact snippet with the value the user just gave, so they can paste it in themselves, and note that the automatic write wasn't possible in this session.
5. **Never log or echo the value** in any report, commit message, or chat-facing summary, regardless of which path was taken.
6. **Never overwrite an existing non-empty value** for a key without asking the user first — a value already present may be intentional and current.

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
- [ ] `.claude/settings.local.json` is listed in `.gitignore`'s `secrets` category (never committed)

---

## Project-Level Safety

### Scope

- The plugin only writes to project-level files (`.mcp.json`, `.claude/settings.json`, `.claude/settings.local.json` in the project root)
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
| `.claude/settings.local.json` (project root) | Project | Yes — limited to creating/merging the key skeleton and writing a value the user explicitly provides via the Secret Prompt & Write Flow. Never invents or overwrites an existing value without asking. |
| `~/.claude/.mcp.json` | User | No |
| `~/.claude/settings.json` | User | No |
| `~/.claude/settings.local.json` | User | No |
