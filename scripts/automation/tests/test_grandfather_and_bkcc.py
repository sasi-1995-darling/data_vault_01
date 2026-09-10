#!/usr/bin/env python3
"""
test_grandfather_and_bkcc.py — Tests for the BKCC code-level exemption and
the .code_review_grandfather frozen burn-down list.

Coverage:
  BKCC exemption (permanent, code-level):
    - ref_business_key_collision.sql with source() → no I4 finding
    - other raw_vault file with source() → I4 fires normally
  Grandfather downgrade:
    - I2 finding on listed file → WARN with [GRANDFATHERED] prefix
    - I2 finding on UNlisted file → still FAIL (new violation blocked)
    - I4 finding on listed file → WARN with [GRANDFATHERED] prefix
    - I4 finding on UNlisted file → still FAIL
  Loader contract:
    - missing grandfather file → empty set (fail open)
    - blank lines and # comments ignored
    - malformed lines logged-and-skipped (not raised)
  Validation:
    - is_grandfathered(check_id, file) → True/False as expected

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_grandfather_and_bkcc.py -v
"""
import sys
from pathlib import Path

import pytest

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_review_config import (  # noqa: E402
    FileStatus,
    _reset_caches_for_tests,
    is_grandfathered,
    load_grandfather_list,
)
from code_reviewer import (  # noqa: E402
    Severity,
    check_grain_excludes_metadata,
    check_non_staging_uses_ref_only,
    check_sat_has_foreign_key,
    check_staging_source_discipline,
)


@pytest.fixture(autouse=True)
def _clear_caches():
    _reset_caches_for_tests()
    yield
    _reset_caches_for_tests()


def _make_repo(
    tmp_path: Path,
    grandfather_text: str | None = None,
    sources_yaml: str | None = None,
    allowlist: str | None = None,
) -> Path:
    """Build a tmp repo: optional grandfather file, optional sources YAML,
    optional allowlist (sane default).
    """
    (tmp_path / "models" / "sources").mkdir(parents=True)
    if sources_yaml:
        (tmp_path / "models" / "sources" / "_sources_x.yml").write_text(sources_yaml)
    if allowlist is None:
        allowlist = """\
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
    (tmp_path / "governance_allowlist.yml").write_text(allowlist)
    if grandfather_text is not None:
        gf_dir = tmp_path / "scripts" / "automation"
        gf_dir.mkdir(parents=True)
        (gf_dir / ".code_review_grandfather").write_text(grandfather_text)
    return tmp_path


# ══════════════════════════════════════════════════════════════════════════
# BKCC permanent exemption
# ══════════════════════════════════════════════════════════════════════════

class TestBkccCodeLevelExemption:
    """ref_business_key_collision.sql legitimately reads source() and must
    NEVER be flagged by I4, regardless of grandfather list state."""

    def test_bkcc_file_with_source_no_finding(self, tmp_path):
        repo = _make_repo(tmp_path, grandfather_text=None)
        sql = "SELECT * FROM {{ source('bkcc_admin', 'ref_business_key_collision') }}"
        # The exemption keys on basename, so any raw_vault subpath works
        path = "models/raw_vault/reference_table/ref_business_key_collision.sql"
        findings = check_non_staging_uses_ref_only(sql, path, repo_root=repo)
        assert findings == [], (
            f"BKCC reference table must be exempt from I4. Got: {findings}"
        )

    def test_other_raw_vault_file_with_source_still_fails(self, tmp_path):
        repo = _make_repo(tmp_path, grandfather_text=None)
        sql = "SELECT * FROM {{ source('foo', 'bar') }}"
        path = "models/raw_vault/reference_table/ref_other_table.sql"
        findings = check_non_staging_uses_ref_only(sql, path, repo_root=repo)
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL
        assert findings[0].check_id == "I4"

    def test_bkcc_exempt_even_with_empty_grandfather(self, tmp_path):
        """Exemption is code-level, not list-based — works with no list."""
        repo = _make_repo(tmp_path, grandfather_text="")  # empty list file
        sql = "SELECT * FROM {{ source('x', 'y') }}"
        path = "models/raw_vault/somewhere/ref_business_key_collision.sql"
        findings = check_non_staging_uses_ref_only(sql, path, repo_root=repo)
        assert findings == []

    def test_bkcc_basename_only_match(self, tmp_path):
        """A file NAMED something_similar must still be checked normally."""
        repo = _make_repo(tmp_path, grandfather_text=None)
        sql = "SELECT * FROM {{ source('x', 'y') }}"
        # Similar name, not the exempt file
        path = "models/raw_vault/reference_table/ref_business_key_collision_v2.sql"
        findings = check_non_staging_uses_ref_only(sql, path, repo_root=repo)
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL


# ══════════════════════════════════════════════════════════════════════════
# Grandfather downgrade — I4
# ══════════════════════════════════════════════════════════════════════════

class TestI4GrandfatherDowngrade:
    def test_listed_file_downgrades_fail_to_warn(self, tmp_path):
        repo = _make_repo(
            tmp_path,
            grandfather_text=(
                "I4 models/bus_vault/pit_bridge/connected_device/pb_listed.sql\n"
            ),
        )
        sql = "SELECT * FROM {{ source('x', 'y') }}"
        path = "models/bus_vault/pit_bridge/connected_device/pb_listed.sql"
        findings = check_non_staging_uses_ref_only(sql, path, repo_root=repo)
        assert len(findings) == 1
        f = findings[0]
        assert f.severity == Severity.WARN, (
            f"Grandfathered finding must downgrade to WARN, got {f.severity}"
        )
        assert f.message.startswith("[GRANDFATHERED]"), (
            f"Downgraded message must be marked: {f.message!r}"
        )
        assert "BURN-DOWN" in f.suggestion, (
            f"Suggestion must mention burn-down: {f.suggestion!r}"
        )

    def test_unlisted_file_still_fails_new_violation_blocked(self, tmp_path):
        """The whole point: NEW violations must still FAIL even when other
        files are grandfathered."""
        repo = _make_repo(
            tmp_path,
            grandfather_text=(
                "I4 models/bus_vault/pit_bridge/old_existing_file.sql\n"
            ),
        )
        sql = "SELECT * FROM {{ source('x', 'y') }}"
        # NEW file not on the list
        path = "models/bus_vault/pit_bridge/brand_new_violation.sql"
        findings = check_non_staging_uses_ref_only(sql, path, repo_root=repo)
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL, (
            "New (unlisted) violation MUST still FAIL — the grandfather "
            "list is per-file. Otherwise the ratchet is broken."
        )
        assert "[GRANDFATHERED]" not in findings[0].message


# ══════════════════════════════════════════════════════════════════════════
# Grandfather downgrade — I2
# ══════════════════════════════════════════════════════════════════════════

class TestI2GrandfatherDowngrade:
    def test_listed_file_downgrades(self, tmp_path):
        repo = _make_repo(
            tmp_path,
            grandfather_text=(
                "I2 models/int_staging_views/foo/v_psa_stg_legacy_ref_user.sql\n"
            ),
        )
        sql = "SELECT * FROM {{ ref('hub_customer') }}"
        path = "models/int_staging_views/foo/v_psa_stg_legacy_ref_user.sql"
        findings = check_staging_source_discipline(sql, path, repo_root=repo)
        assert len(findings) == 1
        assert findings[0].severity == Severity.WARN
        assert findings[0].message.startswith("[GRANDFATHERED]")

    def test_unlisted_file_still_fails(self, tmp_path):
        repo = _make_repo(
            tmp_path,
            grandfather_text=(
                "I2 models/int_staging_views/other/v_psa_stg_old.sql\n"
            ),
        )
        sql = "SELECT * FROM {{ ref('hub_customer') }}"
        path = "models/int_staging_views/foo/v_psa_stg_brand_new.sql"
        findings = check_staging_source_discipline(sql, path, repo_root=repo)
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL
        assert "[GRANDFATHERED]" not in findings[0].message


# ══════════════════════════════════════════════════════════════════════════
# Loader contract
# ══════════════════════════════════════════════════════════════════════════

class TestGrandfatherLoader:
    def test_missing_file_returns_empty_set(self, tmp_path):
        # No .code_review_grandfather created
        result = load_grandfather_list(tmp_path)
        assert result == set()

    def test_blank_lines_and_comments_ignored(self, tmp_path):
        gf_dir = tmp_path / "scripts" / "automation"
        gf_dir.mkdir(parents=True)
        (gf_dir / ".code_review_grandfather").write_text("""\
# This is a comment
# Another comment

I2 models/int_staging_views/a.sql

# Section break
I4 models/raw_vault/b.sql

""")
        result = load_grandfather_list(tmp_path)
        assert result == {
            ("I2", "models/int_staging_views/a.sql"),
            ("I4", "models/raw_vault/b.sql"),
        }

    def test_malformed_lines_logged_not_raised(self, tmp_path, caplog):
        import logging
        gf_dir = tmp_path / "scripts" / "automation"
        gf_dir.mkdir(parents=True)
        (gf_dir / ".code_review_grandfather").write_text("""\
I2 models/int_staging_views/valid.sql
malformed_line_no_path
I4 models/raw_vault/also_valid.sql
""")
        with caplog.at_level(logging.WARNING):
            result = load_grandfather_list(tmp_path)
        assert result == {
            ("I2", "models/int_staging_views/valid.sql"),
            ("I4", "models/raw_vault/also_valid.sql"),
        }
        # Malformed line warning logged
        assert any("malformed line" in rec.message for rec in caplog.records)

    def test_backslash_paths_normalized(self, tmp_path):
        """Windows-style paths normalize to forward slashes."""
        gf_dir = tmp_path / "scripts" / "automation"
        gf_dir.mkdir(parents=True)
        (gf_dir / ".code_review_grandfather").write_text(
            r"I2 models\int_staging_views\winpath.sql"
        )
        result = load_grandfather_list(tmp_path)
        assert ("I2", "models/int_staging_views/winpath.sql") in result

    def test_is_grandfathered_helper(self):
        gf = {("I2", "models/foo/bar.sql"), ("I4", "models/bus_vault/x.sql")}
        assert is_grandfathered("I2", "models/foo/bar.sql", gf) is True
        assert is_grandfathered("I4", "models/bus_vault/x.sql", gf) is True
        assert is_grandfathered("I2", "models/foo/other.sql", gf) is False
        assert is_grandfathered("I5", "models/foo/bar.sql", gf) is False
        # Backslash path also matches (normalization in helper)
        assert is_grandfathered("I2", "models\\foo\\bar.sql", gf) is True


# ══════════════════════════════════════════════════════════════════════════
# Cross-cutting: BKCC + grandfather work together
# ══════════════════════════════════════════════════════════════════════════

def test_bkcc_exemption_takes_precedence_over_grandfather(tmp_path):
    """If someone tries to put BKCC on the grandfather list anyway, the
    code-level exemption skips it before the grandfather logic runs."""
    repo = _make_repo(
        tmp_path,
        grandfather_text=(
            "I4 models/raw_vault/reference_table/ref_business_key_collision.sql\n"
        ),
    )
    sql = "SELECT * FROM {{ source('x', 'y') }}"
    path = "models/raw_vault/reference_table/ref_business_key_collision.sql"
    findings = check_non_staging_uses_ref_only(sql, path, repo_root=repo)
    # Code-level exemption returns [] before grandfather is consulted
    assert findings == []


# ══════════════════════════════════════════════════════════════════════════
# Grandfather downgrade — H10 (grain excludes metadata)
# ══════════════════════════════════════════════════════════════════════════

_BAD_H10_YAML = """
version: 2
models:
  - name: sat_legacy_correctness_debt__src
    columns:
      - name: SOMETHING_HK
      - name: LOAD_DTS
      - name: HASHDIFF
    data_tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - SOMETHING_HK
            - LOAD_DTS
            - HASHDIFF
"""


class TestH10GrandfatherDowngrade:
    """H10 is the first correctness-tier check on the grandfather list.
    Asymmetric ratchet: pre-existing entries downgrade to WARN, new violations
    still FAIL. Same shape as I2/I4 but FBIN policy adds an extra constraint
    documented in the grandfather header: NEW correctness-tier entries require
    explicit DataOps lead waiver (policy lives in the header text, not in
    code — these tests verify the runtime behavior only)."""

    def test_listed_file_downgrades_h10(self, tmp_path):
        repo = _make_repo(
            tmp_path,
            grandfather_text=(
                "H10 models/raw_vault/sat/sat_legacy_correctness_debt__src.yml\n"
            ),
        )
        path = "models/raw_vault/sat/sat_legacy_correctness_debt__src.yml"
        findings = check_grain_excludes_metadata(
            "", path, _BAD_H10_YAML, FileStatus.NEW, repo_root=repo,
        )
        assert len(findings) == 1
        f = findings[0]
        assert f.severity == Severity.WARN
        assert f.message.startswith("[GRANDFATHERED]")
        assert "HASHDIFF" in f.message  # original message preserved after prefix

    def test_unlisted_file_still_fails_h10(self, tmp_path):
        """RATCHET CONTRACT: a new sat with HASHDIFF in grain — not on the
        list — must FAIL even when other files are grandfathered.
        This is THE test that proves the ratchet works."""
        repo = _make_repo(
            tmp_path,
            grandfather_text=(
                "H10 models/raw_vault/sat/sat_some_old_file.yml\n"
            ),
        )
        path = "models/raw_vault/sat/sat_brand_new__src.yml"  # not on list
        findings = check_grain_excludes_metadata(
            "", path, _BAD_H10_YAML, FileStatus.NEW, repo_root=repo,
        )
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL, (
            "New H10 violation (file not on grandfather list) MUST still FAIL. "
            "If this fails, the ratchet is broken and correctness debt can be "
            "added without DataOps waiver."
        )
        assert "[GRANDFATHERED]" not in findings[0].message


# ══════════════════════════════════════════════════════════════════════════
# Grandfather downgrade — H11 (sat missing foreign_key)
# ══════════════════════════════════════════════════════════════════════════

_BAD_H11_YAML = """
version: 2
models:
  - name: sat_legacy_missing_fk__src
    columns:
      - name: SOMETHING_HK
        data_tests:
          - not_null
      - name: LOAD_DTS
"""


class TestH11GrandfatherDowngrade:
    def test_listed_file_downgrades_h11(self, tmp_path):
        repo = _make_repo(
            tmp_path,
            grandfather_text=(
                "H11 models/raw_vault/sat/sat_legacy_missing_fk__src.yml\n"
            ),
        )
        path = "models/raw_vault/sat/sat_legacy_missing_fk__src.yml"
        findings = check_sat_has_foreign_key(
            "", path, _BAD_H11_YAML, FileStatus.NEW, repo_root=repo,
        )
        assert len(findings) == 1
        assert findings[0].severity == Severity.WARN
        assert findings[0].message.startswith("[GRANDFATHERED]")

    def test_unlisted_file_still_fails_h11(self, tmp_path):
        repo = _make_repo(
            tmp_path,
            grandfather_text=(
                "H11 models/raw_vault/sat/sat_some_old_file.yml\n"
            ),
        )
        path = "models/raw_vault/sat/sat_brand_new__src.yml"
        findings = check_sat_has_foreign_key(
            "", path, _BAD_H11_YAML, FileStatus.NEW, repo_root=repo,
        )
        assert len(findings) == 1
        assert findings[0].severity == Severity.FAIL
        assert "[GRANDFATHERED]" not in findings[0].message


# ══════════════════════════════════════════════════════════════════════════
# Cross-cutting: H10 + H11 + I2 + I4 + BKCC all coexist on one list
# ══════════════════════════════════════════════════════════════════════════

def test_all_check_categories_coexist_on_grandfather_list(tmp_path):
    """The list holds entries from multiple checks. Each check looks up
    only its own (check_id, file_path) pairs — no cross-check leakage."""
    repo = _make_repo(
        tmp_path,
        grandfather_text=(
            "I2 models/int_staging_views/old_i2.sql\n"
            "I4 models/bus_vault/old_i4.sql\n"
            "H10 models/raw_vault/sat/old_h10.yml\n"
            "H11 models/raw_vault/sat/old_h11.yml\n"
        ),
    )

    # H10 on an H10-listed file → downgrade
    findings = check_grain_excludes_metadata(
        "", "models/raw_vault/sat/old_h10.yml", _BAD_H10_YAML,
        FileStatus.NEW, repo_root=repo,
    )
    assert findings and findings[0].severity == Severity.WARN

    # H11 on the H10-listed file (no H11 entry for it) → still FAIL
    findings = check_sat_has_foreign_key(
        "", "models/raw_vault/sat/old_h10.yml", _BAD_H11_YAML,
        FileStatus.NEW, repo_root=repo,
    )
    assert findings and findings[0].severity == Severity.FAIL, (
        "H10-listed file should NOT be H11-listed automatically — entries "
        "are per (check_id, file_path) pair, not per file."
    )


# ══════════════════════════════════════════════════════════════════════════
# Fail-open contract — repo_root=None must NOT load the real grandfather list
# ══════════════════════════════════════════════════════════════════════════

def test_fail_open_when_repo_root_is_none(tmp_path, monkeypatch):
    """If a check function is called with repo_root=None (common in unit
    tests that don't set up a fake repo), it MUST NOT silently load the
    real grandfather list from the test process's cwd. That would couple
    test behavior to the actual repo state and defeat test isolation.

    The contract: `load_grandfather_list(None)` returns an empty set,
    so all findings stay at their natural severity (no downgrade).

    Mutation that this test catches:
      `if repo_root is None: repo_root = '.'`  (silent cwd-fallback)
      — would make tests dependent on whatever .code_review_grandfather
      exists in cwd, which in pytest is the repo root. Tests with
      synthetic fixture paths that *coincidentally* match real grandfather
      entries would mis-downgrade.
    """
    # Run from any cwd that has a real grandfather list at the expected path.
    # If the fail-open contract is honored, the path below — which matches
    # a real production entry — should still FAIL (not WARN).
    repo_root_path = Path(__file__).resolve().parents[3]
    # Pick a path that IS on the real H11 grandfather list. Discovered via
    #     grep "^H11 " scripts/automation/.code_review_grandfather | head
    real_h11_path = "models/raw_vault/sat/_model_yml/esat_sales_agency_group__emtk_ebs.yml"
    # SENTINEL (PR #1827 review R-test-fragility): without this assertion,
    # if the entry above gets burned down off the grandfather list, the
    # test below would silently pass (the real list no longer contains the
    # path, so the mutation's effect would be identical to the fix's effect:
    # FAIL either way). Fail loudly when this happens — the test must be
    # updated to pick another listed path — rather than become a no-op.
    real_grandfather = load_grandfather_list(repo_root_path)
    assert ("H11", real_h11_path) in real_grandfather, (
        f"Test sentinel: '{real_h11_path}' is no longer on the H11 grandfather "
        f"list. The mutation guard below depends on this entry being present. "
        f"Update real_h11_path to another listed entry: "
        f"`grep '^H11 ' scripts/automation/.code_review_grandfather | head`."
    )
    monkeypatch.chdir(repo_root_path)  # cd to repo root

    findings = check_sat_has_foreign_key(
        "", real_h11_path, _BAD_H11_YAML, FileStatus.NEW, repo_root=None,
    )
    # Even though this path IS on the real grandfather list, repo_root=None
    # means we don't consult it — so the finding stays FAIL.
    assert findings, "H11 should still produce a finding"
    for f in findings:
        assert f.severity == Severity.FAIL, (
            f"With repo_root=None, no grandfather list should be consulted. "
            f"Got severity={f.severity.value}, message={f.message!r}. If this "
            f"says WARN [GRANDFATHERED], the fail-open contract is broken — "
            f"check load_grandfather_list's None handling."
        )
        assert "[GRANDFATHERED]" not in f.message
