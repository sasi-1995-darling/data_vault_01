"""Composite business-key handling: arg-parse validation, source_column list
serialization (Defect 2), XLSX composite rendering (Defect 3), and the shared
CONCAT_WS delimiter constant.

Covers the three defects surfaced by the EMTK_EBS supplier-invoice-line session:
  1. --bk rejects hand-built CONCAT/`||` composites with an actionable message
     (single-column derivations are still accepted).
  2. source_column is emitted as a YAML list (uniform, order-preserving) via one
     normalizer, read via one accessor.
  3. The XLSX tech spec renders a composite BK's source columns split (never
     comma-joined), enforced by XLSX_COMPOSITE_BK_COLUMNS_SPLIT.
"""

import json
import subprocess
import sys
from argparse import Namespace
from pathlib import Path

import pytest
import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from pipeline_orchestrator import (
    _validate_bk_arg,
    _validate_raw_column_list,
    cmd_generate_yaml,
    cmd_init,
    _now_iso,
    STATE_DIR,
    SCRIPT_DIR,
)
from source_column_utils import (
    COMPOSITE_BK_DELIMITER,
    LegacySourceColumnWarning,
    normalize_source_column,
    get_source_columns,
    source_columns_to_str,
)


# ═══════════════════════════════════════════════════════════════════════════
# Group A — Defect 1: --bk / --hk / --dck validation
# ═══════════════════════════════════════════════════════════════════════════

class TestBkArgValidation:
    """_validate_bk_arg is scoped (Option 1): single-column derivations pass;
    only malformed MULTI-part composites are rejected."""

    # ---- single-column expressions: ALL accepted (returns None) ----
    @pytest.mark.parametrize("expr", [
        "INVOICE_ID",                 # raw column
        "ID::TEXT",                   # cast
        "TO_CHAR(ID)",                # function derivation
        "COALESCE(NAME, '-1')",       # derivation with inner comma + literal
        "CONCAT(REGION, '-', ID)",    # CONCAT single-column derivation (cited in Q1)
        "ID || '-' || REGION",        # || single-column derivation (cited in Q1)
    ])
    def test_single_column_expressions_accepted(self, expr):
        assert _validate_bk_arg(expr) is None

    # ---- raw composites: accepted (orchestrator builds CONCAT_WS) ----
    @pytest.mark.parametrize("expr", ["INVOICE_ID,LINE_NUMBER", "INVOICE_ID, LINE_NUMBER"])
    def test_raw_composite_accepted(self, expr):
        assert _validate_bk_arg(expr) is None

    # ---- malformed multi-part composites: rejected with actionable message ----
    def test_rejects_bad_identifier_in_composite_naming_token(self):
        msg = _validate_bk_arg("INVOICE_ID,123BAD")
        assert msg is not None
        assert "123BAD" in msg
        assert "raw column names only" in msg

    def test_rejects_mixed_raw_and_derivation_composite(self):
        # A top-level comma joining a raw column and a function is ambiguous —
        # steer to raw columns (or a single expression).
        msg = _validate_bk_arg("INVOICE_ID, CONCAT(X, Y)")
        assert msg is not None
        assert "CONCAT(X, Y)" in msg


def _full_init_args(bk, model_name="v_psa_stg_ci_bkinit__x", **over):
    """A complete cmd_init Namespace (all fields cmd_init reads)."""
    defaults = dict(
        model_name=model_name, schema="emtk_ebs_ap", table="ap_invoice_lines",
        bk=bk, bk_name="X_BK", rec_src="USWIOC.ORCL.EBSEMTK.AP_INVOICE_LINES",
        objects="stg", force=True, hk=[], lnk_name=None, parent_hks=None, dck=None,
        sat_type=None, sat_parent_hk=None, sat_parent_model=None, multi_active_key=None,
        sat_name=None, sat_columns=None, grain_columns=None, hub_name=None,
        additional_bk=[], domain=None, load_dts_column=None,
        secondary_schema=None, secondary_table=None, secondary_alias=None,
        secondary_join_type=None, join_type=None, join_on=None,
        secondary_columns=None, secondary_bk=None, secondary_bk_name=None,
    )
    defaults.update(over)
    return Namespace(**defaults)


class TestBkArgCmdInitLevel:
    """cmd_init-level acceptance (NOT just _validate_bk_arg): the reviewer noted
    the YAML-builder tests bypass cmd_init, so suite-green alone does not prove
    the CLI path accepts these. Each derivation is driven through cmd_init here."""

    # The exact expressions Codex cited from Q1 evidence as valid single-column
    # derivations. All must be accepted by cmd_init (rc == 0).
    @pytest.mark.parametrize("bk", [
        "TO_CHAR(ID)",
        "COALESCE(NAME, '-1')",
        "CONCAT(REGION, '-', ID)",
        "ID || '-' || REGION",
        "ID::TEXT",
    ])
    def test_cmd_init_accepts_single_column_derivation(self, bk):
        model = "v_psa_stg_ci_bkinit__x"
        try:
            rc = cmd_init(_full_init_args(bk, model_name=model))
            assert rc == 0, f"cmd_init rejected single-column derivation {bk!r}"
            st = json.loads((STATE_DIR / f"{model}.json").read_text())
            assert st["bk"] == bk  # stored verbatim, not mis-split
        finally:
            (STATE_DIR / f"{model}.json").unlink(missing_ok=True)

    def test_cmd_init_accepts_raw_composite(self):
        model = "v_psa_stg_ci_bkinit_comp__x"
        try:
            rc = cmd_init(_full_init_args("INVOICE_ID,LINE_NUMBER", model_name=model))
            assert rc == 0
        finally:
            (STATE_DIR / f"{model}.json").unlink(missing_ok=True)

    def test_cmd_init_rejects_malformed_composite(self):
        model = "v_psa_stg_ci_bkinit_bad__x"
        try:
            rc = cmd_init(_full_init_args("INVOICE_ID,123BAD", model_name=model))
            assert rc == 1
        finally:
            (STATE_DIR / f"{model}.json").unlink(missing_ok=True)


class TestRawColumnListValidation:
    def test_dck_accepts_and_normalizes(self):
        tokens, err = _validate_raw_column_list("PO_LINE_NUMBER, SEQ_NBR", "--dck")
        assert err is None
        assert tokens == ["PO_LINE_NUMBER", "SEQ_NBR"]

    def test_dck_rejects_bad_identifier(self):
        tokens, err = _validate_raw_column_list("1BAD", "--dck")
        assert err is not None
        assert "1BAD" in err


# ═══════════════════════════════════════════════════════════════════════════
# Group B — source_column_utils accessor / normalizer
# ═══════════════════════════════════════════════════════════════════════════

class TestSourceColumnUtils:
    def test_normalize_string(self):
        with pytest.warns(LegacySourceColumnWarning):
            assert normalize_source_column("A, B") == ["A", "B"]

    def test_normalize_list(self):
        assert normalize_source_column(["X", "Y"]) == ["X", "Y"]

    def test_normalize_none(self):
        assert normalize_source_column(None) == []

    def test_normalize_single_token_string_does_not_warn(self, recwarn):
        # A single-column legacy string is benign and must NOT spam a warning.
        assert normalize_source_column("INVOICE_ID") == ["INVOICE_ID"]
        assert not [w for w in recwarn.list if issubclass(w.category, LegacySourceColumnWarning)]

    def test_normalize_derived_sentinel(self):
        assert normalize_source_column("(DERIVED)") == ["(DERIVED)"]

    def test_normalize_strips_and_drops_empties(self):
        with pytest.warns(LegacySourceColumnWarning):
            assert normalize_source_column("  A , , B ") == ["A", "B"]

    def test_multicolumn_legacy_string_emits_deprecation_warning(self):
        with pytest.warns(LegacySourceColumnWarning):
            normalize_source_column("INVOICE_ID,LINE_NUMBER")

    def test_get_source_columns_from_dict_list(self):
        assert get_source_columns({"source_column": ["INVOICE_ID", "LINE_NUMBER"]}) == [
            "INVOICE_ID", "LINE_NUMBER"]

    def test_get_source_columns_from_dict_string(self):
        with pytest.warns(LegacySourceColumnWarning):
            assert get_source_columns({"source_column": "INVOICE_ID,LINE_NUMBER"}) == [
                "INVOICE_ID", "LINE_NUMBER"]

    def test_to_str_composite(self):
        assert source_columns_to_str(["X", "Y"]) == "X,Y"

    def test_to_str_single_is_bare_token(self):
        assert source_columns_to_str(["INVOICE_ID"]) == "INVOICE_ID"

    def test_order_is_preserved_not_sorted(self):
        # Order is load-bearing (CONCAT_WS arg order -> BK -> HKs). Never sorted.
        assert normalize_source_column(["B", "A"]) == ["B", "A"]
        with pytest.warns(LegacySourceColumnWarning):
            assert normalize_source_column("B,A") == ["B", "A"]

    def test_legacy_string_equals_list_form(self):
        with pytest.warns(LegacySourceColumnWarning):
            assert normalize_source_column("INVOICE_ID,LINE_NUMBER") == normalize_source_column(
                ["INVOICE_ID", "LINE_NUMBER"])


# ═══════════════════════════════════════════════════════════════════════════
# Group C — cross-cutting CONCAT_WS delimiter constant
# ═══════════════════════════════════════════════════════════════════════════

class TestDelimiterConstant:
    def test_constant_value(self):
        assert COMPOSITE_BK_DELIMITER == "||"

    def test_build_py_uses_same_delimiter(self):
        # build.py generates the HK CONCAT_WS with the same literal — assert they
        # do not drift (one constant, one literal, verified equal).
        build_src = (SCRIPT_DIR / "src" / "build.py").read_text()
        assert f"CONCAT_WS('{COMPOSITE_BK_DELIMITER}'" in build_src


# ═══════════════════════════════════════════════════════════════════════════
# Group D/E — end-to-end generate-yaml + XLSX for composite / single BK
# ═══════════════════════════════════════════════════════════════════════════

def _profiled_state(model_name, bk, bk_name, columns):
    steps = ["init", "profile", "approve-profile"]
    return {
        "model_name": model_name,
        "schema": "emtk_ebs_ap",
        "table": "ap_invoice_lines",
        "bk": bk,
        "bk_name": bk_name,
        "rec_src": "USWIOC.ORCL.EBSEMTK.AP_INVOICE_LINES",
        "objects": ["stg"],
        "created_at": _now_iso(),
        "steps_completed": [{"step": s, "completed_at": _now_iso()} for s in steps],
        "config_path": "",
        "xlsx_path": "",
        "xlsx_validation": {},
        "generated_files": {},
        "stage3_results": {},
        "hash_keys": [],
        "profile_results": {
            "columns": columns,
            "row_count": 500,
            "ingestion_source": "fivetran",
            "has_fivetran_deleted": True,
            "has_psa_delete_ind": True,
            "grain_valid": True,
            "volume_tier": "normal",
        },
    }


_COMPOSITE_COLUMNS = [
    {"name": "INVOICE_ID", "type": "NUMBER", "nullable": "NO"},
    {"name": "LINE_NUMBER", "type": "NUMBER", "nullable": "NO"},
    {"name": "AMOUNT", "type": "NUMBER", "nullable": "YES"},
    {"name": "_FIVETRAN_DELETED", "type": "BOOLEAN", "nullable": "YES"},
    {"name": "_FIVETRAN_SYNCED", "type": "TIMESTAMP_TZ", "nullable": "YES"},
    {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_NTZ", "nullable": "YES"},
    {"name": "PSA_RECORD_SOURCE", "type": "TEXT", "nullable": "YES"},
    {"name": "PSA_DELETE_IND", "type": "TEXT", "nullable": "YES"},
    {"name": "_FIVETRAN_ID", "type": "TEXT", "nullable": "YES"},
]


def _run_generate_yaml(state):
    model_name = state["model_name"]
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    (STATE_DIR / f"{model_name}.json").write_text(json.dumps(state, indent=2, default=str))
    args = Namespace(model_name=model_name, bk_cast=None, bk_cast_type=None)
    rc = cmd_generate_yaml(args)
    assert rc == 0
    config_name = model_name.replace("v_psa_stg_", "")
    return SCRIPT_DIR / "configs" / f"{config_name}.yml"


def _cleanup(model_name, config_path=None):
    (STATE_DIR / f"{model_name}.json").unlink(missing_ok=True)
    if config_path:
        Path(config_path).unlink(missing_ok=True)


def _bk_column(config):
    for col in config["models"][0]["columns"]:
        if str(col.get("staging_column_name", "")).endswith("_BK") and str(
                col.get("not_null", "")).lower() == "yes":
            return col
    return None


class TestCompositeYamlGeneration:
    def test_composite_source_column_is_ordered_list(self):
        model = "v_psa_stg_supplier_invoice_line__emtk_ebs"
        cfg = None
        try:
            state = _profiled_state(model, "INVOICE_ID,LINE_NUMBER",
                                    "SUPPLIER_INVOICE_LINE_BK", _COMPOSITE_COLUMNS)
            cfg = _run_generate_yaml(state)
            config = yaml.safe_load(cfg.read_text())

            bk_col = _bk_column(config)
            assert bk_col is not None
            # source_column is a list, preserving declared order.
            assert bk_col["source_column"] == ["INVOICE_ID", "LINE_NUMBER"]
            # CONCAT_WS composite uses the shared delimiter.
            assert f"CONCAT_WS('{COMPOSITE_BK_DELIMITER}'" in bk_col["manual_logic"]

            # Every column's source_column is a list (uniform shape, no bare strings).
            for col in config["models"][0]["columns"]:
                assert isinstance(col["source_column"], list), col

            # The raw-passthrough and BK-alias rows carry the SAME ordered list
            # (single normalizer — no drift between the two call sites).
            composites = [c["source_column"] for c in config["models"][0]["columns"]
                          if c["source_column"] == ["INVOICE_ID", "LINE_NUMBER"]]
            assert len(composites) == 2
        finally:
            _cleanup(model, cfg)

    def test_single_column_bk_is_list_length_one_no_concat_ws(self):
        model = "v_psa_stg_supplier_invoice_single__emtk_ebs"
        cfg = None
        try:
            state = _profiled_state(model, "INVOICE_ID", "INVOICE_BK", _COMPOSITE_COLUMNS)
            cfg = _run_generate_yaml(state)
            config = yaml.safe_load(cfg.read_text())

            bk_col = _bk_column(config)
            assert bk_col["source_column"] == ["INVOICE_ID"]
            # No composite wrapper for a single-column BK.
            assert "CONCAT_WS" not in (bk_col.get("manual_logic") or "")
        finally:
            _cleanup(model, cfg)

    def test_regenerate_is_byte_identical(self):
        model = "v_psa_stg_supplier_invoice_idem__emtk_ebs"
        cfg = None
        try:
            state = _profiled_state(model, "INVOICE_ID,LINE_NUMBER",
                                    "SUPPLIER_INVOICE_LINE_BK", _COMPOSITE_COLUMNS)
            cfg = _run_generate_yaml(state)
            first = cfg.read_bytes()
            # Re-run on unchanged state.
            cfg2 = _run_generate_yaml(state)
            assert cfg2 == cfg
            assert cfg2.read_bytes() == first
        finally:
            _cleanup(model, cfg)

    def test_legacy_string_config_read_matches_list_form(self):
        # A reader encountering a legacy comma-string source_column returns the
        # same list as the list-form equivalent (liberal reader) and signals
        # deprecation.
        legacy = {"source_column": "INVOICE_ID,LINE_NUMBER"}
        listform = {"source_column": ["INVOICE_ID", "LINE_NUMBER"]}
        with pytest.warns(LegacySourceColumnWarning):
            assert get_source_columns(legacy) == get_source_columns(listform)


class TestCompositeXlsxRendering:
    def test_xlsx_splits_composite_source_columns_and_validates(self, tmp_path):
        import openpyxl

        model = "v_psa_stg_supplier_invoice_xlsx__emtk_ebs"
        cfg = None
        try:
            state = _profiled_state(model, "INVOICE_ID,LINE_NUMBER",
                                    "SUPPLIER_INVOICE_LINE_BK", _COMPOSITE_COLUMNS)
            cfg = _run_generate_yaml(state)

            # Generate the XLSX (separate process, reads the on-disk YAML list).
            r1 = subprocess.run(
                [sys.executable, str(SCRIPT_DIR / "generate_tech_spec.py"),
                 "--config", str(cfg), "--outdir", str(tmp_path)],
                capture_output=True, text=True,
            )
            assert r1.returncode == 0, r1.stderr + r1.stdout

            xlsx_candidates = list(tmp_path.glob("*.xlsx"))
            assert xlsx_candidates, "no XLSX produced"
            xlsx_path = xlsx_candidates[0]

            # Validate — the new XLSX_COMPOSITE_BK_COLUMNS_SPLIT check must pass.
            r2 = subprocess.run(
                [sys.executable, str(SCRIPT_DIR / "validate_tech_spec.py"),
                 "--config", str(cfg), "--xlsx", str(xlsx_path)],
                capture_output=True, text=True,
            )
            assert "XLSX_COMPOSITE_BK_COLUMNS_SPLIT" not in r2.stdout, r2.stdout
            assert r2.returncode == 0, r2.stdout + r2.stderr

            # The BK-alias row's Source Column cell holds two newline-separated
            # tokens, never a comma-joined single cell.
            wb = openpyxl.load_workbook(xlsx_path)
            found_bk = False
            staging_names = set()
            for ws in wb.worksheets:
                if "Columns" not in ws.title:
                    continue
                for row in ws.iter_rows(min_row=2, values_only=True):
                    staging_names.add(row[8])
                    if (row[8] or "") == "SUPPLIER_INVOICE_LINE_BK":
                        cell = row[2] or ""
                        assert cell.split("\n") == ["INVOICE_ID", "LINE_NUMBER"]
                        assert "," not in cell
                        found_bk = True
            assert found_bk, "composite BK row not found in XLSX"
            # Passthrough rendered one row per source column (distinct staging names).
            assert "INVOICE_ID" in staging_names
            assert "LINE_NUMBER" in staging_names
            assert "INVOICE_ID,LINE_NUMBER" not in staging_names
        finally:
            _cleanup(model, cfg)
