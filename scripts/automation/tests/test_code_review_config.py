#!/usr/bin/env python3
"""
test_code_review_config.py — Tests for code_review_config.py (CD-1, CD-2, CD-3).

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_code_review_config.py -v
"""
import sys
import tempfile
from pathlib import Path

import pytest

# Path setup
SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_review_config import (
    EXCLUDED_PATHS,
    FileStatus,
    is_excluded,
    is_naming_ignored,
    load_ignore_list,
)


# ═══════════════════════════════════════════════════════════════════════════════
# CD-2: EXCLUDED_PATHS — Legacy AutomateDV models skip ALL checks
# ═══════════════════════════════════════════════════════════════════════════════

class TestExcludedPaths:
    """CD-2: Verify path-scoped exclusions for legacy AutomateDV models."""

    def test_staging_base_excluded(self):
        """models/staging/base/ files are fully excluded."""
        assert is_excluded("models/staging/base/base_supplier__winn_sap.sql")

    def test_staging_stage_excluded(self):
        """models/staging/stage/ files are fully excluded."""
        assert is_excluded("models/staging/stage/stg_supplier__winn_sap.sql")

    def test_staging_base_nested_excluded(self):
        """Nested files under excluded dirs are also excluded."""
        assert is_excluded("models/staging/base/sap/base_supplier__winn_sap.sql")

    def test_bus_vault_stg_not_excluded(self):
        """models/bus_vault/ stg_ files are NOT excluded — active PIT staging helpers."""
        assert not is_excluded("models/bus_vault/pit/pos/stg_pit_pos_amazon.sql")

    def test_bus_vault_pit_not_excluded(self):
        """Regular bus_vault models are never excluded."""
        assert not is_excluded("models/bus_vault/pit/pit_supplier.sql")

    def test_int_staging_views_not_excluded(self):
        """v_psa_stg models are never excluded."""
        assert not is_excluded("models/int_staging_views/bom/v_psa_stg_bom_header__winn_sap.sql")

    def test_raw_vault_not_excluded(self):
        """Raw vault models are never excluded."""
        assert not is_excluded("models/raw_vault/hub/hub_supplier.sql")

    def test_backslash_normalized(self):
        """Windows-style backslashes are normalized to forward slashes."""
        assert is_excluded("models\\staging\\base\\base_foo.sql")

    def test_excluded_paths_are_directories(self):
        """Verify EXCLUDED_PATHS entries end with / (directory scope, not prefix)."""
        for path in EXCLUDED_PATHS:
            assert path.endswith("/"), f"EXCLUDED_PATHS entry '{path}' must end with /"


# ═══════════════════════════════════════════════════════════════════════════════
# CD-3: .code_review_ignore — Category G naming exceptions
# ═══════════════════════════════════════════════════════════════════════════════

class TestIgnoreList:
    """CD-3: Verify .code_review_ignore loading and matching."""

    def test_load_from_real_file(self):
        """Load the actual .code_review_ignore from the repo."""
        repo_root = SCRIPT_DIR.parent.parent  # dbt-datavault root
        patterns = load_ignore_list(repo_root)
        assert len(patterns) >= 4  # At minimum: shipment, ferguson, date_spine, t_*

    def test_load_missing_file_returns_empty(self):
        """Missing .code_review_ignore returns empty list, not error."""
        with tempfile.TemporaryDirectory() as tmpdir:
            patterns = load_ignore_list(Path(tmpdir))
            assert patterns == []

    def test_load_skips_comments_and_blanks(self):
        """Comments and blank lines are filtered out."""
        with tempfile.TemporaryDirectory() as tmpdir:
            ignore_dir = Path(tmpdir) / "scripts" / "automation"
            ignore_dir.mkdir(parents=True)
            ignore_file = ignore_dir / ".code_review_ignore"
            ignore_file.write_text(
                "# This is a comment\n"
                "\n"
                "models/bus_vault/flat_logic/shipment.sql\n"
                "  # Indented comment\n"
                "models/bus_vault/dim/date_spine.sql\n"
            )
            patterns = load_ignore_list(Path(tmpdir))
            assert patterns == [
                "models/bus_vault/flat_logic/shipment.sql",
                "models/bus_vault/dim/date_spine.sql",
            ]


class TestNamingIgnored:
    """CD-3: Verify naming ignore matching logic."""

    def test_exact_path_match(self):
        """Exact path matches are ignored."""
        patterns = ["models/bus_vault/flat_logic/shipment.sql"]
        assert is_naming_ignored("models/bus_vault/flat_logic/shipment.sql", patterns)

    def test_glob_pattern_match(self):
        """Glob patterns (t_*.sql) match correctly."""
        patterns = ["models/bus_vault/flat_logic/t_*.sql"]
        assert is_naming_ignored("models/bus_vault/flat_logic/t_foo.sql", patterns)
        assert is_naming_ignored("models/bus_vault/flat_logic/t_bar.sql", patterns)

    def test_non_matching_path(self):
        """Non-matching paths are NOT ignored."""
        patterns = ["models/bus_vault/flat_logic/shipment.sql"]
        assert not is_naming_ignored("models/bus_vault/dim/dim_foo.sql", patterns)

    def test_empty_patterns_never_match(self):
        """Empty pattern list never matches."""
        assert not is_naming_ignored("models/bus_vault/flat_logic/shipment.sql", [])

    def test_bus_vault_stg_not_ignored(self):
        """bus_vault stg_ files are NOT in the ignore list."""
        patterns = [
            "models/bus_vault/flat_logic/shipment.sql",
            "models/bus_vault/flat_logic/t_*.sql",
            "models/bus_vault/dim/date_spine.sql",
        ]
        assert not is_naming_ignored(
            "models/bus_vault/pit/pos/stg_pit_pos_amazon.sql", patterns
        )

    def test_backslash_normalized(self):
        """Windows paths are normalized before matching."""
        patterns = ["models/bus_vault/flat_logic/shipment.sql"]
        assert is_naming_ignored("models\\bus_vault\\flat_logic\\shipment.sql", patterns)


# ═══════════════════════════════════════════════════════════════════════════════
# CD-1: FileStatus enum
# ═══════════════════════════════════════════════════════════════════════════════

class TestFileStatus:
    """CD-1: Verify FileStatus enum values."""

    def test_new_status(self):
        assert FileStatus.NEW.value == "new"

    def test_modified_status(self):
        assert FileStatus.MODIFIED.value == "modified"
