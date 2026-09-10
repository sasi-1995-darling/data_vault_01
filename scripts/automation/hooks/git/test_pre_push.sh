#!/usr/bin/env bash
# test_pre_push.sh — logic regression for pre-push DA enforcement hook.
#
# Runs hook against 14 synthetic scenarios in an isolated scratch git
# repo. Does NOT touch the parent repo's git state.
#
# Invokes the hook via SYNTHETIC STDIN (not real `git push`) because:
#   - Faithfully tests our hook's handling of the documented stdin format
#   - No bare-remote setup / ref management / network round-trips needed
#   - Lets us exercise edge cases (deletion, new-branch, multi-ref)
#     without needing real remote refs
#   - Mirrors test_pre_commit.sh's spirit: synthetic scenarios in
#     isolated scratch repo
#
# Pure bash + git (no python dependency) to keep the harness portable.
#
# Scenarios (14, see Commit C locked spec):
#   c1  docs-only push <200 LOC                      → PASS
#   c2  docs-only push >200 LOC                      → REJECT (Rule 3)
#   c3  c2 + valid `da-completed: <value>` in HEAD   → PASS (satisfaction)
#   c4  new triage .py (ZERO smell tokens fixture)   → REJECT (Rule 1 isolation)
#   c5  c4 + valid token in HEAD                     → PASS
#   c6  modified triage .py w/ `def _is_*` predicate → REJECT (Rule 2)
#   c7  modified triage .py, NO smell tokens         → PASS (Rule 2 negative)
#   c8  multi-commit: agg <200, ONE commit >200      → REJECT (per-commit)
#   c9  empty stdin (already up-to-date)             → PASS
#   c10 branch deletion (local_sha = 0…)             → SKIP, PASS
#   c11 multi-ref new-branch push                    → gates every ref
#   c12 fixture-only push >200 LOC JSON              → PASS (C-3 exclusion)
#   c13 token in non-HEAD commit (HEAD also has one) → REJECT (C-4 asymmetry)
#   c14 bare `da-completed:` (no value)              → REJECT (C-4 value req)
#
# Harness triangle (4 / 6 / 7) locks the Rule 1 / Rule 2 / Rule 1-negative
# discrimination — see new_helper.py inline comment in c4 setup.
#
# Usage: bash scripts/automation/hooks/git/test_pre_push.sh
# Exit:  0 = all 14 cases pass; non-zero = case failed (output shows which)

set -euo pipefail

HOOK_SRC="$(cd "$(dirname "$0")" && pwd)/pre-push"
[ -x "$HOOK_SRC" ] || { echo "ERROR: hook not found or not executable: $HOOK_SRC"; exit 2; }

ZERO="0000000000000000000000000000000000000000"

SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

cd "$SCRATCH"
git init -q
git config user.email "test@test"
git config user.name "test"
# NOTE: deliberately do NOT set core.hooksPath in the scratch repo. The
# harness invokes the pre-push hook directly via synthetic stdin (not via
# real `git push`), so git's hook plumbing is unused. Setting hooksPath
# would activate the sibling pre-commit hook (entry-7 enforcement) during
# `git commit` calls in test setup, which would reject c4/c5's new triage
# fixtures and the init commit itself. The pre-push hook reads git state
# directly (rev-list, show, log) without needing to be wired into git's
# hook machinery. Mirror this discipline if adding a new test harness.

# Pin an explicit known base branch (same pattern as test_pre_commit.sh)
git checkout -q -b base

# Init commit: pre-existing structure so we can test MODIFIED-file rules.
#   - docs/triage-agent/some_doc.md  (target for docs LOC tests)
#   - scripts/automation/src/triage/existing.py  (target for Rule 2 tests)
mkdir -p docs/triage-agent scripts/automation/src/triage
echo "init" > docs/triage-agent/some_doc.md
cat > scripts/automation/src/triage/existing.py <<'EOF'
def normal_function():
    return 1
EOF
git add . && git commit -q -m "init"
INIT_SHA=$(git rev-parse HEAD)

# Simulate a remote tracking branch so `--not --remotes` excludes init in
# the new-branch path (c11). Without this, `rev-list new_branch --not --remotes`
# would include init commit, which DID add existing.py under triage subtree
# — Rule 1 would false-fire on init.
git update-ref refs/remotes/origin/base "$INIT_SHA"

PASS=0; FAIL=0
expect() {
    local name="$1" expected_exit="$2" actual_exit="$3"
    if [ "$expected_exit" -eq "$actual_exit" ]; then
        echo "  PASS  $name (exit=$actual_exit)"
        PASS=$((PASS+1))
    else
        echo "  FAIL  $name (expected exit=$expected_exit, got $actual_exit)"
        echo "        --- hook output ---"
        sed 's|^|        |' /tmp/pre_push_test_out 2>/dev/null || true
        echo "        ---"
        FAIL=$((FAIL+1))
    fi
}

# Run hook with synthetic stdin (single-ref).
# Captures output to /tmp/pre_push_test_out for failure diagnostics.
run_hook() {
    local local_ref="$1" local_sha="$2" remote_ref="$3" remote_sha="$4"
    set +e
    echo "$local_ref $local_sha $remote_ref $remote_sha" \
        | "$HOOK_SRC" origin "git@host:repo.git" >/tmp/pre_push_test_out 2>&1
    local rc=$?
    set -e
    echo $rc
}

# Run hook with multi-line synthetic stdin (multi-ref push).
run_hook_multi() {
    local input="$1"
    set +e
    printf "%s\n" "$input" | "$HOOK_SRC" origin "git@host:repo.git" >/tmp/pre_push_test_out 2>&1
    local rc=$?
    set -e
    echo $rc
}

# Reset to pinned base, discarding all per-case state.
# (Same discipline as test_pre_commit.sh::reset_to_base.)
reset_to_base() {
    git reset --hard -q "$INIT_SHA"
    git clean -fdq
    git checkout -q base
    # Delete all non-base branches in one sweep
    for b in $(git branch --format='%(refname:short)' | grep -v '^base$' || true); do
        git branch -D "$b" -q 2>/dev/null || true
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 1 — docs-only push <200 LOC → PASS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git checkout -q -b c1 base
for i in $(seq 1 50); do echo "line $i"; done >> docs/triage-agent/some_doc.md
git add . && git commit -q -m "c1: small docs update"
expect "c1: docs-only <200 LOC" 0 \
    "$(run_hook "refs/heads/c1" "$(git rev-parse HEAD)" "refs/heads/c1" "$INIT_SHA")"
reset_to_base

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 2 — docs-only push >200 LOC → REJECT (Rule 3)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git checkout -q -b c2 base
for i in $(seq 1 250); do echo "prose line $i with content"; done >> docs/triage-agent/some_doc.md
git add . && git commit -q -m "c2: large docs update"
expect "c2: docs-only >200 LOC (Rule 3)" 1 \
    "$(run_hook "refs/heads/c2" "$(git rev-parse HEAD)" "refs/heads/c2" "$INIT_SHA")"
reset_to_base

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 3 — c2 + valid `da-completed: <value>` in HEAD → PASS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git checkout -q -b c3 base
for i in $(seq 1 250); do echo "prose line $i with content"; done >> docs/triage-agent/some_doc.md
git add . && git commit -q -m "c3: large docs update

da-completed: reviewed the prose, no defensive predicates added"
expect "c3: c2 + valid token → satisfaction" 0 \
    "$(run_hook "refs/heads/c3" "$(git rev-parse HEAD)" "refs/heads/c3" "$INIT_SHA")"
reset_to_base

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 4 — NEW python under triage (ZERO smell tokens) → REJECT (Rule 1)
#
# CRITICAL fixture discipline: this file MUST contain zero smell tokens.
# If it had any, the test would pass via Rule 2 firing, hiding any
# regression of Rule 1 — the C-1 lesson in miniature ("green harness
# asking the wrong question"). See locked spec harness triangle.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git checkout -q -b c4 base
cat > scripts/automation/src/triage/new_helper.py <<'EOF'
# Fixture for pre-push hook c4 — tests Rule 1 (new triage code → trigger)
# in isolation from Rule 2 (smell tokens in modifications).
# DO NOT add smell tokens (def _is_*, def _has_*, _usable, _valid,
# re.compile/match/search, isinstance...else bool) to this fixture.
# See Commit C lessons-learned cross-ref and harness triangle (c4/c6/c7).
def hello():
    return 1
EOF
git add . && git commit -q -m "c4: add helper"
expect "c4: NEW triage py (Rule 1, zero-token fixture)" 1 \
    "$(run_hook "refs/heads/c4" "$(git rev-parse HEAD)" "refs/heads/c4" "$INIT_SHA")"
reset_to_base

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 5 — c4 + valid token in HEAD → PASS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git checkout -q -b c5 base
cat > scripts/automation/src/triage/new_helper.py <<'EOF'
def hello():
    return 1
EOF
git add . && git commit -q -m "c5: add helper

da-completed: trivial 2-line file, no logic to audit"
expect "c5: NEW triage py + valid token → satisfaction" 0 \
    "$(run_hook "refs/heads/c5" "$(git rev-parse HEAD)" "refs/heads/c5" "$INIT_SHA")"
reset_to_base

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 6 — MODIFIED triage py with new _is_* predicate → REJECT (Rule 2)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git checkout -q -b c6 base
cat >> scripts/automation/src/triage/existing.py <<'EOF'


def _is_valid_input(x):
    return x is not None
EOF
git add . && git commit -q -m "c6: add defensive predicate"
expect "c6: MODIFIED triage w/ _is_* predicate (Rule 2)" 1 \
    "$(run_hook "refs/heads/c6" "$(git rev-parse HEAD)" "refs/heads/c6" "$INIT_SHA")"
reset_to_base

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 7 — MODIFIED triage py, NO smell tokens → PASS (Rule 2 negative)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git checkout -q -b c7 base
cat >> scripts/automation/src/triage/existing.py <<'EOF'


def add(a, b):
    return a + b
EOF
git add . && git commit -q -m "c7: add ordinary function"
expect "c7: MODIFIED triage, no smell tokens" 0 \
    "$(run_hook "refs/heads/c7" "$(git rev-parse HEAD)" "refs/heads/c7" "$INIT_SHA")"
reset_to_base

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 8 — Multi-commit: aggregate <200, ONE commit alone >200 → REJECT
# (Locks per-commit evaluation: a single qualifying commit triggers the
# push, even if the aggregate range is small.)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git checkout -q -b c8 base
for i in $(seq 1 30); do echo "small line $i"; done >> docs/triage-agent/some_doc.md
git add . && git commit -q -m "c8a: small"
for i in $(seq 1 250); do echo "big line $i"; done >> docs/triage-agent/some_doc.md
git add . && git commit -q -m "c8b: large"
for i in $(seq 1 10); do echo "tail line $i"; done >> docs/triage-agent/some_doc.md
git add . && git commit -q -m "c8c: small tail"
expect "c8: multi-commit one >200 LOC (per-commit rule)" 1 \
    "$(run_hook "refs/heads/c8" "$(git rev-parse HEAD)" "refs/heads/c8" "$INIT_SHA")"
reset_to_base

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 9 — Empty stdin (push when already up-to-date) → PASS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set +e
echo -n "" | "$HOOK_SRC" origin "git@host:repo.git" >/tmp/pre_push_test_out 2>&1
c9_rc=$?
set -e
expect "c9: empty stdin (already up-to-date)" 0 "$c9_rc"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 10 — Branch deletion (local_sha = all zeros) → SKIP, PASS
# (Per `man githooks`: deletions arrive with local_ref="(delete)" and
# local_sha=ZERO. We SKIP these refs entirely — nothing being pushed
# to gate. C-2 fix iii.)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
expect "c10: branch deletion (local_sha=ZERO)" 0 \
    "$(run_hook "(delete)" "$ZERO" "refs/heads/old-branch" "$INIT_SHA")"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 11 — Multi-ref new-branch push → gates EVERY ref (C-2 fix i)
# Two new branches (remote_sha=ZERO for both); c11a passes, c11b fails.
# Hook must process both lines from stdin and reject on any failure.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git checkout -q -b c11a base
echo "small change" >> docs/triage-agent/some_doc.md
git add . && git commit -q -m "c11a: small"
C11A_SHA=$(git rev-parse HEAD)
git checkout -q base
git checkout -q -b c11b base
for i in $(seq 1 250); do echo "prose $i"; done >> docs/triage-agent/some_doc.md
git add . && git commit -q -m "c11b: big docs"
C11B_SHA=$(git rev-parse HEAD)
MULTI_STDIN="refs/heads/c11a $C11A_SHA refs/heads/c11a $ZERO
refs/heads/c11b $C11B_SHA refs/heads/c11b $ZERO"
expect "c11: multi-ref new-branch push (rejects on any ref)" 1 \
    "$(run_hook_multi "$MULTI_STDIN")"
git checkout -q base
git branch -D c11a c11b -q

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 12 — Fixture-only push >200 LOC JSON → PASS (C-3 fixture exclusion)
# (Commit-B style fixture re-emissions routinely add hundreds of `+` JSON
# lines. Docs LOC counter excludes non-`.md` files; fixtures have their
# own gates: idempotency tests, EXPECTED_BANDS.)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git checkout -q -b c12 base
mkdir -p docs/triage-agent/fixtures
{
    echo "{"
    for i in $(seq 1 250); do echo "  \"k$i\": \"v$i\","; done
    echo "  \"end\": 1"
    echo "}"
} > docs/triage-agent/fixtures/big.json
git add . && git commit -q -m "c12: big fixture JSON re-emission"
expect "c12: fixture-only >200 LOC JSON (C-3 exclusion)" 0 \
    "$(run_hook "refs/heads/c12" "$(git rev-parse HEAD)" "refs/heads/c12" "$INIT_SHA")"
reset_to_base

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 13 — Token in non-HEAD commit → REJECT (C-4 asymmetry lock)
#
# Setup: 2 commits, BOTH have da-completed token. HEAD has a valid
# token (satisfaction check would pass), but the non-HEAD commit ALSO
# has one (asymmetry violation). Without HEAD having a valid token,
# the test would short-circuit on "lacks token" and miss the asymmetry
# rule — same C-1 "green harness asking wrong question" failure mode.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git checkout -q -b c13 base
for i in $(seq 1 250); do echo "prose $i"; done >> docs/triage-agent/some_doc.md
git add . && git commit -q -m "c13a: big docs

da-completed: first commit reviewed"
echo "small" >> docs/triage-agent/some_doc.md
git add . && git commit -q -m "c13b: small follow-up

da-completed: HEAD also has token, but c13a still has stale one"
expect "c13: token in non-HEAD commit (C-4 asymmetry)" 1 \
    "$(run_hook "refs/heads/c13" "$(git rev-parse HEAD)" "refs/heads/c13" "$INIT_SHA")"
reset_to_base

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Case 14 — Bare `da-completed:` (no value) → REJECT (C-4 value required)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
git checkout -q -b c14 base
for i in $(seq 1 250); do echo "prose $i"; done >> docs/triage-agent/some_doc.md
git add . && git commit -q -m "c14: big docs

da-completed:"
expect "c14: bare da-completed: token (C-4 value required)" 1 \
    "$(run_hook "refs/heads/c14" "$(git rev-parse HEAD)" "refs/heads/c14" "$INIT_SHA")"
reset_to_base

echo
echo "Result: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
