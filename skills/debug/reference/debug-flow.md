# Debug Flow Reference

Detailed flow, decision trees, and anti-rationalization rules for the
debug skill.

---

## 1. Feedback Loop Construction

All 10 methods with examples and when to use each. Try in order — use the
first one that works.

### Method 1: Failing Test

Write or find a test that reproduces the bug.

```
When to use: A test framework exists and the bug is in testable code.
Example: npm test -- --testPathPattern=auth.test
Example: npx vitest run src/auth/__tests__/session.test.ts
```

### Method 2: CLI Command

A single command that shows the error.

```
When to use: The bug manifests as a build failure, type error, or lint error.
Example: npm run build
Example: npx tsc --noEmit
Example: npx eslint src/middleware/auth.ts
```

### Method 3: HTTP Request

curl/fetch that triggers the error.

```
When to use: The bug is in an API endpoint or server-side handler.
Example: curl -X POST localhost:3000/api/auth -H "Content-Type: application/json" -d '{"token": "expired"}'
Example: curl -s -o /dev/null -w "%{http_code}" localhost:3000/api/users/me
```

### Method 4: Script

Throwaway script isolating the condition.

```
When to use: The bug requires specific setup or a sequence of operations.
Example: Write debug-repro.js, run with node debug-repro.js
Example: Write debug-repro.py, run with python debug-repro.py
Rule: Delete the script after debugging. Never commit it.
```

### Method 5: Headless Browser

For UI bugs that need a browser.

```
When to use: The bug is in frontend rendering, user interaction, or browser-specific behavior.
Example: Playwright script clicking the failing flow
Example: npx playwright test --grep "login flow"
```

### Method 6: Log Grep

Run the app and grep logs for the error pattern.

```
When to use: The bug appears in log output but not in test results.
Example: npm run dev & sleep 3 && curl localhost:3000/route && grep "ERROR" logs/
Example: npm run dev 2>&1 | grep -m 1 "TypeError"
```

### Method 7: Snapshot Diff

Diff output against expected.

```
When to use: The output is subtly wrong (not crashing, just incorrect).
Example: node script.js > actual.txt && diff expected.txt actual.txt
Example: curl localhost:3000/api/data | jq . > actual.json && diff expected.json actual.json
```

### Method 8: Git Bisect

Find the breaking commit.

```
When to use: The bug is a regression — it used to work.
Example: git bisect start && git bisect bad && git bisect good v1.2.0 && git bisect run npm test
Note: Requires a known-good commit.
```

### Method 9: Differential Loop

Compare old vs new behavior.

```
When to use: Two versions of the code exist (branches, commits, configs).
Example: Run same input on two branches and diff the output.
Example: Toggle a feature flag and compare behavior.
```

### Method 10: Human-in-the-Loop

Last resort. Ask the user to trigger the bug and report what they see.

```
When to use: All automated methods failed to reproduce.
Example: Ask user to trigger the bug and report what they see.
Note: This is the LAST resort. Exhaust methods 1-9 first.
```

---

## 2. Feedback Loop Sanity Check

```
After constructing the feedback loop:
1. Run the command once
2. Check exit code:
   +-- Non-zero (fails) → Bug reproduces. Loop confirmed. Proceed.
   +-- Zero (passes) → Loop is WRONG. Does not reproduce the bug.
       +-- Try the next method from the 10-method list
       +-- If all methods tried → HARD GATE: stop and ask user
```

The sanity check is mandatory. Never skip it.

---

## 3. Session Tag Convention

**Generation:** 4-character random hex string (e.g., `a3f1`, `b7e2`).

**Usage:** All instrumentation lines prefixed with `[DEBUG-<tag>]`:

```javascript
// JavaScript/TypeScript
console.log('[DEBUG-a3f1] variable:', variable);
console.log('[DEBUG-a3f1] req.user:', JSON.stringify(req.user));
```

```python
# Python
print(f'[DEBUG-a3f1] variable: {variable}')
print(f'[DEBUG-a3f1] session: {session}')
```

**Cleanup:** Single grep removes all instrumentation:

```
Find:   grep -rn "\[DEBUG-a3f1\]" .
Remove: Delete all lines containing the tag
```

**Rule:** Never leave `[DEBUG-xxxx]` tags in committed code.

---

## 4. Hypothesis Template

```markdown
## Hypothesis N: <title>
**Claim:** <specific, falsifiable statement>
**Evidence:** <what supports this>
**Test:** <what to instrument/check to confirm or refute>
**Prediction:** <if this hypothesis is correct, I should see X when I do Y>
```

### Example

```markdown
## Hypothesis 1: JWT expiry causes null session
**Claim:** getSession() returns undefined when the JWT expires, and the auth middleware doesn't check for this
**Evidence:** Stack trace shows NPE at req.user.id (line 42), and the error occurs ~1hr after login
**Test:** Add [DEBUG-a3f1] log before getSession() call, log the raw JWT and decoded expiry
**Prediction:** The JWT's exp field will be in the past, and getSession() will return undefined
```

---

## 5. Anti-Rationalization Tables

| Thought | Response |
|---------|----------|
| "This is obviously just a typo" | Use `/fix` if you know the cause. `/debug` doesn't skip investigation. |
| "Let me just try this one thing" | That's a hypothesis. Write it down. Rank it. Test it properly. |
| "No time to build a feedback loop" | A feedback loop saves more time than it costs. Build it. |
| "I know what's wrong" | Write it as hypothesis #1. But still generate 2-4 alternatives. |
| "One more fix attempt" | Have you exhausted all hypotheses? If so, revert and escalate. |
| "This try/catch will handle it" | try/catch hides bugs. Find the root cause. |
| "The tests are too slow to run" | Find a faster subset. A slow feedback loop beats no feedback loop. |
| "It works on my machine" | The feedback loop must reproduce the bug. If it can't, you don't understand it yet. |

---

## 6. Red Flags

Thoughts that should trigger an immediate STOP:

- **"Quick fix for now, proper fix later"** — There is no later. Fix it properly now.
- **"I'll just suppress this error"** — Suppression is not a fix. Find the root cause.
- **"Let me add a null check here"** — Why is the value null? That's the real bug.
- **"This is probably a race condition"** (without evidence) — "Probably" is not evidence. Instrument and prove it.
- **"Let me try a different approach"** (without understanding why the current one failed) — Understanding failure is more important than trying alternatives.

---

## 7. Iron Laws

1. **NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST**
   Rationale: Even "obvious" fixes can mask deeper issues. Investigation confirms you're fixing the right thing.

2. **NO HYPOTHESES WITHOUT A FEEDBACK LOOP**
   Rationale: Without a reproducible signal, you can't confirm or refute anything. You're guessing.

3. **NO STACKING FIXES — revert before trying the next**
   Rationale: Stacked changes create compound state that makes debugging harder. One change at a time.

4. **NO TRY/CATCH AS A FIX — ever**
   Rationale: try/catch hides bugs from future debuggers. The root cause persists and will surface again.

---

## 8. Exhaustion Escalation Protocol

```
All hypotheses tested and refuted:
1. STOP — do not generate more hypotheses
2. Revert ALL changes:
   git checkout -- .    (or git stash if changes need preserving)
3. Write post-mortem:
   - Bug symptoms (what the user reported)
   - Feedback loop used (how the bug was reproduced)
   - Each hypothesis tested:
     - What was predicted
     - What was observed
     - Why it was refuted
   - Conclusion: why the bug likely indicates a structural/architectural problem
4. Flag as "needs human"
5. Guard pops stash on exit
6. Present post-mortem to user
```

---

## 9. Stash/Pop Safety Protocol

Stash/pop is handled by the universal git guard (see
`skills/git-workflow/SKILL.md`, Guard section). The debug skill does NOT
manage its own stash — the guard stashes before the command runs and pops
on all exit paths (success, failure, error, abort).

```
On error/crash:
  The stash persists in git. User can recover with:
  git stash list    (find the "pre-<command>-stash" entry)
  git stash pop     (restore their work)
```

---

## 10. Verbose Output Format (`--verbose`)

Phase transitions:
```
[PHASE 2/6] Building feedback loop...
```

Feedback loop attempts:
```
[LOOP] Trying method 1: failing test... ✗ not applicable
[LOOP] Trying method 2: CLI command... ✓ reproduces bug
```

Evidence found:
```
[EVIDENCE] git blame shows line 42 changed 2 days ago by commit abc123
```

Hypothesis presentation:
```
[HYPOTHESIS 1/3] JWT expiry causes null session (likelihood: HIGH)
```

Instrumentation:
```
[INSTRUMENT] Added [DEBUG-a3f1] tag to src/middleware/auth.ts:41
```

Test results:
```
[TEST] Hypothesis 1: CONFIRMED — getSession() returned undefined
```

---

## 11. Parallel Agent Dispatch (`--parallel`)

Dispatch 5 debugger-agent instances in a single message for parallel
execution:

```
Agent(description="Stack Trace Agent", prompt="...", subagent_type="debugger-agent")
Agent(description="Git Blame Agent", prompt="...", subagent_type="debugger-agent")
Agent(description="Test Agent", prompt="...", subagent_type="debugger-agent")
Agent(description="Pattern Agent", prompt="...", subagent_type="debugger-agent")
Agent(description="Dependency Agent", prompt="...", subagent_type="debugger-agent")
```

Each agent receives:
- Bug symptoms
- Affected files
- Feedback loop command

Each agent returns:
- Raw evidence only (no hypotheses, no fix suggestions)

All 5 dispatched in a single message for parallel execution.
