# Fix Flow Reference

Detailed flow, constraints, and escalation logic for the fix skill.

---

## 1. Directive Parsing

Extract the fix target from user input or `/debug` dispatch.

### Example Directives

**Simple:**
```
Change the API timeout from 5000ms to 30000ms in src/config.ts
```

**Multi-file:**
```
Rename the userId field to accountId in src/models/user.ts and update all imports in src/routes/
```

**With context:**
```
The auth middleware crashes because req.user is undefined when JWT expires — add an early return in src/middleware/auth.ts
```

### Dispatch Detection

Check if the directive starts with or contains the `[dispatched-by-debug]` marker:

```
Directive text:
+-- Starts with or contains "[dispatched-by-debug]"
|   → Dispatched mode
|   → Strip the marker
|   → Extract: what to change, where, why (root cause from /debug)
+-- No marker
    → Standalone mode
    → Extract: what to change (may include file paths, line numbers, reasoning)
```

---

## 2. Standalone vs Dispatched Mode

| Aspect | Standalone | Dispatched |
|--------|-----------|------------|
| Source | User typed `/fix` | `/debug` invoked skill |
| Context marker | None | `[dispatched-by-debug]` |
| On verification failure | Offer `/debug` escalation | Return failure silently |
| On success | Commit + report to user | Commit + return success |
| User interaction | Yes (questions, escalation) | No (return to caller) |

---

## 3. Context Reading

Before applying any fix:

1. Read target file(s) completely
2. Read 50 lines above and below the change location
3. Check imports/exports to understand dependencies
4. For multi-file: read ALL target files before making ANY changes
5. Never apply a fix without reading surrounding code first

---

## 4. Multi-File Changes

- A single directive can span multiple files
- Apply all changes before running verification
- If verification fails, revert ALL changes (not just some)
- Commit all changes as a single atomic commit

---

## 5. Verification Strategy

Priority order:

1. Check `.fullstack-dev/config.json` for configured verification commands
2. Find test files closest to the changed files (same directory, then parent, then project-wide)
3. Run those specific tests only (not the full suite)
4. Run the project's build command

```
Exit codes:
+-- 0 → pass
+-- Non-zero → fail

Capture both stdout and stderr for error reporting.
```

---

## 6. Escalation Protocol (Standalone Only)

When verification fails in standalone mode:

1. Show the user what failed and why
2. Offer three options:
   - **(a) Run `/debug` to investigate** (recommended)
   - **(b) Revert the change**
   - **(c) Keep the change anyway**
3. Never attempt alternative fixes — that's `/debug`'s job

```
Verification failed in standalone mode:
+-- Show error output to user
+-- AskUserQuestion with 3 options:
    +-- (a) /debug → tell user to run /debug with the symptom
    +-- (b) Revert → git checkout the changed files
    +-- (c) Keep → warn that verification failed, commit anyway
```

---

## 7. Anti-Patterns

Each blocked behavior with rationale:

| Anti-Pattern | Why It's Blocked | Do This Instead |
|---|---|---|
| Wrapping in try/catch | Hides the bug instead of fixing it. The root cause persists. | Apply the fix the caller specified |
| Adding `\|\| undefined` / `?? null` | Masking symptoms. The undefined value still propagates. | Fix the source of the undefined value |
| Fixing without reading code | Without context, fixes break adjacent logic. | Always read 50 lines above and below |
| Ignoring the directive | The caller knows the fix. Trust the directive. | Follow the directive exactly |
| Attempting alternative fixes | If the specified fix fails, the issue needs investigation. | Report the failure, suggest `/debug` |

---

## 8. Commit Message Format

```
fix: <concise description of what was changed>

<what the issue was>
<what was changed and why>
```

For dispatched mode, include the root cause:

```
fix: <concise description of what was changed>

Root cause: <hypothesis from /debug>
<what was changed and why>
```

### Examples

**Standalone:**
```
fix: increase API timeout from 5s to 30s

External API calls were timing out under load because the default
5000ms timeout was too aggressive. Increased to 30000ms in src/config.ts.
```

**Dispatched by /debug:**
```
fix: add null check for req.user in auth middleware

Root cause: JWT expiry causes getSession() to return undefined, but
the auth middleware assumes req.user is always populated.
Added early return with 401 when req.user is undefined in
src/middleware/auth.ts.
```
