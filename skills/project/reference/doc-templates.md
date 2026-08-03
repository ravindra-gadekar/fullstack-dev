# Document Templates

Templates for all generated documentation files. Referenced by init-agent (initial generation) and scanner-agent (content population from code scans).

---

## How Templates Are Used

1. **Init-agent** creates files using these templates during `/project --init`.
2. **Scanner-agent** populates placeholder sections with data extracted from code scans and wizard answers.
3. **Refresh-agent** updates existing docs surgically — it does not regenerate from templates. Templates are only used for initial creation.

Placeholder text in angle brackets (`<...>`) is replaced with real content. Sections marked `(conditional)` are only included when the condition is met.

---

## 1. CONTEXT.md

**Location:** Workspace root (`CONTEXT.md`)
**Purpose:** Cross-repo domain model, data flow, and conventions. The single source of truth for domain language.
**Created by:** init-agent + scanner-agent
**Updated by:** refresh-agent (incremental, on schema/model file changes)

### Template

```markdown
# CONTEXT.md

## Domain Model

### Entities

| Entity | Description | Source |
|---|---|---|
| <EntityName> | <what it represents> | <repo/file where defined> |

### Relationships

<how entities relate to each other — e.g., "A User owns many Projects">

### Glossary

| Term | Meaning |
|---|---|
| <term> | <definition used consistently across the codebase> |

## Data Flow

<how data moves between services, databases, and external systems>

### Request Lifecycle

1. <step 1 — e.g., client sends request to frontend>
2. <step 2 — e.g., frontend calls API endpoint>
3. <step 3 — e.g., API processes and writes to database>

### Event Flow (if applicable)

<event-driven communication between services>

## Conventions

### Naming

| Context | Convention | Example |
|---|---|---|
| Files | <pattern> | <example> |
| Functions | <pattern> | <example> |
| Database collections | <pattern> | <example> |

### Patterns

<architectural patterns adopted — e.g., event-driven steps, repository pattern>

### Decisions

<key technical decisions and their rationale — brief, not full ADRs>
```

### Population Rules

- **Entities** are extracted from database models/schemas, TypeScript interfaces, and API resource names.
- **Glossary** is seeded from entity names, then enriched manually.
- **Data Flow** is inferred from API routes, event handlers, and inter-service calls.
- **Conventions** are detected from file naming patterns and code style.

---

## 2. docs/project/architecture.md

**Location:** `docs/project/architecture.md`
**Purpose:** Unified system architecture spanning all repos. High-level view of how services connect.
**Created by:** init-agent + scanner-agent
**Updated by:** refresh-agent (incremental, on route/controller/step file changes)

### Template

```markdown
# Architecture

## System Overview

<high-level architecture description — what the system does, how services are arranged>

### Service Map

| Service | Repo | Tech | Port/URL |
|---|---|---|---|
| <service name> | <repo name> | <framework/runtime> | <dev URL or port> |

## Services

### <Service Name>

- **Repo:** `<repo-name>/`
- **Purpose:** <what this service does>
- **Tech:** <framework, language, runtime>
- **Communication:** <how it talks to other services — REST, events, direct import>

<repeat for each service>

## Data Storage

### Databases

| Database | Type | Used By | Purpose |
|---|---|---|---|
| <name> | <MongoDB/PostgreSQL/etc.> | <which services> | <what it stores> |

### Caches (if applicable)

<caching layer details>

### File Storage (if applicable)

<object storage, local filesystem, CDN>

## External Integrations

| Integration | Type | Purpose |
|---|---|---|
| <name> | <API/MCP/webhook/SDK> | <what it does> |

## Authentication & Authorization

<how auth works across services — tokens, sessions, shared middleware>

## Deployment

<how the system is deployed — platforms, CI/CD, environment strategy>
```

### Population Rules

- **Service Map** is built from `config.json` repos array plus detected dev server ports.
- **Services** are populated by scanning each repo's entry points, package.json, and framework config.
- **Data Storage** is detected from database connection strings, ORM config, and model files.
- **External Integrations** are found by scanning for HTTP client usage, SDK imports, and MCP server configs.

---

## 3. docs/project/tech-stack.md

**Location:** `docs/project/tech-stack.md`
**Purpose:** Centralized record of all technologies used across the workspace.
**Created by:** init-agent + scanner-agent
**Updated by:** refresh-agent (incremental, on package.json/config file changes)

### Template

```markdown
# Tech Stack

## Languages & Frameworks

| Technology | Version | Used In | Purpose |
|---|---|---|---|
| <name> | <version> | <repo(s)> | <role — e.g., frontend framework, API runtime> |

## Databases

| Database | Version | Purpose |
|---|---|---|
| <name> | <version or "managed"> | <what it stores> |

## DevOps & Infrastructure

| Tool | Purpose |
|---|---|
| <name> | <what it does — e.g., CI/CD, hosting, containerization> |

## AI/LLM Integration

| Provider/Tool | Purpose |
|---|---|
| <name> | <what it does — e.g., agent orchestration, content generation> |

## Key Libraries

| Library | Version | Used In | Purpose |
|---|---|---|---|
| <name> | <version> | <repo(s)> | <role> |
```

### Population Rules

- **Languages & Frameworks** are extracted from `package.json` (dependencies + devDependencies), framework config files, and file extensions.
- **Versions** are read from `package.json` or lock files. Use the specified range (e.g., `^14.0.0`), not resolved versions.
- **Databases** come from wizard answers and connection config detection.
- **AI/LLM Integration** comes from wizard answers and detected LLM SDK imports.
- **Key Libraries** includes only significant dependencies (auth, ORM, UI framework, testing), not every transitive package.

---

## 4. Per-repo BRAND.md

**Location:** `<repo-name>/BRAND.md` (inside each repo root)
**Purpose:** Design tokens extracted from the codebase. Only generated for repos whose `type` is `frontend` or `fullstack`.
**Created by:** init-agent + scanner-agent (conditional: repo's `type` is `frontend` or `fullstack`)
**Updated by:** refresh-agent (incremental, on CSS/Tailwind/theme file changes within that repo)

### Template

```markdown
# Brand

## Colors

### Primary Palette

| Token | Value | Usage |
|---|---|---|
| <name> | <hex/rgb/hsl> | <where used — e.g., buttons, headings> |

### Neutral Palette

| Token | Value | Usage |
|---|---|---|
| <name> | <hex/rgb/hsl> | <where used — e.g., text, borders, backgrounds> |

### Semantic Colors (if applicable)

| Token | Value | Usage |
|---|---|---|
| success | <value> | <positive states> |
| warning | <value> | <caution states> |
| error | <value> | <error states> |

## Typography

### Fonts

| Role | Font Family | Fallback |
|---|---|---|
| Heading | <font name> | <fallback stack> |
| Body | <font name> | <fallback stack> |
| Mono | <font name> | <fallback stack> |

### Scale

| Name | Size | Weight | Usage |
|---|---|---|---|
| <name> | <rem/px> | <weight> | <where used> |

## Spacing & Layout

### Spacing Scale

| Token | Value |
|---|---|
| <name> | <rem/px> |

### Breakpoints

| Name | Value | Description |
|---|---|---|
| sm | <value> | <device class> |
| md | <value> | <device class> |
| lg | <value> | <device class> |
| xl | <value> | <device class> |

### Grid

<grid system details — columns, gutters, max-width>

## Component Patterns (if applicable)

<border-radius tokens, shadow tokens, transition defaults>
```

### Population Rules

- **Colors** are extracted from Tailwind config (`theme.extend.colors`), CSS custom properties, or SCSS variables.
- **Typography** is extracted from font imports, Tailwind font config, and global CSS.
- **Spacing** is extracted from Tailwind spacing config or CSS custom properties.
- **Breakpoints** are extracted from Tailwind screens config or media query definitions.
- If the frontend uses a component library (e.g., shadcn/ui), note the library and its theme configuration method.

---

## 5. Per-repo ARCHITECTURE.md

**Location:** `<repo-name>/ARCHITECTURE.md` (inside each repo root)
**Purpose:** Repo-specific architecture, directory catalog, patterns, and entry points.
**Created by:** init-agent + scanner-agent
**Updated by:** refresh-agent (incremental, on structural file changes within the repo)

### Template

```markdown
# <Repo Name> Architecture

## Purpose

<one-paragraph description of what this repo does and its role in the system>

## Directory Structure

```
<repo-name>/
+-- <dir>/          # <purpose>
+-- <dir>/          # <purpose>
+-- <file>          # <purpose>
```

## Key Patterns

### <Pattern Name>

<description of the architectural pattern — e.g., "Event-driven steps", "App Router file-based routing">

**Example:**
```
<brief code or file structure example showing the pattern>
```

<repeat for each significant pattern>

## Entry Points

| Entry Point | Type | Purpose |
|---|---|---|
| <file or route> | <HTTP/event/cron/CLI> | <what it handles> |

## Dependencies

### Internal (other repos in workspace)

| Dependency | How |
|---|---|
| <repo name> | <communication method — e.g., HTTP calls to backend-api> |

### External

| Dependency | Purpose |
|---|---|
| <name> | <what it provides> |

## Testing

| Type | Framework | Location |
|---|---|---|
| <unit/integration/e2e> | <framework name> | <directory> |
```

### Population Rules

- **Directory Structure** is generated from a shallow directory listing (depth 2), excluding `node_modules/`, `.git/`, and other standard ignores.
- **Key Patterns** are inferred from framework conventions (e.g., Next.js App Router, iii.dev steps) and repeated structural patterns.
- **Entry Points** are detected from route files, handler exports, cron definitions, and CLI entry points.
- **Dependencies** are detected from import statements, HTTP client usage, and config files referencing other services.
- **Testing** is detected from test runner config (vitest, jest, playwright) and test file locations.

---

## 6. CLAUDE.md

**Location:** Workspace root (`CLAUDE.md`)
**Purpose:** Instructions for Claude Code. The primary file Claude reads to understand the project.
**Created by:** init-agent
**Updated by:** Never auto-updated. User owns this file. Plugin only manages its own marker block.

### Important: Append-Only with Marker Block

If a `CLAUDE.md` already exists, the plugin **MUST NOT overwrite it**. Instead, it appends its sections inside a marker block at the end of the file. The markers allow the plugin to find and update its own sections without touching user content.

```markdown
<!-- fullstack-dev:start -->
<!-- fullstack-dev:end -->
```

If no `CLAUDE.md` exists, the plugin generates the full file with the marker block wrapping the generated sections.

### Template (Full Generation)

When no `CLAUDE.md` exists, generate the entire file:

```markdown
# CLAUDE.md

## Project Overview

**<Project Name>** is <description from config.json>.

## Repository Structure

<conditional: mono-repo or multi-repo>

<!-- fullstack-dev:start -->

### Repos

<for multi-repo:>
- **`<repo-name>/`** -- <repo description> (<repo type>)

<for mono-repo:>
This is a mono-repo. Key directories:
- **`<dir>/`** -- <purpose>

### Tech Stack

<summary from docs/project/tech-stack.md — languages, frameworks, databases>

### Build & Development Commands

<for each repo:>
#### <Repo Name> (`<repo-name>/`)

```bash
<install command>     # install dependencies
<dev command>         # start dev server
<build command>       # build for production
<test command>        # run tests
<lint command>        # run linter
```

### Git Workflow

1. Work on `local-dev` branch -- never commit directly to `<targetBranch>`
2. Commit using Conventional Commits: `<type>(<scope>): <summary>`
3. When pushing: `git push origin local-dev:<type>/<name>`
4. Create PR targeting `<targetBranch>` using MCP tools
5. Never push `local-dev` to remote
6. Never create local feature/fix branches
7. Use `/git sync` to pull latest from `<targetBranch>`

<conditional: multi-repo with multiple repos>

### Per-Repo Target Branches

| Repo          | Target Branch       |
|---------------|---------------------|
| <repo.name>   | <repo.targetBranch> |

Push and PR commands automatically target the correct branch per repo.

</conditional>

### <Git Platform> Operations

**ALWAYS use `mcp__<platform>__*` MCP tools for <platform> operations** (issues, PRs, repos, branches, search). Never use the CLI -- the MCP server is configured per-workspace with its own auth token.

### Architecture Reference -- Lookup Order

When you need to understand the codebase:

1. **Read CONTEXT.md** -- cross-repo domain model, data flow, decisions, conventions
2. **Read docs/project/architecture.md** -- unified system architecture
3. **Read the relevant ARCHITECTURE.md** -- repo-specific structure, catalogs, patterns
4. **Read the repo's BRAND.md** (if it has one) -- design tokens (for UI work)
5. **Read source files** -- only when the above don't have what you need

### Documentation Structure

```text
docs/
+-- project/     # Architecture, tech stack, brand
+-- specs/       # Design specs from brainstorming
+-- plans/       # Implementation plans
```

<!-- fullstack-dev:end -->
```

### Template (Append to Existing)

When `CLAUDE.md` already exists, append only the marker block at the end:

```markdown

<!-- fullstack-dev:start -->

## Repository Structure

<same content as above, starting from "### Repos">

<!-- fullstack-dev:end -->
```

### Section Population Rules

- **Project Overview** uses `projectName` and `description` from `config.json`.
- **Repos** list is built from `config.json` `repos` array.
- **Tech Stack** summary is a condensed version of `docs/project/tech-stack.md`.
- **Build commands** are detected from `package.json` scripts or framework conventions. Use placeholder comments when commands cannot be detected.
- **Git Workflow** uses `repos[i].targetBranch` from `config.json`. Multi-repo table is included when config has multiple repos. Regenerated on `/project --init`, `/git setup`, or config change.
- **Git Platform** section adapts to `config.json` `gitPlatform.provider`. The MCP tool prefix changes per platform (`mcp__github__*`, `mcp__bitbucket__*`, etc.).
- **Architecture Reference** always includes all 5 levels. Level 4 (BRAND.md) is only listed for repos that actually have one (`type` is `frontend` or `fullstack`).

### Marker Block Rules

1. **Finding the block:** Search for `<!-- fullstack-dev:start -->` and `<!-- fullstack-dev:end -->`.
2. **Updating:** Replace everything between the markers (exclusive of the markers themselves).
3. **Never touch content outside the markers.** That belongs to the user.
4. **Blank line before the start marker** and after the end marker for clean rendering.

---

## 6a. Per-repo `.code-review-graphignore` (multi-repo only)

**Location:** `<repo-name>/.code-review-graphignore` (inside each sub-repo root)
**Purpose:** Excludes build artifacts from that repo's own code-review-graph index. Each sub-repo has its own `.code-review-graph/` directory and its own graph, so each needs its own ignore file — the root `.code-review-graphignore` does not cover it.
**Created by:** init-agent, per repo
**Updated by:** init-agent health check (regenerates if patterns are stale for that repo's stack)
**Condition:** Only generated when `repoStructure` is `"multi-repo"`. Mono-repo projects use the single root `.code-review-graphignore` instead — skip this file entirely.

### Template

```gitignore
# >>> fullstack-dev:code-review-graph (do not edit this block) >>>

node_modules/
dist/

# Node/TypeScript (stack-derived)
coverage/
.nyc_output/

# <<< fullstack-dev:code-review-graph <<<

# --- User entries below ---
```

### Population Rules

- `node_modules/` and `dist/` are always included, regardless of stack — universal for Node.js projects.
- Stack-derived sections are added based on that specific repo's `repos[].stack` entry in `config.json` — never filesystem scanning:
  - Node/TypeScript (`stack` contains `"node"` or `"typescript"`) → `coverage/`, `.nyc_output/`
  - Next.js / frontend (`stack` contains `"next.js"`, or repo `type` is `"frontend"`) → `.next/`, `out/`, `storybook-static/`, `.storybook/`
  - Motia / iii.dev (`stack` contains `"motia"` or `"iii.dev"`) → `.motia/`, `data/`
- Omit stack-derived sections that don't apply to that repo.
- See `reference/tools-setup.md` § "Per-Repo `.code-review-graphignore` (multi-repo only)" for the full merge rules and build-ordering requirements.

---

## 7. .fullstack-dev/config.json

**Location:** `.fullstack-dev/config.json`
**Purpose:** Plugin configuration. Drives all code generation and documentation decisions.
**Created by:** init-agent (from wizard answers)
**Updated by:** init-agent (`--add-repo`, `--set`), refresh-agent (version bumps)

### Schema

```json
{
  "version": "1.1.0",
  "plugin": "https://github.com/ravindra-gadekar/fullstack-dev-plugin.git",
  "projectName": "",
  "description": "",
  "projectType": "full-stack",
  "repoStructure": "multi-repo",
  "metaRepo": {
    "remote": true,
    "url": ""
  },
  "repos": [
    {
      "name": "",
      "type": "frontend",
      "stack": [],
      "targetBranch": ""
    }
  ],
  "hasFrontend": true,
  "databases": [],
  "aiIntegration": [],
  "teamSize": "solo",
  "gitPlatform": {
    "provider": "github",
    "method": "mcp",
    "org": ""
  },
  "gitWorkflow": {
    "localBranch": "local-dev",
    "commitConvention": "conventional",
    "branchNaming": "<type>/<ticket?>-<name>",
    "deleteRemoteBranches": false
  },
  "gitIgnore": {
    "activeCategories": ["universal", "secrets", "node", "nextjs", "typescript", "windows", "macos", "linux", "ide", "build", "cache"],
    "hookInstalled": true,
    "categoriesEverActivated": []
  }
}
```

### Field Reference

| Field | Type | Required | Description |
|---|---|---|---|
| `version` | string | yes | Config schema version. Currently `"1.1.0"`. |
| `plugin` | string | yes | Git URL of the plugin repo. Always `"https://github.com/ravindra-gadekar/fullstack-dev-plugin.git"`. |
| `projectName` | string | yes | Human-readable project name (e.g., `"My Project"`). |
| `description` | string | yes | One-line project description. |
| `projectType` | enum | yes | One of: `"full-stack"`, `"api"`, `"frontend"`, `"cli"`, `"microservices"`. |
| `repoStructure` | enum | yes | One of: `"mono-repo"`, `"multi-repo"`. |
| `metaRepo` | object | no | Meta-repo configuration (multi-repo only). |
| `metaRepo.remote` | boolean | -- | Whether the meta-repo has a remote origin. |
| `metaRepo.url` | string | -- | Remote URL of the meta-repo. Empty if `remote: false`. |
| `repos` | array | yes | List of repositories/packages in the workspace. |
| `repos[].name` | string | yes | Directory name of the repo (e.g., `"frontend-app"`). |
| `repos[].type` | enum | yes | One of: `"frontend"`, `"backend"`, `"service"`, `"library"`. |
| `repos[].stack` | string[] | yes | Technologies used (e.g., `["next.js", "typescript", "tailwind"]`). |
| `hasFrontend` | boolean | yes | Whether any repo has type `"frontend"`. Controls whether the Agentation optional tool is offered. |
| `databases` | string[] | yes | Database technologies (e.g., `["mongodb"]`). Empty array if none. |
| `aiIntegration` | string[] | yes | AI/LLM tools used (e.g., `["openai", "anthropic"]`). Empty array if none. |
| `teamSize` | enum | yes | One of: `"solo"`, `"small"`, `"larger"`. Affects workflow recommendations. |
| `gitPlatform` | object | yes | Git hosting platform configuration. |
| `gitPlatform.provider` | enum | yes | One of: `"github"`, `"bitbucket"`, `"gitlab"`, `"azure-devops"`. |
| `gitPlatform.method` | string | yes | Integration method. Currently always `"mcp"`. |
| `gitPlatform.org` | string | yes | Organization or workspace name on the platform. |
| `gitWorkflow` | object | no | Git workflow configuration. Auto-populated during `/git setup` or `/project --init`. |
| `gitWorkflow.localBranch` | string | -- | Working branch name. Default `"local-dev"`. |
| `gitWorkflow.commitConvention` | string | -- | Commit format. Default `"conventional"`. |
| `gitWorkflow.branchNaming` | string | -- | Remote branch naming pattern. Default `"<type>/<ticket?>-<name>"`. |
| `gitWorkflow.deleteRemoteBranches` | boolean | -- | Whether to delete remote branches after merge. Default `false`. |
| `gitIgnore` | object | no | Gitignore management state. |
| `gitIgnore.activeCategories` | string[] | -- | Catalog categories active for this project. Set during init or `/gitignore rebuild`. |
| `gitIgnore.hookInstalled` | boolean | -- | Whether the gitignore pre-commit hook is installed. |
| `gitIgnore.categoriesEverActivated` | string[] | -- | Persistent record of every category ever activated for this project. Unlike `activeCategories` (a live, re-detected snapshot that can drop a category if its detection signal briefly disappears), this array only ever grows. Used to distinguish true first-activation from re-detection. |
| `optionalTools` | object | no | Optional developer tool configuration. |
| `optionalTools.agentation` | boolean | -- | Whether Agentation was configured during init. Only relevant when `projectType` includes frontend. |
| `repos[].targetBranch` | string | no | PR target branch for this repo (e.g., `"main"`, `"develop"`). Set by CI/CD auto-detection or user choice. |

### Validation Rules

- `projectName` must not be empty.
- `repos` must contain at least one entry.
- `hasFrontend` must be `true` if any repo has `type: "frontend"`.
- `repos[].stack` should contain lowercase, hyphenated names (e.g., `"next.js"` not `"Next.js"`).
- `metaRepo` is only meaningful when `repoStructure` is `"multi-repo"`.

---

## 8. .env.example

**Location:** Workspace root (`.env.example`)
**Purpose:** Documents required environment variables without exposing values.
**Created by:** init-agent
**Updated by:** Manually by the user. Plugin does not auto-update this file.

### Template

```env
# ============================================
# Required Environment Variables
# Copy this file to .env and fill in values
# ============================================
```

### Rules

- Every variable must have a comment explaining its purpose.
- Values are always empty -- never include actual secrets, even as examples.
- Group variables by category with blank-line separators.
- The specific variables included depend on the project's `aiIntegration` settings (application-runtime secrets only — MCP-server secrets like `GITHUB_TOKEN` never appear here, see `tools-setup.md` § Secrets Handling):
  - AI integrations: `OPENAI_API_KEY=`, `ANTHROPIC_API_KEY=`, etc. (one per detected provider)

---

## 9. Mono-repo vs Multi-repo Differences

Several generated files change shape based on the `repoStructure` setting in `config.json`. This section documents every difference.

### .gitignore

| Aspect | Mono-repo | Multi-repo |
|---|---|---|
| Marker block | `fullstack-dev:gitignore` markers with tech-stack patterns | `fullstack-dev:gitignore` markers with tech-stack patterns + sub-repo directories |
| Sub-repo entries | N/A | Listed as `# Sub-repositories` category inside marker block |
| Pattern source | `skills/gitignore/reference/gitignore-catalog.md` | `skills/gitignore/reference/gitignore-catalog.md` |
| Pre-commit hook | Installed with `fullstack-dev:gitignore` marker in `.git/hooks/pre-commit` | Installed per-repo |

See [gitignore-catalog.md](../../gitignore/reference/gitignore-catalog.md) for the full pattern catalog and [gitignore-flow.md](../../gitignore/reference/gitignore-flow.md) for marker block format and merge rules.

### Workspace File (*.code-workspace)

| Aspect | Mono-repo | Multi-repo |
|---|---|---|
| Generated | No | Yes |
| Content | N/A | One folder entry per repo + root |
| Settings | N/A | Shared workspace settings |

### Meta-repo Setup

| Aspect | Mono-repo | Multi-repo |
|---|---|---|
| Separate parent git repo | No (everything is one repo) | Yes (parent tracks docs, config, workspace file) |
| `config.json` `metaRepo` field | Ignored | Used (tracks remote URL) |
| Sub-repos as git submodules | N/A | No -- sub-repos are independent clones, not submodules |

### ARCHITECTURE.md Files

| Aspect | Mono-repo | Multi-repo |
|---|---|---|
| Root-level `ARCHITECTURE.md` | Not generated (use `docs/project/architecture.md` instead) | Not generated (use `docs/project/architecture.md` instead) |
| Per-repo `ARCHITECTURE.md` | Single file at repo root | One per sub-repo directory |
| Location | `./ARCHITECTURE.md` | `<repo-name>/ARCHITECTURE.md` |

### CLAUDE.md Repos Section

| Aspect | Mono-repo | Multi-repo |
|---|---|---|
| Repo listing | Key directories within the mono-repo | Each sub-repo as a bullet with its type |
| Build commands | Single section | One section per repo |

### docs/project/architecture.md

| Aspect | Mono-repo | Multi-repo |
|---|---|---|
| Service Map | Lists internal modules/packages | Lists each repo as a service |
| Services section | Organized by module/package | Organized by repo |

### CONTEXT.md

| Aspect | Mono-repo | Multi-repo |
|---|---|---|
| Entity Source column | References directories within the repo | References repo names |
| Data Flow | Internal function calls and module boundaries | Inter-service communication (HTTP, events) |

---

## Template File Creation Order

During `/project --init`, files are created in this order:

1. `.fullstack-dev/config.json` -- drives everything else
2. `.env.example` -- environment setup
3. `.gitignore` -- before any git operations (marker block with tech-stack patterns from catalog)
4. `.code-review-graphignore` -- after .gitignore (needs gitIgnore.activeCategories)
5. `*.code-workspace` -- workspace file (multi-repo only)
6. `CONTEXT.md` -- domain model (populated later by scanner)
7. `docs/project/tech-stack.md` -- technology inventory
8. `docs/project/architecture.md` -- system architecture
9. Per-repo `BRAND.md` -- design tokens (only in repos whose `type` is `frontend` or `fullstack`)
10. Per-repo `ARCHITECTURE.md` -- one per repo
11. `CLAUDE.md` -- last, because it references other docs
12. Per-repo `.code-review-graphignore` -- one per repo, after that repo's docs/configs exist (multi-repo only)
13. Per-repo `.gitignore` `.code-review-graph/` entry -- verify/add per repo (multi-repo only)
14. Per-repo full graph build -- last step overall for that repo, after its `.code-review-graphignore` is in place (multi-repo only)

This order ensures that each file can reference files created before it. The scanner-agent populates placeholder content after all files exist.
