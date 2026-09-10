#!/usr/bin/env python3
"""
test_category_h10_h11_n1_e1.py — Tests for the H10, H11 additions and N1, E1
modifications landed alongside the layer-aware Category I work.

Coverage:
  H10 (check_grain_excludes_metadata):
    - HASHDIFF in PK → FAIL
    - PSA_DELETE_IND in unique_combination → FAIL
    - clean parent_HK-only PK → PASS
    - HK + valid child key → PASS
  H11 (check_sat_has_foreign_key):
    - sat_ YAML with a foreign_key → PASS
    - sat_ YAML with no foreign_key → FAIL
    - hub_ YAML (out of scope) → no finding
  N1 (check_no_delete_flag_filter, DV-EXCEPTION downgrade):
    - WHERE PSA_DELETE_IND='N' no comment → FAIL
    - with `-- DV-EXCEPTION: <reason>` → WARN
    - with bare `-- needed` → still FAIL
    - with `-- DV-EXCEPTION:` (no reason) → still FAIL
  E1 (check_no_select_distinct, path-scoped severity):
    - SELECT DISTINCT in v_psa_stg → FAIL
    - SELECT DISTINCT in raw_vault/sat → FAIL
    - SELECT DISTINCT in bus_vault/pb → WARN

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_category_h10_h11_n1_e1.py -v
"""
import sys
from pathlib import Path

import pytest

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_review_config import FileStatus  # noqa: E402
from code_reviewer import (  # noqa: E402
    Severity,
    check_grain_excludes_metadata,
    check_sat_has_foreign_key,
    check_no_delete_flag_filter,
    check_no_select_distinct,
)


SAT_YAML_PATH = "models/raw_vault/sat/_model_yml/sat_foo__src.yml"
HUB_YAML_PATH = "models/raw_vault/hub/_model_yml/hub_foo.yml"
STG_PATH = "models/int_staging_views/foo/v_psa_stg_foo__src.sql"
SAT_SQL_PATH = "models/raw_vault/sat/sat_foo__src.sql"
PB_PATH = "models/bus_vault/pit_bridge/pb_foo.sql"


# ══════════════════════════════════════════════════════════════════════════
# H10 — grain_excludes_metadata
# ══════════════════════════════════════════════════════════════════════════

class TestH10GrainExcludesMetadata:
    def test_canonical_sat_grain_parent_hk_load_dts_passes(self):
        """THE canonical DV 2.0 satellite grain. Must NEVER FAIL.

        Per spec correction 2026-06-22: LOAD_DTS is REQUIRED in sat PK
        (one row per key per load). Separately excluded from HASHDIFF (B4)
        for a different reason — different rule, different column treatment.
        """
        yaml = """\
version: 2
models:
- name: sat_foo__src
  data_tests:
  - dbt_constraints.primary_key:
      column_names:
        - FOO_HK
        - LOAD_DTS
"""
        findings = check_grain_excludes_metadata("", SAT_YAML_PATH, yaml_content=yaml)
        assert findings == [], (
            "Canonical satellite grain (parent_HK, LOAD_DTS) must PASS — "
            "this is the DV 2.0 standard. Any FAIL here is a spec bug. "
            f"Got: {findings}"
        )

    def test_hashdiff_in_pk_fails(self):
        yaml = """\
version: 2
models:
- name: sat_foo__src
  data_tests:
  - dbt_constraints.primary_key:
      column_names:
        - FOO_HK
        - LOAD_DTS
        - HASHDIFF
"""
        findings = check_grain_excludes_metadata("", SAT_YAML_PATH, yaml_content=yaml)
        # LOAD_DTS is allowed (canonical grain). Only HASHDIFF fails.
        assert len(findings) == 1, (
            f"Only HASHDIFF should fail (LOAD_DTS is canonical sat grain). "
            f"Got: {[f.message for f in findings]}"
        )
        f = findings[0]
        assert f.check_id == "H10"
        assert f.severity == Severity.FAIL
        assert "HASHDIFF" in f.message
        # Defensive: ensure LOAD_DTS is NOT in any message (regression guard)
        assert all("LOAD_DTS" not in f.message for f in findings), (
            "LOAD_DTS must never appear in H10 findings — it's canonical sat grain."
        )

    def test_psa_delete_ind_in_unique_combination_fails(self):
        yaml = """\
version: 2
models:
- name: sat_bar__src
  data_tests:
  - dbt_utils.unique_combination_of_columns:
      combination_of_columns:
        - BAR_HK
        - PSA_DELETE_IND
"""
        findings = check_grain_excludes_metadata("", SAT_YAML_PATH, yaml_content=yaml)
        assert len(findings) == 1
        assert findings[0].check_id == "H10"
        assert findings[0].severity == Severity.FAIL
        assert "PSA_DELETE_IND" in findings[0].message
        assert "sat_bar__src" in findings[0].message

    def test_clean_hk_only_pk_passes(self):
        yaml = """\
version: 2
models:
- name: sat_baz__src
  data_tests:
  - dbt_constraints.primary_key:
      column_names:
        - BAZ_HK
"""
        findings = check_grain_excludes_metadata("", SAT_YAML_PATH, yaml_content=yaml)
        assert findings == []

    def test_hk_plus_child_key_passes(self):
        """msat-style grain: parent_HK + child_key (no LOAD_DTS — that's for
        the underlying load-time uniqueness, not the grain test)."""
        yaml = """\
version: 2
models:
- name: msat_qux__src
  data_tests:
  - dbt_constraints.primary_key:
      column_names:
        - QUX_HK
        - LINE_NUM
"""
        findings = check_grain_excludes_metadata("", SAT_YAML_PATH, yaml_content=yaml)
        assert findings == []

    def test_pit_style_grain_with_load_dts_passes(self):
        """Spec correction 2026-06-22: LOAD_DTS in a PK is correct, not a
        violation — it's the canonical DV 2.0 grain. PIT/PB models with
        (parent_HK, LOAD_DTS) PKs are declaring grain correctly.
        """
        yaml = """\
version: 2
models:
- name: pit_customer
  data_tests:
  - dbt_constraints.primary_key:
      column_names:
        - CUSTOMER_HK
        - LOAD_DTS
"""
        findings = check_grain_excludes_metadata("", SAT_YAML_PATH, yaml_content=yaml)
        assert findings == [], (
            f"PIT-style (parent_HK, LOAD_DTS) grain must PASS. Got: {findings}"
        )

    def test_no_yaml_returns_empty(self):
        assert check_grain_excludes_metadata("", SAT_YAML_PATH, yaml_content=None) == []

    def test_no_pk_tests_returns_empty(self):
        yaml = "version: 2\nmodels:\n- name: foo\n"
        assert check_grain_excludes_metadata("", SAT_YAML_PATH, yaml_content=yaml) == []

    def test_columns_block_does_not_mis_associate_grain_to_column_name(self):
        """REGRESSION GUARD (PR #1827 review R-parser): the shared parser
        ``_parse_pk_unique_column_lists`` originally treated any ``- name:``
        at indent <= 4 as a model boundary. But FBIN's YAML convention puts
        column items inside a ``columns:`` block at indent 2 — same level
        as the model's other keys (data_tests, columns, etc.).

        Without the in-columns-block guard, ``- name: STORE_HK`` (a column
        entry) would overwrite ``in_model``, and any LATER grain test list
        would be mis-attributed to a column name instead of the model name.
        On the grandfather list, a mis-keyed entry means the wrong file
        gets grandfathered and the right file's violation FAILs unexpectedly.

        To force the bug to actually leak into a finding, the YAML below
        puts ``columns:`` BEFORE ``data_tests:`` — so the corrupted
        ``in_model`` (= last column name) is what's live when the grain
        list is parsed. (In FBIN's actual convention data_tests comes
        first, which is why the bug was latent in the cited file's exact
        layout; this test exercises the reorder-tolerant path.)

        Reference: structure derived from the column-block layout in
        ``models/raw_vault/sat/_model_yml/sat_inventory__homedepot_ft.yml``
        (columns at indent 2, ``- name: COL`` items at indent 2).
        """
        yaml_content = """\
version: 2
models:
- name: sat_xyz
  columns:
  - name: STORE_HK
    data_tests:
    - not_null:
        config:
          severity: warn
  - name: D_STORE_NBR
    data_tests:
    - not_null:
        config:
          severity: warn
  data_tests:
  - dbt_constraints.primary_key:
      arguments:
        column_names:
        - PARENT_HK
        - HASHDIFF
        - LOAD_DTS
"""
        findings = check_grain_excludes_metadata(
            "", SAT_YAML_PATH, yaml_content=yaml_content,
        )
        # The H10 violation we expect: HASHDIFF in the grain.
        assert len(findings) == 1, (
            f"Expected exactly one H10 finding (HASHDIFF in sat_xyz's PK). "
            f"Got: {findings}"
        )
        f = findings[0]
        assert f.check_id == "H10"
        assert "HASHDIFF" in f.message
        # The critical assertion: model name must be 'sat_xyz', NOT one of
        # the column names that the bug would have overwritten in_model with.
        assert "sat_xyz" in f.message, (
            f"Mis-association bug: grain finding attributed to wrong model. "
            f"Expected 'sat_xyz' in message, got: {f.message}"
        )
        # The two column names that would have leaked through the bug:
        for col_name in ("STORE_HK", "D_STORE_NBR"):
            assert f"Grain test for {col_name}" not in f.message, (
                f"Mis-association bug: column name '{col_name}' leaked into "
                f"model name slot. Got: {f.message}"
            )


# ══════════════════════════════════════════════════════════════════════════
# H11 — sat_has_foreign_key
# ══════════════════════════════════════════════════════════════════════════

class TestH11SatHasForeignKey:
    def test_sat_with_foreign_key_passes(self):
        yaml = """\
version: 2
models:
- name: sat_foo__src
  columns:
  - name: FOO_HK
    data_tests:
    - dbt_constraints.foreign_key:
        pk_table_name: ref('hub_foo')
        pk_column_name: FOO_HK
"""
        findings = check_sat_has_foreign_key("", SAT_YAML_PATH, yaml_content=yaml)
        assert findings == []

    def test_sat_with_no_foreign_key_fails(self):
        yaml = """\
version: 2
models:
- name: sat_orphan__src
  data_tests:
  - dbt_constraints.primary_key:
      column_names:
        - ORPHAN_HK
"""
        findings = check_sat_has_foreign_key("", SAT_YAML_PATH, yaml_content=yaml)
        assert len(findings) == 1
        assert findings[0].check_id == "H11"
        assert findings[0].severity == Severity.FAIL
        assert "sat_orphan__src" in findings[0].message
        assert "no foreign_key" in findings[0].message

    def test_hub_yaml_out_of_scope_no_finding(self):
        yaml = """\
version: 2
models:
- name: hub_customer
  data_tests:
  - dbt_constraints.primary_key:
      column_names:
        - CUSTOMER_HK
"""
        findings = check_sat_has_foreign_key("", HUB_YAML_PATH, yaml_content=yaml)
        assert findings == []

    def test_lsat_in_sat_dir_with_no_fk_fails(self):
        """lsat_ models also satellites — they must have FK back to their link."""
        yaml = """\
version: 2
models:
- name: lsat_orderline_promo__src
  data_tests:
  - dbt_constraints.primary_key:
      column_names:
        - LNK_ORDERLINE_PROMO_HK
"""
        findings = check_sat_has_foreign_key("", SAT_YAML_PATH, yaml_content=yaml)
        assert len(findings) == 1
        assert "lsat_orderline_promo__src" in findings[0].message

    def test_multiple_sats_in_one_yaml_only_one_missing_fk(self):
        yaml = """\
version: 2
models:
- name: sat_with_fk__src
  columns:
  - name: WITH_FK_HK
    data_tests:
    - dbt_constraints.foreign_key:
        pk_table_name: ref('hub_with')
        pk_column_name: WITH_FK_HK
- name: sat_without_fk__src
  data_tests:
  - dbt_constraints.primary_key:
      column_names:
        - WITHOUT_FK_HK
"""
        findings = check_sat_has_foreign_key("", SAT_YAML_PATH, yaml_content=yaml)
        assert len(findings) == 1
        assert "sat_without_fk__src" in findings[0].message

    def test_non_yaml_skipped(self):
        assert check_sat_has_foreign_key("", SAT_YAML_PATH, yaml_content=None) == []

    def test_yaml_outside_sat_dir_skipped(self):
        yaml = "version: 2\nmodels:\n- name: sat_foo\n"
        findings = check_sat_has_foreign_key("", "models/bus_vault/sat_lookalike.yml", yaml_content=yaml)
        assert findings == []


# ══════════════════════════════════════════════════════════════════════════
# N1 — DV-EXCEPTION downgrade
# ══════════════════════════════════════════════════════════════════════════

class TestN1DvExceptionDowngrade:
    def test_filter_no_comment_fails(self):
        sql = "SELECT * FROM SRC_S WHERE PSA_DELETE_IND = 'N'"
        findings = check_no_delete_flag_filter(sql, STG_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "N1"
        assert findings[0].severity == Severity.FAIL

    def test_filter_with_dv_exception_downgrades_to_warn(self):
        sql = (
            "SELECT * FROM SRC_S\n"
            "-- DV-EXCEPTION: truncate-reload artifact, retained via HASHDIFF\n"
            "WHERE PSA_DELETE_IND = 'N'\n"
        )
        findings = check_no_delete_flag_filter(sql, STG_PATH)
        assert len(findings) == 1
        assert findings[0].severity == Severity.WARN
        assert "DV-EXCEPTION" in findings[0].message
        assert "preserved in history" in findings[0].message

    def test_filter_with_dv_exception_on_same_line_warns(self):
        sql = (
            "SELECT * FROM SRC_S\n"
            "WHERE PSA_DELETE_IND = 'N'  -- DV-EXCEPTION: legacy migration cutoff\n"
        )
        findings = check_no_delete_flag_filter(sql, STG_PATH)
        assert len(findings) == 1
        assert findings[0].severity == Severity.WARN

    def test_filter_with_dv_exception_below_line_warns(self):
        sql = (
            "SELECT * FROM SRC_S\n"
            "WHERE PSA_DELETE_IND = 'N'\n"
            "-- DV-EXCEPTION: source upstream guarantees no deletes\n"
        )
        findings = check_no_delete_flag_filter(sql, STG_PATH)
        assert len(findings) == 1
        assert findings[0].severity == Severity.WARN

    def test_bare_comment_does_not_downgrade(self):
        sql = (
            "SELECT * FROM SRC_S\n"
            "-- needed\n"
            "WHERE PSA_DELETE_IND = 'N'\n"
        )
        findings = check_no_delete_flag_filter(sql, STG_PATH)
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL

    def test_dv_exception_without_reason_does_not_downgrade(self):
        sql = (
            "SELECT * FROM SRC_S\n"
            "-- DV-EXCEPTION:\n"
            "WHERE PSA_DELETE_IND = 'N'\n"
        )
        findings = check_no_delete_flag_filter(sql, STG_PATH)
        assert len(findings) == 1, f"Expected 1 finding, got {findings}"
        assert findings[0].severity == Severity.FAIL, (
            f"Bare 'DV-EXCEPTION:' with no reason must NOT downgrade. "
            f"Got {findings[0].severity}"
        )

    def test_dv_exception_no_colon_does_not_downgrade(self):
        sql = (
            "SELECT * FROM SRC_S\n"
            "-- DV-EXCEPTION something\n"
            "WHERE PSA_DELETE_IND = 'N'\n"
        )
        findings = check_no_delete_flag_filter(sql, STG_PATH)
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL

    def test_and_clause_also_downgrades(self):
        """N1's WHERE_RE and AND_RE both match a WHERE...AND...flag construct
        (pre-existing behavior — duplicate findings on the same flag). The
        DV-EXCEPTION downgrade must apply to BOTH so a single marker covers
        the whole filter chain.
        """
        sql = (
            "SELECT * FROM SRC_S\n"
            "WHERE 1=1\n"
            "  AND _FIVETRAN_DELETED = FALSE  -- DV-EXCEPTION: cdc source guarantees soft-delete handling\n"
        )
        findings = check_no_delete_flag_filter(sql, STG_PATH)
        # Two matches (WHERE_RE + AND_RE) both downgraded
        assert len(findings) == 2, f"Expected 2 findings (WHERE+AND both match), got {len(findings)}"
        assert all(f.severity == Severity.WARN for f in findings), (
            f"All findings must be downgraded to WARN. Got: "
            f"{[f.severity for f in findings]}"
        )


# ══════════════════════════════════════════════════════════════════════════
# E1 — path-scoped severity
# ══════════════════════════════════════════════════════════════════════════

class TestE1PathScopedSeverity:
    def test_select_distinct_in_vpsa_stg_fails(self):
        sql = "SELECT DISTINCT customer_id, order_id FROM SRC_S"
        findings = check_no_select_distinct(sql, STG_PATH)
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL

    def test_select_distinct_in_raw_vault_sat_fails(self):
        sql = "SELECT DISTINCT customer_id, order_id FROM SRC_S"
        findings = check_no_select_distinct(sql, SAT_SQL_PATH)
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL

    def test_select_distinct_in_bus_vault_warns(self):
        sql = "SELECT DISTINCT customer_id, install_date FROM joined_data"
        findings = check_no_select_distinct(sql, PB_PATH)
        assert len(findings) == 1
        assert findings[0].severity == Severity.WARN
        assert "BV" in findings[0].message
        assert "QUALIFY" in findings[0].message

    def test_select_distinct_in_info_mart_fails(self):
        """info_mart is NOT bus_vault — should still FAIL."""
        sql = "SELECT DISTINCT customer_id FROM joined_data"
        findings = check_no_select_distinct(
            sql, "models/info_mart/sales/fact_orders.sql"
        )
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL

    def test_select_distinct_in_comment_still_skipped(self):
        sql = "-- SELECT DISTINCT was used here\nSELECT * FROM SRC_S"
        findings = check_no_select_distinct(sql, PB_PATH)
        assert findings == []
