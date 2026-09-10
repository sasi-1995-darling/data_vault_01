"""
Tests for the ghost-record UNION ALL emission in `build.generate_union_all_block`.

Covers two defects the generator must avoid:
  (1) Satellites: a payload column with NOT NULL=Y but GHOST RECORD blank/null
      must NOT emit `NULL AS COL` — it must emit a type-appropriate sentinel
      so the ghost row does not violate the model's own not_null test.
  (2) Hubs and Links: HK and BK columns must always be populated in the ghost
      row. If the XLSX GHOST RECORD directive is blank for a HK/BK column,
      the generator must defensively substitute the canonical formula
      (`MD5_BINARY(GR.VALUE)` for HK, `GR.VALUE::number|::text` for BK).

Also exercises the pure type-sentinel map.
"""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from build import (  # noqa: E402
    _ghost_sentinel_for_datatype,
    _is_numeric_datatype,
    generate_union_all_block,
)


# ─────────────────────────────────────────────────────────────────────────────
# Pure type-sentinel map
# ─────────────────────────────────────────────────────────────────────────────

@pytest.mark.parametrize("datatype,expected", [
    ("VARCHAR", "'GHOST RECORD'::VARCHAR"),
    ("VARCHAR(255)", "'GHOST RECORD'::VARCHAR(255)"),
    ("varchar(16777216)", "'GHOST RECORD'::varchar(16777216)"),
    ("TEXT", "'GHOST RECORD'::TEXT"),
    ("STRING", "'GHOST RECORD'::STRING"),
    ("CHAR(1)", "'GHOST RECORD'::CHAR(1)"),
    ("NUMBER", "0::NUMBER"),
    ("NUMBER(38,0)", "0::NUMBER(38,0)"),
    ("INTEGER", "0::INTEGER"),
    ("FLOAT", "0::FLOAT"),
    ("DECIMAL(10,2)", "0::DECIMAL(10,2)"),
    ("DATE", "'1900-01-01'::DATE"),
    ("TIMESTAMP", "'1900-01-01'::TIMESTAMP"),
    ("TIMESTAMP_NTZ", "'1900-01-01'::TIMESTAMP_NTZ"),
    ("TIMESTAMP_LTZ", "CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP_NTZ)::TIMESTAMP_LTZ"),
    ("BOOLEAN", "FALSE"),
    ("BINARY", "TO_BINARY('00')"),
])
def test_sentinel_for_datatype(datatype, expected):
    assert _ghost_sentinel_for_datatype(datatype) == expected


@pytest.mark.parametrize("datatype", [None, "", "   ", "UNKNOWN_TYPE", "ARRAY", "OBJECT", "VARIANT", "GEOGRAPHY"])
def test_sentinel_returns_none_for_unknown(datatype):
    assert _ghost_sentinel_for_datatype(datatype) is None


@pytest.mark.parametrize("dt,is_num", [
    ("NUMBER", True),
    ("NUMBER(38,0)", True),
    ("INT", True),
    ("FLOAT", True),
    ("DECIMAL", True),
    ("VARCHAR", False),
    ("TEXT", False),
    ("DATE", False),
    ("", False),
    (None, False),
])
def test_is_numeric_datatype(dt, is_num):
    assert _is_numeric_datatype(dt) is is_num


# ─────────────────────────────────────────────────────────────────────────────
# Fixture builder for `generate_union_all_block` input dict
# ─────────────────────────────────────────────────────────────────────────────

def _col(name, *, ghost="NULL", datatype="VARCHAR", not_null="", hashdiff="", pk="", remove=""):
    """Build one column row dict in the shape `generate_union_all_block` expects."""
    return {
        "STAGING LAYER COLUMN NAME": name,
        "STAGING LAYER DATATYPE": datatype,
        "DATATYPE": datatype,
        "GHOST RECORD": ghost,
        "NOT NULL": not_null,
        "HASHDIFF": hashdiff,
        "PK": pk,
        "REMOVE COLUMN": remove,
    }


def _cols(*column_dicts):
    """Wrap a sequence of column dicts in the columns-by-index outer dict."""
    return {str(i + 1): c for i, c in enumerate(column_dicts)}


# ─────────────────────────────────────────────────────────────────────────────
# Problem 1 — Satellite NOT NULL payload sweep
# ─────────────────────────────────────────────────────────────────────────────

def test_sat_not_null_text_payload_gets_string_sentinel():
    """Sat with NOT NULL=Y on a TEXT payload + blank GHOST RECORD →
    emit 'GHOST RECORD'::TEXT, not NULL."""
    cols = _cols(
        _col("SUPPLIER_HK", ghost="hash"),
        _col("PARTY_ID", ghost="value_text", pk="yes"),
        _col("LOAD_DTS", ghost="load_dts"),
        _col("PARTY_NAME", ghost="", datatype="TEXT", not_null="yes"),  # the bug-target column
        _col("HASHDIFF", ghost="hashdiff", hashdiff="yes"),
    )
    block = generate_union_all_block(cols, "SAT_SUPPLIER_PARTY__FIB_OCF")
    assert "'GHOST RECORD'::TEXT AS PARTY_NAME" in block
    assert "NULL AS PARTY_NAME" not in block


def test_sat_not_null_number_payload_gets_zero_sentinel():
    cols = _cols(
        _col("CUSTOMER_HK", ghost="hash"),
        _col("LOAD_DTS", ghost="load_dts"),
        _col("CREDIT_LIMIT", ghost="", datatype="NUMBER(10,2)", not_null="yes"),
        _col("HASHDIFF", ghost="hashdiff", hashdiff="yes"),
    )
    block = generate_union_all_block(cols, "SAT_CUSTOMER_FINANCIALS__SAP")
    assert "0::NUMBER(10,2) AS CREDIT_LIMIT" in block


def test_sat_not_null_date_payload_gets_1900_sentinel():
    cols = _cols(
        _col("ORDER_HK", ghost="hash"),
        _col("LOAD_DTS", ghost="load_dts"),
        _col("DELIVERY_DATE", ghost="", datatype="DATE", not_null="yes"),
        _col("HASHDIFF", ghost="hashdiff", hashdiff="yes"),
    )
    block = generate_union_all_block(cols, "SAT_ORDER_DATES__SAP")
    assert "'1900-01-01'::DATE AS DELIVERY_DATE" in block


def test_sat_not_null_timestamp_ltz_payload_gets_convert_timezone():
    cols = _cols(
        _col("EVENT_HK", ghost="hash"),
        _col("LOAD_DTS", ghost="load_dts"),
        _col("EVENT_TS", ghost="", datatype="TIMESTAMP_LTZ", not_null="yes"),
        _col("HASHDIFF", ghost="hashdiff", hashdiff="yes"),
    )
    block = generate_union_all_block(cols, "SAT_EVENTS__APP")
    assert "CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP_NTZ)::TIMESTAMP_LTZ AS EVENT_TS" in block


def test_sat_not_null_boolean_payload_gets_false():
    cols = _cols(
        _col("FLAG_HK", ghost="hash"),
        _col("LOAD_DTS", ghost="load_dts"),
        _col("IS_ACTIVE", ghost="", datatype="BOOLEAN", not_null="yes"),
        _col("HASHDIFF", ghost="hashdiff", hashdiff="yes"),
    )
    block = generate_union_all_block(cols, "SAT_FLAGS__APP")
    assert "FALSE AS IS_ACTIVE" in block


def test_sat_nullable_payload_keeps_null_behavior():
    """If NOT NULL is blank, NULL emission is preserved (no over-eager
    substitution). This is the negative-control test that proves the
    substitution is GATED on NOT NULL=Y."""
    cols = _cols(
        _col("X_HK", ghost="hash"),
        _col("LOAD_DTS", ghost="load_dts"),
        _col("OPTIONAL_COL", ghost="", datatype="TEXT", not_null=""),  # nullable
        _col("HASHDIFF", ghost="hashdiff", hashdiff="yes"),
    )
    block = generate_union_all_block(cols, "SAT_X__SRC")
    assert "NULL AS OPTIONAL_COL" in block
    assert "'GHOST RECORD'::TEXT AS OPTIONAL_COL" not in block


def test_sat_not_null_unknown_datatype_falls_back_to_string_sentinel():
    """If the datatype is unknown (e.g., VARIANT, ARRAY), the generator must
    NOT emit NULL on a not_null column. It falls back to a string sentinel
    rather than silently producing a broken ghost row."""
    cols = _cols(
        _col("X_HK", ghost="hash"),
        _col("LOAD_DTS", ghost="load_dts"),
        _col("WEIRD_COL", ghost="", datatype="VARIANT", not_null="yes"),
        _col("HASHDIFF", ghost="hashdiff", hashdiff="yes"),
    )
    block = generate_union_all_block(cols, "SAT_X__SRC")
    assert "'GHOST RECORD'::TEXT AS WEIRD_COL" in block
    assert "NULL AS WEIRD_COL" not in block


def test_sat_not_null_substitution_applies_to_all_sat_variants():
    """The NOT NULL payload sweep must apply to every sat-variant prefix:
    SAT_, LSAT_, MSAT_, ESAT_, LMSAT_, RSAT_."""
    for prefix in ("SAT_", "LSAT_", "MSAT_", "ESAT_", "LMSAT_", "RSAT_"):
        cols = _cols(
            _col("X_HK", ghost="hash"),
            _col("LOAD_DTS", ghost="load_dts"),
            _col("PAY", ghost="", datatype="TEXT", not_null="yes"),
            _col("HASHDIFF", ghost="hashdiff", hashdiff="yes"),
        )
        block = generate_union_all_block(cols, f"{prefix}X__SRC")
        assert "'GHOST RECORD'::TEXT AS PAY" in block, f"failed for prefix {prefix}"


def test_sat_hk_blank_ghost_emits_md5_binary_not_typed_sentinel():
    """REGRESSION (DA gate, 2026-06-22):
    A sat's HK column with blank GHOST RECORD + NOT NULL=Y must emit
    MD5_BINARY(GR.VALUE), NOT a TO_BINARY('00') typed sentinel.

    Why: the sat ghost row's HK must match the parent hub's ghost HK so
    FK joins to the ghost parent return a row. The hub ghost emits
    MD5_BINARY(GR.VALUE); the sat MUST emit the same expression on its
    parent HK column.

    Pre-fix, the sat NOT-NULL payload sweep claimed the HK column (because
    it has NOT NULL=Y) and substituted TO_BINARY('00') from the BINARY type
    map. That broke the sat<->hub FK relationship on the ghost row.
    """
    cols = _cols(
        _col("SUPPLIER_HK", ghost="", datatype="BINARY(16)", not_null="yes", pk="yes"),
        _col("LOAD_DTS", ghost="load_dts"),
        _col("PAYLOAD_COL", ghost="", datatype="TEXT"),  # nullable payload
        _col("HASHDIFF", ghost="hashdiff", hashdiff="yes"),
    )
    block = generate_union_all_block(cols, "SAT_SUPPLIER_DETAILS__FIB")
    assert "MD5_BINARY(GR.VALUE) AS SUPPLIER_HK" in block
    assert "TO_BINARY('00') AS SUPPLIER_HK" not in block


def test_lsat_link_hk_blank_ghost_emits_md5_binary():
    """LSAT (link-satellite) — parent HK is a LNK_*_HK. Same rule applies:
    must emit MD5_BINARY(GR.VALUE) for ghost-row FK matching."""
    cols = _cols(
        _col("LNK_ORDER_ITEM_HK", ghost="", datatype="BINARY(16)", not_null="yes", pk="yes"),
        _col("LOAD_DTS", ghost="load_dts"),
        _col("HASHDIFF", ghost="hashdiff", hashdiff="yes"),
    )
    block = generate_union_all_block(cols, "LSAT_ORDER_ITEM_STATUS__SAP")
    assert "MD5_BINARY(GR.VALUE) AS LNK_ORDER_ITEM_HK" in block


def test_hub_not_null_payload_is_NOT_substituted():
    """The NOT NULL payload sweep is sat-only. Hubs don't carry payload, so
    if a hub had NOT NULL=Y on some non-BK/non-HK column, do NOT trigger the
    sat sentinel — the hub-specific BK/HK sweep handles hub columns. This
    keeps the two branches cleanly separated."""
    cols = _cols(
        _col("CUST_HK", ghost="hash"),
        _col("CUST_BK", ghost="value_text"),
        _col("LOAD_DTS", ghost="load_dts"),
        _col("WEIRD_HUB_COL", ghost="", datatype="TEXT", not_null="yes"),  # not _HK, not _BK
    )
    block = generate_union_all_block(cols, "HUB_CUSTOMER")
    # The "weird" column doesn't match HK/BK suffix, doesn't trigger sat sweep
    # on a HUB, so it falls through to NULL emission. This is intentional:
    # NOT NULL on a non-key hub column is itself a design smell and should
    # surface as a build failure rather than be hidden by silent substitution.
    assert "NULL AS WEIRD_HUB_COL" in block


# ─────────────────────────────────────────────────────────────────────────────
# Problem 2 — Hub/Link HK/BK defensive sweep
# ─────────────────────────────────────────────────────────────────────────────

def test_hub_bk_blank_ghost_directive_emits_value_text_cast():
    """Hub BK column with blank GHOST RECORD must NOT emit NULL — defensive
    sweep substitutes GR.VALUE::text (TEXT datatype path)."""
    cols = _cols(
        _col("CUSTOMER_HK", ghost="hash"),
        _col("CUSTOMER_BK", ghost="", datatype="VARCHAR(50)"),  # author forgot 'value_text'
        _col("LOAD_DTS", ghost="load_dts"),
    )
    block = generate_union_all_block(cols, "HUB_CUSTOMER")
    assert "GR.VALUE::text AS CUSTOMER_BK" in block
    assert "NULL AS CUSTOMER_BK" not in block


def test_hub_bk_blank_ghost_directive_with_numeric_emits_value_number_cast():
    cols = _cols(
        _col("ACCOUNT_HK", ghost="hash"),
        _col("ACCOUNT_BK", ghost="", datatype="NUMBER(18,0)"),  # numeric BK, author forgot 'value_number'
        _col("LOAD_DTS", ghost="load_dts"),
    )
    block = generate_union_all_block(cols, "HUB_ACCOUNT")
    assert "GR.VALUE::number AS ACCOUNT_BK" in block


def test_hub_hk_blank_ghost_directive_emits_md5_binary():
    """Hub HK column with blank GHOST RECORD must NOT emit NULL — defensive
    sweep substitutes MD5_BINARY(GR.VALUE) so the ghost row's HK is non-null
    and matches the K5 reviewer pattern."""
    cols = _cols(
        _col("ITEM_HK", ghost=""),  # author forgot 'hash'
        _col("ITEM_BK", ghost="value_text"),
        _col("LOAD_DTS", ghost="load_dts"),
    )
    block = generate_union_all_block(cols, "HUB_ITEM")
    assert "MD5_BINARY(GR.VALUE) AS ITEM_HK" in block
    assert "NULL AS ITEM_HK" not in block


def test_link_with_multiple_hks_all_blank_get_md5_binary():
    """Multi-HK link with EVERY HK ghost-directive blank must populate all
    of them — link HK, parent HK 1, parent HK 2."""
    cols = _cols(
        _col("LNK_ORDER_ITEM_HK", ghost=""),
        _col("ORDER_HK", ghost=""),
        _col("ITEM_HK", ghost=""),
        _col("LOAD_DTS", ghost="load_dts"),
    )
    block = generate_union_all_block(cols, "LNK_ORDER_ITEM")
    assert "MD5_BINARY(GR.VALUE) AS LNK_ORDER_ITEM_HK" in block
    assert "MD5_BINARY(GR.VALUE) AS ORDER_HK" in block
    assert "MD5_BINARY(GR.VALUE) AS ITEM_HK" in block
    assert "NULL AS" not in block  # no NULL HKs


def test_tlink_with_multiple_hks_get_md5_binary():
    """TLINK prefix triggers link sweep."""
    cols = _cols(
        _col("TLINK_TXN_HK", ghost=""),
        _col("TXN_HK", ghost=""),
        _col("LOAD_DTS", ghost="load_dts"),
    )
    block = generate_union_all_block(cols, "TLINK_TXN_EVENTS")
    assert "MD5_BINARY(GR.VALUE) AS TLINK_TXN_HK" in block
    assert "MD5_BINARY(GR.VALUE) AS TXN_HK" in block


def test_explicit_hash_directive_unchanged_by_sweep():
    """Defensive sweep only fires on blank/null — explicit 'hash' directive
    still emits MD5_BINARY(GR.VALUE), no behavior change."""
    cols = _cols(
        _col("CUSTOMER_HK", ghost="hash"),
        _col("CUSTOMER_BK", ghost="value_text"),
        _col("LOAD_DTS", ghost="load_dts"),
    )
    block = generate_union_all_block(cols, "HUB_CUSTOMER")
    assert block.count("MD5_BINARY(GR.VALUE) AS CUSTOMER_HK") == 1


# ─────────────────────────────────────────────────────────────────────────────
# Cross-cutting: K1/K5 reviewer compatibility
# ─────────────────────────────────────────────────────────────────────────────

def test_generated_ghost_block_preserves_k5_hk_pattern():
    """The K5 reviewer check requires MD5_BINARY(GR.VALUE) for HK in ghost
    rows. Confirm the defensive sweep produces output that K5 accepts."""
    cols = _cols(
        _col("CUSTOMER_HK", ghost=""),       # sweep fills this
        _col("CUSTOMER_BK", ghost="value_text"),
        _col("BKCC", ghost="bkcc"),
        _col("LOAD_DTS", ghost="load_dts"),
    )
    block = generate_union_all_block(cols, "HUB_CUSTOMER")
    # K5 pattern present
    assert "MD5_BINARY(GR.VALUE)" in block
    # K1 BKCC pattern preserved
    assert "DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM'" in block


def test_generated_ghost_block_preserves_k2_three_sentinels():
    """K2 requires strtok_split_to_table('0|-1|-2', '|') — unchanged by the
    sweep."""
    cols = _cols(
        _col("CUSTOMER_HK", ghost=""),
        _col("LOAD_DTS", ghost="load_dts"),
    )
    block = generate_union_all_block(cols, "HUB_CUSTOMER")
    assert "strtok_split_to_table('0|-1|-2', '|')" in block
