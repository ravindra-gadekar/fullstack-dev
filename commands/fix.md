---
name: fix
description: "Apply a known fix directly with verification. Use when you know exactly what's wrong."
argument-hint: "[--auto] [--verbose] <what to change>"
---

EXECUTE IMMEDIATELY — invoke the fix skill.

## Argument Parsing

Extract from $ARGUMENTS:

- `--auto` — Auto-approve file reads/writes/commits. No permission prompts for file operations.
- `--verbose` — Show detailed progress and verification output.
- Everything else — the fix directive (what to change, where, why).

## Execution

1. Parse `$ARGUMENTS` to separate the fix directive from flags
2. Invoke the `fix` skill via the Skill tool
3. Pass the parsed flags and fix directive to the skill
