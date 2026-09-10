#!/usr/bin/env python3
"""
test_category_i2.py — Tests for I2 (check_staging_source_discipline).

Layer-aware staging rule: v_psa_stg models must source() from PSA_PROD
(or EDP_BRONZE_PROD for sources registered in _sources_base_legacy.yml),
and may not ref() anything except ref('ref_business_key_collision').

Covers the spec's 9 staging scenarios + the config-proof scenario.

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_category_i2.py -v
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
    check_staging_source_discipline,
)


STG_PATH = "models/int_staging_views/foo/v_psa_stg_foo__src.sql"
NON_STG_PATH = "models/raw_vault/sat/sat_foo__src.sql"


@pytest.fixture(autouse=True)
def _clear_caches():
    _reset_caches_for_tests()
    yield
    _reset_caches_for_tests()


def _make_repo(
    tmp_path: Path,
    *,
    new_sources: str = "",
    legacy_sources: str = "",
    allowlist: str | None = None,
) -> Path:
    """Build a tmp repo with optional new + legacy sources YAMLs and a
    governance_allowlist.yml carrying the I2 staging-discipline config.
    """
    (tmp_path / "models" / "sources").mkdir(parents=True)
    if new_sources:
        (tmp_path / "models" / "sources" / "_sources_staging_psa.yml").write_text(new_sources)
    if legacy_sources:
        (tmp_path / "models" / "sources" / "_sources_base_legacy.yml").write_text(legacy_sources)
    if allowlist is None:
        allowlist = _DEFAULT_ALLOWLIST
    (tmp_path / "governance_allowlist.yml").write_text(allowlist)
    return tmp_path


_DEFAULT_ALLOWLIST = """\
allowed_databases:
  - PSA_PROD
  - EDP_BRONZE_PROD
allowed_schemas: []
allowed_projects: []
staging_source_db_default: PSA_PROD
staging_source_db_legacy:
  - PSA_PROD
  - EDP_BRONZE_PROD
legacy_sources_yaml: _sources_base_legacy.yml
"""


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 1: staging + source() in NEW yaml → PSA_PROD → PASS
# ────────────────────────────────────────────────────────────────────────────
def test_new_source_resolving_to_psa_passes(tmp_path):
    repo = _make_repo(
        tmp_path,
        new_sources="""\
version: 2
sources:
- name: amazon_us
  database: PSA_PROD
  schema: amazon_us
  tables:
  - name: sales
""",
    )
    sql = "SELECT * FROM {{ source('amazon_us', 'sales') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert findings == [], f"PSA_PROD in new yaml must pass, got {findings}"


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 2: staging + source() in NEW yaml → EDP_BRONZE_PROD → FAIL
# ────────────────────────────────────────────────────────────────────────────
def test_new_source_resolving_to_edp_bronze_fails(tmp_path):
    """A NEW source (not in legacy YAML) using EDP_BRONZE_PROD must FAIL —
    new sources are PSA-only."""
    repo = _make_repo(
        tmp_path,
        new_sources="""\
version: 2
sources:
- name: edp_bronze_new
  database: EDP_BRONZE_PROD
  schema: PUBLIC
  tables:
  - name: customer
""",
    )
    sql = "SELECT * FROM {{ source('edp_bronze_new', 'customer') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert len(findings) == 1
    f = findings[0]
    assert f.check_id == "I2"
    assert f.severity == Severity.FAIL
    assert "EDP_BRONZE_PROD" in f.message
    assert "_sources_base_legacy.yml" in f.message
    assert "only permitted for legacy" in f.message


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 3: staging + source() in LEGACY yaml → EDP_BRONZE_PROD → PASS
# ────────────────────────────────────────────────────────────────────────────
def test_legacy_source_resolving_to_edp_bronze_passes(tmp_path):
    """Sources registered in _sources_base_legacy.yml may use EDP_BRONZE_PROD."""
    repo = _make_repo(
        tmp_path,
        legacy_sources="""\
version: 2
sources:
- name: edp_legacy
  database: EDP_BRONZE_PROD
  schema: PUBLIC
  tables:
  - name: customer
""",
    )
    sql = "SELECT * FROM {{ source('edp_legacy', 'customer') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert findings == [], f"Legacy EDP_BRONZE_PROD source must pass, got {findings}"


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 4: staging + source() → BI_SANDBOX → FAIL (any yaml)
# ────────────────────────────────────────────────────────────────────────────
def test_sandbox_source_fails_even_in_legacy_yaml(tmp_path):
    repo = _make_repo(
        tmp_path,
        legacy_sources="""\
version: 2
sources:
- name: bi_sandbox
  database: BI_SANDBOX
  schema: SANDBOX
  tables:
  - name: amz_moen_wk_master_xref
""",
    )
    sql = "SELECT * FROM {{ source('bi_sandbox', 'amz_moen_wk_master_xref') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert len(findings) == 1
    f = findings[0]
    assert f.check_id == "I2"
    assert "BI_SANDBOX" in f.message
    assert "PSA_PROD" in f.message  # what they should use


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 5: staging + ref('ref_business_key_collision') → PASS
# ────────────────────────────────────────────────────────────────────────────
def test_bkcc_ref_in_staging_passes(tmp_path):
    repo = _make_repo(tmp_path)
    sql = """
    SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }}
    """
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert findings == [], f"BKCC ref is the one allowed ref in staging, got {findings}"


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 6: staging + ref('other_model') → FAIL
# ────────────────────────────────────────────────────────────────────────────
def test_non_bkcc_ref_in_staging_fails(tmp_path):
    repo = _make_repo(tmp_path)
    sql = "SELECT * FROM {{ ref('hub_customer') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert len(findings) == 1
    f = findings[0]
    assert f.check_id == "I2"
    assert "ref('hub_customer')" in f.message
    assert "ref_business_key_collision" in f.message  # exemption mentioned


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 6b: staging + ref(<named-exempted model>) → PASS (new exemption)
# ────────────────────────────────────────────────────────────────────────────
def test_named_ref_exemption_passes(tmp_path):
    """A staging ref() to a model listed in staging_ref_exemptions PASSES,
    same as the BKCC code-level exemption. Mirrors the precedent set by
    ref_business_key_collision; differs only in being config-driven rather
    than hardcoded."""
    repo = _make_repo(
        tmp_path,
        allowlist=_DEFAULT_ALLOWLIST + """\
staging_ref_exemptions:
  - v_psa_stg_ref_avc_talend_migration_cutoff_date
  - v_psa_stg_ref_appbot_talend_migration_cutoff_date
""",
    )
    sql = """
    WITH SRC_S AS (SELECT * FROM {{ source('amazon_us', 'sales') }}),
         CUTOFF AS (SELECT * FROM {{ ref('v_psa_stg_ref_avc_talend_migration_cutoff_date') }})
    SELECT s.* FROM SRC_S s INNER JOIN CUTOFF c ON s.dt > c.cutoff_date
    """
    # Need a source declaration for SRC_S to avoid the undeclared-source noise
    (tmp_path / "models" / "sources" / "_sources_extra.yml").write_text("""\
version: 2
sources:
- name: amazon_us
  database: PSA_PROD
  schema: amazon_us
  tables:
  - name: sales
""")
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert findings == [], (
        f"Named ref exemption should permit this ref() the same way BKCC is "
        f"permitted. Got: {findings}"
    )


def test_named_exemption_is_case_insensitive_via_lowercase_storage(tmp_path):
    """Config loader lowercases exemption names; ref() match is case-insensitive
    via .lower() on group(1). UPPER-cased ref() to an exemption still PASSES."""
    repo = _make_repo(
        tmp_path,
        allowlist=_DEFAULT_ALLOWLIST + """\
staging_ref_exemptions:
  - v_psa_stg_ref_my_cutoff_date
""",
    )
    # ref() with mixed case
    sql = "SELECT * FROM {{ ref('V_PSA_Stg_Ref_My_Cutoff_Date') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert findings == []


def test_unexempted_ref_still_fails_when_exemptions_configured(tmp_path):
    """RATCHET CONTRACT: adding named exemptions must NOT widen I2's ref()
    rule for unlisted refs. A ref() to a model NOT on the list still FAILs.
    """
    repo = _make_repo(
        tmp_path,
        allowlist=_DEFAULT_ALLOWLIST + """\
staging_ref_exemptions:
  - v_psa_stg_ref_my_cutoff_date
""",
    )
    sql = "SELECT * FROM {{ ref('hub_customer') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert len(findings) == 1
    assert findings[0].severity == Severity.FAIL
    assert "ref('hub_customer')" in findings[0].message
    # Error message should mention the configured exemptions so the reader
    # knows what IS allowed
    assert "v_psa_stg_ref_my_cutoff_date" in findings[0].message


def test_missing_exemptions_key_defaults_to_empty(tmp_path):
    """If governance_allowlist.yml omits staging_ref_exemptions, only BKCC
    is permitted (existing behavior preserved)."""
    repo = _make_repo(
        tmp_path,
        allowlist=_DEFAULT_ALLOWLIST,  # No staging_ref_exemptions key
    )
    # BKCC still passes
    sql_bkcc = "SELECT * FROM {{ ref('ref_business_key_collision') }}"
    assert check_staging_source_discipline(sql_bkcc, STG_PATH, repo_root=repo) == []
    # Any other ref still fails
    sql_other = "SELECT * FROM {{ ref('v_psa_stg_ref_my_cutoff_date') }}"
    findings = check_staging_source_discipline(sql_other, STG_PATH, repo_root=repo)
    assert len(findings) == 1
    assert findings[0].severity == Severity.FAIL


# ────────────────────────────────────────────────────────────────────────────
# Two-arg ref('project','model') — the model name is the LAST arg, not first
# ────────────────────────────────────────────────────────────────────────────
def test_two_arg_ref_uses_model_name_not_project_name(tmp_path):
    """REGRESSION GUARD (PR #1827 review R3): for two-arg
    `ref('project','model')`, the model name lives in the SECOND quoted
    argument, not the first. Picking the first would (a) name the project
    in the error message and (b) compare the project name against the
    exemption list — both wrong. Two failure modes covered by this test:

      Mode A (false-negative): ref('ref_business_key_collision', 'real_model')
        — the project happens to share the BKCC exemption name. If we matched
        group(1), this would be silently exempted; correct behavior is FAIL
        on 'real_model'.

      Mode B (mis-labeled error): ref('upstream', 'hub_customer') — error
        message must name 'hub_customer', not 'upstream'.
    """
    repo = _make_repo(tmp_path)

    # Mode A: project name happens to equal the BKCC exemption — model still fails.
    sql_a = "SELECT * FROM {{ ref('ref_business_key_collision', 'real_model') }}"
    findings_a = check_staging_source_discipline(sql_a, STG_PATH, repo_root=repo)
    assert len(findings_a) == 1, (
        "ref('ref_business_key_collision', 'real_model') must FAIL — the "
        "exemption applies to the MODEL name (group 2), not the project name "
        "(group 1). Got: %s" % findings_a
    )
    assert "ref('real_model')" in findings_a[0].message, (
        "Error message must name the actual model 'real_model', not the "
        "project arg. Got: %s" % findings_a[0].message
    )

    # Mode B: error message names the model, not the project.
    sql_b = "SELECT * FROM {{ ref('upstream', 'hub_customer') }}"
    findings_b = check_staging_source_discipline(sql_b, STG_PATH, repo_root=repo)
    assert len(findings_b) == 1
    assert "ref('hub_customer')" in findings_b[0].message
    assert "upstream" not in findings_b[0].message


def test_two_arg_ref_to_exempted_model_still_passes(tmp_path):
    """REGRESSION GUARD (PR #1827 review R3, positive side): a two-arg
    `ref('project', '<exempted>')` correctly matches the exemption on the
    MODEL name (group 2). Symmetric to the negative test above.
    """
    repo = _make_repo(
        tmp_path,
        allowlist=_DEFAULT_ALLOWLIST + """\
staging_ref_exemptions:
  - v_psa_stg_ref_my_cutoff_date
""",
    )
    sql = "SELECT * FROM {{ ref('upstream_project', 'v_psa_stg_ref_my_cutoff_date') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert findings == [], (
        "Two-arg ref to an exempted model must PASS (model name matches "
        "exemption). Got: %s" % findings
    )


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 7: staging source() inside /* */ → no finding
# ────────────────────────────────────────────────────────────────────────────
def test_source_in_block_comment_skipped(tmp_path):
    repo = _make_repo(
        tmp_path,
        legacy_sources="""\
version: 2
sources:
- name: bi_sandbox
  database: BI_SANDBOX
  schema: SANDBOX
  tables:
  - name: foo
""",
    )
    sql = """
    /*
    -- Old version:
    SELECT * FROM {{ source('bi_sandbox', 'foo') }}
    */
    SELECT 1
    """
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert findings == []


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 8: undeclared source → FAIL
# ────────────────────────────────────────────────────────────────────────────
def test_undeclared_source_fails(tmp_path):
    repo = _make_repo(tmp_path)
    sql = "SELECT * FROM {{ source('ghost', 'phantom') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert len(findings) == 1
    f = findings[0]
    assert f.check_id == "I2"
    assert "undeclared" in f.message
    assert "ghost.phantom" in f.message


# ────────────────────────────────────────────────────────────────────────────
# Spec scenario 9: env-swap — DEV equivalent of PSA_PROD → PASS
# ────────────────────────────────────────────────────────────────────────────
def test_dev_suffix_normalizes_to_prod(tmp_path):
    repo = _make_repo(
        tmp_path,
        new_sources="""\
version: 2
sources:
- name: amazon_dev
  database: PSA_DEV
  schema: amazon_dev
  tables:
  - name: sales
""",
    )
    sql = "SELECT * FROM {{ source('amazon_dev', 'sales') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert findings == [], f"PSA_DEV must normalize to PSA_PROD and pass, got {findings}"


def test_jinja_env_var_normalizes(tmp_path):
    """The repo's actual convention: psa_{{env_var('DBT_SOURCE_ENV')}}."""
    repo = _make_repo(
        tmp_path,
        new_sources="""\
version: 2
sources:
- name: amazon_us
  database: "psa_{{env_var('DBT_SOURCE_ENV')}}"
  schema: amazon_us
  tables:
  - name: sales
""",
    )
    sql = "SELECT * FROM {{ source('amazon_us', 'sales') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert findings == []


# ────────────────────────────────────────────────────────────────────────────
# Config proof: flip staging_source_db_default → resolution follows config
# ────────────────────────────────────────────────────────────────────────────
def test_config_driven_default_db(tmp_path):
    """Flipping staging_source_db_default to ALT_PROD must make a source
    resolving to ALT_PROD pass — proves no hardcoded PSA_PROD."""
    repo = _make_repo(
        tmp_path,
        new_sources="""\
version: 2
sources:
- name: my_alt
  database: ALT_PROD
  schema: PUBLIC
  tables:
  - name: foo
""",
        allowlist="""\
allowed_databases:
  - ALT_PROD
allowed_schemas: []
allowed_projects: []
staging_source_db_default: ALT_PROD
staging_source_db_legacy:
  - ALT_PROD
legacy_sources_yaml: _sources_base_legacy.yml
""",
    )
    sql = "SELECT * FROM {{ source('my_alt', 'foo') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=repo)
    assert findings == [], (
        "Config-driven default_db must override the PSA_PROD default. "
        f"Got: {findings}"
    )


# ────────────────────────────────────────────────────────────────────────────
# Scope guards
# ────────────────────────────────────────────────────────────────────────────
def test_non_staging_path_skipped(tmp_path):
    """I2 only fires on int_staging_views/ paths."""
    repo = _make_repo(
        tmp_path,
        legacy_sources="""\
version: 2
sources:
- name: bi_sandbox
  database: BI_SANDBOX
  schema: SANDBOX
  tables:
  - name: foo
""",
    )
    sql = "SELECT * FROM {{ source('bi_sandbox', 'foo') }}"
    findings = check_staging_source_discipline(sql, NON_STG_PATH, repo_root=repo)
    assert findings == []


def test_non_sql_file_skipped(tmp_path):
    repo = _make_repo(tmp_path)
    findings = check_staging_source_discipline(
        "anything", "models/int_staging_views/foo/foo.yml", repo_root=repo
    )
    assert findings == []


# ────────────────────────────────────────────────────────────────────────────
# Fail-open AND-gate: skip ONLY when BOTH allowlist missing AND no sources
# (PR #1827 review R-failopen — locks in the documented behavior)
# ────────────────────────────────────────────────────────────────────────────
def test_fail_open_only_when_both_allowlist_and_sources_missing(tmp_path):
    """REGRESSION GUARD (PR #1827 review R-failopen): the docstring describes
    an AND-gate for fail-open. A bare repo with no allowlist AND no sources
    YAMLs (fresh clone / test fixture without scaffolding) is skipped; any
    OTHER configuration state runs the check.

    Three matrix cells documented; row 3 is the contentious one Copilot
    flagged \u2014 the design intent (per the inline comment) is that having
    sources registered means the check has enough context to enforce, even
    if the allowlist is the missing signal (it falls back to defaults).
    """
    # Cell A: neither allowlist nor sources \u2014 SKIP (fail open)
    (tmp_path / "models").mkdir()
    sql = "SELECT * FROM {{ source('bi_sandbox', 'foo') }}"
    findings = check_staging_source_discipline(sql, STG_PATH, repo_root=tmp_path)
    assert findings == [], (
        "Fail-open AND-gate: both allowlist and sources absent must SKIP. "
        "Got: %s" % findings
    )

    # Cell B: sources present, no allowlist \u2014 check RUNS (asymmetric case
    # Copilot flagged). The defaults from load_staging_discipline_config()
    # kick in; an unregistered source must still be flagged.
    _reset_caches_for_tests()
    (tmp_path / "models" / "sources").mkdir(exist_ok=True)
    (tmp_path / "models" / "sources" / "_sources_psa.yml").write_text("""\
version: 2
sources:
- name: amazon_us
  database: PSA_PROD
  schema: amazon_us
  tables:
  - name: sales
""")
    # An UNDECLARED source must still fail even without an allowlist file
    sql_undeclared = "SELECT * FROM {{ source('made_up', 'nothing') }}"
    findings = check_staging_source_discipline(sql_undeclared, STG_PATH, repo_root=tmp_path)
    assert len(findings) == 1, (
        "Asymmetric fail-open case: sources present but allowlist missing must "
        "still enforce \u2014 undeclared source must FAIL. Got: %s" % findings
    )
    assert findings[0].check_id == "I2"
    assert "undeclared" in findings[0].message.lower()
