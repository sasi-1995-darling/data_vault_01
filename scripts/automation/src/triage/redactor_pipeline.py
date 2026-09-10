"""Redactor pipeline — emit deterministic, sweep-clean fixtures from raw
scratch payloads via the redact.py contract.

Purpose
-------
Closes the in-sample reproducibility hole: makes Phase-2 backtest runnable
from a clean clone by producing committed fixtures that:

  1. Are derived from `redact_early_failure()` (the privacy control),
     NOT hand-minimization, so they faithfully represent what the runtime
     redactor would produce on raw production payloads.

  2. Are byte-stable across repeated invocations (G8-1 determinism),
     so a future `git diff --stat` after regen is the snapshot assertion.

  3. Are audited at commit-boundary by a dual sweep that covers both the
     structural dict (escape-affected patterns) and the serialized JSON text
     (key-name placements) — closing the holes Claude flagged in the locked
     spec review.

Trust model (DA-5)
------------------
This is a developer tool run from the project venv:

    .venv/bin/python3 -m scripts.automation.src.triage.redactor_pipeline ...

The CLI accepts arbitrary `--input` paths; operator controls invocation.
NO path allowlist — over-engineering for a developer tool, and an allowlist
creates its own bypass surface. Do NOT deploy this module to a service
surface where untrusted users could specify --input.

Concurrency model
-----------------
Single-writer, batch-orchestrated. Documented, not locked — adding fcntl
or file-locks would be over-engineering for a single-operator developer
tool. Do not invoke this module concurrently against the same fixture dir.

Security sequencing (DA-1 INVARIANT — see emit_single)
------------------------------------------------------
The dual sweep MUST complete in memory BEFORE any .tmp write touches disk.
The load-bearing comment at the emission sequence flags this; reordering
without the full quality-gate battery is a P0 security regression.

Bookkeeping
-----------
- redact.py is the SINGLE source of truth for `CREDENTIAL_PATTERNS` and
  `REDACT_SCHEMA_VERSION`. Both imported, neither copied.
- Spec freeze + 15 amendments folded: see `/memories/session/commit-a-spec.md`
  (this session) or, in the repo, the git log entry for this commit.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Optional

from scripts.automation.src.triage.redact import (
    CREDENTIAL_PATTERNS,
    REDACT_SCHEMA_VERSION,
    CredentialSentinelFired,
    SentinelEvent,
    redact_early_failure,
)


# ---------------------------------------------------------------------------
# Configuration constants
# ---------------------------------------------------------------------------

# Where committed fixtures live; CLI --output-dir overrides.
DEFAULT_FIXTURE_DIR = Path("docs/triage-agent/fixtures")

# Default raw-scratch directory; CLI --input-dir overrides.
DEFAULT_INPUT_DIR = Path.home() / "scratch" / "triage-day4"

# Cluster → output-filename pattern segment. Matches existing fixture
# naming convention.
#
# Adding cluster D (or any new letter) requires THREE coordinated edits
# in the same PR (verification ask #3, DA finding F-5 doc-coupling has
# no test enforcement — keep that in mind when extending):
#   1. Add the letter to KNOWN_CLUSTERS below.
#   2. Add the mapping entry here.
#   3. Update docs/triage-agent/fixtures/README (or equivalent) so the
#      fixture-naming convention stays in sync.
CLUSTER_TO_PATTERN: dict = {
    "A": "manifest_parse",
    "B": "pr_schema_missing",
    "C": "dmf_failure",
}

# Single source of truth for the cluster alphabet. Used by both
# RAW_FILENAME_PATTERN (the regex character class) and downstream
# error messages. Derived directly from CLUSTER_TO_PATTERN so a future
# maintainer who adds a cluster to ONE without the other gets caught
# by the assert below at import time (cheap fail-fast guard — the
# doc-coupling between this constant and the README is still unenforced,
# tracked as F-5 in phase-2-progress-log.md).
KNOWN_CLUSTERS: frozenset = frozenset(CLUSTER_TO_PATTERN.keys())
assert KNOWN_CLUSTERS == frozenset("ABC"), (
    "KNOWN_CLUSTERS drift detected — update RAW_FILENAME_PATTERN and "
    "docs/triage-agent/fixtures/README in the same edit. See F-5 in "
    "phase-2-progress-log.md for the doc-coupling tracking row."
)

# Raw scratch filename convention enforced by RAW_FILENAME_PATTERN.
# Files matching this regex are processed; everything else in the
# input-dir is silently skipped (--all mode).
#
# The cluster character class is built from KNOWN_CLUSTERS (the sorted
# alphabet of CLUSTER_TO_PATTERN keys) so unknown cluster letters route
# to the malformed_input bucket via emit_single's filename-mismatch
# branch, instead of crashing _output_filename downstream (DA finding
# F-1, originally M-1 in the first cross-review pass).
RAW_FILENAME_PATTERN = re.compile(
    r"^run_(?P<run_id>\d+)_cluster_"
    r"(?P<cluster>[" + "".join(sorted(KNOWN_CLUSTERS)) + r"])\.json$"
)


# ---------------------------------------------------------------------------
# Per-payload result taxonomy (DA-3 — 3 buckets)
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class EmissionResult:
    """Per-payload outcome. Exactly one of fixture_path / sentinel_event /
    malformed_reason is set, determined by `bucket`."""
    run_id: int  # -1 when filename could not be parsed
    bucket: str  # 'emitted' | 'sentinel_fired' | 'malformed_input'
    fixture_path: Optional[Path] = None
    fixture_bytes: Optional[int] = None
    sentinel_event: Optional[SentinelEvent] = None
    malformed_reason: Optional[str] = None


# ---------------------------------------------------------------------------
# Iterative structural walk (MOD-1 — no recursion limit, no magic constant)
# ---------------------------------------------------------------------------

def _iter_string_leaves(root: Any) -> Iterable[str]:
    """Yield every string leaf in a nested dict/list structure.

    Iterative LIFO stack — no recursion. Pathological depth (e.g., 10K
    nested dicts) terminates cleanly here. Upstream `_redact_node` in
    redact.py recurses; it may raise `RecursionError` on the same input
    before this walk runs. That's caught at the per-payload boundary
    (DA-3) and bucketed as `malformed_input` — see `emit_single`.
    """
    stack: list = [root]
    while stack:
        node = stack.pop()
        if isinstance(node, dict):
            stack.extend(node.values())
        elif isinstance(node, list):
            stack.extend(node)
        elif isinstance(node, str):
            yield node


# ---------------------------------------------------------------------------
# Commit-boundary credential audit (G2-1 dual sweep, CS-1 named for what)
# ---------------------------------------------------------------------------

def _audit_fixture_for_credentials(payload: dict, fixture_text: str) -> None:
    """Commit-boundary credential audit. Raises CredentialSentinelFired on hit.

    Dual sweep — two passes, both fail-closed, first hit wins:

    (a) Structural walk over every string leaf of `payload`. Catches
        escape-affected patterns: both `bearer_token` and `snowflake_pwd`
        in CREDENTIAL_PATTERNS use `\\s*`; in serialized JSON form a real
        newline becomes the two-char sequence `\\n` and these patterns
        miss. Walking the structural dict scans the raw values.

    (b) Regex search over `fixture_text` (json.dumps output). Catches
        credentials placed in dict KEY names (key names are never visited
        as values by walk (a)) and anything (a) traversal missed.

    Both layers import `CREDENTIAL_PATTERNS` from redact.py — single
    source of truth, no copy/drift. Pattern family changes propagate
    automatically.

    NEVER logs the matched value (gate-d-findings.md §5.6 item #6).
    `SentinelEvent` carries pattern_name + field_path + offset + length only.
    """
    # (a) Structural walk over every string leaf of the dict
    for s in _iter_string_leaves(payload):
        for pattern_name, pattern in CREDENTIAL_PATTERNS:
            m = pattern.search(s)
            if m:
                raise CredentialSentinelFired(
                    SentinelEvent(
                        pattern_name=pattern_name,
                        field_path="<structural_walk_string_leaf>",
                        offset=m.start(),
                        length=m.end() - m.start(),
                    )
                )

    # (b) Regex sweep over serialized fixture text
    for pattern_name, pattern in CREDENTIAL_PATTERNS:
        m = pattern.search(fixture_text)
        if m:
            raise CredentialSentinelFired(
                SentinelEvent(
                    pattern_name=pattern_name,
                    field_path="<serialized_fixture_text>",
                    offset=m.start(),
                    length=m.end() - m.start(),
                )
            )


# ---------------------------------------------------------------------------
# Metadata construction (CS-2 — exactly 8 fields, no timestamps, no paths)
# ---------------------------------------------------------------------------

def _build_metadata(raw_path: Path, raw_bytes: bytes, raw_dict: dict,
                    redaction_events: int) -> dict:
    """Construct the `_fixture_metadata` block.

    Exactly 8 fields. Growing past 8 needs justification (CS-2 cap).
    NO `generated_at_utc` — that destroys determinism (G8-1). NO full
    paths — `source_basename` carries the filename only (G3-1).

    `content_sha256` is the sha256 of RAW source bytes — the provenance
    link to the input. NOT self-referential (hashing the fixture's own
    text inside itself is undefined).

    `redact_schema_version` is imported from redact.py — when the
    redactor behavior changes, REDACT_SCHEMA_VERSION must bump (per the
    existing discipline in redact.py:92), and that bump propagates here.
    Phase-2 backtest harness can then detect stale fixtures.

    Field-name discipline (G4-1): three independent version series
    coexist in this repo — redact schema (v1.0.0), label schema (v1.1.0),
    and gate-spec (v1.x). Field name must match the SOURCE CONSTANT
    NAME exactly (`REDACT_SCHEMA_VERSION` → `redact_schema_version`) so
    no consumer ever has to guess which series a value belongs to.
    """
    match = RAW_FILENAME_PATTERN.match(raw_path.name)
    if not match:
        # Filename was already validated upstream in emit_single; this
        # branch is defensive only.
        raise ValueError(
            f"raw filename does not match convention: {raw_path.name!r}"
        )

    return {
        "source_run_id": int(match.group("run_id")),
        "source_cluster": match.group("cluster"),
        "source_basename": raw_path.name,
        "source_size_bytes": len(raw_bytes),
        "content_sha256": hashlib.sha256(raw_bytes).hexdigest(),
        "redact_schema_version": REDACT_SCHEMA_VERSION,
        # Email substitution count from redact.py's _apply_regex (the only
        # redaction class that returns a count — credential hits raise,
        # PREVIEW_FIELDS rewrites + allowlist drops + log truncations are
        # silent). Named precisely (per DA finding F-4, originally M-4) to
        # avoid the false consumer inference "events_count: 0 → fixture
        # unchanged".
        "email_substitution_count": int(redaction_events),
        "retained_step_count": len(
            raw_dict.get("data", {}).get("run_steps", [])
        ),
    }


def _output_filename(metadata: dict) -> str:
    """Build `early_failure_<pattern>_<run_id>.json` from metadata."""
    cluster = metadata["source_cluster"]
    pattern = CLUSTER_TO_PATTERN.get(cluster)
    if pattern is None:
        raise ValueError(
            f"no output-filename pattern mapping for cluster {cluster!r} "
            f"(known: {sorted(CLUSTER_TO_PATTERN)}). Add the mapping in "
            "redactor_pipeline.py:CLUSTER_TO_PATTERN."
        )
    return f"early_failure_{pattern}_{metadata['source_run_id']}.json"


# ---------------------------------------------------------------------------
# Single-payload emission
# ---------------------------------------------------------------------------

def emit_single(raw_path: Path, fixture_dir: Path,
                seen_basenames: set) -> EmissionResult:
    """Pipe one raw scratch payload through the redactor and emit fixture.

    Returns EmissionResult with 3-bucket taxonomy (DA-3):
      - 'emitted'         → fixture written, fixture_path + fixture_bytes set
      - 'sentinel_fired'  → credential detected, NO file, sentinel_event set
      - 'malformed_input' → input rejected, NO file, malformed_reason set

    The function is total over its input: every path returns an
    EmissionResult. Uncaught exceptions are a programming error.
    """
    # Parse filename first (cheap, no I/O) so run_id is known for taxonomy.
    match = RAW_FILENAME_PATTERN.match(raw_path.name)
    if not match:
        return EmissionResult(
            run_id=-1,
            bucket="malformed_input",
            malformed_reason=(
                f"raw filename does not match convention "
                f"`run_<id>_cluster_<X>.json`: {raw_path.name!r}"
            ),
        )
    run_id = int(match.group("run_id"))

    # R2 exception-handling discipline — canonical rule for this block.
    # NEVER interpolate exception objects (`{exc}`, `str(exc)`, `repr(exc)`)
    # into malformed_reason or any operator-visible output. Use
    # `type(exc).__name__` only. Per-class reasons each class is unsafe:
    #
    #   - OSError carries `filename`/`strerror`; on attacker-controlled
    #     input paths these can echo path components into the batch log.
    #   - json.JSONDecodeError carries `.doc` — the FULL input document.
    #     NEVER interpolate this exception object: JSONDecodeError.doc IS
    #     the payload on a credential-containing input. Its str/repr also
    #     includes a snippet of the offending bytes.
    #   - TypeError raised by `redact_early_failure` may stringify a
    #     value derived from the input (see T3 near line ~380).
    #
    # See: docs/triage-agent/credential-threat-model.md R2.
    try:
        raw_bytes = raw_path.read_bytes()
        raw_dict = json.loads(raw_bytes)
    except OSError as exc:
        # T1 — R2 per H comment above.
        return EmissionResult(
            run_id=run_id,
            bucket="malformed_input",
            malformed_reason=f"read failed: {type(exc).__name__}",
        )
    except json.JSONDecodeError as exc:
        # T2 — R2 per H comment above. exc.doc carries the full input
        # document — never interpolate this exception object.
        return EmissionResult(
            run_id=run_id,
            bucket="malformed_input",
            malformed_reason=f"JSON parse failed: {type(exc).__name__}",
        )
    except RecursionError as exc:
        # MOD-1b: json.loads recurses on deeply-nested input; pathological
        # depth caught here at the per-payload boundary. Mirror of the
        # redact-phase handler below (~line 380) — same bucket, same
        # reason-shape, same return structure. The 3-site coverage
        # (parse / redact / serialize) is what makes the
        # "no uncaught RecursionError" contract documented on
        # `_iter_string_leaves` (~line 153) actually true; missing any
        # one site leaves the contract unmet under Python versions
        # where the encoder/decoder hits the default recursion limit
        # (e.g., 3.11 at depth ~1000).
        return EmissionResult(
            run_id=run_id,
            bucket="malformed_input",
            malformed_reason=(
                "input depth exceeded Python recursion limit during "
                f"JSON parse: {type(exc).__name__}"
            ),
        )

    # DA-2: collision check on `_fixture_metadata` key in raw input.
    # If the dbt Cloud API ever ships a field with this name, or a
    # hand-mangled raw already contains one, we'd silently overwrite
    # operator-relevant data. Fail loud.
    if isinstance(raw_dict, dict) and "_fixture_metadata" in raw_dict:
        return EmissionResult(
            run_id=run_id,
            bucket="malformed_input",
            malformed_reason=(
                "raw payload already has top-level `_fixture_metadata` key; "
                "refusing to overwrite operator-relevant data"
            ),
        )

    # Run redactor through the per-field sentinel pass.
    try:
        result = redact_early_failure(raw_dict)
    except CredentialSentinelFired as exc:
        # Per-field sentinel caught it before we got to dual sweep.
        return EmissionResult(
            run_id=run_id,
            bucket="sentinel_fired",
            sentinel_event=exc.event,
        )
    except RecursionError as exc:
        # MOD-1: upstream `_redact_node` recurses; pathological depth
        # caught here at the per-payload boundary.
        return EmissionResult(
            run_id=run_id,
            bucket="malformed_input",
            malformed_reason=(
                "input depth exceeded Python recursion limit during "
                f"redaction: {type(exc).__name__}"
            ),
        )
    except TypeError as exc:
        # redact_early_failure raises TypeError on non-dict input. Should
        # not happen given the dict isinstance check above, but defensive.
        return EmissionResult(
            run_id=run_id,
            bucket="malformed_input",
            malformed_reason=f"redactor refused input: {type(exc).__name__}",
            # T3 — R2 per H comment in emit_single. TypeError.args may
            # stringify a dict value derived from the input.
        )

    # ADD-2: post-redaction output-contract validation.
    # An empty `data.run_steps` cannot drive `triage_failure` or satisfy
    # the `load_fixture` consumer contract; emitting it manufactures a
    # landmine for Commit B's label repoint.
    run_steps = result.payload.get("data", {}).get("run_steps", [])
    if not run_steps:
        return EmissionResult(
            run_id=run_id,
            bucket="malformed_input",
            malformed_reason=(
                "post-redaction payload has empty `data.run_steps`; "
                "fixture cannot satisfy load_fixture / triage_failure contract"
            ),
        )

    # Build the 8-field metadata block + envelope-faithful wrap (Q5A).
    metadata = _build_metadata(raw_path, raw_bytes, raw_dict,
                               result.redaction_events)
    wrapped = {"_fixture_metadata": metadata, **result.payload}

    # Serialize with determinism contract: sort_keys=True locks key order,
    # indent=2 locks whitespace, trailing newline for POSIX-friendly diff.
    #
    # MOD-1c: json.dumps recurses on deeply-nested output; mirror of the
    # redact-phase RecursionError handler (~line 380) — same bucket, same
    # reason-shape. Note: if we reach here, redact_early_failure succeeded
    # (`_redact_node` tolerated the depth) but serialization on the
    # redacted-but-still-deep payload can still hit the recursion limit.
    # The 3-site coverage (parse / redact / serialize) is what makes the
    # per-payload boundary actually total. Fail-closed property: if
    # json.dumps raises, `fixture_text` is never assigned, so the
    # downstream `_audit_fixture_for_credentials` and `tmp_path.write_text`
    # are never reached — no .tmp file is created. DA-1 sequencing
    # invariant (below) is preserved: this catch sits BEFORE the
    # in-memory dual sweep, not around it.
    try:
        fixture_text = json.dumps(
            wrapped, sort_keys=True, indent=2, ensure_ascii=False
        ) + "\n"
    except RecursionError as exc:
        return EmissionResult(
            run_id=run_id,
            bucket="malformed_input",
            malformed_reason=(
                "input depth exceeded Python recursion limit during "
                f"JSON serialize: {type(exc).__name__}"
            ),
        )

    # ========================================================================
    # DA-1 SECURITY-SEQUENCING INVARIANT (load-bearing — M11 partial-catch).
    #
    # The dual sweep MUST complete in memory BEFORE any .tmp write to disk.
    # Reordering this sequence (e.g., writing .tmp first, then sweeping the
    # on-disk bytes) creates a window where credential content is persisted
    # to the filesystem even when sweep later fails-closed.
    #
    # DO NOT REORDER without:
    #   1. Updating M11 in the mutation table (test_redactor_pipeline.py)
    #   2. Adding a test that observes the transient write window
    #   3. Re-running the full 8-gate battery
    #
    # Tests cannot directly observe the transient .tmp existence (cleanup
    # is synchronous in the fail-closed path); this comment is the
    # load-bearing control for that mutation class.
    # ========================================================================
    try:
        _audit_fixture_for_credentials(wrapped, fixture_text)
    except CredentialSentinelFired as exc:
        return EmissionResult(
            run_id=run_id,
            bucket="sentinel_fired",
            sentinel_event=exc.event,
        )

    # DA-6: basename collision check before any write.
    output_name = _output_filename(metadata)
    if output_name in seen_basenames:
        return EmissionResult(
            run_id=run_id,
            bucket="malformed_input",
            malformed_reason=(
                f"basename collision in batch: {output_name!r} already "
                "emitted by an earlier payload — two raws map to the same "
                "fixture filename"
            ),
        )
    seen_basenames.add(output_name)

    # Atomic write: .tmp in the SAME dir (same-filesystem requirement for
    # os.replace atomicity), then atomic-overwrite rename. os.replace is
    # cross-platform; os.rename has Windows quirks we don't need to
    # tolerate.
    final_path = fixture_dir / output_name
    tmp_path = fixture_dir / (output_name + ".tmp")
    tmp_path.write_text(fixture_text, encoding="utf-8")
    os.replace(tmp_path, final_path)

    return EmissionResult(
        run_id=run_id,
        bucket="emitted",
        fixture_path=final_path,
        fixture_bytes=len(fixture_text.encode("utf-8")),
    )


# ---------------------------------------------------------------------------
# DA-4 startup orphan check — OPERATIONAL INTEGRITY, NOT credentials
# ---------------------------------------------------------------------------

def _check_orphans(fixture_dir: Path) -> list:
    """Scan `fixture_dir` for stale `.tmp` orphans from a prior crash.

    IMPORTANT — rationale: per DA-1 the dual sweep ran in memory before
    any .tmp was written, so an orphaned .tmp file contains content that
    was sweep-clean at write time. This check does NOT protect against
    credential leakage; that's already covered by the in-memory sweep.

    It protects OPERATIONAL INTEGRITY:
      - A stale .tmp indicates a previous emission crashed or was killed
        mid-write. The operator needs to know and investigate.
      - Auto-deleting orphans would mask the prior failure.
      - Leaving them in place could confuse a future operator into thinking
        the .tmp IS the fixture.

    DO NOT "simplify" this control to a silent auto-delete (a future
    maintainer reading the docstring's correct threat model is the
    protection against that).

    Returns the sorted list of orphan paths; caller decides whether to
    refuse to proceed.
    """
    return sorted(fixture_dir.glob("*.tmp"))


# ---------------------------------------------------------------------------
# Batch orchestration
# ---------------------------------------------------------------------------

def emit_batch(raw_paths: list, fixture_dir: Path,
               batch_log_path: Optional[Path] = None) -> dict:
    """Emit fixtures for a batch of raw scratch payloads.

    Returns the batch summary dict with 3-bucket taxonomy (DA-3).

    Writes the batch summary as JSON to `batch_log_path` if provided.
    The batch log is an OPERATOR ARTIFACT, NOT committed to the repo
    (default location is `~/scratch/triage-day4/_batch_<ISO>.json`).

    The batch log INHERITS the metadata-only rule: SentinelEvent fields
    only (pattern_name, field_path, offset, length), NEVER matched values,
    NEVER `str(exc)` from any wrapper that might have re-included input
    context. This is the one remaining surface where a careless
    implementation could relocate the credential leak.

    Raises RuntimeError if `.tmp` orphans are present in fixture_dir at
    startup (DA-4 operational-integrity guard).
    """
    orphans = _check_orphans(fixture_dir)
    if orphans:
        listing = "\n".join(f"  {p}" for p in orphans)
        raise RuntimeError(
            f"refusing to proceed: {len(orphans)} stale .tmp orphan(s) in "
            f"{fixture_dir} from a prior emission failure. Investigate and "
            "clean up manually before re-running:\n"
            f"{listing}\n\n"
            "(These files contain no credentials — per DA-1 they were "
            "sweep-clean before being written — but their presence indicates "
            "a previous emission crashed mid-write, which the operator "
            "should diagnose rather than silently overwrite.)"
        )

    seen_basenames: set = set()
    emitted: list = []
    sentinel_fired: list = []
    malformed: list = []

    for raw_path in raw_paths:
        result = emit_single(raw_path, fixture_dir, seen_basenames)
        if result.bucket == "emitted":
            emitted.append(result)
        elif result.bucket == "sentinel_fired":
            sentinel_fired.append(result)
        else:  # 'malformed_input'
            malformed.append(result)

    summary = {
        "emitted_count": len(emitted),
        "sentinel_fired_count": len(sentinel_fired),
        "malformed_input_count": len(malformed),
        "emitted": [
            {
                "run_id": r.run_id,
                "fixture_path": str(r.fixture_path),
                "fixture_bytes": r.fixture_bytes,
            }
            for r in emitted
        ],
        # Metadata-only — pattern_name + field_path + offset + length.
        # NEVER include matched values or `str(exc)` wrappers.
        "sentinel_fired": [
            {
                "run_id": r.run_id,
                "pattern_name": r.sentinel_event.pattern_name,
                "field_path": r.sentinel_event.field_path,
                "offset": r.sentinel_event.offset,
                "length": r.sentinel_event.length,
            }
            for r in sentinel_fired
        ],
        "malformed_input": [
            {"run_id": r.run_id, "reason": r.malformed_reason}
            for r in malformed
        ],
    }

    if batch_log_path is not None:
        batch_log_path.parent.mkdir(parents=True, exist_ok=True)
        batch_log_path.write_text(
            json.dumps(summary, sort_keys=True, indent=2) + "\n",
            encoding="utf-8",
        )

    return summary


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _default_batch_log_path() -> Path:
    """Default operator-artifact location (NOT committed to repo).

    The ISO timestamp here is fine because G8-1's determinism rule
    applies to FIXTURE CONTENT, not to operator-only run logs.
    """
    iso = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    return DEFAULT_INPUT_DIR / f"_batch_{iso}.json"


def main(argv: Optional[list] = None) -> int:
    """CLI entry point.

    Usage:
        .venv/bin/python3 -m scripts.automation.src.triage.redactor_pipeline \\
            --input ~/scratch/triage-day4/run_485850628_cluster_A.json

        .venv/bin/python3 -m scripts.automation.src.triage.redactor_pipeline \\
            --all

    Exit codes:
        0 = all payloads emitted cleanly
        1 = at least one sentinel_fired or malformed_input (see batch log)
        2 = startup refused (DA-4 .tmp orphan present, or CLI usage error)
    """
    parser = argparse.ArgumentParser(
        description=(
            "Redactor pipeline — pipe raw scratch payloads through "
            "redact_early_failure() and emit deterministic, sweep-clean "
            "fixtures."
        ),
    )
    parser.add_argument(
        "--input", action="append", type=Path, default=None,
        help=(
            "Raw scratch JSON file (repeatable). Mutually exclusive with "
            "--all."
        ),
    )
    parser.add_argument(
        "--input-dir", type=Path, default=DEFAULT_INPUT_DIR,
        help=(
            f"Directory containing raw scratch JSON files "
            f"(default: {DEFAULT_INPUT_DIR}). Used with --all."
        ),
    )
    parser.add_argument(
        "--all", action="store_true",
        help=(
            "Process all files matching `run_*_cluster_*.json` in --input-dir."
        ),
    )
    parser.add_argument(
        "--output-dir", type=Path, default=DEFAULT_FIXTURE_DIR,
        help=f"Output fixture directory (default: {DEFAULT_FIXTURE_DIR}).",
    )
    parser.add_argument(
        "--batch-log", type=Path, default=None,
        help=(
            "Batch summary JSON path (default: "
            "~/scratch/triage-day4/_batch_<ISO>.json). NOT committed."
        ),
    )
    args = parser.parse_args(argv)

    # Resolve input list.
    if args.all:
        if args.input:
            parser.error("--input and --all are mutually exclusive")
        raw_paths = sorted(args.input_dir.glob("run_*_cluster_*.json"))
        if not raw_paths:
            parser.error(
                f"no raw payloads matching `run_*_cluster_*.json` found "
                f"in {args.input_dir}"
            )
    elif args.input:
        raw_paths = list(args.input)
    else:
        parser.error("either --input or --all is required")

    fixture_dir = args.output_dir.resolve()
    fixture_dir.mkdir(parents=True, exist_ok=True)
    batch_log_path = args.batch_log or _default_batch_log_path()

    try:
        summary = emit_batch(raw_paths, fixture_dir, batch_log_path)
    except RuntimeError as exc:
        # DA-4 orphan refusal — distinguished from other errors by exit 2.
        # R2 construction exemption: `exc` at this site is the RuntimeError
        # raised by `_ensure_no_orphans`, whose message is built from
        # `_check_orphans(fixture_dir)` output. Orphan paths come from
        # `fixture_dir.glob("*.tmp")`; `.tmp` basenames are constructed by
        # `_output_filename` from raw filenames validated against
        # `RAW_FILENAME_PATTERN`. No path component is derived from
        # payload bytes — only from CLI `--output-dir` and validated
        # `run_<id>_cluster_<X>` filename matches.
        # Falsifiable: this exemption fails if `_check_orphans` ever
        # returns paths derived from payload content, or if
        # `_ensure_no_orphans` interpolates payload-derived strings
        # into its RuntimeError message.
        # See: docs/triage-agent/credential-threat-model.md
        # §Construction Exemption.
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    # Operator-friendly summary on stdout.
    print(f"Batch summary (full log: {batch_log_path}):")
    print(f"  emitted:         {summary['emitted_count']}")
    print(f"  sentinel_fired:  {summary['sentinel_fired_count']}")
    print(f"  malformed_input: {summary['malformed_input_count']}")

    if summary["sentinel_fired_count"] > 0:
        print("\nSENTINEL FIRES (operator must investigate):", file=sys.stderr)
        for entry in summary["sentinel_fired"]:
            print(
                f"  run_id={entry['run_id']} pattern={entry['pattern_name']} "
                f"path={entry['field_path']} offset={entry['offset']} "
                f"length={entry['length']}",
                file=sys.stderr,
            )

    if summary["malformed_input_count"] > 0:
        print("\nMALFORMED INPUTS:", file=sys.stderr)
        for entry in summary["malformed_input"]:
            print(
                f"  run_id={entry['run_id']}: {entry['reason']}",
                file=sys.stderr,
            )

    if (summary["sentinel_fired_count"] > 0
            or summary["malformed_input_count"] > 0):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
