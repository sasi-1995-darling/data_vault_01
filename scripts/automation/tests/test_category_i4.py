#!/usr/bin/env python3
"""
test_category_i4.py — Tests for I4 (check_non_staging_uses_ref_only).

Downstream layer rule: raw_vault/, bus_vault/, info_mart/ models must use
ref() only — any source() bypasses the staging layer and FAILs.

Mostly content-only — no allowlist or sources YAML needed. The check does
accept ``repo_root`` (used to load .code_review_grandfather for FAIL→WARN
downgrades of pre-existing debt); pass ``repo_root=tmp_path`` (or omit) to
run without grandfather suppression.

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_category_i4.py -v
"""
import sys
from pathlib import Path

import pytest

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_review_config import FileStatus  # noqa: E402
from code_reviewer import Severity, check_non_staging_uses_ref_only  # noqa: E402


HUB_PATH = "models/raw_vault/hub/hub_customer.sql"
SAT_PATH = "models/raw_vault/sat/sat_customer__src.sql"
PB_PATH = "models/bus_vault/pb/pb_customer.sql"
FACT_PATH = "models/info_mart/fact/fact_orders.sql"
STG_PATH = "models/int_staging_views/foo/v_psa_stg_foo__src.sql"


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 1: raw_vault hub, ref() only → PASS
# ────────────────────────────────────────────────────────────────────────────
def test_raw_vault_hub_ref_only_passes():
    sql = """
    SELECT * FROM {{ ref('v_psa_stg_customer__src') }}
    UNION ALL
    SELECT * FROM {{ ref('v_psa_stg_customer__alt') }}
    """
    findings = check_non_staging_uses_ref_only(sql, HUB_PATH)
    assert findings == [], f"raw_vault with ref() only must pass, got {findings}"


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 2: raw_vault sat with source() → FAIL
# ────────────────────────────────────────────────────────────────────────────
def test_raw_vault_sat_with_source_fails():
    sql = "SELECT * FROM {{ source('amazon_us', 'sales') }}"
    findings = check_non_staging_uses_ref_only(sql, SAT_PATH)
    assert len(findings) == 1
    f = findings[0]
    assert f.check_id == "I4"
    assert f.severity == Severity.FAIL
    assert "raw vault" in f.message.lower()
    assert "amazon_us" in f.message
    assert "sales" in f.message


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 3: bus_vault PB with source() → FAIL
# ────────────────────────────────────────────────────────────────────────────
def test_bus_vault_pb_with_source_fails():
    sql = "SELECT * FROM {{ source('edp_bronze', 'customer') }}"
    findings = check_non_staging_uses_ref_only(sql, PB_PATH)
    assert len(findings) == 1
    f = findings[0]
    assert f.check_id == "I4"
    assert "bus vault" in f.message.lower()


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 4: info_mart fact, ref() only → PASS
# ────────────────────────────────────────────────────────────────────────────
def test_info_mart_fact_ref_only_passes():
    sql = "SELECT * FROM {{ ref('pb_orders') }}"
    findings = check_non_staging_uses_ref_only(sql, FACT_PATH)
    assert findings == []


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 5: source() in a comment in raw_vault → no finding
# ────────────────────────────────────────────────────────────────────────────
def test_source_in_block_comment_skipped():
    sql = """
    /*
    Old version (intentionally retained as documentation):
    SELECT * FROM {{ source('amazon_us', 'sales') }}
    */
    SELECT * FROM {{ ref('v_psa_stg_customer__src') }}
    """
    findings = check_non_staging_uses_ref_only(sql, SAT_PATH)
    assert findings == []


def test_source_in_line_comment_skipped():
    sql = "-- old: SELECT * FROM {{ source('amazon_us', 'sales') }}\nSELECT 1\n"
    findings = check_non_staging_uses_ref_only(sql, SAT_PATH)
    assert findings == []


# ────────────────────────────────────────────────────────────────────────────
# Scope guards: staging and non-model files are out of I4's scope
# ────────────────────────────────────────────────────────────────────────────
def test_staging_path_skipped():
    """I4 must NOT fire on staging paths — that's I2's job."""
    sql = "SELECT * FROM {{ source('amazon_us', 'sales') }}"
    findings = check_non_staging_uses_ref_only(sql, STG_PATH)
    assert findings == []


def test_non_sql_file_skipped():
    sql = "SELECT * FROM {{ source('amazon_us', 'sales') }}"
    findings = check_non_staging_uses_ref_only(
        sql, "models/raw_vault/sat/_model_yml/sat_foo.yml"
    )
    assert findings == []


# ────────────────────────────────────────────────────────────────────────────
# Layer-label correctness — message names the right layer
# ────────────────────────────────────────────────────────────────────────────
@pytest.mark.parametrize("path,layer_label", [
    (HUB_PATH, "raw vault"),
    (SAT_PATH, "raw vault"),
    (PB_PATH, "bus vault"),
    (FACT_PATH, "info mart"),
])
def test_layer_label_correct(path, layer_label):
    sql = "SELECT * FROM {{ source('x', 'y') }}"
    findings = check_non_staging_uses_ref_only(sql, path)
    assert len(findings) == 1
    assert layer_label in findings[0].message.lower()


# ────────────────────────────────────────────────────────────────────────────
# Cap: I4 caps at 5 findings per file to avoid review noise
# ────────────────────────────────────────────────────────────────────────────
def test_findings_capped_at_5_per_file():
    sql = "\n".join(
        f"SELECT * FROM {{{{ source('src{i}', 'tbl{i}') }}}}" for i in range(10)
    )
    findings = check_non_staging_uses_ref_only(sql, SAT_PATH)
    assert len(findings) == 5, f"Cap should be 5, got {len(findings)}"
