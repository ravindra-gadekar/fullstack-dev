---
name: git
description: "Git workflow management — setup local-dev, sync with target branch, check status, publish changes."
argument-hint: "<setup|sync|status|publish> [--all] [repo-name]"
---

EXECUTE IMMEDIATELY — invoke the git skill.

## Argument Parsing

Extract from $ARGUMENTS:

- First positional arg — subcommand: `setup`, `sync`, `status`, `publish`
- `--all` — Apply operation to all repos in a multi-repo project.
- Remaining positional arg — optional repo name to target a specific repo.

## Execution

```
$ARGUMENTS parsed?
+-- No arguments → Show help:
|   /git setup [--all] [repo]   Create local-dev branch for repo(s)
|   /git sync [--all] [repo]    Pull latest from target branch into local-dev
|   /git status [--all] [repo]  Show branch state, changes, ahead/behind
|   /git publish [repo]         Push changes and create PR
+-- Valid subcommand → Invoke git skill via Skill tool
+-- Invalid subcommand → Error:
    "Unknown subcommand '<cmd>'. Available: setup, sync, status, publish."
```

1. Parse `$ARGUMENTS` to extract subcommand, flags, and repo name
2. Invoke the `git` skill via the Skill tool
3. Pass the parsed subcommand, flags, and repo name to the skill
