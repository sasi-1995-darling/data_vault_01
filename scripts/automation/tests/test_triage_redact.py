"""Tests for ``scripts/automation/src/triage/redact.py`` v1.0.0.

Each of the four locked invariants from ``docs/triage-agent/gate-d-findings.md``
§5 has a dedicated guard test. The mapping is documented at the top of each
TestCase so reviewers can mutate one source line and verify exactly which
test catches the regression.

Invariant → mutation → test map (kept in lockstep with redact.py docstring):

| #   | Invariant | Mutation that breaks it | Guard test |
|-----|-----------|------------------------|-----------|
| 2   | REGEX_ELIGIBLE_FIELDS gates regex | Remove the eligibility check in dispatcher | ``TestRegexEligibility.test_regex_does_not_apply_outside_eligible_fields`` |
| 3   | Excluded patterns stay excluded | Add ``phone_us`` to ACTIVE_PATTERNS | ``TestExcludedPatterns.test_phone_shaped_text_passes_through_untouched`` |
| 4   | Credential sentinel logs metadata only | Include matched value in exception | ``TestCredentialSentinel.test_sentinel_event_carries_no_matched_value`` |
| 5   | strip_string_literals=True inside preview | Flip ``Token.Literal.String`` strip off | ``TestLiteralStripping.test_string_literals_in_compiled_code_are_stripped`` |
| R1a | truncate_logs noop on None/empty (R3.5.5) | Drop the empty/None guards | ``TestTruncateLogsV2.test_mut_r1a_empty_and_none`` |
| R1b | truncate_logs noop on short input ≤1024 B (R3.5.5) | Remove the short-circuit | ``TestTruncateLogsV2.test_mut_r1b_short_unchanged`` |
| R2  | Earliest-position-wins across all 5 specific anchors (R3.5.5) | Use list-order-wins or last-position-wins | ``TestTruncateLogsV2.test_mut_r2_earliest_position_wins`` |
| R3  | Anchor in head (<HEAD_BOUNDARY) → first 64 KB (R3.5.5) | Skip Rule 3; fall through to Rule 4 | ``TestTruncateLogsV2.test_mut_r3_head_window`` |
| R3_b | Head-boundary clipping (documented limitation) | Auto-fix Rule 3 to preserve anchor across boundary | ``TestTruncateLogsV2.test_mut_r3_boundary_documented_limitation`` |
| R4  | Anchor in body/tail → ±16 KB centered window (R3.5.5) | Use head window for all anchor positions | ``TestTruncateLogsV2.test_mut_r4_centered_window`` |
| R5  | No specific anchor → tail 64 KB (R3.5.5) | Return empty or first 64 KB on no-anchor | ``TestTruncateLogsV2.test_mut_r5_tail_fallback`` |
| 9d  | Catalog gate: `logs` patterns require ``max_bytes`` | Add a pattern citing `logs` without ``max_bytes`` | ``test_triage_catalog.TestMutations.test_mut9d_*`` (3 sub-cases) |
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from scripts.automation.src.triage.redact import (
    ANCHOR_WINDOW_HALF,
    CREDENTIAL_PATTERNS,
    CredentialSentinelFired,
    ERROR_ANCHORS,
    EXCLUDED_PATTERNS,
    HEAD_BOUNDARY,
    HEAD_WINDOW,
    LITERAL_STRIP_METHOD,
    LOGS_MAX_BYTES,
    PREVIEW_FIELDS,
    PREVIEW_MAX_CHARS,
    REGEX_ELIGIBLE_FIELDS,
    RedactionResult,
    SentinelEvent,
    SHORT_LOG_THRESHOLD,
    TAIL_FALLBACK,
    _find_earliest_anchor,
    redact_artifact,
    redact_early_failure,
    truncate_logs,
)


# ===========================================================================
# Constants / module sanity
# ===========================================================================

class TestModuleConstants:
    """Smoke tests for the locked constants."""

    def test_regex_eligible_is_exactly_four_fields(self):
        # Adding a field requires PR amendment to gate-d-findings.md §5.3
        # OR gate-d-logs-field-amendment.md §3.2 (for the `logs` field).
        # If this test fails on a green commit, the contract changed —
        # update the relevant amendment doc first.
        # `logs` added Day 3.8 (Sprint-1 #12); see hybrid truncation in
        # truncate_logs() per gate-d-logs-field-amendment.md §3.2.
        assert REGEX_ELIGIBLE_FIELDS == frozenset({
            "message", "truncated_debug_logs", "status_message", "logs",
        })

    def test_excluded_patterns_locked(self):
        # Negative evidence — see redact.py module docstring + gate-d §5.4.
        assert EXCLUDED_PATTERNS == frozenset({
            "phone_us", "cc_like", "ssn", "ip_address",
        })

    def test_preview_fields_locked(self):
        assert PREVIEW_FIELDS == frozenset({"compiled_code", "raw_code"})

    def test_literal_strip_method_records_sqlparse_version(self):
        assert LITERAL_STRIP_METHOD.startswith("sqlparse_v")

    def test_sqlparse_version_matches_pinned_requirement(self):
        """Pin guard — see scripts/automation/requirements.txt.

        sqlparse tokenization on edge cases (dollar-quoting, dialect
        literals) varies across minor versions. The pinned version is
        embedded in every redacted payload via LITERAL_STRIP_METHOD;
        a silent drift would invalidate all downstream snapshots without
        any test failing. Bump deliberately: update requirements.txt,
        re-run tests, re-snapshot canonical fixtures, update this assert.
        """
        import sqlparse
        assert sqlparse.__version__ == "0.5.4", (
            f"sqlparse version drift: installed {sqlparse.__version__}, "
            f"pinned 0.5.4. Update requirements.txt + this assert in lockstep."
        )


# ===========================================================================
# Invariant 5: literal stripping inside preview
# ===========================================================================

class TestLiteralStripping:
    """Invariant 5 — sqlparse strips string literals + comments BEFORE truncation."""

    def test_string_literals_in_compiled_code_are_stripped(self):
        """MUTATION GUARD: if the dispatcher stops calling
        ``_literal_stripped_preview`` (or the preview helper stops
        replacing string literals), the raw email survives into the
        preview and this test fails."""
        sql = "SELECT * FROM t WHERE created_by = 'becky.anderson@fbin.com'"
        result = redact_artifact({
            "results": [{"unique_id": "model.x", "compiled_code": sql}]
        })
        preview = result.payload["results"][0]["compiled_code"]
        assert "becky.anderson@fbin.com" not in preview["literal_stripped_preview"]
        assert "<LIT>" in preview["literal_stripped_preview"]

    def test_sql_comments_in_compiled_code_are_stripped(self):
        """Comments may carry SME notes with emails — they MUST be replaced."""
        sql = "SELECT 1 -- AS per SME becky@fbin.com\nFROM t"
        result = redact_artifact({
            "results": [{"compiled_code": sql}]
        })
        preview = result.payload["results"][0]["compiled_code"]
        assert "becky@fbin.com" not in preview["literal_stripped_preview"]
        assert "<COMMENT>" in preview["literal_stripped_preview"]

    def test_preview_truncated_to_500_chars(self):
        sql = "SELECT " + ", ".join(f"col{i}" for i in range(200)) + " FROM t"
        result = redact_artifact({"results": [{"compiled_code": sql}]})
        preview = result.payload["results"][0]["compiled_code"]
        assert preview["preview_chars"] <= PREVIEW_MAX_CHARS
        assert preview["preview_truncated"] is True
        assert preview["literal_stripped_preview"].endswith("...")

    def test_preview_payload_contract_shape(self):
        """Contract test: §5.2 payload shape must be stable."""
        result = redact_artifact({"results": [{"compiled_code": "SELECT 1"}]})
        preview = result.payload["results"][0]["compiled_code"]
        assert set(preview.keys()) == {
            "literal_stripped_preview",
            "preview_chars",
            "preview_truncated",
            "literal_strip_method",
        }

    def test_empty_compiled_code_handled(self):
        result = redact_artifact({"results": [{"compiled_code": None}]})
        preview = result.payload["results"][0]["compiled_code"]
        assert preview["literal_stripped_preview"] == ""
        assert preview["preview_chars"] == 0
        assert preview["preview_truncated"] is False


# ===========================================================================
# Invariant 2: regex eligibility
# ===========================================================================

class TestRegexEligibility:
    """Invariant 2 — regex applies ONLY to REGEX_ELIGIBLE_FIELDS."""

    def test_regex_does_not_apply_outside_eligible_fields(self):
        """MUTATION GUARD: if the dispatcher's eligibility check is removed
        (e.g., applies regex to every string), then an email placed in a
        non-eligible field would also be redacted. Here we use a field
        that the allowlist drops — the email never appears in output
        either way, but the count of redaction_events tells the story.

        We use a field IN PASSTHROUGH (status) — strings here must NOT
        be regex-scanned. An email here passes through verbatim."""
        result = redact_artifact({
            "results": [{
                "unique_id": "model.x",
                "status": "error: contact ops@fbin.com",  # PASSTHROUGH field
            }]
        })
        # Status is passthrough — string survives untouched, NO redaction event.
        assert result.payload["results"][0]["status"] == "error: contact ops@fbin.com"
        assert result.redaction_events == 0

    def test_regex_applies_inside_message_field(self):
        result = redact_artifact({
            "results": [{"message": "failed: alice@example.com retry"}]
        })
        assert result.payload["results"][0]["message"] == (
            "failed: <EMAIL_REDACTED> retry"
        )
        assert result.redaction_events == 1

    def test_regex_applies_inside_truncated_debug_logs(self):
        payload = {
            "status_message": "Run failed",
            "run_steps": [{"truncated_debug_logs": "stderr: bob@x.com"}],
        }
        result = redact_early_failure(payload)
        assert "<EMAIL_REDACTED>" in result.payload["run_steps"][0]["truncated_debug_logs"]
        assert "bob@x.com" not in result.payload["run_steps"][0]["truncated_debug_logs"]

    def test_regex_applies_inside_status_message(self):
        result = redact_early_failure({
            "status_message": "Connection failed for user dba@fbin.com",
            "run_steps": [],
        })
        assert "<EMAIL_REDACTED>" in result.payload["status_message"]


# ===========================================================================
# Invariant 3: excluded patterns
# ===========================================================================

class TestExcludedPatterns:
    """Invariant 3 — phone_us / cc_like / ssn / ip_address never run."""

    def test_phone_shaped_text_passes_through_untouched(self):
        """MUTATION GUARD: if phone_us regex is added to ACTIVE_PATTERNS,
        the 10-digit business ID below would be redacted, breaking SQL
        IN-clause analysis."""
        result = redact_artifact({
            "results": [{
                "message": "row '0000001016' not found in source",
            }]
        })
        # Business ID survives — only email/credential patterns active.
        assert "0000001016" in result.payload["results"][0]["message"]
        assert result.redaction_events == 0

    def test_cc_shaped_float_passes_through_untouched(self):
        """execution_time floats like 18.03371024131775 must NOT match."""
        result = redact_artifact({
            "results": [{
                "message": "execution_time was 18.03371024131775 seconds",
            }]
        })
        assert "18.03371024131775" in result.payload["results"][0]["message"]

    def test_no_credential_pattern_named_phone_or_cc(self):
        active_names = {name for name, _ in CREDENTIAL_PATTERNS}
        assert active_names.isdisjoint(EXCLUDED_PATTERNS)


# ===========================================================================
# Invariant 4: credential sentinel — value-leak prevention
# ===========================================================================

class TestCredentialSentinel:
    """Invariant 4 — sentinel carries ONLY metadata (pattern name, field
    path, offset, length). NEVER the matched value."""

    SECRET_AWS = "AKIAIOSFODNN7EXAMPLE"  # AWS example key from official docs

    def test_sentinel_fires_on_aws_key_in_message(self):
        with pytest.raises(CredentialSentinelFired) as exc:
            redact_artifact({
                "results": [{"message": f"failure: key={self.SECRET_AWS}"}]
            })
        assert exc.value.event.pattern_name == "aws_access_key"

    def test_sentinel_event_carries_no_matched_value(self):
        """MUTATION GUARD: if SentinelEvent gains a ``matched_value`` field
        or the exception ``__str__`` interpolates the match, this test
        catches the value-leak regression."""
        try:
            redact_artifact({
                "results": [{"message": f"key={self.SECRET_AWS}"}]
            })
            pytest.fail("expected CredentialSentinelFired")
        except CredentialSentinelFired as exc:
            event = exc.event
            # Whitelist-style assertion: event fields are exactly the
            # metadata-only set. Adding any field requires updating
            # gate-d-findings.md §5.6 AND this test.
            from dataclasses import fields
            field_names = {f.name for f in fields(event)}
            assert field_names == {"pattern_name", "field_path", "offset", "length"}
            # The exception message must not contain the secret either.
            assert self.SECRET_AWS not in str(exc)
            # And no field's repr contains the secret.
            for fname in field_names:
                assert self.SECRET_AWS not in str(getattr(event, fname))

    def test_sentinel_records_correct_field_path(self):
        with pytest.raises(CredentialSentinelFired) as exc:
            redact_early_failure({
                "run_steps": [
                    {"truncated_debug_logs": f"x {self.SECRET_AWS}"}
                ]
            })
        assert "truncated_debug_logs" in exc.value.event.field_path

    def test_sentinel_records_offset_and_length(self):
        prefix = "log line: token="
        with pytest.raises(CredentialSentinelFired) as exc:
            redact_artifact({
                "results": [{"message": prefix + self.SECRET_AWS}]
            })
        assert exc.value.event.offset == len(prefix)
        assert exc.value.event.length == len(self.SECRET_AWS)

    def test_sentinel_fires_before_email_redaction(self):
        """Order matters: credential check runs before email pass so
        a credential+email field aborts immediately."""
        with pytest.raises(CredentialSentinelFired):
            redact_artifact({
                "results": [{
                    "message": f"alice@x.com {self.SECRET_AWS}",
                }]
            })


# ===========================================================================
# Allowlist closed-by-default
# ===========================================================================

class TestAllowlist:

    def test_unknown_field_at_top_level_dropped(self):
        result = redact_artifact({
            "results": [{
                "unique_id": "model.x",
                "secret_metadata": "should not appear",
            }]
        })
        assert "secret_metadata" not in result.payload["results"][0]
        assert result.payload["results"][0]["unique_id"] == "model.x"

    def test_passthrough_fields_preserved(self):
        result = redact_artifact({
            "results": [{
                "unique_id": "model.x",
                "relation_name": "DB.SCHEMA.TBL",
                "execution_time": 1.234,
            }]
        })
        row = result.payload["results"][0]
        assert row["unique_id"] == "model.x"
        assert row["relation_name"] == "DB.SCHEMA.TBL"
        assert row["execution_time"] == 1.234

    def test_nested_adapter_response_query_id_preserved(self):
        result = redact_artifact({
            "results": [{
                "adapter_response": {
                    "query_id": "01ab-cd-ef",
                    "internal_metric": "drop me",  # not in allowlist
                }
            }]
        })
        ar = result.payload["results"][0].get("adapter_response", {})
        assert ar.get("query_id") == "01ab-cd-ef"
        assert "internal_metric" not in ar


# ===========================================================================
# Input validation
# ===========================================================================

class TestInputValidation:

    def test_artifact_rejects_non_dict(self):
        with pytest.raises(TypeError):
            redact_artifact("not a dict")  # type: ignore[arg-type]

    def test_early_failure_rejects_non_dict(self):
        with pytest.raises(TypeError):
            redact_early_failure(None)  # type: ignore[arg-type]

    def test_empty_artifact_returns_empty_payload(self):
        result = redact_artifact({})
        assert result.payload == {}
        assert result.redaction_events == 0


# ===========================================================================
# Snapshot: canonical email-in-SQL input → redacted output
# ===========================================================================

class TestSnapshot:
    """Lock the redaction behaviour on the canonical Gate-D-style fixture.

    Real fixtures live in /tmp/triage-gate-d/ and are NOT committed
    (gate-d §7 item 6). This synthetic input reproduces the highest-risk
    pattern observed: email-in-SQL-comment + email-in-WHERE-clause +
    phone-shaped business ID + cc-shaped execution_time.
    """

    def test_canonical_payload_snapshot(self):
        canonical = {
            "results": [{
                "unique_id": "model.fbin_dv.sat_order_line",
                "status": "error",
                "execution_time": 18.03371024131775,  # cc-shaped FP source
                "relation_name": "FBIN_DV.SAT.SAT_ORDER_LINE",
                "message": (
                    "Compilation Error: column not found; contact "
                    "becky.anderson@fbin.com for context"
                ),
                "compiled_code": (
                    "-- AS per the Larson SME: 'becky.anderson@fbin.com'\n"
                    "SELECT * FROM t WHERE created_by IN ('0000001016',"
                    " 'lynzee.eddins@fiberondecking.com')"
                ),
                "adapter_response": {"query_id": "01b1-aaaa"},
            }]
        }
        result = redact_artifact(canonical)
        row = result.payload["results"][0]

        # Message: email redacted
        assert "becky.anderson@fbin.com" not in row["message"]
        assert "<EMAIL_REDACTED>" in row["message"]

        # compiled_code: both emails AND the phone-shaped ID swallowed
        # by literal stripping; comment swallowed by comment sentinel.
        preview = row["compiled_code"]["literal_stripped_preview"]
        assert "becky.anderson@fbin.com" not in preview
        assert "lynzee.eddins@fiberondecking.com" not in preview
        assert "0000001016" not in preview
        assert "<LIT>" in preview
        assert "<COMMENT>" in preview

        # cc-shaped float in execution_time: passthrough, NOT redacted
        assert row["execution_time"] == 18.03371024131775

        # adapter_response.query_id preserved
        assert row["adapter_response"]["query_id"] == "01b1-aaaa"

        # Redaction event count: exactly 1 (the email in message).
        # If this number changes, gate-d-findings.md needs an update —
        # ANY drift here indicates either policy creep or regression.
        assert result.redaction_events == 1


# ===========================================================================
# RedactionResult contract
# ===========================================================================

class TestRedactionResultContract:

    def test_redaction_result_is_frozen(self):
        r = RedactionResult(payload={})
        with pytest.raises(Exception):
            r.payload = {"new": 1}  # type: ignore[misc]


# ============================================================================
# Round 3.5.5 — truncate_logs v2 (5-rule algorithm)
# ============================================================================
# Spec & evidence:
#   docs/triage-agent/round-3.5.5-spike-results.md   (spike outcome 15/15)
#   docs/triage-agent/lessons-learned.md             (2026-06-05 entry 4)
#   scripts/automation/triage/spike_truncate_v2.py   (harness)
#   scripts/automation/triage/spike_synthetic_fixtures.py (synth contracts)
#
# These tests are the mutation harness for the v2 algorithm. Mut9d lives
# in the catalog test module because it is a load-time validation gate,
# not a redaction-path gate.
#
# Mut_R1a … R5 each engineered to fail loudly if a single source line in
# redact.py is mutated. They verify the CONTRACT, not parameter adequacy.
# Empirical adequacy is captured by the spike (15/15 PASS).
#
# Mut_R3_boundary is a DOCUMENTED-LIMITATION test: the algorithm clips
# anchors that span the head boundary. The test asserts the limitation
# exists; an auto-fix that preserves anchors across the cut would make
# the test FAIL by design, surfacing the change for explicit review.
# ============================================================================


class TestTruncateLogsV2:
    """Mut_R1a … R5 — truncate_logs v2 (Round 3.5.5) runtime contract."""

    # ------------------------------------------------------------------
    # Type contract (lock all entry-point paths before behavioral tests)
    # ------------------------------------------------------------------

    def test_truncate_logs_handles_none(self):
        out, strategy = truncate_logs(None)
        assert out == ""
        assert strategy == "noop:none"

    def test_truncate_logs_handles_empty_string(self):
        out, strategy = truncate_logs("")
        assert out == ""
        assert strategy == "noop:empty"

    def test_truncate_logs_rejects_non_string(self):
        with pytest.raises(TypeError, match="truncate_logs expects str or None"):
            truncate_logs(12345)  # type: ignore[arg-type]
        with pytest.raises(TypeError):
            truncate_logs(b"bytes are not str")  # type: ignore[arg-type]

    # ------------------------------------------------------------------
    # Mut_R1a/R1b — Rule 1: noop guards
    # ------------------------------------------------------------------

    def test_mut_r1a_empty_and_none(self):
        """Rule 1: None → noop:none; empty → noop:empty.

        Mutation that this catches:
          - Dropping the None guard (would raise TypeError on .find)
          - Dropping the empty guard (would fall through to tail and
            return "" with wrong strategy tag)
        """
        out, strategy = truncate_logs(None)
        assert out == ""
        assert strategy == "noop:none"

        out, strategy = truncate_logs("")
        assert out == ""
        assert strategy == "noop:empty"

    def test_mut_r1b_short_unchanged(self):
        """Rule 1: input ≤ SHORT_LOG_THRESHOLD (1024 B) returned unchanged.

        Even if a short input contains an anchor, the short-circuit
        wins (anchor branches only fire on long logs where truncation
        is needed; short logs ship verbatim).

        Mutation that this catches:
          - Removing the short-circuit (would route short anchored
            inputs through Rule 3 head window)
          - Using a different threshold (e.g., 512)
        """
        # Anchor-bearing short input — still returned as-is
        short_with_anchor = "Compilation Error: model foo failed"
        assert len(short_with_anchor) <= SHORT_LOG_THRESHOLD
        out, strategy = truncate_logs(short_with_anchor)
        assert out == short_with_anchor
        assert strategy == "noop:short"

        # Exactly-at-threshold edge
        at_threshold = "x" * SHORT_LOG_THRESHOLD
        out, strategy = truncate_logs(at_threshold)
        assert out == at_threshold
        assert strategy == "noop:short"

        # One byte over threshold → no longer noop:short
        over_threshold = "x" * (SHORT_LOG_THRESHOLD + 1)
        out, strategy = truncate_logs(over_threshold)
        assert strategy != "noop:short"

    # ------------------------------------------------------------------
    # Mut_R2 — Rule 2: earliest-position-wins across all 5 anchors
    # ------------------------------------------------------------------

    def test_mut_r2_earliest_position_wins(self):
        """Rule 2: scan returns the EARLIEST byte position across all 5
        specific anchors. Position is the only tiebreaker.

        Construct text where "Runtime Error" appears EARLIER than
        "Database Error". Earliest-wins → Runtime selected.

        Mutation that this catches:
          - last-position-wins (Day-3.8 algorithm regression)
          - list-order-wins (would always pick whichever anchor is
            first in ERROR_ANCHORS regardless of position)
        """
        # Place "Runtime Error" early, "Database Error" later. Both in
        # body region (>HEAD_BOUNDARY) so Rule 4 fires.
        head_filler = "x" * (HEAD_BOUNDARY + 1000)  # push past head
        text = (
            head_filler
            + "Runtime Error: at byte ~66K\n"
            + ("y" * 50_000)
            + "Database Error: at byte ~120K\n"
            + ("z" * 1000)
        )
        out, strategy = truncate_logs(text)
        assert strategy == "window:Runtime Error"
        assert "Runtime Error: at byte ~66K" in out
        # Later anchor's window does NOT fire
        assert "Database Error: at byte ~120K" not in out

    def test_mut_r2_all_five_anchors_recognized(self):
        """All 5 specific anchors trigger Rule 2 when alone in input.

        Mutation that this catches:
          - Accidental removal of any single anchor from ERROR_ANCHORS
          - Re-introduction of generic anchors (the failed v1 mode)
        """
        head_filler = "x" * (HEAD_BOUNDARY + 1000)
        for anchor in ERROR_ANCHORS:
            text = head_filler + anchor + " details here\n"
            out, strategy = truncate_logs(text)
            assert strategy == f"window:{anchor}", f"failed for {anchor!r}"
            assert anchor in out

    def test_mut_r2_no_generic_anchors(self):
        """Generic anchors (`failed`, `^ERROR`) MUST NOT appear in
        ERROR_ANCHORS. Their inclusion was the Day-3.8 Cluster A
        failure mechanism (lessons-learned 2026-06-05 entry 4).

        Mutation that this catches:
          - Re-adding generic anchors during a future "expansion"
        """
        assert len(ERROR_ANCHORS) == 5
        for anchor in ERROR_ANCHORS:
            assert "failed" not in anchor.lower()
            # No bare "ERROR" — only "Runtime Error", "Database Error",
            # "Compilation Error" (compound forms)
            assert anchor != "ERROR"

    def test_find_earliest_anchor_returns_none_on_no_match(self):
        """_find_earliest_anchor returns None when no anchor matches.

        Mutation that this catches:
          - Returning a default tuple like (0, '') instead of None
        """
        assert _find_earliest_anchor("ordinary log line with no errors") is None
        assert _find_earliest_anchor("") is None

    # ------------------------------------------------------------------
    # Mut_R3 — Rule 3: anchor in head → first 64 KB window
    # ------------------------------------------------------------------

    def test_mut_r3_head_window(self):
        """Rule 3: anchor at position < HEAD_BOUNDARY returns first
        HEAD_WINDOW bytes.

        Mutation that this catches:
          - Falling through to Rule 4 (centered window) for head anchors
          - Returning a smaller/larger head window
        """
        # Anchor at byte ~200 (well inside head region)
        prefix = "x" * 200
        anchor = "Compilation Error"
        # Add post-anchor content extending past HEAD_BOUNDARY so the
        # head-window slice is the discriminator
        suffix = "y" * (HEAD_BOUNDARY * 2)
        text = prefix + anchor + suffix

        out, strategy = truncate_logs(text)
        assert strategy == "head:Compilation Error"
        assert len(out) == HEAD_WINDOW
        assert out == text[:HEAD_WINDOW]
        assert anchor in out

    def test_mut_r3_anchor_at_zero(self):
        """Edge: anchor at byte 0 — still Rule 3 (head window)."""
        anchor = "Encountered an error:"
        text = anchor + (" detail\n" * 20_000)
        assert len(text) > HEAD_WINDOW
        out, strategy = truncate_logs(text)
        assert strategy == "head:Encountered an error:"
        assert out.startswith(anchor)
        assert len(out) == HEAD_WINDOW

    def test_mut_r3_boundary_documented_limitation(self):
        """DOCUMENTED LIMITATION: anchors whose first byte falls in
        [HEAD_BOUNDARY − len(anchor) + 1, HEAD_BOUNDARY − 1] get
        clipped by the head-window cut.

        synth_01a' fixture documents this case. The test asserts that
        the clipping happens (current behavior) — an auto-fix that
        preserves the anchor across the boundary would FAIL this test,
        surfacing the change for explicit review (mutation surveillance,
        not aspirational test).

        Round-4 trigger: if Day-6+ backtest reveals >5% of real
        failures exhibit this clipping pattern, schedule algorithm
        revision. Until then, behavior is INTENTIONAL.
        """
        anchor = "Database Error"  # 14 chars
        assert len(anchor) == 14
        # Construct so anchor START is at HEAD_BOUNDARY − 7 (anchor
        # ends at HEAD_BOUNDARY + 6, straddling the cut by 7 bytes)
        prefix = "x" * (HEAD_BOUNDARY - 7)
        suffix = "y" * 1000
        text = prefix + anchor + suffix
        assert len(text) > HEAD_WINDOW

        out, strategy = truncate_logs(text)
        # Rule 3 fires (anchor START < HEAD_BOUNDARY)
        assert strategy == "head:Database Error"
        # …but the head-window cut clips the anchor — only prefix +
        # partial anchor survive
        assert out == text[:HEAD_WINDOW]
        # The full anchor literal is NOT preserved (documented limitation)
        assert anchor not in out, (
            "Anchor unexpectedly preserved across head boundary — "
            "this would be an UPGRADE; update test and announce."
        )

    # ------------------------------------------------------------------
    # Mut_R4 — Rule 4: anchor in body/tail → ±16 KB centered window
    # ------------------------------------------------------------------

    def test_mut_r4_centered_window(self):
        """Rule 4: anchor at position ≥ HEAD_BOUNDARY returns the
        ±ANCHOR_WINDOW_HALF byte window centered on the anchor start.

        Mutation that this catches:
          - Using head window for body/tail anchors
          - Skipping the slice bounds (returning full text)
          - Off-by-one on start/end slicing
        """
        # Anchor at byte 200_000 (well past head, well past midpoint)
        prefix = "x" * 200_000
        anchor = "Runtime Error: late failure"
        suffix = "y" * 200_000
        text = prefix + anchor + suffix

        out, strategy = truncate_logs(text)
        assert strategy == "window:Runtime Error"
        # Centered ±ANCHOR_WINDOW_HALF
        assert len(out) == 2 * ANCHOR_WINDOW_HALF
        # Anchor preserved
        assert anchor in out
        # Centered: anchor should appear roughly in the middle
        anchor_idx = out.find(anchor)
        assert ANCHOR_WINDOW_HALF - 100 <= anchor_idx <= ANCHOR_WINDOW_HALF

    def test_mut_r4_cluster_a_regression(self):
        """Cluster A regression test: Day-3.8 algorithm chose
        ``generic_failed`` @ byte 2.69 M over ``Encountered an error:``
        @ byte 315 because generic anchors were in ERROR_ANCHORS and
        last-position-wins. v2 fixes both: generics removed +
        earliest-position-wins.

        This test asserts the v2 algorithm picks the early specific
        anchor on a Cluster-A-shaped payload.
        """
        anchor = "Encountered an error:"
        prefix = "init\n" + anchor + ": real error here\n"
        # Then ~2.7 MB of manifest-dump noise (the v1 trap was that
        # this dump contained "failed" hundreds of times)
        noise = ("step failed: this is part of a manifest dump\n" * 50_000)
        suffix = "tail content\n"
        text = prefix + noise + suffix
        assert len(text) > 2_000_000  # sanity: multi-MB input

        out, strategy = truncate_logs(text)
        # v2: earliest specific anchor wins (Rule 3 head window)
        assert strategy == "head:Encountered an error:"
        assert anchor in out
        assert len(out) == HEAD_WINDOW

    # ------------------------------------------------------------------
    # Mut_R5 — Rule 5: no specific anchor → tail 64 KB
    # ------------------------------------------------------------------

    def test_mut_r5_tail_fallback(self):
        """Rule 5: when no anchor in ERROR_ANCHORS matches, output is
        the last TAIL_FALLBACK bytes.

        Mutation that this catches:
          - Returning "" on no-anchor (Day-3.8 boundary regression)
          - Returning head bytes instead of tail
          - Off-by-one on the negative slice
        """
        # 200 KB of anchor-free content
        text = "abcdefghij" * 20_000
        out, strategy = truncate_logs(text)
        assert strategy == "tail:no_anchor"
        assert out == text[-TAIL_FALLBACK:]
        assert len(out) == TAIL_FALLBACK

    def test_mut_r5_short_no_anchor_handled_by_rule_1(self):
        """Inputs ≤ SHORT_LOG_THRESHOLD never reach Rule 5 (Rule 1
        short-circuits first).

        Mutation that this catches:
          - Reordering rules (Rule 5 before Rule 1)
        """
        text = "short anchor-free message"
        out, strategy = truncate_logs(text)
        assert strategy == "noop:short"
        assert out == text

    # ------------------------------------------------------------------
    # Hard size cap (Mut9b carry-over from Day 3.8)
    # ------------------------------------------------------------------

    def test_logs_max_bytes_cap_enforced_all_branches(self):
        """LOGS_MAX_BYTES is a hard cap across ALL branches.

        Mutation that this catches:
          - Drift between HEAD_WINDOW / TAIL_FALLBACK / ANCHOR_WINDOW_HALF
            and the LOGS_MAX_BYTES cap
        """
        assert LOGS_MAX_BYTES == 65_536
        assert LOGS_MAX_BYTES == max(
            HEAD_WINDOW,
            TAIL_FALLBACK,
            ANCHOR_WINDOW_HALF * 2,
        )

        # Rule 3 (head): exactly HEAD_WINDOW bytes
        head_text = "Compilation Error\n" + ("x" * HEAD_WINDOW * 2)
        out, _ = truncate_logs(head_text)
        assert len(out) <= LOGS_MAX_BYTES

        # Rule 4 (window): exactly 2 * ANCHOR_WINDOW_HALF bytes
        body_text = ("x" * 200_000) + "Runtime Error\n" + ("y" * 200_000)
        out, _ = truncate_logs(body_text)
        assert len(out) <= LOGS_MAX_BYTES

        # Rule 5 (tail): exactly TAIL_FALLBACK bytes
        tail_text = "x" * 200_000
        out, _ = truncate_logs(tail_text)
        assert len(out) <= LOGS_MAX_BYTES

    # ------------------------------------------------------------------
    # Constants lock (public contract — bump requires explicit PR)
    # ------------------------------------------------------------------

    def test_error_anchors_count_and_membership_locked(self):
        """ERROR_ANCHORS is the public contract — 5 specific anchors.

        Adding/removing requires:
          (1) Bump this assertion + Mut_R2 anchor-list test
          (2) Update redact.py module-docstring + spike harness
          (3) Re-run extended battery (15/15 PASS gate)

        Mutation that this catches:
          - Silent anchor addition/removal/reorder
        """
        assert len(ERROR_ANCHORS) == 5
        assert ERROR_ANCHORS == (
            "Encountered an error:",
            "Traceback (most recent call last):",
            "Database Error",
            "Compilation Error",
            "Runtime Error",
        )

    def test_constants_locked(self):
        """Public algorithm constants are part of the contract."""
        assert SHORT_LOG_THRESHOLD == 1024
        assert HEAD_WINDOW == 65_536
        assert ANCHOR_WINDOW_HALF == 16_384
        assert TAIL_FALLBACK == 65_536
        assert HEAD_BOUNDARY == 65_536


# ============================================================================
# Round 3.5.5 — Real-payload snapshot regression
# ============================================================================
# Pins (strategy, output_byte_count) for the 7 Day-4 P0.1 payloads.
# Source: spike_truncate_v2.py output on 2026-06-05 (commit 8879285e).
#
# Pin SHAPE (not content) — payload bytes contain customer object names
# and are NOT committed. Test SKIPS when scratch payloads are absent
# (CI without the local scratch directory still passes).
#
# Regenerate after intentional algorithm change:
#   .venv/bin/python3 scripts/automation/triage/spike_truncate_v2.py \
#     --json > /tmp/spike_pins.json
# then transcribe to PAYLOAD_PINS below.
# ============================================================================

PAYLOAD_PINS = {
    # run_id: (expected_strategy, expected_output_bytes)
    # Pins captured from spike_truncate_v2.py 2026-06-05 run, all PASS
    # (anchor preserved + actionable error in window).
    "484675412_cluster_C": ("head:Database Error", 2795),
    "485821754_cluster_A": ("head:Encountered an error:", 65_536),
    "485850628_cluster_A": ("head:Encountered an error:", 65_536),
    "485851058_cluster_A": ("head:Encountered an error:", 65_536),
    "486060143_cluster_C": ("window:Database Error", 18_067),
    "487313189_cluster_B": ("head:Database Error", 10_570),
    "487333396_cluster_B": ("head:Database Error", 10_576),
}


class TestTruncateLogsSnapshots:
    """Snapshot pins for 7 real Day-4 P0.1 payloads.

    Skips when ``~/scratch/triage-day4/`` is absent (developer machines
    without the scratch corpus, CI runners). When the corpus IS
    present, every payload must match its pinned (strategy, output_size).
    """

    @pytest.fixture
    def scratch_dir(self) -> Path:
        import os
        return Path(os.path.expanduser("~/scratch/triage-day4"))

    def test_scratch_payloads_match_snapshot(self, scratch_dir):
        if not scratch_dir.exists():
            pytest.skip(f"Scratch corpus absent: {scratch_dir}")

        payload_files = sorted(scratch_dir.glob("run_*.json"))
        if not payload_files:
            pytest.skip(f"No run_*.json payloads in {scratch_dir}")

        # If PAYLOAD_PINS is empty (initial commit), regenerate hint
        if not PAYLOAD_PINS:
            pytest.skip(
                "PAYLOAD_PINS empty — populate by running "
                "spike_truncate_v2.py and transcribing strategy + "
                "output_bytes per run_id."
            )

        mismatches = []
        for payload_path in payload_files:
            run_id = payload_path.stem.replace("run_", "")
            if run_id not in PAYLOAD_PINS:
                continue
            data = json.loads(payload_path.read_text())
            steps = data.get("steps") or data.get("run_steps") or []
            if not steps:
                continue
            logs = steps[-1].get("logs") or ""
            out, strategy = truncate_logs(logs)
            expected_strategy, expected_bytes = PAYLOAD_PINS[run_id]
            if strategy != expected_strategy or len(out) != expected_bytes:
                mismatches.append(
                    f"{run_id}: got ({strategy!r}, {len(out)}) "
                    f"expected ({expected_strategy!r}, {expected_bytes})"
                )

        assert not mismatches, "Snapshot drift:\n  " + "\n  ".join(mismatches)


class TestHybridTruncationViaDispatcher:
    """Verify the dispatcher hook fires hybrid truncation for `logs`
    BEFORE the regex sentinel pass."""

    def test_logs_field_is_truncated_in_redact_artifact(self):
        """A logs field with a late anchor in a multi-MB stream is
        truncated to the anchor window when redact_artifact processes
        a nested run_steps[].logs payload.
        """
        anchor = "Runtime Error: late-stage failure"
        big_logs = ("filler line\n" * 100_000) + anchor + ("\ntail filler\n" * 100)
        payload = {
            "status_message": "Run failed",
            "run_steps": [{"logs": big_logs}],
        }

        result = redact_artifact(payload)
        truncated = result.payload["run_steps"][0]["logs"]

        # The truncation cap applies
        assert len(truncated) <= LOGS_MAX_BYTES
        # The anchor survives the truncation
        assert anchor in truncated


# ===========================================================================
# R1 raw-payload audit (audit_raw_for_credentials) — proving tests
# ===========================================================================
# These tests are the proving-test set for invariant 6 (audit-before-
# transform) and for R1 of docs/triage-agent/credential-threat-model.md.
# They replace test_credential_outside_anchor_window_is_not_exposed
# (deleted in PR 2 — 2026-06-16 audit Finding #9), which asserted the
# OPPOSITE: that truncate_logs running before the sentinel was correct
# behaviour. That test was inert for TWO independent reasons:
#   1. Truncate-before-scan dropped the planted credential from the
#      sentinel's view (the bug PR 2 fixes).
#   2. The planted canary was a 'ghp_' GitHub-PAT shape, and
#      CREDENTIAL_PATTERNS has NO ghp_ entry — so even if the order had
#      been right, the sentinel would never have fired on that input.
# An unmatchable canary makes a proving test a no-op. Every test below
# uses a canary verified to match a live CREDENTIAL_PATTERNS entry.


class TestRawAudit:
    """Proving-test set for ``audit_raw_for_credentials`` (R1)."""

    # ---- AWS canary: matches CREDENTIAL_PATTERNS 'aws_access_key'
    # \b(?:AKIA|ASIA)[0-9A-Z]{16}\b. AKIAIOSFODNN7EXAMPLE is AWS's
    # published example key (AKIA + 16 alphanumerics). Shared with
    # TestCredentialSentinel for consistency.
    SECRET_AWS = "AKIAIOSFODNN7EXAMPLE"

    # ---- JWT canary: matches CREDENTIAL_PATTERNS 'jwt'
    # \beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b
    # Same shape as the canary used by test_no_credential_substring_in_any_field
    # in test_triage_orchestrator.py — keeps both proving-test sets
    # consistent.
    SECRET_JWT = (
        "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTYifQ"
        ".SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
    )

    # ---- PEM private-key marker: matches CREDENTIAL_PATTERNS 'private_key'
    # -----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED |)PRIVATE KEY-----
    PEM_MARKER = "-----BEGIN RSA PRIVATE KEY-----"

    def test_credential_anywhere_in_logs_fires_sentinel(self):
        """INVERT: replaces test_credential_outside_anchor_window_is_not_exposed
        (deleted in PR 2 — 2026-06-16 audit Finding #9).

        Proves R1: ``audit_raw_for_credentials`` scans the RAW payload
        structure BEFORE ``truncate_logs`` runs. The credential is
        planted FAR from any anchor — outside the bytes that
        ``truncate_logs`` would retain. Without the raw audit, the
        credential would be silently dropped by truncation and the
        sentinel would never see it (the bug PR 2 fixes). With the raw
        audit, the credential is scanned in the raw structure BEFORE
        truncation runs, so the sentinel fires.

        IMPORTANT: this canary MUST match a live entry in
        ``CREDENTIAL_PATTERNS``. The deleted test used a ``ghp_``
        GitHub-PAT canary that no pattern matched — the test passed
        for TWO independent wrong reasons (truncate-before-scan AND
        unmatchable canary). An unmatchable canary makes this proving
        test a no-op. ``SECRET_JWT`` matches the live ``jwt`` pattern;
        see class docstring.
        """
        # Place canary FAR before the anchor — outside truncate_logs's
        # retention window. If truncation ran before the scan, the
        # credential would be discarded and the sentinel would never
        # see it.
        prefix_noise = "benign log line\n" * 100_000  # ~1.6 MB
        anchor = "Runtime Error: late-stage error"
        text_with_cred = (
            prefix_noise[:500_000]
            + self.SECRET_JWT
            + prefix_noise[500_000:]
            + anchor
        )
        payload = {"run_steps": [{"logs": text_with_cred}]}

        with pytest.raises(CredentialSentinelFired) as exc:
            redact_artifact(payload)
        assert exc.value.event.pattern_name == "jwt"
        assert "logs" in exc.value.event.field_path

    def test_credential_in_passthrough_field_fires(self):
        """R1: field-routing is NOT a mitigation. ``status_message`` is
        in ``PASSTHROUGH_FIELDS`` — without the audit, its content
        would pass through unchanged (no scan, no redaction). The audit
        scans it anyway because R1 requires every str leaf be scanned
        in the raw structure, regardless of how the allowlist treats it.
        """
        payload = {
            "data": {
                "status_message": f"Run failed: token={self.SECRET_AWS}"
            }
        }
        with pytest.raises(CredentialSentinelFired) as exc:
            redact_early_failure(payload)
        assert exc.value.event.pattern_name == "aws_access_key"
        assert "status_message" in exc.value.event.field_path

    def test_credential_in_unknown_field_fires(self):
        """R1 teeth: the audit visits EVERY str leaf, including fields
        the allowlist would later drop. This is the only test that
        catches mutation M7 (audit moved to AFTER ``_redact_node``):
        with M7, the unknown field is dropped by the allowlist before
        the audit could see it, so the sentinel never fires. With the
        audit running step 0 (current correct order), the field is
        scanned in the raw structure and the credential is detected.
        """
        payload = {
            "data": {
                "run_steps": [
                    {"some_future_field_dbt_might_add": f"x {self.SECRET_AWS}"}
                ]
            }
        }
        with pytest.raises(CredentialSentinelFired) as exc:
            redact_early_failure(payload)
        assert exc.value.event.pattern_name == "aws_access_key"
        assert "some_future_field_dbt_might_add" in exc.value.event.field_path

    def test_credential_in_compiled_code_fires_before_preview_projection(self):
        """R1: preview projection is a lossy transform. The audit must
        run BEFORE ``_literal_stripped_preview`` rewrites
        ``compiled_code`` into a preview shape. The assertion is the
        RAISE — the test passes iff the sentinel fires, which proves
        the audit ran before the preview projection swallowed the
        credential into a transformed shape.

        Closes Finding A from the 2026-06-16 audit (the preview path
        was treated as credential-safe-by-construction without a
        proving test — see
        docs/triage-agent/credential-threat-model.md §Why This
        Document Exists).
        """
        payload = {
            "results": [
                {
                    "compiled_code": (
                        f"SELECT 1; {self.PEM_MARKER}\n"
                        f"MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDz"
                    )
                }
            ]
        }
        with pytest.raises(CredentialSentinelFired) as exc:
            redact_artifact(payload)
        assert exc.value.event.pattern_name == "private_key"
        assert "compiled_code" in exc.value.event.field_path

    def test_audit_returns_normally_when_no_credentials(self):
        """Negative control: a credential-free payload passes through
        the audit and is redacted normally. Without this test, a future
        mutation that always raised ``CredentialSentinelFired``
        regardless of input would not be caught by the four positive
        tests above.
        """
        payload = {
            "data": {
                "run_steps": [
                    {"message": "benign error: column 'foo' not found"}
                ]
            }
        }
        # No exception raised
        result = redact_early_failure(payload)
        # Payload survives through to a non-empty redacted shape
        assert result.payload != {}
