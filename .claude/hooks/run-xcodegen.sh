#!/bin/bash
# Runs xcodegen generate after Swift files are created/deleted.
# Triggered as a PostToolUse hook on Write operations.

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only trigger on Swift files
if [[ "$FILE_PATH" != *.swift ]]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 1

if xcodegen generate 2>&1; then
  echo "xcodegen regenerated after: $(basename "$FILE_PATH")" >&2
  exit 0
else
  echo "xcodegen generate failed" >&2
  exit 1
fi
