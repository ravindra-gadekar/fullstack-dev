---
name: gitignore
description: "Auto-manage .gitignore — scan for violations, rebuild from tech stack, cleanup tracked files that should be ignored."
argument-hint: "<scan|rebuild|cleanup> [--all] [--dry-run] [repo-name]"
---

EXECUTE IMMEDIATELY — invoke the gitignore skill.

## Argument Parsing

Extract from $ARGUMENTS:

- First positional arg — subcommand: `scan`, `rebuild`, or `cleanup`
- `--all` — Apply operation to all repos in a multi-repo project.
- `--dry-run` — Preview changes without applying them (cleanup subcommand).
- Remaining positional arg — optional repo name to target a specific repo.

## Execution

```
$ARGUMENTS parsed?
+-- No arguments → Show help:
|   /gitignore scan [--all] [repo]              Check for tracked files that should be ignored
|   /gitignore rebuild [--all] [repo]           Regenerate .gitignore from detected tech stack
|   /gitignore cleanup [--all] [--dry-run] [repo]  Remove tracked files that match .gitignore
+-- Valid subcommand → Invoke gitignore skill via Skill tool
+-- Invalid subcommand → Error:
    "Unknown subcommand '<cmd>'. Available: scan, rebuild, cleanup."
```

1. Parse `$ARGUMENTS` to extract subcommand, flags, and repo name
2. Invoke the `gitignore` skill via the Skill tool
3. Pass the parsed subcommand, flags, and repo name to the skill
