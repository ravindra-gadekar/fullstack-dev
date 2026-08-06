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
  "version": "1.1.0",
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

1. Run CI/CD auto-detection per `skills/git/reference/git-flow.md` Section 1
2. Store detected/chosen branch as `repos[i].targetBranch` in config

This step runs BEFORE config is finalized so detection results feed into the config file.

### 9.2 `.gitignore`

Create or update at workspace root. Generate comprehensive `.gitignore` from the pattern catalog based on the project's tech stack.

1. Read `skills/gitignore/reference/gitignore-catalog.md` for available patterns.
2. Determine active categories from detected tech stack (`repos[].stack` from config):
   - Always include: `universal`, `secrets`, `build`, `cache`, `ide`
   - Always include all OS categories: `macos`, `windows`, `linux`
   - Per-repo tech stack: map `repos[].stack` entries to catalog category keys
   - File detection fallback: check for marker files (`package.json` → node, `tsconfig.json` → typescript, etc.)
   - MCP tooling: read `.mcp.json` server entries, activate `mcp-tooling` if servers found
   - Deployment: check for config files (`vercel.json`, `serverless.yml`, etc.)
3. Generate marker block content grouped by category, sorted per catalog order:
   `universal → secrets → node → framework-specific → build → cache → ide → OS → mcp-tooling → deployment → sub-repositories`
4. For multi-repo: include sub-repo directories as `# Sub-repositories` category inside the block.
5. Write `.gitignore` following merge rules from `skills/gitignore/reference/gitignore-flow.md` Section 2:
   - No `.gitignore` exists → create with full marker block
   - `.gitignore` exists, no marker block → prepend marker block, preserve all existing content below
   - Marker block exists → replace everything between markers only
   - Old marker format detected → migrate per `gitignore-flow.md` Section 5
6. Store active categories in `config.json` `gitIgnore.activeCategories`.

The marker block format:

```gitignore
# >>> fullstack-dev:gitignore (do not edit this block) >>>

# Universal
node_modules/
*.log
...

# Sub-repositories
frontend-app/
backend-api/

# <<< fullstack-dev:gitignore <<<

# --- User entries below ---
```

Never remove lines outside the marker block. On subsequent runs, replace only the content between the markers.

See `skills/gitignore/reference/gitignore-catalog.md` for the full pattern catalog and `skills/gitignore/reference/gitignore-flow.md` for marker block format and merge rules.

### 9.2a Pre-commit gitignore hook

Install a gitignore enforcement hook at `.git/hooks/pre-commit`. This hook catches accidentally staged files that match essential ignore patterns before they enter the repository.

1. Read hook script template from `skills/gitignore/reference/gitignore-flow.md` Section 3.
2. Check if `.git/hooks/pre-commit` exists:
   - **File exists** — check for existing `fullstack-dev:gitignore` marker block:
     - Found → replace content within markers
     - Not found → append marker block (preserves existing hook content, including the `fullstack-dev` doc-staging block from Section 9.8)
   - **File does not exist** — create file with `#!/bin/sh` shebang + marker block
3. Ensure file is executable (`chmod +x` on Unix, warn on Windows).
4. Store `gitIgnore.hookInstalled: true` in `config.json`.

The hook uses its own marker block (`fullstack-dev:gitignore`) distinct from the doc-staging hook marker (`fullstack-dev`), so both coexist independently.

### 9.3 Documentation files

Generate these files using the wizard answers and any existing code
found in the repos:

| File | Location | When |
|------|----------|------|
| `CONTEXT.md` | Workspace root | Always |
| `docs/project/architecture.md` | Workspace root | Always |
| `docs/project/tech-stack.md` | Workspace root | Always |
| `BRAND.md` | Each sub-repo root that has a frontend | Per repo — generated when that repo's `type` is `frontend`, or (mono-repo) when `projectType` is `full-stack` or `frontend` |
| `ARCHITECTURE.md` | Each sub-repo root | For each repo that exists locally |

Also ensure these directories exist (create if missing):

- `docs/specs/`
- `docs/plans/`

### 9.3a `local-dev` Branch Setup (per repo)

For each repo that exists locally, create the `local-dev` branch:

1. Reference: `skills/git/reference/git-flow.md` Section 5 (Setup Flow)
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

### 9.5 MCP Setup

Create/merge `.mcp.json` at workspace root with MCP server configuration.

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

**code-review-graph (always-on):**

code-review-graph is configured automatically for every project — it is
no longer an opt-in prompt. Follow `reference/tools-setup.md` Section
"code-review-graph MCP Configuration" for exact content:

1. **Merge into `.mcp.json`:**

   ```json
   {"command":"uvx","args":["code-review-graph","mcp","--repo","."]}
   ```

2. **Merge hooks into `.claude/settings.json`:**
   - PostToolUse: `uvx code-review-graph update --skip-flows --repo .`
     (matcher: `Edit|Write|Bash|PowerShell`, timeout: 30000)
   - SessionStart: `uvx code-review-graph build --skip-flows --repo .`
     (timeout: 120000)
3. **Generate `.code-review-graphignore`:**
   - Read `repos[].stack` + `gitIgnore.activeCategories` from config
   - Filter to extras NOT covered by built-in defaults (per
     `reference/tools-setup.md` Section "`.code-review-graphignore`
     Configuration")
   - Write file with `fullstack-dev:code-review-graph` marker block
   - Data dependency: runs AFTER Section 9.2 `.gitignore` generation
4. **Run initial graph build:**
   - Execute: `uvx code-review-graph build --skip-flows --repo .`
   - This builds the graph immediately so it is ready to use without
     requiring a session restart
   - The SessionStart hook will rebuild it on subsequent sessions;
     the PostToolUse hook will keep it current during sessions
5. **Per-repo setup (multi-repo only):** each sub-repo has its own
   `.code-review-graph/` directory and its own graph, so each needs the
   same three steps individually. Skip this entirely for mono-repo
   projects — the root file/build above is already sufficient. For
   each repo in `config.json` `repos[]`:
   - **Generate `<repo>/.code-review-graphignore`** per
     `reference/tools-setup.md` Section "Per-Repo `.code-review-graphignore`
     (multi-repo only)": always include `node_modules/` and `dist/` as
     baseline, then add stack-derived entries from that repo's
     `repos[].stack`. Same managed-block pattern as the root file, with
     a `# --- User entries below ---` footer.
   - **Verify/add `.code-review-graph/` to that repo's own `.gitignore`**
     (not the root workspace `.gitignore`) — append the line if missing.
   - **Run a full graph build for that repo** using the MCP tool
     `build_or_update_graph_tool` with `full_rebuild: true` (not the CLI
     command), scoped to that repo's path. This runs last for that repo
     — after its `.code-review-graphignore` is written, so the build
     respects the exclusions from the first pass.

> **Note:** the code-review-graph PostToolUse hook (matcher
> `Edit|Write|Bash|PowerShell`) coexists alongside the fullstack-dev
> doc-staging PostToolUse hook (matcher `Edit|Write`) — see the Hooks
> Merge Note in `reference/tools-setup.md`.

### 9.6 Optional Tools

After MCP Setup (Section 9.5), offer remaining optional tools that
improve AI agent capabilities. Present the following prompt:

```
? Optional developer tools (improve AI agent capabilities):

  Agentation — Visual UI feedback tool
    Click elements in your browser to report UI issues to the AI agent.
    (Only available for projects with a frontend)
    ○ Configure now
    ○ Skip
```

**Branching:**
- This prompt is only shown when `projectType` includes frontend
  (`fullstack` or `frontend`).
- If "Configure now" for Agentation: follow `reference/tools-setup.md`
  Section "Agentation" for `.mcp.json` entry AND npm dev dependency.
- If "Skip": no action, continue to next step.

**Store:**
- `optionalTools.agentation` (boolean) -- whether Agentation was
  configured

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
            "command": "sh .fullstack-dev/refresh-hint.sh"
          }
        ]
      }
    ]
  }
}
```

The hook runs the targeted refresh-hint script (§9.7a) instead of a
generic echo. The script reads the changed file path from PostToolUse
JSON on stdin, matches it against the smart refresh rules from
`agents/refresh-agent.md`, and outputs a targeted reminder naming the
specific doc to update — or nothing if the file doesn't match any rule.

If the file already exists, merge the hooks — do not overwrite existing
user-configured hooks.

### 9.7a `.fullstack-dev/refresh-hint.sh`

Generate the targeted doc-refresh hint script. This script is the
executable behind the PostToolUse hook from §9.7. It replaces the old
bare `echo` approach with file-specific reminders.

```bash
#!/bin/sh
# fullstack-dev: targeted doc-refresh hint
# Reads PostToolUse JSON from stdin, matches the changed file against
# smart refresh rules (see skills/project/agents/refresh-agent.md),
# outputs a specific reminder or nothing.
INPUT=$(cat)
FILE=$(echo "$INPUT" | grep -o '"file_path" *: *"[^"]*"' | head -1 | sed 's/"file_path" *: *"//;s/"$//')
[ -z "$FILE" ] && exit 0

# Strip absolute prefix to get repo-relative path
CWD=$(pwd)
case "$FILE" in "$CWD"/*) FILE="${FILE#$CWD/}" ;; esac

# Detect repo context (multi-repo: first path component with its own .git/)
REPO=""
case "$FILE" in
  */*)
    DIR=$(echo "$FILE" | cut -d/ -f1)
    [ -d "$DIR/.git" ] && REPO="$DIR"
    ;;
esac
if [ -n "$REPO" ]; then
  BRAND="$REPO/BRAND.md"
  ARCH="$REPO/ARCHITECTURE.md"
else
  BRAND="BRAND.md"
  ARCH="ARCHITECTURE.md"
fi

case "$FILE" in
  *.css|*.scss|*.tsx|*/tailwind.config.*)
    echo ">> You modified $FILE. Update $BRAND (colors/tokens section) if design tokens changed." ;;
  *.ts|*.js)
    echo ">> You modified $FILE. Update docs/project/architecture.md and $ARCH if routes/controllers/structure changed." ;;
  */package.json|*config.*)
    echo ">> You modified $FILE. Update docs/project/tech-stack.md if dependencies/tooling changed." ;;
  */schema/*|*.model.*)
    echo ">> You modified $FILE. Update CONTEXT.md (domain model section) if entities/relationships changed." ;;
esac
# No match = no output (silent, no noise for non-doc-affecting changes)
```

Write to `.fullstack-dev/refresh-hint.sh`. Ensure it is executable
(`chmod +x` on Unix; on Windows, Git tracks the execute bit via
`git update-index --chmod=+x`).

This script is layout-agnostic: in mono-repo `REPO` stays empty so
paths resolve to root (`BRAND.md`, `ARCHITECTURE.md`); in multi-repo
the first path component with its own `.git/` is detected as the repo
name (`<repo>/BRAND.md`, `<repo>/ARCHITECTURE.md`).

### 9.8 Pre-commit hook (root repo)

Install a git pre-commit hook at `.git/hooks/pre-commit` (in the root
repo). The hook does two things:

1. **Auto-stage** docs that were already refreshed during the session
2. **Gate** the commit if staged code changes affect docs that weren't
   updated — blocks with a targeted message so Claude refreshes them
   and retries

```bash
#!/bin/sh
# fullstack-dev: auto-stage refreshed docs + doc-freshness gate

# Helper: skip files inside sub-repos (they have their own hooks)
in_subrepo() {
  case "$1" in
    */*) DIR=$(echo "$1" | cut -d/ -f1); [ -d "$DIR/.git" ] && return 0 ;;
  esac
  return 1
}

# --- Part 1: Auto-stage already-refreshed docs ---
# Root-level docs (always safe to stage from root repo)
for f in CONTEXT.md docs/project/architecture.md docs/project/tech-stack.md .code-review-graphignore ARCHITECTURE.md BRAND.md; do
  if [ -f "$f" ] && git diff --name-only | grep -qx "$f"; then
    git add "$f"
  fi
done
# Per-directory docs (mono-repo only — skip sub-repos with own .git/)
for g in */ARCHITECTURE.md */BRAND.md */.code-review-graphignore; do
  [ -f "$g" ] && ! in_subrepo "$g" && git diff --name-only | grep -qx "$g" && git add "$g"
done

# --- Part 2: Doc-freshness gate ---
# After auto-staging, check if staged code changes still need doc updates.
STAGED=$(git diff --cached --name-only)
[ -z "$STAGED" ] && exit 0

STALE=""
check_doc() {
  # Skip sub-repo files — handled by per-repo hooks (§9.8a)
  in_subrepo "$1" && return 0
  if [ -f "$1" ] && ! echo "$STAGED" | grep -qxF "$1"; then
    STALE="$STALE $1"
  fi
}

# CSS/design changes → BRAND.md
if echo "$STAGED" | grep -qE '\.(css|scss|tsx)$|tailwind\.config\.'; then
  check_doc "BRAND.md"
  for b in */BRAND.md; do [ -f "$b" ] && check_doc "$b"; done
fi

# New/deleted JS/TS files → architecture docs (modifications skipped
# to avoid false positives — not every .ts edit is structural)
if git diff --cached --diff-filter=AD --name-only | grep -qE '\.(ts|js)$'; then
  check_doc "docs/project/architecture.md"
  check_doc "ARCHITECTURE.md"
  for a in */ARCHITECTURE.md; do [ -f "$a" ] && check_doc "$a"; done
fi

# Dependency/config changes → tech-stack
if echo "$STAGED" | grep -qE 'package\.json$|\.config\.(ts|js|mjs|cjs)$'; then
  check_doc "docs/project/tech-stack.md"
fi

# Schema/model changes → CONTEXT.md
if echo "$STAGED" | grep -qE 'schema/|\.model\.'; then
  check_doc "CONTEXT.md"
fi

if [ -n "$STALE" ]; then
  echo ""
  echo "fullstack-dev: Staged code changes affect these docs, but they were not updated:"
  for doc in $STALE; do echo "  - $doc"; done
  echo ""
  echo "Refresh the listed docs, then 'git add' them and commit again."
  exit 1
fi
```

**Notes:**
- `CLAUDE.md` is deliberately excluded — it is user-owned and never
  auto-refreshed (see `reference/doc-templates.md` §6).
- Part 1 (auto-staging) runs first so docs refreshed during the session
  are picked up before the gate checks.
- Part 2 (gate) only triggers for file patterns likely to affect docs.
  JS/TS uses `--diff-filter=AD` (new/deleted files only) to avoid
  false positives on simple modifications.
- In a Claude session, Claude handles the retry automatically — it
  reads the failure message, refreshes the listed docs, stages them,
  and re-commits.
- Outside Claude sessions, the developer sees the message and updates
  docs manually or runs `/project --refresh`.

If a pre-commit hook already exists, append the plugin section inside
a marker block (same pattern as `.gitignore`).

### 9.8a Pre-commit hook (per sub-repo, multi-repo only)

In multi-repo projects, per-repo docs (`ARCHITECTURE.md`, `BRAND.md`)
live inside sub-repos with their own `.git/`. The root repo's
pre-commit hook cannot `git add` files across `.git/` boundaries. Each
sub-repo needs its own hook with the same two-part logic.

For each repo in `config.repos` whose `path` is not `"."`:

```bash
#!/bin/sh
# fullstack-dev: auto-stage + doc-freshness gate (per-repo)

# --- Part 1: Auto-stage already-refreshed per-repo docs ---
for f in ARCHITECTURE.md BRAND.md .code-review-graphignore; do
  if [ -f "$f" ] && git diff --name-only | grep -qx "$f"; then
    git add "$f"
  fi
done

# --- Part 2: Doc-freshness gate ---
STAGED=$(git diff --cached --name-only)
[ -z "$STAGED" ] && exit 0

STALE=""
if echo "$STAGED" | grep -qE '\.(css|scss|tsx)$|tailwind\.config\.'; then
  [ -f "BRAND.md" ] && ! echo "$STAGED" | grep -qxF "BRAND.md" && STALE="$STALE BRAND.md"
fi
if git diff --cached --diff-filter=AD --name-only | grep -qE '\.(ts|js)$'; then
  [ -f "ARCHITECTURE.md" ] && ! echo "$STAGED" | grep -qxF "ARCHITECTURE.md" && STALE="$STALE ARCHITECTURE.md"
fi

if [ -n "$STALE" ]; then
  echo ""
  echo "fullstack-dev: Staged code changes affect these docs, but they were not updated:"
  for doc in $STALE; do echo "  - $doc"; done
  echo ""
  echo "Refresh the listed docs, then 'git add' them and commit again."
  exit 1
fi
```

Install at `<repo-path>/.git/hooks/pre-commit` using the same marker
block pattern as the root hook (`fullstack-dev` markers). The
`[ -f "$f" ]` check means BRAND.md is silently skipped in repos that
don't have one (non-frontend repos).

Ensure the hook file is executable (`chmod +x`).

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
  [<repo>/BRAND.md]                (per frontend repo)
  [<repo>/ARCHITECTURE.md]         (per repo)
  .mcp.json
  .claude/settings.json
  .gitignore
  .code-review-graphignore
  [<repo>/.code-review-graphignore]  (per repo, if multi-repo)
  [<project>.code-workspace]       (if multi-repo)

Graph indexed:
  root:      <files> files, <nodes> nodes, <edges> edges
  [<repo>:   <files> files, <nodes> nodes, <edges> edges]   (per repo, if multi-repo)

Next steps:
  - Restart Claude Code to activate MCP servers and hooks
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
                  | Per-repo BRAND.md for each frontend/fullstack repo | Yes (regenerate)
                  | Per-repo ARCHITECTURE.md for each sub-repo       | Yes (regenerate)
                  | docs/specs/ directory exists                     | Yes (create)
                  | docs/plans/ directory exists                     | Yes (create)
                  | Doc staleness (per refresh-agent mapping)        | No (report only — see §10.2a)
Git               | Root has git initialized                         | No (warn)
                  | .gitignore has fullstack-dev:gitignore markers    | Yes (regenerate from catalog)
                  | All sub-repos listed in .gitignore marker block   | Yes (add missing to Sub-repositories category)
                  | Pre-commit hook has fullstack-dev:gitignore block  | Yes (append hook script)
                  | Pre-commit hook has fullstack-dev doc-staging block | Yes (append hook script)
                  | Per-repo pre-commit hooks installed (multi-repo only) | Yes (install per §9.8a)
                  | gitIgnore field exists in config.json             | Yes (populate from detection)
                  | No tracked files matching active ignore patterns  | Yes (offer /gitignore cleanup)
                  | Old gitignore marker format migrated              | Yes (migrate to fullstack-dev:gitignore)
                  | No new .git/ directories missing from config     | Yes (prompt to add)
                  | local-dev branch exists in each repo             | Yes (run /git setup)
                  | targetBranch set in each repo config entry       | Yes (run /git setup)
Claude Config     | .claude/settings.json exists                     | Yes (create)
                  | PostToolUse doc-staging hook command matches §9.7 | Yes (replace command text)
                  | .fullstack-dev/refresh-hint.sh exists and matches §9.7a | Yes (regenerate)
                  | Skills installed                                 | Yes (report missing)
                  | Commands installed                               | Yes (report missing)
MCP               | .mcp.json exists                                 | Yes (create)
                  | context7 configured                              | Yes (add entry)
                  | Git platform MCP configured                      | Yes (add entry)
                  | github entry is not deprecated stdio shape       | Yes (replace, named exception — see Merge Rules)
                  | claude mcp list reports no connectivity warnings | No (report only)
                  | Required MCP env vars present in settings.local.json | Partial (agent creates skeleton + reports; orchestrator asks user and writes — see Secret Prompt & Write Flow in tools-setup.md)
                  | code-review-graph entry in .mcp.json              | Yes (add entry)
                  | code-review-graph PostToolUse hook in settings.json | Yes (merge hook)
                  | code-review-graph SessionStart hook in settings.json | Yes (merge hook)
                  | .code-review-graphignore exists with marker block  | Yes (generate)
                  | .code-review-graphignore patterns match current tech stack | Yes (regenerate marker block)
                  | Each repo has a .code-review-graphignore (multi-repo only) | Yes (regenerate missing/stale)
                  | Each repo's .gitignore contains .code-review-graph/ (multi-repo only) | Yes (add missing entry)
                  | Each repo's graph has > 0 indexed files (multi-repo only) | Yes (trigger full rebuild)
Developer Tools   | Agentation in .mcp.json (if frontend)            | Yes (add entry)
Workspace         | .code-workspace file exists (if multi-repo)      | Yes (create)
                  | All repos listed in workspace folders            | Yes (add missing)
```

### 10.2a Doc staleness heuristic

For each doc file that exists, compare its last-commit timestamp against
the newest commit timestamp among its mapped source files (per the Smart
Refresh Rules table in `skills/project/agents/refresh-agent.md`):

```bash
doc_ts=$(git log -1 --format=%ct -- <doc-path>)
src_ts=$(git log -1 --format=%ct -- <source-glob-1> <source-glob-2> ...)
```

If `src_ts > doc_ts`, report the doc as `POSSIBLY STALE` alongside PASS/FAIL
results. This is **report-only** — never auto-fix, never auto-regenerate.
The user decides whether to run `/project --refresh` or update manually.

Source globs per doc (derived from refresh-agent.md's mapping table):

| Doc | Source globs |
|-----|-------------|
| `CONTEXT.md` | `**/schema/**`, `**/*.model.*` |
| `docs/project/architecture.md` | `**/*.ts`, `**/*.js` (routes, controllers, steps) |
| `docs/project/tech-stack.md` | `**/package.json`, `**/*config.*` |
| Per-repo `ARCHITECTURE.md` | `<repo>/**/*.ts`, `<repo>/**/*.js` |
| Per-repo `BRAND.md` | `<repo>/**/*.css`, `<repo>/**/*.scss`, `<repo>/**/*.tsx`, `<repo>/tailwind.config.*` |

For mono-repo, per-repo globs use `.` as `<repo>`. BRAND.md is only
checked for repos whose `type` is `frontend`/`fullstack`.

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
   - For the plugin-owned doc-staging hook (identified by matcher
     `Edit|Write` and command containing `Docs may be stale` or
     `refresh-hint`), replace the command with the current template
     from §9.7 (`sh .fullstack-dev/refresh-hint.sh`). This migrates
     old bare-echo installs to the targeted script approach.
   - Generate `.fullstack-dev/refresh-hint.sh` if it does not exist
     (per §9.7a).
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

### 12.3 Version-Specific Migrations

**1.0.0 → 1.1.0: code-review-graph always-on**

- Add code-review-graph `.mcp.json` entry (merge, skip if already present)
- Add code-review-graph PostToolUse and SessionStart hooks to
  `.claude/settings.json` (merge alongside existing hooks)
- Generate `.code-review-graphignore` with marker block (per
  `reference/tools-setup.md`)
- Run initial graph build: `uvx code-review-graph build --skip-flows
  --repo .` so the graph is ready immediately
- Remove `optionalTools.codeReviewGraph` from `config.json` regardless
  of its prior value (`true` or `false`). The `optionalTools` object
  remains with only `agentation: boolean`.
- Projects that previously had `codeReviewGraph: false` get
  code-review-graph added — intentional, since it is now always-on.
- Completion report note: "Added code-review-graph (now standard)."

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
