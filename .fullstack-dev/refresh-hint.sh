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
