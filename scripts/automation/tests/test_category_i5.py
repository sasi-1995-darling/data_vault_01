#!/usr/bin/env python3
"""
test_category_i5.py — Tests for I5 (source_ref_in_governed_allowlist).

Note: this check was originally registered as I2; it was renamed to I5 when
layer-aware I2 (check_staging_source_discipline) and I4
(check_non_staging_uses_ref_only) were added. The semantics here are unchanged.

Covers the 8 scenarios from the original I5/I2 spec:
  1. source() to allowlisted DB → PASS
  2. source() to sandbox DB → FAIL, correct resolved DB in message
  3. source() to undeclared source → FAIL ("undeclared source")
  4. first-party single-arg ref() → PASS
  5. mixed model (one allowlisted + one sandbox source) → only the sandbox flagged
  6. source() inside a /* */ block comment → no finding
  7. env-swap: DEV equivalent of allowlisted PROD DB → PASS
  8. config-driven: adding sandbox to governance_allowlist.yml → no finding
     (proves no hardcoded allowlist)

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_category_i5.py -v
"""
import sys
from pathlib import Path

import pytest

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_review_config import FileStatus, _reset_caches_for_tests  # noqa: E402
from code_reviewer import (  # noqa: E402
    Severity,
    check_source_ref_in_governed_allowlist,
)


SQL_PATH = "models/raw_vault/sat/sat_foo__src.sql"


@pytest.fixture(autouse=True)
def _clear_caches():
    """Reset memoization between tests so per-test tmp_path fixtures don't leak."""
    _reset_caches_for_tests()
    yield
    _reset_caches_for_tests()


def _make_repo(
    tmp_path: Path,
    sources_yaml: str,
    allowlist_yaml: str,
    sources_filename: str = "_sources_x.yml",
) -> Path:
    """Build a minimal repo skeleton under tmp_path with a sources YAML
    and a governance_allowlist.yml.
    """
    (tmp_path / "models" / "sources").mkdir(parents=True)
    (tmp_path / "models" / "sources" / sources_filename).write_text(sources_yaml)
    (tmp_path / "governance_allowlist.yml").write_text(allowlist_yaml)
    return tmp_path


_DEFAULT_ALLOWLIST = """\
allowed_databases:
  - EDP_BRONZE_PROD
  - PSA_PROD
allowed_schemas: []
allowed_projects: []
"""


# ────────────────────────────────────────────────────────────────────────────
# Scenario 1: source() resolving to allowlisted DB → PASS
# ────────────────────────────────────────────────────────────────────────────
def test_scenario_1_allowlisted_source_passes(tmp_path):
    repo = _make_repo(
        tmp_path,
        sources_yaml="""\
version: 2
sources:
- name: edp_bronze
  database: EDP_BRONZE_PROD
  schema: PUBLIC
  tables:
  - name: customer
""",
        allowlist_yaml=_DEFAULT_ALLOWLIST,
    )
    sql = "SELECT * FROM {{ source('edp_bronze', 'customer') }}"
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert findings == [], f"Expected no findings, got {[(f.check_id, f.message) for f in findings]}"


# ────────────────────────────────────────────────────────────────────────────
# Scenario 2: source() to sandbox DB → FAIL with correct resolved DB
# ────────────────────────────────────────────────────────────────────────────
def test_scenario_2_sandbox_source_fails(tmp_path):
    repo = _make_repo(
        tmp_path,
        sources_yaml="""\
version: 2
sources:
- name: bi_sandbox
  database: BI_SANDBOX
  schema: SANDBOX
  tables:
  - name: amz_moen_wk_master_xref
""",
        allowlist_yaml=_DEFAULT_ALLOWLIST,
    )
    sql = "SELECT * FROM {{ source('bi_sandbox', 'amz_moen_wk_master_xref') }}"
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert len(findings) == 1
    f = findings[0]
    assert f.check_id == "I5"
    assert f.severity == Severity.FAIL
    assert "bi_sandbox.amz_moen_wk_master_xref" in f.message
    assert "BI_SANDBOX.SANDBOX" in f.message, (
        f"Resolved DB.schema missing from message: {f.message!r}"
    )
    assert "outside the governed allowlist" in f.message
    assert "EDP_BRONZE_PROD" in f.message  # allowlist mentioned in message


# ────────────────────────────────────────────────────────────────────────────
# Scenario 3: undeclared source → FAIL
# ────────────────────────────────────────────────────────────────────────────
def test_scenario_3_undeclared_source_fails(tmp_path):
    repo = _make_repo(
        tmp_path,
        sources_yaml="""\
version: 2
sources:
- name: edp_bronze
  database: EDP_BRONZE_PROD
  schema: PUBLIC
  tables:
  - name: customer
""",
        allowlist_yaml=_DEFAULT_ALLOWLIST,
    )
    # 'ghost_source' is not declared in any sources YAML
    sql = "SELECT * FROM {{ source('ghost_source', 'phantom_table') }}"
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert len(findings) == 1
    f = findings[0]
    assert f.check_id == "I5"
    assert f.severity == Severity.FAIL
    assert "undeclared source" in f.message
    assert "ghost_source.phantom_table" in f.message


# ────────────────────────────────────────────────────────────────────────────
# Scenario 4: first-party single-arg ref() → PASS
# ────────────────────────────────────────────────────────────────────────────
def test_scenario_4_first_party_ref_passes(tmp_path):
    repo = _make_repo(
        tmp_path,
        sources_yaml="""\
version: 2
sources: []
""",
        allowlist_yaml=_DEFAULT_ALLOWLIST,
    )
    sql = "SELECT * FROM {{ ref('hub_customer') }}"
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert findings == [], f"First-party ref must pass, got {findings}"


# ────────────────────────────────────────────────────────────────────────────
# Scenario 5: mixed model — only sandbox source flagged
# ────────────────────────────────────────────────────────────────────────────
def test_scenario_5_mixed_only_sandbox_reported(tmp_path):
    repo = _make_repo(
        tmp_path,
        sources_yaml="""\
version: 2
sources:
- name: edp_bronze
  database: EDP_BRONZE_PROD
  schema: PUBLIC
  tables:
  - name: customer
- name: bi_sandbox
  database: BI_SANDBOX
  schema: SANDBOX
  tables:
  - name: manual_xref
""",
        allowlist_yaml=_DEFAULT_ALLOWLIST,
    )
    sql = """
    SELECT a.*, b.*
    FROM {{ source('edp_bronze', 'customer') }} a
    LEFT JOIN {{ source('bi_sandbox', 'manual_xref') }} b ON a.id = b.id
    """
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert len(findings) == 1, f"Expected exactly 1 finding (sandbox only), got {findings}"
    # The finding's resolved source must be the sandbox one, not edp_bronze.
    # (edp_bronze_prod legitimately appears in the message because the allowlist
    # is enumerated — assert on the *resolved source* identifier instead.)
    assert "source 'bi_sandbox.manual_xref' resolves to" in findings[0].message
    assert "source 'edp_bronze.customer'" not in findings[0].message


# ────────────────────────────────────────────────────────────────────────────
# Scenario 6: source() inside block comment → no finding
# ────────────────────────────────────────────────────────────────────────────
def test_scenario_6_source_in_block_comment_skipped(tmp_path):
    repo = _make_repo(
        tmp_path,
        sources_yaml="""\
version: 2
sources:
- name: bi_sandbox
  database: BI_SANDBOX
  schema: SANDBOX
  tables:
  - name: manual_xref
""",
        allowlist_yaml=_DEFAULT_ALLOWLIST,
    )
    sql = """
    /*
    Example usage from earlier draft (intentionally commented out):
    SELECT * FROM {{ source('bi_sandbox', 'manual_xref') }}
    */
    SELECT 1
    """
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert findings == [], f"Block-commented source() must not trigger I2, got {findings}"


def test_scenario_6b_source_in_line_comment_skipped(tmp_path):
    """Sanity: line-comment skip works too (mirrors block-comment case)."""
    repo = _make_repo(
        tmp_path,
        sources_yaml="""\
version: 2
sources:
- name: bi_sandbox
  database: BI_SANDBOX
  schema: SANDBOX
  tables:
  - name: manual_xref
""",
        allowlist_yaml=_DEFAULT_ALLOWLIST,
    )
    sql = "-- TODO migrate from {{ source('bi_sandbox', 'manual_xref') }}\nSELECT 1\n"
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert findings == []


# ────────────────────────────────────────────────────────────────────────────
# Scenario 7: env-swap — DEV equivalent of allowlisted PROD DB → PASS
# ────────────────────────────────────────────────────────────────────────────
def test_scenario_7_env_dev_suffix_normalized(tmp_path):
    """A source declared with database 'EDP_BRONZE_DEV' should pass against
    an allowlist entry of 'EDP_BRONZE_PROD' (env-swap normalization)."""
    repo = _make_repo(
        tmp_path,
        sources_yaml="""\
version: 2
sources:
- name: edp_bronze_dev
  database: EDP_BRONZE_DEV
  schema: PUBLIC
  tables:
  - name: customer
""",
        allowlist_yaml=_DEFAULT_ALLOWLIST,
    )
    sql = "SELECT * FROM {{ source('edp_bronze_dev', 'customer') }}"
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert findings == [], f"DEV-suffixed equivalent of PROD must pass, got {findings}"


def test_scenario_7b_jinja_env_var_normalized(tmp_path):
    """A source declared with database psa_{{env_var('DBT_SOURCE_ENV')}} (the
    project's actual convention) must normalize to PSA_PROD and pass."""
    repo = _make_repo(
        tmp_path,
        sources_yaml="""\
version: 2
sources:
- name: amazon_us
  database: "psa_{{env_var('DBT_SOURCE_ENV')}}"
  schema: amazon_us
  tables:
  - name: winn_avc_sales_view
""",
        allowlist_yaml=_DEFAULT_ALLOWLIST,
    )
    sql = "SELECT * FROM {{ source('amazon_us', 'winn_avc_sales_view') }}"
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert findings == [], f"Jinja env_var-templated PSA database must pass, got {findings}"


# ────────────────────────────────────────────────────────────────────────────
# Scenario 8: config-driven — add sandbox to allowlist → previously-failing model PASSES
# ────────────────────────────────────────────────────────────────────────────
def test_scenario_8_allowlist_is_config_driven(tmp_path):
    """Proves no hardcoded allowlist: adding BI_SANDBOX to
    governance_allowlist.yml makes the previously-failing sandbox source pass.
    """
    repo = _make_repo(
        tmp_path,
        sources_yaml="""\
version: 2
sources:
- name: bi_sandbox
  database: BI_SANDBOX
  schema: SANDBOX
  tables:
  - name: manual_xref
""",
        allowlist_yaml="""\
allowed_databases:
  - EDP_BRONZE_PROD
  - PSA_PROD
  - BI_SANDBOX
allowed_schemas: []
allowed_projects: []
""",
    )
    sql = "SELECT * FROM {{ source('bi_sandbox', 'manual_xref') }}"
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert findings == [], (
        "Adding sandbox to allowlist must make I2 pass (proves config-driven, "
        f"no hardcoded list). Got: {findings}"
    )


# ────────────────────────────────────────────────────────────────────────────
# Additional safety checks
# ────────────────────────────────────────────────────────────────────────────
def test_schema_level_allowlist_works(tmp_path):
    """Schema-level allowance: only the specific DB.SCHEMA combination passes."""
    repo = _make_repo(
        tmp_path,
        sources_yaml="""\
version: 2
sources:
- name: mixed_db_governed_schema
  database: MIXED_DB
  schema: GOVERNED_SCHEMA
  tables:
  - name: foo
- name: mixed_db_ungoverned_schema
  database: MIXED_DB
  schema: UNGOVERNED_SCHEMA
  tables:
  - name: bar
""",
        allowlist_yaml="""\
allowed_databases:
  - EDP_BRONZE_PROD
allowed_schemas:
  - MIXED_DB.GOVERNED_SCHEMA
allowed_projects: []
""",
    )
    sql = """
    SELECT 1 FROM {{ source('mixed_db_governed_schema', 'foo') }}
    UNION ALL
    SELECT 1 FROM {{ source('mixed_db_ungoverned_schema', 'bar') }}
    """
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert len(findings) == 1, f"Expected only the ungoverned-schema finding, got {findings}"
    assert "mixed_db_ungoverned_schema.bar" in findings[0].message


def test_cross_project_ref_fails_when_project_unlisted(tmp_path):
    """Two-arg ref('project', 'model') fails if project is not in allowed_projects.
    (No-op branch in this repo as of 2026-06-22, but the validation runs.)"""
    repo = _make_repo(
        tmp_path,
        sources_yaml="version: 2\nsources: []\n",
        allowlist_yaml=_DEFAULT_ALLOWLIST,  # allowed_projects is []
    )
    sql = "SELECT * FROM {{ ref('ungoverned_project', 'their_model') }}"
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert len(findings) == 1
    assert "ungoverned_project" in findings[0].message
    assert findings[0].severity == Severity.FAIL


def test_cross_project_ref_passes_when_project_allowlisted(tmp_path):
    repo = _make_repo(
        tmp_path,
        sources_yaml="version: 2\nsources: []\n",
        allowlist_yaml="""\
allowed_databases:
  - EDP_BRONZE_PROD
allowed_schemas: []
allowed_projects:
  - shared_dv_project
""",
    )
    sql = "SELECT * FROM {{ ref('shared_dv_project', 'shared_model') }}"
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=repo)
    assert findings == []


def test_missing_allowlist_fails_open(tmp_path):
    """If governance_allowlist.yml is missing, I2 must not block PRs — fail open."""
    (tmp_path / "models" / "sources").mkdir(parents=True)
    (tmp_path / "models" / "sources" / "_sources_x.yml").write_text(
        "version: 2\nsources:\n- name: bi_sandbox\n  database: BI_SANDBOX\n"
        "  schema: SANDBOX\n  tables:\n  - name: foo\n"
    )
    # NOTE: no governance_allowlist.yml at tmp_path

    sql = "SELECT * FROM {{ source('bi_sandbox', 'foo') }}"
    findings = check_source_ref_in_governed_allowlist(sql, SQL_PATH, repo_root=tmp_path)
    assert findings == [], (
        "Missing allowlist must fail open (no findings), not block every PR. "
        f"Got: {findings}"
    )


def test_non_sql_file_skipped(tmp_path):
    """I2 only applies to .sql files."""
    repo = _make_repo(
        tmp_path,
        sources_yaml="version: 2\nsources:\n- name: bi_sandbox\n  database: BI_SANDBOX\n"
                     "  schema: SANDBOX\n  tables:\n  - name: foo\n",
        allowlist_yaml=_DEFAULT_ALLOWLIST,
    )
    yml_path = "models/raw_vault/sat/_model_yml/sat_foo.yml"
    sql_in_yml = "SELECT * FROM {{ source('bi_sandbox', 'foo') }}"
    findings = check_source_ref_in_governed_allowlist(sql_in_yml, yml_path, repo_root=repo)
    assert findings == []
