"""Tests for MT1-MT8 multi-table XLSX validation checks in validate_tech_spec.py."""

import sys
from pathlib import Path

import pytest
from unittest.mock import MagicMock, patch
from collections import namedtuple

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from validate_tech_spec import TechSpecValidator, ValidationError


def _make_validator(config=None, metadata=None):
    """Create a TechSpecValidator with mocked workbook."""
    if config is None:
        config = {"models": [], "_pipeline_metadata": metadata or {}}
    elif metadata:
        config["_pipeline_metadata"] = metadata
    with patch("validate_tech_spec.openpyxl.load_workbook"):
        v = TechSpecValidator(config, "dummy.xlsx")
    v.errors = []
    if metadata:
        v.metadata = metadata
    return v


# ── Tables row helpers ──────────────────────────────────────────────────
# Tables sheet indices: 0=Schema, 1=Table, 2=Alias, 3=SrcLayerFilter,
#   4=FilterConds, 5=FilterRestrRule, 6=ParentJoinNum,
#   7=ParentTableJoin, 8=ChildTableJoin, 9=FinalLayerFilter,
#   10=JoinType, 11=TargetSchema, 12=ModelConfig, 13=QualifyOrderBy

def _driver_row(alias="SRC", src_filter="", final_filter="", join_type=""):
    return (
        "shopify_moen", "fulfillment", alias, src_filter,
        None, None, None,
        None, None, final_filter,
        join_type, None, None, None
    )

def _secondary_row(alias="ORD", src_filter="QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY _FIVETRAN_SYNCED DESC) = 1",
                    parent_join="ORDER_ID", child_join="ORD_ID", join_type="LEFT JOIN"):
    return (
        "shopify_moen", "ORDER", alias, src_filter,
        None, None, None,
        parent_join, child_join, None,
        join_type, None, None, None
    )

def _bkcc_row():
    return (
        "DV_DEV", "REF_BUSINESS_KEY_COLLISION", "ref_bkcc", None,
        None, None, None,
        "'1'", "'1'", None,
        "INNER JOIN", None, None, None
    )


# ── Column row helpers ──────────────────────────────────────────────────
# Columns sheet indices: 0=Schema, 1=SourceTable, 2=SourceColumn, 3=Datatype,
#   4=AutoLogic, 5=ManualLogic, 6=MappingNotes, 7=Order,
#   8=StagingColumnName, 9=StagingDatatype, 10=PK, 11=Unique,
#   12=NotNull, 13=Hashdiff, 14=GhostRecord, 15=RemoveCol,
#   16=SetDefault, 17=TestExpr, 18=AcceptedValues, 19=Relationship

def _col_row(source_table, source_col, staging_name, manual_logic="",
             hashdiff="", ghost="", pk="", unique="", not_null=""):
    return (
        "shopify_moen", source_table, source_col, "TEXT",
        "", manual_logic, "", "",
        staging_name, "TEXT", pk, unique,
        not_null, hashdiff, ghost, "",
        "", "", "", ""
    )


# ── Fixtures ────────────────────────────────────────────────────────────

@pytest.fixture
def valid_tables():
    """3-row tables: driver + secondary + BKCC."""
    return [_driver_row(), _secondary_row(), _bkcc_row()]


@pytest.fixture
def valid_columns():
    """Columns with driver + secondary + derived columns."""
    return [
        _col_row("SRC", "ID", "ID"),
        _col_row("SRC", "ORDER_ID", "ORDER_ID"),
        _col_row("SRC", "STATUS", "STATUS"),
        _col_row("SRC", "_FIVETRAN_SYNCED", "_FIVETRAN_SYNCED"),
        _col_row("ORD", "ID", "ORD_ID"),      # renamed: ID → ORD_ID (collision)
        _col_row("ORD", "NAME", "ORD_NAME"),   # renamed: NAME → ORD_NAME (collision)
        _col_row("", "(DERIVED)", "FULFILLMENT_BK", manual_logic="TO_CHAR(ID)"),
        _col_row("", "(DERIVED)", "ORDER_HEADER_BK", manual_logic="COALESCE(ORD_NAME, '-1')"),
        _col_row("", "(DERIVED)", "FULFILLMENT_HK", manual_logic="HASH: ID, BKCC"),
        _col_row("", "(DERIVED)", "ORDER_HEADER_HK", manual_logic="HASH: ORDER_HEADER_BK, BKCC"),
        _col_row("", "(DERIVED)", "LNK_ORDER_FULFILLMENT_HK",
                 manual_logic="HASH: ID, ORDER_HEADER_BK, BKCC"),
        _col_row("", "(DERIVED)", "HASHDIFF",
                 manual_logic="HASH: STATUS, ORD_ID, ORD_NAME"),
        _col_row("", "(DERIVED)", "BKCC"),
        _col_row("", "(DERIVED)", "REC_SRC"),
        _col_row("", "(DERIVED)", "LOAD_DTS"),
    ]


# ═══════════════════════════════════════════════════════════════════════
# MT1: Tables tab row count
# ═══════════════════════════════════════════════════════════════════════

class TestMT1:
    def test_pass_3_rows(self, valid_tables):
        v = _make_validator()
        v._check_mt1_tables_row_count(valid_tables, "ORD")
        assert not v.errors

    def test_fail_2_rows(self):
        v = _make_validator()
        tables = [_driver_row(), _bkcc_row()]
        v._check_mt1_tables_row_count(tables, "ORD")
        assert any(e.rule == "MT1_TABLE_ROW_COUNT" for e in v.errors)

    def test_fail_wrong_first_alias(self):
        v = _make_validator()
        tables = [_driver_row(alias="WRONG"), _secondary_row(), _bkcc_row()]
        v._check_mt1_tables_row_count(tables, "ORD")
        assert any("Row 1 alias" in e.message for e in v.errors)

    def test_fail_wrong_bkcc_alias(self):
        v = _make_validator()
        tables = [_driver_row(), _secondary_row(), _driver_row(alias="other")]
        v._check_mt1_tables_row_count(tables, "ORD")
        assert any("Row 3 alias" in e.message for e in v.errors)

    def test_fail_bkcc_not_inner(self):
        v = _make_validator()
        bkcc = (
            "DV_DEV", "REF_BUSINESS_KEY_COLLISION", "ref_bkcc", None,
            None, None, None, "'1'", "'1'", None,
            "LEFT JOIN", None, None, None
        )
        tables = [_driver_row(), _secondary_row(), bkcc]
        v._check_mt1_tables_row_count(tables, "ORD")
        assert any("INNER JOIN" in e.message for e in v.errors)


# ═══════════════════════════════════════════════════════════════════════
# MT2: Secondary QUALIFY dedup
# ═══════════════════════════════════════════════════════════════════════

class TestMT2:
    def test_pass_valid_qualify(self):
        v = _make_validator()
        sec = _secondary_row()
        v._check_mt2_secondary_qualify(sec, "ORD")
        assert not v.errors

    def test_fail_missing_filter(self):
        v = _make_validator()
        sec = _secondary_row(src_filter="")
        v._check_mt2_secondary_qualify(sec, "ORD")
        assert any(e.rule == "MT2_SECONDARY_QUALIFY" for e in v.errors)

    def test_fail_no_qualify_keyword(self):
        v = _make_validator()
        sec = _secondary_row(src_filter="ROW_NUMBER() OVER (PARTITION BY ID ORDER BY X) = 1")
        v._check_mt2_secondary_qualify(sec, "ORD")
        assert any("QUALIFY keyword" in e.message for e in v.errors)

    def test_fail_no_partition_by(self):
        v = _make_validator()
        sec = _secondary_row(src_filter="QUALIFY ROW_NUMBER() OVER (ORDER BY X DESC) = 1")
        v._check_mt2_secondary_qualify(sec, "ORD")
        assert any("PARTITION BY" in e.message for e in v.errors)

    def test_fail_no_order_by(self):
        v = _make_validator()
        sec = _secondary_row(src_filter="QUALIFY ROW_NUMBER() OVER (PARTITION BY ID) = 1")
        v._check_mt2_secondary_qualify(sec, "ORD")
        assert any("ORDER BY" in e.message for e in v.errors)


# ═══════════════════════════════════════════════════════════════════════
# MT3: Join predicate valid
# ═══════════════════════════════════════════════════════════════════════

class TestMT3:
    def test_pass_valid_join(self, valid_tables, valid_columns):
        v = _make_validator()
        sec = _secondary_row()
        v._check_mt3_join_predicate_valid(valid_tables, valid_columns, sec, "ORD")
        assert not v.errors

    def test_fail_missing_parent_join(self, valid_tables, valid_columns):
        v = _make_validator()
        sec = _secondary_row(parent_join="", child_join="ORD_ID")
        v._check_mt3_join_predicate_valid(valid_tables, valid_columns, sec, "ORD")
        assert any("missing Parent/Child" in e.message for e in v.errors)

    def test_fail_parent_col_not_in_driver(self, valid_tables, valid_columns):
        v = _make_validator()
        sec = _secondary_row(parent_join="NONEXISTENT_COL")
        v._check_mt3_join_predicate_valid(valid_tables, valid_columns, sec, "ORD")
        assert any("not found in driver" in e.message for e in v.errors)

    def test_fail_child_alias_mismatch(self, valid_tables, valid_columns):
        v = _make_validator()
        sec = _secondary_row(child_join="WRONG.ORD_ID")
        v._check_mt3_join_predicate_valid(valid_tables, valid_columns, sec, "ORD")
        assert any("doesn't match secondary alias" in e.message for e in v.errors)

    def test_fail_child_col_not_in_secondary(self, valid_tables, valid_columns):
        v = _make_validator()
        sec = _secondary_row(child_join="ORD.NONEXIST")
        v._check_mt3_join_predicate_valid(valid_tables, valid_columns, sec, "ORD")
        assert any("not found in ORD" in e.message for e in v.errors)


# ═══════════════════════════════════════════════════════════════════════
# MT4: Collision columns renamed
# ═══════════════════════════════════════════════════════════════════════

class TestMT4:
    def test_pass_renamed(self, valid_columns):
        v = _make_validator()
        v._check_mt4_collision_renamed(valid_columns, "ORD")
        assert not v.errors

    def test_fail_not_renamed(self):
        v = _make_validator()
        cols = [
            _col_row("SRC", "ID", "ID"),
            _col_row("ORD", "ID", "ID"),  # collision not renamed!
        ]
        v._check_mt4_collision_renamed(cols, "ORD")
        assert any(e.rule == "MT4_COLLISION_RENAME" for e in v.errors)
        assert any("not renamed" in e.message for e in v.errors)

    def test_skip_derived(self):
        v = _make_validator()
        cols = [
            _col_row("SRC", "ID", "ID"),
            _col_row("ORD", "(DERIVED)", "SOMETHING"),
        ]
        v._check_mt4_collision_renamed(cols, "ORD")
        assert not v.errors


# ═══════════════════════════════════════════════════════════════════════
# MT5: Secondary BK uses renamed column references
# ═══════════════════════════════════════════════════════════════════════

class TestMT5:
    def test_pass_uses_renamed(self, valid_columns):
        v = _make_validator()
        v._check_mt5_secondary_bk_refs(valid_columns, "ORD")
        assert not v.errors

    def test_fail_uses_original_name(self):
        v = _make_validator()
        cols = [
            _col_row("SRC", "NAME", "NAME"),
            _col_row("SRC", "CODE", "CODE"),
            _col_row("ORD", "NAME", "ORD_NAME"),  # renamed: collision
            _col_row("ORD", "CODE", "ORD_CODE"),  # renamed: collision
            # BK references ORD_NAME (correct) but CODE (wrong — should be ORD_CODE)
            _col_row("", "(DERIVED)", "ORDER_BK",
                     manual_logic="COALESCE(ORD_NAME, CODE, '-1')"),
        ]
        v._check_mt5_secondary_bk_refs(cols, "ORD")
        assert any(e.rule == "MT5_BK_RENAME_REF" for e in v.errors)
        assert any("CODE" in e.message and "ORD_CODE" in e.message for e in v.errors)

    def test_no_collision_no_error(self):
        v = _make_validator()
        cols = [
            _col_row("SRC", "ID", "ID"),
            _col_row("ORD", "UNIQUE_COL", "UNIQUE_COL"),  # no collision
            _col_row("", "(DERIVED)", "ORDER_BK", manual_logic="COALESCE(UNIQUE_COL, '-1')"),
        ]
        v._check_mt5_secondary_bk_refs(cols, "ORD")
        assert not v.errors


# ═══════════════════════════════════════════════════════════════════════
# MT6: HK HASH formulas valid
# ═══════════════════════════════════════════════════════════════════════

class TestMT6:
    def test_pass_bkcc_last(self, valid_columns):
        v = _make_validator()
        v._check_mt6_hk_formulas(valid_columns)
        assert not v.errors

    def test_fail_bkcc_not_last(self):
        v = _make_validator()
        cols = [
            _col_row("", "(DERIVED)", "MY_HK", manual_logic="HASH: BKCC, ID"),
        ]
        v._check_mt6_hk_formulas(cols)
        assert any(e.rule == "MT6_HK_FORMULA" for e in v.errors)
        assert any("BKCC must be last" in e.message for e in v.errors)

    def test_skip_non_hash(self):
        v = _make_validator()
        cols = [
            _col_row("", "(DERIVED)", "MY_HK", manual_logic="MD5_BINARY(...)"),
        ]
        v._check_mt6_hk_formulas(cols)
        assert not v.errors


# ═══════════════════════════════════════════════════════════════════════
# MT7: HASHDIFF excludes BK/HK
# ═══════════════════════════════════════════════════════════════════════

class TestMT7:
    def test_pass_clean_hashdiff(self, valid_columns):
        v = _make_validator()
        v._check_mt7_hashdiff_excludes(valid_columns)
        assert not v.errors

    def test_fail_bk_in_hashdiff(self):
        v = _make_validator()
        cols = [
            _col_row("", "(DERIVED)", "MY_BK"),
            _col_row("", "(DERIVED)", "HASHDIFF", manual_logic="HASH: MY_BK, STATUS"),
        ]
        v._check_mt7_hashdiff_excludes(cols)
        assert any("BK aliases must be excluded" in e.message for e in v.errors)

    def test_fail_hk_in_hashdiff(self):
        v = _make_validator()
        cols = [
            _col_row("", "(DERIVED)", "MY_HK"),
            _col_row("", "(DERIVED)", "HASHDIFF", manual_logic="HASH: MY_HK, STATUS"),
        ]
        v._check_mt7_hashdiff_excludes(cols)
        assert any("HK columns must be excluded" in e.message for e in v.errors)

    def test_fail_metadata_in_hashdiff(self):
        v = _make_validator()
        cols = [
            _col_row("", "(DERIVED)", "HASHDIFF", manual_logic="HASH: STATUS, BKCC"),
        ]
        v._check_mt7_hashdiff_excludes(cols)
        assert any("metadata column must be excluded" in e.message for e in v.errors)

    def test_fail_psa_delete_missing(self):
        v = _make_validator()
        cols = [
            _col_row("SRC", "PSA_DELETE_IND", "PSA_DELETE_IND"),
            _col_row("", "(DERIVED)", "HASHDIFF", manual_logic="HASH: STATUS"),
        ]
        v._check_mt7_hashdiff_excludes(cols)
        assert any("PSA_DELETE_IND" in e.message and "missing from HASHDIFF" in e.message
                    for e in v.errors)

    def test_pass_psa_delete_included(self):
        v = _make_validator()
        cols = [
            _col_row("SRC", "PSA_DELETE_IND", "PSA_DELETE_IND"),
            _col_row("", "(DERIVED)", "HASHDIFF", manual_logic="HASH: STATUS, PSA_DELETE_IND"),
        ]
        v._check_mt7_hashdiff_excludes(cols)
        assert not v.errors


# ═══════════════════════════════════════════════════════════════════════
# MT8: Driver QUALIFY gating
# ═══════════════════════════════════════════════════════════════════════

class TestMT8:
    def test_pass_grain_valid_no_qualify(self, valid_tables):
        v = _make_validator(metadata={"grain_valid": True})
        v._check_mt8_driver_qualify_gating(valid_tables, {})
        assert not v.errors

    def test_pass_grain_invalid_with_qualify(self):
        v = _make_validator(metadata={"grain_valid": False})
        driver = _driver_row(src_filter="QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY _FIVETRAN_SYNCED DESC) = 1")
        tables = [driver, _secondary_row(), _bkcc_row()]
        v._check_mt8_driver_qualify_gating(tables, {})
        assert not v.errors

    def test_fail_grain_valid_with_qualify(self):
        v = _make_validator(metadata={"grain_valid": True})
        driver = _driver_row(src_filter="QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY X DESC) = 1")
        tables = [driver, _secondary_row(), _bkcc_row()]
        v._check_mt8_driver_qualify_gating(tables, {})
        assert any(e.rule == "MT8_DRIVER_QUALIFY" for e in v.errors)
        assert any("grain_valid=True" in e.message for e in v.errors)

    def test_fail_grain_invalid_no_qualify(self, valid_tables):
        v = _make_validator(metadata={"grain_valid": False})
        v._check_mt8_driver_qualify_gating(valid_tables, {})
        assert any(e.rule == "MT8_DRIVER_QUALIFY" for e in v.errors)
        assert any("grain_valid=False" in e.message for e in v.errors)


# ═══════════════════════════════════════════════════════════════════════
# Integration: _detect_secondary_table
# ═══════════════════════════════════════════════════════════════════════

class TestDetectSecondary:
    def test_detects_secondary(self, valid_tables):
        v = _make_validator()
        sec = v._detect_secondary_table(valid_tables)
        assert sec is not None
        assert (sec[2] or "").strip().upper() == "ORD"

    def test_no_secondary(self):
        v = _make_validator()
        tables = [_driver_row(), _bkcc_row()]
        sec = v._detect_secondary_table(tables)
        assert sec is None

    def test_ignores_bkcc(self):
        v = _make_validator()
        tables = [_driver_row(), _bkcc_row()]
        sec = v._detect_secondary_table(tables)
        assert sec is None


# ═══════════════════════════════════════════════════════════════════════
# Integration: _run_mt_checks end-to-end
# ═══════════════════════════════════════════════════════════════════════

class TestRunMTChecks:
    def test_all_pass(self, valid_tables, valid_columns):
        v = _make_validator(metadata={"grain_valid": True})
        model = {"layer": "STG", "derived_name": "test"}
        v._run_mt_checks(model, valid_tables, valid_columns)
        assert not v.errors, f"Expected 0 errors, got: {[str(e) for e in v.errors]}"

    def test_skips_when_no_secondary(self):
        v = _make_validator()
        tables = [_driver_row(), _bkcc_row()]
        model = {"layer": "STG"}
        v._run_mt_checks(model, tables, [])
        assert not v.errors
