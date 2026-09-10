#!/bin/bash
# pre-commit-skill-sync.sh — Local pre-commit hook to catch skill drift
#
# Prevents commits where .github/skills/ is modified without updating .claude/skills/.
# .github/skills/ is the CANONICAL source. .claude/skills/ must mirror it.
#
# Install:
#   cp .github/hooks/pre-commit-skill-sync.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Or append to existing pre-commit hook:
#   cat .github/hooks/pre-commit-skill-sync.sh >> .git/hooks/pre-commit

set -euo pipefail

# Count staged files in each skill location
GITHUB_CHANGED=$(git diff --cached --name-only | grep "^\.github/skills/" | wc -l | tr -d ' ')
CLAUDE_CHANGED=$(git diff --cached --name-only | grep -E "^\.claude/skills/(dv-code-implementer|dv-tech-design-creator|v-psa-stg-generator|dv-raw-vault-generator|conventional-commit)/" | wc -l | tr -d ' ')

if [ "$GITHUB_CHANGED" -gt 0 ] && [ "$CLAUDE_CHANGED" -eq 0 ]; then
    echo ""
    echo "================================================================"
    echo "  SKILL SYNC REQUIRED"
    echo "================================================================"
    echo ""
    echo "  You modified .github/skills/ (canonical) but did not update"
    echo "  .claude/skills/ (mirror for Claude Code users)."
    echo ""
    echo "  Fix:"
    echo "    bash scripts/sync_skills.sh"
    echo "    git add .claude/skills/"
    echo ""
    echo "  Then retry your commit."
    echo "================================================================"
    echo ""
    exit 1
fi

if [ "$CLAUDE_CHANGED" -gt 0 ] && [ "$GITHUB_CHANGED" -eq 0 ]; then
    echo ""
    echo "================================================================"
    echo "  WRONG EDIT LOCATION"
    echo "================================================================"
    echo ""
    echo "  You edited .claude/skills/ directly. This is a MIRROR."
    echo "  All skill edits must go to .github/skills/ (canonical)."
    echo ""
    echo "  Fix:"
    echo "    1. Move your changes to .github/skills/"
    echo "    2. Run: bash scripts/sync_skills.sh"
    echo "    3. Stage both: git add .github/skills/ .claude/skills/"
    echo ""
    echo "================================================================"
    echo ""
    exit 1
fi

# --- Agent sync check ---
# REMOVED: Agent-sync block was contradicting AGENTS.md policy.
# AGENTS.md states: "Agent files live ONLY in .github/agents/. Do NOT copy to .claude/agents/"
# The old check exit 1'd when .claude/agents/ was empty — which IS the correct state.
# CI workflow (.github/workflows/skill-sync-check.yaml) validates skill sync separately.
