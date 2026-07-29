# Add-Repo Flow

How new repositories are added to a multi-repo project. Referenced by the repo-agent and the SKILL.md orchestrator.

---

## Trigger

Explicit: `/project --add-repo`

This is a wizard-driven flow. The repo-agent presents each question in sequence, collects answers, then executes the configuration steps.

---

## Guard: Multi-Repo Only

Before starting the wizard, check `config.json` at `.fullstack-dev/config.json`:

- If `projectType` is `"multi-repo"` -> proceed with wizard.
- If `projectType` is `"mono-repo"` -> stop and inform the user:

```
This is a mono-repo project. The --add-repo command is for multi-repo
workspaces only. To add a new module within this repo, use standard
directory creation instead.
```

Do not proceed with the wizard for mono-repo projects.

---

## Wizard Questions

Present each question exactly as shown. Collect all answers before executing configuration steps.

### Question 1 -- Service Type

```
? What kind of service is this?
  ○ Microservice
  ○ Lambda / serverless function
  ○ Worker / background processor
  ○ Shared library / package
  ○ Frontend application
  ○ Other
```

If "Other" is selected, ask for a brief description of the service type.

### Question 2 -- Service Name

```
? Service name: _______________
```

Validate: must be a valid directory name (lowercase, hyphens allowed, no spaces). This becomes the directory name and the repo name.

### Question 3 -- Framework or Runtime

```
? Framework or runtime? > _______________
```

Free text. Examples: `express`, `next.js`, `fastapi`, `spring-boot`, `plain node`. Used to populate tech-stack docs and determine starter structure.

### Question 4 -- Database

```
? Does this service need a database?
  ○ Use existing shared database
  ○ Its own database
  ○ No database
```

If "Use existing shared database" -- note which database from the project's existing stack.
If "Its own database" -- ask a follow-up for the database technology (e.g., PostgreSQL, MongoDB, Redis).

### Question 5 -- Communication

```
? How does it communicate with other services?
  ○ HTTP / REST API
  ○ Event bus / message queue
  ○ gRPC
  ○ Shared database
  ○ MCP (Model Context Protocol)
```

Multiple selections are allowed. The answer informs the domain model and architecture docs.

### Question 6 -- Remote Repo

```
? Create a GitHub/Bitbucket repo now?
  ○ Yes — create via MCP
  ○ Later — I'll set it up myself
```

If "Yes" -- remote repo is created immediately after the local setup (see MCP Repo Creation below).

---

## Configuration Steps

After all wizard answers are collected, execute these steps in order:

### Step 1: Create directory

Create the new service directory at the project root:

```
<project-root>/<service-name>/
```

### Step 2: Initialize git

Run `git init` inside the new directory to make it its own repository.

### Step 3: Update `.gitignore`

Add the new repo directory to the meta-repo `.gitignore` marker block. Delegate to `gitignore-rules.md` for the exact format and placement rules.

### Step 4: Generate `ARCHITECTURE.md`

Generate an `ARCHITECTURE.md` inside the new repo directory. Delegate to `doc-templates.md` for the template structure. Populate with:

- Service type (from Question 1)
- Framework/runtime (from Question 3)
- Database info (from Question 4)
- Communication pattern (from Question 5)

### Step 5: Update `docs/project/architecture.md`

Add a new section for the repo in the project-level architecture doc. Include:

- Service name and type
- Purpose (derived from wizard answers)
- Communication patterns with other services
- Database usage

### Step 6: Update `docs/project/tech-stack.md`

Add stack entries for:

- Framework/runtime from Question 3
- Database technology if applicable (from Question 4)
- Communication protocols (from Question 5)

Only add entries that are not already present in the tech-stack doc.

### Step 7: Update `.fullstack-dev/config.json`

Add the new repo to the `repos` array:

```json
{
  "name": "<service-name>",
  "path": "<service-name>",
  "type": "<service-type>",
  "framework": "<framework>",
  "database": "<database-or-null>",
  "communication": ["<protocol-1>", "<protocol-2>"]
}
```

### Step 8: Update `CONTEXT.md`

If the new service introduces a new bounded context, domain entity, or data flow, add it to the domain model section in `CONTEXT.md`. Skip this step if the service is purely infrastructural (e.g., a shared utility library with no domain concepts).

### Step 9: Update `*.code-workspace`

Add a folder entry for the new repo to the VS Code workspace file:

```json
{
  "path": "<service-name>"
}
```

### Step 10: Set remote origin (conditional)

If the user chose "Yes" for remote repo creation in Question 6, and the MCP repo creation succeeded:

```
git remote add origin <remote-url>
```

Run this inside the new repo directory.

### Step 11: Commit meta-repo changes

Commit all changes in the meta-repo (`.gitignore`, docs, config, workspace file). This does **not** commit inside the new repo itself -- that repo starts with an empty history.

---

## MCP Repo Creation

Executed only if the user chose "Yes" in Question 6.

### Platform detection

Read `config.json` at `.fullstack-dev/config.json` and check `gitPlatform.provider`:

| Provider | MCP tool |
|---|---|
| `github` | `mcp__github__create_repository` |
| Other platforms | Use equivalent MCP tool or inform user to create manually |

### Creation parameters

- **Name:** the service name from Question 2
- **Organization:** from `gitPlatform.org` in `config.json` (if set)
- **Visibility:** default to private unless `gitPlatform.defaultVisibility` says otherwise
- **Description:** auto-generated from service type and framework (e.g., "Microservice built with Express")

### After creation

1. Capture the remote URL from the MCP response.
2. Set as remote origin (Step 10 above).
3. Inform the user of the created repo URL.

If MCP creation fails, inform the user and continue with the remaining steps. The remote can be added manually later.

---

## Auto-Detect Trigger (v2 Reference)

This section documents the planned auto-detect behavior for v2 workflow skills. It is **not implemented** in the current wizard flow -- it is here for reference when building v2.

### Decision tree during brainstorming

When a feature is being brainstormed and the implementation scope is being determined:

```
Feature scope analysis
├── Feature fits entirely within one existing repo
│   └── Continue — no repo action needed
├── Feature spans multiple existing repos
│   └── Identify which repos are involved, proceed with multi-repo plan
└── Feature doesn't fit any existing repo
    ├── Offer: create a new repo (triggers add-repo flow)
    └── Offer: fit into the closest existing repo (explain trade-offs)
```

### Signals that a new repo may be needed

- The feature introduces a new runtime (e.g., Python service in a Node.js project)
- The feature has independent scaling requirements
- The feature is a shared library consumed by multiple services
- The feature has a fundamentally different deployment model
- The feature introduces a new bounded context with its own data store

### v2 integration point

In v2 workflow skills, the brainstorm-agent would run this decision tree automatically during the scoping phase. If it determines a new repo is needed, it would hand off to the repo-agent with pre-filled answers from the brainstorming context, reducing the wizard to a confirmation step rather than a full Q&A session.
