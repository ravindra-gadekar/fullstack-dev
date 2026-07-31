# Phase 1: Foundation — context7-usage.md

**Repo:** fullstack-dev
**Depends on:** None
**Delivers:** The canonical `skills/project/reference/context7-usage.md` doc that every subsequent phase's agent sections point to instead of duplicating the discipline inline.

## File Structure

```
skills/project/reference/
└── context7-usage.md   [CREATE]
```

### Task 1: Create the canonical context7 usage doc

**Files:**
- Create: `skills/project/reference/context7-usage.md`

**Interfaces:**
- Consumes: none (foundation task).
- Produces: `skills/project/reference/context7-usage.md` — sections `## When to Use context7` (with `### Concrete Skip Heuristic`), `## Call Flow`, `## Call-Budget Discipline` (with `### Per-Instance Budgets for Parallel Dispatch`), `## When context7 Is Unavailable or Insufficient`. All 10 tasks in Phases 2–4 consume this file by reference (a pointer line in each agent's new/updated section).

**Acceptance Criteria:** AC1

**Steps:**

1. **Write content.** Create `skills/project/reference/context7-usage.md` with exactly this content:

   ```markdown
   # Context7 Usage

   The canonical reference for how any Fullstack Dev agent uses the context7 MCP
   server to fetch current, version-accurate documentation. Every agent with the
   `context7` MCP grant points here instead of repeating this discipline inline --
   mirroring how `skills/git/SKILL.md` is referenced from other skills as shared
   behavior.

   ---

   ## When to Use context7

   Query context7 when correctness depends on matching a fast-moving or
   versioned API -- not for every task that happens to touch a library.

   ### Concrete Skip Heuristic

   Skip context7 for:
   - Language built-ins (standard library functions, core syntax).
   - Any API that has been unchanged across the library's last two major
     versions.
   - Trivial tasks where no version-specific behavior is in play (e.g.
     renaming a variable, fixing a typo, formatting).

   Query context7 for:
   - APIs introduced or changed within the target project's currently pinned
     major version (per `package.json` / `requirements.txt` / `pom.xml` /
     `Gemfile` / `composer.json` / `*.csproj` -- whichever the target project
     uses).
   - Framework conventions, config schemas, or directory structures you are
     not certain are still current for the detected version.

   This bar is falsifiable, not a judgment call: if you cannot name the
   specific version-pinned API or convention you are unsure about, you do not
   need context7 for this task.

   ---

   ## Call Flow

   1. Call `mcp__context7__resolve-library-id` with the library/framework name
      to resolve it to a context7-recognized library ID.
   2. Call `mcp__context7__query-docs` with that ID, scoped to **one concept**
      -- e.g. "Next.js App Router route handlers", not "Next.js routing and
      data fetching and middleware".
   3. Incorporate the returned documentation into your output (code written,
      root-cause hypothesis, review finding, refreshed doc content) and
      continue your normal flow. This is a knowledge lookup step embedded in
      existing behavior, not a new orchestration path.

   ---

   ## Call-Budget Discipline

   Some environments cap context7 calls per question (e.g. at 3). Scope each
   query tightly and narrowly up front rather than issuing broad queries and
   retrying:

   - One `resolve-library-id` call per library you need to look up.
   - One `query-docs` call per concept, not per question you might have about
     that concept.
   - If the budget is exhausted before you have enough information, proceed
     with what you gathered and explicitly note the incompleteness in your
     output rather than looping or stalling.

   ### Per-Instance Budgets for Parallel Dispatch

   `debugger-agent` and `refactor-agent` are dispatched once per investigation
   dimension (up to 5 and 4 parallel instances respectively) as part of
   `/debug` and `/refactor`'s normal parallel-evidence-gathering flow. A single
   user question can therefore fan out to several times the per-instance
   budget in aggregate. To avoid this:

   - `debugger-agent` reserves context7 calls for the `dependencies` dimension
     only. Do not query context7 when investigating `stack-trace`,
     `git-blame`, `tests`, or `patterns`.
   - `refactor-agent` reserves context7 calls for the `dependencies` and
     `patterns` dimensions only. Do not query context7 when investigating
     `metrics` or `tests`.

   ---

   ## When context7 Is Unavailable or Insufficient

   - **context7 unavailable or declined in this project** (MCP server
     unreachable, or the user opted out during `/project --init`): proceed on
     best-effort existing knowledge and flag the gap with a note in your
     output. Never block the task on a missing MCP tool. No agent has a
     `WebSearch` grant to fall back to (only `grill-agent` has `WebFetch`,
     scoped to a specific known URL) -- do not suggest general web search as
     a substitute.
   - **Library not resolvable via `resolve-library-id`**: proceed on
     best-effort existing knowledge for that library. Note the fallback as a
     known limitation in your output rather than silently guessing.
   ```

2. **Verify references.** Confirm the file was written with all four `##` sections present (`grep -c "^## " skills/project/reference/context7-usage.md` should report `4`), and that the doc names both `mcp__context7__resolve-library-id` and `mcp__context7__query-docs` exactly (matching the tool names used elsewhere in this plan and in `agents/scanner-agent.md`'s existing MCP usage).

3. **Commit.**

   ```
   docs(reference): add canonical context7-usage.md
   ```

---

## Phase 1 Complete

`skills/project/reference/context7-usage.md` exists with the full call flow, query scoping guidance, budget discipline (including the debugger-agent/refactor-agent per-instance reservation rule), and skip heuristic. No agent yet points to it — that begins in Phase 2.

**Next:** `phase-2.md`
