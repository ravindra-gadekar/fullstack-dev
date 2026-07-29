---
name: implement
description: "Execute implementation plans produced by /plan. Auto smoke testing, auto security testing, 3-tier auto-fix. Built-in resume and progress tracking."
argument-hint: "[--auto] [--status] [plan-path]"
---

EXECUTE IMMEDIATELY — invoke the implement skill.

## Argument Parsing

Extract from $ARGUMENTS:

- `--auto` — Auto-approve file reads/writes/commits and phase transitions. Blocked task decisions remain interactive.
- `--status` — Show progress dashboard for the specified plan (or all plans). Does not execute.
- `--parallel` — Silently accepted (always-on for /implement). Pre-task research agents always dispatch automatically.
- Everything else — the plan path (folder path or specific phase file path).

## Execution

1. Parse `$ARGUMENTS` to separate the plan path from flags
2. Invoke the `implement` skill via the Skill tool
3. Pass the plan path, `--auto` flag (if present), and `--status` flag (if present) to guide behavior
