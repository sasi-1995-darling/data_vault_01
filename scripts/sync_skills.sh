#!/usr/bin/env bash
# sync_skills.sh — Mirror .github/skills/ (canonical) → .claude/skills/ (backward compat)
#                   Verify .claude/agents/ exists (Claude Code-native agents)
#
# .github/skills/ is the single source of truth for FBIN custom skills.
# .claude/skills/ is a mirror for Claude Code users.
# .claude/agents/ contains Claude Code-native agents (separate from .github/agents/ Copilot format).
#
# Usage:
#   bash scripts/sync_skills.sh
#
# Enforced by:
#   - Pre-commit hook: .github/hooks/pre-commit-skill-sync.sh
#   - CI check: .github/workflows/skill-sync-check.yaml

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CANONICAL="$REPO_ROOT/.github/skills"
MIRROR="$REPO_ROOT/.claude/skills"

# Only sync FBIN custom skills (not dbt-labs plugin skills)
SKILLS=("dv-code-implementer" "dv-tech-design-creator" "v-psa-stg-generator" "dv-raw-vault-generator" "conventional-commit" "dv-code-reviewer" "dv-pipeline-handoff" "dv-modeling-advisor")

echo "Syncing skills: .github/skills/ → .claude/skills/"
echo ""

for skill in "${SKILLS[@]}"; do
  if [ ! -d "$CANONICAL/$skill" ]; then
    echo "  SKIP: $CANONICAL/$skill does not exist"
    continue
  fi

  # Create target directory structure
  mkdir -p "$MIRROR/$skill"

  # Mirror with rsync (delete files in mirror that don't exist in canonical)
  if command -v rsync &> /dev/null; then
    rsync -a --delete --exclude='.DS_Store' --exclude='__pycache__' "$CANONICAL/$skill/" "$MIRROR/$skill/"
  else
    # Fallback: remove and copy
    rm -rf "$MIRROR/$skill"
    cp -r "$CANONICAL/$skill" "$MIRROR/$skill"
    find "$MIRROR/$skill" \( -name '.DS_Store' -o -name '__pycache__' \) -delete 2>/dev/null || true
  fi

  echo "  OK: $skill"
done

# --- Agent note ---
# Agents are NOT synced to .claude/agents/ because VS Code Copilot discovers
# agent frontmatter in ALL .md files, causing duplicate dropdown entries.
# Canonical agents live in .github/agents/ ONLY.
# Claude Code users: symlink or configure to use .github/agents/ directly.
echo ""
echo "Agents: .github/agents/ is canonical (NOT synced to .claude/agents/)"
echo "  VS Code Copilot discovers agent frontmatter in all .md files."
echo "  Syncing would create duplicate entries in the agent dropdown."

echo ""
echo "Done. Remember to: git add .claude/skills/"
echo ""
echo "Verify with:"
echo "  diff -r .github/skills/ .claude/skills/ --exclude='.DS_Store' --exclude='__pycache__'"
