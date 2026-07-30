---
name: project
description: "Manage project structure, docs, and config. Flags: --init (initialize/health-check), --add-repo (add repo to multi-repo project), --refresh (refresh all docs)."
argument-hint: "--init | --add-repo | --refresh"
---

EXECUTE IMMEDIATELY — invoke the project skill.

## Argument Parsing

Extract from $ARGUMENTS:

- `--init` — Initialize project (first run) or run health check (subsequent runs)
- `--add-repo` — Add a new repository to a multi-repo project
- `--refresh` — Manually refresh all documentation
- No flag — Show usage help

## Execution

1. Invoke the `project` skill via the Skill tool
2. Pass the parsed flag to guide behavior
3. The skill handles auto-init guard, dispatch, and reporting
