# Refactor Flow Reference

Detailed decision trees, refactoring catalog, scoring algorithm, metrics,
graph workflows, and anti-patterns for the refactor skill.

---

## 1. Refactoring Catalog

All 12 supported refactoring operations. Select from this catalog when
planning operations in Step 4.

| Operation | When to Use |
|-----------|-------------|
| **Extract function** | Function doing too many things — extract a coherent chunk into its own named function |
| **Extract module/file** | File with mixed responsibilities — split into focused modules |
| **Inline** | Unnecessary abstraction (used once, adds indirection) — collapse back into the caller |
| **Rename** | Name doesn't match what it does — align name with actual behavior |
| **Move** | Code is in the wrong module — relocate to where it logically belongs |
| **Extract interface/type** | Multiple implementations share a shape — extract the common contract |
| **Replace conditional with polymorphism** | Complex if/switch on type — use dispatch instead of branching |
| **Simplify parameters** | Too many args — group into an options/config object |
| **Remove dead code** | Unused exports, unreachable branches — delete them |
| **Flatten nesting** | Deep indentation — use early returns, guard clauses |
| **Deepen module** | Shallow module — interface nearly as complex as implementation |
| **Merge modules** | Tightly coupled modules that should be one — combine them |

> **Note:** "Deepen module" is a manual judgment operation. It is NOT
> included in automated discovery scoring because "shallow" has no reliable
> automated metric. It appears as a suggestion only when community analysis
> reveals modules with high export-to-LOC ratios.

---

## 2. Anti-Patterns (Blocked)

These patterns are explicitly blocked. If you catch yourself doing any of
them, stop immediately.

| Anti-Pattern | Why It's Blocked | Do Instead |
|---|---|---|
| Batching multiple operations into one commit | Can't revert individually. Compound changes mask which operation broke tests. | One operation, one commit. Always. |
| Refactoring without running tests first | No baseline = no safety net. You won't know if the refactoring broke something. | Establish green baseline before any change. |
| "Fix forward" after a failed test | Stacking changes makes the problem harder to diagnose. | Revert immediately, analyze, try a different approach (max 2 alternatives). |
| Changing behavior during refactoring | Refactoring preserves external behavior (= what tests assert). Behavior changes are feature work. | If behavior needs changing, stop and use `/brainstorm` → `/plan` → `/implement`. |
| Refactoring test assertions | Tests are the safety net. Changing assertions removes the safety. | Leave test assertions alone. Only update test imports after structural moves. |
| Proceeding without user plan approval | User must understand and agree with the plan. Surprises are bad. | Always present the plan and get approval (even in `--auto` mode). |

---

## 3. Scope Control

### DO Refactor

- The specific target identified or selected from candidates
- Direct dependencies IF tightly coupled to the target
- Dead code that's part of the target module

### DO NOT Refactor

- Unrelated code noticed while working
- Test assertions or test logic (tests are the safety net)
- Configuration files unless directly needed
- Code that "could be better" but isn't part of the target

### Exception

Updating test imports/paths to follow production renames IS required — this
is maintaining test infrastructure, not refactoring tests.

---

## 4. Verbose Output Format (`--verbose`)

Tagged output for structured progress reporting. Each tag corresponds to
the step producing it.

### Step 2 (Discovery)

```
[DISCOVERY] Scanning 3 repos, 247 source files...
[GRAPH] find_large_functions: 12 candidates
[GRAPH] refactor_tool(suggest): 8 suggestions
[GRAPH] refactor_tool(dead_code): 3 unreferenced exports
[GRAPH] list_communities: 5 tightly-coupled clusters
[GRAPH] get_hub_nodes: 4 high-risk central nodes
[GRAPH] get_bridge_nodes: 2 cross-community connectors
[SCORE] src/services/auth.ts: severity=0.9 freq=0.6 risk=0.8 gap=0.7 → score=0.82
[SCORE] src/utils/helpers.ts: severity=0.3 freq=0.2 risk=0.2 gap=0.5 → score=0.28
```

### Step 3 (Assessment)

```
[ASSESS] Blast radius: 47 dependents
[ASSESS] Affected flows: /api/auth/login, /api/auth/refresh, /api/users/me
[TESTS] Running 14 related tests... all pass
[METRICS] LOC=342 functions=12 max_length=67 imports=8
```

### Step 5 (Execute)

```
[OP 1/3] Extract validateToken from authMiddleware
[DIFF] +15 -67 lines in src/middleware/auth.ts
[TESTS] Running 14 related tests... all pass
[COMMIT] refactor: extract validateToken from authMiddleware

[OP 2/3] Move session helpers to src/services/session.ts
[DIFF] +42 -38 lines across 2 files
[TESTS] Running 14 related tests... all pass
[COMMIT] refactor: move session helpers to session.ts

[OP 3/3] Inline unused formatError wrapper
[DIFF] +0 -12 lines in src/utils/errors.ts
[TESTS] Running 14 related tests... all pass
[COMMIT] refactor: inline formatError wrapper
```

---

## 5. Discovery Scoring Algorithm

Each candidate receives a composite score using a **weighted sum** (not
multiplication — ensures no single zero-value factor zeroes the entire
score):

```
score = (0.4 × severity) + (0.2 × change_frequency) + (0.2 × change_risk) + (0.2 × test_gap)
```

### Severity Values

| Candidate Type | Severity |
|----------------|----------|
| dead_code | 0.3 |
| bridge_node (natural seam) | 0.4 |
| long_function | 0.5 |
| code_duplication | 0.6 |
| high_coupling | 0.7 |
| god_class | 0.9 |

### Change Frequency

```
change_frequency = min(git_log_count / 10, 1.0)

Measurement:
  git log --oneline --since="30 days" <file> | wc -l

Interpretation:
  10+ commits in 30 days = 1.0 (maximum frequency)
  0 commits = 0.0 (still surfaces via severity weight)
```

### Change Risk

Based on `get_impact_radius` dependent count:

| Dependents | Risk Score |
|------------|------------|
| 0–5 | 0.2 (low risk, safe to change) |
| 6–20 | 0.5 |
| 21–50 | 0.8 |
| 51+ | 1.0 |

### Test Gap

```
test_gap = 1 - (tested_functions / total_functions)

Interpretation:
  0 = fully tested
  1 = no tests
```

### Threshold

Candidates with score < **0.15** are filtered out and excluded from the
ranked list.

> **Note:** "Deepen module" is NOT included in automated discovery scoring.
> It appears only as a manual suggestion when community analysis reveals
> modules with high export-to-LOC ratios.

---

## 6. Metrics Definitions

Baseline metrics measured in Step 3 and re-measured in Step 6 for
before/after comparison.

| Metric | Measurement Approach |
|--------|---------------------|
| Lines of code | Count non-empty, non-comment lines in target files |
| Number of functions/methods | Count function/method declarations |
| Max function length | Longest function body in lines |
| Import/dependency count | Count import/require statements |
| Coupling (dependents) | `get_impact_radius` dependent count from graph |
| Cohesion (internal connectivity) | Ratio of internal calls to total calls within the module |
| Cyclomatic complexity | Count decision points (if/else/switch/for/while/catch) per function, if measurable |

### Before/After Comparison Table Format

```
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Lines of code | 342 | 198 | -42% |
| Functions | 12 | 8 | -33% |
| Longest function | 67 | 25 | -63% |
| Imports | 8 | 4 | -50% |
| Files | 1 | 2 | +1 (extracted session.ts) |
| Dependents | 47 | 47 | (unchanged) |
| Tests passing | 14 | 14 | (no change) |
```

---

## 7. Graph Tool Workflows by Step

Primary analysis engine. Graph tools are required when available, with
fallback if unavailable.

### Graph Tool Usage

| Step | Graph Tools | Purpose |
|------|-------------|---------|
| Step 2 | `find_large_functions`, `refactor_tool(suggest)`, `refactor_tool(dead_code)`, `list_communities`, `get_hub_nodes`, `get_bridge_nodes` | Find candidates |
| Step 3 | `get_impact_radius`, `get_affected_flows`, `query_graph(tests_for)` | Assess risk and coverage |
| Step 4 | `refactor_tool(rename)` | Preview rename impacts |
| Step 5 | `apply_refactor_tool` | Execute renames across files |
| Step 7 | `detect_changes` | Verify change scope |

### Fallback (No Graph)

| Step | Fallback | Trade-off |
|------|----------|-----------|
| Step 2 | Glob + Read + manual metrics | Slower, misses structural relationships |
| Step 3 | Grep for imports + Read tests | No blast radius, no flow analysis |
| Step 4 | Manual rename search | May miss indirect references |
| Step 5 | Edit tool only | No cross-file rename safety |
| Step 7 | `git diff --stat` | No structural verification |

---

## 8. Rename Workflow

For rename operations with graph support, use the 4-step graph-assisted
workflow:

```
1. refactor_tool(mode="rename", ...) → preview all affected locations
2. Review the edit list — verify all locations are correct
3. apply_refactor_tool(refactor_id) → apply edits across all files
4. Run related tests → commit or revert
```

Without graph support, fall back to:

```
1. Grep for all references to the old name
2. Edit each file manually
3. Run related tests → commit or revert
```

---

## 9. Multi-Repo Execution

When a refactoring operation spans multiple repos (e.g., rename in repo A
affects imports in repo B):

```
1. Apply changes to ALL affected repos before running tests
2. Run related tests in ALL affected repos
3. Result:
   +-- ALL pass → commit in each repo separately
   |   Commit messages reference each other:
   |   "refactor: <operation> (1/2 — see <other-repo>)"
   +-- ANY fail → revert in ALL repos (maintain consistency)
       git checkout -- $CHANGED_FILES in each affected repo
```

Rules:
- Changes are atomic across repos — partial application is never acceptable
- Test ALL repos before committing ANY
- Revert ALL repos if ANY test fails
- Each repo gets its own commit with cross-references to related commits
