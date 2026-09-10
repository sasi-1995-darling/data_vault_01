#!/usr/bin/env python3
"""ARCHIVED — Day-4 triage payload re-pull tool (one-time corpus accretion).

==============================================================================
ARCHIVED FOR AUDIT REPRODUCIBILITY — DO NOT USE AS A TEMPLATE
==============================================================================

This script was the one-time tool that re-pulled the 7 Day-4 triage payloads
under the rotated dbt PAT after the 2026-06-04 credential exposure incident.
Step 11 (corpus accretion to docs/triage-agent/fixtures/) completed 2026-06-04;
byte-match verified in docs/triage-agent/gate-d-logs-field-amendment.md §1.

It is kept here (per the original archival intent recorded in commit 061d15da)
so the corpus pull is reproducible/auditable. It is NOT part of the production
triage pipeline and is NOT a template for new code:

  * Active production triage code goes through
    scripts/automation/src/triage/writer.py and its upstream redactor.
    Redaction (including R1 audit) happens via redact_early_failure /
    redact_artifact BEFORE the writer ever sees the payload — the writer's
    boundary contract is post-redact and grep-checked.

  * THIS SCRIPT historically wrote raw HTTP response bytes to disk BEFORE
    running the R1 credential audit. That sequencing violated the R1
    "sentinel-before-write" rule recorded in
    docs/triage-agent/credential-threat-model.md. The one-time original
    pull (2026-06-04) ran under that sequencing on a monitored host with a
    fresh PAT. The pulled bytes have since been redacted into the
    docs/triage-agent/fixtures/ corpus.

  * The R1 sequencing is now FIXED at HEAD (see PR #1821 Commit 5): the
    raw body is parsed BEFORE write, audit_raw_for_credentials() runs on
    the parsed structure, and write_bytes() runs only on sentinel-pass.
    On sentinel fire the script logs SANITIZED event metadata
    (pattern_name + field_path + offset + length — NEVER the matched
    value), skips the write for that run, marks the MANIFEST row as
    SKIPPED, and continues with the remaining runs.

If a future re-pull is genuinely needed for audit, this script is now safe
to re-execute under a rotated PAT. For any new (non-audit) pull, prefer
mcp_dbt_get_job_run_details — see "Why direct urllib" note below for why
this script used curl-direct instead.

Why direct urllib instead of mcp_dbt_get_job_run_details:
  The MCP wrapper returns metadata-only run_steps (no inlined logs). Day-4
  Pre-flight #3 documented the same gap and worked around it with curl-direct.
  This script is the curl-direct equivalent for Step 11 of the security
  remediation follow-up.

Writes raw JSON + MANIFEST.txt under ~/scratch/triage-day4/. Token via getpass
(never echoed, never persisted). Uses urllib only (no curl, no requests),
plus the in-repo redact module for the R1 audit.
"""
from __future__ import annotations

import getpass
import hashlib
import json
import pathlib
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

# Bootstrap repo root on sys.path so the in-repo redact module is importable
# when this script runs standalone (no PYTHONPATH needed at the shell).
# parents: [0]=archive/ [1]=triage/ [2]=automation/ [3]=scripts/ [4]=repo_root
_REPO_ROOT = pathlib.Path(__file__).resolve().parents[4]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from scripts.automation.src.triage.redact import (  # noqa: E402
    CredentialSentinelFired,
    audit_raw_for_credentials,
)

HOST = "kl673.us1.dbt.com"  # multi-cell host (validated 200/200/200 this session)
ACCOUNT_ID = "173296"
OUT_DIR = pathlib.Path.home() / "scratch" / "triage-day4"

# (run_id, cluster, day4_documented_size_kb)
# Day-4 sizes are metadata-only (wrapper shape); logs-inlined payloads will be
# much larger. The size_delta_pct column in MANIFEST surfaces the gap.
RUNS: list[tuple[int, str, float]] = [
    (487333396, "B", 13.2),
    (487313189, "B", 12.8),
    (485851058, "A",  9.1),
    (485850628, "A",  9.4),
    (485821754, "A",  9.2),
    (484675412, "C", 10.1),
    (486060143, "C", 11.6),
]


def fetch_run(run_id: int, token: str) -> bytes:
    """GET /api/v2/accounts/<acct>/runs/<id>/?include_related=...

    Returns raw response bytes. Raises HTTPError on non-2xx.
    """
    # dbt Cloud accepts include_related as a JSON-encoded list in the query string.
    qs = urllib.parse.urlencode({"include_related": '["run_steps","debug_logs"]'})
    url = f"https://{HOST}/api/v2/accounts/{ACCOUNT_ID}/runs/{run_id}/?{qs}"
    req = urllib.request.Request(url, headers={
        "Authorization": f"Token {token}",
        "Accept": "application/json",
    })
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def summarize_logs_presence(payload: dict) -> dict:
    """Inspect run_steps[] to report what log fields are populated, and sizes."""
    steps = (payload.get("data") or payload).get("run_steps") or []
    summary = {
        "step_count": len(steps),
        "step_with_debug_logs": 0,
        "step_with_logs": 0,
        "step_with_truncated_debug_logs": 0,
        "total_debug_logs_bytes": 0,
        "total_logs_bytes": 0,
        "total_truncated_debug_logs_bytes": 0,
        "log_field_names_observed": set(),
    }
    for s in steps:
        if not isinstance(s, dict):
            continue
        for k, v in s.items():
            if "log" in k.lower():
                summary["log_field_names_observed"].add(k)
        dl = s.get("debug_logs") or ""
        lg = s.get("logs") or ""
        tdl = s.get("truncated_debug_logs") or ""
        if dl:
            summary["step_with_debug_logs"] += 1
            summary["total_debug_logs_bytes"] += len(dl)
        if lg:
            summary["step_with_logs"] += 1
            summary["total_logs_bytes"] += len(lg)
        if tdl:
            summary["step_with_truncated_debug_logs"] += 1
            summary["total_truncated_debug_logs_bytes"] += len(tdl)
    summary["log_field_names_observed"] = sorted(summary["log_field_names_observed"])
    return summary


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Output dir: {OUT_DIR}")

    token = getpass.getpass("Paste dbt PAT (won't echo): ").strip()
    if not token.isascii() or len(token) < 20 or " " in token or "\n" in token:
        print(f"  REJECTED: paste does not look like a PAT (len={len(token)}, ascii={token.isascii()}).")
        return 2

    pull_time = datetime.now(timezone.utc).isoformat(timespec="seconds")
    manifest_lines = [
        "# Day-4 triage payload re-pull manifest",
        f"# Pull time (UTC): {pull_time}",
        f"# Host: {HOST}  Account: {ACCOUNT_ID}",
        "# include_related: run_steps, debug_logs",
        "#",
        "# Columns: run_id | cluster | day4_size_kb | actual_size_kb | size_delta_pct | logs_field_populated | steps_with_logs/steps | sha256",
        "",
    ]

    canary_done = False
    rows: list[dict] = []
    for run_id, cluster, day4_kb in RUNS:
        out_path = OUT_DIR / f"run_{run_id}_cluster_{cluster}.json"
        try:
            body = fetch_run(run_id, token)
        except urllib.error.HTTPError as e:
            print(f"  run {run_id}: HTTP {e.code} {e.reason}")
            rows.append({
                "run_id": run_id, "cluster": cluster, "day4_kb": day4_kb,
                "actual_kb": None, "delta_pct": None, "logs_pop": None,
                "steps_with_logs": None, "step_count": None, "sha256": f"ERROR_HTTP_{e.code}",
            })
            continue
        except Exception as e:
            print(f"  run {run_id}: ERROR {type(e).__name__}: {e}")
            rows.append({
                "run_id": run_id, "cluster": cluster, "day4_kb": day4_kb,
                "actual_kb": None, "delta_pct": None, "logs_pop": None,
                "steps_with_logs": None, "step_count": None, "sha256": f"ERROR_{type(e).__name__}",
            })
            continue

        # ------------------------------------------------------------------
        # R1 sentinel-before-write. Mirrors the redact_artifact /
        # redact_early_failure ordering: audit the raw structure BEFORE
        # any lossy/persistent transform. Documented in
        # docs/triage-agent/credential-threat-model.md R1 and enforced
        # at the public redactor entrypoints in
        # scripts/automation/src/triage/redact.py.
        # ------------------------------------------------------------------
        try:
            payload = json.loads(body)
        except json.JSONDecodeError:
            # Body is not JSON — cannot run the structural audit; refuse
            # to persist on the conservative side (better to lose a row
            # than persist unaudited bytes).
            print(f"  run {run_id}: SKIPPED (response body is not JSON, cannot audit)")
            rows.append({
                "run_id": run_id, "cluster": cluster, "day4_kb": day4_kb,
                "actual_kb": None, "delta_pct": None, "logs_pop": None,
                "steps_with_logs": None, "step_count": None,
                "sha256": "SKIPPED_NOT_JSON",
            })
            continue

        try:
            audit_raw_for_credentials(payload)
        except CredentialSentinelFired as exc:
            # Sanitized log — pattern_name + field_path + offset + length,
            # NEVER the matched value. Matches the policy in
            # redact.py's CredentialSentinelFired class docstring.
            ev = exc.event
            print(
                f"  run {run_id}: CREDENTIAL SENTINEL FIRED "
                f"(pattern={ev.pattern_name!r}, field={ev.field_path!r}, "
                f"offset={ev.offset}, length={ev.length}) "
                f"— refusing to persist raw body"
            )
            rows.append({
                "run_id": run_id, "cluster": cluster, "day4_kb": day4_kb,
                "actual_kb": None, "delta_pct": None, "logs_pop": None,
                "steps_with_logs": None, "step_count": None,
                "sha256": f"SKIPPED_SENTINEL_{ev.pattern_name}",
            })
            continue

        # Sentinel passed — safe to persist.
        out_path.write_bytes(body)
        size_kb = len(body) / 1024.0
        delta_pct = ((size_kb - day4_kb) / day4_kb * 100.0) if day4_kb else None
        sha256 = hashlib.sha256(body).hexdigest()
        log_summary = summarize_logs_presence(payload)
        logs_pop = log_summary["step_with_logs"] > 0
        rows.append({
            "run_id": run_id, "cluster": cluster, "day4_kb": day4_kb,
            "actual_kb": size_kb, "delta_pct": delta_pct, "logs_pop": logs_pop,
            "steps_with_logs": log_summary["step_with_logs"],
            "step_count": log_summary["step_count"], "sha256": sha256,
            "log_field_names": log_summary["log_field_names_observed"],
            "total_logs_bytes": log_summary["total_logs_bytes"],
            "total_truncated_debug_logs_bytes": log_summary["total_truncated_debug_logs_bytes"],
        })
        flag = " <-- DELTA>20%" if delta_pct is not None and abs(delta_pct) > 20 else ""
        print(f"  run {run_id} cluster {cluster}: {size_kb:>10.1f} KB  (day4 {day4_kb:>5.1f} KB, delta {delta_pct:+.1f}%) logs_pop={logs_pop} steps_with_logs={log_summary['step_with_logs']}/{log_summary['step_count']}{flag}")

        if not canary_done:
            canary_done = True
            print()
            print("  === CANARY (run 487333396) structural summary ===")
            print(f"    File:                         {out_path.name}")
            print(f"    Raw size:                     {len(body):,} bytes ({size_kb:.1f} KB)")
            print(f"    Day-4 documented:             {day4_kb} KB")
            print(f"    Delta:                        {delta_pct:+.1f}%")
            print(f"    Step count:                   {log_summary['step_count']}")
            print(f"    Steps with `logs` field:      {log_summary['step_with_logs']}")
            print(f"    Steps with `debug_logs`:      {log_summary['step_with_debug_logs']}")
            print(f"    Steps with `truncated_debug_logs`: {log_summary['step_with_truncated_debug_logs']}")
            print(f"    Total logs bytes:             {log_summary['total_logs_bytes']:,}")
            print(f"    Total truncated_debug_logs:   {log_summary['total_truncated_debug_logs_bytes']:,}")
            print(f"    Log-shaped field names seen:  {log_summary['log_field_names_observed']}")
            print(f"    SHA256:                       {sha256}")
            print()
            if log_summary["step_with_logs"] == 0 and log_summary["total_truncated_debug_logs_bytes"] == 0:
                print("  WARNING: canary still shows NO populated logs/truncated_debug_logs fields.")
                print("  Continuing through remaining 6 anyway so MANIFEST captures the full picture.")
                print()

    del token

    for r in rows:
        if r.get("actual_kb") is None:
            line = f"{r['run_id']} | {r['cluster']} | {r['day4_kb']:.1f} KB | ERROR | - | - | - | {r['sha256']}"
        else:
            line = (
                f"{r['run_id']} | {r['cluster']} | {r['day4_kb']:>5.1f} KB | "
                f"{r['actual_kb']:>10.1f} KB | {r['delta_pct']:+8.1f}% | "
                f"logs_pop={r['logs_pop']!s:<5} | "
                f"{r['steps_with_logs']}/{r['step_count']} | "
                f"{r['sha256']}"
            )
        manifest_lines.append(line)

    manifest_lines.append("")
    manifest_lines.append("# Per-run log-field detail:")
    for r in rows:
        if r.get("actual_kb") is None:
            continue
        manifest_lines.append(
            f"#   run {r['run_id']}: log_fields={r.get('log_field_names', [])} "
            f"logs_bytes={r.get('total_logs_bytes', 0)} "
            f"truncated_debug_logs_bytes={r.get('total_truncated_debug_logs_bytes', 0)}"
        )

    (OUT_DIR / "MANIFEST.txt").write_text("\n".join(manifest_lines) + "\n")
    print()
    print(f"MANIFEST written: {OUT_DIR / 'MANIFEST.txt'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
