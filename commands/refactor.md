---
name: refactor
description: "Refactor code with graph-powered discovery, atomic changes, and before/after metrics."
argument-hint: "[--auto] [--parallel] [--verbose] [--scope <path>] [<target> [-- <reason>]]"
---

EXECUTE IMMEDIATELY — invoke the refactor skill.

## Argument Parsing

Extract from $ARGUMENTS:

- `--auto` — Auto-approve file reads/writes/commits. No permission prompts.
  Still requires user approval on the refactoring plan (Step 4).
  Discovery prompts auto-resolve: default to discovery mode, auto-select top 3 above threshold.
- `--parallel` — Spawn parallel refactor-agent instances during analysis (4 agents: metrics, dependencies, tests, patterns).
- `--verbose` — Show rich structured progress: graph analysis results, scoring breakdowns, metrics calculations, full test output, git diffs.
- `--scope <path>` — Limit discovery to specific directories. Only applies to discovery mode. If provided with a target path, warn and proceed with targeted mode.
- Everything else — target path and optional reason (after `--`).

## Execution

1. Parse `$ARGUMENTS` to separate flags from target/reason
2. Invoke the `refactor` skill via the Skill tool
3. Pass the parsed flags, target path, and reason to the skill
