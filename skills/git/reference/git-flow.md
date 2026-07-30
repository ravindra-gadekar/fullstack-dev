# Git Workflow Flow Reference

Decision trees, conventions, and rules for the git workflow system.

---

## 1. CI/CD Auto-Detection

Detect the target branch from CI/CD configuration files.

### Files to Scan

| File Pattern | Platform |
|-------------|----------|
| `.github/workflows/*.yml` | GitHub Actions |
| `.gitlab-ci.yml` | GitLab CI |
| `Jenkinsfile` | Jenkins |
| `.circleci/config.yml` | CircleCI |
| `bitbucket-pipelines.yml` | Bitbucket Pipelines |

### GitHub Actions Parsing

Parse only top-level trigger keys:

```
on:
  push:
    branches: [main, develop]      # extract these
  pull_request:
    branches: [main]               # extract these
```

Extract only **literal branch names**. Ignore:
- Glob patterns (`release/**`)
- Negations (`!main`)
- Matrix strategies
- Nested/reusable workflow triggers

If YAML parsing fails or returns no literal branches, fall back to asking the user.

### Result Decision Tree

```
CI/CD config files found?
+-- Yes → Parse branch names
|   +-- One branch found → Auto-set as target branch
|   +-- Multiple branches found → AskUserQuestion with list of branches
|   +-- No literal branches extracted → AskUserQuestion with open input
+-- No CI/CD files found → AskUserQuestion with open input
```

---

## 2. Conventional Commits Reference

Format: `<type>(<scope>): <short summary>`

### Type Mapping by Command

| Command | Default Type | Notes |
|---------|-------------|-------|
| `/implement` | `feat` | Can be `fix`, `refactor`, `test` based on task content |
| `/fix` | `fix` | Always `fix` |
| `/debug` | `fix` | The fix dispatched from debug |
| `/refactor` | `refactor` | Always `refactor` |
| `/brainstorm` | `docs` | Spec documents |
| `/plan` | `docs` | Plan documents |
| `/project --init` | `chore` | Project setup |

### Scope Derivation

| Condition | Scope |
|-----------|-------|
| Single file changed | Filename without extension |
| Single directory changed | Directory name |
| Multiple areas changed | Most significant area, or omitted |

### Short Summary Rules

- Lowercase first letter
- No trailing period
- Imperative mood ("add", not "added" or "adds")
- Max 72 characters

### Body Rules

- Explain **what** changed and **why**
- Reference ticket ID if available
- `/implement` includes phase/task context in body only (not in summary)

### Examples

```
feat(auth): add token refresh endpoint

Implement automatic JWT token refresh when access token expires.
Refresh tokens are stored in httpOnly cookies with 7-day expiry.
The middleware checks expiry before each authenticated request.

Resolves PROJ-123
```

```
refactor(services): extract validation into separate module

authService.ts had mixed responsibilities — authentication logic
and input validation in the same file (342 LOC). Extracted all
validation functions into services/auth-validation.ts.
```

```
docs(specs): add user dashboard design spec

Design spec covering layout, data widgets, filtering, and
real-time updates for the user dashboard feature.
```

---

## 3. Branch Naming Rules

Format: `<type>/<ticket-id?>-<kebab-case-name>`

### Type Mapping

| Type | When |
|------|------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring |
| `docs` | Documentation |
| `chore` | Maintenance, setup |
| `test` | Test-only changes |

### Ticket ID Detection

```
Ticket ID source?
+-- GitHub issue linked → Use issue number
|   Example: feat/42-add-auth
+-- External tracker pattern in commits → Extract ID
|   Example: feat/PROJ-123-add-auth
+-- No ticket found → Omit ID
    Example: feat/add-auth
```

### Name Derivation

- Auto-derived from commit summary or PR title
- Kebab-case (lowercase, hyphens)
- Max 50 characters total (type + slash + id + name)

---

## 4. Git Guard Decision Tree

The git guard wraps commands to ensure a clean git state.

### Commands That Get This Guard

`/implement`, `/fix`, `/debug`, `/refactor`, `/brainstorm`, `/plan`

### Commands That Do NOT Get This Guard

`/git` — it IS the git tool.

### 6-Step Decision Tree

```
Step 1: Check config
  .fullstack-dev/config.json has gitWorkflow config?
  +-- Not configured → Offer /project --init or /git setup → EXIT
  +-- Configured → Continue

Step 2: Check current branch
  Current branch?
  +-- local-dev → Proceed to Step 3
  +-- Another branch → Ask user to switch to local-dev → EXIT
  +-- Detached HEAD → Ask user to switch to local-dev → EXIT

Step 3: Check orphaned stashes
  git stash list | grep "pre-.*-stash"
  +-- Found → Offer pop / drop / ignore
  +-- Not found → Continue

Step 4: Universal stash
  git stash push -u -m "pre-<command>-stash"
  Record: stash_created = true/false

Step 5: Command executes...

Step 6: Universal stash pop (ALL exit paths)
  +-- stash_created == true → git stash pop
  +-- stash_created == false → Skip
```

### Stash Ownership

The guard owns ALL stash/pop operations. Commands that previously had
their own stash logic must remove it — the guard handles stashing
universally.

---

## 5. Setup Flow

### When `local-dev` Gets Created

- During `/project --init`
- During `/project --add-repo`
- Via `/git setup`
- Git guard detects missing config and offers `/git setup`

### Setup Flow Per Repo (5 Steps)

```
Step 1: Detect target branch
  Run CI/CD auto-detection (Section 1)
  +-- Branch detected → Use it
  +-- Not detected → Ask user

Step 2: Check if local-dev exists
  git branch --list local-dev
  +-- Exists with unpushed commits → Warn user with options:
  |   - Keep and continue
  |   - Reset to target branch (loses commits)
  |   - Abort setup
  +-- Exists clean → Skip creation
  +-- Does not exist → Continue to Step 3

Step 3: Create local-dev
  git checkout <target>
  git pull origin <target>
  git checkout -b local-dev

Step 4: Store config
  Write repos[i].targetBranch in .fullstack-dev/config.json

Step 5: Educate user (first time only)
  Explain:
  - Why local-dev exists (isolation from target branch)
  - All work happens on local-dev
  - Never push local-dev directly
  - Use /git publish to create remote branches and PRs
  - Use /git sync to pull latest from target
```

---

## 6. Sync Strategies

### 5-Step Sync Flow

```
Step 1: Check uncommitted changes
  git status --porcelain
  +-- Changes found → git stash push -u -m "pre-sync-stash"
  +-- Clean → Continue

Step 2: Fetch
  git fetch origin

Step 3: Determine strategy
  Unpushed commits on local-dev?
  +-- No unpushed commits → git rebase origin/<target>
  +-- Unpushed commits exist → git rebase origin/<target>
  |   +-- Rebase succeeds → Continue
  |   +-- Rebase conflicts → git rebase --abort
  |       +-- Fall back to merge: git merge origin/<target>
  |           +-- Merge succeeds → Continue
  |           +-- Merge conflicts → Inform user, EXIT

Step 4: Pop stash
  +-- Stash was created → git stash pop
  |   +-- Stash pop succeeds → Continue
  |   +-- Stash conflicts → Inform user, keep stash intact
  +-- No stash → Skip

Step 5: Report result
  Show: strategy used, commits pulled, current state
```

### Multi-Repo Sync

| Input | Behavior |
|-------|----------|
| No args | Sync all configured repos |
| Specific repo | Sync that one repo only |

### Auto-Sync Suggestion

When the git guard detects `local-dev` is behind the target branch,
suggest `/git sync` to the user before proceeding.

---

## 7. Publish Flow

### 11-Step Publish Flow

```
Step 1: Collect commits
  git log origin/<target>..local-dev --oneline
  +-- No commits ahead → Nothing to publish, EXIT

Step 2: Determine type
  Analyze commit types (feat, fix, refactor, etc.)
  +-- All same type → Use that type
  +-- Most frequent type dominates → Use most frequent
  +-- Mixed with no clear winner → Ask user

Step 3: Check for ticket ID
  Scan commit messages for ticket references
  (GitHub issue numbers, PROJ-123 patterns)

Step 4: Generate branch name
  Apply Section 3 rules: <type>/<ticket-id?>-<kebab-case-name>

Step 5: Confirm with user
  Show: branch name, commits to publish, target branch
  +-- User confirms → Continue
  +-- User modifies → Use modified name

Step 6: Push
  git push origin local-dev:<branch-name>

Step 7: Auto-generate PR content
  - Title: from branch name or primary commit
  - Body: list of commits, description of changes
  - Labels: based on type (feat → enhancement, fix → bug, etc.)

Step 8: Create PR
  mcp__github__create_pull_request
  Base: <target>, Head: <branch-name>

Step 9: Report PR link
  Show URL to user

Step 10: Stay on local-dev
  Do NOT switch branches. User continues working on local-dev.

Step 11: Suggest next steps
  Suggest /git sync after the PR is merged
```

### Post-Publish Options

Offer to reset `local-dev` to match target:

```
git reset --hard origin/<target>
```

This clears published commits from local-dev so it stays clean.

### Remote Branch Deletion

NEVER delete remote branches unless the user explicitly requests it.

---

## 8. Temporary Branch Operations

### 3-Step Pattern

```
Step 1: Before leaving local-dev
  Stash uncommitted changes + record state

Step 2: Perform operation
  Execute on other branch (checkout, bisect, cherry-pick, etc.)

Step 3: Return to local-dev
  git checkout local-dev
  Pop stash if created
  Inform user of what happened
```

### When This Happens

| Trigger | Operation |
|---------|-----------|
| User asks to check another branch | Checkout + return |
| `/debug` bisect | Bisect across commits + return |
| `/git sync` fetch | Fetch from remote (no branch switch needed) |
| Cherry-pick request | Checkout target, cherry-pick, return |

---

## 9. Dynamic CLAUDE.md Template

### Single-Repo Format

```markdown
## Git Workflow

1. Work on `local-dev` branch — never commit directly to `<targetBranch>`
2. Commit using Conventional Commits: `<type>(<scope>): <summary>`
3. When pushing: `git push origin local-dev:<type>/<name>`
4. Create PR targeting `<targetBranch>` using MCP tools
5. Never push `local-dev` to remote
6. Never create local feature/fix branches
7. Use `/git sync` to pull latest from `<targetBranch>`
```

### Multi-Repo Table Format

```markdown
### Per-Repo Target Branches

| Repo | Target Branch |
|------|--------------|
| <repo.name> | <repo.targetBranch> |

Push and PR commands automatically target the correct branch per repo.
```

### When Regenerated

- `/project --init`
- `/git setup`
- Config change to target branches
