"""Markdown rendering + CLI for the backtest harness.

Split from `backtest.py` (session prompt 2026-06-07 refinement) to keep
each file under the 250-line surface cap. The core harness is pure;
this module deals with how the report SURFACES — rendering, file paths,
and CLI argument handling.

Phase-1 ships this as a one-shot CLI; the baseline report is committed
under `docs/triage-agent/` and updated whenever catalog YAML, redact.py,
or pattern fixtures change (per H6 non-gating decision, 2026-06-07).

Usage
-----
    # Render to stdout
    .venv/bin/python3 -m scripts.automation.src.triage.backtest_report

    # Write to file
    .venv/bin/python3 -m scripts.automation.src.triage.backtest_report \\
        --output docs/triage-agent/backtest-baseline-2026-06-07.md
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timezone
from pathlib import Path

from scripts.automation.src.triage.backtest import (
    BacktestReport,
    CaseResult,
    PatternMetrics,
    Verdict,
    load_labels,
    run_backtest,
)


REPO_ROOT = Path(__file__).resolve().parents[4]
DEFAULT_LABEL_PATH = REPO_ROOT / "docs/triage-agent/fixtures/p01_labels.yml"


# ---------------------------------------------------------------------------
# Markdown rendering
# ---------------------------------------------------------------------------


def _fmt_metric(value: float | None) -> str:
    return "—" if value is None else f"{value:.3f}"


def _render_summary(report: BacktestReport, generated_at_utc: str) -> str:
    """Top-level summary block."""
    lines: list[str] = [
        "# Backtest baseline — P0.1 corpus",
        "",
        f"**Generated:** {generated_at_utc}",
        f"**Harness version:** `{report.harness_version}`  "
        f"**Catalog schema:** `{report.catalog_schema_version}`",
        f"**Label spec:** `{report.label_path}` (version `{report.label_version}`)",
        f"**Cases total:** {report.case_count_total}  "
        f"**scored:** {report.case_count_scored}  "
        f"**skipped (payload missing):** {report.case_count_skipped}  "
        f"**errored (triage raised):** {report.case_count_errored}",
        "",
        "This report is **non-gating** in Phase 1 (per H6 adjudication "
        "2026-06-07). Regenerate when `fbin_error_catalog.yml`, `redact.py`, "
        "or the committed fixtures change. Regression visibility happens "
        "via git-diff of this file, not via test failure. Drift in any of "
        "the four version stamps (harness, catalog schema, label spec, or "
        "label path) is itself a signal worth investigating.",
        "",
    ]
    return "\n".join(lines)


def _render_verdict_table(report: BacktestReport) -> str:
    """Verdict-count table."""
    lines: list[str] = [
        "## Verdict counts",
        "",
        "| Verdict | Count |",
        "|---|---|",
    ]
    for verdict in Verdict:
        count = report.verdict_counts[verdict]
        lines.append(f"| `{verdict.value}` | {count} |")
    lines.append("")
    return "\n".join(lines)


def _render_pattern_metrics(metrics: list[PatternMetrics]) -> str:
    """Per-pattern precision/recall over scored cases (skipped excluded)."""
    lines: list[str] = [
        "## Per-pattern precision / recall",
        "",
        "Computed over **scored** cases only — payloads missing from the "
        "local environment (e.g., `~/scratch/triage-day4/` absent in clean "
        "clones) are excluded from the denominator. `UNKNOWN` is the "
        "synthetic bucket for the no-match path.",
        "",
        "| Pattern | TP | FP | FN | Precision | Recall |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for m in metrics:
        lines.append(
            f"| `{m.pattern_id}` | {m.true_positive} | {m.false_positive} | "
            f"{m.false_negative} | {_fmt_metric(m.precision)} | "
            f"{_fmt_metric(m.recall)} |"
        )
    lines.append("")
    return "\n".join(lines)


def _render_case_table(cases: list[CaseResult]) -> str:
    """Per-case verdict table — each label entry resolved to one row."""
    lines: list[str] = [
        "## Per-case results",
        "",
        "| run_id | cluster | verdict | expected pattern | observed pattern | "
        "expected outcome | observed outcome |",
        "|---|---|---|---|---|---|---|",
    ]
    for c in cases:
        observed_outcome = c.observed_outcome.value if c.observed_outcome else "—"
        observed_pattern = c.observed_pattern_id or "—"
        expected_pattern = c.expected_pattern_id or "—"
        lines.append(
            f"| {c.run_id} | {c.cluster} | `{c.verdict.value}` | "
            f"`{expected_pattern}` | `{observed_pattern}` | "
            f"`{c.expected_outcome.value}` | `{observed_outcome}` |"
        )
    lines.append("")
    return "\n".join(lines)


def _render_rationales(cases: list[CaseResult]) -> str:
    """Append rationale excerpts so reviewers can audit drift without re-running."""
    lines: list[str] = [
        "## Observed rationale excerpts (first 240 chars)",
        "",
    ]
    for c in cases:
        if c.verdict == Verdict.SKIPPED_PAYLOAD_MISSING:
            lines.append(f"- **{c.run_id}**: _skipped (payload not present)_")
            continue
        lines.append(f"- **{c.run_id}**: `{c.rationale_excerpt}`")
    lines.append("")
    return "\n".join(lines)


def _render_label_notes(report: BacktestReport) -> str:
    """Surface the LabelSet.notes block (corpus caveats) — empty → skip."""
    if not report.label_notes.strip():
        return ""
    return "\n".join([
        "## Corpus caveats (from label spec)",
        "",
        report.label_notes.strip(),
        "",
    ])


def render_markdown_report(report: BacktestReport, generated_at_utc: str) -> str:
    """Full markdown report — committed as baseline."""
    sections = [
        _render_summary(report, generated_at_utc),
        _render_label_notes(report),
        _render_verdict_table(report),
        _render_pattern_metrics(report.per_pattern_metrics),
        _render_case_table(report.cases),
        _render_rationales(report.cases),
    ]
    return "\n".join(s for s in sections if s)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run the backtest harness against the P0.1 labeled corpus and "
            "emit a markdown baseline report."
        ),
    )
    parser.add_argument(
        "--label-path",
        type=Path,
        default=DEFAULT_LABEL_PATH,
        help="Path to the label YAML file (default: %(default)s)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Where to write the report. Omit to print to stdout.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    label_set = load_labels(args.label_path)
    # Render label_path relative to REPO_ROOT for the audit stamp; fall
    # back to the absolute path if the file lives outside the repo.
    try:
        label_path_stamp = str(args.label_path.resolve().relative_to(REPO_ROOT))
    except ValueError:
        label_path_stamp = str(args.label_path)
    report = run_backtest(label_set, REPO_ROOT, label_path=label_path_stamp)
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    rendered = render_markdown_report(report, generated_at)
    if args.output is None:
        sys.stdout.write(rendered)
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        # Pin encoding="utf-8" — this is a committed baseline report
        # generator; output bytes must be stable across environments
        # (the platform-default encoding drifts to locale on non-UTF-8
        # systems). Matches the convention in migrate_mcp_secrets.py and
        # the rest of the triage writers. PR #1821 Commit 6, R4 N3.
        args.output.write_text(rendered, encoding="utf-8")
        print(f"wrote {args.output}", file=sys.stderr)
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
