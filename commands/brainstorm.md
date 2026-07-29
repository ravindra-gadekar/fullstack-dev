---
name: brainstorm
description: "Brainstorm a feature into a design spec. Explores context, asks questions, proposes approaches, writes spec. Use before building anything."
argument-hint: "<feature description> [--auto]"
---

EXECUTE IMMEDIATELY — invoke the brainstorm skill.

## Argument Parsing

Extract from $ARGUMENTS:

- `--auto` — Auto-approve file reads/writes/commits. No permission prompts for file operations.
- `--parallel` — Silently ignored (parallel research is always-on). Kept for backward compatibility.
- Everything else — the feature description to brainstorm.

## Execution

1. Parse `$ARGUMENTS` to separate the feature description from flags
2. Invoke the `brainstorm` skill via the Skill tool
3. Pass the feature description and `--auto` flag (if present) to guide behavior
