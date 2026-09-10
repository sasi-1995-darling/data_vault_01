"""Field-aware redaction for the DV Failure Triage Agent — v1.0.0.

Source-of-truth design: ``docs/triage-agent/gate-d-findings.md`` §5.
This module turns raw dbt Cloud run artifacts (or early-failure run_step
payloads) into LLM-safe payloads by applying a closed allowlist and a
narrow regex pass over only the fields known to need it.

Architecture (LOCKED — do not relax without amending gate-d-findings.md):

  1. **Field-aware allowlist FIRST, narrow regex SECOND.** Pattern-only
     redaction on real artifacts produced 95%+ false positives (24-307
     phone/cc-shaped matches per artifact, all false). Strip or
     selectively redact known-risky fields, then apply regex only where
     signal exists.

  2. **Regex eligibility is a frozenset invariant.** ``REGEX_ELIGIBLE_FIELDS``
     gates every regex application. Adding a field requires a PR amendment
     to this module AND to gate-d-findings.md §5.3.

  3. **Excluded patterns are coded in.** ``EXCLUDED_PATTERNS`` carries
     negative evidence so future engineers cannot silently re-introduce
     phone_us / cc_like / ssn / ip_address (see §5.4 for the FP analysis).

  4. **Credential sentinel never logs the matched value.** Only pattern
     name, field path, offset, length. Item #6 in §5.6 is THE most
     important rule in this module — logging the credential value to
     forensics is worse than never detecting it.

  5. **Literal-stripped preview for compiled_code / raw_code.** sqlparse
     tokenises and replaces ``Token.Literal.String.*`` and ``Token.Comment.*``
     with sentinels BEFORE truncation. The 500-char head frequently lands
     in WHERE/IN clauses where literals re-appear; truncation alone is not
     sufficient.

  6. **Audit-before-transform (v1.1.0+).** Public entrypoints invoke
     ``audit_raw_for_credentials`` as step 0 — BEFORE any lossy transform
     (truncation, field-routing, preview projection). Per R1 of
     ``docs/triage-agent/credential-threat-model.md`` (sentinel-before-
     transform): field-routing and truncation are NOT credential
     mitigations. The audit walks every str leaf of the raw payload
     regardless of allowlist membership. Proving tests: ``TestRawAudit``
     in tests/test_triage_redact.py.

The five invariants 2-6 above each have a dedicated mutation-verified
test in ``tests/test_triage_redact.py``. Mutating any one of them in
isolation must cause at least one test to fail.

Day-3.8 amendment (Sprint-1 #12) — `logs` field support
-------------------------------------------------------

Extended ``REGEX_ELIGIBLE_FIELDS`` to include ``run_steps[*].logs``
(full runtime log, up to ~2.9 MB).

**Round 3.5.5 closure (2026-06-05):** the original Day-3.8 hybrid
truncation (last-anchor + ±16 KB window) was empirically falsified
on the 7 Day-4 P0.1 payloads — Cluster A placed the actionable error
≈ 2.67 MB outside the window because the generic ``\bfailed\b`` anchor
matched manifest-dump noise at byte 2.69 M and beat the specific
``Encountered an error:`` anchor at byte 315. Round 3 + Round 3.5
methodology iteration was superseded by a 5-rule spike that passed
7/7 real payloads + 8/8 synthetic fixtures on first run. See
``docs/triage-agent/round-3.5.5-spike-results.md`` for the spike
evidence; ``docs/triage-agent/lessons-learned.md`` 2026-06-05 entry 4
for the methodology lesson.

New algorithm (Mut_R1a–R5, all mutation-guarded in test_triage_redact.py):

  Rule 1: empty/short input → noop
  Rule 2: scan for EARLIEST occurrence of any of 5 SPECIFIC anchors
          (generics excluded — that was the Cluster A failure)
  Rule 3: anchor in first 64 KB → first 64 KB returned
  Rule 4: anchor in body/tail → ±16 KB window centered on anchor
  Rule 5: no specific anchor → tail 64 KB

Mut9d is still enforced in ``fbin_error_catalog.py`` (catalog load-time
gate that patterns citing ``logs`` declare ``max_bytes ∈ [1, LOGS_MAX_BYTES]``).

Ordering (v1.1.0 contract — audit-before-transform per R1):

  audit_raw_for_credentials (raw payload, every str leaf)
    → field-aware allowlist
    → truncate_logs (logs only, post-audit, post-allowlist)
    → _apply_regex credential check (downstream defense-in-depth)
    → email pass

``audit_raw_for_credentials`` runs BEFORE any lossy transform
(truncation, field-routing, preview projection) — per
``docs/triage-agent/credential-threat-model.md`` R1
(sentinel-before-transform). The matcher-latency target for
``_apply_regex`` is met by it operating downstream on truncated /
allowlist-filtered fields. The audit pass is an
O(payload-bytes × |CREDENTIAL_PATTERNS|) sweep of str leaves only;
the threat model explicitly forbids trading the audit away for
latency. The downstream ``_apply_regex`` credential check remains as
defense-in-depth — it covers the same patterns the audit already
scanned, so a future audit-skip would still hit it for allowlisted
fields. Proving test:
``TestRawAudit::test_credential_anywhere_in_logs_fires_sentinel``.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any, Optional, Tuple

import sqlparse
from sqlparse import tokens as T


# ---------------------------------------------------------------------------
# Versioning
# ---------------------------------------------------------------------------

# v1.1.0 (2026-06-16): added audit_raw_for_credentials step 0 in public
# entrypoints. Payload shape unchanged (non-breaking); credential-safety
# contract changed — audit is now part of the redactor's guarantee per
# docs/triage-agent/credential-threat-model.md R1.
# v1.2.0 (2026-06-17): removed RedactionResult.sentinel_events field and
# .sentinel_fired property. The field was always () in production — sentinel
# fires raise CredentialSentinelFired rather than accumulate into the result.
# The outcome enum (Outcome.CREDENTIAL_SENTINEL_FIRED) is the source of truth.
# Minor bump: no correct consumer depended on the removed attributes.
REDACT_SCHEMA_VERSION = "v1.2.0"

# sqlparse version is embedded in every preview payload so a future
# behaviour change in the tokenizer is traceable in the observability log.
# Read at import to fail loudly if the dependency disappears.
LITERAL_STRIP_METHOD = f"sqlparse_v{sqlparse.__version__}"


# ---------------------------------------------------------------------------
# Allowlist — see gate-d-findings.md §5.1
# ---------------------------------------------------------------------------

# Fields that pass through unchanged (no regex, no transform).
PASSTHROUGH_FIELDS = frozenset([
    "unique_id",
    "relation_name",
    "status",
    "execution_time",
    "query_id",
    "rows_affected",
    "name",
    "status_humanized",
    "started_at",
    "finished_at",
])

# Fields replaced with a literal-stripped preview (see §5.2).
PREVIEW_FIELDS = frozenset(["compiled_code", "raw_code"])

# Fields eligible for regex application. Adding here requires a PR
# amendment to gate-d-findings.md §5.3 (or gate-d-logs-field-amendment.md
# for `logs`) — this is an enforced invariant, not a documentation suggestion.
REGEX_ELIGIBLE_FIELDS = frozenset([
    "message",
    "truncated_debug_logs",
    "status_message",
    # Day 3.8 (Sprint-1 #12): early-failure mode pattern matching.
    # Hybrid-truncated to LOGS_MAX_BYTES before sentinel pass.
    # Source: docs/triage-agent/gate-d-logs-field-amendment.md §3.2
    "logs",
])


# ---------------------------------------------------------------------------
# Excluded patterns — negative evidence (gate-d-findings.md §5.4)
# ---------------------------------------------------------------------------
# DO NOT silently omit any of these. Each one has documented false-positive
# evidence from the 2026-06-03 Gate D analysis on 6 real artifacts:
#   - phone_us:   24+ FPs/artifact from 10-digit zero-padded customer IDs
#                 like '0000001016' in SQL IN(...) literals.
#   - cc_like:    26-307 FPs/artifact from execution_time floats like
#                 18.03371024131775 in adapter_response metadata.
#   - ssn:        Zero real matches across stratified sample.
#   - ip_address: Zero real matches; would catch Snowflake account
#                 locators (already covered by url_with_creds).
EXCLUDED_PATTERNS = frozenset(["phone_us", "cc_like", "ssn", "ip_address"])


# ---------------------------------------------------------------------------
# Active patterns
# ---------------------------------------------------------------------------

EMAIL_PATTERN = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
EMAIL_REDACTION = "<EMAIL_REDACTED>"

# Credential family — ANY match fires the sentinel (see §5.6).
# Patterns are conservative; false positives here are SAFE (halt + human
# review), false negatives are CATASTROPHIC (credential exfiltration).
CREDENTIAL_PATTERNS: Tuple[Tuple[str, "re.Pattern[str]"], ...] = (
    # AWS access keys: AKIA / ASIA + 16 uppercase alphanumerics
    ("aws_access_key", re.compile(r"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b")),
    # PEM-style private keys (any variant)
    ("private_key", re.compile(r"-----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED |)PRIVATE KEY-----")),
    # JWT: three base64url segments separated by dots (header.payload.sig)
    ("jwt", re.compile(r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b")),
    # Bearer / Authorization tokens
    ("bearer_token", re.compile(r"(?i)\b(?:bearer|authorization)\s*[:=]\s*[A-Za-z0-9._\-+/=]{20,}")),
    # dbt Cloud personal/service tokens (40 hex)
    ("dbt_token", re.compile(r"\bdbtu_[A-Za-z0-9]{32,}\b")),
    # Snowflake password parameter in URL/connection string
    ("snowflake_pwd", re.compile(r"(?i)(?:password|pwd)\s*=\s*[^\s;&]{6,}")),
    # URL with embedded credentials: scheme://user:pwd@host
    ("url_with_creds", re.compile(r"[a-z][a-z0-9+.-]*://[^\s/@]+:[^\s/@]+@")),
)


# ---------------------------------------------------------------------------
# Preview spec (gate-d-findings.md §5.2)
# ---------------------------------------------------------------------------

PREVIEW_MAX_CHARS = 500
PREVIEW_ELLIPSIS = "..."
LITERAL_SENTINEL = "<LIT>"
COMMENT_SENTINEL = "<COMMENT>"


# ---------------------------------------------------------------------------
# Result types
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class SentinelEvent:
    """Metadata-only record of a credential pattern match. NEVER contains
    the matched value — see gate-d-findings.md §5.6 item #6."""

    pattern_name: str
    field_path: str
    offset: int
    length: int


class CredentialSentinelFired(Exception):
    """Raised when a credential pattern matches in any REGEX_ELIGIBLE field.

    The exception carries metadata ONLY (pattern name, field path, byte
    offset, match length). It MUST NOT carry the matched value — the
    caller writes this metadata to TRIAGE_INVOCATIONS for forensics, and
    logging the credential value there is a P0 incident.
    """

    def __init__(self, event: SentinelEvent) -> None:
        self.event = event
        super().__init__(
            f"credential pattern {event.pattern_name!r} fired in field "
            f"{event.field_path!r} at offset {event.offset} "
            f"(length {event.length})"
        )


@dataclass(frozen=True)
class RedactionResult:
    """Output of a redaction pass."""

    payload: dict
    redaction_events: int = 0


# ---------------------------------------------------------------------------
# Literal-stripped preview
# ---------------------------------------------------------------------------

def _literal_stripped_preview(sql: Optional[str]) -> dict:
    """Return a preview-shaped dict for compiled_code / raw_code.

    Replaces string literals and comments with sentinels via sqlparse,
    then truncates to PREVIEW_MAX_CHARS using first_n_chars_then_ellipsis.

    Returns the §5.2 payload shape regardless of input — never raises on
    malformed SQL (falls back to literal-free truncation).
    """
    if not sql:
        return {
            "literal_stripped_preview": "",
            "preview_chars": 0,
            "preview_truncated": False,
            "literal_strip_method": LITERAL_STRIP_METHOD,
        }

    try:
        parsed = sqlparse.parse(sql)
        out_parts = []
        for stmt in parsed:
            for tok in stmt.flatten():
                ttype = tok.ttype
                if ttype is not None and ttype in T.Literal.String:
                    out_parts.append(LITERAL_SENTINEL)
                elif ttype is not None and ttype in T.Comment:
                    out_parts.append(COMMENT_SENTINEL)
                else:
                    out_parts.append(tok.value)
        stripped = "".join(out_parts)
    except Exception:  # noqa: BLE001 — fallback path is intentional
        # sqlparse should never raise on valid Python str, but if a future
        # version regresses, fail SAFE: drop everything that looks like a
        # string literal via a coarse regex. Better an over-aggressive
        # preview than leaking the original SQL.
        stripped = re.sub(r"'[^']*'", LITERAL_SENTINEL, sql)
        stripped = re.sub(r"--[^\n]*", COMMENT_SENTINEL, stripped)

    truncated = len(stripped) > PREVIEW_MAX_CHARS
    if truncated:
        preview = stripped[: PREVIEW_MAX_CHARS - len(PREVIEW_ELLIPSIS)] + PREVIEW_ELLIPSIS
    else:
        preview = stripped

    return {
        "literal_stripped_preview": preview,
        "preview_chars": len(preview),
        "preview_truncated": truncated,
        "literal_strip_method": LITERAL_STRIP_METHOD,
    }


# ---------------------------------------------------------------------------
# Truncation for `logs` field — Round 3.5.5 5-rule algorithm
# ---------------------------------------------------------------------------
# Replaces the Day-3.8 hybrid (last-anchor + ±16KB) that was empirically
# falsified on Cluster A payloads. Spec, evidence, and methodology lesson:
#
#   docs/triage-agent/round-3.5.5-spike-results.md   (spike outcome)
#   docs/triage-agent/lessons-learned.md             (2026-06-05 entry 4)
#   scripts/automation/triage/spike_truncate_v2.py   (spike harness)
#
# Key change from Day-3.8: generic anchors (\bfailed\b, ^ERROR\b) are
# REMOVED from ERROR_ANCHORS. Cluster A failure mechanism was
# generic_failed @ byte 2.69M beating specifics; dropping generics
# entirely + earliest-position-wins sidesteps the cross-position
# selection complexity (lesson cd9876ee).
#
# Documented limitations (mutation tests reference both):
#
#   1. Rule 3 head-boundary clipping (Mut_R3_boundary): when an anchor's
#      first byte falls in [HEAD_BOUNDARY − len(anchor) + 1, HEAD_BOUNDARY − 1],
#      the head-window cut splits the anchor substring. Real-world
#      likelihood: low; mitigation deferred until backtest evidence
#      justifies (Round-4 trigger: >5% of Day-6+ failures exhibit this).
#
#   2. Earliest-position-wins limitation (synth_04 fixture): when an
#      anchor literal appears in non-error contexts (e.g., dbt seed file
#      containing "Database Error" as CSV row data), Rule 2 picks the
#      data-row position over the real error. No algorithm mitigation
#      ships in v2; same Round-4 trigger threshold applies.

SHORT_LOG_THRESHOLD = 1024     # bytes; logs ≤ this returned as-is (Rule 1)
HEAD_WINDOW = 65_536           # bytes; first 64 KB if anchor in head (Rule 3)
ANCHOR_WINDOW_HALF = 16_384    # bytes; ±16 KB centered on anchor (Rule 4)
TAIL_FALLBACK = 65_536         # bytes; last 64 KB if no anchor (Rule 5)
HEAD_BOUNDARY = 65_536         # bytes; head vs body/tail partition

# Hard size cap on any truncate_logs output (Mut9b carry-over from Day 3.8).
# Equals max(HEAD_WINDOW, TAIL_FALLBACK, 2*ANCHOR_WINDOW_HALF) = 65,536 B.
LOGS_MAX_BYTES = max(
    HEAD_WINDOW,
    TAIL_FALLBACK,
    ANCHOR_WINDOW_HALF * 2,
)

# Specificity-ordered. Generics intentionally excluded (see header
# comment above and lessons-learned 2026-06-05 entry 4). The list order
# is enumeration only; within a payload Rule 2 takes the earliest-
# position match across ALL five.
ERROR_ANCHORS: Tuple[str, ...] = (
    "Encountered an error:",
    "Traceback (most recent call last):",
    "Database Error",
    "Compilation Error",
    "Runtime Error",
)


def _find_earliest_anchor(text: str) -> Optional[Tuple[int, str]]:
    """Scan ``text`` for the EARLIEST occurrence of any anchor in
    ``ERROR_ANCHORS``. Returns ``(start_position, anchor_name)`` or
    ``None`` if no anchor matches.

    Earliest-position-wins is intentional (Round-3 cross-position
    scoping lesson, cd9876ee): position is the only tiebreaker, so
    no cross-position selection rule is needed.
    """
    best: Optional[Tuple[int, str]] = None
    for anchor in ERROR_ANCHORS:
        idx = text.find(anchor)
        if idx == -1:
            continue
        if best is None or idx < best[0]:
            best = (idx, anchor)
    return best


def truncate_logs(text: Optional[str]) -> Tuple[str, str]:
    """5-rule truncation for the ``logs`` field — Round 3.5.5 algorithm.

    Returns ``(truncated_text, strategy_used)``. Strategy tags:

      - ``"noop:none"``        — input was ``None``
      - ``"noop:empty"``       — input was empty string
      - ``"noop:short"``       — input ≤ SHORT_LOG_THRESHOLD (1024 B)
      - ``"head:<anchor>"``    — Rule 3 fired (anchor < HEAD_BOUNDARY)
      - ``"window:<anchor>"``  — Rule 4 fired (anchor ≥ HEAD_BOUNDARY)
      - ``"tail:no_anchor"``   — Rule 5 fired (no specific anchor)

    Invariants (mutation-guarded — see test_triage_redact.py):

      Mut_R1a: None/empty → ("", "noop:none"|"noop:empty")
      Mut_R1b: short (≤1024B) input returned unchanged with "noop:short"
      Mut_R2:  earliest position across all 5 anchors wins
      Mut_R3:  anchor in [0, HEAD_BOUNDARY) → first HEAD_WINDOW bytes
      Mut_R3_boundary: anchor starting at HEAD_BOUNDARY−k for k<len(anchor)
                  exhibits documented clipping (regression detector)
      Mut_R4:  anchor in [HEAD_BOUNDARY, len) → ±ANCHOR_WINDOW_HALF window
      Mut_R5:  no recognized anchor → last TAIL_FALLBACK bytes

    Hard cap: ``len(truncate_logs(text)[0]) ≤ LOGS_MAX_BYTES`` (65,536 B)
    for ALL inputs (Mut9b carry-over from Day 3.8).

    Type contract:

      - ``None``    → ``("", "noop:none")``
      - ``""``      → ``("", "noop:empty")``
      - non-``str`` → raises ``TypeError``
    """
    # Type contract
    if text is None:
        return "", "noop:none"
    if not isinstance(text, str):
        raise TypeError(
            f"truncate_logs expects str or None, got {type(text).__name__}"
        )

    # Rule 1: empty / short
    if not text:
        return "", "noop:empty"
    if len(text) <= SHORT_LOG_THRESHOLD:
        return text, "noop:short"

    # Rule 2: find EARLIEST match across all specific anchors
    anchor = _find_earliest_anchor(text)

    # Rule 3: anchor in head region → first HEAD_WINDOW bytes
    if anchor is not None and anchor[0] < HEAD_BOUNDARY:
        return text[:HEAD_WINDOW], f"head:{anchor[1]}"

    # Rule 4: anchor in body/tail → ±ANCHOR_WINDOW_HALF window
    if anchor is not None:
        start = max(0, anchor[0] - ANCHOR_WINDOW_HALF)
        end = min(len(text), anchor[0] + ANCHOR_WINDOW_HALF)
        return text[start:end], f"window:{anchor[1]}"

    # Rule 5: no specific anchor → tail fallback
    return text[-TAIL_FALLBACK:], "tail:no_anchor"


# ---------------------------------------------------------------------------
# Path convention helpers — shared by _redact_node and _walk_str_leaves
# ---------------------------------------------------------------------------
# These tiny helpers are the single source of truth for field-path
# composition. tests/test_triage_redact.py L283 asserts
# "truncated_debug_logs" in event.field_path; the redactor walk and the
# R1 audit walk MUST produce identical path strings. Sharing these helpers
# couples the path convention without coupling the two walks' semantics
# (redactor prunes by allowlist; audit must visit all str leaves).

def _child_path(parent: str, key: str) -> str:
    """Compose a dotted child path: ``'parent.key'``, or ``'key'`` at root."""
    return f"{parent}.{key}" if parent else key


def _list_element_path(parent: str) -> str:
    """Compose a list-element path: ``'parent[]'``."""
    return f"{parent}[]"


# ---------------------------------------------------------------------------
# Credential scan — single canonical pattern-loop site
# ---------------------------------------------------------------------------

def _scan_for_credentials(
    text: str,
    field_path: str,
) -> Optional[SentinelEvent]:
    """Scan ``text`` against ``CREDENTIAL_PATTERNS``; return the first
    match as a ``SentinelEvent`` or ``None`` if no pattern matched.

    Field-local offset semantics: returned ``offset`` is ``m.start()``
    against the input ``text``, NEVER a cumulative walk position.
    Locked by tests/test_triage_redact.py L294
    (``test_sentinel_records_offset_and_length``).

    Returns ``None`` on empty / non-str input — safe for both call sites
    (``_apply_regex`` and ``audit_raw_for_credentials``).

    This is the ONLY pattern-loop site in the module — both the public
    audit and the downstream ``_apply_regex`` call it. A single mutation
    (e.g., ``search`` → ``match``) breaks both call paths uniformly,
    which is the desired behaviour: there is no way to credential-scan
    in this module that bypasses these patterns.
    """
    if not isinstance(text, str) or not text:
        return None
    for pattern_name, pattern in CREDENTIAL_PATTERNS:
        m = pattern.search(text)
        if m is not None:
            return SentinelEvent(
                pattern_name=pattern_name,
                field_path=field_path,
                offset=m.start(),
                length=m.end() - m.start(),
            )
    return None


# ---------------------------------------------------------------------------
# Regex pass
# ---------------------------------------------------------------------------

def _apply_regex(
    field_path: str,
    text: str,
) -> Tuple[str, int]:
    """Apply email + credential regex to a single REGEX_ELIGIBLE field.

    Returns (redacted_text, redaction_event_count).
    Raises CredentialSentinelFired on first credential pattern match.

    Defense-in-depth: the credential scan here is ALSO performed by
    ``audit_raw_for_credentials`` as step 0 of the public entrypoints
    (v1.1.0+). This downstream check covers the same patterns for
    allowlisted fields so a future audit-skip would still hit it here.

    Caller MUST gate on ``field_path`` being in REGEX_ELIGIBLE_FIELDS —
    this function does not re-check (separation of concerns: gating is
    the dispatcher's job so a single mutation cannot bypass it).
    """
    if not isinstance(text, str) or not text:
        return text, 0

    # Credential sentinel — defense-in-depth (audit already ran step 0
    # in the public entrypoint; see ``audit_raw_for_credentials``).
    event = _scan_for_credentials(text, field_path)
    if event is not None:
        raise CredentialSentinelFired(event)

    # Email pass.
    new_text, count = EMAIL_PATTERN.subn(EMAIL_REDACTION, text)
    return new_text, count


# ---------------------------------------------------------------------------
# Dispatcher
# ---------------------------------------------------------------------------

def _redact_node(node: Any, path: str, events: list) -> Any:
    """Recursively redact a node per the allowlist policy.

    - dict: keep only keys in PASSTHROUGH | PREVIEW | REGEX_ELIGIBLE
            (defense in depth — anything else is dropped)
    - list: recurse into each element
    - str:  return as-is (regex application happens at the field level
            in the parent, not here)
    """
    if isinstance(node, dict):
        out: dict = {}
        for key, value in node.items():
            sub_path = _child_path(path, key)
            if key in PREVIEW_FIELDS:
                out[key] = _literal_stripped_preview(value)
            elif key in REGEX_ELIGIBLE_FIELDS:
                if isinstance(value, str):
                    # Hybrid truncation for `logs` (Day 3.8 / Sprint-1 #12).
                    # Ordering (v1.1.0): R1 audit (audit_raw_for_credentials)
                    # already ran in the public entrypoint BEFORE any walk
                    # reached this point. Truncation here is post-audit,
                    # post-allowlist; downstream _apply_regex re-scans the
                    # truncated value as defense-in-depth. See module
                    # docstring §Ordering.
                    if key == "logs":
                        value, _strategy = truncate_logs(value)
                    new_value, count = _apply_regex(sub_path, value)
                    out[key] = new_value
                    if count:
                        events.append(count)
                else:
                    # Non-string in a regex-eligible field: pass through.
                    # No regex applies; never silently coerce.
                    out[key] = value
            elif key in PASSTHROUGH_FIELDS:
                out[key] = value
            elif isinstance(value, (dict, list)):
                # Recurse to find nested allowlist matches (e.g.,
                # results[].adapter_response.query_id).
                redacted = _redact_node(value, sub_path, events)
                if redacted not in (None, {}, []):
                    out[key] = redacted
            else:
                # Unknown leaf — drop (defense in depth, see §5.1).
                continue
        return out

    if isinstance(node, list):
        return [_redact_node(item, _list_element_path(path), events) for item in node]

    # Bare leaf — return as-is. Allowlist gating happened at the parent.
    return node


# ---------------------------------------------------------------------------
# R1 raw-payload audit — step 0 of the public entrypoints
# ---------------------------------------------------------------------------
# See ``docs/triage-agent/credential-threat-model.md`` R1
# (sentinel-before-transform). The audit walks the raw payload BEFORE
# any lossy transform (truncation, field-routing, preview projection)
# so a credential planted in a field the allowlist would drop, or
# outside truncate_logs's retention window, is still detected. R1
# forbids treating field-routing or truncation as credential mitigations.

def _walk_str_leaves(node: Any, path: str):
    """Recursively yield ``(path, text)`` for every str leaf in ``node``.

    Sister walk to ``_redact_node`` — shares the field-path convention
    via ``_child_path`` / ``_list_element_path`` so produced paths are
    byte-identical (tests/test_triage_redact.py L283). Differs in
    semantics: this walk visits ALL str leaves regardless of allowlist
    membership; ``_redact_node`` prunes by allowlist. The two walks are
    deliberately NOT unified — unifying them would either prune the
    audit (breaking R1 teeth) or de-prune the redactor (breaking the
    allowlist contract).
    """
    if isinstance(node, dict):
        for key, value in node.items():
            yield from _walk_str_leaves(value, _child_path(path, key))
    elif isinstance(node, list):
        for item in node:
            yield from _walk_str_leaves(item, _list_element_path(path))
    elif isinstance(node, str):
        yield path, node


def audit_raw_for_credentials(payload: Any) -> None:
    """R1 audit — scan the raw payload structure for credential matches
    BEFORE any lossy transform (truncation, field-routing, preview
    projection, serialization).

    Raises ``CredentialSentinelFired`` on the FIRST pattern match.
    Returns normally if no pattern matches.

    Visits ALL str leaves, including fields the allowlist would later
    drop — required by R1 (field-routing is NOT a mitigation). See
    ``docs/triage-agent/credential-threat-model.md`` and
    ``TestRawAudit`` in tests/test_triage_redact.py.

    The downstream ``_apply_regex`` runs the same credential scan on
    allowlisted fields as defense-in-depth; a future audit-skip would
    still hit it for those fields.

    Called by the public entrypoints (``redact_artifact`` and
    ``redact_early_failure``) which type-check ``payload``; this
    function does not re-check.
    """
    for path, text in _walk_str_leaves(payload, ""):
        event = _scan_for_credentials(text, path)
        if event is not None:
            raise CredentialSentinelFired(event)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def redact_artifact(run_results: dict) -> RedactionResult:
    """Redact a dbt Cloud run_results.json payload (artifact mode).

    Returns a RedactionResult whose ``payload`` is safe to send to the
    LLM and persist to TRIAGE_INVOCATIONS.evidence_json.

    Raises CredentialSentinelFired on credential pattern match — caller
    MUST catch and log via the sanitized path (event metadata only).
    """
    if not isinstance(run_results, dict):
        raise TypeError(
            f"redact_artifact expects dict, got {type(run_results).__name__}"
        )

    # Step 0 (v1.1.0+) — R1 audit on raw structure before ANY lossy
    # transform. See module docstring §Ordering and
    # docs/triage-agent/credential-threat-model.md R1.
    audit_raw_for_credentials(run_results)

    events: list = []
    redacted = _redact_node(run_results, path="", events=events)
    return RedactionResult(
        payload=redacted,
        redaction_events=sum(events),
    )


def redact_early_failure(payload: dict) -> RedactionResult:
    """Redact an early-failure payload (run_steps + status_message).

    Same policy as artifact mode — see gate-d-findings.md §2: early-failure
    truncated_debug_logs has the SAME PII surface as compiled_code because
    dbt prints failing SQL to stderr.
    """
    if not isinstance(payload, dict):
        raise TypeError(
            f"redact_early_failure expects dict, got {type(payload).__name__}"
        )

    # Step 0 (v1.1.0+) — R1 audit on raw structure before ANY lossy
    # transform. See module docstring §Ordering and
    # docs/triage-agent/credential-threat-model.md R1.
    audit_raw_for_credentials(payload)

    events: list = []
    redacted = _redact_node(payload, path="", events=events)
    return RedactionResult(
        payload=redacted,
        redaction_events=sum(events),
    )
