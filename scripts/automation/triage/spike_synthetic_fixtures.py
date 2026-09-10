#!/usr/bin/env python3
"""Round 3.5.5 spike — synthetic fixture generator.

Generates 5 synthetic test cases under ~/scratch/triage-day38/synthetic/
for the extended battery. Each fixture probes a specific concern from
the spike review; the set is NOT exhaustive (that's the landing
commit's mutation-test responsibility).

Fixture spec authored by user during Option-C bounded extension.

Run:
    .venv/bin/python3 scripts/automation/triage/spike_synthetic_fixtures.py

Output: ~/scratch/triage-day38/synthetic/<name>.json   (5 files)
        ~/scratch/triage-day38/synthetic/MANIFEST.md   (provenance)

Each fixture is a JSON file with:
  {
    "name":            <fixture id>,
    "rationale":       <what behavior this probes>,
    "logs":            <the synthetic log content>,
    "expected_strategy_prefix": <e.g. "head:", "window:", "tail:">,
    "expected_anchor":          <anchor name expected to win or None>,
    "expected_in_window":       <true|false  — for test 4, may be false>,
    "expected_substrings_in_output":  [<list of substrings that MUST appear>],
    "expected_substrings_NOT_in_output": [<substrings that must NOT appear>],
  }

The spike runner consumes this contract directly.
"""
from __future__ import annotations

import json
from pathlib import Path

OUT = Path.home() / "scratch" / "triage-day38" / "synthetic"
OUT.mkdir(parents=True, exist_ok=True)


def write(fixture: dict) -> Path:
    path = OUT / f"{fixture['name']}.json"
    path.write_text(json.dumps(fixture, indent=2))
    return path


# Realistic-shape padding (dbt log noise) — used to position anchors
# at specific byte offsets without using a single repeated character.
DBT_NOISE = (
    "16:42:01  Running with dbt=1.5.0\n"
    "16:42:01  Registered adapter: snowflake=1.5.0\n"
    "16:42:02  Found 2141 models, 488 tests, 0 snapshots, 15 analyses, "
    "612 macros, 0 operations, 0 seed files, 89 sources, 0 exposures, "
    "0 metrics\n"
    "16:42:03  Concurrency: 4 threads (target='dev')\n"
    "16:42:04  Compiled node 'model.fbin.hub_customer' at "
    "macros/audit_helper/null_check.sql:14:8 → models/raw_vault/hub/"
    "hub_customer.sql:23:1 (binding=cte_src) success in 0.42s\n"
)


def pad_to_offset(prefix: str, target_offset: int) -> str:
    """Pad ``prefix`` with DBT_NOISE until length == target_offset."""
    if len(prefix) > target_offset:
        raise ValueError(
            f"prefix length {len(prefix)} exceeds target offset {target_offset}"
        )
    needed = target_offset - len(prefix)
    if needed == 0:
        return prefix
    repeats = (needed // len(DBT_NOISE)) + 1
    padding = (DBT_NOISE * repeats)[:needed]
    return prefix + padding


# -------------------------------------------------------------------------
# Fixture 1a — Anchor LAST byte at position 65,535
# (corrected from prior version where anchor START was at 65,535;
# the prior fixture exposed a real algorithm limitation now captured
# as synth_01a' below.)
# -------------------------------------------------------------------------
ANCHOR_HEAD_EDGE = "Database Error"  # 14 chars; ends at 65,535 → starts at 65,522
ANCHOR_START_BYTE_1A = 65_535 - len(ANCHOR_HEAD_EDGE) + 1   # = 65,522
prefix = pad_to_offset("16:42:00  start\n", ANCHOR_START_BYTE_1A)
logs_1a = prefix + ANCHOR_HEAD_EDGE + " in model dim_brand\n   missing column 'brand_key'\n"
write({
    "name": "synth_01a_anchor_ends_at_65535",
    "rationale": (
        "Anchor LAST byte at position 65,535 — anchor fully fits inside "
        "logs[:65_536]. Probes Rule 3 boundary at its true upper edge: "
        "anchor_position=65,522 < HEAD_BOUNDARY (65,536) → first 65,536B "
        "returned → anchor preserved intact."
    ),
    "logs": logs_1a,
    "expected_strategy_prefix": "head:",
    "expected_anchor": "Database Error",
    "expected_in_window": True,
    "expected_substrings_in_output": [ANCHOR_HEAD_EDGE],
    "expected_substrings_NOT_in_output": [],
})

# -------------------------------------------------------------------------
# Fixture 1a' — Boundary-spanning anchor (anchor STARTS at byte 65,535)
# Known-failing edge case: Rule 3 returns logs[:65_536]; anchor at byte
# 65,535 is clipped to just its first byte "D". Documented limitation;
# landing commit's mutation tests reference this as Mut_R3_boundary.
# -------------------------------------------------------------------------
prefix = pad_to_offset("16:42:00  start\n", 65_535)
logs_1a_prime = prefix + ANCHOR_HEAD_EDGE + " in model dim_brand\n   missing column 'brand_key'\n"
write({
    "name": "synth_01a_prime_anchor_starts_at_65535_BOUNDARY_SPANNING",
    "rationale": (
        "KNOWN-FAILING by design. Anchor FIRST byte at position 65,535. "
        "Rule 3 returns logs[:65_536]; anchor occupies bytes 65,535–65,548, "
        "so output contains only the first byte ('D'). Algorithm strategy "
        "tag is `head:Database Error` (Rule 3 fired), but the anchor "
        "substring is split across the head-window cut. "
        "DOCUMENTED LIMITATION — preserved as a regression detector. If "
        "Day-6+ backtest evidence shows >5% of real failures have anchors "
        "spanning byte 65,535, the algorithm change is justified at that "
        "point. Until then: known limitation, mutation test exists for CI "
        "visibility (Mut_R3_boundary)."
    ),
    "logs": logs_1a_prime,
    "expected_strategy_prefix": "head:",
    "expected_anchor": "Database Error",
    # Per contract: behavior IS exactly the documented limitation. The
    # algorithm picks the right strategy and the right anchor name; what
    # fails is preserving the anchor substring in output. We mark this
    # fixture as expected-FAIL-on-substring-presence so the runner
    # registers it as a known limitation, not an unexpected fail.
    "expected_in_window": False,
    "expected_substrings_in_output": [],   # we don't assert anchor substring present
    "expected_substrings_NOT_in_output": [],
    "ground_truth_actionable_error": ANCHOR_HEAD_EDGE,  # this is what the algorithm CAN'T preserve here
})

# -------------------------------------------------------------------------
# Fixture 1b — Anchor at byte 65,536 (exactly at HEAD_BOUNDARY)
# -------------------------------------------------------------------------
prefix = pad_to_offset("16:42:00  start\n", 65_536)
logs_1b = prefix + ANCHOR_HEAD_EDGE + "\n   missing column 'brand_key'\n"
write({
    "name": "synth_01b_anchor_at_65536",
    "rationale": (
        "Anchor at byte 65,536 = HEAD_BOUNDARY exactly. Spec: "
        "`anchor_position < HEAD_BOUNDARY` → strict less-than → fails "
        "→ falls through to Rule 4 centered window. This is the "
        "boundary-condition test; anchor at exactly 65,536 should NOT "
        "use head strategy."
    ),
    "logs": logs_1b,
    "expected_strategy_prefix": "window:",
    "expected_anchor": "Database Error",
    "expected_in_window": True,
    "expected_substrings_in_output": [ANCHOR_HEAD_EDGE],
    "expected_substrings_NOT_in_output": [],
})

# -------------------------------------------------------------------------
# Fixture 1c — Anchor at byte 65,537 (just above HEAD_BOUNDARY)
# -------------------------------------------------------------------------
prefix = pad_to_offset("16:42:00  start\n", 65_537)
logs_1c = prefix + ANCHOR_HEAD_EDGE + "\n   missing column 'brand_key'\n"
write({
    "name": "synth_01c_anchor_at_65537",
    "rationale": (
        "Anchor at byte 65,537 — first byte past HEAD_BOUNDARY. Probes "
        "Rule 4: anchor_position >= HEAD_BOUNDARY → centered ±16KB window. "
        "Output should contain the anchor near the center of the window."
    ),
    "logs": logs_1c,
    "expected_strategy_prefix": "window:",
    "expected_anchor": "Database Error",
    "expected_in_window": True,
    "expected_substrings_in_output": [ANCHOR_HEAD_EDGE],
    "expected_substrings_NOT_in_output": [],
})

# -------------------------------------------------------------------------
# Fixture 2 — Multi-anchor at different positions (earliest wins)
# -------------------------------------------------------------------------
ANCHOR_EARLY = "Database Error in model dim_pos"
ANCHOR_LATE = "Encountered an error: cascade from upstream model failure"
prefix_early = pad_to_offset("16:42:00  start\n", 5_000)
mid_pad = pad_to_offset("", 80_000 - 5_000 - len(ANCHOR_EARLY) - 1)
trailing = (
    ANCHOR_LATE + "\n"
    + DBT_NOISE * 3
)
logs_2 = (
    prefix_early
    + ANCHOR_EARLY + "\n"
    + mid_pad
    + trailing
)
write({
    "name": "synth_02_multi_anchor_earliest_wins",
    "rationale": (
        "Multi-anchor payload: `Database Error` at byte 5,000 and "
        "`Encountered an error:` at byte ~80,000. Per Rule 2 spec, "
        "earliest-position-wins across ALL anchors (not list-order-wins). "
        "Database Error wins (byte 5,000 < 80,000). Rule 3 fires "
        "(5,000 < 65,536) → first 64KB returned. Encountered an error: "
        "(at byte ~80,000) is OUTSIDE the returned window and MUST NOT "
        "appear in output. This is the spec-design-notes test: "
        "earliest-position-only sidesteps cross-position selection rules."
    ),
    "logs": logs_2,
    "expected_strategy_prefix": "head:",
    "expected_anchor": "Database Error",
    "expected_in_window": True,
    "expected_substrings_in_output": [ANCHOR_EARLY],
    "expected_substrings_NOT_in_output": [ANCHOR_LATE],
})

# -------------------------------------------------------------------------
# Fixture 3 — No-anchor infrastructure failure (OOM-killed pattern)
# -------------------------------------------------------------------------
OOM_LINE = "oom-killed: process exceeded memory limit (cgroup=dbt-runner-7)\n"
# Repeat to ~100KB
oom_lines_needed = (100 * 1024) // len(OOM_LINE) + 1
logs_3 = OOM_LINE * oom_lines_needed
# Tail-marker for verification: insert a unique sentinel near end so we
# can prove Rule 5 returned exactly the last 65,536 bytes.
SENTINEL_TAIL = "OOM_TAIL_SENTINEL_LAST_4KB_MARKER\n"
logs_3 = logs_3[: -len(SENTINEL_TAIL)] + SENTINEL_TAIL
write({
    "name": "synth_03_no_anchor_oom_pattern",
    "rationale": (
        "No specific anchor present (no `Encountered an error:`, no "
        "`Database Error`, etc.). Content is ~100KB of OOM-kill messages "
        "simulating infrastructure failure where dbt didn't emit a "
        "recognized error keyword. Probes Rule 5: tail fallback "
        "(last 65,536 bytes), strategy tag `tail:no_anchor`. Sentinel "
        "near end of input must appear in output (proves last-N bytes "
        "returned, not first-N)."
    ),
    "logs": logs_3,
    "expected_strategy_prefix": "tail:",
    "expected_anchor": None,
    "expected_in_window": True,  # Rule 5 IS the intended behavior
    "expected_substrings_in_output": [SENTINEL_TAIL.strip()],
    "expected_substrings_NOT_in_output": [],
})

# -------------------------------------------------------------------------
# Fixture 4 — Pathological repeated anchor in string-literal CSV context
# (the critical test — designed to potentially FAIL the binary criterion)
# -------------------------------------------------------------------------
# Simulate a dbt seed-file dump where the CSV data rows contain the words
# "Database Error" as legitimate data (e.g., an error_message_catalog seed).
# 50 occurrences in CSV rows starting at byte 100; real Compilation Error
# at byte 80,000.
CSV_ROW = (
    '"row_{i:03d}","Database Error: missing primary key","ERR_{i:04d}",'
    '"2025-01-15 09:30:00"\n'
)
csv_block = "".join(CSV_ROW.format(i=i) for i in range(50))  # 50 rows
prefix_4 = pad_to_offset("16:42:00  start dbt seed\n", 100)
# After CSV block, pad to byte 80,000, then place real Compilation Error
csv_section = prefix_4 + csv_block
real_error = "Compilation Error in model stg_pos_fb_invoice (incompatible type)"
mid_pad_4 = pad_to_offset("", 80_000 - len(csv_section) - 1)
logs_4 = (
    csv_section
    + mid_pad_4
    + real_error + "\n"
    + "  at: models/staging/stg_pos_fb_invoice.sql:23:4\n"
    + DBT_NOISE * 2
)
write({
    "name": "synth_04_pathological_csv_anchor",
    "rationale": (
        "PATHOLOGICAL CASE — designed to potentially FAIL spike criterion. "
        "Simulates dbt seed file containing 'Database Error' as legitimate "
        "CSV row data (50 occurrences starting byte 100). Real actionable "
        "error is 'Compilation Error in model stg_pos_fb_invoice' at byte "
        "~80,000. Per current spec (earliest-position-wins): Database Error "
        "at byte ~100 wins → Rule 3 head window → first 64KB returned → "
        "real Compilation Error at byte 80,000 is OUTSIDE returned window. "
        "Expected algorithm output: strategy `head:Database Error`, "
        "real Compilation Error NOT in output. Per spike spec: if this "
        "fixture fails the in-window criterion (which it WILL by design), "
        "report as design-input data; do NOT tune algorithm."
    ),
    "logs": logs_4,
    # Per spec: algorithm WILL pick Database Error (earliest); output is
    # head-window; Compilation Error at byte 80,000 is OUTSIDE.
    "expected_strategy_prefix": "head:",
    "expected_anchor": "Database Error",
    # ground-truth "actionable error" for the binary criterion is the
    # Compilation Error — which the algorithm will NOT preserve.
    "expected_in_window": False,
    "expected_substrings_in_output": ["Database Error"],
    "expected_substrings_NOT_in_output": [real_error],
    "ground_truth_actionable_error": real_error,
})

# -------------------------------------------------------------------------
# Fixture 5 — Empty/short payload boundaries (3 sub-cases, single file)
# -------------------------------------------------------------------------
write({
    "name": "synth_05_empty_short_boundaries",
    "rationale": (
        "Three sub-cases probing Rule 1 (empty/short noop) and Rule 5 "
        "(short-no-anchor → tail). Sub-cases evaluated independently; "
        "fixture passes only if all three sub-cases match expectations."
    ),
    "sub_cases": [
        {
            "name": "5a_empty",
            "logs": "",
            "expected_strategy": "noop:empty",
            "expected_output": "",
        },
        {
            "name": "5b_short_exactly_1024",
            "logs": "x" * 1024,
            "expected_strategy": "noop:short",
            "expected_output": "x" * 1024,
        },
        {
            "name": "5c_1025_no_anchor",
            "logs": "x" * 1025,
            # 1025 > SHORT_LOG_THRESHOLD (1024), no anchor → Rule 5 tail
            # tail of "xxx...x" with len=1025 → last 65,536 bytes = whole string
            "expected_strategy": "tail:no_anchor",
            "expected_output": "x" * 1025,
        },
    ],
})


# -------------------------------------------------------------------------
# MANIFEST
# -------------------------------------------------------------------------
MANIFEST = """# Round 3.5.5 Spike — Synthetic Fixture Manifest

Generated by: `scripts/automation/triage/spike_synthetic_fixtures.py`
Date: 2026-06-05
Purpose: Bounded extension of the 7-real-payload spike with 5
synthetic fixtures probing specific concerns from spike review.

Each fixture is intentionally not maximally adversarial — they're
empirically motivated by gaps in the 7-payload corpus, not designed
to break the algorithm for its own sake. Exception: Fixture 4
(pathological CSV anchor) is designed to potentially fail and is
preserved as design-input data per spec.

## Fixtures

| # | Name | Probes | Expected outcome |
|---|------|--------|------------------|
| 1a | synth_01a_anchor_ends_at_65535 | Rule 3 head-boundary upper edge (anchor LAST byte at 65,535) | `head:Database Error`, anchor preserved intact |
| 1a' | synth_01a_prime_anchor_starts_at_65535_BOUNDARY_SPANNING | **KNOWN-FAILING by design** — anchor FIRST byte at 65,535 → spans head-window cut | `head:Database Error`, anchor substring NOT preserved (clipped). Contract: expected_in_window=False; landing commit's mutation test `Mut_R3_boundary` references this fixture |
| 1b | synth_01b_anchor_at_65536 | Rule 3/4 strict-less-than boundary | `window:Database Error`, anchor present |
| 1c | synth_01c_anchor_at_65537 | Rule 4 just above head boundary | `window:Database Error`, anchor present |
| 2  | synth_02_multi_anchor_earliest_wins | Rule 2 earliest-position-only (cross-position-scoping lesson) | `head:Database Error`, late anchor NOT in output |
| 3  | synth_03_no_anchor_oom_pattern | Rule 5 tail fallback on no-recognized-anchor input | `tail:no_anchor`, tail sentinel in output |
| 4  | synth_04_pathological_csv_anchor | **DOCUMENTED LIMITATION** — earliest-position picks data-row "Database Error" over real "Compilation Error" | `head:Database Error`, real Compilation Error NOT in output. Contract: in_window=False (algorithm misses actionable error by design) |
| 5  | synth_05_empty_short_boundaries | Rule 1 empty + Rule 1 short + Rule 5 short-no-anchor | 3 sub-cases match expected strategy/output exactly |

## Fixture 1a' design note

Boundary-spanning fixture kept as regression detector. Algorithm does
NOT preserve anchor substring when anchor's first byte lands at byte
65,535 (or any byte where `start + len(anchor) > HEAD_WINDOW`). This
is a Rule 3 limitation. Fix would require extending head window by
`max(len(a) for a in ERROR_ANCHORS)` = 34 bytes (`Traceback (most
recent call last):`). Deferred until backtest evidence justifies the
fix cost.

## Fixture 4 design note

This fixture encodes a real concern: dbt seed files often contain
error-keyword strings as legitimate row data. The current algorithm's
earliest-position-only tie-break is by design (per spec design notes:
"Earliest-position wins; the list order is just an enumeration of which
strings to look for, not a precedence ranking") and per the Round-3
cross-position scoping lesson (`cd9876ee`) — adding a "skip anchors in
CSV context" or "prefer anchors near end" rule would re-introduce the
cross-position selection complexity that was the original failure mode.

If Fixture 4 fails the binary in-window criterion, that is empirical
evidence that the simple algorithm has a known limitation in seed-file-
heavy dbt projects. The decision then becomes: accept the limitation
(document + land), or resume methodology track with this fixture as
starting point for a more nuanced design.

Do NOT tune the algorithm in response to a Fixture 4 failure. Tuning
is overfitting to one synthetic fixture; the discipline is to surface
the failure as design data.

## Provenance

- Generator script: `scripts/automation/triage/spike_synthetic_fixtures.py`
- Padding source: `DBT_NOISE` constant (5 realistic dbt log lines, ~512 B per cycle)
- Anchor strings: from spec ERROR_ANCHORS list verbatim
- CSV row pattern: synthetic, approximating real dbt seed file shape
  (could be replaced with extracted real seed content if needed; not
  required for the binary spike criterion)
- All fixtures: file-system only (`~/scratch/triage-day38/synthetic/`).
  NOT committed to repo (same provenance pattern as the 7 real
  payloads under `~/scratch/triage-day4/`).
"""
(OUT / "MANIFEST.md").write_text(MANIFEST)

print(f"Generated 5 fixture files + MANIFEST under {OUT}")
for f in sorted(OUT.glob("*.json")):
    print(f"  {f.name}  ({f.stat().st_size} B)")
