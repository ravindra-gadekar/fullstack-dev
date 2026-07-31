# .gitignore Management — Routing Reference

This file exists for backward compatibility. It previously contained hardcoded gitignore patterns and merge rules, but those have moved to the dedicated gitignore skill.

---

## Where to find what you need

**Pattern catalog:** `skills/gitignore/reference/gitignore-catalog.md`
All gitignore patterns organized by category with detection rules.

**Flow reference:** `skills/gitignore/reference/gitignore-flow.md`
Marker block format, merge rules, pre-commit hook template, detection heuristics, migration logic.

---

## Canonical marker format

The standard marker format is:

    # >>> fullstack-dev:gitignore (do not edit this block) >>>
    # <<< fullstack-dev:gitignore <<<

---

## Retired marker format

The old `# ============` marker format (previously documented in this file) is retired. It is automatically migrated to the new format on rebuild or health check. See `gitignore-flow.md` Section 5 for migration details.

---

## Command reference

Use `/gitignore <scan|rebuild|cleanup>` for gitignore management operations.
