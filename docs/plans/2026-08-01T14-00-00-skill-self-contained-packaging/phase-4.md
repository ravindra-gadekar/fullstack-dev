# Phase 4: Regenerate Lockfile & Verify

**Repo:** fullstack-dev (path `.`)
**Depends on:** Phase 3 (all file moves, dispatch fixes, and doc updates complete)
**Delivers:** All four static checks from the spec's Testing Strategy pass with zero unexpected matches; `skills-lock.json` reflects the new file layout; a fresh `npx skills add --skill '*'` install in a scratch test project includes agent files under `.claude/skills/<name>/agents/`; `/project --init` runs in that fresh install without file-not-found or "no such subagent type" errors.

## File Structure

```
skills-lock.json   [modify] regenerated hashes for all skills whose SKILL.md content changed
(no other files created/modified — this phase is verification + lockfile regeneration)
```

---

### Task 1: Run static dangling-reference and orphan checks

**Files:**
- Modify: any file flagged by the checks below (expected: none, since Phases 1-3 already addressed every known reference; this task is the safety net)

**Interfaces:**
- Consumes: Phase 1 Produces (relocated/deleted files), Phase 2 Produces (dispatch blocks), Phase 3 Produces (doc updates) — this task validates all of the above in one pass
- Produces: a clean bill of health, consumed by Task 2 (lockfile regeneration should only run against a verified-consistent tree)

**Acceptance Criteria:** Spec checkboxes "`grep -r \"<plugin-path>/agents/\" skills/` returns zero matches", "`grep -r \"../../agents/\" skills/` returns zero matches", "`grep -r \"subagent_type.*-agent\" skills/` returns zero matches"; spec's Static Checks section items 1-3 (Dangling reference scan, Old relative path scan, Orphan check).

**Steps:**
1. Run `grep -rn "agents/" skills/ --include="*.md" | grep -v "\.agents/"` and manually confirm every match resolves within some `skills/<name>/agents/` path (per spec Static Check #1). Expect two known, out-of-scope matches in `skills/gitignore/reference/gitignore-flow.md` and `skills/gitignore/reference/gitignore-catalog.md` referring to the unrelated `.agents/` Claude-Code-session-artifact gitignore pattern — these are excluded by the `grep -v` above and must NOT be "fixed"; they are not in the spec's File Changes list. If any *other* match points outside a skill's own `agents/` subdirectory, fix it before proceeding.
2. Run `grep -rn "<plugin-path>/agents/" skills/` — must return zero matches. If any remain, locate and fix them (a Phase 2 task was missed).
3. Run `grep -rn "\.\./\.\./agents/" skills/` — must return zero matches (per spec Static Check #2 and the "old relative path" acceptance criterion).
4. Run `grep -rn 'subagent_type.*-agent"' skills/` — must return zero matches (per acceptance criterion; excludes the intentional `subagent_type: "claude"` and `subagent_type="claude"` occurrences, which don't match this pattern).
5. Confirm via directory listing that `agents/`, `scripts/`, and `hooks/` do not exist at the repo root (per spec Static Check #3, Orphan check).
6. If every check passes with zero unexpected matches, no commit is needed for this task (verification only). If any check surfaces a straggler, fix it and commit: `fix(skills): resolve dangling agent path reference found in verification`

---

### Task 2: Regenerate skills-lock.json

**Files:**
- Modify: `skills-lock.json`

**Interfaces:**
- Consumes: Task 1's clean verification (all `SKILL.md` files are in their final, correct state before hashing)
- Produces: updated `computedHash` values for every skill the CLI determines has changed; every skill's installed mirror reflects the new `agents/` subdirectory layout regardless of hash-scope details

**Acceptance Criteria:** Spec checkbox "`skills-lock.json` regenerated with correct hashes after structural change"; spec's Error Handling note "the fix commit should include a regenerated `skills-lock.json`".

**Steps:**
1. Run `npx skills add https://github.com/ravindra-gadekar/fullstack-dev-plugin.git --skill '*'` against this repo itself (the existing dogfooding install mechanism per `CLAUDE.md`'s Build & Development Commands) to regenerate `skills-lock.json` with hashes matching the post-restructure content.
2. Verify `skills-lock.json` still parses as valid JSON and every one of the 9 skill entries (`brainstorm`, `debug`, `fix`, `git`, `gitignore`, `implement`, `plan`, `project`, `refactor`) is present.
3. Verify `computedHash` changed for `brainstorm`, `plan`, `project`, `refactor`, and `implement` — these skills' `SKILL.md` files were directly edited in Phase 2. **Do not assert a hash change for `debug`**: only `skills/debug/reference/debug-flow.md` was edited, not `skills/debug/SKILL.md` itself, and the lockfile schema (`skillPath: skills/debug/SKILL.md` + one hash per skill) suggests the hash may cover only that one file, not the whole directory tree. If the CLI hashes just `SKILL.md`, `debug`'s hash is expected to be unchanged — that is not a failure. Instead, verify `debug`'s installed correctness directly: confirm `.claude/skills/debug/agents/debugger-agent.md` exists in this repo's own installed mirror (`.claude/skills/`). If `debug`'s hash unexpectedly *did* change, that's fine too (broader hash scope) — either outcome is acceptable; only a missing `debugger-agent.md` in the installed mirror is a real failure.
4. Commit: `chore(skills-lock): regenerate hashes after self-contained packaging restructure`

---

### Task 3: Fresh-install and dispatch smoke test

**Files:**
- No repo files modified (external scratch directory only)

**Interfaces:**
- Consumes: Task 2 Produces (regenerated `skills-lock.json` and finalized skill tree); a git ref the `npx skills add` CLI can actually fetch from (a pushed branch, since the CLI installs from a git URL, not a local filesystem path — confirm this up front rather than assuming a local-path fallback exists)
- Produces: a pass/fail smoke-test result reported to the user; this is the plan's terminal verification step

**Acceptance Criteria:** Spec checkboxes "Fresh `npx skills add --skill '*'` install in a test project includes agent files under `.claude/skills/<name>/agents/`" and "`/project --init` executes successfully in a freshly installed test project (no file-not-found or \"no such subagent type\" errors)"; spec's Testing Strategy items "Fresh install test", "Command dispatch test", and "Dogfood test".

**Steps:**
1. Confirm whether `npx skills add` can install from a local filesystem path. If yes, use the local repo path directly. If no (git-URL-only), this task cannot run against `local-dev` before that branch is pushed to the remote — per `CLAUDE.md`'s Git Workflow, `local-dev` is never pushed directly, so push the work to a `chore/`-or-similar remote branch first (per `/git publish`), then point the install at that branch, OR defer this task to run as a post-PR follow-up once the branch is pushed for review. Note explicitly which path was taken when reporting results.
2. In a scratch directory outside this repo (e.g. under the session scratchpad), create an empty test project directory.
3. From that directory, run `npx skills add https://github.com/ravindra-gadekar/fullstack-dev-plugin.git --skill '*'` against the git ref confirmed in step 1 to perform a fresh install.
4. Verify `.claude/skills/<name>/agents/*.md` files exist for each of the 6 skills that own agents (`project`, `plan`, `brainstorm`, `implement`, `debug`, `refactor`) in the freshly installed test project.
5. In a Claude Code session rooted at the test project, run `/project --init` and confirm the init-agent executes end-to-end without a file-not-found or "no such subagent type" error.
6. Re-confirm the dogfood install performed in Task 2 (`npx skills add` on this repo itself) also produced `.claude/skills/<name>/agents/*.md` files in this repo's own installed mirror.
7. Report the smoke-test result (pass/fail per check) to the user. No commit — this task is verification only. If any check fails, return to the relevant Phase 1-3 task, fix it, and re-run this task's checks.

## Phase 4 Complete

All static checks pass, `skills-lock.json` is regenerated and consistent with the new file layout, and a fresh install has been proven to work end-to-end — including a live `/project --init` dispatch with no file-not-found errors. The skill self-contained packaging fix is fully implemented and verified.

**Next:** Plan complete. When `/implement` reaches branch finishing, include the migration note from this plan's README "Global Constraints" in the PR description: *"If you previously installed this plugin, re-run `npx skills add https://github.com/ravindra-gadekar/fullstack-dev-plugin.git --skill '*'` to pick up the restructured agent files."*
