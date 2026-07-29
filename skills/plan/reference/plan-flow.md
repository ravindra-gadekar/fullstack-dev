# Plan Flow Reference

This document contains the detailed decision trees, templates, keyword lists,
and behavioral rules for the /plan command. The SKILL.md orchestrator references
this document for specifics.

---

## Section 1: Auto-Init Guard

Before the plan flow begins, verify the project is initialized.

```
.fullstack-dev/config.json exists?
+-- YES --> validate JSON is parseable
|   +-- Valid JSON --> extract repos[], projectName, projectType
|   |   --> proceed to Step 1 (Spec Resolution)
|   +-- Invalid JSON --> warn: "Config file is corrupted. Run /project --init to regenerate."
|       --> offer:
|           (a) Run /project --init
|           (b) Proceed in degraded mode
+-- NO --> offer choice:
    +-- (a) Run /project --init first (recommended)
    +-- (b) Proceed in degraded mode
```

### Degraded Mode Behavior

In degraded mode the plan is still generated, but it lacks project context.
The following differences apply:

| Aspect | Normal Mode | Degraded Mode |
|---|---|---|
| Context loading | Reads CONTEXT.md, ARCHITECTURE.md, config.json | Skipped |
| Repo paths | Resolved from config.json repos[] | Research agents read files directly |
| File path accuracy | Config-driven, precise repo-relative paths | Best-effort, may be less accurate |
| Research agents | Full graph + project doc awareness | Graph (if available) + file scanning only |
| Output note | None | "Generated in degraded mode -- file paths may be less accurate without project config." |

---

## Section 2: Spec Resolution

Decision tree for finding the spec to plan.

```
spec-path provided?
+-- YES --> validate file exists
|   +-- File exists --> read it
|   |   +-- Check if matching plan already exists (exact slug match)
|   |   |   +-- Plan exists and has README.md with Phases table
|   |   |   |   --> offer:
|   |   |   |       (a) View existing plan
|   |   |   |       (b) Regenerate (archive old to <dir>.archived)
|   |   |   |       (c) Pick different spec
|   |   |   +-- Plan dir exists but incomplete (no README.md or no Phases table)
|   |   |       --> treat as unplanned, offer to clean up abandoned dir
|   |   +-- No matching plan --> proceed
|   +-- File does not exist --> error: "Spec not found at <path>. Check the path."
+-- NO --> auto-detect unplanned specs
    +-- Scan docs/specs/ for *-design.md files
    +-- For each spec, extract slug: strip timestamp prefix and -design.md suffix
    +-- For each slug, check docs/plans/ for a directory containing EXACTLY the same slug
    |   (no partial matches: "keyword-tracking" != "keyword-tracking-v2")
    |   A plan dir counts as "planned" only if README.md exists with a "## Phases" heading
    +-- Filter to unplanned specs only
    +-- Results:
        +-- 0 unplanned --> "No unplanned specs found. Run /brainstorm to create one.", stop
        +-- 1 unplanned --> suggest it, user confirms or picks another
        +-- 2+ unplanned --> interactive picker (AskUserQuestion) showing:
            - Spec filename
            - Spec title (first # heading)
            - Date created
```

### Slug Extraction Rules

- Input: `2026-07-30T01-00-00-auth-system-design.md`
- Strip timestamp: regex `^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}-` removes the leading
  ISO 8601 timestamp and its trailing hyphen, yielding `auth-system-design.md`
- Strip `-design.md` suffix: yields `auth-system`
- Slug matching is case-insensitive

### Existing Plan Detection

When checking whether a plan already exists for a slug:

1. Scan `docs/plans/` for directories whose name contains the slug as an exact
   substring bounded by directory-name boundaries (start-of-name, end-of-name,
   or hyphens). For example, slug `auth-system` matches directory
   `auth-system` or `2026-07-30-auth-system` but does NOT match
   `auth-system-v2` or `auth-system-redesign`.

2. A matching directory counts as "planned" only if it contains a `README.md`
   file with a `## Phases` heading (H2 level, exact text match).

3. If the directory exists but lacks a valid README.md, it is treated as
   abandoned. Offer to clean it up: rename to `<dir>.abandoned` and proceed
   as if no plan exists.

---

## Section 3: Spec Analysis (Best-Effort Parsing)

Rules for extracting structured data from the spec.

### Minimum Viable Structure

The spec must contain at least these two elements:

1. **Overview/introduction paragraph** -- the first section after any metadata
   (the content under the first heading, or the first paragraph if no heading).
2. **Acceptance Criteria section** -- a section containing a bullet list with
   `- [ ]` checkboxes.

If either is missing, ask the user:

```
This spec is missing [Overview / Acceptance Criteria].
Please provide it, or run /brainstorm to generate a complete spec.
```

Do not proceed until both elements are present or the user explicitly chooses
to continue without them.

### Full Extraction Targets

Extract the following sections if present. Skip any that are absent -- they
are not required.

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

After parsing, present results to the user:

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

## Section 4: Codebase Research

Strategy selection based on available tooling.

```
code-review-graph available? (scan .mcp.json for "code-review-graph" key)
+-- YES --> try graph tools first
|   +-- semantic_search_nodes: search for entities from spec's data model
|   +-- query_graph: trace callers_of/imports_of for entities found
|   +-- get_impact_radius: for files that will be modified
|   +-- get_architecture_overview: per repo touched by the spec
|   +-- If any graph query FAILS (timeout, error, empty):
|       --> fall back to Grep/Glob/Read for that specific query
|       --> log: "Graph query failed for <query>, using filesystem fallback"
+-- NO --> use physical file tools:
    +-- Grep: search for function names, type names, import patterns from spec
    +-- Glob: find file patterns (test files, route files, model files, component files)
    +-- Read: examine discovered files for interfaces, patterns, conventions
```

### Research Priorities

Research is guided by the extracted spec data. Prioritize in this order:

1. **Data model entities** -- find existing types, interfaces, and schemas
   that the spec references or extends.
2. **API endpoints** -- find existing route handlers, middleware, and
   controllers in the path of the new feature.
3. **File structure** -- map the existing directory layout to understand where
   new files should be placed.
4. **Test infrastructure** -- identify the testing framework, conventions,
   and representative test files.
5. **Utilities and helpers** -- find reusable functions, shared components,
   and common patterns.

### Research Output Structure

Regardless of the method used (graph tools or filesystem), produce the
following structured output:

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

Each entry must include the full repo-relative file path. Do not list files
speculatively -- only include files confirmed to exist via graph query or
filesystem read.

---

## Section 5: Parallel Research Agents (--parallel mode)

When the `--parallel` flag is set, dispatch 3 research agents simultaneously
instead of running inline graph/file calls sequentially. This reduces wall
clock time for large codebases.

### Agent 1: File Mapper

```
Focus: Find existing files related to the spec's domain
Method: graph tools (semantic_search_nodes, get_architecture_overview) or Glob/Grep fallback
Output schema:
- files[]: { path, description, action: "create" | "modify" }
- directories[]: { path, purpose }
```

**Prompt template:**

```
You are mapping the file structure for a feature: [feature].
Working directory: [workspace-root]
Repos: [repos from config.json]

Spec summary: [overview paragraph from spec]
Data model entities: [list of type/interface names from spec]
API endpoints: [list of routes from spec]

Steps:
1. Use code-review-graph tools (if available) or Glob/Grep to find files
   related to the entities and endpoints listed above.
2. For each file found, determine whether the feature will CREATE a new file
   or MODIFY the existing one.
3. Identify directories where new files should be placed, based on existing
   directory conventions.

Report format (use exactly):

## File Mapping Results

### Files
- path: <repo-relative path>
  description: <what the file does>
  action: <create | modify>

### Directories
- path: <directory path>
  purpose: <what files in this directory do>
```

### Agent 2: Interface Scanner

```
Focus: Extract existing types, interfaces, and function signatures the feature will consume
Method: graph tools (query_graph imports_of/callers_of) or Grep/Read fallback
Output schema:
- interfaces[]: { name, sourcePath, definition (signature or shape) }
- utilities[]: { name, sourcePath, description }
```

**Prompt template:**

```
You are scanning for interfaces and utilities relevant to: [feature].
Working directory: [workspace-root]
Repos: [repos from config.json]

Data model entities from spec: [list of type/interface names]
API endpoints from spec: [list of routes]

Steps:
1. Use code-review-graph query_graph (imports_of, callers_of) or Grep/Read
   to find existing TypeScript interfaces, types, and function signatures
   that relate to the entities listed above.
2. For each interface found, extract its definition (field names and types).
3. For each utility function found, extract its signature and a one-line
   description of what it does.

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
```

### Agent 3: Test Pattern Analyzer

```
Focus: Discover testing conventions, frameworks, file structure
Method: Glob for test files, Read representative tests, check package.json for test config
Output schema:
- framework: string (vitest/jest/mocha)
- fileNaming: string (e.g., "*.test.ts", "*.spec.ts")
- directories[]: string (test directories)
- exampleTest: { path, pattern description }
```

**Prompt template:**

```
You are analyzing the testing patterns for: [feature].
Working directory: [workspace-root]
Repos: [repos from config.json]

Steps:
1. Read package.json in each repo to find test framework configuration
   (look for vitest, jest, or mocha in devDependencies and scripts).
2. Glob for test files: **/*.test.ts, **/*.spec.ts, **/*.test.tsx,
   **/*.spec.tsx, **/__tests__/**
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
```

### Timeout and Failure Handling

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

If all 3 agents fail, abandon the parallel approach entirely and run inline
research using the same strategy as without the `--parallel` flag.

### Merging Results

After all agents complete (or their fallbacks finish), merge results into
the research output structure defined in Section 4:

1. **Existing Files to Modify** -- populated from Agent 1 (File Mapper),
   filtered to `action: "modify"` entries.
2. **Existing Interfaces to Consume** -- populated from Agent 2 (Interface
   Scanner), interfaces[] entries.
3. **Test Patterns** -- populated from Agent 3 (Test Pattern Analyzer).
4. **Utilities to Reuse** -- populated from Agent 2 (Interface Scanner),
   utilities[] entries.

Deduplicate entries that appear in multiple agents' results (same file path).
Prefer the more detailed description when merging duplicates.
