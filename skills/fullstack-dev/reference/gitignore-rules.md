# .gitignore Marker Block Management

Reference for init-agent and repo-agent when managing the `.gitignore` file in a Fullstack Dev workspace. Claude follows these rules directly using Read/Edit tools — no script needed.

---

## 1. Marker Block Format

The managed block uses exact start/end markers. Copy this template verbatim (including blank lines):

```gitignore
# ============================================
# Fullstack Dev Plugin — auto-generated entries
# Do NOT remove this block manually
# ============================================

# Sub-repositories (each has its own git)
frontend-app/
backend-api/
worker-service/

# Plugin internals
.fullstack-dev/*.local.*

# Generated / rebuilt automatically
node_modules/

# Secrets
.env
.env.local
.env.*.local

# ============================================
# End Fullstack Dev Plugin block
# ============================================

# --- User entries below ---
```

The sub-repository list is project-specific. The example above shows three repos; your workspace may have more or fewer.

---

## 2. What Goes in the Marker Block

| Category | Pattern(s) | Why |
|---|---|---|
| Sub-repository directories | `frontend-app/`, `backend-api/`, etc. | Each sub-repo has its own `.git`; the parent repo must not track them |
| Plugin internals | `.fullstack-dev/*.local.*` | Local config/state files that should never be committed |
| Generated / rebuilt files | `node_modules/` | Rebuilt on `npm install`; never committed |
| Secrets | `.env`, `.env.local`, `.env.*.local` | Environment secrets must never be committed |

Only entries that the plugin manages belong inside the markers. Everything else belongs below the `# --- User entries below ---` line.

---

## 3. Rules for Modifying the Block

### Finding the block

1. Read `.gitignore` with the Read tool.
2. Search for the start marker: `# Fullstack Dev Plugin — auto-generated entries`.
3. Search for the end marker: `# End Fullstack Dev Plugin block`.

### Editing within the block

- **Marker block found** — edit ONLY within the start and end markers. Do not move, reorder, or modify anything outside them.
- **Marker block NOT found** — append the full template block (Section 1) above any existing file content, following the merge rules in Section 4.
- **NEVER touch entries outside the marker block.** User-managed entries are their responsibility.

### Adding a repo (`--add-repo`)

1. Find the `# Sub-repositories (each has its own git)` section inside the marker block.
2. Add the new directory on its own line, with a trailing `/` (e.g., `new-repo/`).
3. Keep the list alphabetically sorted.

### Removing a repo

1. Find the directory line inside the `# Sub-repositories` section.
2. Remove that single line.
3. Do not remove the section header even if the list becomes empty.

---

## 4. Merge with Existing .gitignore

When the `.gitignore` already has content and no marker block exists:

1. **Place the marker block at the TOP of the file.**
2. **Preserve ALL existing entries** below the `# --- User entries below ---` line.
3. **If existing entries duplicate** what is in the marker block (e.g., `node_modules/` appears in both), **keep both**. Git processes `.gitignore` top-to-bottom; user entries are harmless duplicates and removing them would alter the user's file.

### Example merge

Before (existing `.gitignore`):

```gitignore
node_modules/
.DS_Store
*.log
```

After (marker block inserted):

```gitignore
# ============================================
# Fullstack Dev Plugin — auto-generated entries
# Do NOT remove this block manually
# ============================================

# Sub-repositories (each has its own git)
frontend-app/
backend-api/

# Plugin internals
.fullstack-dev/*.local.*

# Generated / rebuilt automatically
node_modules/

# Secrets
.env
.env.local
.env.*.local

# ============================================
# End Fullstack Dev Plugin block
# ============================================

# --- User entries below ---
node_modules/
.DS_Store
*.log
```

---

## 5. Mono-repo vs Multi-repo

| Workspace type | Marker block? | Reason |
|---|---|---|
| **Multi-repo** | Required | Sub-repo directories must be listed so the parent repo ignores them |
| **Mono-repo** | Not needed | There are no sub-repos to ignore; standard `.gitignore` rules suffice |

When converting from mono-repo to multi-repo (or vice versa), add or remove the marker block accordingly.

---

## 6. Key Principle

Claude reads the `.gitignore` file, locates the markers, and edits only within the block — no shell script, no regex replacement, no external tool. The init-agent and repo-agent follow these rules mechanically:

1. **Read** the file (Read tool).
2. **Find** the marker boundaries.
3. **Edit** within the markers (Edit tool) or **prepend** the full block if absent.
4. **Leave everything else untouched.**
