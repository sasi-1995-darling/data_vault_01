"""
test_bk_validation.py — Tests for secondary BK expression column validation.

Validates lesson #92: --sec-bk-expr column references must resolve to actual
post-rename column names. Catches typos like COALESCE(ORD_NAME, '-1') when
the column NAME was not collision-renamed (correct: COALESCE(NAME, '-1')).
"""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from multi_table import validate_bk_references_renamed_columns


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _state_with_secondary(bk_expr, rename_map, collisions=None):
    """Build minimal state dict with secondary BK info."""
    return {
        "secondary": {
            "bk": bk_expr,
            "bk_name": "ORDER_HEADER_BK",
            "rename_map": rename_map,
            "collisions": collisions or [],
        }
    }


# ---------------------------------------------------------------------------
# Check 1: collision-renamed columns (existing behavior)
# ---------------------------------------------------------------------------

class TestCollisionRenamedColumns:
    """BK expr must use post-rename name for collision columns."""

    def test_collision_renamed_column_rejected(self):
        """COALESCE(ID, '-1') should fail when ID was renamed to ORD_ID."""
        state = _state_with_secondary(
            bk_expr="COALESCE(ID, '-1')",
            rename_map={"ID": "ORD_ID", "NAME": "NAME"},
            collisions=["ID"],
        )
        with pytest.raises(ValueError, match="renamed to 'ORD_ID'"):
            validate_bk_references_renamed_columns(state)

    def test_collision_renamed_column_accepted(self):
        """COALESCE(ORD_ID, '-1') should pass — uses renamed name."""
        state = _state_with_secondary(
            bk_expr="COALESCE(ORD_ID, '-1')",
            rename_map={"ID": "ORD_ID", "NAME": "NAME"},
            collisions=["ID"],
        )
        validate_bk_references_renamed_columns(state)  # Should not raise


# ---------------------------------------------------------------------------
# Check 2: non-existent column references (lesson #92)
# ---------------------------------------------------------------------------

class TestNonExistentColumnReferences:
    """BK expr must only reference columns that exist post-rename."""

    def test_nonexistent_column_rejected(self):
        """COALESCE(ORD_NAME, '-1') should fail — ORD_NAME doesn't exist."""
        state = _state_with_secondary(
            bk_expr="COALESCE(ORD_NAME, '-1')",
            rename_map={"ID": "ORD_ID", "NAME": "NAME"},
            collisions=["ID"],
        )
        with pytest.raises(ValueError, match="not a valid column"):
            validate_bk_references_renamed_columns(state)

    def test_nonexistent_column_suggests_match(self):
        """Error message should suggest closest column name."""
        state = _state_with_secondary(
            bk_expr="COALESCE(ORD_NAME, '-1')",
            rename_map={"ID": "ORD_ID", "NAME": "NAME"},
            collisions=["ID"],
        )
        with pytest.raises(ValueError, match="Did you mean: NAME"):
            validate_bk_references_renamed_columns(state)

    def test_valid_column_accepted(self):
        """COALESCE(NAME, '-1') should pass — NAME exists post-rename."""
        state = _state_with_secondary(
            bk_expr="COALESCE(NAME, '-1')",
            rename_map={"ID": "ORD_ID", "NAME": "NAME"},
            collisions=["ID"],
        )
        validate_bk_references_renamed_columns(state)  # Should not raise

    def test_simple_column_ref_accepted(self):
        """TO_CHAR(ORD_ID) should pass — ORD_ID is the renamed column."""
        state = _state_with_secondary(
            bk_expr="TO_CHAR(ORD_ID)",
            rename_map={"ID": "ORD_ID", "NAME": "NAME"},
            collisions=["ID"],
        )
        validate_bk_references_renamed_columns(state)  # Should not raise

    def test_completely_bogus_column_rejected(self):
        """COALESCE(FOOBAR, '-1') should fail — FOOBAR doesn't exist."""
        state = _state_with_secondary(
            bk_expr="COALESCE(FOOBAR, '-1')",
            rename_map={"ID": "ORD_ID", "NAME": "NAME"},
            collisions=["ID"],
        )
        with pytest.raises(ValueError, match="not a valid column"):
            validate_bk_references_renamed_columns(state)

    def test_sql_keywords_ignored(self):
        """SQL keywords like COALESCE, CAST, VARCHAR should not be flagged."""
        state = _state_with_secondary(
            bk_expr="CAST(NAME AS VARCHAR)",
            rename_map={"ID": "ORD_ID", "NAME": "NAME"},
            collisions=["ID"],
        )
        validate_bk_references_renamed_columns(state)  # Should not raise

    def test_no_rename_map_skips_check2(self):
        """If rename_map is empty, check 2 is skipped (no info to validate)."""
        state = _state_with_secondary(
            bk_expr="COALESCE(ANYTHING, '-1')",
            rename_map={},
            collisions=[],
        )
        validate_bk_references_renamed_columns(state)  # Should not raise

    def test_no_secondary_is_noop(self):
        """No secondary table → validation is a no-op."""
        state = {}
        validate_bk_references_renamed_columns(state)  # Should not raise
