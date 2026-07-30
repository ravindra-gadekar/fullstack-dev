# Init Flow Reference

Complete decision tree and wizard for `/project --init`. The init-agent
presents these questions verbatim, collects answers, then generates all
project files in a single pass.

---

## 1. First-Run Detection

On every `/project --init` invocation, run this decision tree before
anything else.

### 1.1 Config exists?

Check for `.fullstack-dev/config.json` in the working directory.

    config.json exists?
    +-- YES --> Subsequent Run (Section 8: Health Check)
    +-- NO  --> First Run (continue to 1.2)

### 1.2 Directory state

    Is the working directory empty (no files besides .git)?
    +-- YES --> Fresh project. Continue to Section 2 (Wizard).
    +-- NO  --> Existing project. Continue to 1.3.

### 1.3 Git detection

Scan the working directory for `.git/` directories (recursive, depth 1
for immediate children, plus the root itself).

    .git/ directories found?
    |
    +-- Multiple .git/ dirs (children have .git/)
    |   --> Multi-repo detected.
    |       Set `repoStructure = "multi-repo"` (pre-fill Step 3).
    |       Catalog each child directory containing .git/ as a sub-repo.
    |       Continue to Section 2 (Wizard), skip Step 3.
    |
    +-- One .git/ at root only
    |   --> Mono-repo detected.
    |       Set `repoStructure = "mono-repo"` (pre-fill Step 3).
    |       Continue to Section 2 (Wizard), skip Step 3.
    |
    +-- No .git/ anywhere
        --> Print:
            "This directory has no git repository. Please initialize
             git first:  git init"
            STOP. Do not proceed with the wizard.

---

## 2. Wizard — Step 1: Project Basics

Present exactly:

```
? Project name: _______________
? One-line description: _______________
```

**Validation:**
- Project name: required, no empty string. Used as display name and to
  derive the workspace filename (kebab-case).
- Description: required, one sentence. Stored in config and used in
  generated docs.

**Store:**
- `projectName` (string)
- `projectDescription` (string)

---

## 3. Wizard — Step 2: Project Type

Present exactly:

```
? What kind of project is this?
  * Full-stack web app (frontend + backend)
  * API / backend service only
  * Frontend only (SPA, marketing site, dashboard)
  * CLI tool / library / package
  * Microservices (multiple backend services)
```

**Store:**
- `projectType` (enum: `fullstack` | `api` | `frontend` | `cli` | `microservices`)

**Branching:**
- `fullstack` or `microservices` --> continue to Step 3 (Repo Structure)
- `api`, `frontend`, or `cli` --> skip Step 3, go to Step 4 (Technologies)
  - For these types, set `repoStructure = "mono-repo"` automatically.

---

## 4. Wizard — Step 3: Repo Structure

Only shown when `projectType` is `fullstack` or `microservices`, AND the
structure was not already auto-detected in Section 1.3.

Present exactly:

```
? How do you want to organize the code?
  * Mono-repo (everything in one repo)
  * Multi-repo (separate repos for frontend, backend, etc.)
```

**Store:**
- `repoStructure` (enum: `mono-repo` | `multi-repo`)

**Branching:**
- `mono-repo` --> skip 3a and 3b, go to Step 4
- `multi-repo` --> continue to Step 3a

### 4.1 Step 3a: Existing Repos (multi-repo only)

Present exactly:

```
? Do you have existing repos to clone into this project?
  * Yes -- I'll provide repo URLs
  * No -- I'll add repos later
```

**If "Yes":**

Prompt for repo URLs one at a time:

```
? Repo URL (or blank to finish): _______________
```

Repeat until the user enters a blank line. For each URL provided:
- Extract the repo name from the URL (last path segment, minus `.git`).
- Store in the repos list with `source: "clone"` and `url: <provided>`.

**If "No":**

Store an empty repos list. The user will use `/project --add-repo` later.

**Store:**
- `repos` (array of `{ name, url, source }`)

### 4.2 Step 3b: Meta-Repo Remote (multi-repo only)

Present exactly:

```
? How do you want to track project-level files?
  * Local + Remote (Recommended) -- push to GitHub for backup and team
  * Local only -- git tracking, no remote
```

**If "Local + Remote":**

```
? Remote URL for project-level repo: _______________
```

Store the remote URL. During configuration phase, add it as `origin`.

**If "Local only":**

No further input needed. The root directory is git-tracked locally but
has no remote.

**Store:**
- `metaRepo.mode` (enum: `local-remote` | `local-only`)
- `metaRepo.remoteUrl` (string, only if `local-remote`)

---

## 5. Wizard — Step 4: Technologies

Free-text, comma-separated inputs. Present exactly:

```
? Backend language/framework? > _______________
? Frontend framework? > _______________
? Database(s)? > _______________
? Any other technologies? > _______________
```

**Conditional display:**
- If `projectType` is `frontend` --> skip "Backend language/framework?"
- If `projectType` is `api` or `cli` --> skip "Frontend framework?"
- Always show "Database(s)?" and "Any other technologies?"

**Parsing:**
Split each answer on commas, trim whitespace, lowercase for matching,
preserve original casing for display. Empty answers are allowed (user
presses Enter to skip).

**Store:**
- `technologies.backend` (string[])
- `technologies.frontend` (string[])
- `technologies.databases` (string[])
- `technologies.other` (string[])

---

## 6. Wizard — Step 5: AI Integration

Present exactly:

```
? Will this project use AI/LLM features?
  * Yes -- Claude (Anthropic)
  * Yes -- OpenAI
  * Yes -- multiple providers
  * No / not yet
```

**Store:**
- `aiIntegration` (enum: `claude` | `openai` | `multiple` | `none`)

This informs CONTEXT.md generation and may affect future skill
recommendations.

---

## 7. Wizard — Step 6: Team Size

Present exactly:

```
? Who's working on this?
  * Solo developer
  * Small team (2-5)
  * Larger team (6+)
```

**Store:**
- `teamSize` (enum: `solo` | `small` | `large`)

This influences:
- Git workflow recommendations in CONTEXT.md
- Whether collaboration-oriented MCP tools are emphasized

---

## 8. Wizard — Step 7: Configuration (No Questions)

No more questions. Print:

```
Generating project configuration...
```

Then execute the Configuration Phase (Section 9) in full.

---

## 9. Configuration Phase

After the wizard completes, generate all files in this exact order.
Each subsection describes what to create and where.

### 9.1 `.fullstack-dev/config.json`

Create at workspace root. This is the plugin's state file.

```json
{
  "version": "1.0.0",
  "projectName": "<projectName>",
  "projectDescription": "<projectDescription>",
  "projectType": "<projectType>",
  "repoStructure": "<repoStructure>",
  "metaRepo": {
    "mode": "<metaRepo.mode>",
    "remoteUrl": "<metaRepo.remoteUrl or null>"
  },
  "repos": [
    {
      "name": "<repo-name>",
      "path": "<relative-path>",
      "url": "<clone-url or null>",
      "source": "clone | existing | created",
      "targetBranch": ""
    }
  ],
  "technologies": {
    "backend": [],
    "frontend": [],
    "databases": [],
    "other": []
  },
  "gitWorkflow": {
    "localBranch": "local-dev",
    "commitConvention": "conventional",
    "branchNaming": "<type>/<ticket?>-<name>",
    "deleteRemoteBranches": false
  },
  "aiIntegration": "<aiIntegration>",
  "teamSize": "<teamSize>",
  "createdAt": "<ISO 8601 timestamp>",
  "updatedAt": "<ISO 8601 timestamp>"
}
```

### 9.1a Target Branch Detection (per repo)

For each repo in the config, detect the CI/CD target branch:

1. Run CI/CD auto-detection per `skills/git-workflow/reference/git-workflow-flow.md` Section 1
2. Store detected/chosen branch as `repos[i].targetBranch` in config

This step runs BEFORE config is finalized so detection results feed into the config file.

### 9.2 `.gitignore`

Create or update at workspace root. If the file already exists, append
the plugin marker block. If it does not exist, create it with the block.

The marker block format:

```gitignore
# >>> fullstack-dev (do not edit this block) >>>
<repo-name-1>/
<repo-name-2>/
# <<< fullstack-dev <<<
```

Each sub-repo directory is listed so the meta-repo does not track
sub-repo contents. Only applicable for multi-repo setups.

Never remove lines outside the marker block. On subsequent runs,
replace only the lines between the markers.

### 9.3 Documentation files

Generate these files using the wizard answers and any existing code
found in the repos:

| File | Location | When |
|------|----------|------|
| `CONTEXT.md` | Workspace root | Always |
| `docs/project/architecture.md` | Workspace root | Always |
| `docs/project/tech-stack.md` | Workspace root | Always |
| `docs/project/brand.md` | Workspace root | If `projectType` includes frontend (`fullstack` or `frontend`) |
| `ARCHITECTURE.md` | Each sub-repo root | For each repo that exists locally |

Also ensure these directories exist (create if missing):

- `docs/specs/`
- `docs/plans/`

### 9.3a `local-dev` Branch Setup (per repo)

For each repo that exists locally, create the `local-dev` branch:

1. Reference: `skills/git-workflow/reference/git-workflow-flow.md` Section 5 (Setup Flow)
2. For each repo:
   - `git -C <repo-path> checkout <targetBranch>`
   - `git -C <repo-path> pull origin <targetBranch>`
   - `git -C <repo-path> checkout -b local-dev`
3. Show education message (first-time setup — always shown during init):
   - Why local-dev exists (isolation from target branch)
   - All work happens on local-dev
   - Never push local-dev directly
   - Use `/git publish` to create remote branches and PRs
   - Use `/git sync` to pull latest from target

This step runs AFTER config is written (needs config to exist) but BEFORE CLAUDE.md generation (CLAUDE.md references the git workflow).

### 9.4 `CLAUDE.md`

Generate at workspace root. This file is fully auto-generated and safe
to overwrite on every run. It wires up:

- Project name, description, and type
- Repository structure and paths
- Build/dev commands per repo (detected or placeholder)
- Architecture reference lookup order (CONTEXT.md, ARCHITECTURE.md, then source)
- Git workflow (derived from `teamSize` and `repoStructure`)
- MCP tool usage instructions
- Documentation structure

### 9.5 `.mcp.json`

Create at workspace root with MCP server configuration.

Always include:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

Add git platform MCP based on auto-detection (Section 11):

- **GitHub**: Add `github` server entry
- **GitLab**: Add `gitlab` server entry
- **Bitbucket**: Add `bitbucket` server entry
- **Azure DevOps**: Add `azure-devops` server entry

If no platform detected, ask the user (Section 11) and configure
accordingly. If the user says "none / skip", only include context7.

### 9.6 Optional Developer Tools

After configuring MCP servers (context7, git platform), offer optional
developer tools that improve AI agent capabilities. Present the
following prompt:

```
? Optional developer tools (improve AI agent capabilities):

  code-review-graph — Structural codebase understanding (Recommended)
    Helps AI read your codebase faster and saves tokens.
    ○ Configure now (Recommended)
    ○ Skip

  Agentation — Visual UI feedback tool
    Click elements in your browser to report UI issues to the AI agent.
    (Only available for projects with a frontend)
    ○ Configure now
    ○ Skip
```

**Branching:**
- Agentation option is only shown when `projectType` includes frontend
  (`fullstack` or `frontend`).
- If "Configure now" for code-review-graph: follow
  `reference/tools-setup.md` Section "code-review-graph MCP
  Configuration" for `.mcp.json` entry AND hooks in
  `.claude/settings.json`.
- If "Configure now" for Agentation: follow `reference/tools-setup.md`
  Section "Agentation" for `.mcp.json` entry AND npm dev dependency.
- If "Skip" for either: no action, continue to next step.

**Store:**
- `optionalTools.codeReviewGraph` (boolean) -- whether code-review-graph
  was configured
- `optionalTools.agentation` (boolean) -- whether Agentation was
  configured

> **Note:** code-review-graph hooks should be merged alongside existing
> hooks per the Hooks Merge Note in `reference/tools-setup.md`.

### 9.7 `.claude/settings.json`

Create at workspace root:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "echo '>> Docs may be stale. If you changed exports, schemas, or domain concepts, update the relevant ARCHITECTURE.md and CONTEXT.md sections now.'"
          }
        ]
      }
    ]
  }
}
```

If the file already exists, merge the hooks — do not overwrite existing
user-configured hooks.

### 9.8 Pre-commit hook

Install a git pre-commit hook at `.git/hooks/pre-commit` (in the root
repo). The hook auto-stages documentation files that were already
modified, so they ship with the code commit:

```bash
#!/bin/sh
# fullstack-dev: auto-stage refreshed docs
for f in CONTEXT.md CLAUDE.md docs/project/architecture.md docs/project/tech-stack.md docs/project/brand.md; do
  if [ -f "$f" ] && git diff --name-only | grep -qx "$f"; then
    git add "$f"
  fi
done
# auto-stage per-repo ARCHITECTURE.md
for repo_arch in */ARCHITECTURE.md; do
  if [ -f "$repo_arch" ] && git diff --name-only | grep -qx "$repo_arch"; then
    git add "$repo_arch"
  fi
done
```

If a pre-commit hook already exists, append the plugin section inside
a marker block (same pattern as `.gitignore`).

### 9.9 `*.code-workspace` (multi-repo only)

Create `<project-name>.code-workspace` at workspace root:

```json
{
  "folders": [
    { "path": "." },
    { "path": "<repo-1>" },
    { "path": "<repo-2>" }
  ],
  "settings": {}
}
```

Only generated for multi-repo setups. The root folder (`.`) is always
first so project-level files are accessible.

### 9.10 Clone repos (multi-repo, if URLs provided)

For each repo in the repos list with `source: "clone"`:

```bash
git clone <url> <repo-name>
```

Clone into the workspace root. After cloning, generate the per-repo
`ARCHITECTURE.md` for each cloned repo.

### 9.11 Set meta-repo remote (if local-remote)

If `metaRepo.mode` is `local-remote`:

```bash
git remote add origin <metaRepo.remoteUrl>
```

If the root directory does not have git initialized, run `git init`
first.

### 9.12 Initial commit

Stage all generated files and create an initial commit:

```bash
git add -A
git commit -m "chore: initialize project with fullstack-dev"
```

If meta-repo has a remote, do NOT push automatically. Inform the user:

```
Ready. Run `git push -u origin main` when you want to push.
```

### 9.13 Completion report

Print a summary:

```
Project initialized successfully.

  Project:    <projectName>
  Type:       <projectType>
  Structure:  <repoStructure>
  Repos:      <count> repositories
  Platform:   <detected git platform or "none">

Files created:
  .fullstack-dev/config.json
  CONTEXT.md
  CLAUDE.md
  docs/project/architecture.md
  docs/project/tech-stack.md
  [docs/project/brand.md]          (if frontend)
  [<repo>/ARCHITECTURE.md]         (per repo)
  .mcp.json
  .claude/settings.json
  .gitignore
  [<project>.code-workspace]       (if multi-repo)

Next steps:
  - Review CONTEXT.md and fill in domain-specific sections
  - Run /project --add-repo to add more repositories
  - Run /project --refresh to regenerate docs after changes
```

---

## 10. Subsequent Runs: Health Check

When `.fullstack-dev/config.json` already exists, `/project --init`
runs a health check instead of the wizard.

### 10.1 Version check

Compare `config.json` version against the plugin version.

    config version < plugin version?
    +-- YES --> Run version migration (Section 12) first, then health check
    +-- NO  --> Continue to health check

### 10.2 Health check table

Run every check in this table. Report each as PASS or FAIL.

```
Category          | Check                                           | Auto-fix?
------------------+-------------------------------------------------+----------
Config            | .fullstack-dev/config.json exists and valid      | No
                  | Config version matches plugin version            | Yes (migrate)
Docs              | CONTEXT.md exists at root                        | Yes (regenerate)
                  | docs/project/architecture.md exists              | Yes (regenerate)
                  | docs/project/tech-stack.md exists                | Yes (regenerate)
                  | docs/project/brand.md exists (if frontend)       | Yes (regenerate)
                  | Per-repo ARCHITECTURE.md for each sub-repo       | Yes (regenerate)
                  | docs/specs/ directory exists                     | Yes (create)
                  | docs/plans/ directory exists                     | Yes (create)
Git               | Root has git initialized                         | No (warn)
                  | .gitignore exists with plugin marker block       | Yes (regenerate block)
                  | All sub-repos listed in .gitignore               | Yes (add missing)
                  | No new .git/ directories missing from config     | Yes (prompt to add)
                  | local-dev branch exists in each repo             | Yes (run /git setup)
                  | targetBranch set in each repo config entry       | Yes (run /git setup)
Claude Config     | .claude/settings.json exists                     | Yes (create)
                  | PostToolUse hooks configured                     | Yes (merge hooks)
                  | Skills installed                                 | Yes (report missing)
                  | Commands installed                               | Yes (report missing)
MCP               | .mcp.json exists                                 | Yes (create)
                  | context7 configured                              | Yes (add entry)
                  | Git platform MCP configured                      | Yes (add entry)
Developer Tools   | code-review-graph in .mcp.json                   | Yes (add entry)
                  | code-review-graph hooks in settings.json         | Yes (merge hooks)
                  | Agentation in .mcp.json (if frontend)            | Yes (add entry)
Workspace         | .code-workspace file exists (if multi-repo)      | Yes (create)
                  | All repos listed in workspace folders            | Yes (add missing)
```

### 10.3 Results

**All checks pass:**

```
Project is healthy. Nothing to do.
```

**Issues found:**

```
Health check complete. Found <N> issue(s):

  FAIL  CONTEXT.md exists at root
  FAIL  PostToolUse hooks configured
  FAIL  context7 configured

Fix now? (Y/n)
```

If the user confirms (or default yes):
- Apply all auto-fixable items
- Report what was fixed
- Report any items that require manual action

```
Fixed <N> issues:
  - Regenerated CONTEXT.md
  - Added PostToolUse hooks to .claude/settings.json
  - Added context7 to .mcp.json

Manual action required:
  - (none, or list items that cannot be auto-fixed)
```

---

## 11. Git Platform Auto-Detection

Run this during the configuration phase (Step 9.5) and during health
checks.

### 11.1 Detection logic

For each sub-repo (and the root repo), read git remotes:

```bash
git -C <repo-path> remote -v
```

Parse the remote URLs and match against known platforms:

| URL pattern           | Platform     | MCP server     |
|-----------------------|--------------|----------------|
| `github.com`          | GitHub       | `github`       |
| `bitbucket.org`       | Bitbucket    | `bitbucket`    |
| `gitlab.com`          | GitLab       | `gitlab`       |
| `dev.azure.com`       | Azure DevOps | `azure-devops` |

### 11.2 Multiple platforms

If different repos use different platforms, configure MCP servers for
all detected platforms.

### 11.3 No remotes detected

If no repos have remotes (or no repos exist yet), ask the user:

```
? Which git platform will you use?
  * GitHub
  * GitLab
  * Bitbucket
  * Azure DevOps
  * None / skip for now
```

Store the answer and configure MCP accordingly. "None / skip" means only
context7 is configured in `.mcp.json`.

---

## 12. Version Migration

When `config.json` version is older than the plugin version, run
migration before the health check.

### 12.1 Migration steps

1. **Update version field** in `config.json` to the current plugin version.

2. **Re-merge hooks** in `.claude/settings.json`:
   - Add any new hooks introduced in the newer version.
   - Preserve all existing user-configured hooks.
   - Never remove hooks that already exist.

3. **Regenerate CLAUDE.md**:
   - CLAUDE.md is fully auto-generated, so it is safe to overwrite.
   - Use current config values to regenerate.

4. **Add new health checks**:
   - If the newer plugin version introduces new checks, they are
     automatically included when the health check runs after migration.

5. **Update config schema**:
   - If new fields were added to `config.json` in the newer version,
     populate them with sensible defaults.

### 12.2 Migration report

```
Migrated from v<old> to v<new>.
  - Updated config.json version
  - Re-merged hooks in .claude/settings.json
  - Regenerated CLAUDE.md
  - Added <N> new config fields with defaults

Running health check...
```

Then proceed to the health check (Section 10.2).

---

## 13. Team Member Onboarding

When `config.json` already exists but some repos listed in it are not
present locally, this indicates a team member cloning the project for
the first time.

### 13.1 Detection

During health check, for each repo in `config.repos`:

    Does <repo.path> exist locally?
    +-- YES --> skip
    +-- NO  --> add to missing list

### 13.2 Clone offer

If missing repos are found:

```
Found <N> repo(s) listed in config but not cloned locally:

  - <repo-1> (<url>)
  - <repo-2> (<url>)

Clone now? (Y/n)
```

If the user confirms:
- Clone each missing repo using its stored URL.
- Generate per-repo `ARCHITECTURE.md` for each newly cloned repo.

If a repo has no URL stored (was added manually without a remote):

```
  - <repo-name> (no URL stored -- skip or provide URL)
? URL for <repo-name> (or blank to skip): _______________
```

### 13.3 Post-clone

After cloning, run the full health check (Section 10.2) to ensure
everything is properly configured.

```
All repos cloned. Running health check...
```

Report the final state:

```
Project ready.

  Repos cloned:   <count>
  Health issues:  <count> (auto-fixed <count>)
```

---

## 14. Decision Tree Summary

Complete flow in one view:

```
/project --init
|
+-- config.json exists?
    |
    +-- YES
    |   |
    |   +-- Config version < plugin version?
    |   |   +-- YES --> Migrate (Section 12) --> Health Check (Section 10)
    |   |   +-- NO  --> Health Check (Section 10)
    |   |
    |   +-- Missing repos?
    |       +-- YES --> Onboarding (Section 13) --> Health Check (Section 10)
    |       +-- NO  --> Health Check only (Section 10)
    |
    +-- NO
        |
        +-- .git/ found?
        |   +-- Multiple --> multi-repo detected, pre-fill Step 3
        |   +-- One at root --> mono-repo detected, pre-fill Step 3
        |   +-- None --> "Please init git first." STOP.
        |
        +-- Wizard
            |
            +-- Step 1: Project Basics (name, description)
            +-- Step 2: Project Type
            |   +-- fullstack / microservices --> Step 3
            |   +-- api / frontend / cli --> skip to Step 4
            +-- Step 3: Repo Structure (if not auto-detected)
            |   +-- mono-repo --> Step 4
            |   +-- multi-repo --> Step 3a, 3b --> Step 4
            +-- Step 4: Technologies (free text)
            +-- Step 5: AI Integration
            +-- Step 6: Team Size
            +-- Step 7: Configuration (auto-generate everything)
            |
            +-- Done. Print completion report.
```
