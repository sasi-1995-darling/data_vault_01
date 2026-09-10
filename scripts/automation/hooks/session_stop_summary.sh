#!/usr/bin/env bash
# session_stop_summary.sh — Stop hook
#
# Runs when a Claude Code session ends.
# Outputs a summary of what happened during the session
# for audit trail and team visibility.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PIPELINE_STATE_DIR="$REPO_ROOT/scripts/automation/.pipeline_state"

echo "═══════════════════════════════════════════════════"
echo "  Session End Summary"
echo "═══════════════════════════════════════════════════"
echo ""

# --- Git changes summary ---
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    echo "🌿 Branch: $BRANCH"

    # Count commits made during this session (rough: last 2 hours)
    RECENT_COMMITS=$(git log --oneline --since="2 hours ago" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$RECENT_COMMITS" -gt 0 ]; then
        echo "📝 Recent commits ($RECENT_COMMITS):"
        git log --oneline --since="2 hours ago" 2>/dev/null | head -10 | while read -r line; do
            echo "   • $line"
        done
    fi

    # Uncommitted changes
    DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DIRTY" -gt 0 ]; then
        echo "⚠️  $DIRTY uncommitted changes remaining"
    fi
fi

echo ""

# --- Pipeline state at exit ---
if [ -d "$PIPELINE_STATE_DIR" ]; then
    for state_file in "$PIPELINE_STATE_DIR"/*.json; do
        if [ -f "$state_file" ]; then
            MODEL_NAME=$(basename "$state_file" .json)
            CURRENT_STEP=$(grep -o '"current_step": *"[^"]*"' "$state_file" 2>/dev/null | head -1 | sed 's/.*: *"\(.*\)"/\1/' || echo "unknown")
            echo "🔧 Pipeline '$MODEL_NAME' left at step: $CURRENT_STEP"
        fi
    done
fi

echo ""
echo "═══════════════════════════════════════════════════"
