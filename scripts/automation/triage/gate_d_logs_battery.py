"""Mini-Gate-D battery: PII surface + truncation-strategy evidence for the
dbt Cloud `logs` field.

Status: DRAFT — runs locally against `~/scratch/triage-day4/run_*.json`
(payloads re-pulled under the rotated DBT_TOKEN after the 2026-06-04
security incident). Does NOT make API calls. Does NOT commit results.

Output target (when run): `docs/triage-agent/gate-d-logs-field-amendment.md`
(draft; reviewer is the user before any redact.py changes).

What this battery answers
-------------------------
Gate-D Round 1 was conducted on artifact-mode runs whose meaningful
content lives in `run_results.json`. The negative-evidence finding
("no real PII in artifact mode") does NOT generalize to the `logs`
field, which is up to ~2.9 MB of full runtime log including:

  - compiled SQL with potential customer IDs
  - dbt_date macro definitions (huge mass; pure code; no PII)
  - error keywords + stack traces
  - Snowflake error responses (object names, sometimes column names)
  - Snowflake URLs (account ID is OK; user/role embedded in some
    debug output)
  - email addresses in package metadata + git author lines

This battery measures three things across the 7 cached payloads:

1. **PII surface** — counts of credential-shape, email, abs-path, IP,
   account URL, customer-ID patterns
2. **Truncation-strategy candidates** — for each payload, identify
   (a) tail-N-KB outcomes for N ∈ {16, 32, 64, 128, 256}
   (b) last-ERROR-anchor position + window
   (c) hybrid (anchor first, tail fallback) outcomes
3. **Content composition** — what fraction is dbt_date macro dump vs.
   actual log content (informs why tail-N-KB alone is wrong per
   Phase A observation that errors live EARLIER than the macro dump)

Strategy decision matrix (output)
----------------------------------
For each candidate strategy, the doc reports:
  - error-keyword capture rate across the 7 payloads (% with the actual
    error string preserved after truncation)
  - PII surface delivered to LLM context (count of sentinel-tripping
    matches in the truncated window)
  - size delivered (KB) — bounds LLM token cost
  - tail-vs-anchor sensitivity: does the anchor strategy depend on
    `ERROR` literal? what if a future dbt version emits `error:` or
    `Error encountered:`?

The doc then RECOMMENDS one strategy with evidence; redact.py amendment
implements only the recommended strategy. Future engineers can re-run
this battery on new sample data to validate the recommendation still
holds.

How to run
----------
    .venv/bin/python3 scripts/automation/triage/gate_d_logs_battery.py \\
        --input-dir ~/scratch/triage-day4 \\
        --output docs/triage-agent/gate-d-logs-field-amendment.md

Pre-conditions:
  - 7 payloads re-pulled under ROTATED dbt token (see follow-up item #1
    in docs/triage-agent/security-incident-2026-06-04.md)
  - Payloads in `~/scratch/triage-day4/` (NOT `/tmp/`)
  - Script is read-only on payloads; writes only the output markdown

What this script DOES NOT do
----------------------------
- Make API calls (no credential exposure surface)
- Modify redact.py (that's Day 3.8 after this output reviewed)
- Commit anything (output is draft for user review)
- Pre-commit to a strategy (evidence determines; not the script author)
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


# ---- PII surface battery (same shape as Gate-D Round 1 + log-specific) ----
PII_PROBES: dict[str, re.Pattern[str]] = {
    # Credential-shape (must be zero, or this run's payloads themselves
    # have a leak we need to handle BEFORE expanding the allowlist)
    "jwt_shape":         re.compile(r"eyJ[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}"),
    "github_pat":        re.compile(r"gh[pso]_[a-zA-Z0-9]{30,}"),
    "aws_access_key":    re.compile(r"AKIA[0-9A-Z]{16}"),
    "private_key_block": re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY"),

    # PII shapes (low-volume, high-signal)
    "email":             re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"),
    "ssn_us":            re.compile(r"\b\d{3}-\d{2}-\d{4}\b"),
    "credit_card_lax":   re.compile(r"\b(?:\d[ -]?){13,19}\b"),

    # File-system / host PII
    "abs_path_home":     re.compile(r"/Users/[a-zA-Z0-9_-]+/"),
    "abs_path_root":     re.compile(r"/(home|root)/[a-zA-Z0-9_-]+/"),
    "ipv4":              re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b"),
    "ipv6_lax":          re.compile(r"\b(?:[0-9a-f]{1,4}:){4,}[0-9a-f]{0,4}\b", re.IGNORECASE),

    # Snowflake / dbt Cloud identifiers (account ID + role are typically OK;
    # user identity is the concern)
    "snowflake_user_attr": re.compile(r"SNOWFLAKE_USER\s*[:=]\s*['\"]?([A-Za-z0-9._@-]+)", re.IGNORECASE),
    "snowflake_url":       re.compile(r"\b[a-z0-9_-]+\.[a-z0-9-]+\.snowflakecomputing\.com\b", re.IGNORECASE),

    # FBIN customer IDs (heuristic from Gate-D Round 1 false-positive table)
    "customer_id_shape": re.compile(r"\b[0-9]{7,12}\b"),
}

# ---- Anchor patterns (candidate Error markers for anchor strategy) -------
# Ordered: most-specific first. Strategy picks the LAST match in the field.
ERROR_ANCHORS: list[tuple[str, re.Pattern[str]]] = [
    ("dbt_error_runtime",       re.compile(r"Runtime Error", re.IGNORECASE)),
    ("dbt_error_database",      re.compile(r"Database Error", re.IGNORECASE)),
    ("dbt_error_compilation",   re.compile(r"Compilation Error", re.IGNORECASE)),
    ("snowflake_compile_error", re.compile(r"SQL compilation error", re.IGNORECASE)),
    ("snowflake_error_code",    re.compile(r"\b\d{6}\s*\([0-9A-Z]{5}\):", re.IGNORECASE)),  # e.g. 002003 (42S02):
    ("python_exception",        re.compile(r"Traceback \(most recent call last\):")),
    ("encountered_an_error",    re.compile(r"Encountered an error:")),
    ("generic_error_colon",     re.compile(r"^ERROR\b", re.IGNORECASE | re.MULTILINE)),
    ("generic_failed",          re.compile(r"\bfailed\b", re.IGNORECASE)),
]

# ---- Truncation strategy candidates --------------------------------------
TAIL_KB_CANDIDATES = (16, 32, 64, 128, 256)
ANCHOR_WINDOW_KB = 32   # Take ±16 KB around the anchor by default


def extract_logs_field(payload_path: Path) -> dict[int, str]:
    """Return {step_index_1based: logs_content} for steps that have logs."""
    raw = json.loads(payload_path.read_text())["data"]
    out: dict[int, str] = {}
    for i, step in enumerate(raw.get("run_steps", []), start=1):
        logs = step.get("logs") or ""
        if logs:
            out[i] = logs
    return out


def measure_pii_surface(text: str) -> dict[str, int]:
    """Return {probe_name: hit_count}. Counts repeats."""
    return {name: len(rx.findall(text)) for name, rx in PII_PROBES.items()}


def tail_n_kb(text: str, n_kb: int) -> str:
    n_bytes = n_kb * 1024
    return text[-n_bytes:] if len(text) > n_bytes else text


def find_last_anchor(text: str) -> tuple[str, int] | None:
    """Find the LAST match of any anchor pattern; return (name, end_pos)."""
    best: tuple[str, int] | None = None
    for name, rx in ERROR_ANCHORS:
        for m in rx.finditer(text):
            if best is None or m.end() > best[1]:
                best = (name, m.end())
    return best


def anchor_window(text: str, end_pos: int, window_kb: int) -> str:
    half = (window_kb * 1024) // 2
    start = max(0, end_pos - half)
    end = min(len(text), end_pos + half)
    return text[start:end]


def hybrid_truncate(text: str, anchor_window_kb: int, tail_fallback_kb: int) -> tuple[str, str]:
    """Return (truncated_text, strategy_used)."""
    anchor = find_last_anchor(text)
    if anchor is not None:
        return anchor_window(text, anchor[1], anchor_window_kb), f"anchor:{anchor[0]}"
    return tail_n_kb(text, tail_fallback_kb), f"tail:{tail_fallback_kb}KB"


def ground_truth_error_keywords(text: str) -> list[str]:
    """Heuristic: the substring around the LAST anchor IS the ground truth.
    A truncation strategy 'captures' the error if its output contains the
    same anchor match.
    """
    anchor = find_last_anchor(text)
    if anchor is None:
        return []
    # Snapshot ±256 chars around the anchor; truncation must preserve it
    start = max(0, anchor[1] - 256)
    end = min(len(text), anchor[1] + 256)
    return [text[start:end]]


def evaluate_strategy(text: str, truncated: str) -> bool:
    """Did truncation preserve the ground-truth error window?"""
    truth = ground_truth_error_keywords(text)
    if not truth:
        # No anchor found → cannot fail this test
        return True
    return any(t in truncated for t in truth)


def measure_macro_dump_fraction(text: str) -> float:
    """Heuristic: what fraction of the field is dbt_date macro dump?

    dbt_date macros are recognizable by `{% macro ... %}` / `{% endmacro %}`
    blocks emitted during compilation tracing. Returns 0.0..1.0.
    """
    macro_pattern = re.compile(r"\{% (?:macro|endmacro)\b", re.IGNORECASE)
    macro_hits = len(macro_pattern.findall(text))
    if macro_hits == 0:
        return 0.0
    # Rough estimate: each macro block is ~500 chars on average
    estimated_macro_chars = macro_hits * 500
    return min(1.0, estimated_macro_chars / max(1, len(text)))


def evaluate_payload(payload_path: Path) -> dict[str, Any]:
    """Run the full battery on one payload's logs field across all steps."""
    logs_by_step = extract_logs_field(payload_path)
    result: dict[str, Any] = {
        "file": payload_path.name,
        "step_count_with_logs": len(logs_by_step),
        "total_logs_bytes": sum(len(v) for v in logs_by_step.values()),
        "per_step": {},
    }
    for step_idx, text in logs_by_step.items():
        anchor = find_last_anchor(text)
        per_step: dict[str, Any] = {
            "size_bytes": len(text),
            "macro_dump_fraction": round(measure_macro_dump_fraction(text), 3),
            "last_anchor": {"name": anchor[0], "end_pos": anchor[1]} if anchor else None,
            "pii_surface_full": measure_pii_surface(text),
            "strategies": {},
        }
        # Tail-N-KB candidates
        for n_kb in TAIL_KB_CANDIDATES:
            t = tail_n_kb(text, n_kb)
            per_step["strategies"][f"tail_{n_kb}kb"] = {
                "size_bytes": len(t),
                "preserves_error": evaluate_strategy(text, t),
                "pii_surface": measure_pii_surface(t),
            }
        # Anchor strategy
        if anchor is not None:
            t = anchor_window(text, anchor[1], ANCHOR_WINDOW_KB)
            per_step["strategies"][f"anchor_{ANCHOR_WINDOW_KB}kb"] = {
                "size_bytes": len(t),
                "preserves_error": evaluate_strategy(text, t),
                "pii_surface": measure_pii_surface(t),
            }
        # Hybrid
        t, used = hybrid_truncate(text, ANCHOR_WINDOW_KB, tail_fallback_kb=64)
        per_step["strategies"]["hybrid"] = {
            "size_bytes": len(t),
            "preserves_error": evaluate_strategy(text, t),
            "pii_surface": measure_pii_surface(t),
            "strategy_used": used,
        }
        result["per_step"][step_idx] = per_step
    return result


def write_markdown_report(results: list[dict[str, Any]], output_path: Path) -> None:
    """Emit the gate-d-logs-field-amendment.md draft."""
    lines: list[str] = []
    lines.append("# Gate-D Round 2 — `logs` Field Amendment (DRAFT)")
    lines.append("")
    lines.append("**Status:** DRAFT — auto-generated by `gate_d_logs_battery.py`")
    lines.append("")
    lines.append("**Purpose:** Extend the field-aware allowlist in `redact.py` to "
                 "include the `run_steps[*].logs` field for early-failure mode "
                 "pattern matching. Gate-D Round 1 only validated artifact-mode "
                 "fields; this round validates the `logs` field's PII surface and "
                 "selects a truncation strategy.")
    lines.append("")
    lines.append("**Generated from:** N payloads re-pulled under rotated dbt token "
                 "post-security-incident-2026-06-04. See "
                 "`docs/triage-agent/security-incident-2026-06-04.md` for context.")
    lines.append("")

    # Section 1: PII surface summary
    lines.append("## 1. PII Surface Census")
    lines.append("")
    lines.append("| File | Step | Size (KB) | Macro dump % | JWTs | PATs | AWS keys | Emails | Abs paths | IPs | Customer-ID shapes |")
    lines.append("|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
    for r in results:
        for step, ps in r["per_step"].items():
            p = ps["pii_surface_full"]
            lines.append(
                f"| {r['file']} | {step} | {ps['size_bytes']//1024:,} | "
                f"{int(ps['macro_dump_fraction']*100)}% | "
                f"{p['jwt_shape']} | {p['github_pat']} | {p['aws_access_key']} | "
                f"{p['email']} | {p['abs_path_home']+p['abs_path_root']} | "
                f"{p['ipv4']+p['ipv6_lax']} | {p['customer_id_shape']} |"
            )
    lines.append("")
    lines.append("**Interpretation rules:**")
    lines.append("- Any nonzero in JWTs/PATs/AWS-keys columns → STOP, real "
                 "credentials are leaking into `logs`; do not allowlist until "
                 "redact path can strip them.")
    lines.append("- High email count → expected (package metadata, git author "
                 "lines); document the source pattern and confirm none point to "
                 "external recipients.")
    lines.append("- High customer-ID-shape count → likely false positive (Gate-D "
                 "Round 1 found these were execution-time floats); confirm by "
                 "manual sampling.")
    lines.append("")

    # Section 2: Truncation strategy comparison
    lines.append("## 2. Truncation Strategy Evaluation")
    lines.append("")
    lines.append("For each step's `logs`, evaluated 7 strategies: 5 tail-N-KB "
                 "variants, 1 anchor-window, 1 hybrid. The 'preserves error' "
                 "column is TRUE if the truncated text contains the ±256 chars "
                 "around the last error anchor.")
    lines.append("")
    lines.append("| File | Step | tail-16 | tail-32 | tail-64 | tail-128 | tail-256 | anchor-32 | hybrid |")
    lines.append("|---|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|")
    for r in results:
        for step, ps in r["per_step"].items():
            def mark(key: str) -> str:
                v = ps["strategies"].get(key)
                if v is None:
                    return "—"
                return "✓" if v["preserves_error"] else "✗"
            lines.append(
                f"| {r['file']} | {step} | "
                f"{mark('tail_16kb')} | {mark('tail_32kb')} | {mark('tail_64kb')} | "
                f"{mark('tail_128kb')} | {mark('tail_256kb')} | "
                f"{mark(f'anchor_{ANCHOR_WINDOW_KB}kb')} | {mark('hybrid')} |"
            )
    lines.append("")

    # Section 3: Strategy recommendation (decision matrix template)
    lines.append("## 3. Strategy Recommendation")
    lines.append("")
    lines.append("**Decision rule:** select the strategy with the highest "
                 "error-preservation rate at the lowest PII surface and lowest "
                 "size delivered to LLM context. Ties broken by simplicity "
                 "(tail < anchor < hybrid).")
    lines.append("")
    lines.append("Aggregate evaluation across all payloads:")
    lines.append("")
    lines.append("| Strategy | Error-preserve rate | Avg PII surface (total hits) | Avg size delivered (KB) |")
    lines.append("|---|---:|---:|---:|")

    strategies = ["tail_16kb", "tail_32kb", "tail_64kb", "tail_128kb", "tail_256kb",
                  f"anchor_{ANCHOR_WINDOW_KB}kb", "hybrid"]
    for s in strategies:
        rows = []
        for r in results:
            for ps in r["per_step"].values():
                v = ps["strategies"].get(s)
                if v is not None:
                    rows.append(v)
        if not rows:
            continue
        preserve = sum(1 for v in rows if v["preserves_error"]) / max(1, len(rows))
        avg_pii = sum(sum(v["pii_surface"].values()) for v in rows) / max(1, len(rows))
        avg_kb = sum(v["size_bytes"] for v in rows) / max(1, len(rows)) / 1024
        lines.append(f"| {s} | {int(preserve*100)}% | {avg_pii:.1f} | {avg_kb:.1f} |")
    lines.append("")
    lines.append("**Recommended strategy:** TBD — fill in after reviewing the "
                 "table above. The recommended strategy becomes the implementation "
                 "spec for the Day 3.8 redact.py amendment.")
    lines.append("")

    # Section 4: Sprint-1-item-12 acceptance criteria draft (filled by reviewer)
    lines.append("## 4. Sprint-1 Deferred Item #12 — Acceptance Criteria")
    lines.append("")
    lines.append("(Update `docs/triage-agent/sprint-1-deferred.md` item #12 with "
                 "these once strategy is selected.)")
    lines.append("")
    lines.append("- [ ] `logs` added to `REGEX_ELIGIBLE_FIELDS` in `redact.py`")
    lines.append("- [ ] Truncation strategy: <FILL IN from §3 recommendation>")
    lines.append("- [ ] New mutation invariant (Mut9 or Mut8): "
                 "<FILL IN — e.g. 'truncated output always contains the last "
                 "anchor match if one exists in full text'>")
    lines.append("- [ ] PII surface census in §1 shows zero credential-shape hits "
                 "(or, if nonzero, redact path strips them before truncation)")
    lines.append("- [ ] At least 1 of Clusters A / C from Day-4 Phase B ships as "
                 "a new catalog pattern using `logs` source successfully")
    lines.append("- [ ] Matcher latency stays sub-10ms at p95 on truncated output")
    lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("_Generated by `scripts/automation/triage/gate_d_logs_battery.py`. "
                 "Re-run after adding new payloads to refresh the evidence._")

    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--input-dir", required=True, type=Path,
                    help="Directory containing run_*.json payloads (re-pulled "
                         "under rotated token).")
    ap.add_argument("--output", required=True, type=Path,
                    help="Output markdown path (typically "
                         "docs/triage-agent/gate-d-logs-field-amendment.md)")
    args = ap.parse_args(argv)

    input_dir: Path = args.input_dir.expanduser()
    if not input_dir.is_dir():
        print(f"ERROR: input-dir not found: {input_dir}", file=sys.stderr)
        return 2

    payloads = sorted(input_dir.glob("run_*.json"))
    if not payloads:
        print(f"ERROR: no run_*.json files in {input_dir}", file=sys.stderr)
        return 3

    print(f"Processing {len(payloads)} payloads from {input_dir}")
    results = [evaluate_payload(p) for p in payloads]
    print(f"Writing report to {args.output}")
    write_markdown_report(results, args.output)
    print("Done. Review the draft before any redact.py changes.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
