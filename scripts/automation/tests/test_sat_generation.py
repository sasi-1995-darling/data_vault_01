"""
test_sat_generation.py — Tests for SAT model generation pipeline.

Validates:
- _build_sat_yaml_model produces correct YAML structure
- _derive_sat_name naming conventions
- SAT column composition follows 100% data rule
- Ghost record values (hash, null, value_text, etc.)
- NOT EXISTS includes PARENT_HK + HASHDIFF (+ multi-active key for MSAT)
- QUALIFY full-refresh-only pattern
- Volume tiers: Normal/Caution/Large config correct
- Watermark: -1 HOUR per-REC_SRC for ≥ 50M
- XLSX generation with SAT Columns tab
- make_yml produces correct SAT/MSAT test composition
"""

import sys
import tempfile
from pathlib import Path

import pytest
import yaml

# Add parent dirs so we can import the modules under test
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from pipeline_orchestrator import (
    _derive_sat_name,
    _build_sat_yaml_model,
    SAT_WATERMARK_THRESHOLD,
    SAT_CLUSTER_THRESHOLD,
)
from generate_tech_spec import TechSpecBuilder
from make_yml import make_yml


# ---------------------------------------------------------------------------
# _derive_sat_name tests
# ---------------------------------------------------------------------------

class TestDeriveSatName:

    def test_default_sat(self):
        assert _derive_sat_name("v_psa_stg_po_item__winn_sap") == "sat_po_item__winn_sap"

    def test_lsat(self):
        assert _derive_sat_name("v_psa_stg_shipment_line__winn_sap", "lsat") == "lsat_shipment_line__winn_sap"

    def test_msat(self):
        assert _derive_sat_name("v_psa_stg_payment_terms__emtk_ebs", "msat") == "msat_payment_terms__emtk_ebs"

    def test_lmsat(self):
        assert _derive_sat_name("v_psa_stg_mrp_lines__winn_sap", "lmsat") == "lmsat_mrp_lines__winn_sap"

    def test_override_name(self):
        assert _derive_sat_name("v_psa_stg_po_item__winn_sap", "sat", "sat_custom_name") == "sat_custom_name"

    def test_override_auto_prefix(self):
        """Override without prefix gets prefix added."""
        assert _derive_sat_name("v_psa_stg_po_item__winn_sap", "msat", "custom_name") == "msat_custom_name"


# ---------------------------------------------------------------------------
# _build_sat_yaml_model tests
# ---------------------------------------------------------------------------

class TestBuildSatYamlModel:

    @pytest.fixture
    def state(self):
        return {
            "model_name": "v_psa_stg_po_item__winn_sap",
            "schema": "sap_ecc_prd",
            "table": "z_ekpo",
            "bk": "EBELN, EBELP",
            "bk_name": "PO_ITEM_BK",
            "rec_src": "USOHNO.SAP.ECCPRD.Z_EKPO",
            "sat": {
                "model_name": "sat_po_item__winn_sap",
                "sat_type": "sat",
                "parent_hk": "PO_ITEM_HK",
                "parent_model": "hub_po_item",
                "multi_active_key": None,
            },
        }

    @pytest.fixture
    def profile(self):
        return {
            "ingestion_source": "snp_glue",
            "columns": [
                {"name": "EBELN", "type": "VARCHAR", "nullable": "NO"},
                {"name": "EBELP", "type": "VARCHAR", "nullable": "NO"},
                {"name": "MATNR", "type": "VARCHAR", "nullable": "YES"},
                {"name": "TXZ01", "type": "VARCHAR", "nullable": "YES"},
                {"name": "MENGE", "type": "NUMBER", "nullable": "YES"},
                {"name": "NETPR", "type": "NUMBER", "nullable": "YES"},
                {"name": "GLDELFLAG", "type": "VARCHAR", "nullable": "YES"},
                {"name": "GLCHANGETIME", "type": "NUMBER", "nullable": "YES"},
                {"name": "GLREQUEST", "type": "VARCHAR", "nullable": "YES"},
                {"name": "GLSOURCESYSTEM", "type": "VARCHAR", "nullable": "YES"},
                {"name": "MANDT", "type": "VARCHAR", "nullable": "YES"},
                {"name": "PSA_DELETE_IND", "type": "VARCHAR", "nullable": "YES"},
                {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_NTZ", "nullable": "YES"},
                {"name": "PSA_RECORD_SOURCE", "type": "VARCHAR", "nullable": "YES"},
            ],
            "row_count": 30_000_000,
        }

    def test_sat_model_structure(self, state, profile):
        """SAT model has correct layer, derived_name, short_name."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        assert model["layer"] == "SAT"
        assert model["derived_name"] == "sat_po_item__winn_sap"

    def test_sat_parent_hk_first(self, state, profile):
        """Parent HK must be the first column."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        first_col = model["columns"][0]
        assert first_col["staging_column_name"] == "PO_ITEM_HK"
        assert first_col["ghost_record"] == "hash"
        assert "PK:" in first_col["pk"]
        assert "PO_ITEM_HK" in first_col["pk"]

    def test_sat_parent_hk_has_relationship(self, state, profile):
        """Parent HK must have Relationship value for FK."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        first_col = model["columns"][0]
        assert first_col["relationship"] == "HUB_PO_ITEM.PO_ITEM_HK"

    def test_sat_100_pct_data_rule(self, state, profile):
        """ALL source columns must be included (100% data rule)."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        col_names = [c["staging_column_name"] for c in model["columns"]]
        # Source data columns present
        assert "MATNR" in col_names
        assert "TXZ01" in col_names
        assert "MENGE" in col_names
        assert "NETPR" in col_names
        # SNP GLUE metadata columns present
        assert "GLDELFLAG" in col_names
        assert "GLCHANGETIME" in col_names
        assert "GLREQUEST" in col_names
        assert "GLSOURCESYSTEM" in col_names
        assert "MANDT" in col_names
        # PSA metadata present
        assert "PSA_DELETE_IND" in col_names
        assert "PSA_LOAD_DTS" in col_names
        assert "PSA_RECORD_SOURCE" in col_names

    def test_sat_no_derived_bk_alias(self, state, profile):
        """Derived BK alias must NOT be in SAT columns."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        col_names = [c["staging_column_name"] for c in model["columns"]]
        assert "PO_ITEM_BK" not in col_names

    def test_sat_excludes_non_parent_hks(self, state, profile):
        """Bug #29: SAT must exclude non-parent HKs and LHKs from payload."""
        # Add derived HK/LHK columns to simulate v_psa_stg profile with HKs
        profile_with_hks = dict(profile)
        profile_with_hks["columns"] = list(profile["columns"]) + [
            {"name": "PO_ITEM_HK", "type": "BINARY", "nullable": "NO"},
            {"name": "ITEM_HK", "type": "BINARY", "nullable": "NO"},
            {"name": "SUPPLIER_HK", "type": "BINARY", "nullable": "NO"},
            {"name": "LNK_PO_ITEM_HK", "type": "BINARY", "nullable": "NO"},
            {"name": "PO_ITEM_LHK", "type": "BINARY", "nullable": "NO"},
        ]
        model = _build_sat_yaml_model(
            state, profile_with_hks, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        col_names = [c["staging_column_name"] for c in model["columns"]]
        # Parent HK is present (added in section 1)
        assert "PO_ITEM_HK" in col_names
        # Non-parent HKs must be excluded
        assert "ITEM_HK" not in col_names
        assert "SUPPLIER_HK" not in col_names
        assert "LNK_PO_ITEM_HK" not in col_names
        assert "PO_ITEM_LHK" not in col_names

    def test_sat_excludes_derived_bk_alias(self, state, profile):
        """Bug #29: Derived BK alias column excluded even if present in profile."""
        # Add the derived BK alias to the profile columns
        profile_with_bk = dict(profile)
        profile_with_bk["columns"] = list(profile["columns"]) + [
            {"name": "PO_ITEM_BK", "type": "VARCHAR", "nullable": "NO"},
        ]
        model = _build_sat_yaml_model(
            state, profile_with_bk, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        col_names = [c["staging_column_name"] for c in model["columns"]]
        assert "PO_ITEM_BK" not in col_names
        # Raw BK columns still present
        assert "EBELN" in col_names
        assert "EBELP" in col_names

    def test_sat_raw_bk_present(self, state, profile):
        """Raw BK columns present with null ghost (DV 2.1: NULL payloads). Lesson #67."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        ebeln = next(c for c in model["columns"] if c["staging_column_name"] == "EBELN")
        ebelp = next(c for c in model["columns"] if c["staging_column_name"] == "EBELP")
        assert ebeln["ghost_record"] == "null"
        assert ebelp["ghost_record"] == "null"

    def test_sat_payload_ghost_null(self, state, profile):
        """All payload columns must have ghost = 'null' (→ NULL AS col in ghost record)."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        matnr = next(c for c in model["columns"] if c["staging_column_name"] == "MATNR")
        assert matnr["ghost_record"] == "null"

    def test_sat_metadata_ghost_values(self, state, profile):
        """Metadata columns have correct ghost values."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        cols = {c["staging_column_name"]: c for c in model["columns"]}
        assert cols["LOAD_DTS"]["ghost_record"] == "load_dts"
        assert cols["REC_SRC"]["ghost_record"] == "rec_src"
        assert cols["BKCC"]["ghost_record"] == "bkcc"
        assert cols["HASHDIFF"]["ghost_record"] == "hashdiff"
        assert cols["PSA_DELETE_IND"]["ghost_record"] == "psa_delete_ind"
        assert cols["PSA_LOAD_DTS"]["ghost_record"] == "psa_load_dts"

    def test_sat_hashdiff_last(self, state, profile):
        """HASHDIFF must be the last column."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        last_col = model["columns"][-1]
        assert last_col["staging_column_name"] == "HASHDIFF"

    def test_sat_column_order(self, state, profile):
        """Column order: HK, BK raw, data, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, LOAD_DTS, REC_SRC, BKCC, HASHDIFF."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        col_names = [c["staging_column_name"] for c in model["columns"]]
        # First = HK
        assert col_names[0] == "PO_ITEM_HK"
        # Raw BKs next
        assert col_names[1] == "EBELN"
        assert col_names[2] == "EBELP"
        # Last 4: LOAD_DTS, REC_SRC, BKCC, HASHDIFF
        assert col_names[-4] == "LOAD_DTS"
        assert col_names[-3] == "REC_SRC"
        assert col_names[-2] == "BKCC"
        assert col_names[-1] == "HASHDIFF"

    def test_sat_not_exists_pattern(self, state, profile):
        """NOT EXISTS must check PARENT_HK + HASHDIFF."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        final_filter = model["sources"][0]["final_layer_filter"]
        assert "NOT EXISTS" in final_filter
        assert "PO_ITEM_HK" in final_filter
        assert "HASHDIFF" in final_filter

    def test_sat_pk_format(self, state, profile):
        """PK must be PARENT_HK, LOAD_DTS for standard SAT."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 30_000_000
        )
        first_col = model["columns"][0]
        assert first_col["pk"] == "PK: PO_ITEM_HK, LOAD_DTS"

    def test_msat_pk_excludes_raw_bk_source_col(self, state, profile):
        """MSAT PK must exclude raw BK source col — only parent HK + filtered grain + LOAD_DTS."""
        # Simulates: BK=VBELN->DELIVERY_BK, grain=[VBELN,SERIALNO], multi_active=SERIALNO
        msat_state = {
            "model_name": "v_psa_stg_delivery_flo_serial__winn_sap",
            "schema": "sap_ecc_prd",
            "table": "z_zflo_serialnos",
            "bk": "VBELN",
            "bk_name": "DELIVERY_BK",
            "rec_src": "US.SAP_ECC_PRD.Z_ZFLO_SERIALNOS",
            "grain_columns": ["VBELN", "SERIALNO"],
            "sat": {
                "model_name": "msat_delivery_flo_serial__winn_sap",
                "sat_type": "msat",
                "parent_hk": "DELIVERY_HK",
                "parent_model": "hub_delivery_v1",
                "multi_active_key": "SERIALNO",
                "grain_columns": ["VBELN", "SERIALNO"],
            },
        }
        model = _build_sat_yaml_model(
            msat_state, profile, ["VBELN"], "DELIVERY_BK", 10_000
        )
        first_col = model["columns"][0]
        # VBELN is excluded (raw BK source), only SERIALNO remains
        assert first_col["pk"] == "PK: DELIVERY_HK, SERIALNO, LOAD_DTS"

    def test_simple_sat_pk_no_raw_bk(self, state, profile):
        """Simple SAT PK must be parent_HK + LOAD_DTS only, no raw BK cols."""
        # Standard SAT with no multi-active key — BK cols should not leak into PK
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 10_000
        )
        first_col = model["columns"][0]
        # No grain keys for non-MSAT, so PK = parent_HK + LOAD_DTS
        assert first_col["pk"] == "PK: PO_ITEM_HK, LOAD_DTS"
        assert "EBELN" not in first_col["pk"]
        assert "EBELP" not in first_col["pk"]
        assert "PSA_LOAD_DTS" not in first_col["pk"]

    # ── Volume tier tests ──

    def test_normal_volume_no_watermark(self, state, profile):
        """Normal volume (<50M) without a delete flag: no watermark, no config.

        Isolated from the PSA_DELETE_IND two-clock fix — a <50M delete-SAT gets a
        global delete-scoped watermark instead (see test_sat_delete_watermark).
        """
        profile = dict(profile)
        profile["columns"] = [
            c for c in profile["columns"] if c["name"].upper() != "PSA_DELETE_IND"
        ]
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 10_000_000
        )
        assert model["sources"][0]["source_layer_filter"] == ""
        assert model["sources"][0]["model_config"] == ""

    def test_caution_volume_watermark(self, state, profile):
        """Caution volume (50M-300M): watermark, no config block."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 95_000_000
        )
        src_filter = model["sources"][0]["source_layer_filter"]
        assert "HOUR" in src_filter
        assert "is_incremental" in src_filter
        assert "rec_src" in src_filter.lower()
        assert model["sources"][0]["model_config"] == ""

    def test_large_volume_config(self, state, profile):
        """Large volume (>300M): watermark + config block."""
        model = _build_sat_yaml_model(
            state, profile, ["EBELN", "EBELP"], "PO_ITEM_BK", 400_000_000
        )
        config = model["sources"][0]["model_config"]
        assert 'full_refresh = var("force_full_refresh", false)' in config
        assert "cluster_by" in config
        assert "PO_ITEM_HK" in config
        assert model["sources"][0]["source_layer_filter"] != ""

    def test_sat_no_duplicate_fivetran_columns(self):
        """Bug #28: _FIVETRAN_* should not appear twice in SAT columns."""
        state = {
            "model_name": "v_psa_stg_planned_order__winn_sap",
            "schema": "sap_ecc_prd",
            "table": "z_plaf",
            "bk": "PLNUM",
            "bk_name": "PLANNED_ORDER_BK",
            "rec_src": "USOHNO.SAP.ECCPRD.Z_PLAF",
            "sat": {
                "model_name": "sat_planned_order__winn_sap",
                "sat_type": "sat",
                "parent_hk": "PLANNED_ORDER_HK",
                "parent_model": "hub_planned_order",
                "multi_active_key": None,
            },
        }
        profile = {
            "ingestion_source": "fivetran",
            "columns": [
                {"name": "PLNUM", "type": "VARCHAR", "nullable": "NO"},
                {"name": "MATNR", "type": "VARCHAR", "nullable": "YES"},
                {"name": "WERKS", "type": "VARCHAR", "nullable": "YES"},
                {"name": "PSA_DELETE_IND", "type": "VARCHAR", "nullable": "YES"},
                {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_NTZ", "nullable": "YES"},
                {"name": "PSA_RECORD_SOURCE", "type": "VARCHAR", "nullable": "YES"},
                {"name": "_FIVETRAN_SYNCED", "type": "TIMESTAMP_TZ", "nullable": "YES"},
                {"name": "_FIVETRAN_ID", "type": "VARCHAR", "nullable": "YES"},
                {"name": "_FIVETRAN_DELETED", "type": "BOOLEAN", "nullable": "YES"},
            ],
            "row_count": 1_000_000,
        }
        model = _build_sat_yaml_model(
            state, profile, ["PLNUM"], "PLANNED_ORDER_BK", 1_000_000
        )
        col_names = [c["staging_column_name"] for c in model["columns"]]
        # Each _FIVETRAN_* column must appear exactly once
        from collections import Counter
        counts = Counter(col_names)
        for ft_col in ("_FIVETRAN_SYNCED", "_FIVETRAN_ID", "_FIVETRAN_DELETED"):
            assert counts[ft_col] == 1, f"{ft_col} appears {counts[ft_col]} times, expected 1"
        # PSA columns must also appear exactly once (Bug #26)
        for psa_col in ("PSA_DELETE_IND", "PSA_LOAD_DTS", "PSA_RECORD_SOURCE"):
            assert counts[psa_col] == 1, f"{psa_col} appears {counts[psa_col]} times, expected 1"


# ---------------------------------------------------------------------------
# MSAT tests
# ---------------------------------------------------------------------------

class TestBuildMsatYamlModel:

    @pytest.fixture
    def state(self):
        return {
            "model_name": "v_psa_stg_payment_term_lines__emtk_ebs",
            "schema": "emtk_ebs_ap",
            "table": "ap_terms_lines",
            "bk": "TERM_ID",
            "bk_name": "PAYMENT_TERM_BK",
            "rec_src": "USWIOC.ORCL.EBSEMTK.AP_TERMS_LINES",
            "sat": {
                "model_name": "msat_payment_term_lines__emtk_ebs",
                "sat_type": "msat",
                "parent_hk": "PAYMENT_TERM_HK",
                "parent_model": "hub_payment_term",
                "multi_active_key": "SEQUENCE_NUM",
            },
        }

    @pytest.fixture
    def profile(self):
        return {
            "ingestion_source": "custom",
            "columns": [
                {"name": "TERM_ID", "type": "NUMBER", "nullable": "NO"},
                {"name": "SEQUENCE_NUM", "type": "NUMBER", "nullable": "NO"},
                {"name": "DUE_PERCENT", "type": "NUMBER", "nullable": "YES"},
                {"name": "DUE_AMOUNT", "type": "NUMBER", "nullable": "YES"},
                {"name": "PSA_DELETE_IND", "type": "VARCHAR", "nullable": "YES"},
                {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_NTZ", "nullable": "YES"},
                {"name": "PSA_RECORD_SOURCE", "type": "VARCHAR", "nullable": "YES"},
            ],
            "row_count": 5_000_000,
        }

    def test_msat_pk_includes_multi_active_key(self, state, profile):
        """MSAT PK must include multi-active key."""
        model = _build_sat_yaml_model(
            state, profile, ["TERM_ID"], "PAYMENT_TERM_BK", 5_000_000
        )
        first_col = model["columns"][0]
        assert "SEQUENCE_NUM" in first_col["pk"]
        assert "LOAD_DTS" in first_col["pk"]
        assert "PAYMENT_TERM_HK" in first_col["pk"]

    def test_msat_not_exists_includes_multi_active_key(self, state, profile):
        """MSAT NOT EXISTS must include multi-active key."""
        model = _build_sat_yaml_model(
            state, profile, ["TERM_ID"], "PAYMENT_TERM_BK", 5_000_000
        )
        final_filter = model["sources"][0]["final_layer_filter"]
        assert "SEQUENCE_NUM" in final_filter
        assert "HASHDIFF" in final_filter

    def test_msat_multi_active_key_has_ghost(self, state, profile):
        """Multi-active key must have value_number ghost (NUMBER type)."""
        model = _build_sat_yaml_model(
            state, profile, ["TERM_ID"], "PAYMENT_TERM_BK", 5_000_000
        )
        seq_col = next(c for c in model["columns"] if c["staging_column_name"] == "SEQUENCE_NUM")
        assert seq_col["ghost_record"] == "value_number"

    def test_msat_layer_prefix(self, state, profile):
        """MSAT model has layer=MSAT."""
        model = _build_sat_yaml_model(
            state, profile, ["TERM_ID"], "PAYMENT_TERM_BK", 5_000_000
        )
        assert model["layer"] == "MSAT"
        assert model["derived_name"] == "msat_payment_term_lines__emtk_ebs"


# ---------------------------------------------------------------------------
# LSAT tests
# ---------------------------------------------------------------------------

class TestBuildLsatYamlModel:

    @pytest.fixture
    def state(self):
        return {
            "model_name": "v_psa_stg_shipment_line__winn_sap",
            "schema": "sap_ecc_prd",
            "table": "z_vttp",
            "bk": "TKNUM, TPNUM",
            "bk_name": "SHIPMENT_LINE_BK",
            "rec_src": "USOHNO.SAP.ECCPRD.Z_VTTP",
            "sat": {
                "model_name": "lsat_shipment_line__winn_sap",
                "sat_type": "lsat",
                "parent_hk": "SHIPMENT_LINE_LHK",
                "parent_model": "lnk_shipment_line",
                "multi_active_key": None,
            },
        }

    @pytest.fixture
    def profile(self):
        return {
            "ingestion_source": "snp_glue",
            "columns": [
                {"name": "TKNUM", "type": "VARCHAR", "nullable": "NO"},
                {"name": "TPNUM", "type": "VARCHAR", "nullable": "NO"},
                {"name": "VBELN", "type": "VARCHAR", "nullable": "YES"},
                {"name": "PSA_DELETE_IND", "type": "VARCHAR", "nullable": "YES"},
                {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_NTZ", "nullable": "YES"},
                {"name": "PSA_RECORD_SOURCE", "type": "VARCHAR", "nullable": "YES"},
            ],
            "row_count": 20_000_000,
        }

    def test_lsat_fk_points_to_link(self, state, profile):
        """LSAT FK must point to lnk_ model, not hub_."""
        model = _build_sat_yaml_model(
            state, profile, ["TKNUM", "TPNUM"], "SHIPMENT_LINE_BK", 20_000_000
        )
        first_col = model["columns"][0]
        assert "LNK_SHIPMENT_LINE" in first_col["relationship"]

    def test_lsat_layer_prefix(self, state, profile):
        """LSAT model has layer=LSAT."""
        model = _build_sat_yaml_model(
            state, profile, ["TKNUM", "TPNUM"], "SHIPMENT_LINE_BK", 20_000_000
        )
        assert model["layer"] == "LSAT"


# ---------------------------------------------------------------------------
# XLSX generation tests
# ---------------------------------------------------------------------------

class TestSatXlsxGeneration:

    def test_sat_xlsx_tab_exists(self):
        """SAT model produces Tables and Columns tabs in XLSX."""
        config = {
            "_pipeline_metadata": {"bkcc_rec_src": "USOHNO.SAP.ECCPRD.Z_EKPO"},
            "models": [{
                "layer": "SAT",
                "derived_name": "sat_test_entity__src",
                "short_name": "test_entity__src",
                "sources": [{
                    "source_schema": "int_staging_views",
                    "source_table": "v_psa_stg_test_entity__src",
                    "alias": "SRC",
                    "source_layer_filter": "",
                    "final_layer_filter": "{% if is_incremental() %}\nWHERE NOT EXISTS (\n    SELECT 1\n    FROM {{ this }} existing\n    WHERE existing.TEST_HK = JOIN_RESULT.TEST_HK\n      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF\n)\n{% endif %}",
                    "target_schema": "raw_vault",
                    "model_config": "",
                }],
                "columns": [
                    {"source_table": "SRC", "source_column": "TEST_HK", "staging_column_name": "TEST_HK", "datatype": "BINARY", "pk": "PK: TEST_HK, LOAD_DTS", "ghost_record": "hash", "relationship": "HUB_TEST.TEST_HK"},
                    {"source_table": "SRC", "source_column": "COL1", "staging_column_name": "COL1", "datatype": "VARCHAR", "ghost_record": ""},
                    {"source_table": "SRC", "source_column": "LOAD_DTS", "staging_column_name": "LOAD_DTS", "datatype": "TIMESTAMP_NTZ", "ghost_record": "load_dts"},
                    {"source_table": "SRC", "source_column": "REC_SRC", "staging_column_name": "REC_SRC", "datatype": "TEXT", "ghost_record": "rec_src"},
                    {"source_table": "SRC", "source_column": "BKCC", "staging_column_name": "BKCC", "datatype": "TEXT", "ghost_record": "bkcc"},
                    {"source_table": "SRC", "source_column": "HASHDIFF", "staging_column_name": "HASHDIFF", "datatype": "BINARY", "ghost_record": "hashdiff"},
                ],
            }],
        }
        builder = TechSpecBuilder(config)
        wb = builder.build()

        sheet_names = wb.sheetnames
        # Should have Index, Tables, Columns
        assert any("Tables" in s for s in sheet_names)
        assert any("Columns" in s for s in sheet_names)

    def test_sat_xlsx_columns_count(self):
        """SAT Columns tab has 19 header columns (SAT format: no Hashdiff header)."""
        config = {
            "_pipeline_metadata": {},
            "models": [{
                "layer": "SAT",
                "derived_name": "sat_test__src",
                "short_name": "test__src",
                "sources": [{"source_schema": "int_staging_views", "source_table": "v_psa_stg_test__src", "alias": "SRC", "source_layer_filter": "", "final_layer_filter": "", "target_schema": "raw_vault", "model_config": ""}],
                "columns": [
                    {"source_table": "SRC", "source_column": "HK", "staging_column_name": "TEST_HK", "datatype": "BINARY", "pk": "PK: TEST_HK, LOAD_DTS", "ghost_record": "hash", "relationship": "HUB_TEST.TEST_HK"},
                    {"source_table": "SRC", "source_column": "COL1", "staging_column_name": "COL1", "datatype": "VARCHAR", "ghost_record": ""},
                ],
            }],
        }
        builder = TechSpecBuilder(config)
        wb = builder.build()

        # Find Columns sheet
        cols_sheet = [s for s in wb.sheetnames if "Columns" in s][0]
        ws = wb[cols_sheet]
        header_row = list(ws.iter_rows(min_row=1, max_row=1, values_only=True))[0]
        assert len(header_row) == 19  # 19 columns per SAT_COLUMNS_HEADERS

    def test_sat_xlsx_ghost_record_populated(self):
        """Ghost Record column must be populated for metadata rows."""
        config = {
            "_pipeline_metadata": {},
            "models": [{
                "layer": "SAT",
                "derived_name": "sat_test__src",
                "short_name": "test__src",
                "sources": [{"source_schema": "int_staging_views", "source_table": "v_psa_stg_test__src", "alias": "SRC", "source_layer_filter": "", "final_layer_filter": "", "target_schema": "raw_vault", "model_config": ""}],
                "columns": [
                    {"source_table": "SRC", "source_column": "HK", "staging_column_name": "TEST_HK", "datatype": "BINARY", "pk": "PK: TEST_HK, LOAD_DTS", "ghost_record": "hash", "relationship": "HUB_TEST.TEST_HK"},
                    {"source_table": "SRC", "source_column": "LOAD_DTS", "staging_column_name": "LOAD_DTS", "datatype": "TIMESTAMP_NTZ", "ghost_record": "load_dts"},
                    {"source_table": "SRC", "source_column": "HASHDIFF", "staging_column_name": "HASHDIFF", "datatype": "BINARY", "ghost_record": "hashdiff"},
                ],
            }],
        }
        builder = TechSpecBuilder(config)
        wb = builder.build()

        cols_sheet = [s for s in wb.sheetnames if "Columns" in s][0]
        ws = wb[cols_sheet]
        rows = list(ws.iter_rows(min_row=2, values_only=True))

        # HK row should have ghost='hash' (SAT format: Ghost Record at idx 12)
        hk_row = next(r for r in rows if (r[8] or "") == "TEST_HK")
        assert hk_row[12] == "hash"

        # LOAD_DTS row should have ghost='load_dts'
        load_row = next(r for r in rows if (r[8] or "") == "LOAD_DTS")
        assert load_row[12] == "load_dts"

    def test_sat_xlsx_pk_populated(self):
        """PK column must be populated for the parent HK row."""
        config = {
            "_pipeline_metadata": {},
            "models": [{
                "layer": "SAT",
                "derived_name": "sat_test__src",
                "short_name": "test__src",
                "sources": [{"source_schema": "", "source_table": "v_psa_stg_test__src", "alias": "SRC", "source_layer_filter": "", "final_layer_filter": "", "target_schema": "raw_vault", "model_config": ""}],
                "columns": [
                    {"source_table": "SRC", "source_column": "HK", "staging_column_name": "TEST_HK", "datatype": "BINARY", "pk": "PK: TEST_HK, LOAD_DTS", "ghost_record": "hash", "relationship": "HUB_TEST.TEST_HK"},
                ],
            }],
        }
        builder = TechSpecBuilder(config)
        wb = builder.build()

        cols_sheet = [s for s in wb.sheetnames if "Columns" in s][0]
        ws = wb[cols_sheet]
        rows = list(ws.iter_rows(min_row=2, values_only=True))

        hk_row = next(r for r in rows if (r[8] or "") == "TEST_HK")
        assert "PK:" in (hk_row[10] or "")

    def test_sat_xlsx_relationship_populated(self):
        """Relationship column must be populated for FK."""
        config = {
            "_pipeline_metadata": {},
            "models": [{
                "layer": "SAT",
                "derived_name": "sat_test__src",
                "short_name": "test__src",
                "sources": [{"source_schema": "", "source_table": "v_psa_stg_test__src", "alias": "SRC", "source_layer_filter": "", "final_layer_filter": "", "target_schema": "raw_vault", "model_config": ""}],
                "columns": [
                    {"source_table": "SRC", "source_column": "HK", "staging_column_name": "TEST_HK", "datatype": "BINARY", "pk": "PK: TEST_HK, LOAD_DTS", "ghost_record": "hash", "relationship": "HUB_TEST.TEST_HK"},
                ],
            }],
        }
        builder = TechSpecBuilder(config)
        wb = builder.build()

        cols_sheet = [s for s in wb.sheetnames if "Columns" in s][0]
        ws = wb[cols_sheet]
        rows = list(ws.iter_rows(min_row=2, values_only=True))

        hk_row = next(r for r in rows if (r[8] or "") == "TEST_HK")
        assert "HUB_TEST" in (hk_row[18] or "")  # Relationship at idx 18 in SAT format


# ---------------------------------------------------------------------------
# make_yml SAT tests
# ---------------------------------------------------------------------------

class TestSatMakeYml:

    def _make_sat_columns(self, pk_str="PK: TEST_HK, LOAD_DTS", relationship="HUB_TEST.TEST_HK"):
        """Create a minimal SAT column dict for make_yml testing."""
        return {
            0: {"STAGING LAYER COLUMN NAME": "TEST_HK", "PK": pk_str, "UNIQUE": "", "NOT NULL": "", "GHOST RECORD": "hash", "RELATIONSHIP": relationship},
            1: {"STAGING LAYER COLUMN NAME": "COL1", "PK": "", "UNIQUE": "", "NOT NULL": "", "GHOST RECORD": "", "RELATIONSHIP": ""},
            2: {"STAGING LAYER COLUMN NAME": "LOAD_DTS", "PK": "", "UNIQUE": "", "NOT NULL": "", "GHOST RECORD": "load_dts", "RELATIONSHIP": ""},
            3: {"STAGING LAYER COLUMN NAME": "HASHDIFF", "PK": "", "UNIQUE": "", "NOT NULL": "", "GHOST RECORD": "hashdiff", "RELATIONSHIP": ""},
        }

    def _make_sat_tables(self, derived_name="sat_test__src"):
        return {"table1": [{"DERIVED_NAME": derived_name}]}

    def test_sat_yml_has_pk_test(self):
        """SAT YAML must have dbt_constraints.primary_key test."""
        columns = self._make_sat_columns()
        tables = self._make_sat_tables()
        result = make_yml("SAT_test__src", tables, columns)
        model = result["models"][0]
        pk_tests = [t for t in model["data_tests"] if isinstance(t, dict) and "dbt_constraints.primary_key" in t]
        assert len(pk_tests) >= 1
        pk_test = pk_tests[0]["dbt_constraints.primary_key"]
        assert "TEST_HK" in pk_test["arguments"]["column_names"]
        assert "LOAD_DTS" in pk_test["arguments"]["column_names"]

    def test_sat_yml_has_row_count_test(self):
        """SAT YAML must have expect_table_row_count_to_be_between test."""
        columns = self._make_sat_columns()
        tables = self._make_sat_tables()
        result = make_yml("SAT_test__src", tables, columns)
        model = result["models"][0]
        row_tests = [t for t in model["data_tests"] if isinstance(t, dict) and "dbt_expectations.expect_table_row_count_to_be_between" in t]
        assert len(row_tests) == 1
        assert row_tests[0]["dbt_expectations.expect_table_row_count_to_be_between"]["arguments"]["min_value"] == 4

    def test_sat_yml_has_fk_test(self):
        """SAT YAML must have FK test on parent HK column."""
        columns = self._make_sat_columns()
        tables = self._make_sat_tables()
        result = make_yml("SAT_test__src", tables, columns)
        model = result["models"][0]
        # Check column-level tests for FK
        hk_col = next((c for c in model.get("columns", []) if c["name"] == "TEST_HK"), None)
        assert hk_col is not None
        fk_tests = [t for t in hk_col.get("data_tests", []) if isinstance(t, dict) and "dbt_constraints.foreign_key" in t]
        assert len(fk_tests) >= 1

    def test_sat_yml_tags(self):
        """SAT YAML must have tags config."""
        columns = self._make_sat_columns()
        tables = self._make_sat_tables()
        result = make_yml("SAT_test__src", tables, columns)
        model = result["models"][0]
        assert "config" in model
        assert "sat" in model["config"]["tags"]

    def test_sat_yml_no_unique_key(self):
        """SAT YAML must NOT have unique_key (append-only strategy)."""
        columns = self._make_sat_columns()
        tables = self._make_sat_tables()
        result = make_yml("SAT_test__src", tables, columns)
        model = result["models"][0]
        assert "unique_key" not in model["config"]

    def test_sat_yml_severity_warn(self):
        """All SAT tests should have severity=warn."""
        columns = self._make_sat_columns()
        tables = self._make_sat_tables()
        result = make_yml("SAT_test__src", tables, columns)
        model = result["models"][0]
        for test in model["data_tests"]:
            if isinstance(test, dict):
                for key, val in test.items():
                    if isinstance(val, dict) and "config" in val:
                        assert val["config"]["severity"] == "warn", f"Test {key} should have severity=warn"

    def test_msat_yml_pk_includes_multi_active_key(self):
        """MSAT PK must include multi-active key."""
        columns = self._make_sat_columns(pk_str="PK: TEST_HK, SEQUENCE_NUM, LOAD_DTS")
        tables = self._make_sat_tables("msat_test__src")
        result = make_yml("MSAT_test__src", tables, columns)
        model = result["models"][0]
        pk_tests = [t for t in model["data_tests"] if isinstance(t, dict) and "dbt_constraints.primary_key" in t]
        assert len(pk_tests) >= 1
        pk_cols = pk_tests[0]["dbt_constraints.primary_key"]["arguments"]["column_names"]
        assert "SEQUENCE_NUM" in pk_cols

    def test_msat_yml_tag(self):
        """MSAT YAML must have 'msat' tag."""
        columns = self._make_sat_columns(pk_str="PK: TEST_HK, SEQUENCE_NUM, LOAD_DTS")
        tables = self._make_sat_tables("msat_test__src")
        result = make_yml("MSAT_test__src", tables, columns)
        model = result["models"][0]
        assert "msat" in model["config"]["tags"]

    def test_lsat_yml_tag(self):
        """LSAT YAML must have 'lsat' tag."""
        columns = self._make_sat_columns(pk_str="PK: TEST_LHK, LOAD_DTS", relationship="LNK_TEST.TEST_LHK")
        columns[0]["STAGING LAYER COLUMN NAME"] = "TEST_LHK"
        tables = self._make_sat_tables("lsat_test__src")
        result = make_yml("LSAT_test__src", tables, columns)
        model = result["models"][0]
        assert "lsat" in model["config"]["tags"]


# ---------------------------------------------------------------------------
# Validation tests
# ---------------------------------------------------------------------------

class TestSatValidation:

    def _build_sat_xlsx(self, columns=None, final_filter=None):
        """Build a minimal SAT XLSX for validation testing."""
        if final_filter is None:
            final_filter = (
                "{% if is_incremental() %}\n"
                "WHERE NOT EXISTS (\n"
                "    SELECT 1\n"
                "    FROM {{ this }} existing\n"
                "    WHERE existing.TEST_HK = JOIN_RESULT.TEST_HK\n"
                "      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF\n"
                ")\n"
                "{% endif %}"
            )
        if columns is None:
            columns = [
                {"source_table": "SRC", "source_column": "TEST_HK", "staging_column_name": "TEST_HK", "datatype": "BINARY", "pk": "PK: TEST_HK, LOAD_DTS", "ghost_record": "hash", "relationship": "HUB_TEST.TEST_HK"},
                {"source_table": "SRC", "source_column": "COL1", "staging_column_name": "COL1", "datatype": "VARCHAR", "ghost_record": ""},
                {"source_table": "SRC", "source_column": "LOAD_DTS", "staging_column_name": "LOAD_DTS", "datatype": "TIMESTAMP_NTZ", "ghost_record": "load_dts"},
                {"source_table": "SRC", "source_column": "REC_SRC", "staging_column_name": "REC_SRC", "datatype": "TEXT", "ghost_record": "rec_src"},
                {"source_table": "SRC", "source_column": "BKCC", "staging_column_name": "BKCC", "datatype": "TEXT", "ghost_record": "bkcc"},
                {"source_table": "SRC", "source_column": "HASHDIFF", "staging_column_name": "HASHDIFF", "datatype": "BINARY", "ghost_record": "hashdiff"},
            ]

        config = {
            "_pipeline_metadata": {},
            "models": [{
                "layer": "SAT",
                "derived_name": "sat_test__src",
                "short_name": "test__src",
                "sources": [{
                    "source_schema": "int_staging_views",
                    "source_table": "v_psa_stg_test__src",
                    "alias": "SRC",
                    "source_layer_filter": "",
                    "final_layer_filter": final_filter,
                    "target_schema": "raw_vault",
                    "model_config": "",
                }],
                "columns": columns,
            }],
        }
        return config

    def test_valid_sat_passes(self, tmp_path):
        """Well-formed SAT should pass validation."""
        from validate_tech_spec import TechSpecValidator

        config = self._build_sat_xlsx()
        builder = TechSpecBuilder(config)
        wb = builder.build()

        xlsx_path = tmp_path / "test.xlsx"
        wb.save(str(xlsx_path))

        validator = TechSpecValidator(config, str(xlsx_path))
        errors = validator.validate()
        error_errors = [e for e in errors if e.severity == "ERROR"]
        assert len(error_errors) == 0, f"Unexpected errors: {[str(e) for e in error_errors]}"

    def test_missing_pk_fails(self, tmp_path):
        """SAT without PK definition should fail validation."""
        from validate_tech_spec import TechSpecValidator

        columns = [
            {"source_table": "SRC", "source_column": "TEST_HK", "staging_column_name": "TEST_HK", "datatype": "BINARY", "pk": "", "ghost_record": "hash", "relationship": "HUB_TEST.TEST_HK"},
            {"source_table": "SRC", "source_column": "LOAD_DTS", "staging_column_name": "LOAD_DTS", "datatype": "TIMESTAMP_NTZ", "ghost_record": "load_dts"},
            {"source_table": "SRC", "source_column": "REC_SRC", "staging_column_name": "REC_SRC", "datatype": "TEXT", "ghost_record": "rec_src"},
            {"source_table": "SRC", "source_column": "BKCC", "staging_column_name": "BKCC", "datatype": "TEXT", "ghost_record": "bkcc"},
            {"source_table": "SRC", "source_column": "HASHDIFF", "staging_column_name": "HASHDIFF", "datatype": "BINARY", "ghost_record": "hashdiff"},
        ]
        config = self._build_sat_xlsx(columns=columns)
        builder = TechSpecBuilder(config)
        wb = builder.build()

        xlsx_path = tmp_path / "test.xlsx"
        wb.save(str(xlsx_path))

        validator = TechSpecValidator(config, str(xlsx_path))
        errors = validator.validate()
        rules = [e.rule for e in errors]
        assert "SAT_PK_MISSING" in rules

    def test_missing_not_exists_fails(self, tmp_path):
        """SAT without NOT EXISTS in final filter should fail."""
        from validate_tech_spec import TechSpecValidator

        config = self._build_sat_xlsx(final_filter="")
        builder = TechSpecBuilder(config)
        wb = builder.build()

        xlsx_path = tmp_path / "test.xlsx"
        wb.save(str(xlsx_path))

        validator = TechSpecValidator(config, str(xlsx_path))
        errors = validator.validate()
        rules = [e.rule for e in errors]
        assert "SAT_MISSING_NOT_EXISTS" in rules


# ---------------------------------------------------------------------------
# XLSX Header Format Tests
# ---------------------------------------------------------------------------

class TestXlsxHeaderFormats:
    """Verify layer-specific column header formats match production."""

    def test_sat_xlsx_column_order_pk_unique_ghost_notnull(self):
        """SAT column header order: PK → Unique → Ghost Record → Not Null (different from HUB!)."""
        from generate_tech_spec import SAT_COLUMNS_HEADERS
        pk_idx = SAT_COLUMNS_HEADERS.index("PK")
        unique_idx = SAT_COLUMNS_HEADERS.index("Unique")
        ghost_idx = SAT_COLUMNS_HEADERS.index("Ghost Record")
        notnull_idx = SAT_COLUMNS_HEADERS.index("Not Null")
        assert pk_idx < unique_idx < ghost_idx < notnull_idx
        assert len(SAT_COLUMNS_HEADERS) == 19
        assert "Hashdiff" not in SAT_COLUMNS_HEADERS

    def test_hub_xlsx_column_order_pk_unique_notnull_ghost(self):
        """HUB column header order: PK → Unique → Not Null → Ghost Record → Hashdiff."""
        from generate_tech_spec import HUB_LNK_COLUMNS_HEADERS
        pk_idx = HUB_LNK_COLUMNS_HEADERS.index("PK")
        unique_idx = HUB_LNK_COLUMNS_HEADERS.index("Unique")
        notnull_idx = HUB_LNK_COLUMNS_HEADERS.index("Not Null")
        ghost_idx = HUB_LNK_COLUMNS_HEADERS.index("Ghost Record")
        hd_idx = HUB_LNK_COLUMNS_HEADERS.index("Hashdiff")
        assert pk_idx < unique_idx < notnull_idx < ghost_idx < hd_idx
        assert len(HUB_LNK_COLUMNS_HEADERS) == 20

    def test_hub_xlsx_20_column_headers(self):
        """HUB Columns tab has 20 columns in correct order."""
        config = {
            "_pipeline_metadata": {},
            "models": [{
                "layer": "HUB",
                "derived_name": "hub_test",
                "short_name": "TEST",
                "sources": [{"source_schema": "int_staging_views", "source_table": "v_psa_stg_test", "alias": "SRC", "source_layer_filter": "", "final_layer_filter": "", "target_schema": "raw_vault", "model_config": ""}],
                "columns": [
                    {"source_table": "SRC", "source_column": "TEST_HK", "staging_column_name": "TEST_HK", "datatype": "BINARY", "pk": "PK: TEST_HK", "ghost_record": "hash"},
                    {"source_table": "SRC", "source_column": "COL1", "staging_column_name": "COL1", "datatype": "VARCHAR", "ghost_record": "value_text"},
                ],
            }],
        }
        builder = TechSpecBuilder(config)
        wb = builder.build()
        cols_sheet = [s for s in wb.sheetnames if "Columns" in s][0]
        ws = wb[cols_sheet]
        headers = [cell.value for cell in ws[1]]
        assert len(headers) == 20
        assert headers[13] == "Ghost Record"
        assert headers[14] == "Hashdiff"

    def test_lnk_xlsx_no_bkcc(self):
        """LNK Columns tab has no BKCC column."""
        from pipeline_orchestrator import _build_lnk_yaml_model
        state = {
            "model_name": "v_psa_stg_test__src",
            "schema": "src", "table": "test",
            "bk": "COL1", "bk_name": "TEST_BK",
            "rec_src": "TEST.SRC",
        }
        profile = {"ingestion_source": "fivetran", "columns": []}
        model = _build_lnk_yaml_model(state, profile, ["A_HK", "B_HK"], "test_ab", [], 1000)
        col_names = [c["staging_column_name"] for c in model["columns"]]
        assert "BKCC" not in col_names

    def test_lnk_xlsx_all_parent_hks_ghost_hash(self):
        """All parent HK columns in LNK have Ghost Record = hash."""
        config = {
            "_pipeline_metadata": {},
            "models": [{
                "layer": "LNK",
                "derived_name": "lnk_test",
                "short_name": "TEST",
                "sources": [{"source_schema": "", "source_table": "v", "alias": "SRC", "source_layer_filter": "", "final_layer_filter": "", "target_schema": "raw_vault", "model_config": ""}],
                "columns": [
                    {"source_table": "SRC", "source_column": "LNK_TEST_HK", "staging_column_name": "LNK_TEST_HK", "datatype": "BINARY", "pk": "PK: LNK_TEST_HK", "ghost_record": "hash"},
                    {"source_table": "SRC", "source_column": "A_HK", "staging_column_name": "A_HK", "datatype": "BINARY", "ghost_record": "hash"},
                    {"source_table": "SRC", "source_column": "B_HK", "staging_column_name": "B_HK", "datatype": "BINARY", "ghost_record": "hash"},
                ],
            }],
        }
        builder = TechSpecBuilder(config)
        wb = builder.build()
        cols_sheet = [s for s in wb.sheetnames if "Columns" in s][0]
        ws = wb[cols_sheet]
        rows = list(ws.iter_rows(min_row=2, values_only=True))
        # Ghost Record at idx 13 for HUB/LNK format
        for r in rows:
            staging = (r[8] or "").upper()
            if staging.endswith("_HK"):
                assert (r[13] or "").strip().lower() == "hash", f"{staging} ghost should be 'hash'"

    def test_hub_xlsx_source_layer_filter_has_qualify(self):
        """Non-watermark HUB has QUALIFY in source_layer_filter."""
        from pipeline_orchestrator import _build_hub_yaml_model, HUB_WATERMARK_THRESHOLD
        state = {
            "model_name": "v_psa_stg_test__src",
            "schema": "src", "table": "test",
            "bk": "COL1", "bk_name": "TEST_BK",
            "rec_src": "TEST.SRC",
        }
        profile = {"ingestion_source": "fivetran", "columns": [{"name": "COL1", "type": "VARCHAR"}]}
        # Below watermark threshold
        model = _build_hub_yaml_model(state, profile, ["COL1"], "TEST_BK", 1000)
        src_filter = model["sources"][0]["source_layer_filter"]
        assert "QUALIFY" in src_filter
        assert "TEST_HK" in src_filter

    def test_hub_xlsx_final_layer_filter_has_not_exists(self):
        """HUB has NOT EXISTS in final_layer_filter."""
        from pipeline_orchestrator import _build_hub_yaml_model
        state = {
            "model_name": "v_psa_stg_test__src",
            "schema": "src", "table": "test",
            "bk": "COL1", "bk_name": "TEST_BK",
            "rec_src": "TEST.SRC",
        }
        profile = {"ingestion_source": "fivetran", "columns": [{"name": "COL1", "type": "VARCHAR"}]}
        model = _build_hub_yaml_model(state, profile, ["COL1"], "TEST_BK", 1000)
        final_filter = model["sources"][0]["final_layer_filter"]
        assert "NOT EXISTS" in final_filter

    def test_hub_no_src_qualify_for_watermark(self):
        """Watermark HUB has empty source_layer_filter (build.py handles it)."""
        from pipeline_orchestrator import _build_hub_yaml_model, HUB_WATERMARK_THRESHOLD
        state = {
            "model_name": "v_psa_stg_test__src",
            "schema": "src", "table": "test",
            "bk": "COL1", "bk_name": "TEST_BK",
            "rec_src": "TEST.SRC",
        }
        profile = {"ingestion_source": "fivetran", "columns": [{"name": "COL1", "type": "VARCHAR"}]}
        model = _build_hub_yaml_model(state, profile, ["COL1"], "TEST_BK", HUB_WATERMARK_THRESHOLD + 1)
        assert model["sources"][0]["source_layer_filter"] == ""
        assert model["sources"][0]["qualify_order_by"] != ""  # build.py uses this
