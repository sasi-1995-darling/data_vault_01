"""
test_hub_add_source.py — Tests for multi-source hub parser and add-source logic.

Step 1: _parse_existing_hub — validates parsing of existing hub SQL.
Steps 2-3: _derive_source_alias + _build_add_source_column_mapping.
Steps 4-5: _generate_add_source_ctes (watermark + CTE generation).
Step 6: _insert_source_into_hub (surgical SQL edit).
"""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pipeline_orchestrator import (
    _parse_existing_hub,
    _parse_select_columns,
    _parse_logic_columns,
    _extract_hub_final_columns,
    _extract_final_qualify_columns,
    _extract_ghost_block,
    _derive_source_alias,
    _build_add_source_column_mapping,
    _generate_add_source_ctes,
    _insert_source_into_hub,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent


# ---------------------------------------------------------------------------
# _parse_select_columns tests
# ---------------------------------------------------------------------------

class TestParseSelectColumns:

    def test_simple_columns(self):
        assert _parse_select_columns("COL_A, COL_B, COL_C") == ["COL_A", "COL_B", "COL_C"]

    def test_with_aliases(self):
        assert _parse_select_columns("EBELN as PO_HEADER_ID, EBELP as PO_LINE_NUMBER") == [
            "PO_HEADER_ID", "PO_LINE_NUMBER"
        ]

    def test_with_cast_and_alias(self):
        assert _parse_select_columns("PO_HEADER_ID::TEXT as PO_HEADER_ID, LINE_NUM") == [
            "PO_HEADER_ID", "LINE_NUM"
        ]

    def test_multiline(self):
        text = """
        PRODUCT_COST_ESTIMATE_HK
      , MATNR
      , WERKS
      , LOAD_DTS
      , BKCC
      , REC_SRC
        """
        result = _parse_select_columns(text)
        assert result == ["PRODUCT_COST_ESTIMATE_HK", "MATNR", "WERKS", "LOAD_DTS", "BKCC", "REC_SRC"]

    def test_skips_jinja(self):
        text = "COL_A, {% if x %} COL_B"
        result = _parse_select_columns(text)
        assert "COL_A" in result

    def test_empty(self):
        assert _parse_select_columns("") == []


# ---------------------------------------------------------------------------
# _parse_logic_columns tests
# ---------------------------------------------------------------------------

class TestParseLogicColumns:

    def test_no_rename(self):
        result = _parse_logic_columns("PO_ITEM_HK, LOAD_DTS, BKCC, REC_SRC")
        assert all(c["raw"] == c["hub"] for c in result)
        assert [c["hub"] for c in result] == ["PO_ITEM_HK", "LOAD_DTS", "BKCC", "REC_SRC"]

    def test_with_renames(self):
        text = """
        PO_ITEM_HK
      , EBELN                                                        as                                       PO_HEADER_ID
      , EBELP                                                        as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , BKCC
      , REC_SRC
        """
        result = _parse_logic_columns(text)
        mapping = {c["raw"]: c["hub"] for c in result}
        assert mapping["EBELN"] == "PO_HEADER_ID"
        assert mapping["EBELP"] == "PO_LINE_NUMBER"
        assert mapping["PO_ITEM_HK"] == "PO_ITEM_HK"

    def test_cast_with_rename(self):
        result = _parse_logic_columns("LINE_NUM::TEXT as PO_LINE_NUMBER")
        assert result[0]["raw"] == "LINE_NUM"
        assert result[0]["hub"] == "PO_LINE_NUMBER"


# ---------------------------------------------------------------------------
# _derive_source_alias tests
# ---------------------------------------------------------------------------

class TestDeriveSourceAlias:

    def test_standard(self):
        assert _derive_source_alias("v_psa_stg_cost_estimate_header__emtk_ebs") == "emtkebs"

    def test_single_word_source(self):
        assert _derive_source_alias("v_psa_stg_po_item__ml_ebs") == "mlebs"

    def test_winn_sap(self):
        assert _derive_source_alias("v_psa_stg_po_item__winn_sap") == "winnsap"

    def test_moen_sap(self):
        assert _derive_source_alias("v_psa_stg_cost_estimate_header__moen_sap") == "moensap"


# ---------------------------------------------------------------------------
# _parse_existing_hub — inline fixture tests
# ---------------------------------------------------------------------------

SINGLE_SOURCE_HUB = """\
---- SRC LAYER ----
{% if is_incremental() %}
WITH INCR_WATERMARK AS (
    SELECT REC_SRC as wm_REC_SRC,
           DATEADD(DAY, -3, MAX(LOAD_DTS)) AS watermark_dts
    FROM {{ this }}
    GROUP BY REC_SRC
),
{% else %}
WITH
{% endif %}
SRC_SRC            as ( SELECT PRODUCT_HK, COL_A, COL_B, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_product__moen_sap') }} as SRC
                        {% if is_incremental() %}
                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC
                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)
                        {% else %}
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COL_A, COL_B, BKCC ORDER BY GLCHANGETIME)) = 1
                        {% endif %}
)

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_product__moen_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        PRODUCT_HK
      , COL_A
      , COL_B
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_SRC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
)

---- FINAL LAYER ----
SELECT
          PRODUCT_HK
        , COL_A
        , COL_B
        , LOAD_DTS
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.PRODUCT_HK = JOIN_RESULT.PRODUCT_HK
)
{% endif %}
qualify 1 = row_number() over (partition by COL_A, COL_B, BKCC order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT
MD5_BINARY(GR.VALUE) AS PRODUCT_HK,
GR.VALUE::text AS COL_A,
GR.VALUE::text AS COL_B,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
"""

TWO_SOURCE_6LAYER_HUB = """\
WITH
SRC_srcA           as (
    SELECT ENTITY_HK, RAW_A, LOAD_DTS, BKCC, REC_SRC
    FROM {{ ref('v_psa_stg_entity__src_a') }} as SRC
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY RAW_A, BKCC ORDER BY LOAD_DTS)) = 1
),
SRC_srcB           as (
    SELECT ENTITY_HK, RAW_B, LOAD_DTS, BKCC, REC_SRC
    FROM {{ ref('v_psa_stg_entity__src_b') }} as SRC
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY RAW_B, BKCC ORDER BY LOAD_DTS)) = 1
)

---- LOGIC LAYER ----

, LOGIC_srcA as (
    SELECT
        ENTITY_HK
      , RAW_A                                                        as                                       STANDARD_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_srcA
)

, LOGIC_srcB as (
    SELECT
        ENTITY_HK
      , RAW_B                                                        as                                       STANDARD_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_srcB
)
---- RENAME LAYER ----

, RENAME_srcA as (
    SELECT ENTITY_HK, STANDARD_BK, LOAD_DTS, BKCC, REC_SRC
    FROM LOGIC_srcA
)

, RENAME_srcB as (
    SELECT ENTITY_HK, STANDARD_BK, LOAD_DTS, BKCC, REC_SRC
    FROM LOGIC_srcB
)
---- FILTER LAYER ----

, FILTER_srcA as (
    SELECT * FROM RENAME_srcA
)

, FILTER_srcB as (
    SELECT * FROM RENAME_srcB
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_srcA
    UNION ALL
    SELECT * FROM FILTER_srcB
)

---- FINAL LAYER ----
SELECT
          ENTITY_HK
        , STANDARD_BK
        , LOAD_DTS
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.ENTITY_HK = JOIN_RESULT.ENTITY_HK
)
{% endif %}
qualify 1 = row_number() over (partition by STANDARD_BK, BKCC order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS ENTITY_HK,
GR.VALUE::text AS STANDARD_BK,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
"""


class TestParseExistingHubInline:

    def test_single_source_4layer(self, tmp_path):
        """Parse single-source 4-layer hub with watermark."""
        hub_file = tmp_path / "hub_product.sql"
        hub_file.write_text(SINGLE_SOURCE_HUB)

        result = _parse_existing_hub(str(hub_file))

        # Config
        assert result["config_block"] is None

        # Watermark
        assert result["has_watermark_cte"] is True

        # Sources
        assert len(result["sources"]) == 1
        src = result["sources"][0]
        assert src["alias"] == "SRC"
        assert src["stg_ref"] == "v_psa_stg_product__moen_sap"
        assert src["uses_watermark"] is True
        assert "PRODUCT_HK" in src["src_columns"]
        assert "COL_A" in src["src_columns"]

        # LOGIC CTEs
        assert "SRC" in result["logic_ctes"]
        logic_cols = result["logic_ctes"]["SRC"]["columns"]
        hub_names = [c["hub"] for c in logic_cols]
        assert "PRODUCT_HK" in hub_names
        assert "COL_A" in hub_names

        # CTE chain
        assert result["cte_chain"] == "4-layer"
        assert result["join_source_type"] == "LOGIC"

        # Hub columns
        assert result["hub_columns"] == [
            "PRODUCT_HK", "COL_A", "COL_B", "LOAD_DTS", "BKCC", "REC_SRC"
        ]
        assert result["hk_column"] == "PRODUCT_HK"

        # Qualify columns
        assert result["qualify_columns"] == ["COL_A", "COL_B", "BKCC"]

        # Ghost block
        assert result["ghost_record_block"] is not None
        assert "strtok_split_to_table" in result["ghost_record_block"]

        # JOIN entries
        assert result["join_cte_entries"] == ["LOGIC_SRC"]

    def test_two_source_6layer(self, tmp_path):
        """Parse two-source 6-layer hub with RENAME+FILTER layers."""
        hub_file = tmp_path / "hub_entity.sql"
        hub_file.write_text(TWO_SOURCE_6LAYER_HUB)

        result = _parse_existing_hub(str(hub_file))

        # No watermark
        assert result["has_watermark_cte"] is False

        # Two sources
        assert len(result["sources"]) == 2
        aliases = [s["alias"] for s in result["sources"]]
        assert "srcA" in aliases
        assert "srcB" in aliases

        # Refs
        refs = {s["alias"]: s["stg_ref"] for s in result["sources"]}
        assert refs["srcA"] == "v_psa_stg_entity__src_a"
        assert refs["srcB"] == "v_psa_stg_entity__src_b"

        # No watermark per source
        assert all(not s["uses_watermark"] for s in result["sources"])

        # LOGIC with renames
        assert "srcA" in result["logic_ctes"]
        assert "srcB" in result["logic_ctes"]
        mapping_a = {c["raw"]: c["hub"] for c in result["logic_ctes"]["srcA"]["columns"]}
        assert mapping_a["RAW_A"] == "STANDARD_BK"
        mapping_b = {c["raw"]: c["hub"] for c in result["logic_ctes"]["srcB"]["columns"]}
        assert mapping_b["RAW_B"] == "STANDARD_BK"

        # CTE chain
        assert result["cte_chain"] == "6-layer"
        assert result["join_source_type"] == "FILTER"

        # Hub columns
        assert result["hub_columns"] == ["ENTITY_HK", "STANDARD_BK", "LOAD_DTS", "BKCC", "REC_SRC"]

        # Qualify
        assert result["qualify_columns"] == ["STANDARD_BK", "BKCC"]

        # JOIN entries — unions FILTER CTEs
        assert "FILTER_srcA" in result["join_cte_entries"]
        assert "FILTER_srcB" in result["join_cte_entries"]


# ---------------------------------------------------------------------------
# _parse_existing_hub — real production file tests
# ---------------------------------------------------------------------------

class TestParseExistingHubProduction:

    @pytest.fixture
    def hub_po_item_path(self):
        path = PROJECT_ROOT / "models" / "raw_vault" / "hub" / "hub_po_item.sql"
        if not path.exists():
            pytest.skip("hub_po_item.sql not found in workspace")
        return str(path)

    @pytest.fixture
    def hub_product_cost_path(self):
        path = PROJECT_ROOT / "scripts" / "automation" / "models" / "raw_vault" / "hub" / "hub_product_cost_estimate.sql"
        if not path.exists():
            pytest.skip("hub_product_cost_estimate.sql not found in workspace")
        return str(path)

    @pytest.fixture
    def hub_order_line_path(self):
        path = PROJECT_ROOT / "models" / "raw_vault" / "hub" / "hub_order_line.sql"
        if not path.exists():
            pytest.skip("hub_order_line.sql not found in workspace")
        return str(path)

    def test_hub_po_item_sources(self, hub_po_item_path):
        """hub_po_item sources: unique aliases, all v_psa_stg refs, known aliases present.

        Count-agnostic (#1905): asserts structure, not a pinned source count, so
        adding an N+1th source to the model does not break this test.
        """
        result = _parse_existing_hub(hub_po_item_path)

        sources = result["sources"]
        aliases = [s["alias"] for s in sources]
        assert len(sources) >= 4                     # multi-source hub sanity floor
        assert len(aliases) == len(set(aliases))     # aliases are unique
        for expected in ("polml", "polsap", "pollrsn", "polfib"):
            assert expected in aliases

        # All refs should be v_psa_stg_*
        for src in sources:
            assert src["stg_ref"] is not None
            assert src["stg_ref"].startswith("v_psa_stg_")

    def test_hub_po_item_has_watermark(self, hub_po_item_path):
        """hub_po_item uses INCR_WATERMARK (adopted for large-volume performance)."""
        result = _parse_existing_hub(hub_po_item_path)
        assert result["has_watermark_cte"] is True
        # Not all sources use watermark — some use QUALIFY only (e.g., polml, polttgp)
        assert any(s["uses_watermark"] for s in result["sources"])

    def test_hub_po_item_6layer(self, hub_po_item_path):
        """hub_po_item uses 6-layer CTE chain."""
        result = _parse_existing_hub(hub_po_item_path)
        assert result["cte_chain"] == "6-layer"
        assert result["join_source_type"] == "FILTER"

    def test_hub_po_item_logic_renames(self, hub_po_item_path):
        """hub_po_item LOGIC CTEs rename raw columns to standard names.

        Count-agnostic (#1905): one LOGIC CTE per source (counts match), not a
        pinned literal.
        """
        result = _parse_existing_hub(hub_po_item_path)
        assert len(result["logic_ctes"]) == len(result["sources"])

        # polsap: EBELN → PO_HEADER_ID, EBELP → PO_LINE_NUMBER
        assert "polsap" in result["logic_ctes"]
        mapping = {c["raw"]: c["hub"] for c in result["logic_ctes"]["polsap"]["columns"]}
        assert mapping["EBELN"] == "PO_HEADER_ID"
        assert mapping["EBELP"] == "PO_LINE_NUMBER"

    def test_hub_po_item_hub_columns(self, hub_po_item_path):
        """hub_po_item outputs 6 columns."""
        result = _parse_existing_hub(hub_po_item_path)
        assert result["hub_columns"] == [
            "PO_ITEM_HK", "PO_HEADER_ID", "PO_LINE_NUMBER",
            "LOAD_DTS", "BKCC", "REC_SRC"
        ]
        assert result["hk_column"] == "PO_ITEM_HK"

    def test_hub_po_item_qualify(self, hub_po_item_path):
        """hub_po_item final QUALIFY partitions by PO_ITEM_HK."""
        result = _parse_existing_hub(hub_po_item_path)
        assert "PO_ITEM_HK" in result["qualify_columns"]

    def test_hub_po_item_ghost(self, hub_po_item_path):
        """hub_po_item has ghost record block."""
        result = _parse_existing_hub(hub_po_item_path)
        assert result["ghost_record_block"] is not None
        assert "PO_ITEM_HK" in result["ghost_record_block"]

    def test_hub_po_item_join_entries(self, hub_po_item_path):
        """hub_po_item JOIN_RESULT unions one FILTER CTE per source.

        Count-agnostic (#1905): one join entry per source, all FILTER_-prefixed.
        """
        result = _parse_existing_hub(hub_po_item_path)
        entries = result["join_cte_entries"]
        assert entries                                        # non-empty
        assert len(entries) == len(result["sources"])         # one FILTER per source
        assert all(e.startswith("FILTER_") for e in entries)

    def test_hub_product_cost_single_source(self, hub_product_cost_path):
        """hub_product_cost_estimate — single source, 4-layer, watermark."""
        result = _parse_existing_hub(hub_product_cost_path)

        assert len(result["sources"]) == 1
        assert result["sources"][0]["stg_ref"] == "v_psa_stg_cost_est_hdr_e2e__moen_sap"
        assert result["sources"][0]["uses_watermark"] is True
        assert result["has_watermark_cte"] is True
        assert result["cte_chain"] == "4-layer"
        assert result["hk_column"] == "PRODUCT_COST_ESTIMATE_HK"
        assert "MATNR" in result["hub_columns"]
        assert result["join_cte_entries"] == ["LOGIC_SRC"]

    def test_hub_order_line_direct_pattern(self, hub_order_line_path):
        """hub_order_line — direct pattern (SRC→JOIN, no LOGIC)."""
        result = _parse_existing_hub(hub_order_line_path)

        assert result["cte_chain"] == "direct"
        assert result["join_source_type"] == "SRC"
        assert result["has_watermark_cte"] is True
        assert len(result["sources"]) >= 10
        assert result["hk_column"] == "ORDER_LINE_HK"
        assert result["config_block"] is not None
        assert "full_refresh" in result["config_block"]


# ---------------------------------------------------------------------------
# _extract helper function tests
# ---------------------------------------------------------------------------

class TestExtractHelpers:

    def test_extract_final_columns_explicit(self):
        sql = """
, JOIN_RESULT as (SELECT * FROM LOGIC_SRC)
SELECT COL_A, COL_B, COL_C FROM JOIN_RESULT
WHERE 1=1
"""
        assert _extract_hub_final_columns(sql) == ["COL_A", "COL_B", "COL_C"]

    def test_extract_final_columns_multiline(self):
        sql = """
, JOIN_RESULT as (SELECT * FROM LOGIC_SRC)
SELECT
          ENTITY_HK
        , BK_COL
        , LOAD_DTS
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
"""
        assert _extract_hub_final_columns(sql) == ["ENTITY_HK", "BK_COL", "LOAD_DTS", "BKCC", "REC_SRC"]

    def test_extract_final_columns_star_with_join_columns(self):
        """SELECT * FROM JOIN_RESULT — falls back to JOIN_RESULT's own SELECT."""
        sql = """
, JOIN_RESULT as (
SELECT
          ENTITY_HK
        , BK_COL
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM (
    SELECT * FROM SRC_A UNION ALL SELECT * FROM SRC_B
)
QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY BK_COL ORDER BY LOAD_DTS)
)

SELECT * FROM JOIN_RESULT
"""
        result = _extract_hub_final_columns(sql)
        assert "ENTITY_HK" in result
        assert "BK_COL" in result

    def test_extract_qualify_columns(self):
        sql = "qualify 1 = row_number() over (partition by COL_A, COL_B, BKCC order by LOAD_DTS)"
        assert _extract_final_qualify_columns(sql) == ["COL_A", "COL_B", "BKCC"]

    def test_extract_qualify_takes_last(self):
        """Multiple QUALIFY clauses — takes the last one (final layer)."""
        sql = """
QUALIFY (ROW_NUMBER() OVER(PARTITION BY PO_ITEM_BK ORDER BY LOAD_DTS)) = 1
...
qualify 1= row_number() over(partition by PO_ITEM_HK order by load_dts)
"""
        result = _extract_final_qualify_columns(sql)
        assert result == ["PO_ITEM_HK"]

    def test_extract_ghost_block(self):
        sql = """
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS ENTITY_HK,
GR.VALUE::text AS BK_COL,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
"""
        ghost = _extract_ghost_block(sql)
        assert ghost is not None
        assert "ENTITY_HK" in ghost
        assert "strtok_split_to_table" in ghost

    def test_extract_ghost_block_none(self):
        assert _extract_ghost_block("SELECT 1 FROM foo") is None


# ---------------------------------------------------------------------------
# Steps 2-3: _build_add_source_column_mapping tests
# ---------------------------------------------------------------------------

class TestBuildColumnMapping:

    @pytest.fixture
    def hub_parsed_multi_bk(self):
        """Hub with multi-part BK (PO_HEADER_ID, PO_LINE_NUMBER)."""
        return {
            "hub_columns": ["PO_ITEM_HK", "PO_HEADER_ID", "PO_LINE_NUMBER",
                            "LOAD_DTS", "BKCC", "REC_SRC"],
            "hk_column": "PO_ITEM_HK",
        }

    @pytest.fixture
    def hub_parsed_single_bk(self):
        """Hub with single BK (PRODUCT_BK)."""
        return {
            "hub_columns": ["PRODUCT_HK", "PRODUCT_BK", "LOAD_DTS", "BKCC", "REC_SRC"],
            "hk_column": "PRODUCT_HK",
        }

    def test_same_column_names(self, hub_parsed_single_bk):
        """No renames needed when source uses same column names."""
        result = _build_add_source_column_mapping(hub_parsed_single_bk, ["PRODUCT_BK"])
        mapping = {c["raw"]: c["hub"] for c in result}
        assert mapping["PRODUCT_BK"] == "PRODUCT_BK"
        assert mapping["PRODUCT_HK"] == "PRODUCT_HK"
        assert mapping["LOAD_DTS"] == "LOAD_DTS"

    def test_different_column_names(self, hub_parsed_multi_bk):
        """BK mapping uses hub alias names (v_psa_stg already outputs the alias)."""
        result = _build_add_source_column_mapping(hub_parsed_multi_bk, ["EBELN", "EBELP"])
        mapping = {c["raw"]: c["hub"] for c in result}
        # raw == hub because v_psa_stg outputs BK as the alias (PO_HEADER_ID, PO_LINE_NUMBER)
        assert mapping["PO_HEADER_ID"] == "PO_HEADER_ID"
        assert mapping["PO_LINE_NUMBER"] == "PO_LINE_NUMBER"

    def test_bk_count_mismatch_raises(self, hub_parsed_multi_bk):
        """Raises ValueError if BK column count doesn't match."""
        with pytest.raises(ValueError, match="BK column count mismatch"):
            _build_add_source_column_mapping(hub_parsed_multi_bk, ["ONLY_ONE_COL"])

    def test_column_order(self, hub_parsed_multi_bk):
        """Output order: HK, BKs, LOAD_DTS, BKCC, REC_SRC."""
        result = _build_add_source_column_mapping(hub_parsed_multi_bk, ["EBELN", "EBELP"])
        hub_names = [c["hub"] for c in result]
        assert hub_names == ["PO_ITEM_HK", "PO_HEADER_ID", "PO_LINE_NUMBER",
                             "LOAD_DTS", "BKCC", "REC_SRC"]

    def test_uppercase_normalization(self, hub_parsed_single_bk):
        """Raw column names are uppercased."""
        result = _build_add_source_column_mapping(hub_parsed_single_bk, ["product_bk"])
        assert result[1]["raw"] == "PRODUCT_BK"


# ---------------------------------------------------------------------------
# Steps 4-5: _generate_add_source_ctes tests
# ---------------------------------------------------------------------------

class TestGenerateAddSourceCTEs:

    @pytest.fixture
    def hub_parsed_4layer(self, tmp_path):
        hub_file = tmp_path / "hub.sql"
        hub_file.write_text(SINGLE_SOURCE_HUB)
        return _parse_existing_hub(str(hub_file))

    @pytest.fixture
    def hub_parsed_6layer(self, tmp_path):
        hub_file = tmp_path / "hub.sql"
        hub_file.write_text(TWO_SOURCE_6LAYER_HUB)
        return _parse_existing_hub(str(hub_file))

    def test_4layer_generates_src_and_logic(self, hub_parsed_4layer):
        """4-layer hub generates SRC + LOGIC CTEs only."""
        mapping = _build_add_source_column_mapping(hub_parsed_4layer, ["NEW_A", "NEW_B"])
        result = _generate_add_source_ctes(
            hub_parsed_4layer, "newsrc", "v_psa_stg_product__new_src",
            mapping, use_watermark=False,
            qualify_order_by="LOAD_DTS", new_bk_raw_cols=["NEW_A", "NEW_B"],
        )
        assert "SRC_newsrc" in result["src_cte"]
        assert "LOGIC_newsrc" in result["logic_cte"]
        assert result["rename_cte"] is None
        assert result["filter_cte"] is None
        assert "ref('v_psa_stg_product__new_src')" in result["src_cte"]

    def test_6layer_generates_full_chain(self, hub_parsed_6layer):
        """6-layer hub generates SRC + LOGIC + RENAME + FILTER CTEs."""
        mapping = _build_add_source_column_mapping(hub_parsed_6layer, ["RAW_C"])
        result = _generate_add_source_ctes(
            hub_parsed_6layer, "srcC", "v_psa_stg_entity__src_c",
            mapping, use_watermark=False,
            qualify_order_by="LOAD_DTS", new_bk_raw_cols=["RAW_C"],
        )
        assert "SRC_srcC" in result["src_cte"]
        assert "LOGIC_srcC" in result["logic_cte"]
        assert "RENAME_srcC" in result["rename_cte"]
        assert "FILTER_srcC" in result["filter_cte"]

    def test_watermark_generates_left_join(self, hub_parsed_4layer):
        """Watermarked source generates LEFT JOIN INCR_WATERMARK in SRC."""
        mapping = _build_add_source_column_mapping(hub_parsed_4layer, ["NEW_A", "NEW_B"])
        result = _generate_add_source_ctes(
            hub_parsed_4layer, "newsrc", "v_psa_stg_product__new_src",
            mapping, use_watermark=True,
            qualify_order_by="GLCHANGETIME", new_bk_raw_cols=["NEW_A", "NEW_B"],
        )
        assert "INCR_WATERMARK" in result["src_cte"]
        assert "LEFT JOIN" in result["src_cte"]
        assert "is_incremental()" in result["src_cte"]
        assert result["needs_watermark_cte"] is False  # hub already has it

    def test_needs_watermark_cte_when_hub_lacks_it(self, hub_parsed_6layer):
        """Sets needs_watermark_cte=True when hub has no INCR_WATERMARK."""
        mapping = _build_add_source_column_mapping(hub_parsed_6layer, ["RAW_C"])
        result = _generate_add_source_ctes(
            hub_parsed_6layer, "srcC", "v_psa_stg_entity__src_c",
            mapping, use_watermark=True,
            qualify_order_by="GLCHANGETIME", new_bk_raw_cols=["RAW_C"],
        )
        assert result["needs_watermark_cte"] is True

    def test_no_watermark_uses_qualify_only(self, hub_parsed_4layer):
        """Non-watermarked source uses QUALIFY only (no LEFT JOIN)."""
        mapping = _build_add_source_column_mapping(hub_parsed_4layer, ["NEW_A", "NEW_B"])
        result = _generate_add_source_ctes(
            hub_parsed_4layer, "newsrc", "v_psa_stg_product__new_src",
            mapping, use_watermark=False,
            qualify_order_by="LOAD_DTS", new_bk_raw_cols=["NEW_A", "NEW_B"],
        )
        assert "LEFT JOIN" not in result["src_cte"]
        assert "QUALIFY" in result["src_cte"]
        assert "PARTITION BY COL_A, COL_B, BKCC" in result["src_cte"]

    def test_logic_has_column_renames(self, hub_parsed_6layer):
        """LOGIC CTE uses hub alias names directly (v_psa_stg outputs the alias)."""
        mapping = _build_add_source_column_mapping(hub_parsed_6layer, ["RAW_C"])
        result = _generate_add_source_ctes(
            hub_parsed_6layer, "srcC", "v_psa_stg_entity__src_c",
            mapping, use_watermark=False,
            qualify_order_by="LOAD_DTS", new_bk_raw_cols=["RAW_C"],
        )
        # No rename needed — raw == hub because v_psa_stg already outputs STANDARD_BK
        assert "STANDARD_BK" in result["logic_cte"]
        assert "FROM SRC_srcC" in result["logic_cte"]


# ---------------------------------------------------------------------------
# Step 6: _insert_source_into_hub tests
# ---------------------------------------------------------------------------

class TestInsertSourceIntoHub:

    def test_insert_into_4layer(self, tmp_path):
        """Insert new source into single-source 4-layer hub."""
        hub_file = tmp_path / "hub.sql"
        hub_file.write_text(SINGLE_SOURCE_HUB)

        hub_parsed = _parse_existing_hub(str(hub_file))
        mapping = _build_add_source_column_mapping(hub_parsed, ["NEW_A", "NEW_B"])
        ctes = _generate_add_source_ctes(
            hub_parsed, "newsrc", "v_psa_stg_product__new_src",
            mapping, use_watermark=False,
            qualify_order_by="LOAD_DTS", new_bk_raw_cols=["NEW_A", "NEW_B"],
        )
        _insert_source_into_hub(str(hub_file), hub_parsed, ctes, "newsrc")

        result = hub_file.read_text()
        # New SRC CTE present
        assert "SRC_newsrc" in result
        assert "ref('v_psa_stg_product__new_src')" in result
        # New LOGIC CTE present
        assert "LOGIC_newsrc" in result
        # UNION ALL added
        assert "LOGIC_newsrc" in result
        # Original source untouched
        assert "SRC_SRC" in result
        assert "LOGIC_SRC" in result
        # Ghost records still present
        assert "strtok_split_to_table" in result
        # Re-parse and verify structure
        reparsed = _parse_existing_hub(str(hub_file))
        assert len(reparsed["sources"]) == 2
        aliases = [s["alias"] for s in reparsed["sources"]]
        assert "SRC" in aliases
        assert "newsrc" in aliases

    def test_insert_into_6layer(self, tmp_path):
        """Insert new source into 6-layer hub generates RENAME + FILTER too."""
        hub_file = tmp_path / "hub.sql"
        hub_file.write_text(TWO_SOURCE_6LAYER_HUB)

        hub_parsed = _parse_existing_hub(str(hub_file))
        mapping = _build_add_source_column_mapping(hub_parsed, ["RAW_C"])
        ctes = _generate_add_source_ctes(
            hub_parsed, "srcC", "v_psa_stg_entity__src_c",
            mapping, use_watermark=False,
            qualify_order_by="LOAD_DTS", new_bk_raw_cols=["RAW_C"],
        )
        _insert_source_into_hub(str(hub_file), hub_parsed, ctes, "srcC")

        result = hub_file.read_text()
        assert "SRC_srcC" in result
        assert "LOGIC_srcC" in result
        assert "RENAME_srcC" in result
        assert "FILTER_srcC" in result
        # Re-parse: 3 sources now
        reparsed = _parse_existing_hub(str(hub_file))
        assert len(reparsed["sources"]) == 3
        # JOIN entries should include FILTER_srcC
        assert "FILTER_srcC" in reparsed["join_cte_entries"]

    def test_idempotent_alias_detection(self, tmp_path):
        """Inserting same alias twice can be detected by re-parsing."""
        hub_file = tmp_path / "hub.sql"
        hub_file.write_text(SINGLE_SOURCE_HUB)

        hub_parsed = _parse_existing_hub(str(hub_file))
        mapping = _build_add_source_column_mapping(hub_parsed, ["NEW_A", "NEW_B"])
        ctes = _generate_add_source_ctes(
            hub_parsed, "newsrc", "v_psa_stg_product__new_src",
            mapping, use_watermark=False,
            qualify_order_by="LOAD_DTS", new_bk_raw_cols=["NEW_A", "NEW_B"],
        )
        _insert_source_into_hub(str(hub_file), hub_parsed, ctes, "newsrc")

        # Re-parse — newsrc is now in sources
        reparsed = _parse_existing_hub(str(hub_file))
        existing_aliases = [s["alias"] for s in reparsed["sources"]]
        assert "newsrc" in existing_aliases

    def test_adds_watermark_cte_when_needed(self, tmp_path):
        """Adds INCR_WATERMARK CTE when hub doesn't have one and source needs it."""
        # Use 6-layer hub which has no watermark
        hub_file = tmp_path / "hub.sql"
        hub_file.write_text(TWO_SOURCE_6LAYER_HUB)

        hub_parsed = _parse_existing_hub(str(hub_file))
        assert hub_parsed["has_watermark_cte"] is False

        mapping = _build_add_source_column_mapping(hub_parsed, ["RAW_C"])
        ctes = _generate_add_source_ctes(
            hub_parsed, "srcC", "v_psa_stg_entity__src_c",
            mapping, use_watermark=True,
            qualify_order_by="GLCHANGETIME", new_bk_raw_cols=["RAW_C"],
        )
        assert ctes["needs_watermark_cte"] is True
        _insert_source_into_hub(str(hub_file), hub_parsed, ctes, "srcC")

        result = hub_file.read_text()
        reparsed = _parse_existing_hub(str(hub_file))
        assert reparsed["has_watermark_cte"] is True

    def test_original_source_untouched(self, tmp_path):
        """Existing source CTEs remain byte-for-byte identical."""
        hub_file = tmp_path / "hub.sql"
        hub_file.write_text(SINGLE_SOURCE_HUB)

        original = hub_file.read_text()
        # Extract the original SRC_SRC CTE definition (up to closing paren on its own line)
        import re as _re
        pattern = r"(SRC_SRC\s+as\s*\(.*?\n\))"
        orig_src_match = _re.search(pattern, original, _re.DOTALL).group(1)

        hub_parsed = _parse_existing_hub(str(hub_file))
        mapping = _build_add_source_column_mapping(hub_parsed, ["NEW_A", "NEW_B"])
        ctes = _generate_add_source_ctes(
            hub_parsed, "newsrc", "v_psa_stg_product__new_src",
            mapping, use_watermark=False,
            qualify_order_by="LOAD_DTS", new_bk_raw_cols=["NEW_A", "NEW_B"],
        )
        _insert_source_into_hub(str(hub_file), hub_parsed, ctes, "newsrc")

        modified = hub_file.read_text()
        # Original SRC_SRC CTE block still present and unchanged
        modified_src_match = _re.search(pattern, modified, _re.DOTALL).group(1)
        assert orig_src_match == modified_src_match

# ---------------------------------------------------------------------------
# Integration test: hub_po_item (production multi-source hub)
# ---------------------------------------------------------------------------

class TestInsertSourceHubPoItem:

    @pytest.fixture
    def hub_po_item_copy(self, tmp_path):
        """Copy hub_po_item.sql to tmp_path for safe modification."""
        src = PROJECT_ROOT / "models" / "raw_vault" / "hub" / "hub_po_item.sql"
        if not src.exists():
            pytest.skip("hub_po_item.sql not found in workspace")
        dst = tmp_path / "hub_po_item.sql"
        dst.write_text(src.read_text())
        return str(dst)

    def test_add_source_to_hub_po_item(self, hub_po_item_copy):
        """Add a fake source to production hub_po_item — validates full pipeline.

        Count-agnostic (#1905): asserts the added source increments the count by
        one and the originals are preserved, rather than pinning literals that
        break every time a real source is added to the model.
        """
        hub_parsed = _parse_existing_hub(hub_po_item_copy)
        initial_count = len(hub_parsed["sources"])
        assert initial_count >= 4  # multi-source hub sanity floor
        assert hub_parsed["cte_chain"] == "6-layer"

        # Build column mapping: new source has PURCHASE_ORDER, LINE_NO → PO_HEADER_ID, PO_LINE_NUMBER
        mapping = _build_add_source_column_mapping(hub_parsed, ["PURCHASE_ORDER", "LINE_NO"])

        # Verify positional mapping
        bk_mapping = {c["raw"]: c["hub"] for c in mapping if c["hub"] not in {"PO_ITEM_HK", "LOAD_DTS", "BKCC", "REC_SRC"}}
        # raw == hub because v_psa_stg already outputs the alias
        assert bk_mapping["PO_HEADER_ID"] == "PO_HEADER_ID"
        assert bk_mapping["PO_LINE_NUMBER"] == "PO_LINE_NUMBER"

        # Generate CTEs (no watermark, small source)
        ctes = _generate_add_source_ctes(
            hub_parsed, "polfake", "v_psa_stg_po_item__fake_src",
            mapping, use_watermark=False,
            qualify_order_by="LOAD_DTS", new_bk_raw_cols=["PURCHASE_ORDER", "LINE_NO"],
        )

        # Verify 6-layer chain
        assert ctes["rename_cte"] is not None
        assert ctes["filter_cte"] is not None

        # Insert into copy
        _insert_source_into_hub(hub_po_item_copy, hub_parsed, ctes, "polfake")

        # Re-parse and validate
        reparsed = _parse_existing_hub(hub_po_item_copy)
        assert len(reparsed["sources"]) == initial_count + 1

        # New source present
        aliases = [s["alias"] for s in reparsed["sources"]]
        assert "polfake" in aliases
        new_src = next(s for s in reparsed["sources"] if s["alias"] == "polfake")
        assert new_src["stg_ref"] == "v_psa_stg_po_item__fake_src"

        # LOGIC CTE with identity columns (v_psa_stg outputs BK aliases directly)
        assert "polfake" in reparsed["logic_ctes"]
        logic_mapping = {c["raw"]: c["hub"] for c in reparsed["logic_ctes"]["polfake"]["columns"]}
        # raw == hub because v_psa_stg already outputs the alias
        assert logic_mapping["PO_HEADER_ID"] == "PO_HEADER_ID"
        assert logic_mapping["PO_LINE_NUMBER"] == "PO_LINE_NUMBER"

        # JOIN_RESULT now has one more entry than before
        assert len(reparsed["join_cte_entries"]) == initial_count + 1
        assert "FILTER_polfake" in reparsed["join_cte_entries"]

        # Original sources still have correct refs
        original_refs = [s["stg_ref"] for s in reparsed["sources"] if s["alias"] != "polfake"]
        assert len(original_refs) == initial_count
        assert all(r.startswith("v_psa_stg_") for r in original_refs)

        # Hub columns unchanged
        assert reparsed["hub_columns"] == hub_parsed["hub_columns"]

        # Ghost records still present
        assert reparsed["ghost_record_block"] is not None
