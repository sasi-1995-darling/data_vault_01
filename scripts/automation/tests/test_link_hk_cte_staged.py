#!/usr/bin/env python3
"""
test_link_hk_cte_staged.py — Tests for CTE-staged link HK derivation (issue #1907).

Link hash keys must compose from the participating HUB HK values (DV 2.1), not
raw source columns. Because a SELECT cannot reference a sibling alias, hub HKs are
pre-computed in a HASH_STG CTE and the link HK references them in FINAL via
TO_VARCHAR(HUB_HK). This suite locks the five contracts:

  C-1  reverse-parser recovers link HK hub-HK components (TO_VARCHAR extraction,
       disjoint from the hub CAST regex) with type="link"  (+ mutation guard)
  C-2  multi-table auto-link path emits HASH_FROM_HKS (no BKCC)
  C-3  reverse-parser column extractor skips bare hub-HK passthroughs  (+ mutation)
  C-4  FINAL emitted column order is unchanged by CTE-staging
  C-5  ghost path untouched (v_psa_stg has no ghost union; covered by no-regression)

Plus: build rendering, the manual --hk @HK sigil, marker parity across paths, and
code-reviewer / Category-Q no-false-fire on the TO_VARCHAR link HK.

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_link_hk_cte_staged.py -v
"""
import json
import re
import sys
from argparse import Namespace
from collections import OrderedDict
from pathlib import Path

import pytest

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SCRIPT_DIR))
sys.path.insert(0, str(SRC_DIR))

from build import build_final_layer  # noqa: E402
from pipeline_orchestrator import (  # noqa: E402
    _recover_stg_hash_keys,
    _recover_stg_final_columns,
    cmd_init,
    cmd_generate_yaml,
    _now_iso,
    STATE_DIR,
)
from code_reviewer import (  # noqa: E402
    check_hk_uses_concat_ws,
    check_hk_coalesce_nullif_trim,
    check_hk_uses_raw_column_names,
    check_hk_bkcc_last_component,
    check_hk_has_upper_wrapper,
    check_link_hk_component_collision,
)

STG_PATH = "models/int_staging_views/shipments/v_psa_stg_order_item__winn_sap.sql"


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _col(name, src="(DERIVED)", ml="", defer=False, st=""):
    """A build_final_layer column dict."""
    return {
        "STAGING LAYER COLUMN NAME": name, "REMOVE COLUMN": "", "HASHDIFF": "",
        "SOURCE COLUMN": src, "MANUAL LOGIC": ml, "SOURCE TABLE": st,
        "DEFER_HASH": defer,
    }


def _link_columns():
    """Data col + two hub HKs + one link HK where the link precedes a hub it uses."""
    cols = OrderedDict()
    cols["1"] = _col("MANDT", src="MANDT", st="vbap")
    cols["2"] = _col("ORDER_LINE_HK", ml="HASH: VBELN, POSNR, BKCC", defer=True)
    # Link declared BEFORE ITEM_HK it references — only CTE-staging makes this legal.
    cols["3"] = _col("LNK_ORDER_ITEM_HK", ml="HASH_FROM_HKS: ORDER_LINE_HK, ITEM_HK", defer=True)
    cols["4"] = _col("ITEM_HK", ml="HASH: ITEM_BK, BKCC", defer=True)
    return cols


def _hub_only_columns():
    cols = OrderedDict()
    cols["1"] = _col("MANDT", src="MANDT", st="vbap")
    cols["2"] = _col("ORDER_LINE_HK", ml="HASH: VBELN, POSNR, BKCC", defer=True)
    return cols


def _final(cols):
    return build_final_layer({"t": [{}]}, cols, "STG", "JOIN_RESULT")


def _hk_body(sql, hk_name):
    """Isolate one HK's CONCAT_WS body. The body excludes nested MD5_BINARY so the
    match starts at the closest MD5_BINARY before the alias (not an earlier
    HASH_STG hub HK)."""
    m = re.search(
        r"MD5_BINARY\(UPPER\(CONCAT_WS\('\|\|',((?:(?!MD5_BINARY).)*?)\)\)\)\s*as\s+"
        + re.escape(hk_name),
        sql, re.IGNORECASE | re.DOTALL,
    )
    assert m is not None, f"HK block not found: {hk_name}"
    return m.group(1)


def _cleanup_state(model_name):
    f = STATE_DIR / f"{model_name}.json"
    if f.exists():
        f.unlink()


def _init_args(model_name, hk):
    """Full cmd_init Namespace (all flags defaulted, only model + hk vary)."""
    return Namespace(
        model_name=model_name, schema="test_schema", table="test_table",
        bk="ID", bk_name="TEST_BK", rec_src="US.TEST.APP.TABLE", objects="stg",
        force=True, hk=hk, lnk_name=None, parent_hks=None, dck=None, sat_type=None,
        sat_parent_hk=None, sat_parent_model=None, multi_active_key=None,
        sat_name=None, sat_columns=None, grain_columns=None, secondary_schema=None,
        secondary_table=None, secondary_alias=None, secondary_join_type=None,
        secondary_columns=None, sec_bk=None, sec_bk_name=None, sec_bk_expr=None,
        sec_join_key=None, sec_parent_join_key=None,
    )


def _load_state(model_name):
    return json.loads((STATE_DIR / f"{model_name}.json").read_text())


# ─────────────────────────────────────────────────────────────────────────────
# build_final_layer rendering
# ─────────────────────────────────────────────────────────────────────────────

class TestBuildRendering:

    def test_hub_hks_moved_to_hash_stg_cte(self):
        sql = _final(_link_columns())
        assert ", HASH_STG as (" in sql
        assert "SELECT JOIN_RESULT.*" in sql
        # Hub HKs are computed (raw-col form) inside HASH_STG.
        assert "as ORDER_LINE_HK" in sql.split("---- FINAL LAYER ----")[0]
        assert "as ITEM_HK" in sql.split("---- FINAL LAYER ----")[0]
        # FINAL reads from the staging CTE.
        assert "FROM HASH_STG" in sql

    def test_link_hk_composes_from_hub_hks_via_to_varchar(self):
        sql = _final(_link_columns())
        final = sql.split("---- FINAL LAYER ----")[1]
        assert "TO_VARCHAR(ORDER_LINE_HK)" in final
        assert "TO_VARCHAR(ITEM_HK)" in final
        assert "as LNK_ORDER_ITEM_HK" in final

    def test_link_hk_has_no_bkcc(self):
        """Links carry no BKCC — each hub HK already embeds its own (KB 07)."""
        body = _hk_body(_final(_link_columns()), "LNK_ORDER_ITEM_HK")
        assert "BKCC" not in body

    def test_link_hk_is_standard_shape(self):
        sql = _final(_link_columns())
        assert "MD5_BINARY(UPPER(CONCAT_WS('||'," in sql

    def test_column_order_preserved_c4(self):
        """FINAL emits columns in declared order; link at pos-3 references a
        later hub — proving order is unchanged by CTE-staging."""
        final = _final(_link_columns()).split("---- FINAL LAYER ----")[1]

        def _pos(pat):
            m = re.search(pat, final, re.MULTILINE)
            assert m is not None, pat
            return m.start()

        order = [
            _pos(r"^\s*MANDT\s*$"),
            _pos(r"^\s*,\s*ORDER_LINE_HK\s*$"),
            _pos(r"as LNK_ORDER_ITEM_HK"),
            _pos(r"^\s*,\s*ITEM_HK\s*$"),
        ]
        assert order == sorted(order)

    def test_hub_hk_emitted_as_passthrough_in_final(self):
        sql = _final(_link_columns())
        final = sql.split("---- FINAL LAYER ----")[1]
        # Hub HK appears as a bare passthrough (no MD5 recompute) in FINAL.
        assert re.search(r"^\s*,\s*ORDER_LINE_HK\s*$", final, re.MULTILINE)

    def test_no_link_path_is_legacy_inline(self):
        """Hub/sat-only models must be byte-identical to the pre-#1907 form."""
        sql = _final(_hub_only_columns())
        assert "HASH_STG" not in sql
        assert "FROM JOIN_RESULT" in sql
        assert "TO_VARCHAR(" not in sql
        # Hub HK stays inline in FINAL.
        assert "as ORDER_LINE_HK" in sql.split("---- FINAL LAYER ----")[1]


# ─────────────────────────────────────────────────────────────────────────────
# C-1: reverse-parser HK recovery (round-trip + mutation)
# ─────────────────────────────────────────────────────────────────────────────

class TestReverseParserHashKeys:

    def test_roundtrip_recovers_link_and_hubs(self):
        sql = _final(_link_columns())
        hks = {h["name"]: h for h in _recover_stg_hash_keys(sql)}
        assert hks["ORDER_LINE_HK"]["columns"] == ["VBELN", "POSNR", "BKCC"]
        assert hks["ORDER_LINE_HK"]["type"] is None
        assert hks["ITEM_HK"]["columns"] == ["ITEM_BK", "BKCC"]
        # Link recovered with its participating HUB HK names + type="link".
        assert hks["LNK_ORDER_ITEM_HK"]["columns"] == ["ORDER_LINE_HK", "ITEM_HK"]
        assert hks["LNK_ORDER_ITEM_HK"]["type"] == "link"

    def test_link_not_misrecovered_as_raw_hub(self):
        """The general _HK regex sees the link block but CAST extraction is empty,
        so it is NOT added as a raw-column hub HK (only the link loop adds it)."""
        sql = _final(_link_columns())
        recovered = [h for h in _recover_stg_hash_keys(sql) if h["name"] == "LNK_ORDER_ITEM_HK"]
        assert len(recovered) == 1
        assert recovered[0]["type"] == "link"

    def test_mutation_legacy_cast_regex_silently_misses_link(self):
        """Non-vacuous guard for C-1: the legacy CAST(...) extraction returns []
        on the new TO_VARCHAR link body — a silent break — while TO_VARCHAR
        extraction recovers the hub-HK names. Proves the fix is load-bearing."""
        body = _hk_body(_final(_link_columns()), "LNK_ORDER_ITEM_HK")
        legacy_cast = re.findall(r"CAST\((\w+)\s+as\s+VARCHAR\)", body, re.IGNORECASE)
        new_to_varchar = re.findall(r"TO_VARCHAR\((\w+)\)", body, re.IGNORECASE)
        assert legacy_cast == []                               # silent miss
        assert new_to_varchar == ["ORDER_LINE_HK", "ITEM_HK"]  # correct recovery

    def test_hub_hk_body_has_no_to_varchar(self):
        """Disjointness the other way: hub HK bodies contain CAST, never TO_VARCHAR."""
        body = _hk_body(_final(_link_columns()), "ORDER_LINE_HK")
        assert "TO_VARCHAR(" not in body
        assert re.findall(r"CAST\((\w+)\s+as\s+VARCHAR\)", body, re.IGNORECASE)


# ─────────────────────────────────────────────────────────────────────────────
# C-3: reverse-parser column extractor
# ─────────────────────────────────────────────────────────────────────────────

class TestReverseParserColumns:

    def test_data_col_recovered_hub_hk_passthrough_skipped(self):
        sql = _final(_link_columns())
        names = [c["name"] for c in _recover_stg_final_columns(sql)]
        assert "MANDT" in names
        assert "ORDER_LINE_HK" not in names
        assert "ITEM_HK" not in names

    def test_data_col_ending_hk_kept_only_derived_skipped(self):
        """PR #1950 review: skip only bare passthroughs ACTUALLY derived as HKs
        (`as <NAME>_HK` in HASH_STG/FINAL); a data column that merely ends in _HK is
        kept. A suffix-only heuristic would wrongly drop both — this proves precision."""
        sql = (
            ", HASH_STG as (\n    SELECT JOIN_RESULT.*\n"
            "        , MD5_BINARY(UPPER(CONCAT_WS('||',"
            " COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''),'^^')))) as ORDER_LINE_HK\n"
            "    FROM JOIN_RESULT\n)\n"
            "---- FINAL LAYER ----\nSELECT\n          MANDT\n"
            "        , LEGACY_SOURCE_HK\n"   # data col ending _HK, never derived
            "        , ORDER_LINE_HK\n"       # derived hub HK passthrough
            "        , MD5_BINARY(UPPER(CONCAT_WS('||', TO_VARCHAR(ORDER_LINE_HK)))) as LNK_X_HK\n"
            "FROM HASH_STG\n"
        )
        names = [c["name"] for c in _recover_stg_final_columns(sql)]
        assert "MANDT" in names
        assert "LEGACY_SOURCE_HK" in names   # not derived → kept (the fix)
        assert "ORDER_LINE_HK" not in names   # derived hub HK → skipped

    def test_no_final_layer_returns_empty(self):
        assert _recover_stg_final_columns("WITH SRC as (select 1)") == []


# ─────────────────────────────────────────────────────────────────────────────
# Manual --hk @HK sigil (parity with the auto path)
# ─────────────────────────────────────────────────────────────────────────────

class TestHkSigil:

    def test_sigil_marks_link_and_strips_at(self):
        model = "v_psa_stg_test_1907_sigil__x"
        try:
            rc = cmd_init(_init_args(model, ["LNK_ORDER_ITEM_HK:@ORDER_LINE_HK,@ITEM_HK"]))
            assert rc == 0
            hks = {h["name"]: h for h in _load_state(model)["hash_keys"]}
            assert hks["LNK_ORDER_ITEM_HK"]["type"] == "link"
            assert hks["LNK_ORDER_ITEM_HK"]["columns"] == ["ORDER_LINE_HK", "ITEM_HK"]
        finally:
            _cleanup_state(model)

    def test_raw_cols_stay_hub_type_none(self):
        model = "v_psa_stg_test_1907_raw__x"
        try:
            rc = cmd_init(_init_args(model, ["SUPPLIER_HK:LIFNR,BKCC"]))
            assert rc == 0
            hks = {h["name"]: h for h in _load_state(model)["hash_keys"]}
            assert hks["SUPPLIER_HK"]["type"] is None
            assert hks["SUPPLIER_HK"]["columns"] == ["LIFNR", "BKCC"]
        finally:
            _cleanup_state(model)

    def test_mixing_sigil_and_raw_rejected(self):
        model = "v_psa_stg_test_1907_mix__x"
        try:
            rc = cmd_init(_init_args(model, ["LNK_X_HK:@ORDER_LINE_HK,POSNR"]))
            assert rc == 1
        finally:
            _cleanup_state(model)

    def test_sigil_requires_lnk_name(self):
        """PR #1950 review: @HK references need a LNK_ link name — init-rv only
        recovers TO_VARCHAR HKs under lnk_hk_pattern (LNK_ prefix)."""
        model = "v_psa_stg_test_1907_nonlnk__x"
        try:
            rc = cmd_init(_init_args(model, ["SUPPLIER_HK:@VENDOR_HK,@SITE_HK"]))
            assert rc == 1
        finally:
            _cleanup_state(model)

    def test_sigil_components_must_be_hks(self):
        """PR #1950 review: @HK references must be hub HK columns ending in _HK."""
        model = "v_psa_stg_test_1907_badcomp__x"
        try:
            rc = cmd_init(_init_args(model, ["LNK_X_HK:@ORDER_LINE_HK,@RAW_COL"]))
            assert rc == 1
        finally:
            _cleanup_state(model)

    def test_sigil_components_reject_link_hk(self):
        """PR #1950 review (2nd pass): a link HK cannot compose from another link HK
        (@LNK_*) — components must be hub HKs. Without this guard it passes input and
        fails only at build (FINAL sibling-alias ref), not fail-fast."""
        model = "v_psa_stg_test_1907_linkcomp__x"
        try:
            rc = cmd_init(_init_args(model, ["LNK_A_HK:@ORDER_LINE_HK,@LNK_B_HK"]))
            assert rc == 1
        finally:
            _cleanup_state(model)


# ─────────────────────────────────────────────────────────────────────────────
# Marker parity: type="link" hash_key → HASH_FROM_HKS in generated YAML
# (the additional-HK loop shared by the @sigil and reverse-parser recovery paths)
# ─────────────────────────────────────────────────────────────────────────────

class TestMarkerParity:

    def _profiled_state(self, model_name, hash_keys):
        return {
            "model_name": model_name, "schema": "test_schema", "table": "test_table",
            "bk": "ID", "bk_name": "TEST_BK", "rec_src": "US.TEST.APP.TABLE",
            "objects": ["stg"], "created_at": _now_iso(),
            "steps_completed": [
                {"step": s, "completed_at": _now_iso()}
                for s in ("init", "profile", "approve-profile")
            ],
            "config_path": "", "xlsx_path": "", "xlsx_validation": {},
            "generated_files": {}, "stage3_results": {}, "hash_keys": hash_keys,
            "profile_results": {
                "row_count": 100, "volume_tier": "normal", "column_count": 5,
                "null_bk_count": 0, "grain_valid": True, "bkcc": "TestBKCC",
                "ingestion_source": "fivetran", "source_registered": True,
                "has_fivetran_deleted": True, "has_psa_delete_ind": True,
                "has_fivetran_synced": True, "has_fivetran_id": True,
                "collision_check": {"blocked": False, "layers": {}},
                "columns": [
                    {"name": "ID", "type": "NUMBER", "nullable": "NO"},
                    {"name": "ITEM_ID", "type": "NUMBER", "nullable": "YES"},
                    {"name": "_FIVETRAN_SYNCED", "type": "TIMESTAMP_TZ", "nullable": "YES"},
                    {"name": "_FIVETRAN_DELETED", "type": "BOOLEAN", "nullable": "YES"},
                    {"name": "_FIVETRAN_ID", "type": "TEXT", "nullable": "YES"},
                    {"name": "PSA_DELETE_IND", "type": "TEXT", "nullable": "YES"},
                    {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_NTZ", "nullable": "YES"},
                    {"name": "PSA_RECORD_SOURCE", "type": "TEXT", "nullable": "YES"},
                ],
            },
        }

    def _generate(self, model_name, hash_keys):
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        (STATE_DIR / f"{model_name}.json").write_text(
            json.dumps(self._profiled_state(model_name, hash_keys), indent=2, default=str)
        )
        rc = cmd_generate_yaml(Namespace(model_name=model_name, bk_cast=None, bk_cast_type=None))
        assert rc == 0
        import yaml
        cfg_path = SCRIPT_DIR / "configs" / f"{model_name.replace('v_psa_stg_', '')}.yml"
        cfg = yaml.safe_load(cfg_path.read_text())
        cfg_path.unlink(missing_ok=True)
        return cfg["models"][0]["columns"]

    def test_link_type_hash_key_emits_hash_from_hks(self):
        model = "v_psa_stg_test_1907_parity__x"
        try:
            cols = self._generate(model, [
                {"name": "ITEM_HK", "columns": ["ITEM_ID", "BKCC"], "type": None},
                {"name": "LNK_ORDER_ITEM_HK", "columns": ["TEST_HK", "ITEM_HK"], "type": "link"},
            ])
            by_name = {c.get("staging_column_name"): c for c in cols}
            assert by_name["LNK_ORDER_ITEM_HK"]["manual_logic"] == "HASH_FROM_HKS: TEST_HK, ITEM_HK"
            # A hub HK still uses the raw-column HASH: form.
            assert by_name["ITEM_HK"]["manual_logic"] == "HASH: ITEM_ID, BKCC"
        finally:
            _cleanup_state(model)


# ─────────────────────────────────────────────────────────────────────────────
# Validators: the TO_VARCHAR link HK must not trip HK checks or Category Q1
# ─────────────────────────────────────────────────────────────────────────────

class TestValidatorsNoFalseFire:

    def _sql(self):
        # A minimal int_staging_views-shaped model carrying both hub + link HKs.
        return _final(_link_columns())

    def test_category_a_checks_pass(self):
        sql = self._sql()
        assert check_hk_uses_concat_ws(sql, STG_PATH) == []      # A1
        assert check_hk_coalesce_nullif_trim(sql, STG_PATH) == []  # A2
        assert check_hk_uses_raw_column_names(sql, STG_PATH) == []  # A3
        assert check_hk_bkcc_last_component(sql, STG_PATH) == []    # A4 (link has no BKCC → skipped)
        assert check_hk_has_upper_wrapper(sql, STG_PATH) == []      # A5

    def test_q1_no_component_collision_for_link(self):
        """Q1/TRAP-01: the TO_VARCHAR link HK has no raw components, so it cannot
        byte-collide with a hub HK — the #1907 fix resolves the trap for links."""
        assert check_link_hk_component_collision(self._sql(), STG_PATH) == []
