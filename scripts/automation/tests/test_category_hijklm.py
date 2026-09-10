#!/usr/bin/env python3
"""
test_category_hijklm.py — Tests for Categories H-M.

H (YAML/Test Coverage), I (Source/Layer), J (Incremental Config),
K (Ghost Records), L (Join Patterns), M (Miscellaneous).

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_category_hijklm.py -v
"""
import sys
from pathlib import Path

import pytest

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_review_config import FileStatus
from code_reviewer import (
    Severity,
    # Category H
    check_data_tests_not_deprecated,
    check_no_constraints_on_views,
    # Category I
    check_uses_source_or_ref,
    check_dim_fact_no_business_logic,
    # Category J
    check_where_not_exists_uses_hashdiff,
    check_hub_where_not_exists_hk_only,
    check_watermark_scoped_per_rec_src,
    # Category K
    check_ghost_record_decode_pattern,
    check_ghost_record_three_sentinels,
    check_ghost_record_hk_formula,
    check_ghost_record_keys_not_null,
    # Category L
    check_inner_join_has_comment,
    # Category M
    check_no_hardcoded_env,
    check_no_select_star_outside_src,
    check_rec_src_format,
    check_header_comment_present,
)

VPSA_PATH = "models/int_staging_views/supplier/v_psa_stg_supplier__winn_sap.sql"
VPSA_YAML = "models/int_staging_views/supplier/v_psa_stg_supplier__winn_sap.yml"
SAT_PATH = "models/raw_vault/sat/sat_supplier__winn_sap.sql"
SAT_YAML = "models/raw_vault/sat/_model_yml/sat_supplier__winn_sap.yml"
HUB_PATH = "models/raw_vault/hub/hub_supplier.sql"
DIM_PATH = "models/bus_vault/dim/dim_supplier.sql"
FACT_PATH = "models/bus_vault/fact/fact_order.sql"

# ═══════════════════════════════════════════════════════════════════════════════
# H2: data_tests_not_deprecated
# ═══════════════════════════════════════════════════════════════════════════════

class TestH2DataTestsNotDeprecated:
    """H2: Use data_tests: not deprecated tests: in YAML."""

    def test_pass_data_tests(self):
        yaml = """
models:
  - name: v_psa_stg_supplier__winn_sap
    columns:
      - name: SUPPLIER_BK
        data_tests:
          - not_null
"""
        findings = check_data_tests_not_deprecated("", VPSA_YAML, yaml_content=yaml)
        assert findings == []

    def test_fail_deprecated_tests(self):
        yaml = """
models:
  - name: v_psa_stg_supplier__winn_sap
    columns:
      - name: SUPPLIER_BK
        tests:
          - not_null
"""
        findings = check_data_tests_not_deprecated("", VPSA_YAML, yaml_content=yaml)
        assert len(findings) == 1
        assert findings[0].check_id == "H2"
        assert findings[0].severity == Severity.FAIL

    def test_edge_no_yaml(self):
        findings = check_data_tests_not_deprecated("", VPSA_YAML, yaml_content=None)
        assert findings == []

    def test_edge_non_yaml_file(self):
        findings = check_data_tests_not_deprecated("", VPSA_PATH, yaml_content="tests: []")
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# H8: no_constraints_on_views
# ═══════════════════════════════════════════════════════════════════════════════

class TestH8NoConstraintsOnViews:
    """H8: dbt_constraints must NOT be on v_psa_stg views."""

    def test_pass_no_constraints_on_vpsa(self):
        yaml = """
models:
  - name: v_psa_stg_supplier__winn_sap
    columns:
      - name: SUPPLIER_BK
        data_tests:
          - not_null
"""
        findings = check_no_constraints_on_views("", VPSA_YAML, yaml_content=yaml)
        assert findings == []

    def test_fail_constraints_on_vpsa(self):
        yaml = """
models:
  - name: v_psa_stg_supplier__winn_sap
    data_tests:
      - dbt_constraints.primary_key:
          column_name: SUPPLIER_HK
"""
        findings = check_no_constraints_on_views("", VPSA_YAML, yaml_content=yaml)
        assert len(findings) >= 1
        assert findings[0].check_id == "H8"

    def test_edge_constraints_on_sat_ok(self):
        """Constraints are valid on tables (sats) — not flagged."""
        yaml = """
models:
  - name: sat_supplier__winn_sap
    data_tests:
      - dbt_constraints.primary_key:
          column_name: SUPPLIER_HK
"""
        findings = check_no_constraints_on_views("", SAT_YAML, yaml_content=yaml)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# I1: uses_source_or_ref
# ═══════════════════════════════════════════════════════════════════════════════

class TestI1UsesSourceOrRef:
    """I1: FROM clauses must use source() or ref() — no direct SCHEMA.TABLE."""

    def test_pass_source_function(self):
        sql = "SRC_S as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_vendor') }} )"
        findings = check_uses_source_or_ref(sql, VPSA_PATH)
        assert findings == []

    def test_fail_direct_schema_table(self):
        sql = "SRC_S as ( SELECT * FROM SAP_ECC_PRD.Z_VBUP )"
        findings = check_uses_source_or_ref(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "I1"
        assert "SAP_ECC_PRD.Z_VBUP" in findings[0].message

    def test_edge_inside_comment_ignored(self):
        sql = """
        /*
        SRC_S as ( SELECT * FROM SAP_ECC_PRD.Z_VBUP )
        */
        SRC_S as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_vbup') }} )
        """
        findings = check_uses_source_or_ref(sql, VPSA_PATH)
        assert findings == []

    def test_edge_multiple_violations(self):
        sql = """
        SRC_a as ( SELECT * FROM SAP_ECC_PRD.Z_QMEL )
        , SRC_b as ( SELECT * FROM RAW_VAULT.REF_BUSINESS_KEY_COLLISION )
        """
        findings = check_uses_source_or_ref(sql, VPSA_PATH)
        assert len(findings) == 2


# ═══════════════════════════════════════════════════════════════════════════════
# I3: dim_fact_no_business_logic
# ═══════════════════════════════════════════════════════════════════════════════

class TestI3DimFactNoBusinessLogic:
    """I3: dim/fact models should not contain CASE WHEN."""

    def test_pass_simple_wrapper(self):
        sql = "SELECT * FROM {{ ref('pit_supplier') }}"
        findings = check_dim_fact_no_business_logic(sql, DIM_PATH)
        assert findings == []

    def test_warn_case_when_in_dim(self):
        sql = "SELECT CASE WHEN status = 'Active' THEN 1 ELSE 0 END AS is_active FROM pit"
        findings = check_dim_fact_no_business_logic(sql, DIM_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "I3"
        assert findings[0].severity == Severity.WARN

    def test_edge_case_when_in_sat_not_flagged(self):
        """CASE WHEN in sat is fine — this check only applies to dim/fact."""
        sql = "SELECT CASE WHEN status = 'X' THEN 'Blocked' END FROM stg"
        findings = check_dim_fact_no_business_logic(sql, SAT_PATH)
        assert findings == []

    def test_edge_case_when_in_comment_ignored(self):
        sql = "-- CASE WHEN status = 'Active' THEN 1\nSELECT * FROM pit"
        findings = check_dim_fact_no_business_logic(sql, DIM_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# J1: where_not_exists_uses_hashdiff
# ═══════════════════════════════════════════════════════════════════════════════

class TestJ1WhereNotExistsUsesHashdiff:
    """J1: Satellite WHERE NOT EXISTS must compare on HK AND HASHDIFF."""

    def test_pass_hk_and_hashdiff(self):
        sql = """
        WHERE NOT EXISTS (
            SELECT 1 FROM {{ this }} existing
            WHERE existing.SUPPLIER_HK = JOIN_RESULT.SUPPLIER_HK
            AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
        )
        """
        findings = check_where_not_exists_uses_hashdiff(sql, SAT_PATH)
        assert findings == []

    def test_fail_hk_only(self):
        sql = """
        WHERE NOT EXISTS (
            SELECT 1 FROM {{ this }} existing
            WHERE existing.SUPPLIER_HK = JOIN_RESULT.SUPPLIER_HK
        )
        """
        findings = check_where_not_exists_uses_hashdiff(sql, SAT_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "J1"
        assert findings[0].severity == Severity.FAIL

    def test_edge_not_sat_path(self):
        """WHERE NOT EXISTS in hub should not trigger J1 (that's J2's job)."""
        sql = "WHERE NOT EXISTS (SELECT 1 FROM {{ this }} WHERE SUPPLIER_HK = new.SUPPLIER_HK)"
        findings = check_where_not_exists_uses_hashdiff(sql, HUB_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# J2: hub_where_not_exists_hk_only
# ═══════════════════════════════════════════════════════════════════════════════

class TestJ2HubWhereNotExistsHkOnly:
    """J2: Hub WHERE NOT EXISTS should compare on HK only."""

    def test_pass_hk_only(self):
        sql = """
        WHERE NOT EXISTS (
            SELECT 1 FROM {{ this }} existing
            WHERE existing.SUPPLIER_HK = new.SUPPLIER_HK
        )
        """
        findings = check_hub_where_not_exists_hk_only(sql, HUB_PATH)
        assert findings == []

    def test_warn_hashdiff_in_hub(self):
        sql = """
        WHERE NOT EXISTS (
            SELECT 1 FROM {{ this }} existing
            WHERE existing.SUPPLIER_HK = new.SUPPLIER_HK
            AND existing.HASHDIFF = new.HASHDIFF
        )
        """
        findings = check_hub_where_not_exists_hk_only(sql, HUB_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "J2"
        assert findings[0].severity == Severity.WARN

    def test_edge_sat_path_not_checked(self):
        """J2 only checks hubs."""
        sql = "WHERE NOT EXISTS (SELECT 1 WHERE HASHDIFF = HASHDIFF)"
        findings = check_hub_where_not_exists_hk_only(sql, SAT_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# J5: watermark_scoped_per_rec_src
# ═══════════════════════════════════════════════════════════════════════════════

class TestJ5WatermarkScopedPerRecSrc:
    """J5: Incremental watermark must be scoped per REC_SRC (hubs/links only)."""

    def test_pass_group_by_rec_src(self):
        sql = """
        INCR_WATERMARK AS (
            SELECT REC_SRC, DATEADD(DAY, -1, MAX(LOAD_DTS)) AS watermark_dts
            FROM {{this}}
            GROUP BY REC_SRC
        )
        """
        findings = check_watermark_scoped_per_rec_src(sql, HUB_PATH)
        assert findings == []

    def test_fail_global_watermark_new_file(self):
        sql = """
        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
        """
        findings = check_watermark_scoped_per_rec_src(sql, HUB_PATH, file_status=FileStatus.NEW)
        assert len(findings) == 1
        assert findings[0].check_id == "J5"
        assert findings[0].severity == Severity.FAIL

    def test_warn_global_watermark_modified_file(self):
        sql = """
        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
        """
        findings = check_watermark_scoped_per_rec_src(sql, HUB_PATH, file_status=FileStatus.MODIFIED)
        assert len(findings) == 1
        assert findings[0].severity == Severity.WARN

    def test_edge_no_this_reference(self):
        """Non-incremental model — no {{this}} — should not fire."""
        sql = "SELECT MAX(LOAD_DTS) FROM some_table"
        findings = check_watermark_scoped_per_rec_src(sql, HUB_PATH)
        assert findings == []

    def test_skip_satellite_single_source(self):
        """Satellites are single-source — global watermark is safe, J5 should not fire."""
        sql = """
        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
        """
        for sat_prefix in ["sat_", "msat_", "lsat_", "esat_"]:
            path = f"models/raw_vault/sat/{sat_prefix}test__src.sql"
            findings = check_watermark_scoped_per_rec_src(sql, path, file_status=FileStatus.NEW)
            assert findings == [], f"J5 should not fire on {sat_prefix} (single-source)"


# ═══════════════════════════════════════════════════════════════════════════════
# K1: ghost_record_decode_pattern
# ═══════════════════════════════════════════════════════════════════════════════

class TestK1GhostRecordDecodePattern:
    """K1: Ghost record BKCC must use standard DECODE pattern."""

    STANDARD_GHOST = """
    SELECT MD5_BINARY(GR.VALUE) as SUPPLIER_HK
    , GR.VALUE AS SUPPLIER_BK
    , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
    , CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS
    , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
    FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
    """

    def test_pass_standard_decode(self):
        findings = check_ghost_record_decode_pattern(self.STANDARD_GHOST, HUB_PATH)
        assert findings == []

    def test_fail_nonstandard_bkcc(self):
        sql = """
        SELECT MD5_BINARY(GR.VALUE) as SUPPLIER_HK
        , 'GHOST' AS BKCC
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        findings = check_ghost_record_decode_pattern(sql, HUB_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "K1"

    def test_edge_no_ghost_record(self):
        """File without ghost records — skip."""
        sql = "SELECT * FROM {{ ref('v_psa_stg_supplier__winn_sap') }}"
        findings = check_ghost_record_decode_pattern(sql, HUB_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# K2: ghost_record_three_sentinels
# ═══════════════════════════════════════════════════════════════════════════════

class TestK2GhostRecordThreeSentinels:
    """K2: Ghost records must include all three sentinels (0, -1, -2)."""

    def test_pass_all_three(self):
        sql = "FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR"
        findings = check_ghost_record_three_sentinels(sql, HUB_PATH)
        assert findings == []

    def test_fail_only_zero(self):
        sql = "FROM TABLE(strtok_split_to_table('0', '|')) AS GR"
        findings = check_ghost_record_three_sentinels(sql, HUB_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "K2"

    def test_edge_not_raw_vault(self):
        sql = "FROM TABLE(strtok_split_to_table('0', '|')) AS GR"
        findings = check_ghost_record_three_sentinels(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# K5: ghost_record_hk_formula
# ═══════════════════════════════════════════════════════════════════════════════

class TestK5GhostRecordHkFormula:
    """K5: Ghost record HK must use MD5_BINARY(GR.VALUE), not binary literal."""

    def test_pass_md5_binary_gr(self):
        sql = """
        SELECT MD5_BINARY(GR.VALUE) as SUPPLIER_HK
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        findings = check_ghost_record_hk_formula(sql, HUB_PATH)
        assert findings == []

    def test_fail_binary_literal(self):
        sql = """
        SELECT x'00000000000000000000000000000000' AS SUPPLIER_HK
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        findings = check_ghost_record_hk_formula(sql, HUB_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "K5"

    def test_edge_no_ghost(self):
        sql = "SELECT x'00' FROM some_table"  # x'...' but not in ghost section
        findings = check_ghost_record_hk_formula(sql, HUB_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# K6: ghost_record_keys_not_null
# ═══════════════════════════════════════════════════════════════════════════════

LINK_PATH = "models/raw_vault/link/lnk_order_item.sql"


class TestK6GhostRecordKeysNotNull:
    """K6: A ghost-row `_HK` or hub `_BK` column must not be emitted as NULL.

    Companion to K5 (which catches wrong formulas like binary literals). K6
    catches the *missing* GHOST RECORD directive case where the author left
    the column out and the SQL ended up with `NULL AS <col>_HK`.
    """

    # ── PASS cases ────────────────────────────────────────────────────────────

    def test_pass_hub_with_correct_hk_and_bk(self):
        sql = """
        union all
        SELECT
        MD5_BINARY(GR.VALUE) AS CUSTOMER_HK,
        GR.VALUE::text AS CUSTOMER_BK,
        'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        assert check_ghost_record_keys_not_null(sql, HUB_PATH) == []

    def test_pass_link_with_correct_hks(self):
        sql = """
        union all
        SELECT
        MD5_BINARY(GR.VALUE) AS LNK_ORDER_ITEM_HK,
        MD5_BINARY(GR.VALUE) AS ORDER_HK,
        MD5_BINARY(GR.VALUE) AS ITEM_HK
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        assert check_ghost_record_keys_not_null(sql, LINK_PATH) == []

    def test_pass_null_on_nullable_payload(self):
        """A NULL on a non-key column (e.g., REC_SRC or a stray payload column
        if it ever appears in a hub ghost row) must NOT trigger K6 — only
        _HK and _BK suffixes do."""
        sql = """
        union all
        SELECT
        MD5_BINARY(GR.VALUE) AS CUSTOMER_HK,
        GR.VALUE::text AS CUSTOMER_BK,
        NULL AS SOME_NULLABLE_COLUMN
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        assert check_ghost_record_keys_not_null(sql, HUB_PATH) == []

    # ── FAIL cases ────────────────────────────────────────────────────────────

    def test_fail_hub_hk_emitted_as_null(self):
        sql = """
        union all
        SELECT
        NULL AS CUSTOMER_HK,
        GR.VALUE::text AS CUSTOMER_BK
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        findings = check_ghost_record_keys_not_null(sql, HUB_PATH)
        assert len(findings) == 1
        f = findings[0]
        assert f.check_id == "K6"
        assert f.severity == Severity.FAIL
        assert "CUSTOMER_HK" in f.message
        assert "MD5_BINARY(GR.VALUE)" in f.suggestion
        assert "hash" in f.suggestion  # the directive name

    def test_fail_hub_bk_emitted_as_null(self):
        sql = """
        union all
        SELECT
        MD5_BINARY(GR.VALUE) AS CUSTOMER_HK,
        NULL AS CUSTOMER_BK
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        findings = check_ghost_record_keys_not_null(sql, HUB_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "K6"
        assert "CUSTOMER_BK" in findings[0].message
        assert "value_text" in findings[0].suggestion

    def test_fail_link_hk_emitted_as_null(self):
        sql = """
        union all
        SELECT
        NULL AS LNK_ORDER_ITEM_HK,
        MD5_BINARY(GR.VALUE) AS ORDER_HK,
        MD5_BINARY(GR.VALUE) AS ITEM_HK
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        findings = check_ghost_record_keys_not_null(sql, LINK_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "K6"
        assert "LNK_ORDER_ITEM_HK" in findings[0].message

    def test_fail_link_multiple_parent_hks_null(self):
        """Multi-HK link where ALL three HKs are emitted as NULL — three
        separate findings, one per offending column.

        Stronger than 3× `any(...)` substring checks: the SET equality below
        proves three DISTINCT column names. A substring-only assertion would
        be satisfied if e.g. all three findings mentioned `LNK_ORDER_ITEM_HK`
        (which contains `ORDER_HK` and `ITEM_HK` as substrings), so it
        wouldn't actually catch a single-finding regression that produces
        the right-looking text by accident.
        """
        sql = """
        union all
        SELECT
        NULL AS LNK_ORDER_ITEM_HK,
        NULL AS ORDER_HK,
        NULL AS ITEM_HK
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        findings = check_ghost_record_keys_not_null(sql, LINK_PATH)
        assert len(findings) == 3
        # Extract the offending column name from each finding's message.
        # Message format: "Ghost row emits `NULL AS {col_name}` for a {HK|BK} column. ..."
        import re
        _COL_RE = re.compile(r"`NULL AS (\w+)`")
        names = set()
        for f in findings:
            m = _COL_RE.search(f.message)
            assert m, f"Could not extract column name from K6 message: {f.message!r}"
            names.add(m.group(1))
        assert names == {"LNK_ORDER_ITEM_HK", "ORDER_HK", "ITEM_HK"}, (
            f"K6 must flag the three distinct null HK columns. Got: {names}"
        )

    def test_fail_link_bk_not_checked(self):
        """Links have no BK by design. Even if a link somehow has a `_BK`
        suffixed column with NULL, K6 must NOT flag it — that would be a
        false positive against the spec (links have no BK)."""
        sql = """
        union all
        SELECT
        MD5_BINARY(GR.VALUE) AS LNK_ORDER_HK,
        NULL AS ORDER_BK
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        findings = check_ghost_record_keys_not_null(sql, LINK_PATH)
        # link _BK is NOT flagged; only _HK applies for links
        assert findings == []

    # ── SCOPE cases ───────────────────────────────────────────────────────────

    def test_edge_sat_not_in_scope(self):
        """Sat HK ghost-row NULL emission is left to the generator's defensive
        self-heal (see DA-gate fix in f4df1713). K6 does not apply to sats by
        design — see module-level note."""
        sat_path = "models/raw_vault/sat/sat_customer_details__sap.sql"
        sql = """
        union all
        SELECT
        NULL AS CUSTOMER_HK,
        '1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        assert check_ghost_record_keys_not_null(sql, sat_path) == []

    def test_edge_v_psa_stg_not_in_scope(self):
        """K6 only applies under raw_vault/hub/ and raw_vault/link/."""
        sql = """
        union all
        SELECT
        NULL AS CUSTOMER_HK
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        assert check_ghost_record_keys_not_null(sql, VPSA_PATH) == []

    def test_edge_no_ghost_block(self):
        """A hub SQL with no ghost block (incremental-only model that never
        emits ghost rows) returns no findings — K6 is gated on _has_ghost_record."""
        sql = "SELECT MD5_BINARY(GR.VALUE) AS CUSTOMER_HK FROM SRC"
        assert check_ghost_record_keys_not_null(sql, HUB_PATH) == []

    def test_edge_null_outside_ghost_block_ignored(self):
        """A `NULL AS CUSTOMER_HK` that appears OUTSIDE the ghost block (e.g.,
        in the main SELECT for some reason) must NOT be flagged — K6 only
        scans the strtok_split_to_table ghost-row segment."""
        sql = """
        SELECT
        NULL AS CUSTOMER_HK   -- some unrelated thing in main select
        FROM SRC
        union all
        SELECT
        MD5_BINARY(GR.VALUE) AS CUSTOMER_HK,
        GR.VALUE::text AS CUSTOMER_BK
        FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
        """
        assert check_ghost_record_keys_not_null(sql, HUB_PATH) == []

    # ── BELT-AND-SUSPENDERS contract with generator ───────────────────────────

    def test_generator_self_heal_output_passes_k6(self):
        """The generator's defensive sweep emits MD5_BINARY(GR.VALUE) for blank
        _HK directives. K6 must NOT flag generator-produced output — only
        hand-edits or pre-generator legacy code with the bug."""
        import sys
        sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parents[1] / "src"))
        from build import generate_union_all_block

        cols = {
            '1': {'STAGING LAYER COLUMN NAME': 'CUSTOMER_HK', 'STAGING LAYER DATATYPE': 'BINARY(16)',
                  'GHOST RECORD': '',  # blank — generator self-heals
                  'NOT NULL': '', 'HASHDIFF': '', 'PK': '', 'REMOVE COLUMN': ''},
            '2': {'STAGING LAYER COLUMN NAME': 'CUSTOMER_BK', 'STAGING LAYER DATATYPE': 'VARCHAR(50)',
                  'GHOST RECORD': '',  # blank — generator self-heals
                  'NOT NULL': '', 'HASHDIFF': '', 'PK': '', 'REMOVE COLUMN': ''},
            '3': {'STAGING LAYER COLUMN NAME': 'LOAD_DTS', 'STAGING LAYER DATATYPE': 'TIMESTAMP_NTZ',
                  'GHOST RECORD': 'load_dts', 'NOT NULL': '', 'HASHDIFF': '', 'PK': '', 'REMOVE COLUMN': ''},
        }
        block = generate_union_all_block(cols, "HUB_CUSTOMER")
        # The generator self-heal produces non-NULL emissions for HK/BK, so K6
        # has nothing to flag on the output.
        assert check_ghost_record_keys_not_null(block, HUB_PATH) == []


# ═══════════════════════════════════════════════════════════════════════════════
# L1: inner_join_has_comment
# ═══════════════════════════════════════════════════════════════════════════════

class TestL1InnerJoinHasComment:
    """L1: Non-BKCC INNER JOIN should have an inline comment."""

    def test_pass_bkcc_join_no_comment_needed(self):
        sql = "INNER JOIN FILTER_A ON '1' = '1'"
        findings = check_inner_join_has_comment(sql, VPSA_PATH)
        assert findings == []

    def test_pass_inner_join_with_comment(self):
        sql = "INNER JOIN dim_product ON a.id = b.id -- required: 1:1 match"
        findings = check_inner_join_has_comment(sql, VPSA_PATH)
        assert findings == []

    def test_warn_inner_join_no_comment(self):
        sql = "INNER JOIN dim_product ON a.product_hk = b.product_hk"
        findings = check_inner_join_has_comment(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "L1"
        assert findings[0].severity == Severity.WARN

    def test_edge_left_join_not_flagged(self):
        """LEFT JOIN is the default for lookups — no comment needed."""
        sql = "LEFT JOIN ref_table ON a.id = b.id"
        findings = check_inner_join_has_comment(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# M1: no_hardcoded_env
# ═══════════════════════════════════════════════════════════════════════════════

class TestM1NoHardcodedEnv:
    """M1: No hardcoded environment names."""

    def test_pass_env_var(self):
        sql = "WHERE env = {{ env_var('DBT_ENVIRON') }}"
        findings = check_no_hardcoded_env(sql, VPSA_PATH)
        assert findings == []

    def test_fail_hardcoded_prd(self):
        sql = "WHERE environment = 'PRD'"
        findings = check_no_hardcoded_env(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "M1"
        assert "'PRD'" in findings[0].message

    def test_edge_in_comment_ignored(self):
        sql = "-- WHERE environment = 'PRD'"
        findings = check_no_hardcoded_env(sql, VPSA_PATH)
        assert findings == []

    def test_edge_ghost_record_not_flagged(self):
        """Ghost record DECODE strings are not env names."""
        sql = """
        DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM') AS BKCC
        """
        findings = check_no_hardcoded_env(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# M2: no_select_star_outside_src
# ═══════════════════════════════════════════════════════════════════════════════

class TestM2NoSelectStarOutsideSrc:
    """M2: SELECT * only allowed in SRC/RENAME/FILTER CTEs."""

    def test_pass_select_star_in_src(self):
        sql = """
        WITH SRC_S as ( SELECT * FROM {{ source('x','y') }} )
        , LOGIC_S as ( SELECT col1, col2 FROM SRC_S )
        SELECT col1, col2 FROM LOGIC_S
        """
        findings = check_no_select_star_outside_src(sql, VPSA_PATH)
        assert findings == []

    def test_warn_select_star_in_logic(self):
        sql = """
        WITH SRC_S as ( SELECT * FROM {{ source('x','y') }} )
        , LOGIC_S as ( SELECT * FROM SRC_S )
        SELECT col1 FROM LOGIC_S
        """
        findings = check_no_select_star_outside_src(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "M2"

    def test_edge_dim_model_select_star_allowed(self):
        """dim_ models are 1:1 wrappers — SELECT * is acceptable."""
        sql = "SELECT * FROM {{ ref('pit_supplier') }}"
        findings = check_no_select_star_outside_src(sql, DIM_PATH)
        assert findings == []

    def test_edge_rename_cte_select_star_allowed(self):
        """RENAME_S uses SELECT * as passthrough — allowed in 6-layer."""
        sql = """
        WITH SRC_S as ( SELECT * FROM {{ source('x','y') }} )
        , RENAME_S as ( SELECT * FROM SRC_S )
        SELECT col1 FROM RENAME_S
        """
        findings = check_no_select_star_outside_src(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# M3: rec_src_format
# ═══════════════════════════════════════════════════════════════════════════════

class TestM3RecSrcFormat:
    """M3: REC_SRC should follow Location.System.Application.Table format."""

    def test_pass_4part_format(self):
        sql = "'USOHNO.SAP.ECCPRD.Z_LFA1' AS REC_SRC"
        findings = check_rec_src_format(sql, VPSA_PATH)
        assert findings == []

    def test_warn_too_short(self):
        sql = "'SAP' AS REC_SRC"
        findings = check_rec_src_format(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "M3"

    def test_edge_non_vpsa_path(self):
        sql = "'SAP' AS REC_SRC"
        findings = check_rec_src_format(sql, SAT_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# M4: header_comment_present
# ═══════════════════════════════════════════════════════════════════════════════

class TestM4HeaderCommentPresent:
    """M4: SQL files should have a header comment."""

    def test_pass_header_comment(self):
        sql = "---- SRC LAYER ----\nWITH SRC_S as ( SELECT * FROM t )"
        findings = check_header_comment_present(sql, VPSA_PATH)
        assert findings == []

    def test_pass_config_block(self):
        sql = "{{ config(materialized='view') }}\nSELECT * FROM t"
        findings = check_header_comment_present(sql, VPSA_PATH)
        assert findings == []

    def test_warn_no_header(self):
        sql = "WITH SRC_S as ( SELECT * FROM t )"
        findings = check_header_comment_present(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "M4"
        assert findings[0].severity == Severity.WARN

    def test_edge_dash_dash_comment(self):
        sql = "-- v_psa_stg model for supplier\nWITH SRC_S as (...)"
        findings = check_header_comment_present(sql, VPSA_PATH)
        assert findings == []
