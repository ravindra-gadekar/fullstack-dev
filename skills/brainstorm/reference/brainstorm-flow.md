# Brainstorm Flow Reference

Complete decision trees, prompts, templates, and rules for the `/brainstorm`
skill. The brainstorm SKILL.md is the summary; this file is the authoritative
source for exact formats, dispatch logic, and behavioral rules.

---

## 1. Auto-Init Guard Decision Tree

Before the brainstorm flow begins, verify the project is initialized.

```
Read .fullstack-dev/config.json
+-- Exists + valid JSON
|   --> Proceed to Step 1 (Load Project Context)
+-- Does not exist
    --> Ask: "Project not initialized. Run /project --init first?"
    +-- Yes
    |   --> Invoke fullstack-dev skill with --init
    |   --> After init completes, restart brainstorm from Step 1
    +-- No
        --> Degraded mode
            - Skip Steps 1 and 3 (no config.json to read)
            - Research agents read files directly (no project doc awareness)
            - Spec still gets written but without fullstack-dev context
```

### Degraded Mode Behavior

In degraded mode the brainstorm still produces a spec, but it lacks project
context. The following differences apply:

| Aspect | Normal Mode | Degraded Mode |
|---|---|---|
| Project docs | Read CONTEXT.md, ARCHITECTURE.md, tech-stack.md | Skipped |
| Repo analysis | Config-driven repo matching | Skipped |
| Spec metadata | Project name, repo(s) from config | Generic placeholders |
| Research agents | Full context7 + project docs | context7 + file scanning only |

---

## 2. Research Agent Dispatch (Step 2)

Dispatch all 5 research agents in parallel via the Agent tool. Each agent
runs independently and returns structured findings. The brainstorm skill
collects all results before proceeding to Step 3.

### Agent Dispatch Pattern

```
Agent(
  subagent_type: "claude",
  description: "<agent name>",
  prompt: "<prompt from template below>",
  run_in_background: true
)
```

Launch all 5 in a single message so they run concurrently.

---

### 2.1 Architecture Agent

**Purpose:** Understand existing codebase structure, patterns, and integration
points relevant to the feature.

**Tools:**
- If code-review-graph MCP is available: `mcp__code-review-graph__semantic_search_nodes`, `mcp__code-review-graph__query_graph`, `mcp__code-review-graph__get_architecture_overview`
- Else: `Glob`, `Grep`, `Read`

**Prompt template:**

```
You are researching the codebase architecture for a feature: [feature].
Working directory: [workspace-root]

Find relevant modules, patterns, and dependencies. Focus on: [relevant areas
from project docs].

Steps:
1. Use code-review-graph tools (if available) or Glob/Grep/Read to explore
   the codebase structure.
2. Identify modules, files, and patterns that relate to [feature].
3. Note existing architectural patterns (naming conventions, file layout,
   framework idioms).
4. Identify potential integration points where the new feature would connect.

Report format (use exactly):

## Architecture Findings

### Existing Architecture
[modules, patterns, directory structure relevant to the feature]

### Relevant Patterns
[framework patterns, naming conventions, code organization approaches]

### Integration Points
[where the new feature would plug in — existing files, modules, APIs]

### Potential Conflicts
[anything that might clash with or constrain the new feature]
```

---

### 2.2 History Agent

**Purpose:** Find recent changes, existing specs, and plans related to the
feature topic.

**Tools:** `Bash` (git log), `Read`, `Glob`

**Prompt template:**

```
You are researching recent history for context on: [feature].
Working directory: [workspace-root]

Steps:
1. Run git log for recent commits in [target area] (last 30 days or 50
   commits, whichever is smaller).
2. Search docs/specs/ for existing specs matching keywords: [keywords].
3. Search docs/plans/ for existing plans matching keywords: [keywords].
4. Check for any open TODO/FIXME comments related to [keywords].

Report format (use exactly):

## History Findings

### Recent Changes
[relevant commits — hash, date, message, files touched]

### Related Specs
[existing specs that overlap with this feature — path, title, status]

### Related Plans
[existing plans that overlap — path, title, completion status]

### Open TODOs
[any TODO/FIXME comments in the codebase related to this feature]
```

---

### 2.3 Docs Agent

**Purpose:** Extract conventions, constraints, and decisions from project
documentation.

**Tools:** `Read`, `Glob`

**Prompt template:**

```
You are reading project documentation for context on: [feature].
Working directory: [workspace-root]

Steps:
1. Read CONTEXT.md — extract domain model, glossary terms, conventions
   relevant to [feature].
2. Read docs/project/architecture.md — extract system architecture,
   service boundaries, data storage relevant to [feature].
3. Read docs/project/tech-stack.md — extract technology constraints.
4. Read CLAUDE.md — extract workflow conventions and build commands.
5. Read any ADR docs (docs/adr/ or similar) relevant to [feature].
6. Read README files in [relevant repos] for repo-specific conventions.

Report format (use exactly):

## Documentation Findings

### Domain Context
[entities, glossary terms, relationships relevant to the feature]

### Conventions
[naming patterns, architectural patterns, coding standards that apply]

### Constraints
[technology limitations, decided-against approaches, firm requirements]

### Decisions
[prior ADRs or documented decisions that affect this feature]
```

---

### 2.4 Web Agent

**Purpose:** Research external documentation for frameworks, libraries, and
best practices relevant to the feature.

**Tools:** `mcp__context7__resolve-library-id`, `mcp__context7__query-docs`, `WebSearch`, `WebFetch`

**Prompt template:**

```
You are researching external documentation for: [feature].
Working directory: [workspace-root]
Tech stack: [technologies from config.json or detected from package.json]

Steps:
1. For each relevant framework/library in the tech stack, use context7:
   a. Resolve the library ID: mcp__context7__resolve-library-id
   b. Query relevant docs: mcp__context7__query-docs
2. If context7 does not cover the topic, fall back to WebSearch.
3. Look for: API patterns, best practices, version-specific notes,
   migration guides, known gotchas.

Report format (use exactly):

## External Documentation Findings

### Framework/Library Docs
[relevant API patterns, recommended approaches, version-specific notes]

### Best Practices
[industry best practices for this type of feature]

### Version Notes
[any version-specific considerations for the project's tech stack]

### Gotchas
[known issues, common mistakes, deprecated patterns to avoid]
```

---

### 2.5 Dependency Agent

**Purpose:** Analyze dependency and infrastructure context that affects
implementation choices.

**Tools:** `Read`, `Glob`, `Grep`

**Prompt template:**

```
You are analyzing dependency and infrastructure context for: [feature].
Working directory: [workspace-root]

Steps:
1. Read package.json files in all repos — note relevant dependencies and
   their versions.
2. Read config files: tsconfig.json, tailwind.config.*, vite.config.*,
   next.config.*, webpack.config.*, etc.
3. Check for Docker/infrastructure setup: Dockerfile, docker-compose.yml,
   deployment configs.
4. Check for CI/CD configuration: .github/workflows/, .gitlab-ci.yml,
   bitbucket-pipelines.yml.
5. Note any dependency constraints (peer deps, version locks, resolution
   overrides).

Report format (use exactly):

## Dependency Findings

### Available Dependencies
[relevant packages already installed — name, version, purpose]

### Config Patterns
[relevant configuration that affects implementation — compiler options,
 module resolution, path aliases, CSS strategy]

### Infrastructure
[Docker setup, deployment targets, environment configuration]

### Constraints
[version locks, peer dependency requirements, engine requirements]
```

---

## 3. Repo Analysis Decision Tree (Step 3)

After research agents return, determine which repo(s) the feature targets.

```
Read config.json --> repos array
Analyze feature scope against repos
|
+-- Fits one repo
|   --> Note target repo name and path
|   --> Continue to Step 4
|
+-- Spans multiple repos
|   --> Identify which repos and why
|   --> Example: "This feature needs changes in frontend-app (UI)
|       and backend-api (API endpoints)."
|   --> Spec will include a "Per-Repo Changes" section
|   --> Continue to Step 4
|
+-- Does not fit any repo
|   --> Offer options:
|   +-- New repo needed
|   |   --> "Consider running /project --add-repo first."
|   |   --> If user agrees, pause brainstorm, run add-repo, then resume
|   +-- Fit into existing
|       --> Recommend best-fit repo with reasoning
|       --> Continue to Step 4 with the chosen repo
|
+-- Too large for single spec
    --> "This feature is too large for a single brainstorm.
         Let's break it into sub-projects."
    --> Identify natural boundaries (by bounded context, by layer,
        by user-facing workflow)
    --> Present the proposed breakdown to the user
    --> Each sub-project gets its own brainstorm cycle
    --> Start with the first sub-project
```

### Repo Matching Heuristics

When analyzing which repo a feature belongs to, use these signals:

| Signal | Repo Match |
|---|---|
| UI components, pages, layouts, styling | Frontend repo (`type: "frontend"`) |
| API endpoints, controllers, middleware | Backend repo (`type: "backend"`) |
| Background jobs, workers, schedulers | Service repo (`type: "service"`) |
| Shared types, utilities, validators | Library repo (`type: "library"`) |
| Database schema changes | Repo that owns the ORM/schema definitions |
| Auth changes | Repo(s) that handle authentication |

---

## 4. Auto-Detection Rules (Step 4)

Scan the feature description, research findings, and target files to
auto-detect whether the feature involves UI work and/or security concerns.
Detection drives which conditional sections appear in the spec.

### UI Detection

**Keywords** (case-insensitive match against feature description and target
file content):

```
page, component, dashboard, form, modal, sidebar, navbar, layout, styling,
theme, responsive, animation, UI, UX, frontend, design system, button, menu,
dropdown, tooltip, carousel, tabs, accordion, card, grid, table, chart, graph,
notification, toast, badge, avatar, icon, color, font, spacing, margin,
padding, border, shadow, hover, click, scroll, drag, resize, transition
```

**File patterns** (match against target files and impacted paths):

```
src/components/**
src/pages/**
src/views/**
src/styles/**
src/app/**/*.tsx
*.css
*.scss
*.less
*.styled.*
*.module.css
tailwind.config.*
```

**Detection logic:**

```
UI detected = (any keyword matches feature description)
           OR (any target file matches a UI file pattern)
           OR (target repo type == "frontend")
```

### Security Detection

**Keywords** (case-insensitive match):

```
authentication, authorization, login, signup, register, OAuth, JWT, token,
session, password, API key, secret, encryption, decrypt, hash, payment,
billing, stripe, webhook, file upload, user input, validation, sanitization,
CORS, CSP, middleware, rate limiting, permissions, roles, admin, RBAC, access
control, credential, certificate, SSL, TLS, cookie, CSRF, XSS, SQL injection
```

**File patterns:**

```
**/auth/**
**/middleware/**
**/api/**
**/routes/**
*.env*
**/security/**
**/guards/**
**/policies/**
```

**Detection logic:**

```
Security detected = (any keyword matches feature description)
                 OR (any target file matches a security file pattern)
                 OR (feature modifies auth/middleware/route handler files)
```

### Detection Output

After running both checks, report the results to the user:

```
Detected:
  UI:       [yes | no]
  Security: [yes | no]
```

If UI is detected, the spec will include a Visual Design section.
If Security is detected, the spec will include a Security Requirements section.

---

## 5. Visual Companion Behavior (Step 4a)

When UI is detected, the brainstorm skill creates visual companions using
Artifacts to help the user evaluate design options. This section defines
when to use browser-based visuals vs terminal text.

### Use Browser (Artifacts)

Create an Artifact for:

- Mockups of proposed UI layouts
- Wireframes showing component hierarchy
- Color palette comparisons
- Typography demonstrations
- Layout alternatives shown side-by-side
- Architecture diagrams (component trees, service maps)
- Data flow diagrams

**Rules for Artifact creation:**

- Always include light and dark theme support
- Use relative units and responsive layout
- Keep mockups low-fidelity (wireframe-style) to avoid bikeshedding on pixels
- Label each alternative clearly (Option A, Option B)
- Include interactive toggles when showing alternatives

### Use Terminal (text output)

Keep in the terminal for:

- Requirements lists and bullet points
- Conceptual choices (e.g., "server vs client rendering?")
- Trade-off comparison tables
- Scope decisions (in vs out)
- Naming conventions and API contract designs
- Data model definitions

### Decision Rule

```
Is this about how something LOOKS?
+-- Yes --> Artifact (browser)
+-- No
    Is this a structural diagram that benefits from visual layout?
    +-- Yes --> Artifact (browser)
    +-- No  --> Terminal (text)
```

---

## 6. Clarifying Question Guidelines (Step 5)

Rules for the clarifying question phase. The goal is to resolve ambiguity
and fill gaps without making the user feel interrogated.

### Delivery Rules

- Ask **one question at a time** — never batch multiple unrelated questions
  in a single message.
- Prefer **multiple choice format** — easier and faster for the user to
  answer. Include an "Other" option when the list is not exhaustive.
- Start with the **highest-impact question** — the one that most affects the
  overall design direction.
- Use **research findings to inform questions** — do not ask what you already
  know from the codebase or docs.
- Limit to **3-6 questions total** — more than 6 makes the process feel like
  an interrogation. If you need more clarity, make a reasonable assumption
  and note it in the spec.

### Topic Priority by Detection

**If UI detected, ask early about:**

- Visual style preference (match existing design system vs new direction)
- Existing component patterns to reuse
- Target devices and screen sizes
- Accessibility requirements

**If Security detected, ask early about:**

- Data sensitivity level (public, internal, PII, financial)
- Compliance requirements (GDPR, SOC2, HIPAA, none)
- Trust boundaries (who can access what)
- Auth integration approach (existing auth system vs new)

### Question Formatting

Present each question as:

```
? [Question text]
  * Option A — [brief explanation]
  * Option B — [brief explanation]
  * Option C — [brief explanation]
  * Other — [let the user specify]
```

### When to Stop Asking

Stop asking and move to approach presentation when:

- You have enough information to propose 2-3 meaningfully different
  approaches.
- The remaining unknowns are implementation details, not design direction.
- You have asked 6 questions already.

---

## 7. Approach Presentation Template (Step 6)

Present 2-3 approaches for the user to choose from. Always recommend one.

### Template

```markdown
## Approaches

### Option 1: [Name] (Recommended)

**How it works:** [2-3 sentences explaining the approach at a high level.
What changes, what stays the same, what the user experience looks like.]

**Pros:**
- [Pro 1]
- [Pro 2]

**Cons:**
- [Con 1]

**Best when:** [scenario where this approach is the right choice]

### Option 2: [Name]

**How it works:** [2-3 sentences]

**Pros:**
- [Pro 1]

**Cons:**
- [Con 1]
- [Con 2]

**Best when:** [scenario]

---

**Recommendation:** Option 1 because [reason tied to project context —
reference specific tech stack, existing patterns, or team size].
```

### Approach Presentation Rules

- Always present at least 2 options. Maximum 3 — more causes decision
  paralysis.
- The recommended option should be first.
- Pros/cons must be concrete and project-specific, not generic.
- "Best when" helps the user self-select if they disagree with the
  recommendation.
- If the user picks an approach, proceed to Step 7. If they want a
  hybrid or something different, iterate once, then proceed.

---

## 8. Design Section Templates (Step 7)

After the user picks an approach, build out the full design. The spec
includes standard sections (always present) and conditional sections
(included based on auto-detection from Step 4).

### Standard Sections (always include)

```markdown
## Architecture

[Components, modules, and boundaries. How they connect to each other and
to existing code. What is new vs what is modified. Include file paths
where known.]

## Data Flow

[How data enters the system, transforms, stores, and leaves. Include
the happy path AND error paths. Name the specific models, APIs, and
handlers involved.]

## Per-Repo Changes

[Only for multi-repo projects. Omit for mono-repo.]

| Repo | Changes | New Files | Modified Files |
|---|---|---|---|
| [repo-name] | [what changes] | [new file paths] | [modified file paths] |

## Error Handling

[Failure modes and what happens for each. Recovery strategies. User-facing
error messages (exact copy). Logging and monitoring approach.]

## Testing Strategy

[What to test — unit, integration, e2e. Key scenarios to cover. Edge cases.
NOT TDD methodology — just what needs testing and why.]
```

### Conditional Sections

**Visual Design** (included when UI detected):

```markdown
## Visual Design

### Component Hierarchy
[parent-child relationships between UI components]

### Interaction States
[default, hover, active, disabled, loading, error, empty states]

### Color and Typography
[which tokens from brand.md to use, or new tokens to add]

### Responsive Behavior
[how the UI adapts across breakpoints — mobile, tablet, desktop]

### Accessibility
[ARIA roles, keyboard navigation, screen reader considerations,
color contrast requirements]
```

**Security Requirements** (included when Security detected):

```markdown
## Security Requirements

### Authentication
[auth approach — session, JWT, OAuth. Integration with existing auth.]

### Authorization
[who can access what. Role/permission model. Trust boundaries.]

### Input Validation
[what inputs are accepted, sanitization rules, validation error handling]

### Data Protection
[encryption at rest, in transit. PII handling. Data retention.]

### Rate Limiting
[which endpoints, threshold values, response to limit breach]

### Audit Logging
[what events to log, log format, retention policy]

### Compliance
[applicable regulations, specific requirements they impose]
```

---

## 9. Spec File Template (Step 8)

The final spec is written to `docs/specs/YYYY-MM-DDTHH-MM-SS-<topic>-design.md`.

### Filename Rules

- Timestamp format: `YYYY-MM-DDTHH-MM-SS` (ISO 8601 without colons in
  time, using hyphens — safe for all filesystems).
- Topic: kebab-case, derived from the feature name. Strip articles (a, an,
  the). Maximum 40 characters.
- Example: `2026-07-30T14-22-05-user-role-management-design.md`

### Template

```markdown
# [Feature Name] — Design Spec

**Project:** [project name from config.json]
**Repo(s):** [target repo(s) — e.g., `frontend-app`, `backend-api`]
**Scope:** [one-line scope description]
**Approach:** [chosen approach name from Step 6]

---

## 1. Overview

[2-3 paragraph summary of what this feature does and why it matters. Include
the user-facing behavior, the technical approach at a high level, and any
key decisions made during brainstorming.]

---

## 2. Architecture

[from Step 7 standard sections]

---

## 3. Data Flow

[from Step 7 standard sections]

---

## 4. Per-Repo Changes

[from Step 7 standard sections — omit for mono-repo]

---

## N. Error Handling

[from Step 7 standard sections]

---

## N+1. Testing Strategy

[from Step 7 standard sections]

---

## N+2. Visual Design

[from Step 7 conditional sections — only if UI detected]

---

## N+3. Security Requirements

[from Step 7 conditional sections — only if Security detected]

---

## N+4. Out of Scope

[Explicitly state what this spec does NOT cover, to prevent scope creep
during implementation. Be specific — vague exclusions invite ambiguity.]
```

### Section Numbering

Sections are numbered sequentially starting from 1. Conditional sections
are included or excluded, and remaining sections renumber accordingly. The
`N` placeholders above indicate variable positions — the actual spec uses
concrete numbers.

---

## 10. Self-Review Checklist (Step 9)

Before presenting the spec to the user, the brainstorm skill runs this
checklist against the generated spec. Every item must pass. Fix issues
in-place rather than flagging them for the user.

### 1. Placeholder Scan

Search the spec for any of the following:

```
TBD
TODO
FIXME
"to be determined"
"will be decided"
"to be defined"
[...]
[placeholder]
<placeholder>
```

Also check for empty sections (a heading followed immediately by another
heading or end-of-file with no content between).

**Action:** For each placeholder found, make a concrete decision based on
research findings and the chosen approach. If you genuinely cannot decide,
remove the section entirely rather than leaving a placeholder.

### 2. Internal Consistency

Verify that:

- Architecture section and Data Flow section agree on components and their
  interactions.
- Per-Repo Changes (if present) covers every component mentioned in
  Architecture.
- Error states in Error Handling align with failure points described in
  Data Flow.
- Testing Strategy covers the main scenarios from Data Flow and the error
  cases from Error Handling.
- Visual Design (if present) references components mentioned in
  Architecture.
- Security Requirements (if present) covers all trust boundaries implied
  by Data Flow.

**Action:** Fix any inconsistencies by updating the less-specific section
to match the more-specific one.

### 3. Scope Check

Estimate the implementation size:

```
Can this be implemented in a single plan (5-20 tasks)?
+-- Yes --> Pass
+-- No (feels like 30+ tasks)
    --> Too big. Split the spec into smaller specs, each covering a
        natural boundary (by layer, by user workflow, by bounded context).
```

**Action:** If too large, inform the user and propose a breakdown before
writing the spec.

### 4. Ambiguity Check

Read each requirement in the spec. For each, ask: "Could a developer
interpret this two different ways?"

```
Ambiguous?
+-- Yes --> Pick one interpretation explicitly. Write it as a concrete
            statement, not a question.
+-- No  --> Pass
```

**Action:** Rewrite ambiguous statements to be unambiguous. Prefer concrete
examples over abstract descriptions.

---

## 11. Grill Gate Dispatch (Step 11)

After the user reviews the spec, offer the grill option:

```
Spec written to docs/specs/<filename>.

Want to stress-test this design? I can grill it for gaps and edge cases.
  * Yes, grill it
  * No, it's good — move to planning
```

### When User Says "Yes, grill it"

Dispatch the grill-agent:

```
Agent(
  subagent_type: "claude",
  description: "Grill the design spec",
  prompt: """
    You are the grill-agent for Fullstack Dev.
    Read your full instructions from: <plugin-path>/agents/grill-agent.md

    Spec file to analyze: <spec-path>
    Working directory: <workspace-root>

    Execute the grill flow defined in your agent instructions.
    Return your findings as structured text.
  """,
  run_in_background: false
)
```

### Processing Grill Findings

After the grill-agent returns findings:

1. **Present findings to the user**, grouped by priority:

   ```
   ## Grill Results

   ### Critical (must fix)
   1. [finding]
   2. [finding]

   ### Important (should fix)
   1. [finding]

   ### Minor (nice to fix)
   1. [finding]
   ```

2. **For each Critical finding:** Update the spec immediately. No user
   confirmation needed — critical issues are always fixed.

3. **For each Important finding:** Update the spec immediately. These are
   strong recommendations that improve the design.

4. **For Minor findings:** Present to the user and ask which ones to
   address:

   ```
   ? Which minor items should I address?
     * All of them
     * None — they're fine as-is
     * Let me pick: [list with checkboxes]
   ```

5. **Re-commit the updated spec** with message:
   `docs: update <topic> spec after grill review`

6. **Report the final state:**

   ```
   Spec updated with grill feedback:
     - [N] critical items fixed
     - [N] important items fixed
     - [N] minor items addressed
   
   Spec: docs/specs/<filename>
   ```

### When User Says "No"

Skip the grill and proceed directly to Step 12 (Plan Transition).

---

## 12. Plan Transition Detection (Step 12)

After the spec is finalized (either after grill or after user declines
grill), offer to transition to planning.

### Detection Logic

```
/plan command available? (check commands/plan.md exists in the plugin directory)
+-- YES
|   --> Tell the user:
|       "Spec is ready! To create an implementation plan, run:
|        /plan --auto <spec-path>"
|   --> Then offer a choice via AskUserQuestion:
|       (a) Invoke /plan now — auto-run /plan --auto <spec-path>
|       (b) I'll do it manually later
|   +-- User picks (a) --> invoke the plan skill via Skill tool,
|       passing --auto and the spec path
|   +-- User picks (b) --> done, end the brainstorm session
+-- NO
    --> "Spec is ready at <spec-path>. Create an implementation plan
         when a plan command is available."
```

When no plan command is found:

```
Spec finalized at docs/specs/<filename>.

No plan command is available yet. When one is installed, run it
against this spec to generate an implementation plan.
```

---

## 13. Naming Collision Note

The `/brainstorm` command from the Fullstack Dev plugin may conflict with
existing `/brainstorm` commands in the target workspace — for example, from
Superpowers or local skill overrides.

### Detection

During plugin installation or project init, check for:

1. A skill file at `.claude/skills/brainstorm/SKILL.md` in the workspace.
2. A skill named `brainstorm` in any loaded plugin.

### Resolution

If a collision is detected:

```
A /brainstorm command already exists in this workspace.

  Existing: [source — e.g., "Superpowers plugin" or "local skill"]
  New:      Fullstack Dev brainstorm (project-aware, with research agents)

Options:
  * Replace existing with Fullstack Dev version
  * Keep existing, skip Fullstack Dev brainstorm
  * Rename Fullstack Dev version to /brainstorm-fd
```

If the user chooses to replace, remove the old skill files. If they choose
to rename, install under the alternate name.

See the plugin README for manual removal instructions if the conflict is
discovered outside the init flow.
