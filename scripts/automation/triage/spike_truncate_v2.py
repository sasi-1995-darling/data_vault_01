#!/usr/bin/env python3
"""Round 3.5.5 spike — 5-rule truncate_logs algorithm against 7 P0.1 snapshots.

This is a SPIKE. Does not modify ``redact.py`` (HC-1 preserved).
Algorithm spec authored by Claude during senior-director assessment;
the 7-snapshot run IS the rigor. Binary pass/fail; no tuning.

Run:
    .venv/bin/python3 scripts/automation/triage/spike_truncate_v2.py

Reads:    ~/scratch/triage-day4/run_*.json   (7 payloads)
Writes:   ~/scratch/triage-day38/spike_results.json
Prints:   per-payload verdict + final binary verdict to stdout.

Decision tree post-run:
    PASS (7/7)   → propose landing commit + Round 3.5.5 close
    FAIL (<7/7)  → surface failure data; methodology track resumes
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Optional


# ---- Algorithm constants (verbatim from spec) ----------------------------
SHORT_LOG_THRESHOLD = 1024       # bytes; logs ≤ this are returned as-is
HEAD_WINDOW = 65_536             # bytes; first 64KB if anchor is in head
ANCHOR_WINDOW_HALF = 16_384      # bytes; ±16KB centered on anchor
TAIL_FALLBACK = 65_536           # bytes; last 64KB if no anchor
HEAD_BOUNDARY = 65_536           # bytes; head vs body/tail partition

# Specificity-ordered. Generics (generic_failed, generic_error_prefix)
# intentionally EXCLUDED — Cluster A failure mechanism was generic_failed
# beating specifics. See spec design notes for full rationale.
ERROR_ANCHORS: list[str] = [
    "Encountered an error:",
    "Traceback (most recent call last):",
    "Database Error",
    "Compilation Error",
    "Runtime Error",
]


# ---- Algorithm (verbatim implementation of spec) --------------------------
def truncate_logs_spike(logs: str) -> tuple[str, str]:
    """Returns (truncated_text, strategy_tag).

    Strategy tags: noop:empty | noop:short | head:<anchor>
                   | window:<anchor> | tail:no_anchor
    """
    # Rule 1: empty / short
    if not logs:
        return ("", "noop:empty")
    if len(logs) <= SHORT_LOG_THRESHOLD:
        return (logs, "noop:short")

    # Rule 2: find EARLIEST match across all specific anchors
    anchor_position: Optional[int] = None
    anchor_name: Optional[str] = None
    for anchor in ERROR_ANCHORS:
        idx = logs.find(anchor)
        if idx != -1 and (anchor_position is None or idx < anchor_position):
            anchor_position = idx
            anchor_name = anchor

    # Rule 3: anchor in head region → first HEAD_WINDOW bytes
    if anchor_position is not None and anchor_position < HEAD_BOUNDARY:
        return (logs[:HEAD_WINDOW], f"head:{anchor_name}")

    # Rule 4: anchor in body/tail → ±ANCHOR_WINDOW_HALF window
    if anchor_position is not None:
        start = max(0, anchor_position - ANCHOR_WINDOW_HALF)
        end = min(len(logs), anchor_position + ANCHOR_WINDOW_HALF)
        return (logs[start:end], f"window:{anchor_name}")

    # Rule 5: no specific anchor → tail fallback
    return (logs[-TAIL_FALLBACK:], "tail:no_anchor")


# ---- Ground-truth labeling (per spec §3.4 ground-truth protocol) ----------
def find_actionable_error(logs: str) -> Optional[tuple[str, int]]:
    """Earliest occurrence of any of the 5 specific anchors in the FULL log.

    Returns (anchor_name, position) or None if no specific anchor exists.
    """
    best: Optional[tuple[str, int]] = None
    for anchor in ERROR_ANCHORS:
        idx = logs.find(anchor)
        if idx != -1 and (best is None or idx < best[1]):
            best = (anchor, idx)
    return best


# ---- Per-payload runner ---------------------------------------------------
def extract_failing_step_logs(payload_path: Path) -> Optional[str]:
    """Extract logs from the LAST step (the failing dbt build step).

    Matches existing snapshot harness convention (generate_snapshots.py
    uses ``steps[-1]``). The P0.1 evidence table's "step 3" label is
    0-indexed (= 4th step = ``steps[3]`` = last for all 7 payloads).
    """
    raw = json.loads(payload_path.read_text())
    data = raw.get("data", raw)
    steps = data.get("run_steps", []) or []
    if not steps:
        return None
    return (steps[-1] or {}).get("logs") or ""


def evaluate_payload(payload_path: Path) -> dict:
    logs = extract_failing_step_logs(payload_path)
    if logs is None:
        return {
            "source": payload_path.name,
            "error": "no steps in payload",
            "verdict": "ERROR",
        }

    raw_bytes = len(logs)
    truncated, strategy = truncate_logs_spike(logs)
    out_bytes = len(truncated)
    ground_truth = find_actionable_error(logs)

    # Truncated-side anchor position (informational)
    truncated_anchor_pos = (
        truncated.find(ground_truth[0]) if ground_truth else None
    )
    in_window = ground_truth is not None and (ground_truth[0] in truncated)

    # Per-spec margin (informational only — not pass/fail)
    margin = None
    if in_window and truncated_anchor_pos is not None:
        margin = min(truncated_anchor_pos, out_bytes - truncated_anchor_pos - len(ground_truth[0]))

    return {
        "source": payload_path.name,
        "raw_bytes": raw_bytes,
        "strategy": strategy,
        "out_bytes": out_bytes,
        "ground_truth_anchor": ground_truth[0] if ground_truth else None,
        "ground_truth_pos_in_raw": ground_truth[1] if ground_truth else None,
        "anchor_pos_in_truncated": truncated_anchor_pos,
        "margin_to_nearest_edge": margin,
        "in_window": in_window,
        "verdict": "PASS" if in_window else "FAIL",
    }


# ---- Synthetic fixture evaluation ----------------------------------------
def _eval_sub_case(sub: dict) -> dict:
    """Evaluate a single sub-case from synth_05_empty_short_boundaries."""
    out, strategy = truncate_logs_spike(sub["logs"])
    strategy_ok = strategy == sub["expected_strategy"]
    output_ok = out == sub["expected_output"]
    return {
        "sub_name": sub["name"],
        "got_strategy": strategy,
        "expected_strategy": sub["expected_strategy"],
        "strategy_match": strategy_ok,
        "output_len_got": len(out),
        "output_len_expected": len(sub["expected_output"]),
        "output_match": output_ok,
        "verdict": "PASS" if (strategy_ok and output_ok) else "FAIL",
    }


def evaluate_synthetic(fixture_path: Path) -> dict:
    """Evaluate one synthetic fixture against its declared contract."""
    fx = json.loads(fixture_path.read_text())
    name = fx["name"]

    # Multi-sub-case fixture (synth_05)
    if "sub_cases" in fx:
        sub_results = [_eval_sub_case(s) for s in fx["sub_cases"]]
        all_pass = all(s["verdict"] == "PASS" for s in sub_results)
        return {
            "source": fixture_path.name,
            "name": name,
            "sub_cases": sub_results,
            "verdict": "PASS" if all_pass else "FAIL",
            "rationale": fx.get("rationale", ""),
        }

    # Standard fixture
    logs = fx["logs"]
    truncated, strategy = truncate_logs_spike(logs)
    expected_prefix = fx["expected_strategy_prefix"]
    expected_anchor = fx.get("expected_anchor")
    expected_in_window = fx.get("expected_in_window", True)
    must_contain = fx.get("expected_substrings_in_output", [])
    must_not_contain = fx.get("expected_substrings_NOT_in_output", [])

    # Strategy prefix check
    strategy_ok = strategy.startswith(expected_prefix)

    # Anchor check (in strategy tag for head: / window: cases)
    if expected_anchor is None:
        anchor_ok = strategy == expected_prefix + "no_anchor"
    else:
        anchor_ok = strategy == expected_prefix + expected_anchor

    # Substring checks
    contains_ok = all(s in truncated for s in must_contain)
    excludes_ok = all(s not in truncated for s in must_not_contain)

    # In-window check (for Fixture 4: expected_in_window=False, so PASS
    # means algorithm DID produce the documented-limitation output)
    gt_anchor = fx.get("ground_truth_actionable_error")
    if gt_anchor is not None:
        actually_in_window = gt_anchor in truncated
        in_window_ok = actually_in_window == expected_in_window
    else:
        in_window_ok = True  # No separate ground truth → contract checks suffice

    all_checks = [strategy_ok, anchor_ok, contains_ok, excludes_ok, in_window_ok]
    verdict = "PASS" if all(all_checks) else "FAIL"

    return {
        "source": fixture_path.name,
        "name": name,
        "raw_bytes": len(logs),
        "out_bytes": len(truncated),
        "got_strategy": strategy,
        "expected_strategy_prefix": expected_prefix,
        "expected_anchor": expected_anchor,
        "strategy_match": strategy_ok,
        "anchor_match": anchor_ok,
        "contains_all_required": contains_ok,
        "excludes_all_forbidden": excludes_ok,
        "in_window_as_expected": in_window_ok,
        "expected_in_window": expected_in_window,
        "verdict": verdict,
        "rationale": fx.get("rationale", ""),
    }


# ---- Main -----------------------------------------------------------------
def main() -> int:
    src_dir = Path.home() / "scratch" / "triage-day4"
    synth_dir = Path.home() / "scratch" / "triage-day38" / "synthetic"
    out_path = Path.home() / "scratch" / "triage-day38" / "spike_results.json"

    payloads = sorted(src_dir.glob("run_*.json"))
    if not payloads:
        print(f"FATAL: no payloads in {src_dir}", file=sys.stderr)
        return 2

    # Real-payload battery
    real_results = [evaluate_payload(p) for p in payloads]

    # Synthetic-fixture battery
    synth_fixtures = sorted(synth_dir.glob("synth_*.json"))
    synth_results = [evaluate_synthetic(p) for p in synth_fixtures]

    # Aggregate
    all_results = real_results + synth_results
    passes = sum(1 for r in all_results if r.get("verdict") == "PASS")
    fails = sum(1 for r in all_results if r.get("verdict") == "FAIL")
    errors = sum(1 for r in all_results if r.get("verdict") == "ERROR")
    total = len(all_results)
    real_pass = sum(1 for r in real_results if r.get("verdict") == "PASS")
    synth_pass = sum(1 for r in synth_results if r.get("verdict") == "PASS")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps({
        "spike": "round-3.5.5-truncate-logs-v2-extended",
        "summary": {
            "total": total, "pass": passes, "fail": fails, "error": errors,
            "real_pass": f"{real_pass}/{len(real_results)}",
            "synthetic_pass": f"{synth_pass}/{len(synth_results)}",
        },
        "binary_verdict": "PASS" if passes == total else "FAIL",
        "real_payloads": real_results,
        "synthetic_fixtures": synth_results,
    }, indent=2))

    # Pretty-print real results
    print(f"\n{'='*72}")
    print("Round 3.5.5 spike — EXTENDED battery (7 real + 5 synthetic)")
    print('='*72)
    print(f"\n--- Real payloads ({len(real_results)}) ---")
    for r in real_results:
        v = r.get("verdict", "?")
        marker = "✅" if v == "PASS" else ("❌" if v == "FAIL" else "⚠️ ")
        print(f"{marker} {r['source']:48s} | {v:5s} | {r.get('strategy', '-')}")
        if v == "PASS":
            print(f"     raw={r['raw_bytes']:>10d}B  out={r['out_bytes']:>6d}B"
                  f"  gt={r['ground_truth_anchor']!r}"
                  f"  margin={r['margin_to_nearest_edge']}B")
        elif v == "FAIL":
            print(f"     raw={r['raw_bytes']:>10d}B  out={r['out_bytes']:>6d}B"
                  f"  gt={r['ground_truth_anchor']!r}"
                  f"  gt_pos={r['ground_truth_pos_in_raw']}")

    print(f"\n--- Synthetic fixtures ({len(synth_results)}) ---")
    for r in synth_results:
        v = r.get("verdict", "?")
        marker = "✅" if v == "PASS" else ("❌" if v == "FAIL" else "⚠️ ")
        if "sub_cases" in r:
            print(f"{marker} {r['name']:48s} | {v:5s} | multi-sub-case")
            for sub in r["sub_cases"]:
                sm = "✅" if sub["verdict"] == "PASS" else "❌"
                print(f"     {sm} {sub['sub_name']:24s}"
                      f"  got={sub['got_strategy']!r:24s}"
                      f"  expect={sub['expected_strategy']!r}")
        else:
            print(f"{marker} {r['name']:48s} | {v:5s} | {r.get('got_strategy', '-')}")
            print(f"     raw={r['raw_bytes']:>6d}B  out={r['out_bytes']:>6d}B"
                  f"  strategy_match={r['strategy_match']}"
                  f"  contains_required={r['contains_all_required']}"
                  f"  excludes_forbidden={r['excludes_all_forbidden']}"
                  f"  in_window_as_expected={r['in_window_as_expected']}")

    print(f"\n{'-'*72}")
    print(f"REAL:      {real_pass}/{len(real_results)} PASS")
    print(f"SYNTHETIC: {synth_pass}/{len(synth_results)} PASS")
    print(f"OVERALL:   {passes}/{total} PASS, {fails} FAIL, {errors} ERROR")
    print(f"Binary spike verdict: {'PASS' if passes == total else 'FAIL'}")
    print(f"Full results: {out_path}")
    print('='*72)

    return 0 if passes == total else 1


if __name__ == "__main__":
    sys.exit(main())
