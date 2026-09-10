"""Fixture loader — explicit strip of `_fixture_metadata` before consumer use.

The committed early-failure fixtures in `docs/triage-agent/fixtures/`
carry the canonical 3-key envelope `{_fixture_metadata, data, status}`.
The metadata block holds 8 audit fields (content_sha256, source_basename,
source_size_bytes, etc.) that describe HOW the fixture was produced;
consumers of the triage harness only depend on the WHAT (`data`, `status`).

D4 review (Kumar 2026-06-11) confirmed the harness was in G7-1
dispatcher-drop posture by accident: `_redact_node` dropped the 8 scalar
metadata fields via the "Unknown leaf — drop (defense in depth, §5.1)"
branch, and `_project_payload` ignored anything outside
`data.run_steps[-1]` and `data` at the top level. The harness passed
because the leak path happened to be projection-blind, not because
anyone removed the leak. Any future non-scalar metadata field (e.g.,
`step_keys_present: [str]`) would survive `_redact_node`'s list-recurse
branch and reach rationale/log paths.

This module retires that reliance. `load_fixture(path)` does the pop
explicitly. The pop uses `pop(..., None)` so the function is a no-op
on payloads without `_fixture_metadata` (raw scratch payloads, future
schema variants) — a single chokepoint both label branches of
`resolve_payload_path` can feed safely.

Public API: `load_fixture(path) -> dict`.
"""

from __future__ import annotations

import json
from pathlib import Path


def load_fixture(path: Path) -> dict:
    """Read a committed early-failure fixture; strip `_fixture_metadata`.

    Returns the envelope's `data`/`status` payload only — the audit
    metadata block is discarded so the body the harness consumes
    cannot carry fixture-only fields into rationale, logs, or future
    LLM context.

    Idempotent on payloads without `_fixture_metadata` (raw scratch
    payloads, hand-built test bodies, future schema variants); the
    pop is `pop(..., None)` so calling sites can use this helper
    anywhere a dbt Cloud early-failure body is expected without
    needing to know the source provenance.

    The JSON root MUST be a dict — non-dict roots (lists, scalars) are
    rejected with `TypeError` at this chokepoint rather than
    propagating through `load_raw_payload`'s `Optional[dict]` and
    lying to downstream type consumers. No production caller consumes
    non-dict roots (every callsite does dict access on the return); if
    a real non-dict fixture ever needs to ship, widen the annotation
    AT THAT POINT with a known requirement, not pre-emptively here.
    Tightened 2026-06-21 (PR #1821 Commit 6, R4 finding N1/N2) from a
    permissive-passthrough that lied to every typed caller.
    """
    body = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(body, dict):
        raise TypeError(
            f"Fixture root must be a JSON object, got "
            f"{type(body).__name__}: {path}"
        )
    body.pop("_fixture_metadata", None)
    return body
