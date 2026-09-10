#!/usr/bin/env bash
# post_write_compile_check.sh — PostToolUse hook for Write|Edit
#
# After any file write/edit, checks if the modified file is a .sql model
# and runs a quick dbt compile to catch syntax errors immediately.
#
# Hook protocol (Claude Code PostToolUse):
#   stdin  → JSON: {"tool_name", "tool_input": {"file_path": "..."}, "tool_result"}
#   stdout → informational only (PostToolUse cannot block)
#
# Exit 0 always — PostToolUse hooks are advisory.

set -euo pipefail

# Read tool input from stdin (Claude Code passes JSON via stdin, NOT env vars)
INPUT_JSON=$(cat)

# Extract file_path from the tool_input object
# Primary: use jq for reliable JSON parsing
# Fallback: regex for systems without jq (e.g., minimal CI containers)
if command -v jq &>/dev/null; then
    FILE_PATH=$(echo "$INPUT_JSON" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null || true)
else
    # Regex fallback — handles simple single-line JSON
    FILE_PATH=$(echo "$INPUT_JSON" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)
    if [[ -z "$FILE_PATH" ]]; then
        FILE_PATH=$(echo "$INPUT_JSON" | grep -o '"filePath"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"filePath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)
    fi
fi

# Exit early if no file path found
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Only check .sql files under models/
if [[ "$FILE_PATH" == *"models/"*".sql" ]]; then
    # Extract model name from path
    MODEL_NAME=$(basename "$FILE_PATH" .sql)

    # Only compile if dbt is available and we're in the project root
    if command -v dbt &>/dev/null && [ -f "dbt_project.yml" ]; then
        echo "Auto-compile check: $MODEL_NAME"

        # Quick compile — timeout after 20s to avoid blocking
        # macOS uses gtimeout (coreutils), Linux uses timeout
        TIMEOUT_CMD="timeout"
        command -v timeout &>/dev/null || TIMEOUT_CMD="gtimeout"
        if ! command -v "$TIMEOUT_CMD" &>/dev/null; then
            # No timeout available — run without it
            TIMEOUT_CMD=""
        fi

        if ${TIMEOUT_CMD:+$TIMEOUT_CMD 20} dbt compile --select "$MODEL_NAME" 2>&1 | tail -5; then
            echo "✅ Compile OK: $MODEL_NAME"
        else
            echo "⚠️  Compile issue detected for $MODEL_NAME — review before proceeding"
        fi
    fi
fi

exit 0
