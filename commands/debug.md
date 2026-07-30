---
name: debug
description: "Investigate and fix unknown issues. Systematic root-cause analysis with mandatory feedback loop, hypothesis testing, and verified fix."
argument-hint: "[--auto] [--parallel] [--verbose] <symptoms>"
---

EXECUTE IMMEDIATELY — invoke the debug skill.

## Argument Parsing

Extract from $ARGUMENTS:

- `--auto` — Auto-approve file reads/writes. Proceed through hypothesis testing without user review.
- `--parallel` — Spawn parallel investigation agents during evidence gathering.
- `--verbose` — Show rich structured progress (phase transitions, hypotheses, evidence).
- Everything else — the bug symptoms (error messages, unexpected behavior description).

## Execution

1. Parse `$ARGUMENTS` to separate the symptom description from flags
2. Invoke the `debug` skill via the Skill tool
3. Pass the parsed flags and symptom description to the skill
