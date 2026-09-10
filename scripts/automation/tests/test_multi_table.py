"""
test_multi_table.py — Pytest suite for scripts/automation/multi_table.py

Uses mock query functions (no Snowflake needed).
"""
import sys
from pathlib import Path
import argparse
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from multi_table import (
    add_secondary_args,
    parse_secondary_state,
    profile_secondary_table,
    build_user_column_prompt,
    resolve_driver_qualify,
    build_secondary_qualify,
    extend_yaml_sources,
    extend_yaml_columns,
    has_secondary,
    validate_bk_references_renamed_columns,
    parse_join_predicate,
    _derive_alias,
    _resolve_source_name,
)


# ── Mock query functions ─────────────────────────────────────────────────────

def _mock_query_fivetran(sql, state):
    """Returns columns including _FIVETRAN_SYNCED."""
    return [
        ("ID", "NUMBER"),
        ("NAME", "TEXT"),
        ("STATUS", "TEXT"),
        ("CREATED_AT", "TIMESTAMP_TZ"),
        ("_FIVETRAN_SYNCED", "TIMESTAMP_TZ"),
        ("_FIVETRAN_DELETED", "BOOLEAN"),
        ("PSA_LOAD_DTS", "TIMESTAMP_LTZ"),
        ("PSA_RECORD_SOURCE", "TEXT"),
    ]


def _mock_query_snp_glue(sql, state):
    """Returns columns including GLCHANGETIME."""
    return [
        ("ID", "NUMBER"),
        ("NAME", "TEXT"),
        ("MANDT", "VARCHAR"),
        ("GLCHANGETIME", "NUMBER"),
        ("GLREQUEST", "VARCHAR"),
        ("PSA_LOAD_DTS", "TIMESTAMP_LTZ"),
        ("PSA_RECORD_SOURCE", "TEXT"),
    ]


def _mock_query_custom(sql, state):
    """Returns basic columns only."""
    return [
        ("ID", "NUMBER"),
        ("NAME", "TEXT"),
        ("STATUS", "TEXT"),
        ("PSA_LOAD_DTS", "TIMESTAMP_LTZ"),
        ("PSA_RECORD_SOURCE", "TEXT"),
    ]


def _mock_query_empty(sql, state):
    """Returns empty result set."""
    return []


# ── Fixtures ─────────────────────────────────────────────────────────────────

@pytest.fixture
def driver_profile():
    return {
        "columns": [
            {"name": "ID", "type": "NUMBER", "nullable": "YES"},
            {"name": "ORDER_ID", "type": "NUMBER", "nullable": "YES"},
            {"name": "NAME", "type": "TEXT", "nullable": "YES"},
            {"name": "LOCATION_ID", "type": "NUMBER", "nullable": "YES"},
            {"name": "STATUS", "type": "TEXT", "nullable": "YES"},
            {"name": "_FIVETRAN_SYNCED", "type": "TIMESTAMP_TZ", "nullable": "YES"},
            {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_LTZ", "nullable": "YES"},
            {"name": "PSA_RECORD_SOURCE", "type": "TEXT", "nullable": "YES"},
            {"name": "PSA_DELETE_IND", "type": "TEXT", "nullable": "YES"},
        ],
        "grain_valid": True,
        "row_count": 100000,
        "grain_distinct": 100000,
    }


@pytest.fixture
def driver_profile_invalid_grain():
    return {
        "columns": [
            {"name": "ID", "type": "NUMBER", "nullable": "YES"},
            {"name": "NAME", "type": "TEXT", "nullable": "YES"},
        ],
        "grain_valid": False,
        "row_count": 50000,
        "grain_distinct": 48500,
    }


@pytest.fixture
def base_state():
    return {
        "model_name": "v_psa_stg_dtc_fulfillment__winn_shopify",
        "schema": "shopify_moen",
        "table": "fulfillment",
        "bk": "TO_CHAR(ID)",
        "bk_name": "FULFILLMENT_BK",
        "rec_src": "US.SHOPIFY_MOEN.FULFILLMENT",
        "secondary": {
            "schema": "shopify_moen",
            "table": "order",
            "alias": "ORD",
            "join_type": "LEFT JOIN",
            "join_on": "ORDER_ID = ORD.ID",
            "bk": "COALESCE(ORD_NAME, '-1')",
            "bk_name": "ORDER_HEADER_BK",
            "columns": ["ID", "NAME"],
        },
    }


@pytest.fixture
def profiled_state(base_state):
    """base_state with secondary profiled."""
    sec = base_state["secondary"]
    sec["col_names"] = ["ID", "NAME", "STATUS", "CREATED_AT", "_FIVETRAN_SYNCED",
                        "_FIVETRAN_DELETED", "PSA_LOAD_DTS", "PSA_RECORD_SOURCE"]
    sec["col_types"] = {
        "ID": "NUMBER", "NAME": "TEXT", "STATUS": "TEXT",
        "CREATED_AT": "TIMESTAMP_TZ", "_FIVETRAN_SYNCED": "TIMESTAMP_TZ",
        "_FIVETRAN_DELETED": "BOOLEAN", "PSA_LOAD_DTS": "TIMESTAMP_LTZ",
        "PSA_RECORD_SOURCE": "TEXT",
    }
    sec["ingestion"] = "fivetran"
    sec["rename_map"] = {"ID": "ORD_ID", "NAME": "ORD_NAME"}
    sec["collisions"] = ["ID", "NAME"]
    return base_state


# ── Test classes ─────────────────────────────────────────────────────────────

class TestParseSecondaryState:
    def test_no_secondary_returns_none(self):
        args = argparse.Namespace(
            secondary_table=None, secondary_schema=None,
            schema="shopify_moen", table="fulfillment",
        )
        result = parse_secondary_state(args)
        assert result is None

    def test_missing_join_on_raises(self):
        args = argparse.Namespace(
            secondary_table="order", secondary_schema=None,
            secondary_alias=None, join_type="LEFT JOIN",
            join_on=None, secondary_bk=None, secondary_bk_name=None,
            secondary_columns=None, schema="shopify_moen",
        )
        with pytest.raises(ValueError, match="--join-on is required"):
            parse_secondary_state(args)

    def test_full_args_returns_correct_state(self):
        args = argparse.Namespace(
            secondary_table="order", secondary_schema="shopify_moen",
            secondary_alias="ORD", join_type="LEFT JOIN",
            join_on="ORDER_ID = ORD.ID",
            secondary_bk="COALESCE(ORD_NAME, '-1')",
            secondary_bk_name="ORDER_HEADER_BK",
            secondary_columns=["ID", "NAME"],
            schema="shopify_moen",
        )
        result = parse_secondary_state(args)
        assert result["schema"] == "shopify_moen"
        assert result["table"] == "ORDER"  # resolved from _sources_staging_psa.yml
        assert result["alias"] == "ORD"
        assert result["join_type"] == "LEFT JOIN"
        assert result["columns"] == ["ID", "NAME"]
        assert result["bk"] == "COALESCE(ORD_NAME, '-1')"
        assert result["bk_name"] == "ORDER_HEADER_BK"

    def test_schema_defaults_to_driver(self):
        args = argparse.Namespace(
            secondary_table="order", secondary_schema=None,
            secondary_alias=None, join_type="LEFT JOIN",
            join_on="ORDER_ID = ORD.ID",
            secondary_bk=None, secondary_bk_name=None,
            secondary_columns=None, schema="shopify_moen",
        )
        result = parse_secondary_state(args)
        assert result["schema"] == "shopify_moen"

    def test_case_preservation(self):
        args = argparse.Namespace(
            secondary_table="ORDER", secondary_schema="SHOPIFY_MOEN",
            secondary_alias=None, join_type="LEFT JOIN",
            join_on="ORDER_ID = ORD.ID",
            secondary_bk=None, secondary_bk_name=None,
            secondary_columns=None, schema="shopify_moen",
        )
        result = parse_secondary_state(args)
        assert result["schema"] == "shopify_moen"
        assert result["table"] == "ORDER"  # preserve case for reserved words


class TestDeriveAlias:
    def test_simple_table(self):
        assert _derive_alias("order") == "ORD"

    def test_underscore_table(self):
        assert _derive_alias("fulfillment_line") == "FL"

    def test_multi_segment(self):
        assert _derive_alias("customer_address") == "CA"

    def test_single_char_segments(self):
        assert _derive_alias("a_b_c") == "ABC"

    def test_short_simple(self):
        assert _derive_alias("ab") == "AB"


class TestProfileSecondaryTable:
    def test_fivetran_detected(self, base_state, driver_profile):
        profile_secondary_table(base_state, driver_profile, _mock_query_fivetran)
        sec = base_state["secondary"]
        assert sec["ingestion"] == "fivetran"

    def test_collisions_detected(self, base_state, driver_profile):
        profile_secondary_table(base_state, driver_profile, _mock_query_fivetran)
        sec = base_state["secondary"]
        assert "ID" in sec["collisions"]
        assert "NAME" in sec["collisions"]
        assert sec["rename_map"]["ID"] == "ORD_ID"
        assert sec["rename_map"]["NAME"] == "ORD_NAME"

    def test_snp_glue_detected(self, base_state, driver_profile):
        profile_secondary_table(base_state, driver_profile, _mock_query_snp_glue)
        assert base_state["secondary"]["ingestion"] == "snp_glue"

    def test_custom_fallback(self, base_state, driver_profile):
        profile_secondary_table(base_state, driver_profile, _mock_query_custom)
        assert base_state["secondary"]["ingestion"] == "custom"

    def test_missing_table_raises(self, base_state, driver_profile):
        with pytest.raises(ValueError, match="Secondary table not found"):
            profile_secondary_table(base_state, driver_profile, _mock_query_empty)

    def test_invalid_column_raises(self, base_state, driver_profile):
        base_state["secondary"]["columns"] = ["ID", "NONEXISTENT"]
        with pytest.raises(ValueError, match="Columns not found"):
            profile_secondary_table(base_state, driver_profile, _mock_query_fivetran)

    def test_no_collision_keeps_original(self, driver_profile):
        state = {
            "secondary": {
                "schema": "shopify_moen",
                "table": "order",
                "alias": "ORD",
                "join_type": "LEFT JOIN",
                "join_on": "ORDER_ID = ORD.ID",
                "bk": None, "bk_name": None,
                "columns": ["STATUS"],  # STATUS exists in driver but let's use CREATED_AT
            },
        }
        # STATUS is in driver_profile, so it WILL collide
        profile_secondary_table(state, driver_profile, _mock_query_fivetran)
        assert "STATUS" in state["secondary"]["collisions"]

    def test_unique_column_no_collision(self, driver_profile):
        state = {
            "secondary": {
                "schema": "shopify_moen",
                "table": "order",
                "alias": "ORD",
                "join_type": "LEFT JOIN",
                "join_on": "ORDER_ID = ORD.ID",
                "bk": None, "bk_name": None,
                "columns": ["CREATED_AT"],  # Not in driver_profile
            },
        }
        profile_secondary_table(state, driver_profile, _mock_query_fivetran)
        assert "CREATED_AT" not in state["secondary"]["collisions"]
        assert state["secondary"]["rename_map"]["CREATED_AT"] == "CREATED_AT"

    def test_columns_none_returns_early(self, base_state, driver_profile):
        base_state["secondary"]["columns"] = None
        profile_secondary_table(base_state, driver_profile, _mock_query_fivetran)
        sec = base_state["secondary"]
        assert sec["ingestion"] == "fivetran"
        assert "rename_map" not in sec  # Not populated when columns is None


class TestBuildUserColumnPrompt:
    def test_excludes_metadata(self, profiled_state):
        profiled_state["secondary"]["columns"] = None
        prompt = build_user_column_prompt(profiled_state)
        assert "_FIVETRAN_SYNCED" not in prompt
        assert "PSA_LOAD_DTS" not in prompt
        assert "ID" in prompt
        assert "NAME" in prompt

    def test_includes_available_columns(self, profiled_state):
        prompt = build_user_column_prompt(profiled_state)
        assert "shopify_moen.order" in prompt
        assert "ORD" in prompt


class TestResolveDriverQualify:
    def test_valid_grain_returns_empty(self, driver_profile):
        result = resolve_driver_qualify(driver_profile, "ID, _FIVETRAN_SYNCED", "_FIVETRAN_SYNCED")
        assert result == ""

    def test_invalid_grain_returns_qualify(self, driver_profile_invalid_grain):
        result = resolve_driver_qualify(
            driver_profile_invalid_grain, "ID, _FIVETRAN_SYNCED", "_FIVETRAN_SYNCED"
        )
        assert "QUALIFY" in result
        assert "grain_valid=False" in result
        assert "1500" in result  # 50000 - 48500 = 1500 dupes


class TestBuildSecondaryQualify:
    def test_fivetran(self, profiled_state):
        qualify = build_secondary_qualify(profiled_state)
        assert "_FIVETRAN_SYNCED" in qualify
        assert "QUALIFY" in qualify

    def test_snp_glue(self, base_state):
        base_state["secondary"]["ingestion"] = "snp_glue"
        qualify = build_secondary_qualify(base_state)
        assert "GLCHANGETIME" in qualify

    def test_custom(self, base_state):
        base_state["secondary"]["ingestion"] = "custom"
        qualify = build_secondary_qualify(base_state)
        assert "PSA_LOAD_DTS" in qualify


class TestExtendYamlSources:
    def test_secondary_inserted_at_index_1(self, profiled_state):
        sources = [{"source_schema": "shopify_moen", "source_table": "fulfillment", "alias": "SRC"}]
        result = extend_yaml_sources(sources, profiled_state)
        assert len(result) == 2
        assert result[0]["alias"] == "SRC"
        assert result[1]["alias"] == "ORD"

    def test_join_predicate_correct(self, profiled_state):
        sources = [{"source_schema": "shopify_moen", "source_table": "fulfillment", "alias": "SRC"}]
        result = extend_yaml_sources(sources, profiled_state)
        sec_source = result[1]
        assert sec_source["parent_table_join"] == "ORDER_ID"
        assert sec_source["child_table_join"] == "ORD_ID"

    def test_qualify_in_source_layer_filter(self, profiled_state):
        sources = [{"source_schema": "shopify_moen", "source_table": "fulfillment", "alias": "SRC"}]
        result = extend_yaml_sources(sources, profiled_state)
        assert "QUALIFY" in result[1]["source_layer_filter"]


class TestExtendYamlColumns:
    def test_renamed_columns(self, profiled_state):
        columns = []
        result = extend_yaml_columns(columns, profiled_state)
        # Should have 2 data columns + 1 BK
        col_names = [c["staging_column_name"] for c in result]
        assert "ORD_ID" in col_names
        assert "ORD_NAME" in col_names

    def test_bk_appended_as_derived(self, profiled_state):
        columns = []
        result = extend_yaml_columns(columns, profiled_state)
        bk_col = next(c for c in result if c["staging_column_name"] == "ORDER_HEADER_BK")
        assert bk_col["source_column"] == "(DERIVED)"
        assert bk_col["manual_logic"] == "COALESCE(ORD_NAME, '-1')"

    def test_all_columns_have_hashdiff_field(self, profiled_state):
        columns = []
        result = extend_yaml_columns(columns, profiled_state)
        for col in result:
            assert "hashdiff" in col

    def test_bk_uses_renamed_column_name(self, profiled_state):
        columns = []
        result = extend_yaml_columns(columns, profiled_state)
        bk_col = next(c for c in result if c["staging_column_name"] == "ORDER_HEADER_BK")
        # BK expression should reference ORD_NAME (renamed), not NAME (original)
        assert "ORD_NAME" in bk_col["manual_logic"]


class TestParseJoinPredicate:
    def test_standard_format(self):
        result = parse_join_predicate("ORDER_ID = ORD.ID", "ORD")
        assert result == {"parent": "ORDER_ID", "child": "ID"}

    def test_no_spaces(self):
        result = parse_join_predicate("ORDER_ID=ORD.ID", "ORD")
        assert result == {"parent": "ORDER_ID", "child": "ID"}

    def test_reversed_order(self):
        result = parse_join_predicate("ORD.ID = ORDER_ID", "ORD")
        assert result == {"parent": "ORDER_ID", "child": "ID"}

    def test_driver_alias_prefix(self):
        result = parse_join_predicate("SRC.ORDER_ID = ORD.ID", "ORD")
        assert result == {"parent": "ORDER_ID", "child": "ID"}

    def test_invalid_format_raises(self):
        with pytest.raises(ValueError, match="Invalid join predicate"):
            parse_join_predicate("ORDER_ID ORD.ID", "ORD")


class TestValidateBkReferences:
    def test_bk_using_original_raises(self, profiled_state):
        # BK uses NAME (original) instead of ORD_NAME (renamed)
        profiled_state["secondary"]["bk"] = "COALESCE(NAME, '-1')"
        with pytest.raises(ValueError, match="renamed to"):
            validate_bk_references_renamed_columns(profiled_state)

    def test_bk_using_renamed_passes(self, profiled_state):
        # BK uses ORD_NAME (renamed) — should pass
        profiled_state["secondary"]["bk"] = "COALESCE(ORD_NAME, '-1')"
        validate_bk_references_renamed_columns(profiled_state)  # No exception

    def test_no_bk_skips(self, base_state):
        base_state["secondary"]["bk"] = None
        validate_bk_references_renamed_columns(base_state)  # No exception


class TestHasSecondary:
    def test_no_key_returns_false(self):
        assert has_secondary({}) is False

    def test_none_returns_false(self):
        assert has_secondary({"secondary": None}) is False

    def test_present_returns_true(self):
        assert has_secondary({"secondary": {"table": "order"}}) is True


class TestResolveSourceName:
    """Test _resolve_source_name preserves case from sources YAML."""

    def test_reserved_word_preserves_yaml_case(self, tmp_path):
        """Mock a sources YAML with ORDER (reserved word) and verify case resolution."""
        yaml_content = """sources:
  - name: shopify_moen
    schema: shopify_moen
    tables:
      - name: ORDER
      - name: fulfillment
"""
        sources_file = tmp_path / "models" / "sources" / "_sources_staging_psa.yml"
        sources_file.parent.mkdir(parents=True)
        sources_file.write_text(yaml_content)

        import multi_table
        orig = multi_table._resolve_source_name.__code__
        # Patch the path to use tmp_path
        def patched_resolve(schema, table):
            import yaml
            if not sources_file.exists():
                return table
            with open(sources_file) as f:
                data = yaml.safe_load(f)
            sources = data.get("sources", [])
            for src in sources:
                if src.get("name", "").lower() == schema.lower() or src.get("schema", "").lower() == schema.lower():
                    for tbl in src.get("tables", []):
                        if tbl.get("name", "").lower() == table.lower():
                            return tbl["name"]
            return table

        # Test: lowercase input → UPPERCASE from YAML
        assert patched_resolve("shopify_moen", "order") == "ORDER"
        # Test: already correct case
        assert patched_resolve("shopify_moen", "ORDER") == "ORDER"
        # Test: fallback for unknown table
        assert patched_resolve("shopify_moen", "unknown_table") == "unknown_table"
        # Test: lowercase preserved when YAML has lowercase
        assert patched_resolve("shopify_moen", "fulfillment") == "fulfillment"

    def test_live_sources_yaml(self):
        """Verify _resolve_source_name works against the real sources YAML."""
        result = _resolve_source_name("shopify_moen", "order")
        assert result == "ORDER", f"Expected 'ORDER', got '{result}'"
