"""
test_hub_generation.py — Tests for hub model generation pipeline.

Validates:
- _build_hub_yaml_model produces correct YAML structure
- _derive_hub_name naming conventions
- Hub XLSX → SQL code generation (end-to-end)
- make_yml produces dbt_constraints.primary_key for hubs
- extract_bk_columns_for_hub_qualify returns correct columns
"""

import sys
import tempfile
from pathlib import Path

import pytest
import yaml

# Add parent dirs so we can import the modules under test
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from pipeline_orchestrator import _derive_hub_name, _build_hub_yaml_model, HUB_WATERMARK_THRESHOLD, HUB_FULL_REFRESH_THRESHOLD
from generate_tech_spec import TechSpecBuilder
from build import extract_bk_columns_for_hub_qualify
from make_yml import make_yml


# ---------------------------------------------------------------------------
# _derive_hub_name tests
# ---------------------------------------------------------------------------

class TestDeriveHubName:

    def test_simple_bk(self):
        assert _derive_hub_name("PO_ITEM_BK") == "hub_po_item"

    def test_composite_bk_name(self):
        assert _derive_hub_name("PRODUCT_COST_ESTIMATE_BK") == "hub_product_cost_estimate"

    def test_lowercase_input(self):
        assert _derive_hub_name("customer_bk") == "hub_customer"

    def test_no_bk_suffix(self):
        """BK name without _BK suffix is passed verbatim (lowered)."""
        assert _derive_hub_name("CUSTOMER") == "hub_customer"


# ---------------------------------------------------------------------------
# _build_hub_yaml_model tests
# ---------------------------------------------------------------------------

class TestBuildHubYamlModel:

    @pytest.fixture
    def state(self):
        return {
            "model_name": "v_psa_stg_product_cost_estimate__moen_sap",
            "schema": "moen_sap",
            "table": "cost_estimate_header",
            "bk": "MATNR, WERKS, POPER, BDATJ, KLVAR",
            "bk_name": "PRODUCT_COST_ESTIMATE_BK",
            "rec_src": "USWIOC.SAP.MOEN.COST_ESTIMATE_HEADER",
        }

    @pytest.fixture
    def profile(self):
        return {
            "ingestion_source": "snp_glue",
            "columns": [
                {"name": "MATNR", "type": "VARCHAR", "nullable": "YES"},
                {"name": "WERKS", "type": "VARCHAR", "nullable": "YES"},
                {"name": "POPER", "type": "VARCHAR", "nullable": "YES"},
                {"name": "BDATJ", "type": "VARCHAR", "nullable": "YES"},
                {"name": "KLVAR", "type": "VARCHAR", "nullable": "YES"},
            ],
            "row_count": 95_000_000,
        }

    def test_hub_model_structure(self, state, profile):
        bk_raw_cols = ["MATNR", "WERKS", "POPER", "BDATJ", "KLVAR"]
        model = _build_hub_yaml_model(state, profile, bk_raw_cols, "PRODUCT_COST_ESTIMATE_BK", 95_000_000)

        assert model["layer"] == "HUB"
        assert model["derived_name"] == "hub_product_cost_estimate"
        assert model["short_name"] == "PRODUCT_COST_ESTIMATE"

    def test_hub_reads_individual_bk_columns(self, state, profile):
        """Hub should have individual BK columns, NOT a concatenated alias."""
        bk_raw_cols = ["MATNR", "WERKS", "POPER", "BDATJ", "KLVAR"]
        model = _build_hub_yaml_model(state, profile, bk_raw_cols, "PRODUCT_COST_ESTIMATE_BK", 95_000_000)

        col_names = [c["staging_column_name"] for c in model["columns"]]
        # Individual BK columns present
        for bk in bk_raw_cols:
            assert bk in col_names, f"BK column {bk} missing from hub"
        # Concatenated alias NOT present
        assert "PRODUCT_COST_ESTIMATE_BK" not in col_names
        # HK is first column
        assert col_names[0] == "PRODUCT_COST_ESTIMATE_HK"

    def test_hub_hk_is_read_not_derived(self, state, profile):
        """Hub HK should be read from v_psa_stg, NOT recomputed as a HASH."""
        bk_raw_cols = ["MATNR", "WERKS", "POPER", "BDATJ", "KLVAR"]
        model = _build_hub_yaml_model(state, profile, bk_raw_cols, "PRODUCT_COST_ESTIMATE_BK", 95_000_000)

        hk_col = next(c for c in model["columns"] if c["staging_column_name"] == "PRODUCT_COST_ESTIMATE_HK")
        # HK is a regular column read from source, not derived
        assert hk_col["source_column"] == "PRODUCT_COST_ESTIMATE_HK"
        assert hk_col["source_table"] == "SRC"
        assert "manual_logic" not in hk_col  # NOT a HASH expression
        assert hk_col["ghost_record"] == "hash"
        assert hk_col["pk"] == "PK: PRODUCT_COST_ESTIMATE_HK"

    def test_hub_no_hashdiff(self, state, profile):
        bk_raw_cols = ["MATNR", "WERKS", "POPER", "BDATJ", "KLVAR"]
        model = _build_hub_yaml_model(state, profile, bk_raw_cols, "PRODUCT_COST_ESTIMATE_BK", 95_000_000)

        col_names = [c["staging_column_name"] for c in model["columns"]]
        assert "HASHDIFF" not in col_names

    def test_hub_no_psa_columns(self, state, profile):
        """Hub should NOT have PSA_LOAD_DTS or PSA_DELETE_IND."""
        bk_raw_cols = ["MATNR", "WERKS", "POPER", "BDATJ", "KLVAR"]
        model = _build_hub_yaml_model(state, profile, bk_raw_cols, "PRODUCT_COST_ESTIMATE_BK", 95_000_000)

        col_names = [c["staging_column_name"] for c in model["columns"]]
        assert "PSA_LOAD_DTS" not in col_names
        assert "PSA_DELETE_IND" not in col_names

    def test_hub_column_order(self, state, profile):
        """Hub columns: HK, BK cols, LOAD_DTS, BKCC, REC_SRC."""
        bk_raw_cols = ["MATNR", "WERKS", "POPER", "BDATJ", "KLVAR"]
        model = _build_hub_yaml_model(state, profile, bk_raw_cols, "PRODUCT_COST_ESTIMATE_BK", 95_000_000)

        col_names = [c["staging_column_name"] for c in model["columns"]]
        expected = ["PRODUCT_COST_ESTIMATE_HK", "MATNR", "WERKS", "POPER", "BDATJ", "KLVAR",
                    "LOAD_DTS", "BKCC", "REC_SRC"]
        assert col_names == expected

    def test_hub_has_bkcc_load_dts_rec_src(self, state, profile):
        bk_raw_cols = ["MATNR", "WERKS", "POPER", "BDATJ", "KLVAR"]
        model = _build_hub_yaml_model(state, profile, bk_raw_cols, "PRODUCT_COST_ESTIMATE_BK", 95_000_000)

        col_names = [c["staging_column_name"] for c in model["columns"]]
        assert "BKCC" in col_names
        assert "LOAD_DTS" in col_names
        assert "REC_SRC" in col_names

    def test_hub_ghost_records(self, state, profile):
        bk_raw_cols = ["MATNR", "WERKS", "POPER", "BDATJ", "KLVAR"]
        model = _build_hub_yaml_model(state, profile, bk_raw_cols, "PRODUCT_COST_ESTIMATE_BK", 95_000_000)

        ghost_map = {c["staging_column_name"]: c.get("ghost_record", "") for c in model["columns"]}
        assert ghost_map["MATNR"] == "value_text"
        assert ghost_map["BKCC"] == "bkcc"
        assert ghost_map["LOAD_DTS"] == "load_dts"
        assert ghost_map["REC_SRC"] == "rec_src"
        assert ghost_map["PRODUCT_COST_ESTIMATE_HK"] == "hash"

    def test_hub_final_layer_filter(self, state, profile):
        bk_raw_cols = ["MATNR", "WERKS", "POPER", "BDATJ", "KLVAR"]
        model = _build_hub_yaml_model(state, profile, bk_raw_cols, "PRODUCT_COST_ESTIMATE_BK", 95_000_000)

        final_filter = model["sources"][0]["final_layer_filter"]
        assert "NOT EXISTS" in final_filter
        assert "PRODUCT_COST_ESTIMATE_HK" in final_filter
        assert "MATNR, WERKS, POPER, BDATJ, KLVAR, BKCC" in final_filter
        assert "qualify" in final_filter.lower()

    def test_hub_watermark_threshold(self, state, profile):
        """Hub >=50M rows: model_config empty (tags in YAML). >=150M: full_refresh."""
        bk_raw_cols = ["MATNR"]

        # 30M — no watermark, no full_refresh
        model_30m = _build_hub_yaml_model(state, profile, bk_raw_cols, "TEST_BK", 30_000_000)
        assert model_30m["sources"][0]["model_config"] == ""

        # 95M — watermark, but model_config empty (tags go in YAML only)
        model_95m = _build_hub_yaml_model(state, profile, bk_raw_cols, "TEST_BK", 95_000_000)
        assert model_95m["sources"][0]["model_config"] == ""

        # 200M — watermark + full_refresh
        model_200m = _build_hub_yaml_model(state, profile, bk_raw_cols, "TEST_BK", 200_000_000)
        assert 'full_refresh = var("force_full_refresh", false)' in model_200m["sources"][0]["model_config"]
        assert "large_volume" in model_200m["sources"][0]["model_config"]

    def test_hub_qualify_order_by(self, state, profile):
        """Hub always uses LOAD_DTS for qualify_order_by (reads from staging, not PSA). Lesson #61."""
        bk_raw_cols = ["MATNR"]

        # snp_glue → still LOAD_DTS (hub reads from v_psa_stg which exposes LOAD_DTS)
        model = _build_hub_yaml_model(state, profile, bk_raw_cols, "TEST_BK", 95_000_000)
        assert model["sources"][0]["qualify_order_by"] == "LOAD_DTS"

        # fivetran → still LOAD_DTS
        profile_ft = {**profile, "ingestion_source": "fivetran"}
        model_ft = _build_hub_yaml_model(state, profile_ft, bk_raw_cols, "TEST_BK", 95_000_000)
        assert model_ft["sources"][0]["qualify_order_by"] == "LOAD_DTS"

    def test_hub_source_uses_ref(self, state, profile):
        """Hub source should reference v_psa_stg via int_staging_views."""
        bk_raw_cols = ["MATNR"]
        model = _build_hub_yaml_model(state, profile, bk_raw_cols, "TEST_BK", 10_000_000)

        src = model["sources"][0]
        assert src["source_schema"] == "int_staging_views"
        assert src["source_table"] == "v_psa_stg_product_cost_estimate__moen_sap"


# ---------------------------------------------------------------------------
# extract_bk_columns_for_hub_qualify tests
# ---------------------------------------------------------------------------

class TestExtractBKColumnsForHubQualify:

    def test_single_bk(self):
        columns = {
            0: {"STAGING LAYER COLUMN NAME": "MATNR", "GHOST RECORD": "value_text"},
            1: {"STAGING LAYER COLUMN NAME": "BKCC", "GHOST RECORD": "bkcc"},
            2: {"STAGING LAYER COLUMN NAME": "LOAD_DTS", "GHOST RECORD": "load_dts"},
            3: {"STAGING LAYER COLUMN NAME": "REC_SRC", "GHOST RECORD": "rec_src"},
            4: {"STAGING LAYER COLUMN NAME": "TEST_HK", "GHOST RECORD": "hash"},
        }
        result = extract_bk_columns_for_hub_qualify(columns)
        assert result == ["MATNR", "BKCC"]

    def test_multi_bk(self):
        columns = {
            0: {"STAGING LAYER COLUMN NAME": "MATNR", "GHOST RECORD": "value_text"},
            1: {"STAGING LAYER COLUMN NAME": "WERKS", "GHOST RECORD": "value_text"},
            2: {"STAGING LAYER COLUMN NAME": "POPER", "GHOST RECORD": "value_text"},
            3: {"STAGING LAYER COLUMN NAME": "BKCC", "GHOST RECORD": "bkcc"},
            4: {"STAGING LAYER COLUMN NAME": "LOAD_DTS", "GHOST RECORD": "load_dts"},
        }
        result = extract_bk_columns_for_hub_qualify(columns)
        assert result == ["MATNR", "WERKS", "POPER", "BKCC"]

    def test_excludes_non_bk(self):
        columns = {
            0: {"STAGING LAYER COLUMN NAME": "ID_COL", "GHOST RECORD": "value_text"},
            1: {"STAGING LAYER COLUMN NAME": "LOAD_DTS", "GHOST RECORD": "load_dts"},
            2: {"STAGING LAYER COLUMN NAME": "REC_SRC", "GHOST RECORD": "rec_src"},
            3: {"STAGING LAYER COLUMN NAME": "MY_HK", "GHOST RECORD": "hash"},
            4: {"STAGING LAYER COLUMN NAME": "BKCC", "GHOST RECORD": "bkcc"},
        }
        result = extract_bk_columns_for_hub_qualify(columns)
        assert "LOAD_DTS" not in result
        assert "REC_SRC" not in result
        assert "MY_HK" not in result


# ---------------------------------------------------------------------------
# make_yml hub tests
# ---------------------------------------------------------------------------

class TestMakeYmlHub:

    def test_hub_has_primary_key_test(self):
        """make_yml should add dbt_constraints.primary_key for hub models."""
        tables = {
            "v_psa_stg_test": [{
                "DERIVED_NAME": "hub_test_entity",
                "SOURCE TABLE": "v_psa_stg_test",
                "ALIAS": "SRC",
            }]
        }
        columns = {
            0: {
                "STAGING LAYER COLUMN NAME": "COL_A",
                "SOURCE COLUMN": "COL_A",
                "GHOST RECORD": "value_text",
                "PK": "",
                "UNIQUE": "",
                "NOT NULL": "",
                "HASHDIFF": "",
            },
            1: {
                "STAGING LAYER COLUMN NAME": "TEST_ENTITY_HK",
                "SOURCE COLUMN": "(DERIVED)",
                "GHOST RECORD": "hash",
                "PK": "PK: TEST_ENTITY_HK",
                "UNIQUE": "",
                "NOT NULL": "",
                "HASHDIFF": "",
            },
        }
        yml = make_yml("HUB_TEST_ENTITY", tables, columns)

        # Check dbt_constraints.primary_key is present
        model_tests = yml["models"][0]["data_tests"]
        pk_tests = [t for t in model_tests if isinstance(t, dict) and "dbt_constraints.primary_key" in t]
        assert len(pk_tests) == 1, f"Expected 1 PK test, got: {model_tests}"
        pk_test = pk_tests[0]["dbt_constraints.primary_key"]
        assert pk_test["arguments"]["column_names"] == ["TEST_ENTITY_HK"]
        # PK severity should be warn for hubs
        assert pk_test.get("config", {}).get("severity") == "warn"

    def test_hub_has_row_count_test(self):
        """make_yml should add expect_table_row_count for hub models."""
        tables = {
            "v_psa_stg_test": [{
                "DERIVED_NAME": "hub_test_entity",
                "SOURCE TABLE": "v_psa_stg_test",
                "ALIAS": "SRC",
            }]
        }
        columns = {
            0: {
                "STAGING LAYER COLUMN NAME": "TEST_ENTITY_HK",
                "SOURCE COLUMN": "(DERIVED)",
                "GHOST RECORD": "hash",
                "PK": "PK: TEST_ENTITY_HK",
                "UNIQUE": "",
                "NOT NULL": "",
                "HASHDIFF": "",
            },
        }
        yml = make_yml("HUB_TEST_ENTITY", tables, columns)

        model_tests = yml["models"][0]["data_tests"]
        row_count_tests = [
            t for t in model_tests
            if isinstance(t, dict) and "dbt_expectations.expect_table_row_count_to_be_between" in t
        ]
        assert len(row_count_tests) == 1


# ---------------------------------------------------------------------------
# make_yml — model-level test name safety-net (regression for PR #1771 review)
# ---------------------------------------------------------------------------

class TestMakeYmlNameSafetyNet:
    """Every model-level test produced by make_yml must carry an explicit
    ``name:`` key. Without it, dbt's partial-parse cache can register two
    distinct tests under the same auto-generated identifier and abort the
    parse (issue that hotfix #1770 patched manually). The safety-net loop
    in ``make_yml`` is the long-term guard. These tests prove it covers
    EVERY model-level test type emitted by ``get_model_tests``, not just
    primary_key / rowcount / grain.
    """

    def _columns_with_pk(self):
        return {
            0: {
                "STAGING LAYER COLUMN NAME": "TEST_HK",
                "SOURCE COLUMN": "(DERIVED)",
                "GHOST RECORD": "hash",
                "PK": "PK: TEST_HK",
                "UNIQUE": "",
                "NOT NULL": "",
                "HASHDIFF": "",
            },
        }

    def _all_model_tests_have_name(self, yml):
        """Helper: assert every model-level test entry has an explicit name."""
        model_tests = yml["models"][0]["data_tests"]
        missing = []
        for entry in model_tests:
            if not isinstance(entry, dict):
                continue
            for test_key, test_props in entry.items():
                if not isinstance(test_props, dict):
                    continue
                if "name" not in test_props:
                    missing.append(test_key)
        return missing

    def test_equality_test_gets_explicit_name(self):
        """``dbt_utils.equality`` (MODEL EQUALITY) must get an explicit name."""
        tables = {
            "v_psa_stg_test": [{
                "DERIVED_NAME": "hub_test_entity",
                "SOURCE TABLE": "v_psa_stg_test",
                "ALIAS": "SRC",
            }]
        }
        columns = self._columns_with_pk()
        # Inject a MODEL EQUALITY into the PK row so get_model_tests fires it.
        columns[0]["MODEL EQUALITY"] = "TEST_HK"

        yml = make_yml("HUB_TEST_ENTITY", tables, columns)
        missing = self._all_model_tests_have_name(yml)
        assert missing == [], (
            f"Model-level tests missing explicit name (regression of PR #1771 "
            f"comment #7): {missing}"
        )
        # And the equality test specifically has a sensible derived name.
        model_tests = yml["models"][0]["data_tests"]
        eq_tests = [
            t for t in model_tests
            if isinstance(t, dict) and "dbt_utils.equality" in t
        ]
        assert eq_tests, "equality test should have been emitted"
        eq_name = eq_tests[0]["dbt_utils.equality"]["name"]
        assert "equality" in eq_name.lower()
        assert "hub_test_entity" in eq_name.lower()

    def test_equal_rowcount_test_gets_explicit_name(self):
        """``dbt_utils.equal_rowcount`` (MODEL EQUAL ROWCOUNT) must get a name."""
        tables = {
            "v_psa_stg_test": [{
                "DERIVED_NAME": "hub_test_entity",
                "SOURCE TABLE": "v_psa_stg_test",
                "ALIAS": "SRC",
            }]
        }
        columns = self._columns_with_pk()
        columns[0]["MODEL EQUAL ROWCOUNT"] = "ref_compare_model"

        yml = make_yml("HUB_TEST_ENTITY", tables, columns)
        missing = self._all_model_tests_have_name(yml)
        assert missing == [], (
            f"Model-level tests missing explicit name (regression of PR #1771 "
            f"comment #7): {missing}"
        )

    def test_expression_is_true_test_gets_explicit_name(self):
        """``dbt_utils.expression_is_true`` (TEST EXPRESSION) must get a name."""
        tables = {
            "v_psa_stg_test": [{
                "DERIVED_NAME": "hub_test_entity",
                "SOURCE TABLE": "v_psa_stg_test",
                "ALIAS": "SRC",
            }]
        }
        columns = self._columns_with_pk()
        # TEST EXPRESSION fires only when the STAGING LAYER COLUMN NAME appears
        # inside the expression text (see tests.py contract).
        columns[0]["TEST EXPRESSION"] = "TEST_HK is not null"

        yml = make_yml("HUB_TEST_ENTITY", tables, columns)
        missing = self._all_model_tests_have_name(yml)
        assert missing == [], (
            f"Model-level tests missing explicit name (regression of PR #1771 "
            f"comment #7): {missing}"
        )

    def test_multiple_same_type_tests_get_unique_names(self):
        """Two tests of the same type must get distinct names via the
        ``_<counter>`` suffix in the dedup loop."""
        tables = {
            "v_psa_stg_test": [
                {
                    "DERIVED_NAME": "hub_test_entity",
                    "SOURCE TABLE": "v_psa_stg_test",
                    "ALIAS": "SRC",
                },
                {
                    "DERIVED_NAME": "hub_test_entity",
                    "SOURCE TABLE": "v_psa_stg_test_2",
                    "ALIAS": "SRC2",
                },
            ]
        }
        columns = {
            0: {
                "STAGING LAYER COLUMN NAME": "TEST_HK",
                "SOURCE COLUMN": "(DERIVED)",
                "GHOST RECORD": "hash",
                "PK": "PK: TEST_HK",
                "UNIQUE": "",
                "NOT NULL": "",
                "HASHDIFF": "",
                "MODEL EQUALITY": "TEST_HK",
            },
        }
        yml = make_yml("HUB_TEST_ENTITY", tables, columns)
        model_tests = yml["models"][0]["data_tests"]
        all_names = [
            props["name"]
            for entry in model_tests if isinstance(entry, dict)
            for props in entry.values() if isinstance(props, dict) and "name" in props
        ]
        assert len(all_names) == len(set(all_names)), (
            f"Duplicate model-test names emitted (would crash dbt partial-parse): {all_names}"
        )
