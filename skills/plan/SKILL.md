---
name: plan
description: "Convert a design spec into a multi-phase implementation plan. Uses code-review-graph (with filesystem fallback) for accurate file paths and task decomposition. Produces plans in docs/plans/ with checkbox tracking."
tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion
model: sonnet
effort: high
---

# Plan Orchestrator

You are the plan orchestrator. You convert a design spec into a detailed,
multi-phase implementation plan with accurate file paths, cross-task
interfaces, and spec traceability. You do all coordination yourself,
dispatching to agents only for parallel research and plan review.

See `reference/plan-flow.md` for detailed decision trees, templates,
and behavioral rules.

---

## Step 0: Auto-Init Guard

Check whether the project is initialized before doing anything else.

```
Read .fullstack-dev/config.json
+-- Exists and valid JSON
|   --> Extract repos[], projectName, projectType from config.
|       Store as internal context.
|       Proceed to Step 1.
+-- Exists but invalid JSON
|   --> Warn: "Config file is corrupted. Run /project --init to regenerate."
|       --> Offer:
|           (a) Run /project --init
|           (b) Proceed in degraded mode
+-- Does not exist
    --> Ask: "Project not initialized. Run /project --init first?"
        +-- Yes --> Invoke the fullstack-dev skill with --init.
        |          After init completes, restart from Step 1.
        +-- No  --> Proceed in degraded mode:
                    - Skip Step 2 (context loading).
                    - Research (Step 4) reads files directly
                      without project doc awareness.
                    - Note in final plan output:
                      "Generated in degraded mode -- file paths may
                       be less accurate without project config."
```

### Degraded Mode Differences

| Aspect | Normal Mode | Degraded Mode |
|---|---|---|
| Context loading | Reads CONTEXT.md, ARCHITECTURE.md, config.json | Skipped |
| Repo paths | Resolved from config.json repos[] | Best-effort from filesystem |
| File path accuracy | Config-driven, precise repo-relative paths | May be less accurate |
| Research agents | Full graph + project doc awareness | Graph (if available) + file scanning only |
| Output note | None | Degraded-mode disclaimer appended to plan README |

---

## Step 1: Spec Resolution

Determine which spec to plan. This step is fully self-contained --
all branching logic is inline below.

```
spec-path argument provided?
+-- YES --> validate file exists
|   +-- File exists --> read it
|   |   +-- Extract slug from filename (see slug rules below)
|   |   +-- Check if matching plan already exists (see detection rules below)
|   |   |   +-- Plan exists: directory found with README.md containing "## Phases"
|   |   |   |   --> Offer via AskUserQuestion:
|   |   |   |       (a) View existing plan
|   |   |   |       (b) Regenerate (archive old plan dir to <dir>.archived)
|   |   |   |       (c) Pick a different spec
|   |   |   +-- Plan dir exists but incomplete (no README.md or no "## Phases" heading)
|   |   |   |   --> Treat as abandoned. Offer to rename dir to <dir>.abandoned.
|   |   |   |       Proceed as if no plan exists.
|   |   |   +-- No matching plan directory
|   |   |       --> Proceed to Step 2.
|   +-- File does not exist
|       --> Error: "Spec not found at <path>. Check the path and try again."
|          Stop.
+-- NO --> auto-detect unplanned specs
    +-- Scan docs/specs/ for *-design.md files
    +-- For each spec file, extract slug (see slug rules below)
    +-- For each slug, check docs/plans/ for matching plan directory
    |   (see detection rules below)
    +-- Filter to unplanned specs only
    +-- Results:
        +-- 0 unplanned specs
        |   --> "No unplanned specs found. Run /brainstorm to create one."
        |      Stop.
        +-- 1 unplanned spec
        |   --> Suggest it to user with filename and title (first # heading).
        |       User confirms or picks another.
        +-- 2+ unplanned specs
            --> AskUserQuestion picker showing for each:
                - Spec filename
                - Spec title (first # heading from file)
                - Date created (extracted from timestamp prefix)
```

### Slug Extraction Rules

Given a spec filename, extract the plan slug:

1. **Strip timestamp prefix** using regex: `^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}-`
   This removes the ISO 8601 compact timestamp and its trailing hyphen.
   - Example: `2026-07-30T01-00-00-auth-system-design.md` becomes `auth-system-design.md`

2. **Strip `-design.md` suffix** to get the slug.
   - Example: `auth-system-design.md` becomes `auth-system`

3. **Slug matching is case-insensitive.**

### Existing Plan Detection Rules

When checking whether a plan already exists for a slug:

1. Scan `docs/plans/` for directories whose name contains the slug as
   an exact substring bounded by directory-name boundaries (start-of-name,
   end-of-name, or hyphens).
   - Slug `auth-system` matches: `auth-system`, `2026-07-30-auth-system`
   - Slug `auth-system` does NOT match: `auth-system-v2`, `auth-system-redesign`

2. A matching directory counts as "planned" only if it contains a `README.md`
   file with a `## Phases` heading (H2 level, exact text match).

3. If the directory exists but lacks a valid README.md, it is treated as
   abandoned. Offer to rename to `<dir>.abandoned` and proceed as if no
   plan exists.

---

## Step 2: Load Project Context

Load project documentation to build context for accurate plan generation.
Skip any missing file silently -- never error on an absent doc.

Read in order:
1. `.fullstack-dev/config.json` -- project structure, repos, tech stack
2. `CONTEXT.md` -- domain model, glossary, conventions
3. `docs/project/architecture.md` -- unified system architecture
4. `docs/project/tech-stack.md` -- languages, frameworks, databases
5. Per-repo `ARCHITECTURE.md` -- repo-specific structure (one per repo
   listed in `config.json -> repos[]`)

Store everything you read as internal context for later steps. Do not
output these docs to the user.

If running in degraded mode (Step 0), skip this step entirely.

---

## Step 3: Spec Analysis

Parse the spec to extract structured data for plan generation. Use
best-effort parsing -- extract what is present, skip what is absent.

### Minimum Viable Structure Check

The spec must contain at least these two elements:

1. **Overview/introduction paragraph** -- the first section after any
   metadata (the content under the first heading, or the first paragraph
   if no heading).
2. **Acceptance Criteria section** -- a section containing a bullet list
   with `- [ ]` checkboxes.

```
Minimum viable structure present?
+-- YES --> proceed to full extraction
+-- NO (missing Overview or Acceptance Criteria)
    --> Ask user:
        "This spec is missing [Overview / Acceptance Criteria / both].
         Please provide it, or run /brainstorm to generate a complete spec."
    --> Do not proceed until both elements are present or the user
        explicitly chooses to continue without them.
```

### Full Extraction Targets

Extract the following sections if present. Skip any that are absent --
they are not required.

| Target | How to Find |
|---|---|
| Key decisions | Table with "Decision" column, or section titled "Key Decisions" |
| Data model | TypeScript interface blocks, or section titled "Data Model" |
| API endpoints | Table with "Method"/"Path" columns, or section titled "API Endpoints" |
| File structure | Fenced code blocks with directory trees, or section titled "File Structure" |
| Acceptance criteria | Section with `- [ ]` checkboxes, or section titled "Acceptance Criteria" |
| Repo scope | `**Repo:**` metadata field, or section titled "Repo" |
| Out of scope | Section titled "Out of Scope" |

### Presenting Extraction Results

After parsing, present a summary to the user:

```
I extracted these sections from the spec:
  - Overview
  - Data Model (3 interfaces)
  - API Endpoints (5 routes)
  - Acceptance Criteria (12 items)

Missing (not found in spec):
  - Key Decisions
  - File Structure
  - Out of Scope

Shall I proceed with what I have, or do you want to add the missing sections?
```

List extracted sections with counts where applicable (number of interfaces,
routes, criteria items). List missing sections without judgment -- they are
optional. Proceed when the user confirms.

---

## Step 4: Codebase Research

Research the existing codebase to map files, interfaces, test patterns,
and utilities relevant to the spec. Strategy depends on available tooling.

### Tool Selection

```
code-review-graph available? (scan .mcp.json for "code-review-graph" key)
+-- YES --> use graph tools first:
|   +-- semantic_search_nodes: search for entities from spec's data model
|   +-- query_graph: trace callers_of/imports_of for entities found
|   +-- get_impact_radius: for files that will be modified
|   +-- get_architecture_overview: per repo touched by the spec
|   +-- If any graph query FAILS (timeout, error, empty results):
|       --> fall back to Grep/Glob/Read for that specific query
|       --> log: "Graph query failed for <query>, using filesystem fallback"
+-- NO --> use physical file tools directly:
    +-- Grep: search for function names, type names, import patterns from spec
    +-- Glob: find file patterns (test files, route files, model files, components)
    +-- Read: examine discovered files for interfaces, patterns, conventions
```

### Research Priorities

Research is guided by the extracted spec data. Prioritize in this order:

1. **Data model entities** -- find existing types, interfaces, and schemas
   that the spec references or extends.
2. **API endpoints** -- find existing route handlers, middleware, and
   controllers in the path of the new feature.
3. **File structure** -- map the existing directory layout to understand
   where new files should be placed.
4. **Test infrastructure** -- identify the testing framework, conventions,
   and representative test files.
5. **Utilities and helpers** -- find reusable functions, shared components,
   and common patterns.

### Research Output Structure

Regardless of the method used (graph tools or filesystem), produce the
following structured output for use in later steps:

```markdown
## Codebase Research Results

### Existing Files to Modify
- `<repo>/<path>` -- <what it does, why it needs modification>

### Existing Interfaces to Consume
- `<TypeName>` from `<repo>/<path>` -- <interface definition summary>

### Test Patterns
- Framework: <vitest/jest/mocha>
- Convention: <test file naming pattern>
- Example: `<path to representative test file>`

### Utilities to Reuse
- `<functionName>` from `<repo>/<path>` -- <what it does>
```

Each entry must include the full repo-relative file path. Do not list
files speculatively -- only include files confirmed to exist via graph
query or filesystem read.

### Parallel Research Mode (--parallel flag)

When the `--parallel` flag is set, dispatch 3 research agents
simultaneously instead of running inline graph/file calls sequentially.
Launch all 3 agents in a single message for parallel execution.

#### Agent 1: File Mapper

```
Agent(
  description: "Map files for plan",
  prompt: """
    You are mapping the file structure for a feature: [feature].
    Working directory: [workspace-root]
    Repos: [repos from config.json]

    Spec summary: [overview paragraph from spec]
    Data model entities: [list of type/interface names from spec]
    API endpoints: [list of routes from spec]

    Steps:
    1. Use code-review-graph tools (if available) or Glob/Grep to find
       files related to the entities and endpoints listed above.
    2. For each file found, determine whether the feature will CREATE a
       new file or MODIFY the existing one.
    3. Identify directories where new files should be placed, based on
       existing directory conventions.

    Report format (use exactly):

    ## File Mapping Results

    ### Files
    - path: <repo-relative path>
      description: <what the file does>
      action: <create | modify>

    ### Directories
    - path: <directory path>
      purpose: <what files in this directory do>
  """
)
```

#### Agent 2: Interface Scanner

```
Agent(
  description: "Scan interfaces for plan",
  prompt: """
    You are scanning for interfaces and utilities relevant to: [feature].
    Working directory: [workspace-root]
    Repos: [repos from config.json]

    Data model entities from spec: [list of type/interface names]
    API endpoints from spec: [list of routes]

    Steps:
    1. Use code-review-graph query_graph (imports_of, callers_of) or
       Grep/Read to find existing TypeScript interfaces, types, and
       function signatures that relate to the entities listed above.
    2. For each interface found, extract its definition (field names
       and types).
    3. For each utility function found, extract its signature and a
       one-line description of what it does.

    Report format (use exactly):

    ## Interface Scan Results

    ### Interfaces
    - name: <TypeName>
      sourcePath: <repo-relative path>
      definition: <TypeScript interface/type definition>

    ### Utilities
    - name: <functionName>
      sourcePath: <repo-relative path>
      description: <what the function does>
  """
)
```

#### Agent 3: Test Pattern Analyzer

```
Agent(
  description: "Analyze test patterns for plan",
  prompt: """
    You are analyzing the testing patterns for: [feature].
    Working directory: [workspace-root]
    Repos: [repos from config.json]

    Steps:
    1. Read package.json in each repo to find test framework
       configuration (look for vitest, jest, or mocha in
       devDependencies and scripts).
    2. Glob for test files: **/*.test.ts, **/*.spec.ts,
       **/*.test.tsx, **/*.spec.tsx, **/__tests__/**
    3. Read 2-3 representative test files to understand patterns:
       - How tests are structured (describe/it, test blocks)
       - How mocks and fixtures are set up
       - How assertions are written
       - Whether there are shared test utilities

    Report format (use exactly):

    ## Test Pattern Results

    ### Framework
    - name: <vitest | jest | mocha>
    - config: <path to test config file, if any>

    ### File Naming
    - pattern: <e.g., "*.test.ts">
    - directories: <list of directories containing tests>

    ### Example Test
    - path: <path to a representative test file>
    - pattern: <description of the test structure and conventions>

    ### Shared Utilities
    - <list of shared test helpers, fixtures, or factories found>
  """
)
```

#### Timeout and Failure Handling

Each agent has a 2-minute timeout. Handle failures as follows:

```
Agent completed?
+-- YES --> collect results
+-- NO (timeout or error)
    +-- Use partial results from agents that did complete
    +-- Run inline fallback (graph tools or Grep/Glob/Read) for the
        failed agent's scope
    +-- Log: "Research agent <name> failed/timed out. Using inline fallback."
```

If all 3 agents fail, abandon the parallel approach entirely and run
inline research using the sequential strategy described above.

#### Merging Results

After all agents complete (or their fallbacks finish), merge results
into the research output structure:

1. **Existing Files to Modify** -- from Agent 1, filtered to `action: "modify"`.
2. **Existing Interfaces to Consume** -- from Agent 2, interfaces[] entries.
3. **Test Patterns** -- from Agent 3.
4. **Utilities to Reuse** -- from Agent 2, utilities[] entries.

Deduplicate entries that appear in multiple agents' results (same file
path). Prefer the more detailed description when merging duplicates.

---

## Step 5: Multi-Repo Detection

Determine which repos the plan touches and how to assign phases across them.

```
How many repos does the spec touch?
+-- Spec has explicit **Repo:** field
|   --> Parse repo list from field.
|   --> Cross-reference with config.json repos[].
|   +-- All repos found in config --> use them
|   +-- Unknown repo name found
|       --> Warn: "Repo '<name>' not found in config.json"
|       --> Ask user to clarify
+-- No explicit repo field
|   --> Infer from file paths and data model in spec:
|       +-- API endpoints, route handlers, Mongoose models/schemas
|       |   --> api repo
|       +-- UI components, pages, layouts, React code
|       |   --> app repo
|       +-- Shared types referenced by both
|       |   --> api repo (source of truth)
|   --> If ambiguous or no file paths in spec
|       --> Ask user: "Which repo(s) does this feature touch?"
|          List available repos from config.json as options.
+-- Results:
    +-- Single repo
    |   --> All phases target that repo.
    +-- Multiple repos
        --> Assign phases by dependency order:
            1. Shared types/models (database layer)
            2. Backend API (produces endpoints)
            3. Frontend (consumes endpoints)
            4. Integration/testing (cross-repo)
```

### Phase-to-Repo Assignment Rules

- Each phase targets exactly one repo.
- Backend phases come before frontend phases.
- If a phase needs files from 2+ repos, split it into separate phases --
  one per repo, ordered by dependency (producer before consumer).
- The README.md Phases table includes a Repo column so the implementer
  knows which repo to work in for each phase.
- When a frontend phase consumes an API endpoint created in a backend
  phase, the frontend phase must list the backend phase as a dependency.

---

## Reference Documents

| File | Purpose |
|------|---------|
| `reference/plan-flow.md` | Detailed decision trees, templates, parallel agent prompts, output formats, error handling |
