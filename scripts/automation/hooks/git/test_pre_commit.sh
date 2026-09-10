#!/usr/bin/env bash
# test_pre_commit.sh — logic regression for entry-7 enforcement hook.
#
# Runs hook against six synthetic staging scenarios in an isolated
# scratch git repo. Does NOT touch the parent repo's git state.
#
# Pure bash + git (no python dependency) to keep the harness portable.
#
# Usage: bash scripts/automation/hooks/git/test_pre_commit.sh
# Exit:  0 = all 6 cases pass; non-zero = case failed (output shows which)

set -euo pipefail

HOOK_SRC="$(cd "$(dirname "$0")" && pwd)/pre-commit"
[ -x "$HOOK_SRC" ] || { echo "ERROR: hook not found or not executable: $HOOK_SRC"; exit 2; }

SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

cd "$SCRATCH"
git init -q
git config user.email "test@test"
git config user.name "test"
git config core.hooksPath "$(dirname "$HOOK_SRC")"

# Pin an explicit, known base branch rather than relying on
# init.defaultBranch (which varies across git installs) or on
# `git checkout -` history staying unbroken across cases. Each case
# returns to "testbase" by name, not relatively.
git checkout -q -b testbase

# Init commit: create required-doc + an existing fixture file (used by
# C4's rename setup and C5's modification case).
mkdir -p docs/triage-agent scripts/automation/src/triage docs/triage-agent/fixtures
echo "checklist" > docs/triage-agent/phase-2-progress-log.md
echo "existing-fixture" > docs/triage-agent/fixtures/existing.json
git add . && git commit -q -m "init"

PASS=0; FAIL=0
expect() {
    local name="$1" expected_exit="$2" actual_exit="$3"
    if [ "$expected_exit" -eq "$actual_exit" ]; then
        echo "  PASS  $name (exit=$actual_exit)"
        PASS=$((PASS+1))
    else
        echo "  FAIL  $name (expected exit=$expected_exit, got $actual_exit)"
        FAIL=$((FAIL+1))
    fi
}

run_hook() {
    set +e
    "$HOOK_SRC" >/dev/null 2>&1
    local rc=$?
    set -e
    echo $rc
}

# Case wrap pattern (applies to all 6):
#   git checkout -q -b cN testbase   # branch FROM the pinned base, by name
#   ... stage scenario ...
#   expect ... "$(run_hook)"
#   reset_to_base cN                 # discard staged + untracked, return to base
#
# reset_to_base discards ALL staged + working-tree state on the current
# branch BEFORE switching. Without this, git's documented "carry staged
# changes across checkout" behavior leaks per-case staging into the
# pinned base branch's index, polluting subsequent cases. (E.g., C2's
# staged checklist mod would survive into testbase's index, causing C3
# to see checklist+fixtures-new-file and incorrectly PASS.)
reset_to_base() {
    local branch="$1"
    git reset --hard -q HEAD
    git clean -fdq
    git checkout -q testbase
    git branch -D "$branch" -q
}

# Case 1 — triage-src new file alone → REJECT (exit 1)
git checkout -q -b c1 testbase
mkdir -p scripts/automation/src/triage
echo "new" > scripts/automation/src/triage/new_helper.py
git add scripts/automation/src/triage/new_helper.py
expect "c1: triage-src new file alone" 1 "$(run_hook)"
reset_to_base c1

# Case 2 — triage-src new file + required-doc staged → PASS (exit 0)
git checkout -q -b c2 testbase
mkdir -p scripts/automation/src/triage
echo "new" > scripts/automation/src/triage/new_helper.py
echo "updated" >> docs/triage-agent/phase-2-progress-log.md
git add scripts/automation/src/triage/new_helper.py docs/triage-agent/phase-2-progress-log.md
expect "c2: triage-src new + required-doc" 0 "$(run_hook)"
reset_to_base c2

# Case 3 — fixtures new file alone → REJECT (exit 1) — D1-A coverage
git checkout -q -b c3 testbase
echo '{"new":1}' > docs/triage-agent/fixtures/new_payload.json
git add docs/triage-agent/fixtures/new_payload.json
expect "c3: fixtures new file alone (D1-A)" 1 "$(run_hook)"
reset_to_base c3

# Case 4 — fixtures rename INTO path alone → REJECT (exit 1) — D2.a AR-filter proof
# This case proves --diff-filter=AR catches `git mv` into watched paths.
# If git's rename detection (-M) decomposes the move into A+D instead of R,
# the test cannot exercise the AR filter and MUST fail loud — silently
# downgrading to "well, it kinda passed" defeats the whole purpose.
#
# Cleanup uses branch-abandon (checkout testbase + branch -D c4), NOT
# reset --hard HEAD~N arithmetic — the latter is fragile against the
# exact number of setup commits this case happens to make.
git checkout -q -b c4 testbase

# Pre-existing fixture must be large enough for git's similarity threshold
# (-M default ~50% similarity; tiny files are flaky). 500 deterministic
# bytes from /dev/zero piped through tr — pure bash, no python dependency.
head -c 500 /dev/zero | tr '\0' 'A' > docs/triage-agent/fixtures/existing.json
git add docs/triage-agent/fixtures/existing.json
git commit -q -m "c4 setup: substantial fixture"

mkdir -p elsewhere
git mv docs/triage-agent/fixtures/existing.json elsewhere/existing.json
git commit -q -m "c4 setup: move out"

# The move-back: this is the staged state the hook is evaluated against.
git mv elsewhere/existing.json docs/triage-agent/fixtures/existing.json

# Pre-check: did git actually detect this as a RENAME (R), or did it
# decompose into A+D? If A+D, --diff-filter=AR won't see it via R, and
# while -A would still catch the destination, this test would no longer
# be proving what it claims. Fail loud rather than silently pass.
#
# IMPORTANT: do NOT use a pathspec (`-- docs/.../fixtures/`) here.
# Cross-boundary renames (source outside pathspec, destination inside)
# are dropped by pathspec filtering — verified empirically. The hook
# itself uses no pathspec, so this pre-check must mirror that. Use
# --name-status to see R100 entries with both source and destination.
RENAME_STATUS=$(git diff --cached --diff-filter=R -M --name-status || echo "")
if [ -z "$RENAME_STATUS" ] || ! echo "$RENAME_STATUS" | grep -q "docs/triage-agent/fixtures/"; then
    echo "  FAIL  c4 SETUP: git did not detect the move as a rename (R) into fixtures/."
    echo "        Cannot prove AR filter. Likely cause: git rename-detection"
    echo "        similarity threshold not met (file too small or too different)."
    echo "        Output of 'git diff --cached --diff-filter=R -M --name-status':"
    echo "          $RENAME_STATUS"
    FAIL=$((FAIL+1))
else
    expect "c4: fixtures rename INTO path (D2.a AR)" 1 "$(run_hook)"
fi

reset_to_base c4

# Case 5 — existing-file modification (score-neutral) → PASS (exit 0)
git checkout -q -b c5 testbase
echo "more" >> docs/triage-agent/fixtures/existing.json
git add docs/triage-agent/fixtures/existing.json
expect "c5: existing-file modification (score-neutral)" 0 "$(run_hook)"
reset_to_base c5

# Case 6 — triage-src new file + required-doc DELETION → REJECT (exit 1)
# DA finding F-6 (orig M-6): --diff-filter=AM rejects the deletion case. A bare
# --name-only check would match the deletion and silently satisfy
# entry-7 while removing the scoring surface. This case proves the
# hook closes that gap.
git checkout -q -b c6 testbase
mkdir -p scripts/automation/src/triage
echo "new" > scripts/automation/src/triage/new_helper.py
git rm -q docs/triage-agent/phase-2-progress-log.md
git add scripts/automation/src/triage/new_helper.py
expect "c6: triage-src new + required-doc DELETION (M-6)" 1 "$(run_hook)"
reset_to_base c6

echo
echo "Result: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
