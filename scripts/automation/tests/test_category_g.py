#!/usr/bin/env python3
"""
test_category_g.py — Tests for Category G (Naming Convention) checks.

Covers: G1 (vpsa_stg_prefix), G2 (hub_prefix), G3 (sat_prefix),
        G4 (link_prefix with CD-1 graduated enforcement),
        G5 (double_underscore_separator), G6 (column_names_uppercase)

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_category_g.py -v
"""
import sys
from pathlib import Path

import pytest

# Path setup
SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_review_config import FileStatus
from code_reviewer import (
    Severity,
    check_column_names_uppercase,
    check_double_underscore_separator,
    check_hub_prefix,
    check_link_prefix,
    check_sat_prefix,
    check_vpsa_stg_prefix,
    review_file,
)

DUMMY_SQL = "SELECT 1"


# ═══════════════════════════════════════════════════════════════════════════════
# G1: vpsa_stg_prefix
# ═══════════════════════════════════════════════════════════════════════════════

class TestG1VpsaStgPrefix:
    """G1: All SQL files in int_staging_views/ must start with v_psa_stg_."""

    def test_pass_standard_name(self):
        findings = check_vpsa_stg_prefix(
            DUMMY_SQL,
            "models/int_staging_views/bom/v_psa_stg_bom_header__winn_sap.sql",
        )
        assert findings == []

    def test_fail_wrong_prefix(self):
        findings = check_vpsa_stg_prefix(
            DUMMY_SQL,
            "models/int_staging_views/pos/v_psa_pos_sellthrough_stages__win.sql",
        )
        assert len(findings) == 1
        assert findings[0].check_id == "G1"
        assert findings[0].severity == Severity.FAIL
        assert "v_psa_stg_" in findings[0].message

    def test_skip_non_staging_path(self):
        """Files outside int_staging_views/ are not checked by G1."""
        findings = check_vpsa_stg_prefix(
            DUMMY_SQL,
            "models/raw_vault/hub/hub_supplier.sql",
        )
        assert findings == []

    def test_skip_yaml_schema_file(self):
        """YAML schema files starting with _ are not checked."""
        findings = check_vpsa_stg_prefix(
            DUMMY_SQL,
            "models/int_staging_views/bom/_v_psa_stg_bom.yml",
        )
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# G2: hub_prefix
# ═══════════════════════════════════════════════════════════════════════════════

class TestG2HubPrefix:
    """G2: All SQL files in raw_vault/hub/ must start with hub_."""

    def test_pass_standard_name(self):
        findings = check_hub_prefix(
            DUMMY_SQL,
            "models/raw_vault/hub/hub_supplier.sql",
        )
        assert findings == []

    def test_fail_wrong_prefix(self):
        findings = check_hub_prefix(
            DUMMY_SQL,
            "models/raw_vault/hub/dim_hub_customer.sql",
        )
        assert len(findings) == 1
        assert findings[0].check_id == "G2"
        assert findings[0].severity == Severity.FAIL

    def test_skip_non_hub_path(self):
        findings = check_hub_prefix(
            DUMMY_SQL,
            "models/raw_vault/sat/sat_supplier.sql",
        )
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# G3: sat_prefix
# ═══════════════════════════════════════════════════════════════════════════════

class TestG3SatPrefix:
    """G3: All SQL files in raw_vault/sat/ must use an accepted prefix."""

    @pytest.mark.parametrize("prefix", ["sat_", "lsat_", "msat_", "esat_", "lmsat_", "rsat_"])
    def test_pass_all_accepted_prefixes(self, prefix):
        findings = check_sat_prefix(
            DUMMY_SQL,
            f"models/raw_vault/sat/{prefix}foo__bar.sql",
        )
        assert findings == []

    def test_fail_wrong_prefix(self):
        findings = check_sat_prefix(
            DUMMY_SQL,
            "models/raw_vault/sat/data_satellite_customer.sql",
        )
        assert len(findings) == 1
        assert findings[0].check_id == "G3"
        assert findings[0].severity == Severity.FAIL
        assert "sat_" in findings[0].message

    def test_skip_non_sat_path(self):
        findings = check_sat_prefix(
            DUMMY_SQL,
            "models/raw_vault/hub/hub_foo.sql",
        )
        assert findings == []

    def test_pass_lmsat(self):
        """lmsat_ (link multi-active satellite) is explicitly accepted."""
        findings = check_sat_prefix(
            DUMMY_SQL,
            "models/raw_vault/sat/lmsat_item_forecast__amazon_moen_anaheim.sql",
        )
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# G4: link_prefix (CD-1 graduated enforcement)
# ═══════════════════════════════════════════════════════════════════════════════

class TestG4LinkPrefix:
    """G4: raw_vault/link/ files must use lnk_ or tlink_. link_ is graduated."""

    def test_pass_lnk_prefix(self):
        findings = check_link_prefix(
            DUMMY_SQL,
            "models/raw_vault/link/lnk_goods_movement.sql",
        )
        assert findings == []

    def test_pass_tlink_prefix(self):
        findings = check_link_prefix(
            DUMMY_SQL,
            "models/raw_vault/link/tlink_transaction.sql",
        )
        assert findings == []

    def test_new_link_file_is_fail(self):
        """CD-1: New link_ files get FAIL severity."""
        findings = check_link_prefix(
            DUMMY_SQL,
            "models/raw_vault/link/link_new_thing.sql",
            file_status=FileStatus.NEW,
        )
        assert len(findings) == 1
        assert findings[0].check_id == "G4"
        assert findings[0].severity == Severity.FAIL
        assert "lnk_" in findings[0].message

    def test_modified_link_file_is_warn(self):
        """CD-1: Modified link_ files get WARN severity (grandfathered)."""
        findings = check_link_prefix(
            DUMMY_SQL,
            "models/raw_vault/link/link_plant_item_v1.sql",
            file_status=FileStatus.MODIFIED,
        )
        assert len(findings) == 1
        assert findings[0].check_id == "G4"
        assert findings[0].severity == Severity.WARN
        assert "Legacy" in findings[0].message

    def test_fail_unknown_prefix(self):
        """Any non-link/lnk/tlink prefix is always FAIL."""
        findings = check_link_prefix(
            DUMMY_SQL,
            "models/raw_vault/link/rel_customer_order.sql",
            file_status=FileStatus.MODIFIED,
        )
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL

    def test_skip_non_link_path(self):
        findings = check_link_prefix(
            DUMMY_SQL,
            "models/raw_vault/hub/hub_foo.sql",
        )
        assert findings == []

    def test_default_file_status_is_new(self):
        """When file_status is not provided, default is NEW → link_ gets FAIL."""
        findings = check_link_prefix(
            DUMMY_SQL,
            "models/raw_vault/link/link_new.sql",
        )
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL


# ═══════════════════════════════════════════════════════════════════════════════
# G5: double_underscore_separator
# ═══════════════════════════════════════════════════════════════════════════════

class TestG5DoubleUnderscore:
    """G5: v_psa_stg model names should use entity__source pattern."""

    def test_pass_double_underscore(self):
        findings = check_double_underscore_separator(
            DUMMY_SQL,
            "models/int_staging_views/bom/v_psa_stg_bom_header__winn_sap.sql",
        )
        assert findings == []

    def test_warn_missing_separator(self):
        findings = check_double_underscore_separator(
            DUMMY_SQL,
            "models/int_staging_views/consumer_feedback/v_psa_stg_sentiment_output.sql",
        )
        assert len(findings) == 1
        assert findings[0].check_id == "G5"
        assert findings[0].severity == Severity.WARN
        assert "double-underscore" in findings[0].message

    def test_skip_non_vpsa_in_staging(self):
        """Non-v_psa_stg files in int_staging_views are skipped (G1 handles those)."""
        findings = check_double_underscore_separator(
            DUMMY_SQL,
            "models/int_staging_views/pos/v_psa_pos_sellthrough_stages__win.sql",
        )
        assert findings == []

    def test_skip_non_staging_path(self):
        findings = check_double_underscore_separator(
            DUMMY_SQL,
            "models/raw_vault/hub/hub_supplier.sql",
        )
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# G6: column_names_uppercase
# ═══════════════════════════════════════════════════════════════════════════════

class TestG6ColumnUppercase:
    """G6: Column aliases in FINAL CTE should be UPPERCASE."""

    def test_pass_uppercase_aliases(self):
        sql = """
---- SRC LAYER ----
WITH SRC AS (
    SELECT * FROM {{ source('psa', 'z_lfa1') }}
),
FINAL AS (
    SELECT
        SUPPLIER_HK AS SUPPLIER_HK,
        SUPPLIER_BK AS SUPPLIER_BK,
        LOAD_DTS AS LOAD_DTS,
        REC_SRC AS REC_SRC
    FROM SRC
)
SELECT * FROM FINAL
"""
        findings = check_column_names_uppercase(
            sql,
            "models/int_staging_views/bom/v_psa_stg_supplier__winn_sap.sql",
        )
        assert findings == []

    def test_warn_lowercase_alias(self):
        sql = """
---- SRC LAYER ----
WITH SRC AS (
    SELECT * FROM {{ source('psa', 'z_lfa1') }}
),
FINAL AS (
    SELECT
        SUPPLIER_HK AS SUPPLIER_HK,
        supplier_name AS supplier_name,
        LOAD_DTS AS LOAD_DTS
    FROM SRC
)
SELECT * FROM FINAL
"""
        findings = check_column_names_uppercase(
            sql,
            "models/int_staging_views/bom/v_psa_stg_supplier__winn_sap.sql",
        )
        assert len(findings) >= 1
        assert findings[0].check_id == "G6"
        assert findings[0].severity == Severity.WARN
        assert "supplier_name" in findings[0].message

    def test_skip_non_sql_file(self):
        findings = check_column_names_uppercase(
            "version: 2",
            "models/int_staging_views/bom/v_psa_stg_supplier__winn_sap.yml",
        )
        assert findings == []

    def test_skip_non_model_path(self):
        """Files outside model directories are not checked."""
        sql = "FINAL AS (\nSELECT foo AS bar\n)"
        findings = check_column_names_uppercase(sql, "macros/my_macro.sql")
        assert findings == []

    def test_no_final_cte_skips(self):
        """Files without a FINAL CTE are skipped (no false positives)."""
        sql = "SELECT supplier_name FROM raw_table"
        findings = check_column_names_uppercase(
            sql,
            "models/int_staging_views/bom/v_psa_stg_foo__bar.sql",
        )
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# Integration: review_file with .code_review_ignore
# ═══════════════════════════════════════════════════════════════════════════════

class TestReviewFileIgnore:
    """Verify .code_review_ignore skips Category G but not other categories."""

    def test_ignored_file_skips_naming_checks(self):
        """A file in .code_review_ignore gets zero Category G findings."""
        ignore_patterns = ["models/bus_vault/flat_logic/shipment.sql"]
        findings = review_file(
            file_path="models/bus_vault/flat_logic/shipment.sql",
            sql_content=DUMMY_SQL,
            ignore_patterns=ignore_patterns,
            category_filter="G",
        )
        assert findings == []

    def test_non_ignored_file_gets_checked(self):
        """A file NOT in .code_review_ignore gets Category G checks."""
        findings = review_file(
            file_path="models/int_staging_views/pos/v_psa_pos_bad_name.sql",
            sql_content=DUMMY_SQL,
            ignore_patterns=[],
            category_filter="G",
        )
        # G1 should fire (wrong prefix in int_staging_views)
        assert any(f.check_id == "G1" for f in findings)

    def test_glob_pattern_skips_naming(self):
        """Glob patterns in .code_review_ignore match correctly."""
        ignore_patterns = ["models/bus_vault/flat_logic/t_*.sql"]
        findings = review_file(
            file_path="models/bus_vault/flat_logic/t_temp_model.sql",
            sql_content=DUMMY_SQL,
            ignore_patterns=ignore_patterns,
            category_filter="G",
        )
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# Integration: review_file with G4 file_status
# ═══════════════════════════════════════════════════════════════════════════════

class TestReviewFileG4Integration:
    """Verify G4 link_ prefix uses file_status from review_file."""

    def test_new_link_via_review_file(self):
        findings = review_file(
            file_path="models/raw_vault/link/link_new_thing.sql",
            sql_content=DUMMY_SQL,
            file_status=FileStatus.NEW,
        )
        g4_findings = [f for f in findings if f.check_id == "G4"]
        assert len(g4_findings) == 1
        assert g4_findings[0].severity == Severity.FAIL

    def test_modified_link_via_review_file(self):
        findings = review_file(
            file_path="models/raw_vault/link/link_plant_item_v1.sql",
            sql_content=DUMMY_SQL,
            file_status=FileStatus.MODIFIED,
        )
        g4_findings = [f for f in findings if f.check_id == "G4"]
        assert len(g4_findings) == 1
        assert g4_findings[0].severity == Severity.WARN
