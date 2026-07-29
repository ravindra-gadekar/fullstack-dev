---
name: plan
description: "Convert a design spec into a multi-phase implementation plan. Uses code-review-graph for accurate file paths. Produces plans in docs/plans/."
argument-hint: "[--auto] [--parallel] [<spec-path>]"
---

EXECUTE IMMEDIATELY — invoke the plan skill.

## Argument Parsing

Extract from $ARGUMENTS:

- `--auto` — Auto-approve file reads/writes/commits. No permission prompts for file operations.
  Spec selection, phase approval, and plan review remain interactive.
- `--parallel` — Dispatch parallel research agents for codebase analysis
  instead of inline graph/file scanning.
- Everything else — the spec file path (optional). If not provided, auto-detects unplanned specs.

## Execution

1. Parse `$ARGUMENTS` to separate the spec path from flags
2. Invoke the `plan` skill via the Skill tool
3. Pass the spec path and flags to guide behavior
