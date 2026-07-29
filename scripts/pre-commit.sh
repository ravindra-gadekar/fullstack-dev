#!/bin/bash
# Fullstack Dev — pre-commit hook
# Stages refreshed docs into the current commit.
# Actual refresh happens during Claude sessions (PostToolUse hook).

for file in \
  CONTEXT.md \
  docs/project/architecture.md \
  docs/project/tech-stack.md \
  docs/project/brand.md; do
  if [ -f "$file" ] && ! git diff --quiet -- "$file" 2>/dev/null; then
    git add "$file"
  fi
done
