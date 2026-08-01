# Phase 2: Unify Dispatch Path References

**Repo:** fullstack-dev (path `.`)
**Depends on:** Phase 1 (agent files must exist at their new `skills/<name>/agents/` locations before dispatch blocks are pointed at them)
**Delivers:** Every `SKILL.md` and reference doc that dispatches an agent uses the single idiom — "Read `agents/<name>.md` relative to this SKILL.md file" + `subagent_type: "claude"` — with zero remaining `<plugin-path>/agents/`, `../../agents/`, or named-agent `subagent_type` references.

## File Structure

```
skills/project/SKILL.md                        [modify] 3 dispatch blocks
skills/plan/SKILL.md                            [modify] 1 dispatch block
skills/plan/reference/plan-flow.md              [modify] 1 dispatch block
skills/brainstorm/SKILL.md                      [modify] inline prompt -> file-read
skills/brainstorm/reference/brainstorm-flow.md  [modify] 1 dispatch block
skills/debug/reference/debug-flow.md            [modify] 5 named-subagent calls -> path-read
skills/refactor/SKILL.md                        [modify] 4 named-subagent calls -> path-read
skills/implement/SKILL.md                       [modify] reference table paths
skills/implement/reference/implement-flow.md    [modify] 3 agent-pointer notes
```

---

### Task 1: Fix project-skill dispatch paths (init, repo, refresh)

**Files:**
- Modify: `skills/project/SKILL.md`

**Interfaces:**
- Consumes: Phase 1 Task 1 Produces (`skills/project/agents/{init,repo,refresh}-agent.md` exist)
- Produces: three corrected dispatch blocks, consumed by Phase 4 Task 1's `grep -r "<plugin-path>/agents/" skills/` verification

**Acceptance Criteria:** Spec checkboxes "All SKILL.md and reference doc dispatch blocks use skill-relative agent paths..." and "`grep -r \"<plugin-path>/agents/\" skills/` returns zero matches" (project subset).

**Steps:**
1. In `skills/project/SKILL.md`, replace the line `    Read your full instructions from: <plugin-path>/agents/init-agent.md` with `    Read your full instructions from: agents/init-agent.md (relative to this SKILL.md file)`.
2. Replace `    Read your full instructions from: <plugin-path>/agents/repo-agent.md` with `    Read your full instructions from: agents/repo-agent.md (relative to this SKILL.md file)`.
3. Replace `    Read your full instructions from: <plugin-path>/agents/refresh-agent.md` with `    Read your full instructions from: agents/refresh-agent.md (relative to this SKILL.md file)`.
4. Verify: `grep -n "plugin-path" skills/project/SKILL.md` returns zero matches.
5. Commit: `fix(skills): use skill-relative agent paths in project dispatch blocks`

---

### Task 2: Fix plan-skill dispatch paths (plan-reviewer)

**Files:**
- Modify: `skills/plan/SKILL.md`
- Modify: `skills/plan/reference/plan-flow.md`

**Interfaces:**
- Consumes: Phase 1 Task 2 Produces (`skills/plan/agents/plan-reviewer-agent.md` exists)
- Produces: corrected dispatch blocks in both files, consumed by Phase 4 Task 1 verification

**Acceptance Criteria:** Spec checkboxes "1 dispatch block: replace `<plugin-path>/agents/plan-reviewer-agent.md`..." (both `skills/plan/SKILL.md` and `skills/plan/reference/plan-flow.md` entries in the File Changes table).

**Steps:**
1. In `skills/plan/SKILL.md`, replace:
   ```
       You are plan-reviewer-agent. Read your full instructions from:
       <plugin-path>/agents/plan-reviewer-agent.md
   ```
   with:
   ```
       You are plan-reviewer-agent. Read your full instructions from:
       agents/plan-reviewer-agent.md (relative to this SKILL.md file)
   ```
2. In `skills/plan/reference/plan-flow.md`, replace:
   ```
   |         You are plan-reviewer-agent. Read your full instructions from:
   |         <plugin-path>/agents/plan-reviewer-agent.md
   ```
   with:
   ```
   |         You are plan-reviewer-agent. Read your full instructions from:
   |         agents/plan-reviewer-agent.md (relative to this SKILL.md file)
   ```
3. Verify: `grep -rn "plugin-path" skills/plan/` returns zero matches.
4. Commit: `fix(skills): use skill-relative agent paths in plan-reviewer dispatch blocks`

---

### Task 3: Convert brainstorm SKILL.md grill-agent dispatch from inline prompt to file-read

**Files:**
- Modify: `skills/brainstorm/SKILL.md`

**Interfaces:**
- Consumes: Phase 1 Task 3 Produces (`skills/brainstorm/agents/grill-agent.md` exists); the authoritative file-read pattern already present in `skills/brainstorm/reference/brainstorm-flow.md` (lines 897-914, pre-fix)
- Produces: `skills/brainstorm/SKILL.md`'s grill dispatch now matches the reference doc's idiom, consumed by Phase 4 Task 1 verification

**Acceptance Criteria:** Spec checkbox "Brainstorm SKILL.md grill-agent dispatch converted from inline prompt to file-read pattern (matching the authoritative reference doc)".

**Steps:**
1. In `skills/brainstorm/SKILL.md`, locate the "### Grill Agent Dispatch" section (the `Agent(description: "Grill the design spec", prompt: """ You are grill-agent. Your job is to stress-test a design spec... """)` block that embeds the full grill instructions inline).
2. Replace the entire inline-prompt `Agent(...)` block with the file-read pattern, mirroring `brainstorm-flow.md`'s existing dispatch:
   ```
   Agent(
     subagent_type: "claude",
     description: "Grill the design spec",
     prompt: """
       You are the grill-agent for Fullstack Dev.
       Read your full instructions from: agents/grill-agent.md (relative to this SKILL.md file)

       Spec file to analyze: <spec-path>
       Working directory: <workspace-root>

       Execute the grill flow defined in your agent instructions.
       Return your findings as structured text.
     """,
     run_in_background: false
   )
   ```
3. Verify: `grep -n "You are grill-agent. Your job is to stress-test" skills/brainstorm/SKILL.md` returns zero matches (inline prompt text is gone) and `grep -n "agents/grill-agent.md" skills/brainstorm/SKILL.md` returns one match.
4. Commit: `fix(skills): convert brainstorm grill-agent dispatch to file-read pattern`

---

### Task 4: Fix brainstorm-flow.md grill-agent dispatch path

**Files:**
- Modify: `skills/brainstorm/reference/brainstorm-flow.md`

**Interfaces:**
- Consumes: Phase 1 Task 3 Produces (`skills/brainstorm/agents/grill-agent.md` exists)
- Produces: corrected dispatch block, consumed by Phase 4 Task 1 verification

**Acceptance Criteria:** Spec checkbox "1 dispatch block: replace `<plugin-path>/agents/grill-agent.md` with skill-relative path" (`skills/brainstorm/reference/brainstorm-flow.md` entry).

**Steps:**
1. Replace `    Read your full instructions from: <plugin-path>/agents/grill-agent.md` with `    Read your full instructions from: agents/grill-agent.md (relative to this SKILL.md file)`.
2. Verify: `grep -n "plugin-path" skills/brainstorm/reference/brainstorm-flow.md` returns zero matches.
3. Commit: `fix(skills): use skill-relative agent path in brainstorm-flow grill dispatch`

---

### Task 5: Convert debug-flow.md named subagent dispatch to path-read pattern

**Files:**
- Modify: `skills/debug/reference/debug-flow.md`

**Interfaces:**
- Consumes: Phase 1 Task 5 Produces (`skills/debug/agents/debugger-agent.md` exists)
- Produces: 5 corrected `Agent()` calls using `subagent_type: "claude"`, consumed by Phase 4 Task 1's `grep -r "subagent_type.*-agent" skills/` verification

**Acceptance Criteria:** Spec checkbox "Named `subagent_type` dispatches in `debug` and `refactor` converted to path-read + `subagent_type: \"claude\"` pattern" (debug subset).

**Steps:**
1. In `skills/debug/reference/debug-flow.md` Section 11 ("Parallel Agent Dispatch (`--parallel`)"), replace:
   ```
   Agent(description="Stack Trace Agent", prompt="...", subagent_type="debugger-agent")
   Agent(description="Git Blame Agent", prompt="...", subagent_type="debugger-agent")
   Agent(description="Test Agent", prompt="...", subagent_type="debugger-agent")
   Agent(description="Pattern Agent", prompt="...", subagent_type="debugger-agent")
   Agent(description="Dependency Agent", prompt="...", subagent_type="debugger-agent")
   ```
   with:
   ```
   Agent(description="Stack Trace Agent", prompt="Read your full instructions from agents/debugger-agent.md (relative to this SKILL.md file). Investigation dimension: stack-trace. ...", subagent_type="claude")
   Agent(description="Git Blame Agent", prompt="Read your full instructions from agents/debugger-agent.md (relative to this SKILL.md file). Investigation dimension: git-blame. ...", subagent_type="claude")
   Agent(description="Test Agent", prompt="Read your full instructions from agents/debugger-agent.md (relative to this SKILL.md file). Investigation dimension: tests. ...", subagent_type="claude")
   Agent(description="Pattern Agent", prompt="Read your full instructions from agents/debugger-agent.md (relative to this SKILL.md file). Investigation dimension: patterns. ...", subagent_type="claude")
   Agent(description="Dependency Agent", prompt="Read your full instructions from agents/debugger-agent.md (relative to this SKILL.md file). Investigation dimension: dependencies. ...", subagent_type="claude")
   ```
2. Immediately above that block, update the intro line "Dispatch 5 debugger-agent instances in a single message for parallel execution:" to append: "Each instance reads its role, tool grants, and constraints from `agents/debugger-agent.md` (relative to this SKILL.md file) and dispatches with `subagent_type: \"claude\"` — the runtime does not enforce the file's frontmatter `tools` restriction under this pattern (see spec's Known Limitations)."
3. Verify: `grep -n 'subagent_type="debugger-agent"' skills/debug/reference/debug-flow.md` returns zero matches.
4. Commit: `fix(skills): convert debug parallel dispatch to path-read pattern`

---

### Task 6: Convert refactor SKILL.md named subagent dispatch to path-read pattern

**Files:**
- Modify: `skills/refactor/SKILL.md`

**Interfaces:**
- Consumes: Phase 1 Task 6 Produces (`skills/refactor/agents/refactor-agent.md` exists)
- Produces: 4 corrected `Agent()` calls using `subagent_type: "claude"`, consumed by Phase 4 Task 1's `grep -r "subagent_type.*-agent" skills/` verification

**Acceptance Criteria:** Spec checkbox "Named `subagent_type` dispatches in `debug` and `refactor` converted to path-read + `subagent_type: \"claude\"` pattern" (refactor subset).

**Steps:**
1. In `skills/refactor/SKILL.md`'s "Parallel Mode (`--parallel`)" section, replace:
   ```
   Agent(description="Metrics Agent", prompt="...", subagent_type="refactor-agent")
   Agent(description="Dependency Agent", prompt="...", subagent_type="refactor-agent")
   Agent(description="Test Agent", prompt="...", subagent_type="refactor-agent")
   Agent(description="Pattern Agent", prompt="...", subagent_type="refactor-agent")
   ```
   with:
   ```
   Agent(description="Metrics Agent", prompt="Read your full instructions from agents/refactor-agent.md (relative to this SKILL.md file). Investigation dimension: metrics. ...", subagent_type="claude")
   Agent(description="Dependency Agent", prompt="Read your full instructions from agents/refactor-agent.md (relative to this SKILL.md file). Investigation dimension: dependencies. ...", subagent_type="claude")
   Agent(description="Test Agent", prompt="Read your full instructions from agents/refactor-agent.md (relative to this SKILL.md file). Investigation dimension: tests. ...", subagent_type="claude")
   Agent(description="Pattern Agent", prompt="Read your full instructions from agents/refactor-agent.md (relative to this SKILL.md file). Investigation dimension: patterns. ...", subagent_type="claude")
   ```
2. Immediately above that block, update "Dispatch all 4 agents in a single message for parallel execution:" to append: "Each instance reads its role, tool grants, and constraints from `agents/refactor-agent.md` (relative to this SKILL.md file) and dispatches with `subagent_type: \"claude\"` — the runtime does not enforce the file's frontmatter `tools` restriction under this pattern (see spec's Known Limitations)."
3. Verify: `grep -n 'subagent_type="refactor-agent"' skills/refactor/SKILL.md` returns zero matches.
4. Commit: `fix(skills): convert refactor parallel dispatch to path-read pattern`

---

### Task 7: Fix implement SKILL.md reference table paths

**Files:**
- Modify: `skills/implement/SKILL.md`

**Interfaces:**
- Consumes: Phase 1 Task 4 Produces (`skills/implement/agents/{implementer,task-reviewer,security-reviewer}-agent.md` exist)
- Produces: corrected Reference Documents table, consumed by Phase 4 Task 1's `grep -r "../../agents/" skills/` verification

**Acceptance Criteria:** Spec checkbox "`skills/implement/SKILL.md` Reference Documents table paths updated from `../../agents/*.md` to `agents/*.md`".

**Steps:**
1. In `skills/implement/SKILL.md`'s "Reference Documents" table, replace:
   ```
   | `../../agents/implementer-agent.md` | Task implementer agent (TDD, normal + fix mode) |
   | `../../agents/task-reviewer-agent.md` | Task reviewer agent (spec compliance, code quality) |
   | `../../agents/security-reviewer-agent.md` | Security reviewer agent (9 OWASP categories) |
   ```
   with:
   ```
   | `agents/implementer-agent.md` | Task implementer agent (TDD, normal + fix mode) |
   | `agents/task-reviewer-agent.md` | Task reviewer agent (spec compliance, code quality) |
   | `agents/security-reviewer-agent.md` | Security reviewer agent (9 OWASP categories) |
   ```
2. Verify: `grep -n "\.\./\.\./agents/" skills/implement/SKILL.md` returns zero matches.
3. Commit: `fix(skills): use skill-relative agent paths in implement reference table`

---

### Task 8: Add skill-relative agent pointers to implement-flow.md dispatch sections

**Files:**
- Modify: `skills/implement/reference/implement-flow.md`

**Interfaces:**
- Consumes: Phase 1 Task 4 Produces (`skills/implement/agents/{implementer,task-reviewer,security-reviewer}-agent.md` exist)
- Produces: explicit agent-file pointers in Sections 7, 10, and 11, consumed by Phase 4 Task 1 verification (dangling-reference scan)

**Acceptance Criteria:** Spec checkbox "`skills/implement/reference/implement-flow.md` | Update dispatch instructions to use skill-relative agent paths" (File Changes table). `implement-flow.md` embeds each agent's full prompt inline in Section 15 rather than reading the agent `.md` at dispatch time (confirmed: zero `agents/` references exist in the file today); this task adds the skill-relative pointer to each agent's role/tool-grant definition so the doc is self-consistent with the other 5 skills' explicit path-read pattern.

**Steps:**
1. In Section 7 ("Implementer Dispatch & Post-Verification"), immediately under the `### Implementer Dispatch` heading (before the `Record pre-task commit...` line), add: "Agent role, tool grants, and constraints are documented in `agents/implementer-agent.md` (relative to this skill's SKILL.md); the prompt sent to the agent is the template in Section 15.1 (or 15.2 for fix mode)."
2. In Section 10 ("Task Review"), immediately under the `### Decision Tree` heading (before the `Dispatch task-reviewer-agent with:` line), add: "Agent role, tool grants, and constraints are documented in `agents/task-reviewer-agent.md` (relative to this skill's SKILL.md); the prompt sent to the agent is the template in Section 15.3."
3. In Section 11 ("Security Review & Trigger Detection"), immediately under the `### Decision Tree` heading (before the `Check task's modified files against trigger patterns:` line), add: "Agent role, tool grants, and constraints are documented in `agents/security-reviewer-agent.md` (relative to this skill's SKILL.md); the prompt sent to the agent is the template in Section 15.4."
4. Verify: `grep -n "agents/implementer-agent.md\|agents/task-reviewer-agent.md\|agents/security-reviewer-agent.md" skills/implement/reference/implement-flow.md` returns three matches, one per file.
5. Commit: `docs(implement): point dispatch sections at skill-relative agent files`

## Phase 2 Complete

Every skill now dispatches its agents through one idiom: read `agents/<name>.md` relative to the dispatching `SKILL.md`, then dispatch with `subagent_type: "claude"`. No file references the deleted top-level `agents/` directory or a named non-`claude` `subagent_type`. Documentation updates (Phase 3) and final verification (Phase 4) remain.

**Next:** `phase-3.md`
