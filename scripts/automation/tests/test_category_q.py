#!/usr/bin/env python3
"""
test_category_q.py — Tests for Category Q (Conceptual Modeling, advisory WARN).

Covers: Q1 (link_hk_component_collision — TRAP-01),
        Q2 (satellite_pii_not_split — privacy split trigger)

Category Q surfaces DESIGN-level modeling risks documented in
.github/knowledge/data-vault/. All findings are WARN (advisory) — the reviewer
never blocks a design decision, it cites the trap and lets the engineer decide.

Each check has: pass, fail (warn), and edge cases.

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_category_q.py -v
"""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_reviewer import (  # noqa: E402
    Severity,
    check_link_hk_component_collision,
    check_satellite_pii_not_split,
)

STG_PATH = "models/int_staging_views/invoice/v_psa_stg_supplier_invoice_line__emtk_ebs.sql"
SAT_PATH = "models/raw_vault/sat/sat_customer__crm.sql"


def _hk(name: str, *cols: str) -> str:
    """Build an FBIN-shaped HK block over raw columns for the given HK name."""
    comps = "\n  , ".join(
        f"COALESCE(NULLIF(TRIM(CAST({c} AS VARCHAR)), ''), '^^')" for c in cols
    )
    return f"MD5_BINARY(UPPER(CONCAT_WS('||',\n    {comps}\n))) AS {name}"


# ===========================================================================
# Q1: check_link_hk_component_collision (TRAP-01)
# ===========================================================================

class TestQ1LinkHkComponentCollision:
    """Q1: two distinct HKs in one staging model must not share a component list."""

    def test_fail_identical_component_lists_collide(self):
        """Line hub HK and link HK built from the same raw columns → byte collision."""
        sql = (
            "SELECT\n    "
            + _hk("INVOICE_LINE_HK", "INVOICE_ID", "LINE_NUMBER", "BKCC")
            + "\n  , "
            + _hk("LNK_INVOICE_LINE_HK", "INVOICE_ID", "LINE_NUMBER", "BKCC")
        )
        findings = check_link_hk_component_collision(sql, STG_PATH)
        assert len(findings) == 1
        f = findings[0]
        assert f.check_id == "Q1"
        assert f.severity == Severity.WARN
        assert "INVOICE_LINE_HK" in f.message and "LNK_INVOICE_LINE_HK" in f.message

    def test_pass_guarded_duplicate_leading_component(self):
        """Link HK duplicates the leading component → distinct list → no collision."""
        sql = (
            "SELECT\n    "
            + _hk("INVOICE_LINE_HK", "INVOICE_ID", "LINE_NUMBER", "BKCC")
            + "\n  , "
            + _hk("LNK_INVOICE_LINE_HK", "INVOICE_ID", "INVOICE_ID", "LINE_NUMBER", "BKCC")
        )
        assert check_link_hk_component_collision(sql, STG_PATH) == []

    def test_pass_link_hk_from_component_hks(self):
        """Link HK composed from participating *_HK columns has no raw components → safe."""
        sql = (
            "SELECT\n    "
            + _hk("INVOICE_LINE_HK", "INVOICE_ID", "LINE_NUMBER", "BKCC")
            + "\n  , MD5_BINARY(UPPER(CONCAT_WS('||', INVOICE_HK, INVOICE_LINE_HK))) AS LNK_INVOICE_LINE_HK"
        )
        assert check_link_hk_component_collision(sql, STG_PATH) == []

    def test_edge_single_hk_no_pair(self):
        """One HK alone cannot collide."""
        sql = "SELECT\n    " + _hk("SUPPLIER_HK", "LIFNR", "BKCC")
        assert check_link_hk_component_collision(sql, STG_PATH) == []

    def test_edge_non_staging_file_ignored(self):
        """Q1 only runs on int_staging_views/ models."""
        sql = (
            "SELECT\n    "
            + _hk("INVOICE_LINE_HK", "INVOICE_ID", "LINE_NUMBER", "BKCC")
            + "\n  , "
            + _hk("LNK_INVOICE_LINE_HK", "INVOICE_ID", "LINE_NUMBER", "BKCC")
        )
        assert check_link_hk_component_collision(sql, "models/raw_vault/link/lnk_invoice_line.sql") == []

    def test_edge_repeated_hk_name_multisource_not_flagged(self):
        """The same HK name defined in two source CTEs is not a collision."""
        block = _hk("SUPPLIER_HK", "LIFNR", "BKCC")
        sql = f"SRC_A as ( SELECT {block} ),\nSRC_B as ( SELECT {block} )"
        assert check_link_hk_component_collision(sql, STG_PATH) == []

    def test_pass_incomplete_extraction_dash1_fallback_not_flagged(self):
        """Distinct '-1'-sentinel keys (PLANT vs MATNR) must NOT be flagged.

        Post-fix, the widened component regex fully extracts '-1' components, so
        these resolve to [PLANT, BKCC] vs [MATNR, BKCC] — genuinely distinct, no
        collision. (Before the fix they were skipped by the completeness guard
        because '-1' collapsed to [BKCC]; either way, correctly not flagged.)
        Companion to test_fail_identical_dash1_sentinel_keys_collide — together
        they prove Q1 tells identical from distinct on the standard sentinel.
        """
        def hk_dash1(name: str, key: str) -> str:
            return (
                "MD5_BINARY(UPPER(CONCAT_WS('||',\n"
                f"    COALESCE(NULLIF(TRIM(CAST({key} as VARCHAR)),''), '-1')\n"
                "  , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')\n"
                f"))) as {name}"
            )
        sql = "SELECT\n    " + hk_dash1("PLANT_HK", "PLANT") + "\n  , " + hk_dash1("ITEM_HK", "MATNR")
        assert check_link_hk_component_collision(sql, STG_PATH) == []

    def test_fail_identical_dash1_sentinel_keys_collide(self):
        """TRAP-01 with the STANDARD '-1' required-BK sentinel (not '^^').

        Two distinct keys built from the SAME raw columns with '-1' fallbacks
        still collide byte-for-byte. Q1 must flag this — the '^^'-only regex
        previously skipped it (false negative: components collapsed to [BKCC],
        the completeness guard then saw len != expected and skipped the compare).
        """
        def hk_dash1(name, *cols):
            parts = []
            for c in cols:
                fb = "'^^'" if c == "BKCC" else "'-1'"
                parts.append(f"COALESCE(NULLIF(TRIM(CAST({c} AS VARCHAR)), ''), {fb})")
            comps = "\n  , ".join(parts)
            return f"MD5_BINARY(UPPER(CONCAT_WS('||',\n    {comps}\n))) AS {name}"
        sql = (
            "SELECT\n    "
            + hk_dash1("INVOICE_LINE_HK", "INVOICE_ID", "LINE_NUMBER", "BKCC")
            + "\n  , "
            + hk_dash1("LNK_INVOICE_LINE_HK", "INVOICE_ID", "LINE_NUMBER", "BKCC")
        )
        findings = check_link_hk_component_collision(sql, STG_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "Q1"
        assert findings[0].severity == Severity.WARN


# ===========================================================================
# Q2: check_satellite_pii_not_split (privacy split trigger)
# ===========================================================================

class TestQ2SatellitePiiNotSplit:
    """Q2: PII in a non-PII satellite should be split for column-level masking."""

    def test_fail_pii_in_plain_satellite(self):
        sql = "SELECT CUSTOMER_HK, HASHDIFF, LOAD_DTS, REC_SRC, CUSTOMER_NAME, EMAIL, SEGMENT FROM x"
        findings = check_satellite_pii_not_split(sql, SAT_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "Q2"
        assert findings[0].severity == Severity.WARN
        assert "EMAIL" in findings[0].message

    def test_fail_multiple_pii_tokens_listed(self):
        sql = "SELECT CUSTOMER_HK, SSN, PASSPORT, TAX_ID, HASHDIFF, LOAD_DTS FROM x"
        findings = check_satellite_pii_not_split(sql, SAT_PATH)
        assert len(findings) == 1
        for tok in ("SSN", "PASSPORT", "TAX_ID"):
            assert tok in findings[0].message

    def test_pass_no_pii_tokens(self):
        sql = "SELECT CUSTOMER_HK, HASHDIFF, LOAD_DTS, REC_SRC, CUSTOMER_NAME, SEGMENT FROM x"
        assert check_satellite_pii_not_split(sql, SAT_PATH) == []

    def test_fail_snake_case_pii_columns(self):
        r"""Real-world snake_case PII (CUSTOMER_EMAIL, EMAIL_ADDRESS) MUST be caught.

        Regression guard (Gate 1 / Devil's Advocate finding): `\bEMAIL\b` fails on
        CUSTOMER_EMAIL because `_` is a word char, so there is no boundary between
        `_` and `E`. The check must treat `_` as a separator.
        """
        sql = "SELECT CUSTOMER_HK, HASHDIFF, LOAD_DTS, CUSTOMER_EMAIL, EMAIL_ADDRESS, SEGMENT FROM x"
        findings = check_satellite_pii_not_split(sql, SAT_PATH)
        assert len(findings) == 1
        assert "EMAIL" in findings[0].message

    def test_fail_snake_case_multiword_tokens(self):
        """Underscore-separated multi-word tokens must match within identifiers."""
        sql = "SELECT CUSTOMER_HK, EMPLOYEE_SSN, FEDERAL_TAX_ID, HASHDIFF FROM x"
        findings = check_satellite_pii_not_split(sql, SAT_PATH)
        assert len(findings) == 1
        assert "SSN" in findings[0].message and "TAX_ID" in findings[0].message

    def test_edge_dedicated_pii_satellite_skipped(self):
        sql = "SELECT CUSTOMER_HK, HASHDIFF, LOAD_DTS, EMAIL, SSN FROM x"
        path = "models/raw_vault/sat/sat_customer_pii__crm.sql"
        assert check_satellite_pii_not_split(sql, path) == []

    def test_edge_effectivity_satellite_skipped(self):
        """esat_ has no descriptive payload — not a split target."""
        sql = "SELECT LNK_HK, LOAD_DTS, EMAIL, START_DATE, END_DATE FROM x"
        path = "models/raw_vault/sat/esat_customer_vendor__crm.sql"
        assert check_satellite_pii_not_split(sql, path) == []

    def test_edge_non_sat_directory_ignored(self):
        sql = "SELECT CUSTOMER_HK, EMAIL FROM x"
        assert check_satellite_pii_not_split(sql, "models/raw_vault/hub/hub_customer.sql") == []

    def test_edge_word_boundary_no_false_positive(self):
        """Substrings inside larger identifiers must not trigger (e.g. RETAIL_ID)."""
        sql = "SELECT CUSTOMER_HK, RETAIL_ID, EMAILING_FLAG_NATIONAL, HASHDIFF FROM x"
        # EMAILING and NATIONAL are not whole-word EMAIL / NATIONAL_ID
        assert check_satellite_pii_not_split(sql, SAT_PATH) == []

    def test_pass_pii_only_in_line_comment(self):
        """#1914: a PII token only in a ``--`` comment is prose, not a payload column."""
        sql = (
            "-- EMAIL and SSN are intentionally excluded from this satellite\n"
            "SELECT CUSTOMER_HK, HASHDIFF, LOAD_DTS, REC_SRC, CUSTOMER_NAME, SEGMENT FROM x"
        )
        assert check_satellite_pii_not_split(sql, SAT_PATH) == []

    def test_pass_pii_only_in_block_comment(self):
        """#1914: a PII token only in a ``/* */`` block comment must not fire."""
        sql = (
            "/* This model deliberately omits EMAIL / SSN; see the PII satellite. */\n"
            "SELECT CUSTOMER_HK, HASHDIFF, LOAD_DTS, REC_SRC, CUSTOMER_NAME FROM x"
        )
        assert check_satellite_pii_not_split(sql, SAT_PATH) == []

    def test_fail_pii_in_column_even_with_comment(self):
        """#1914: stripping prose must NOT suppress a real PII payload column."""
        sql = (
            "-- note: contact details live in this model\n"
            "SELECT CUSTOMER_HK, HASHDIFF, LOAD_DTS, EMAIL, SEGMENT FROM x"
        )
        findings = check_satellite_pii_not_split(sql, SAT_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "Q2"
        assert "EMAIL" in findings[0].message
