#!/usr/bin/env bash
# session_start_digest.sh — SessionStart hook
#
# Runs at the beginning of every Claude Code session.
# Outputs a digest of recent lessons and current pipeline state
# so the agent starts with full context.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
LESSONS_FILE="$REPO_ROOT/scripts/automation/lessons.md"
PIPELINE_STATE_DIR="$REPO_ROOT/scripts/automation/.pipeline_state"

echo "═══════════════════════════════════════════════════"
echo "  FBIN Data Vault Automation — Session Startup"
echo "═══════════════════════════════════════════════════"
echo ""

# --- Lessons digest ---
if [ -f "$LESSONS_FILE" ]; then
    TOTAL_LESSONS=$(grep -c '^[0-9]\+\.' "$LESSONS_FILE" 2>/dev/null || echo "0")
    echo "📚 Lessons: $TOTAL_LESSONS codified (scripts/automation/lessons.md)"

    # Show last 10 lessons (most recent additions)
    echo "   Recent additions:"
    grep '^[0-9]\+\.' "$LESSONS_FILE" | tail -10 | while read -r line; do
        echo "   • $line"
    done

    # Check for any Proposed lessons (unnumbered bullet points, not numbered)
    # Scope to ## Proposed section only (stop at next ## heading or EOF)
    PROPOSED_COUNT=$(sed -n '/^## Proposed$/,/^## /{ /^## /d; p; }' "$LESSONS_FILE" | grep -c '^\s*[-*]' || true)
    if [ "${PROPOSED_COUNT:-0}" -gt 0 ]; then
        echo "   ⚠️  $PROPOSED_COUNT lesson(s) pending review in ## Proposed section"
    fi
else
    echo "⚠️  Lessons file not found at $LESSONS_FILE"
fi

echo ""

# --- Active pipeline state ---
if [ -d "$PIPELINE_STATE_DIR" ]; then
    ACTIVE_PIPELINES=$(find "$PIPELINE_STATE_DIR" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$ACTIVE_PIPELINES" -gt 0 ]; then
        echo "🔧 Active pipelines: $ACTIVE_PIPELINES"
        for state_file in "$PIPELINE_STATE_DIR"/*.json; do
            if [ -f "$state_file" ]; then
                MODEL_NAME=$(basename "$state_file" .json)
                # Extract current step from state JSON
                CURRENT_STEP=$(grep -o '"current_step": *"[^"]*"' "$state_file" 2>/dev/null | head -1 | sed 's/.*: *"\(.*\)"/\1/' || echo "unknown")
                echo "   • $MODEL_NAME → step: $CURRENT_STEP"
            fi
        done
    else
        echo "🔧 No active pipelines"
    fi
else
    echo "🔧 No active pipelines"
fi

echo ""

# --- Hook & test counts ---
HOOKS_DIR="$REPO_ROOT/scripts/automation/hooks"
HOOK_COUNT=$(find "$HOOKS_DIR" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) ! -name 'test_*' 2>/dev/null | wc -l | tr -d ' ')
TEST_COUNT=$(find "$REPO_ROOT/scripts/automation/tests" -name 'test_*.py' -type f 2>/dev/null | wc -l | tr -d ' ')
echo "🔩 Hooks: $HOOK_COUNT active | Tests: $TEST_COUNT test files"

echo ""

# --- Entry-7 / Commit-C hook enforcement check (sprint-1-deferred #21, lesson #9) ---
# Canonical path also encoded in scripts/automation/hooks/git/pre-commit AND
# scripts/automation/hooks/git/pre-push; if relocating, update all three.
# Same `core.hooksPath` serves both hooks (entry-7 artifact-ship guard and
# Commit-C pre-push DA enforcement). See sprint-1-deferred.md #21 closure note.
EXPECTED_HOOKS_PATH="scripts/automation/hooks/git"
ACTUAL_HOOKS_PATH=$(git config --get core.hooksPath 2>/dev/null || echo "")
# Resolve both sides to absolute canonical paths so a trailing slash,
# a relative-vs-absolute encoding (`core.hooksPath foo/bar` vs
# `/abs/path/foo/bar` pointing at the same directory), or a symlink
# does NOT false-fire the "hooks OFF" banner and train users to
# dismiss a verifier they should trust. Empty ACTUAL stays empty
# (genuine OFF). Non-existent paths fall back to the raw value so the
# banner still fires accurately on a misconfigured hooksPath.
# `cd && pwd` portably canonicalizes without requiring GNU realpath.
# Tightened 2026-06-21 (PR #1821 Commit 6, R4 finding N6) from a
# strict-string compare that false-fired on absolute paths.
EXPECTED_ABS="$(cd "$REPO_ROOT/$EXPECTED_HOOKS_PATH" 2>/dev/null && pwd)"
if [ -n "$ACTUAL_HOOKS_PATH" ]; then
    case "$ACTUAL_HOOKS_PATH" in
        /*) ACTUAL_ABS="$(cd "$ACTUAL_HOOKS_PATH" 2>/dev/null && pwd)" ;;
        *)  ACTUAL_ABS="$(cd "$REPO_ROOT/$ACTUAL_HOOKS_PATH" 2>/dev/null && pwd)" ;;
    esac
    : "${ACTUAL_ABS:=$ACTUAL_HOOKS_PATH}"
else
    ACTUAL_ABS=""
fi
if [ "$ACTUAL_ABS" != "$EXPECTED_ABS" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ⚠  ENFORCEMENT HOOKS: OFF (pre-commit + pre-push)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  core.hooksPath is '$ACTUAL_HOOKS_PATH'"
    echo "  (expected: '$EXPECTED_HOOKS_PATH')"
    echo ""
    echo "  Two enforcement hooks share this hooksPath:"
    echo "    • pre-commit (entry 7): artifact-ship + score-update guard"
    echo "    • pre-push  (entry 9 / Commit C): pre-push DA enforcement"
    echo "  Neither will fire. This session can silently drift on a"
    echo "  ship commit OR push a DA-due change without review."
    echo ""
    echo "  ONE-LINE FIX (run now):"
    echo "      git config core.hooksPath $EXPECTED_HOOKS_PATH"
    echo ""
    echo "  Reference: docs/triage-agent/lessons-learned.md entries 7, 8, 9"
    echo "             docs/triage-agent/sprint-1-deferred.md #21"
    echo "             docs/triage-agent/phase-2-progress-log.md (Commit C)"
    echo "  Coverage:  Claude Code sessions only — non-Claude-Code git"
    echo "             operations have no verifier (see #21 closure)."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

# --- Git branch info ---
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    echo "🌿 Branch: $BRANCH ($DIRTY uncommitted changes)"
fi

echo ""
echo "📋 Reminder: Use .venv/bin/python3 for ALL automation commands"
echo "═══════════════════════════════════════════════════"
