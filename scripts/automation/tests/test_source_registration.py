"""
Regression tests for _register_source() rewrite.

These tests use a real copy of models/sources/_sources_staging_psa.yml,
not synthetic fixtures, to catch structure/format regressions.
"""

import copy
import re
import sys
from pathlib import Path

import pytest
import yaml
from ruamel.yaml import YAML

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pipeline_orchestrator as po


@pytest.fixture
def real_sources_fixture(tmp_path):
    """Copy real _sources_staging_psa.yml to a temp project root."""
    repo_root = Path(__file__).resolve().parents[3]
    src_file = repo_root / "models" / "sources" / "_sources_staging_psa.yml"

    temp_root = tmp_path / "repo"
    target_dir = temp_root / "models" / "sources"
    target_dir.mkdir(parents=True, exist_ok=True)
    temp_file = target_dir / "_sources_staging_psa.yml"
    temp_file.write_text(src_file.read_text())

    original_root = po.PROJECT_ROOT
    po.PROJECT_ROOT = temp_root
    try:
        yield temp_file
    finally:
        po.PROJECT_ROOT = original_root


def _load_yaml(path: Path):
    with path.open() as f:
        return yaml.safe_load(f)


def _source_map(data):
    return {s.get("name"): s for s in data.get("sources", [])}


def _table_names(source_block):
    return [t.get("name") for t in source_block.get("tables", [])]


def _assert_yaml_valid(path: Path):
    with path.open() as f:
        yaml.safe_load(f)


def _assert_no_orphan_top_level_table_entry(path: Path, table_name: str):
    text = path.read_text()

    # True orphan regression signature: table accidentally inserted as a
    # top-level source block (column 0 list item under sources).
    top_level_pattern = re.compile(rf"^- name: {re.escape(table_name)}$", re.MULTILINE)
    assert top_level_pattern.search(text) is None, (
        f"Found malformed top-level source entry for table {table_name}"
    )


def _remove_table_if_present(path: Path, schema_name: str, table_name: str):
    """Remove a table from a schema block in fixture setup if already present.
    Uses ruamel.yaml round-trip to preserve original formatting/quoting."""
    yaml_rt = YAML()
    yaml_rt.preserve_quotes = True
    yaml_rt.width = 4096

    with open(path) as f:
        data = yaml_rt.load(f)

    for src in data.get("sources", []):
        if (src.get("name") or "").lower() == schema_name.lower():
            tables = src.get("tables", [])
            src["tables"] = [
                t for t in tables if (t.get("name") or "").lower() != table_name.lower()
            ]
            break

    with open(path, "w") as f:
        yaml_rt.dump(data, f)



def _assert_sap_bw_prd_guard(data):
    sap_bw_prd = None
    for src in data.get("sources", []):
        if (src.get("name") or "").lower() == "sap_bw_prd":
            sap_bw_prd = src
            break

    assert sap_bw_prd is not None, "sap_bw_prd source block must exist"
    assert "database" in sap_bw_prd, "sap_bw_prd must keep database key"
    assert "schema" in sap_bw_prd, "sap_bw_prd must keep schema key"
    assert "tables" in sap_bw_prd and isinstance(sap_bw_prd["tables"], list), (
        "sap_bw_prd must keep tables list"
    )

    sap_tables = {t.get("name") for t in sap_bw_prd.get("tables", [])}
    assert "z_zapopland" in sap_tables, "z_zapopland must remain under sap_bw_prd"
    assert "z_zapoplanm" in sap_tables, "z_zapoplanm must remain under sap_bw_prd"


def _assert_common_post_call_guards(path: Path, expected_source_count: int, table_name: str):
    _assert_yaml_valid(path)
    data = _load_yaml(path)
    assert len(data.get("sources", [])) == expected_source_count
    _assert_sap_bw_prd_guard(data)
    _assert_no_orphan_top_level_table_entry(path, table_name)


def test_source_registration_same_schema_two_tables_sequentially(real_sources_fixture):
    """Test 1: Same schema, two tables added sequentially."""
    fixture_path = real_sources_fixture

    # Ensure the scenario always exercises add-path even if these tables already
    # exist in the real fixture from prior sessions.
    _remove_table_if_present(fixture_path, "lrsn_psft_sysadm", "ps_pymt_trms_net")
    _remove_table_if_present(fixture_path, "lrsn_psft_sysadm", "ps_pymt_trms_dscnt")

    baseline_text = fixture_path.read_text()
    baseline_data = _load_yaml(fixture_path)
    baseline_sources = baseline_data.get("sources", [])
    baseline_count = len(baseline_sources)
    baseline_map = _source_map(baseline_data)

    assert po._register_source("lrsn_psft_sysadm", "ps_pymt_trms_net") is True
    _assert_common_post_call_guards(fixture_path, baseline_count, "ps_pymt_trms_net")

    assert po._register_source("lrsn_psft_sysadm", "ps_pymt_trms_dscnt") is True
    _assert_common_post_call_guards(fixture_path, baseline_count, "ps_pymt_trms_dscnt")

    current_data = _load_yaml(fixture_path)
    current_map = _source_map(current_data)

    target_block = current_map["lrsn_psft_sysadm"]
    tables = set(_table_names(target_block))
    assert "ps_pymt_trms_net" in tables
    assert "ps_pymt_trms_dscnt" in tables

    # Additive-only assertion: all non-target source blocks unchanged.
    for src_name, src_block in baseline_map.items():
        if src_name == "lrsn_psft_sysadm":
            continue
        assert current_map[src_name] == src_block

    # Ensure no accidental top-level orphan table lines for added tables.
    _assert_no_orphan_top_level_table_entry(fixture_path, "ps_pymt_trms_net")
    _assert_no_orphan_top_level_table_entry(fixture_path, "ps_pymt_trms_dscnt")

    assert baseline_text != fixture_path.read_text(), "Expected additive changes for new tables"


def test_source_registration_new_schema_then_second_table(real_sources_fixture):
    """Test 2: New schema block created, then second table added to it."""
    fixture_path = real_sources_fixture
    baseline_data = _load_yaml(fixture_path)
    baseline_count = len(baseline_data.get("sources", []))
    baseline_map = _source_map(baseline_data)

    assert po._register_source("brand_new_schema", "table_one") is True
    _assert_common_post_call_guards(fixture_path, baseline_count + 1, "table_one")

    after_first = _load_yaml(fixture_path)
    after_first_map = _source_map(after_first)
    new_block = after_first_map.get("brand_new_schema")
    assert new_block is not None
    assert "database" in new_block
    assert "schema" in new_block
    assert "tables" in new_block
    assert "table_one" in set(_table_names(new_block))

    assert po._register_source("brand_new_schema", "table_two") is True
    _assert_common_post_call_guards(fixture_path, baseline_count + 1, "table_two")

    current_data = _load_yaml(fixture_path)
    current_map = _source_map(current_data)
    new_block = current_map["brand_new_schema"]
    new_tables = set(_table_names(new_block))
    assert "table_one" in new_tables
    assert "table_two" in new_tables

    # Existing blocks unchanged.
    for src_name, src_block in baseline_map.items():
        assert current_map[src_name] == src_block


def test_source_registration_two_tables_different_schemas(real_sources_fixture):
    """Test 3: Two tables in different schema blocks (no collision)."""
    fixture_path = real_sources_fixture
    baseline_data = _load_yaml(fixture_path)
    baseline_count = len(baseline_data.get("sources", []))
    baseline_map = _source_map(baseline_data)

    # Make deep copies for block-level contamination checks.
    lrsn_before = copy.deepcopy(baseline_map["lrsn_psft_sysadm"])
    outd_before = copy.deepcopy(baseline_map["outd_ocf_ap"])

    assert po._register_source("lrsn_psft_sysadm", "ps_new_table") is True
    _assert_common_post_call_guards(fixture_path, baseline_count, "ps_new_table")

    assert po._register_source("outd_ocf_ap", "ap_new_table") is True
    _assert_common_post_call_guards(fixture_path, baseline_count, "ap_new_table")

    current_data = _load_yaml(fixture_path)
    current_map = _source_map(current_data)

    lrsn_tables = set(_table_names(current_map["lrsn_psft_sysadm"]))
    outd_tables = set(_table_names(current_map["outd_ocf_ap"]))

    assert "ps_new_table" in lrsn_tables
    assert "ap_new_table" in outd_tables

    assert "ap_new_table" not in lrsn_tables
    assert "ps_new_table" not in outd_tables

    # Check no cross-contamination outside intended changes.
    for src_name, src_block in baseline_map.items():
        if src_name in {"lrsn_psft_sysadm", "outd_ocf_ap"}:
            continue
        assert current_map[src_name] == src_block

    # Block-level key metadata remains unchanged for touched blocks.
    for key in ["name", "database", "schema"]:
        assert current_map["lrsn_psft_sysadm"].get(key) == lrsn_before.get(key)
        assert current_map["outd_ocf_ap"].get(key) == outd_before.get(key)


def test_source_registration_idempotent_reregistration(real_sources_fixture):
    """Test 4: Re-register existing table should produce no changes."""
    fixture_path = real_sources_fixture

    # First call: register the table (may or may not already exist on main)
    po._register_source("lrsn_psft_sysadm", "ps_pymt_trms_hdr")

    # Snapshot after first registration
    before_text = fixture_path.read_text()
    before_data = _load_yaml(fixture_path)
    before_count = len(before_data.get("sources", []))

    # Second call: table already exists → should return False (no-op)
    result = po._register_source("lrsn_psft_sysadm", "ps_pymt_trms_hdr")
    assert result is False

    _assert_common_post_call_guards(fixture_path, before_count, "ps_pymt_trms_hdr")

    after_text = fixture_path.read_text()
    after_data = _load_yaml(fixture_path)

    assert after_text == before_text, "File content must remain identical on idempotent call"

    source_block = _source_map(after_data)["lrsn_psft_sysadm"]
    table_names = _table_names(source_block)
    assert table_names.count("ps_pymt_trms_hdr") == 1, "No duplicate table entry allowed"
