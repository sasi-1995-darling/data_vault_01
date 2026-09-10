#!/usr/bin/env python3
"""
code_reviewer.py — Deterministic pre-PR code review for dbt-datavault.

Runs deterministic checks against SQL, YAML, and triage Python files in a PR.
Each check is a pure function: (file_content, file_path) → list[Finding].
No database calls, no LLM calls, no network I/O.

Usage:
    # Review all changed files in current PR
    .venv/bin/python3 scripts/automation/src/code_reviewer.py

    # Review specific files
    .venv/bin/python3 scripts/automation/src/code_reviewer.py \\
        --files models/int_staging_views/foo/v_psa_stg_bar.sql

    # Review one category or check
    .venv/bin/python3 scripts/automation/src/code_reviewer.py --category G
    .venv/bin/python3 scripts/automation/src/code_reviewer.py --check G4

Exit codes:
    0 = no FAILs (WARNs are OK)
    1 = one or more FAILs found
    2 = configuration error

Source of truth: scripts/automation/src/CODE_REVIEW_CHECKS.md
"""
import argparse
import inspect
import json
import logging
import os
import re
import sys
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Callable, NamedTuple, Optional

# ---------------------------------------------------------------------------
# Path setup — allow running from repo root or scripts/automation/
# ---------------------------------------------------------------------------
_THIS_DIR = Path(__file__).resolve().parent
_AUTOMATION_DIR = _THIS_DIR.parent
_PROJECT_ROOT = _AUTOMATION_DIR.parent.parent

if str(_THIS_DIR) not in sys.path:
    sys.path.insert(0, str(_THIS_DIR))

from code_review_config import (
    FileStatus,
    get_file_statuses,
    is_database_allowed,
    is_excluded,
    is_grandfathered,
    is_naming_ignored,
    load_governance_allowlist,
    load_grandfather_list,
    load_ignore_list,
    load_source_resolver,
    load_staging_discipline_config,
    normalize_database,
)

logger = logging.getLogger(__name__)

# ═══════════════════════════════════════════════════════════════════════════════
# 1. CORE DATA STRUCTURES
# ═══════════════════════════════════════════════════════════════════════════════


class Severity(Enum):
    """Check severity. FAIL blocks merge; WARN is advisory."""
    FAIL = "FAIL"
    WARN = "WARN"


@dataclass
class Finding:
    """A single check finding against a file."""
    check_id: str
    check_name: str
    severity: Severity
    file_path: str
    message: str
    line_number: Optional[int] = None
    suggestion: str = ""


@dataclass
class ReviewResult:
    """Aggregated results from running all checks on all files."""
    findings: list[Finding] = field(default_factory=list)
    files_checked: int = 0
    files_skipped: int = 0
    checks_run: int = 0

    @property
    def has_failures(self) -> bool:
        return any(f.severity == Severity.FAIL for f in self.findings)

    @property
    def fail_count(self) -> int:
        return sum(1 for f in self.findings if f.severity == Severity.FAIL)

    @property
    def warn_count(self) -> int:
        return sum(1 for f in self.findings if f.severity == Severity.WARN)


# Type alias for check functions
CheckFn = Callable[..., list[Finding]]


class CheckEntry(NamedTuple):
    """Registry entry for a single check."""
    fn: CheckFn
    file_patterns: list[str]  # e.g. ["*.sql"], ["*.yml"], ["*.sql", "*.yml"]
    category: str             # e.g. "G"


# ═══════════════════════════════════════════════════════════════════════════════
# 2. CATEGORY G — NAMING CONVENTIONS
# ═══════════════════════════════════════════════════════════════════════════════

def check_vpsa_stg_prefix(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """G1: All SQL files in int_staging_views/ must start with v_psa_stg_.

    Enforces: FBIN naming standard (copilot-instructions.md)
    Triggers on: models/int_staging_views/pos/v_psa_pos_sellthrough_stages__win.sql
    Correct pattern: v_psa_stg_<entity>__<source>.sql
    """
    if "int_staging_views/" not in file_path:
        return []
    filename = Path(file_path).stem
    if filename.startswith("_"):
        return []  # YAML schema files like _v_psa_stg_foo.yml — not SQL models
    if filename.startswith("v_psa_stg_"):
        return []
    return [Finding(
        check_id="G1",
        check_name="vpsa_stg_prefix",
        severity=Severity.FAIL,
        file_path=file_path,
        message=f"File '{filename}.sql' in int_staging_views/ must start with 'v_psa_stg_'",
        suggestion="Rename to v_psa_stg_<entity>__<source>.sql",
    )]


def check_hub_prefix(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """G2: All SQL files in raw_vault/hub/ must start with hub_.

    Enforces: FBIN naming standard (copilot-instructions.md)
    Triggers on: models/raw_vault/hub/dim_hub_customer.sql
    Correct pattern: hub_<entity>.sql
    """
    if "raw_vault/hub/" not in file_path:
        return []
    filename = Path(file_path).stem
    if filename.startswith("_"):
        return []
    if filename.startswith("hub_"):
        return []
    return [Finding(
        check_id="G2",
        check_name="hub_prefix",
        severity=Severity.FAIL,
        file_path=file_path,
        message=f"File '{filename}.sql' in raw_vault/hub/ must start with 'hub_'",
        suggestion="Rename to hub_<entity>.sql",
    )]


def check_sat_prefix(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """G3: All SQL files in raw_vault/sat/ must use an accepted sat prefix.

    Enforces: FBIN naming standard + DV 2.1 satellite variants
    Accepted: sat_, lsat_, msat_, esat_, lmsat_, rsat_
    Triggers on: models/raw_vault/sat/data_satellite_customer.sql
    Correct pattern: sat_<entity>__<source>.sql, lmsat_<entity>__<source>.sql
    """
    if "raw_vault/sat/" not in file_path:
        return []
    filename = Path(file_path).stem
    if filename.startswith("_"):
        return []
    accepted = ("sat_", "lsat_", "msat_", "esat_", "lmsat_", "rsat_")
    if filename.startswith(accepted):
        return []
    return [Finding(
        check_id="G3",
        check_name="sat_prefix",
        severity=Severity.FAIL,
        file_path=file_path,
        message=(
            f"File '{filename}.sql' in raw_vault/sat/ must start with one of: "
            f"sat_, lsat_, msat_, esat_, lmsat_, rsat_"
        ),
        suggestion="Rename to <prefix>_<entity>__<source>.sql",
    )]


def check_link_prefix(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """G4: All SQL files in raw_vault/link/ must use lnk_ or tlink_ prefix.

    Enforces: CD-1 graduated enforcement (CODE_REVIEW_CHECKS.md)
    - New link_ files → FAIL (standard going forward is lnk_ only)
    - Modified link_ files → WARN (grandfathered, consider renaming)
    - lnk_ and tlink_ → always pass
    - Any other prefix → FAIL regardless of file status
    Triggers on: models/raw_vault/link/link_new_thing.sql (new file → FAIL)
    """
    if "raw_vault/link/" not in file_path:
        return []
    filename = Path(file_path).stem
    if filename.startswith("_"):
        return []
    if filename.startswith(("lnk_", "tlink_")):
        return []
    if filename.startswith("link_"):
        # CD-1: graduated enforcement based on new vs modified
        if file_status == FileStatus.MODIFIED:
            return [Finding(
                check_id="G4",
                check_name="link_prefix",
                severity=Severity.WARN,
                file_path=file_path,
                message=(
                    f"Legacy 'link_' prefix on '{filename}.sql'. "
                    f"Standard is 'lnk_'. Consider renaming."
                ),
                suggestion="Rename to lnk_<entity>.sql",
            )]
        else:
            return [Finding(
                check_id="G4",
                check_name="link_prefix",
                severity=Severity.FAIL,
                file_path=file_path,
                message=(
                    f"New models must use 'lnk_' prefix, not 'link_'. "
                    f"File: '{filename}.sql'"
                ),
                suggestion="Rename to lnk_<entity>.sql",
            )]
    # Any other prefix (e.g. rel_, association_)
    return [Finding(
        check_id="G4",
        check_name="link_prefix",
        severity=Severity.FAIL,
        file_path=file_path,
        message=(
            f"File '{filename}.sql' in raw_vault/link/ must start with "
            f"'lnk_' or 'tlink_'"
        ),
        suggestion="Rename to lnk_<entity>.sql or tlink_<entity>.sql",
    )]


def check_double_underscore_separator(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """G5: v_psa_stg model names should use entity__source (double underscore).

    Enforces: FBIN naming convention for source traceability
    Triggers on: models/int_staging_views/foo/v_psa_stg_supplier_mdm.sql
    Correct pattern: v_psa_stg_supplier__winn_sap.sql (double underscore separates entity from source)
    """
    if "int_staging_views/" not in file_path:
        return []
    filename = Path(file_path).stem
    if not filename.startswith("v_psa_stg_"):
        return []  # G1 will catch non-v_psa_stg files
    # Strip the v_psa_stg_ prefix and check for double underscore
    remainder = filename[len("v_psa_stg_"):]
    if "__" in remainder:
        return []
    return [Finding(
        check_id="G5",
        check_name="double_underscore_separator",
        severity=Severity.WARN,
        file_path=file_path,
        message=(
            f"Model '{filename}' is missing double-underscore separator. "
            f"Expected pattern: v_psa_stg_<entity>__<source>"
        ),
        suggestion="Rename to v_psa_stg_<entity>__<source_system>.sql",
    )]


def check_column_names_uppercase(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """G6: Column aliases in final SELECT should be UPPERCASE.

    Enforces: FBIN SQL standard — all column names UPPERCASE in queries
    Triggers on: 'supplier_name AS supplier_name' (lowercase alias)
    Correct pattern: 'SUPPLIER_NAME AS SUPPLIER_NAME' or 'col AS SUPPLIER_NAME'

    Scoped to the FINAL CTE's SELECT only to avoid false positives on
    intermediate CTEs where lowercase is acceptable.
    """
    # Only check SQL files in model directories
    if not file_path.endswith(".sql"):
        return []
    if not any(d in file_path for d in (
        "int_staging_views/", "raw_vault/", "bus_vault/", "info_mart/"
    )):
        return []

    # Find the FINAL CTE or the last SELECT block
    # Look for lines with " AS <alias>" pattern in the last SELECT
    findings = []

    # Extract the FINAL CTE content (everything after "FINAL AS (" or last SELECT)
    final_match = re.search(
        r'(?:FINAL\s+AS\s*\(|--+\s*FINAL\s+LAYER\s*--+)(.*)',
        sql_content,
        re.DOTALL | re.IGNORECASE,
    )
    if not final_match:
        # No FINAL CTE found — check the last SELECT statement
        # This handles models without CTE structure
        return []

    final_block = final_match.group(1)

    # Find "AS <alias>" patterns where alias is not all-uppercase
    # Matches: "AS some_name" but not "AS SOME_NAME" or "AS 'literal'"
    alias_pattern = re.compile(
        r'\bAS\s+([a-z][a-z0-9_]*)\s*(?:,|\n|\))',
        re.IGNORECASE,
    )
    for match in alias_pattern.finditer(final_block):
        alias = match.group(1)
        if alias != alias.upper() and not alias.startswith("'"):
            # Find approximate line number
            pre_content = sql_content[:sql_content.find(match.group(0))]
            line_num = pre_content.count("\n") + 1 if pre_content else None
            findings.append(Finding(
                check_id="G6",
                check_name="column_names_uppercase",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=line_num,
                message=f"Column alias '{alias}' should be UPPERCASE: '{alias.upper()}'",
                suggestion=f"Change to: AS {alias.upper()}",
            ))
            # Cap at 5 findings per file to avoid noise
            if len(findings) >= 5:
                break

    return findings


# ═══════════════════════════════════════════════════════════════════════════════
# 3. CATEGORY A — HASH KEY (HK) FORMULA
# ═══════════════════════════════════════════════════════════════════════════════

# Regex to extract the full HK block: from MD5_BINARY(...) through AS <name>_HK
_HK_BLOCK_RE = re.compile(
    r'(MD5_BINARY\s*\(.*?\)\s*\)\s*\))\s+[Aa][Ss]\s+(\w+_HK)\b',
    re.DOTALL | re.IGNORECASE,
)

# Regex to find CONCAT_WS inside an HK block
_HK_CONCAT_WS_RE = re.compile(r'CONCAT_WS\s*\(', re.IGNORECASE)

# Regex to find UPPER wrapper
_HK_UPPER_RE = re.compile(r'MD5_BINARY\s*\(\s*UPPER\s*\(', re.IGNORECASE)

# Regex for individual HK components: COALESCE(NULLIF(TRIM(CAST(col AS VARCHAR)), ''), '<sentinel>')
# Matches ALL THREE FBIN null-fallback sentinels — '^^' (in-hash empty/null),
# '-1' (required-BK null), '-2' (optional-BK null). Matching only '^^' silently
# dropped '-1'/'-2' components, collapsing HKs to [BKCC] → Q1 false negatives and
# A3/A4 blind spots on sentinel models ('-1'/'-2' are the standard null-BK sentinels).
_HK_COMPONENT_RE = re.compile(
    r"COALESCE\s*\(\s*NULLIF\s*\(\s*TRIM\s*\(\s*CAST\s*\(\s*(\w+)\s+[Aa][Ss]\s+VARCHAR\s*\)\s*\)\s*,\s*''\s*\)\s*,\s*'(?:\^\^|-1|-2)'\s*\)",
    re.IGNORECASE,
)

# Regex for simplified/wrong HK components missing NULLIF
_HK_COALESCE_NO_NULLIF_RE = re.compile(
    r"COALESCE\s*\(\s*TRIM\s*\(",
    re.IGNORECASE,
)


def _extract_hk_blocks(sql_content: str) -> list[tuple[str, str, int]]:
    """Extract all HK formula blocks from SQL content.

    Returns list of (hk_formula_text, hk_column_name, line_number).
    """
    results = []
    for m in _HK_BLOCK_RE.finditer(sql_content):
        block = m.group(1)
        hk_name = m.group(2)
        line_num = sql_content[:m.start()].count("\n") + 1
        results.append((block, hk_name, line_num))
    return results


def check_hk_uses_concat_ws(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """A1: HK formula must use CONCAT_WS('||', ...) — not plain CONCAT or ||.

    Enforces: Lesson #1, #16
    Triggers on: MD5_BINARY(CONCAT('||', col1, col2)) AS SUPPLIER_HK
    Correct pattern: MD5_BINARY(UPPER(CONCAT_WS('||', ...))) AS SUPPLIER_HK
    """
    if not file_path.endswith(".sql"):
        return []
    if not any(d in file_path for d in ("int_staging_views/",)):
        return []  # HK formulas only live in v_psa_stg models

    findings = []
    for block, hk_name, line_num in _extract_hk_blocks(sql_content):
        if not _HK_CONCAT_WS_RE.search(block):
            findings.append(Finding(
                check_id="A1",
                check_name="hk_uses_concat_ws",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message=f"HK '{hk_name}' must use CONCAT_WS('||', ...), not plain CONCAT",
                suggestion="Use: MD5_BINARY(UPPER(CONCAT_WS('||', COALESCE(NULLIF(TRIM(CAST(col AS VARCHAR)), ''), '^^'), ...)))",
            ))
    return findings


def check_hk_coalesce_nullif_trim(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """A2: Each HK component must use COALESCE(NULLIF(TRIM(CAST(col AS VARCHAR)), ''), '^^').

    Enforces: Lesson #1
    Triggers on: COALESCE(TRIM(col), '^^') — missing NULLIF (empty strings pass through)
    Correct pattern: COALESCE(NULLIF(TRIM(CAST(LIFNR AS VARCHAR)), ''), '^^')
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    findings = []
    for block, hk_name, line_num in _extract_hk_blocks(sql_content):
        # Check for the wrong pattern: COALESCE(TRIM(...) without NULLIF
        if _HK_COALESCE_NO_NULLIF_RE.search(block) and not re.search(
            r'COALESCE\s*\(\s*NULLIF', block, re.IGNORECASE
        ):
            findings.append(Finding(
                check_id="A2",
                check_name="hk_coalesce_nullif_trim",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message=(
                    f"HK '{hk_name}' components must use "
                    f"COALESCE(NULLIF(TRIM(CAST(col AS VARCHAR)), ''), '^^') "
                    f"— missing NULLIF wrapper"
                ),
                suggestion="Wrap TRIM in NULLIF: COALESCE(NULLIF(TRIM(CAST(col AS VARCHAR)), ''), '^^')",
            ))
    return findings


def check_hk_uses_raw_column_names(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """A3: HK components must reference raw source column names, NOT BK aliases.

    Enforces: Lesson #1, #89
    Triggers on: CAST(SUPPLIER_BK AS VARCHAR) inside HK — uses the alias
    Correct pattern: CAST(LIFNR AS VARCHAR) or CAST(VENDOR_ID AS VARCHAR) — uses raw column

    Exception (Lesson #89): Derived BKs from complex expressions (CONCAT, IFF, etc.)
    use the BK alias because there is no single raw column to reference.
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # Find which column names are aliased as _BK in the LOGIC layer
    # Pattern: <raw_col> as <NAME>_BK or <expression> as <NAME>_BK
    bk_alias_re = re.compile(
        r'(\w+)(?:::TEXT)?'               # raw column name (captured)
        r'\s+[Aa][Ss]\s+'                  # AS keyword
        r'(\w+_BK)\b',                     # BK alias (captured)
        re.IGNORECASE,
    )
    # Find simple BK aliases (single column cast, not complex expressions)
    simple_bk_aliases = set()
    for m in bk_alias_re.finditer(sql_content):
        raw_col = m.group(1).upper()
        bk_alias = m.group(2).upper()
        # Only flag simple aliases (not CONCAT/IFF derived BKs — lesson #89)
        context_start = max(0, m.start() - 80)
        context = sql_content[context_start:m.start()].upper()
        if "CONCAT" not in context and "IFF" not in context and "CASE" not in context:
            simple_bk_aliases.add(bk_alias)

    if not simple_bk_aliases:
        return []

    findings = []
    for block, hk_name, line_num in _extract_hk_blocks(sql_content):
        # Extract column names used in CAST(...AS VARCHAR) within the HK block
        for component in _HK_COMPONENT_RE.finditer(block):
            col_name = component.group(1).upper()
            if col_name in simple_bk_aliases:
                findings.append(Finding(
                    check_id="A3",
                    check_name="hk_uses_raw_column_names",
                    severity=Severity.FAIL,
                    file_path=file_path,
                    line_number=line_num,
                    message=(
                        f"HK '{hk_name}' uses BK alias '{col_name}' — "
                        f"should reference the raw source column name instead"
                    ),
                    suggestion=(
                        "Use the raw source column (e.g., LIFNR, VENDOR_ID) "
                        "not the BK alias (e.g., SUPPLIER_BK)"
                    ),
                ))
    return findings


def check_hk_bkcc_last_component(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """A4: BKCC must be the last argument in every HK CONCAT_WS.

    Enforces: Lesson #12
    Triggers on: CONCAT_WS('||', COALESCE(...BKCC...), COALESCE(...LIFNR...))
    Correct pattern: CONCAT_WS('||', COALESCE(...LIFNR...), COALESCE(...BKCC...))
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    findings = []
    for block, hk_name, line_num in _extract_hk_blocks(sql_content):
        if not _HK_CONCAT_WS_RE.search(block):
            continue  # A1 handles non-CONCAT_WS

        # Find all COALESCE(...CAST(col...)...) components in order
        components = [m.group(1).upper() for m in _HK_COMPONENT_RE.finditer(block)]
        if not components:
            continue

        # Check BKCC is last
        bkcc_positions = [i for i, c in enumerate(components) if c == "BKCC"]
        if bkcc_positions and bkcc_positions[0] != len(components) - 1:
            findings.append(Finding(
                check_id="A4",
                check_name="hk_bkcc_last_component",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message=(
                    f"HK '{hk_name}': BKCC must be the last component in CONCAT_WS, "
                    f"but found at position {bkcc_positions[0] + 1} of {len(components)}"
                ),
                suggestion="Move BKCC COALESCE to the end of the CONCAT_WS argument list",
            ))
    return findings


def check_hk_has_upper_wrapper(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """A5: HK formula must be wrapped in UPPER(...).

    Enforces: FBIN hash key standard
    Triggers on: MD5_BINARY(CONCAT_WS('||', ...)) — missing UPPER
    Correct pattern: MD5_BINARY(UPPER(CONCAT_WS('||', ...)))
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    findings = []
    for block, hk_name, line_num in _extract_hk_blocks(sql_content):
        if not _HK_UPPER_RE.search(block):
            findings.append(Finding(
                check_id="A5",
                check_name="hk_has_upper_wrapper",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message=f"HK '{hk_name}' must wrap formula in UPPER(): MD5_BINARY(UPPER(...))",
                suggestion="Add UPPER wrapper: MD5_BINARY(UPPER(CONCAT_WS(...)))",
            ))
    return findings


# ═══════════════════════════════════════════════════════════════════════════════
# 4. CATEGORY B — HASHDIFF FORMULA
# ═══════════════════════════════════════════════════════════════════════════════

# Columns that must NEVER appear in HASHDIFF
_HASHDIFF_EXCLUDED_METADATA = {
    "LOAD_DTS", "REC_SRC", "BKCC",
    "_FIVETRAN_SYNCED", "_FIVETRAN_ID",
    "PSA_LOAD_DTS", "PSA_RECORD_SOURCE",
}

# Delete-flag columns that are frequently BOOLEAN-typed and therefore REQUIRE an
# explicit text cast inside HASHDIFF so distinct states (TRUE/FALSE/NULL) tokenize
# to distinct strings. Runtime counterpart:
# tests/_vault_integrity/i_hashdiff_delete_flag_value_collapse.sql
_HASHDIFF_DELETE_FLAG_COLUMNS = ("_FIVETRAN_DELETED", "PSA_DELETE_IND", "GLDELFLAG")

# Text-like cast target types B8 accepts as a valid BOOLEAN->TEXT coercion.
# A non-text cast (e.g. ::int) does NOT satisfy B8. CHARACTER precedes CHAR so the
# alternation does not short-match "CHAR" inside "CHARACTER".
_TEXT_CAST_TYPE_RE = r"(?:VARCHAR|NVARCHAR|CHARACTER|NCHAR|CHAR|STRING|TEXT)"

# Regex for HASHDIFF components: IFNULL(TRIM(col::text), '^^')
_HASHDIFF_COMPONENT_RE = re.compile(
    r"IFNULL\s*\(\s*TRIM\s*\(\s*(\w+)::text\s*\)\s*,\s*'\^\^'\s*\)",
    re.IGNORECASE,
)


def _extract_hashdiff_block(sql_content: str) -> tuple[str, int] | None:
    """Extract the HASHDIFF formula block from SQL content.

    Finds 'AS HASHDIFF', then locates the nearest preceding MD5_BINARY
    to extract the full formula block.  This avoids brittle paren-counting
    regexes that break on the '^^||^^' sentinel between closing parens.

    Returns (hashdiff_formula_text, line_number) or None.
    """
    hashdiff_match = re.search(r'[Aa][Ss]\s+HASHDIFF\b', sql_content)
    if not hashdiff_match:
        return None

    # Find the last MD5_BINARY before AS HASHDIFF (skip the HK's MD5_BINARY)
    prefix = sql_content[:hashdiff_match.start()]
    md5_positions = [m.start() for m in re.finditer(r'MD5_BINARY\b', prefix, re.IGNORECASE)]
    if not md5_positions:
        return None

    start = md5_positions[-1]
    block = sql_content[start:hashdiff_match.start()].rstrip()
    line_num = sql_content[:start].count("\n") + 1
    return block, line_num


def _get_model_bk_columns(sql_content: str) -> set[str]:
    """Find the model's own BK column names (the aliased BK, not data columns).

    Returns set of uppercase BK alias names defined in LOGIC layer via
    '<expr> AS <NAME>_BK' pattern.
    """
    # Match: <expression> AS <NAME>_BK at the end of a line/comma
    bk_def_re = re.compile(
        r'\bAS\s+(\w+_BK)\s*$',
        re.MULTILINE | re.IGNORECASE,
    )
    return {m.group(1).upper() for m in bk_def_re.finditer(sql_content)}


def _get_model_hk_columns(sql_content: str) -> set[str]:
    """Find the model's own HK column names.

    Returns set of uppercase HK alias names from 'AS <NAME>_HK' in the FINAL layer.
    """
    hk_def_re = re.compile(
        r'\bAS\s+(\w+_HK)\s*$',
        re.MULTILINE | re.IGNORECASE,
    )
    return {m.group(1).upper() for m in hk_def_re.finditer(sql_content)}


def check_hashdiff_uses_nullif_concat(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """B1: HASHDIFF must use MD5_BINARY(UPPER(NULLIF(CONCAT(...), '^^||^^'))).

    Enforces: FBIN HASHDIFF standard
    Triggers on: MD5_BINARY(CONCAT(...)) AS HASHDIFF — missing NULLIF+UPPER
    Correct: MD5_BINARY(UPPER(NULLIF(CONCAT(...), '^^||^^'))) AS HASHDIFF
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # Check if file has a HASHDIFF at all
    if not re.search(r'\bAS\s+HASHDIFF\b', sql_content, re.IGNORECASE):
        return []

    result = _extract_hashdiff_block(sql_content)
    if result is None:
        # Has HASHDIFF alias but no matching MD5_BINARY block — likely passthrough
        return []

    block, line_num = result
    findings = []

    # Check for UPPER wrapper
    if not re.search(r'MD5_BINARY\s*\(\s*UPPER\s*\(', block, re.IGNORECASE):
        findings.append(Finding(
            check_id="B1",
            check_name="hashdiff_uses_nullif_concat",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message="HASHDIFF must include UPPER wrapper: MD5_BINARY(UPPER(NULLIF(CONCAT(...))))",
            suggestion="Add UPPER: MD5_BINARY(UPPER(NULLIF(CONCAT(...), '^^||^^')))",
        ))

    # Check for NULLIF wrapper
    if not re.search(r'NULLIF\s*\(\s*CONCAT\s*\(', block, re.IGNORECASE):
        findings.append(Finding(
            check_id="B1",
            check_name="hashdiff_uses_nullif_concat",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message="HASHDIFF must include NULLIF wrapper: NULLIF(CONCAT(...), '^^||^^')",
            suggestion="Wrap CONCAT in NULLIF: MD5_BINARY(UPPER(NULLIF(CONCAT(...), '^^||^^')))",
        ))

    return findings


def check_hashdiff_ifnull_trim_pattern(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """B2: Each HASHDIFF component must use IFNULL(TRIM(col::text), '^^').

    Enforces: FBIN HASHDIFF standard (IFNULL, not COALESCE; ::text cast, not CAST)
    Triggers on: COALESCE(col, '^^') or IFNULL(col::text, '^^') — missing TRIM
    Correct: IFNULL(TRIM(LAND1::text), '^^')
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    result = _extract_hashdiff_block(sql_content)
    if result is None:
        return []

    block, line_num = result

    # Check for wrong pattern: COALESCE inside HASHDIFF block
    if re.search(r'COALESCE\s*\(', block, re.IGNORECASE):
        return [Finding(
            check_id="B2",
            check_name="hashdiff_ifnull_trim_pattern",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message="HASHDIFF components must use IFNULL(TRIM(col::text), '^^'), not COALESCE",
            suggestion="Replace COALESCE with IFNULL and add ::text cast",
        )]

    # Check for IFNULL without TRIM
    if re.search(r'IFNULL\s*\(\s*\w+::', block, re.IGNORECASE) and not re.search(
        r'IFNULL\s*\(\s*TRIM\s*\(', block, re.IGNORECASE
    ):
        return [Finding(
            check_id="B2",
            check_name="hashdiff_ifnull_trim_pattern",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message="HASHDIFF components must use IFNULL(TRIM(col::text), '^^') — missing TRIM",
            suggestion="Add TRIM: IFNULL(TRIM(col::text), '^^')",
        )]

    return []


def check_hashdiff_separator_pattern(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """B3: HASHDIFF components separated by ', '||', ' between each IFNULL.

    Enforces: FBIN HASHDIFF standard — separators as CONCAT arguments
    Triggers on: leading '||' before IFNULL with no preceding comma (string concat, not arg)
    Correct: , '||', IFNULL(TRIM(col::text), '^^')

    Note: The first IFNULL in the CONCAT has no leading separator — only
    subsequent components get ', '||', ' prefixed.
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    result = _extract_hashdiff_block(sql_content)
    if result is None:
        return []

    block, line_num = result

    # Look for the wrong pattern: '||' directly concatenated (string operator)
    # instead of being a CONCAT argument with commas
    # Wrong: IFNULL(TRIM(col1::text), '^^') || '||' || IFNULL(...)
    # Right: IFNULL(TRIM(col1::text), '^^'), '||', IFNULL(...)
    if re.search(r"\|\|\s*'\|\|'\s*\|\|", block):
        return [Finding(
            check_id="B3",
            check_name="hashdiff_separator_pattern",
            severity=Severity.WARN,
            file_path=file_path,
            line_number=line_num,
            message=(
                "HASHDIFF uses string concatenation (|| '||' ||) instead of "
                "CONCAT arguments (, '||', ) for separators"
            ),
            suggestion="Use CONCAT arguments: , '||', IFNULL(TRIM(col::text), '^^')",
        )]

    return []


def check_hashdiff_excludes_metadata(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """B4: HASHDIFF must NOT include metadata columns or the model's own HK/BK.

    Enforces: Lesson #4
    Excludes: LOAD_DTS, REC_SRC, BKCC, _FIVETRAN_SYNCED, _FIVETRAN_ID,
              PSA_LOAD_DTS, PSA_RECORD_SOURCE, and the model's own _HK/_BK aliases.

    IMPORTANT edge case: Columns like LEDGER_BK, OBJECT_NUMBER_BK, OBJNR_HK,
    SAME_AS_SUPPLIER_HK are DATA columns that happen to end with _BK/_HK.
    Only the model's OWN BK/HK (defined via 'AS <NAME>_BK/HK' in the model)
    are excluded — not arbitrary columns containing those substrings.

    Triggers on: IFNULL(TRIM(SUPPLIER_HK::text), '^^') inside HASHDIFF
    Correct: SUPPLIER_HK not present in HASHDIFF block
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    result = _extract_hashdiff_block(sql_content)
    if result is None:
        return []

    block, line_num = result

    # Get the model's own BK and HK column names
    model_bks = _get_model_bk_columns(sql_content)
    model_hks = _get_model_hk_columns(sql_content)

    # Build full exclusion set: static metadata + model-specific HK/BK
    excluded = _HASHDIFF_EXCLUDED_METADATA | model_bks | model_hks

    findings = []
    for component in _HASHDIFF_COMPONENT_RE.finditer(block):
        col_name = component.group(1).upper()
        if col_name in excluded:
            findings.append(Finding(
                check_id="B4",
                check_name="hashdiff_excludes_metadata",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message=(
                    f"HASHDIFF must not include metadata/key column '{col_name}'. "
                    f"Excluded columns: HK, BK, LOAD_DTS, REC_SRC, BKCC, "
                    f"_FIVETRAN_SYNCED, _FIVETRAN_ID, PSA_LOAD_DTS, PSA_RECORD_SOURCE"
                ),
                suggestion=f"Remove '{col_name}' from the HASHDIFF CONCAT block",
            ))
    return findings


def check_hashdiff_includes_psa_delete_ind(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """B5: PSA_DELETE_IND is DATA — must be in HASHDIFF when column exists in source.

    Enforces: Lesson #4
    Triggers on: HASHDIFF block present, PSA_DELETE_IND appears elsewhere in SQL
                 (e.g., SELECT list) but is missing from the HASHDIFF block
    Correct: IFNULL(TRIM(PSA_DELETE_IND::text), '^^') as component in HASHDIFF
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # Check if PSA_DELETE_IND exists in the model at all
    if not re.search(r'\bPSA_DELETE_IND\b', sql_content, re.IGNORECASE):
        return []

    result = _extract_hashdiff_block(sql_content)
    if result is None:
        return []

    block, line_num = result

    # Check if PSA_DELETE_IND is in the HASHDIFF block
    if re.search(r'PSA_DELETE_IND', block, re.IGNORECASE):
        return []

    return [Finding(
        check_id="B5",
        check_name="hashdiff_includes_psa_delete_ind",
        severity=Severity.FAIL,
        file_path=file_path,
        line_number=line_num,
        message=(
            "PSA_DELETE_IND is DATA (not metadata) — it must be included "
            "in HASHDIFF when the column exists in the source table"
        ),
        suggestion="Add: , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') to the HASHDIFF block",
    )]


def check_hashdiff_includes_fivetran_deleted(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """B6: _FIVETRAN_DELETED is DATA — must be in HASHDIFF when column exists in source.

    Enforces: Lesson #5
    Triggers on: HASHDIFF block present, _FIVETRAN_DELETED appears elsewhere in SQL
                 (e.g., in SELECT list) but missing from HASHDIFF
    Correct: IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') as component in HASHDIFF

    Note: Only fires for Fivetran sources. Non-Fivetran models won't have
    _FIVETRAN_DELETED in the SQL at all, so this check is inherently scoped.
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # Check if _FIVETRAN_DELETED exists in the model at all
    if not re.search(r'\b_FIVETRAN_DELETED\b', sql_content, re.IGNORECASE):
        return []

    result = _extract_hashdiff_block(sql_content)
    if result is None:
        return []

    block, line_num = result

    # Check if _FIVETRAN_DELETED is in the HASHDIFF block
    if re.search(r'_FIVETRAN_DELETED', block, re.IGNORECASE):
        return []

    return [Finding(
        check_id="B6",
        check_name="hashdiff_includes_fivetran_deleted",
        severity=Severity.FAIL,
        file_path=file_path,
        line_number=line_num,
        message=(
            "_FIVETRAN_DELETED is DATA (not metadata) — it must be included "
            "in HASHDIFF for Fivetran sources"
        ),
        suggestion="Add: , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') to HASHDIFF",
    )]


def check_hashdiff_ends_with_sentinel(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """B7: HASHDIFF NULLIF must close with '^^||^^' sentinel for all-null rows.

    Enforces: FBIN HASHDIFF standard
    Triggers on: MD5_BINARY(UPPER(CONCAT(...))) AS HASHDIFF — missing '^^||^^' sentinel
    Correct: MD5_BINARY(UPPER(NULLIF(CONCAT(...), '^^||^^'))) AS HASHDIFF
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    result = _extract_hashdiff_block(sql_content)
    if result is None:
        return []

    block, line_num = result

    if "'^^||^^'" not in block:
        return [Finding(
            check_id="B7",
            check_name="hashdiff_ends_with_sentinel",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message="HASHDIFF must include '^^||^^' sentinel in NULLIF to handle all-null rows",
            suggestion="Use: NULLIF(CONCAT(...), '^^||^^') to close the HASHDIFF formula",
        )]

    return []


def check_hashdiff_delete_flag_explicit_cast(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """B8: Delete-flag columns in HASHDIFF must carry an explicit text cast.

    Enforces: BOOLEAN delete flags (_FIVETRAN_DELETED, PSA_DELETE_IND, GLDELFLAG)
    must be cast to text inside HASHDIFF so distinct states (TRUE/FALSE/NULL)
    tokenize to distinct strings. Without a cast a logically-deleted row could
    share a HASHDIFF with a live row (silent missed delete).

    B5/B6 prove the flag is PRESENT in the block (structural). B8 proves it is
    present WITH a cast (value integrity). Closes the gap where
    IFNULL(TRIM(_FIVETRAN_DELETED), '^^') -- no ::text -- passes B2/B5/B6.

    Triggers on: delete-flag column in HASHDIFF block without a text-like cast
    (::text / CAST(... AS VARCHAR)); a non-text cast such as ::int does NOT count.
    Correct: IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^')
    Runtime counterpart: tests/_vault_integrity/i_hashdiff_delete_flag_value_collapse.sql
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    result = _extract_hashdiff_block(sql_content)
    if result is None:
        return []

    block, line_num = result

    findings: list[Finding] = []
    for col in _HASHDIFF_DELETE_FLAG_COLUMNS:
        # Only evaluate columns actually present in the HASHDIFF block.
        if not re.search(rf'\b{col}\b', block, re.IGNORECASE):
            continue
        # Accept ONLY a text-like cast: `col::<text-type>` shorthand or
        # `CAST([qualifier.]col AS <text-type>)`. A non-text cast (e.g. ::int) or
        # a missing cast leaves BOOLEAN->TEXT coercion implicit, which B8 forbids.
        # The CAST form allows an optional `qualifier.` so CAST(LOGIC_S.col AS ...)
        # is not misread as a missing cast.
        has_shorthand_cast = re.search(
            rf'\b{col}\s*::\s*{_TEXT_CAST_TYPE_RE}\b', block, re.IGNORECASE
        )
        has_cast_fn = re.search(
            rf'\bCAST\s*\(\s*(?:\w+\.)?{col}\s+AS\s+{_TEXT_CAST_TYPE_RE}\b',
            block, re.IGNORECASE,
        )
        if has_shorthand_cast or has_cast_fn:
            continue
        findings.append(Finding(
            check_id="B8",
            check_name="hashdiff_delete_flag_explicit_cast",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message=(
                f"Delete-flag '{col}' is in HASHDIFF without an explicit text cast. "
                f"BOOLEAN coercion without ::text can collapse TRUE/FALSE/NULL into "
                f"one token, silently masking a delete."
            ),
            suggestion=f"Cast to text: IFNULL(TRIM({col}::text), '^^')",
        ))
    return findings


# ═══════════════════════════════════════════════════════════════════════════════
# 5. CATEGORY C — CTE STRUCTURE
# ═══════════════════════════════════════════════════════════════════════════════

# Standard CTE name prefixes for both 4-layer and 6-layer patterns
_STANDARD_CTE_PREFIXES = (
    "SRC_", "LOGIC_", "RENAME_", "FILTER_", "JOIN_RESULT", "FINAL",
    "SRC_BKCC", "INCR_WATERMARK",
)

# Regex to extract CTE names: <name> AS (
_CTE_NAME_RE = re.compile(
    r',?\s*(\w+)\s+[Aa][Ss]\s*\(',
    re.MULTILINE,
)


def check_cte_4layer_new_models(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """C1: New orchestrator-generated models should use 4-layer CTE: SRC → LOGIC → JOIN → FINAL.

    Enforces: Lesson #8
    Triggers on: New v_psa_stg model with RENAME_* or FILTER_* layers (6-layer legacy pattern)
    Correct: SRC_S, LOGIC_S, JOIN_RESULT (or FINAL) — no RENAME/FILTER passthroughs

    Note: Only fires on NEW files. Modified legacy files keep their 6-layer structure.
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []
    if file_status != FileStatus.NEW:
        return []

    cte_names = [m.group(1).upper() for m in _CTE_NAME_RE.finditer(sql_content)]
    has_rename = any(n.startswith("RENAME") for n in cte_names)
    has_filter = any(n.startswith("FILTER") for n in cte_names)

    if has_rename or has_filter:
        layers = []
        if has_rename:
            layers.append("RENAME")
        if has_filter:
            layers.append("FILTER")
        return [Finding(
            check_id="C1",
            check_name="cte_4layer_new_models",
            severity=Severity.WARN,
            file_path=file_path,
            line_number=1,
            message=(
                f"New models should use 4-layer CTE (SRC → LOGIC → JOIN → FINAL). "
                f"Found legacy layers: {', '.join(layers)}"
            ),
            suggestion="Remove RENAME/FILTER passthrough CTEs — merge logic into LOGIC layer",
        )]
    return []


def check_cte_no_nonstandard_names(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """C2: CTE names must follow standard patterns: SRC_*, LOGIC_*, RENAME_*, FILTER_*, JOIN_RESULT, FINAL.

    Enforces: CTE naming convention
    Triggers on: WITH TEMP_CTE AS (...), CLEANUP AS (...)
    Correct: SRC_S AS (...), LOGIC_S AS (...)
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    findings = []
    for m in _CTE_NAME_RE.finditer(sql_content):
        name = m.group(1).upper()
        # Skip WITH keyword artifacts
        if name == "WITH":
            continue
        if not any(name.startswith(p) for p in _STANDARD_CTE_PREFIXES):
            line_num = sql_content[:m.start()].count("\n") + 1
            findings.append(Finding(
                check_id="C2",
                check_name="cte_no_nonstandard_names",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=line_num,
                message=f"Non-standard CTE name '{name}'. Expected: SRC_*, LOGIC_*, RENAME_*, FILTER_*, JOIN_RESULT, FINAL",
                suggestion="Use standard CTE naming convention",
            ))
    return findings


def check_final_select_from_join_result(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """C3: Final SELECT should reference JOIN_RESULT or FINAL — not intermediate CTEs.

    Enforces: CTE structure standard
    Triggers on: Last non-CTE SELECT ... FROM RENAME_S
    Correct: SELECT ... FROM JOIN_RESULT
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # Find the last FROM clause that isn't inside a CTE definition
    # Strategy: find FROM after the last closing paren of CTEs
    # Simple approach: find the last FROM in the file
    from_matches = list(re.finditer(
        r'\bFROM\s+(\w+)\b',
        sql_content,
        re.IGNORECASE,
    ))
    if not from_matches:
        return []

    last_from = from_matches[-1]
    table_ref = last_from.group(1).upper()

    # Acceptable final FROM targets
    if table_ref in ("JOIN_RESULT", "FINAL"):
        return []

    # Skip if it's a subquery reference (e.g., in WHERE NOT EXISTS)
    # The final FROM should be the main output query
    line_num = sql_content[:last_from.start()].count("\n") + 1
    return [Finding(
        check_id="C3",
        check_name="final_select_from_join_result",
        severity=Severity.WARN,
        file_path=file_path,
        line_number=line_num,
        message=f"Final SELECT references '{table_ref}' — expected JOIN_RESULT or FINAL",
        suggestion="Final output query should SELECT FROM JOIN_RESULT (6-layer) or FINAL (4-layer)",
    )]


# ═══════════════════════════════════════════════════════════════════════════════
# 6. CATEGORY D — BKCC STANDARDS
# ═══════════════════════════════════════════════════════════════════════════════


def check_bkcc_join_on_1_equals_1(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """D1: BKCC must be joined via INNER JOIN ... ON '1' = '1' — never hardcoded.

    Enforces: Lesson #10
    Triggers on: WHERE BKCC = 'FBIN' — hardcoded BKCC value
    Correct: INNER JOIN FILTER_A ON '1' = '1'

    Note: Only checks v_psa_stg models where BKCC is a cross-join from ref table.
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # Check for BKCC column in output
    if not re.search(r'\bBKCC\b', sql_content, re.IGNORECASE):
        return []

    # Check for ON '1' = '1' pattern (the standard BKCC join)
    if re.search(r"ON\s*'1'\s*=\s*'1'", sql_content):
        return []

    # If BKCC exists but no cross-join pattern found, check for hardcoded BKCC
    hardcoded = re.search(
        r"'[^']+'\s+[Aa][Ss]\s+BKCC\b",
        sql_content,
    )
    if hardcoded:
        line_num = sql_content[:hardcoded.start()].count("\n") + 1
        return [Finding(
            check_id="D1",
            check_name="bkcc_join_on_1_equals_1",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message="BKCC must not be hardcoded — use INNER JOIN on ref_business_key_collision with ON '1' = '1'",
            suggestion="Replace hardcoded BKCC with: INNER JOIN <BKCC_CTE> ON '1' = '1'",
        )]

    # BKCC referenced but no ON '1'='1' cross-join and no hardcoded value — likely missing join
    return [Finding(
        check_id="D1",
        check_name="bkcc_join_on_1_equals_1",
        severity=Severity.WARN,
        file_path=file_path,
        line_number=1,
        message="BKCC column present but standard INNER JOIN ... ON '1' = '1' pattern not found",
        suggestion="Ensure BKCC is sourced via: INNER JOIN <BKCC_CTE> ON '1' = '1'",
    )]


def check_bkcc_from_ref_table(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """D2: BKCC must be sourced from ref('ref_business_key_collision') — not a literal.

    Enforces: Lesson #10
    Triggers on: 'FBIN' AS BKCC — literal BKCC value
    Correct: SRC_A AS (SELECT * FROM {{ ref('ref_business_key_collision') }} ...)
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    if not re.search(r'\bBKCC\b', sql_content, re.IGNORECASE):
        return []

    # Strip SQL comments before checking for ref table reference
    # (generator emits commented-out direct table references)
    stripped = re.sub(r'--[^\n]*', '', sql_content)
    stripped = re.sub(r'/\*.*?\*/', '', stripped, flags=re.DOTALL)

    # Check for ref('ref_business_key_collision') or the literal table name
    has_ref = re.search(r"ref\s*\(\s*'ref_business_key_collision'\s*\)", stripped, re.IGNORECASE)
    has_direct = re.search(r'REF_BUSINESS_KEY_COLLISION', stripped, re.IGNORECASE)

    if has_ref or has_direct:
        return []

    return [Finding(
        check_id="D2",
        check_name="bkcc_from_ref_table",
        severity=Severity.FAIL,
        file_path=file_path,
        line_number=1,
        message="BKCC must be sourced from ref('ref_business_key_collision'), not a literal value",
        suggestion="Add: SRC_A AS (SELECT * FROM {{ ref('ref_business_key_collision') }} ...)",
    )]


def check_bkcc_column_present(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """D3: Every v_psa_stg model must output a BKCC column.

    Enforces: Data Vault standard — BKCC required for all staging views
    Triggers on: v_psa_stg model with no BKCC in output
    Correct: BKCC appears in JOIN_RESULT / final SELECT
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    if re.search(r'\bBKCC\b', sql_content, re.IGNORECASE):
        return []

    return [Finding(
        check_id="D3",
        check_name="bkcc_column_present",
        severity=Severity.FAIL,
        file_path=file_path,
        line_number=1,
        message="v_psa_stg model must output a BKCC column",
        suggestion="Add BKCC from ref_business_key_collision via INNER JOIN ON '1' = '1'",
    )]


# ═══════════════════════════════════════════════════════════════════════════════
# 7. CATEGORY E — DEDUP & QUALIFY
# ═══════════════════════════════════════════════════════════════════════════════

# Regex for SELECT DISTINCT (not inside comments)
_SELECT_DISTINCT_RE = re.compile(
    r'\bSELECT\s+DISTINCT\b',
    re.IGNORECASE,
)


def check_no_select_distinct(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """E1: SELECT DISTINCT discipline — prohibited in staging and raw vault,
    downgraded to WARN in business vault.

    Enforces: Lesson #11
    Triggers on: SELECT DISTINCT col1, col2 FROM ...
    Correct (staging/raw vault): SELECT col1, col2 FROM ... QUALIFY ROW_NUMBER() OVER (...) = 1
    Acceptable (bus vault): SELECT DISTINCT in derivations (WARN, not FAIL) —
    BV models often legitimately need distinct values across joined dimensions
    where QUALIFY would be awkward. Still flagged so reviewers can confirm it
    expresses grain intent rather than masking a join cardinality bug.
    """
    if not file_path.endswith(".sql"):
        return []

    in_bus_vault = "bus_vault/" in file_path

    findings = []
    for m in _SELECT_DISTINCT_RE.finditer(sql_content):
        # Skip if inside a comment block
        prefix = sql_content[:m.start()]
        # Check for block comment
        last_open = prefix.rfind("/*")
        last_close = prefix.rfind("*/")
        if last_open > last_close:
            continue  # Inside a block comment
        # Check for line comment
        line_start = prefix.rfind("\n") + 1
        line_prefix = prefix[line_start:]
        if "--" in line_prefix:
            continue

        line_num = prefix.count("\n") + 1
        if in_bus_vault:
            findings.append(Finding(
                check_id="E1",
                check_name="no_select_distinct",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=line_num,
                message=(
                    "SELECT DISTINCT in BV — acceptable for derivations but "
                    "prefer QUALIFY where it expresses grain intent."
                ),
                suggestion=(
                    "If the DISTINCT is masking a join-cardinality bug, replace "
                    "with QUALIFY ROW_NUMBER() OVER (PARTITION BY <grain>) = 1. "
                    "If it genuinely expresses a derivation grain, keep it."
                ),
            ))
        else:
            findings.append(Finding(
                check_id="E1",
                check_name="no_select_distinct",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message="SELECT DISTINCT is prohibited — use QUALIFY ROW_NUMBER() OVER (...) = 1",
                suggestion="Replace with: SELECT ... QUALIFY ROW_NUMBER() OVER (PARTITION BY ... ORDER BY LOAD_DTS DESC) = 1",
            ))
    return findings


def check_qualify_has_row_number(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """E2: QUALIFY clauses should use ROW_NUMBER() (preferred) or RANK().

    Enforces: Lesson #11, #14
    Triggers on: QUALIFY DENSE_RANK() OVER (...) — unusual, may be intentional
    Correct: QUALIFY ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...) = 1
    """
    if not file_path.endswith(".sql"):
        return []

    findings = []
    for m in re.finditer(r'\bQUALIFY\b', sql_content, re.IGNORECASE):
        # Skip if inside a block comment
        prefix = sql_content[:m.start()]
        last_open = prefix.rfind("/*")
        last_close = prefix.rfind("*/")
        if last_open > last_close:
            continue
        # Skip if inside a line comment
        line_start = prefix.rfind("\n") + 1
        line_prefix = prefix[line_start:]
        if "--" in line_prefix:
            continue

        # Get the text after QUALIFY to check which function is used
        after = sql_content[m.end():m.end() + 100]
        if re.search(r'ROW_NUMBER\s*\(', after, re.IGNORECASE):
            continue  # Preferred
        if re.search(r'(?<!\w)RANK\s*\(', after, re.IGNORECASE):
            continue  # Acceptable (but not DENSE_RANK)

        line_num = sql_content[:m.start()].count("\n") + 1
        findings.append(Finding(
            check_id="E2",
            check_name="qualify_has_row_number",
            severity=Severity.WARN,
            file_path=file_path,
            line_number=line_num,
            message="QUALIFY should use ROW_NUMBER() (preferred) or RANK()",
            suggestion="Use: QUALIFY ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...) = 1",
        ))
    return findings


# ═══════════════════════════════════════════════════════════════════════════════
# 8. CATEGORY F — DATE & TIMEZONE HANDLING
# ═══════════════════════════════════════════════════════════════════════════════


def check_convert_timezone_utc(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """F1: All CONVERT_TIMEZONE calls must specify 'UTC' as target.

    Enforces: FBIN timezone standard
    Triggers on: CONVERT_TIMEZONE('America/New_York', col)
    Correct: CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)
    """
    if not file_path.endswith(".sql"):
        return []

    findings = []
    for m in re.finditer(r'CONVERT_TIMEZONE\s*\(\s*\'([^\']+)\'', sql_content, re.IGNORECASE):
        tz = m.group(1)
        if tz.upper() != "UTC":
            line_num = sql_content[:m.start()].count("\n") + 1
            findings.append(Finding(
                check_id="F1",
                check_name="convert_timezone_utc",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message=f"CONVERT_TIMEZONE must use 'UTC', found '{tz}'",
                suggestion="Use: CONVERT_TIMEZONE('UTC', <column>)",
            ))
    return findings


def check_null_date_1900_placeholder(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """F2: NULL dates should use '1900-01-01'::TIMESTAMP placeholder.

    Enforces: FBIN date handling standard
    Triggers on: IFNULL(date_col, '9999-12-31') — wrong sentinel
    Correct: IFNULL(CONVERT_TIMEZONE('UTC', date_col), '1900-01-01'::TIMESTAMP)
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # Look for IFNULL with non-standard date sentinels
    findings = []
    for m in re.finditer(
        r"IFNULL\s*\([^,]+,\s*'(\d{4}-\d{2}-\d{2})'",
        sql_content,
        re.IGNORECASE,
    ):
        date_val = m.group(1)
        if date_val != "1900-01-01":
            line_num = sql_content[:m.start()].count("\n") + 1
            findings.append(Finding(
                check_id="F2",
                check_name="null_date_1900_placeholder",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=line_num,
                message=f"NULL date placeholder should be '1900-01-01', found '{date_val}'",
                suggestion="Use: IFNULL(CONVERT_TIMEZONE('UTC', date_col), '1900-01-01'::TIMESTAMP)",
            ))
    return findings


def check_load_dts_derivation_fivetran(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """F3: Fivetran models: LOAD_DTS must derive from _FIVETRAN_SYNCED, not PSA_LOAD_DTS.

    Enforces: FBIN LOAD_DTS derivation standard
    Triggers on: PSA_LOAD_DTS AS LOAD_DTS in a model that has _FIVETRAN_SYNCED
    Correct: CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED) AS LOAD_DTS
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # Only for Fivetran sources (has _FIVETRAN_SYNCED)
    if not re.search(r'\b_FIVETRAN_SYNCED\b', sql_content, re.IGNORECASE):
        return []

    # Check if LOAD_DTS references _FIVETRAN_SYNCED
    load_dts_line = re.search(
        r'(.{0,80})\b[Aa][Ss]\s+LOAD_DTS\b',
        sql_content,
    )
    if not load_dts_line:
        return []

    context = load_dts_line.group(1).upper()
    if "_FIVETRAN_SYNCED" in context:
        return []  # Correct derivation

    line_num = sql_content[:load_dts_line.start()].count("\n") + 1
    return [Finding(
        check_id="F3",
        check_name="load_dts_derivation_fivetran",
        severity=Severity.FAIL,
        file_path=file_path,
        line_number=line_num,
        message="Fivetran model: LOAD_DTS must derive from _FIVETRAN_SYNCED, not PSA_LOAD_DTS",
        suggestion="Use: CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED) AS LOAD_DTS",
    )]


def check_load_dts_derivation_snp_glue(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """F4: SNP GLUE models: LOAD_DTS must derive from GLCHANGETIME with SUBSTR+FF9 mask.

    Enforces: FBIN LOAD_DTS derivation standard
    Triggers on: CONVERT_TIMEZONE('UTC', GLCHANGETIME) AS LOAD_DTS — wrong, GLCHANGETIME is NUMBER
    Correct: IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC',
             TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME,1,14) || '.' || SUBSTR(GLCHANGETIME,16),
             'YYYYMMDDHH24MISS.FF9')))
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # Only for SNP GLUE sources (has GLCHANGETIME)
    if not re.search(r'\bGLCHANGETIME\b', sql_content, re.IGNORECASE):
        return []

    # Check if LOAD_DTS derivation uses SUBSTR pattern
    if re.search(r'SUBSTR\s*\(\s*GLCHANGETIME', sql_content, re.IGNORECASE):
        return []  # Has the SUBSTR pattern — correct

    # Direct CONVERT_TIMEZONE on GLCHANGETIME is wrong
    if re.search(r'CONVERT_TIMEZONE\s*\([^)]*GLCHANGETIME', sql_content, re.IGNORECASE):
        line_num = 1
        m = re.search(r'GLCHANGETIME', sql_content, re.IGNORECASE)
        if m:
            line_num = sql_content[:m.start()].count("\n") + 1
        return [Finding(
            check_id="F4",
            check_name="load_dts_derivation_snp_glue",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message="SNP GLUE model: GLCHANGETIME is NUMBER — must use SUBSTR+TO_TIMESTAMP_NTZ pattern",
            suggestion="Use: TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME,1,14) || '.' || SUBSTR(GLCHANGETIME,16), 'YYYYMMDDHH24MISS.FF9')",
        )]

    return []


def check_load_dts_has_convert_timezone(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """F5: Every LOAD_DTS alias must include CONVERT_TIMEZONE — no raw passthrough.

    Enforces: FBIN timezone standard
    Triggers on: PSA_LOAD_DTS AS LOAD_DTS — raw passthrough without UTC conversion
    Correct: CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS) AS LOAD_DTS
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # Find LOAD_DTS alias definition
    load_dts_match = re.search(
        r'(.{0,120})\b[Aa][Ss]\s+LOAD_DTS\b',
        sql_content,
    )
    if not load_dts_match:
        return []

    context = load_dts_match.group(1).upper()
    if "CONVERT_TIMEZONE" in context:
        return []
    # IFF(...) patterns with CONVERT_TIMEZONE deeper in the expression
    # SNP GLUE models can have 500+ chars between CONVERT_TIMEZONE and AS LOAD_DTS
    # due to multi-line SUBSTR+REGEXP_REPLACE patterns
    start = max(0, load_dts_match.start() - 600)
    wider_context = sql_content[start:load_dts_match.end()].upper()
    if "CONVERT_TIMEZONE" in wider_context and "LOAD_DTS" in wider_context:
        return []

    line_num = sql_content[:load_dts_match.start()].count("\n") + 1
    return [Finding(
        check_id="F5",
        check_name="load_dts_has_convert_timezone",
        severity=Severity.FAIL,
        file_path=file_path,
        line_number=line_num,
        message="LOAD_DTS must include CONVERT_TIMEZONE('UTC', ...) — no raw passthrough",
        suggestion="Use: CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS) AS LOAD_DTS",
    )]


# ═══════════════════════════════════════════════════════════════════════════════
# 9. CATEGORY H — TEST COVERAGE (YAML)
# ═══════════════════════════════════════════════════════════════════════════════


def check_data_tests_not_deprecated(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """H2: Use data_tests: — not deprecated tests: key in YAML.

    Enforces: Lesson #7
    Triggers on: tests: at model level in YAML
    Correct: data_tests: at model level in YAML
    """
    if yaml_content is None:
        return []
    if not file_path.endswith((".yml", ".yaml")):
        return []

    findings = []
    for line_num, line in enumerate(yaml_content.splitlines(), 1):
        stripped = line.lstrip()
        # Match 'tests:' at start of line (indented), but not 'data_tests:'
        if stripped.startswith("tests:") and not stripped.startswith("data_tests:"):
            findings.append(Finding(
                check_id="H2",
                check_name="data_tests_not_deprecated",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message="Use 'data_tests:' — 'tests:' is deprecated in dbt 1.5+",
                suggestion="Replace 'tests:' with 'data_tests:'",
            ))
    return findings


def check_no_constraints_on_views(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """H8: dbt_constraints (primary_key/foreign_key) must NOT be on views (v_psa_stg).

    Enforces: Snowflake cannot enforce PK/FK on views
    Triggers on: dbt_constraints.primary_key in a v_psa_stg YAML
    Correct: Use not_null + unique_combination_of_columns for v_psa_stg models
    """
    if yaml_content is None:
        return []
    if not file_path.endswith((".yml", ".yaml")):
        return []
    # Only applies to v_psa_stg YAML files
    basename = file_path.rsplit("/", 1)[-1] if "/" in file_path else file_path
    if not basename.startswith("v_psa_stg") and "v_psa_stg" not in basename:
        # Also check if file is inside int_staging_views/
        if "int_staging_views/" not in file_path:
            return []

    findings = []
    for line_num, line in enumerate(yaml_content.splitlines(), 1):
        if "dbt_constraints" in line:
            findings.append(Finding(
                check_id="H8",
                check_name="no_constraints_on_views",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message="dbt_constraints (PK/FK) cannot be enforced on views — remove from v_psa_stg YAML",
                suggestion="Use not_null + unique_combination_of_columns instead of dbt_constraints",
            ))
    return findings


def _parse_pk_unique_column_lists(yaml_content: str):
    """Yield (model_name, column_list_upper, line_number) for each
    ``column_names:`` or ``combination_of_columns:`` block (under
    ``dbt_constraints.primary_key`` / ``unique_combination_of_columns``)
    in a dbt schema YAML.

    Extracted from H9's original inline state machine so H10 (and any
    future grain-column check) can reuse the exact same parser without
    drift. State machine semantics unchanged from the original:
      - Tracks current model via ``- name:`` at indent <= 4 (model-level
        only). Column-level ``- name:`` entries (inside a ``columns:``
        block) MUST NOT be treated as model boundaries — see the
        ``in_columns_block`` state below. Without that guard, a column
        ``- name: COL`` at indent <= 4 (the FBIN convention puts column
        items at indent 2) would silently overwrite ``in_model``, and
        any later ``column_names:`` / ``combination_of_columns:`` list
        would be mis-attributed to a column name instead of the model.
      - On ``column_names:`` / ``combination_of_columns:``, starts a fresh
        list; collects ``- COL`` items at the established list indent;
        flushes on indent change, on next model boundary, or at EOF.
      - Yields the same ``(model_name, [COL, ...], line_number)`` tuples
        that the old ``_evaluate_sat_grain`` callsites consumed.

    A model with both a primary_key and a unique_combination_of_columns
    will yield two tuples (one per list) — callers handle them independently.

    Known limitation (PR #1827 review R-parser; tracked as a follow-up):
      This parser is indent-heuristic-based. The structurally-correct
      durable fix is to use ``yaml.safe_load`` (same pattern H11 adopted)
      and walk the parsed tree. That refactor is intentionally deferred
      because it touches H9's pre-existing behavior; it lives in this PR's
      Follow-ups list rather than expanding scope here.
    """
    in_model = None
    in_columns_block = False
    columns_block_indent = -1  # indent of the "columns:" keyword line
    collecting_columns = False
    col_list_indent = -1
    pk_columns: list[str] = []
    lines = yaml_content.splitlines()

    for line_num, line in enumerate(lines, 1):
        stripped = line.lstrip()
        indent = len(line) - len(stripped)

        if not stripped or stripped.startswith("#"):
            continue

        # Exit the columns: block when we encounter a sibling key (or a
        # higher-level key / new model). Two cases:
        #   - indent < columns_block_indent: definitely outside the block
        #     (e.g., a new ``- name: sat_xxx`` at indent 0 after a columns
        #     block at indent 2).
        #   - indent == columns_block_indent AND the line does NOT start
        #     with "- ": a sibling key like ``data_tests:`` at the same
        #     indent as ``columns:``. (We can't use a plain ``<=`` because
        #     column list items ``- name: COL`` at indent == columns_block_indent
        #     are legitimately inside the block.)
        if in_columns_block:
            if indent < columns_block_indent:
                in_columns_block = False
                columns_block_indent = -1
            elif indent == columns_block_indent and not stripped.startswith("- "):
                in_columns_block = False
                columns_block_indent = -1

        # Enter the columns: block on a bare ``columns:`` key (trailing
        # whitespace/comments tolerated). Match the key-only form so we
        # don't accidentally trigger on ``column_names:`` (the grain key).
        _key_part = stripped.split("#", 1)[0].rstrip()
        if _key_part == "columns:":
            in_columns_block = True
            columns_block_indent = indent
            continue

        # Model boundary detection. Suppressed when inside a ``columns:``
        # block (the line is a column declaration, not a new model).
        if stripped.startswith("- name:") and indent <= 4 and not in_columns_block:
            if collecting_columns and in_model and pk_columns:
                yield (in_model, list(pk_columns), line_num - 1)
            in_model = stripped.replace("- name:", "").strip()
            collecting_columns = False
            pk_columns = []

        if stripped.startswith("column_names:") or stripped.startswith("combination_of_columns:"):
            collecting_columns = True
            col_list_indent = -1
            pk_columns = []
            continue

        if collecting_columns:
            if stripped.startswith("- "):
                item_indent = indent
                if col_list_indent == -1:
                    col_list_indent = item_indent
                if item_indent == col_list_indent:
                    col = stripped[2:].strip().strip("'\"")
                    if col:
                        pk_columns.append(col.upper())
                else:
                    if in_model and pk_columns:
                        yield (in_model, list(pk_columns), line_num - 1)
                    collecting_columns = False
                    pk_columns = []
            elif indent <= col_list_indent or col_list_indent == -1:
                if in_model and pk_columns:
                    yield (in_model, list(pk_columns), line_num - 1)
                collecting_columns = False
                pk_columns = []

    if collecting_columns and in_model and pk_columns:
        yield (in_model, list(pk_columns), len(lines))


def check_sat_grain_suggests_msat(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """H9: sat_ with grain columns beyond parent_HK + LOAD_DTS suggests msat_.

    DV 2.0 standard:
      - sat_:  grain = parent_HK + LOAD_DTS (one record per key per time)
      - msat_: grain = parent_HK + child_key(s) + LOAD_DTS (multi-active)
      - lsat_: grain = link_HK + LOAD_DTS
      - lmsat_: grain = link_HK + child_key(s) + LOAD_DTS

    Triggers on: sat_ or lsat_ YAML with extra columns in PK/unique test
    Skips: msat_, lmsat_, esat_ (already multi-active or effectivity)
    """
    if yaml_content is None:
        return []
    if not file_path.endswith((".yml", ".yaml")):
        return []

    # Only check sat_ and lsat_ models (not msat_, lmsat_, esat_)
    basename = file_path.rsplit("/", 1)[-1] if "/" in file_path else file_path
    basename_lower = basename.lower()

    # Must be in raw_vault/sat/ directory
    if "raw_vault/sat/" not in file_path and "raw_vault\\sat\\" not in file_path:
        return []

    findings: list[Finding] = []
    for model_name, pk_columns, line_number in _parse_pk_unique_column_lists(yaml_content):
        _evaluate_sat_grain(findings, model_name, pk_columns, file_path, line_number)
    return findings


def _evaluate_sat_grain(
    findings: list,
    model_name: str,
    pk_columns: list[str],
    file_path: str,
    line_number: int,
) -> None:
    """Evaluate if a sat_ model's grain suggests it should be msat_."""
    model_lower = model_name.lower()

    # Only check sat_ and lsat_ (not msat_, lmsat_, esat_)
    is_sat = model_lower.startswith("sat_")
    is_lsat = model_lower.startswith("lsat_")
    if not is_sat and not is_lsat:
        return

    # Filter out structural columns: any _HK column, LOAD_DTS, REC_SRC
    extra_cols = [
        c for c in pk_columns
        if not c.endswith("_HK")
        and c != "LOAD_DTS"
        and c != "REC_SRC"
    ]

    if extra_cols:
        suggested = f"msat_{model_name[4:]}" if is_sat else f"lmsat_{model_name[5:]}"
        findings.append(Finding(
            check_id="H9",
            check_name="sat_grain_suggests_msat",
            severity=Severity.WARN,
            file_path=file_path,
            line_number=line_number,
            message=(
                f"Model {model_name} has grain columns beyond parent_HK + LOAD_DTS: "
                f"{extra_cols}. This suggests a multi-active satellite — "
                f"consider renaming to {suggested}."
            ),
            suggestion=f"Rename to {suggested} if this is multi-active (DV 2.0 standard)",
        ))


# Columns that must never appear in PK / unique_combination_of_columns grain tests.
# HASHDIFF in particular is a payload hash — including it in a PK masks true
# duplicates and breaks the grain contract (rows with same key but different
# payload would falsely test as distinct grain rows).
#
# IMPORTANT: LOAD_DTS is NOT on this list — the canonical satellite grain
# IS (parent_HK, LOAD_DTS) per Data Vault 2.0. Including LOAD_DTS in a sat
# PK is REQUIRED (one row per key per load), not a violation. LOAD_DTS is
# separately excluded from HASHDIFF (check B4) because change-detection
# shouldn't key on load time — different rule, different column treatment.
_GRAIN_FORBIDDEN_COLS = frozenset({
    "HASHDIFF",
    "REC_SRC",
    "BKCC",
    "PSA_DELETE_IND",
    "PSA_LOAD_DTS",
    "PSA_RECORD_SOURCE",
    "_FIVETRAN_SYNCED",
    "_FIVETRAN_ID",
    "_FIVETRAN_DELETED",
})


def check_grain_excludes_metadata(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
    repo_root: Path | None = None,
) -> list[Finding]:
    """H10: Grain tests (primary_key / unique_combination_of_columns) must not
    include metadata or payload columns.

    Enforces the DV 2.0 grain contract: a model's grain is defined by its
    *_HK (parent key) plus any dependent child keys (msat) PLUS the canonical
    satellite ``LOAD_DTS`` (sat grain is parent_HK + LOAD_DTS — one row per
    key per load). Metadata columns (HASHDIFF, REC_SRC, BKCC) and payload
    markers (PSA_DELETE_IND, _FIVETRAN_DELETED, etc.) are NEVER part of grain.

    Including HASHDIFF in a PK is especially dangerous — it masks true
    duplicates because rows with same key but different payload would
    falsely test as distinct grain rows, and the test would pass while
    the model silently stores ambiguous history.

    Forbidden columns:
        HASHDIFF, REC_SRC, BKCC,
        PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE,
        _FIVETRAN_SYNCED, _FIVETRAN_ID, _FIVETRAN_DELETED

    NOT forbidden (intentionally):
        LOAD_DTS — REQUIRED in satellite PK as the canonical DV 2.0 grain.
                   Separately excluded from HASHDIFF (B4) for a different
                   reason: change-detection shouldn't key on load time.

    Allowed grain cols: *_HK, LOAD_DTS, and dependent child keys.

    Reports each offending column per (model, list) so the fix is precise.
    """
    if yaml_content is None or not file_path.endswith((".yml", ".yaml")):
        return []

    findings: list[Finding] = []
    for model_name, pk_columns, line_number in _parse_pk_unique_column_lists(yaml_content):
        for col in pk_columns:
            if col in _GRAIN_FORBIDDEN_COLS:
                findings.append(Finding(
                    check_id="H10",
                    check_name="grain_excludes_metadata",
                    severity=Severity.FAIL,
                    file_path=file_path,
                    line_number=line_number,
                    message=(
                        f"Grain test for {model_name} includes metadata/payload "
                        f"column '{col}' — PK/unique grain must be *_HK + "
                        f"dependent child keys only. Remove '{col}'."
                    ),
                    suggestion=(
                        f"Remove '{col}' from the column list. If '{col}' "
                        f"genuinely participates in distinguishing rows, the "
                        f"model's grain may need rethinking (consider msat/lmsat)."
                    ),
                ))

    # Apply burn-down-only grandfather downgrade to pre-existing debt entries.
    # See scripts/automation/.code_review_grandfather for the frozen list.
    # H10 correctness-tier entries (HASHDIFF/BKCC in grain) require an explicit
    # DataOps lead waiver to be ADDED to the list — the standard burn-down rule
    # applies (removal only) once they're on it.
    grandfather = load_grandfather_list(repo_root)
    return [_apply_grandfather(f, grandfather) for f in findings]


def check_sat_has_foreign_key(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
    repo_root: Path | None = None,
) -> list[Finding]:
    """H11: Every satellite YAML (raw_vault/sat/) must declare a foreign_key
    constraint pointing the parent_HK back to its hub or link.

    The generator adds the FK automatically as part of the satellite build
    template. A missing FK is therefore a structural defect: it means the
    model was hand-edited around the generator OR the YAML was checked in
    without running the build pipeline. Either way, downstream models
    cannot reliably navigate the satellite back to its parent hub/link.

    Presence-only check — we do NOT validate the FK target (model_name or
    column reference). dbt's own ``dbt-constraints`` package validates the
    reference at parse time; this check just enforces declaration.

    Applies to: YAML files in ``raw_vault/sat/`` whose model name starts
    with one of: sat_, msat_, lsat_, lmsat_, esat_, rsat_.

    Implementation note: uses ``yaml.safe_load`` rather than a line-by-line
    state machine to avoid conflating model-level ``- name:`` with
    column-level ``- name:`` (both can land at indent 2 in dbt schema YAMLs).
    """
    if yaml_content is None or not file_path.endswith((".yml", ".yaml")):
        return []
    if "raw_vault/sat/" not in file_path and "raw_vault\\sat\\" not in file_path:
        return []

    import yaml as _yaml
    try:
        data = _yaml.safe_load(yaml_content) or {}
    except _yaml.YAMLError:
        return []  # malformed YAML — not our problem to report here
    if not isinstance(data, dict):
        return []

    sat_prefixes = ("sat_", "msat_", "lsat_", "lmsat_", "esat_", "rsat_")
    findings: list[Finding] = []

    for model in (data.get("models") or []):
        if not isinstance(model, dict):
            continue
        model_name = str(model.get("name") or "")
        if not model_name.lower().startswith(sat_prefixes):
            continue

        # Walk the model dict looking for any 'foreign_key' key under
        # data_tests / tests at model or column level. dbt_constraints uses
        # 'dbt_constraints.foreign_key' as the test name; the foreign_key
        # token always appears as a YAML key (mapping name).
        if _yaml_has_foreign_key(model):
            continue

        # Locate the source line of this model's '- name:' for reporting.
        # yaml.safe_load discards line numbers, so re-scan textually.
        line_number = 1
        for ln, line in enumerate(yaml_content.splitlines(), 1):
            stripped = line.lstrip()
            if stripped.startswith("- name:") and \
                    stripped.replace("- name:", "").strip() == model_name:
                # Heuristic only — take the first '- name: <model_name>' match.
                # We do NOT structurally verify this entry isn't nested inside
                # a 'columns:' block; the one-model-per-file convention makes
                # the first match the model-level entry in practice. A column
                # named identically to its parent model could shadow the
                # model-level line. Standing follow-up: replace this indent-
                # free text scan with yaml.safe_load-based structural parsing
                # (reach the model via data['models'] directly, then resolve
                # the line number from the loaded node).
                line_number = ln
                break

        findings.append(Finding(
            check_id="H11",
            check_name="sat_has_foreign_key",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_number,
            message=(
                f"{model_name} is a satellite but declares no foreign_key — "
                f"parent_HK must FK back to its hub/link. FK is added by build "
                f"automation, so a missing FK means the model bypassed the pipeline."
            ),
            suggestion=(
                f"Re-run the generator/build for {model_name}, OR manually add "
                f"a dbt_constraints.foreign_key test under the parent_HK column "
                f"pointing at the hub/link."
            ),
        ))

    # Apply burn-down-only grandfather downgrade to pre-existing debt entries.
    # See scripts/automation/.code_review_grandfather for the frozen list.
    grandfather = load_grandfather_list(repo_root)
    return [_apply_grandfather(f, grandfather) for f in findings]


def _yaml_has_foreign_key(node) -> bool:
    """Recursively scan a YAML-loaded structure for any 'foreign_key' key
    (e.g. ``dbt_constraints.foreign_key:`` test entries). Presence-only —
    does not validate the target.
    """
    if isinstance(node, dict):
        for key, value in node.items():
            if isinstance(key, str) and key.lower().endswith("foreign_key"):
                return True
            if _yaml_has_foreign_key(value):
                return True
    elif isinstance(node, list):
        for item in node:
            if _yaml_has_foreign_key(item):
                return True
    return False


# ═══════════════════════════════════════════════════════════════════════════════
# 10. CATEGORY I — SOURCE & LAYER INTEGRITY
# ═══════════════════════════════════════════════════════════════════════════════

# Regex to find FROM clauses with direct schema.table references (no {{ }})
_DIRECT_TABLE_RE = re.compile(
    r'\bFROM\s+([A-Z_]\w+\.[A-Z_]\w+)\b',
    re.IGNORECASE,
)


def check_uses_source_or_ref(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """I1: All FROM clauses must use {{ source(...) }} or {{ ref(...) }} — no direct SCHEMA.TABLE.

    Enforces: dbt lineage tracking standard
    Triggers on: FROM SAP_ECC_PRD.Z_VBUP
    Correct: FROM {{ source('sap_ecc_prd', 'z_vbup') }}

    Note: Direct refs inside block comments (/* ... */) are ignored.
    """
    if not file_path.endswith(".sql"):
        return []

    findings = []
    for m in _DIRECT_TABLE_RE.finditer(sql_content):
        table_ref = m.group(1)
        # Skip if inside a block comment
        prefix = sql_content[:m.start()]
        last_open = prefix.rfind("/*")
        last_close = prefix.rfind("*/")
        if last_open > last_close:
            continue
        # Skip if on a commented line
        line_start = prefix.rfind("\n") + 1
        line_prefix = prefix[line_start:]
        if "--" in line_prefix and line_prefix.index("--") < len(line_prefix) - 2:
            continue

        line_num = prefix.count("\n") + 1
        findings.append(Finding(
            check_id="I1",
            check_name="uses_source_or_ref",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message=f"Direct table reference '{table_ref}' — use {{{{ source() }}}} or {{{{ ref() }}}} instead",
            suggestion=f"Replace with: {{{{ source('{table_ref.split('.')[0].lower()}', '{table_ref.split('.')[1].lower()}') }}}}",
        ))
    return findings


def check_dim_fact_no_business_logic(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """I3: dim_* and fact_* models should NOT contain CASE WHEN — logic belongs in PIT/PB.

    Enforces: Business Logic Layer Rules
    Triggers on: CASE WHEN status = 'Active' THEN ... in a dim_ model
    Correct: SELECT * FROM {{ ref('pit_customer') }} — simple wrapper
    """
    if not file_path.endswith(".sql"):
        return []

    basename = file_path.rsplit("/", 1)[-1] if "/" in file_path else file_path
    if not (basename.startswith("dim_") or basename.startswith("fact_")):
        return []

    findings = []
    # Check for CASE WHEN expressions
    for m in re.finditer(r'\bCASE\s+WHEN\b', sql_content, re.IGNORECASE):
        # Skip if inside a comment
        prefix = sql_content[:m.start()]
        last_open = prefix.rfind("/*")
        last_close = prefix.rfind("*/")
        if last_open > last_close:
            continue
        line_start = prefix.rfind("\n") + 1
        line_prefix = prefix[line_start:]
        if "--" in line_prefix:
            continue

        line_num = prefix.count("\n") + 1
        findings.append(Finding(
            check_id="I3",
            check_name="dim_fact_no_business_logic",
            severity=Severity.WARN,
            file_path=file_path,
            line_number=line_num,
            message="dim/fact models should not contain CASE WHEN — business logic belongs in PIT/PB layer",
            suggestion="Move CASE WHEN logic to the PIT/PB model; dim/fact should be a simple SELECT wrapper",
        ))

    # Check for WHERE clause filters (excluding {{ ref() }}/{{ source() }} and IS NOT NULL)
    for m in re.finditer(r'\bWHERE\b', sql_content, re.IGNORECASE):
        prefix = sql_content[:m.start()]
        # Skip if inside a comment
        last_open = prefix.rfind("/*")
        last_close = prefix.rfind("*/")
        if last_open > last_close:
            continue
        line_start = prefix.rfind("\n") + 1
        line_prefix = prefix[line_start:]
        if "--" in line_prefix:
            continue

        # Get the full WHERE clause (to end of line or next keyword)
        clause_end = sql_content.find("\n", m.end())
        if clause_end == -1:
            clause_end = len(sql_content)
        clause = sql_content[m.end():clause_end].strip()

        # Skip benign patterns: IS NOT NULL, incremental guards, Jinja
        if re.match(r'.*\bIS\s+NOT\s+NULL\b', clause, re.IGNORECASE):
            continue
        if '{%' in clause or '{{' in clause:
            continue

        line_num = prefix.count("\n") + 1
        findings.append(Finding(
            check_id="I3",
            check_name="dim_fact_no_business_logic",
            severity=Severity.WARN,
            file_path=file_path,
            line_number=line_num,
            message="dim/fact models should not contain WHERE filters — business logic belongs in PIT/PB layer",
            suggestion="Move WHERE filter logic to the PIT/PB model; dim/fact should be a simple SELECT wrapper",
        ))

    return findings


# Pre-compiled regexes for I2 (compile once at module load, reused per call).
# {{ source('x', 'y') }} — two-arg form (only form dbt accepts for sources)
_I2_SOURCE_RE = re.compile(
    r"\{\{\s*source\s*\(\s*['\"]([^'\"]+)['\"]\s*,\s*"
    r"['\"]([^'\"]+)['\"]\s*\)\s*\}\}",
    re.IGNORECASE,
)
# {{ ref('project', 'model') }} — two-arg cross-project form ONLY.
# Single-arg {{ ref('model') }} is first-party and compiles to the project's
# own database (governed by definition), so it is intentionally not matched.
_I2_CROSS_REF_RE = re.compile(
    r"\{\{\s*ref\s*\(\s*['\"]([^'\"]+)['\"]\s*,\s*"
    r"['\"]([^'\"]+)['\"]\s*\)\s*\}\}",
    re.IGNORECASE,
)


def _i2_is_in_comment(sql_content: str, pos: int) -> bool:
    """Return True if ``pos`` is inside a /* ... */ block or after -- on the
    same line. Mirrors the comment-skip pattern used throughout the module.
    """
    prefix = sql_content[:pos]
    last_open = prefix.rfind("/*")
    last_close = prefix.rfind("*/")
    if last_open > last_close:
        return True
    line_start = prefix.rfind("\n") + 1
    if "--" in prefix[line_start:]:
        return True
    return False


def _apply_grandfather(finding: "Finding", grandfather: set[tuple[str, str]]) -> "Finding":
    """Downgrade FAIL → WARN and prefix the message with ``[GRANDFATHERED]``
    if ``(finding.check_id, finding.file_path)`` is in the grandfather set.

    Returns the finding unchanged otherwise. Used by I2 and I4 to honor
    the burn-down-only frozen list at
    ``scripts/automation/.code_review_grandfather``.

    The downgraded finding's suggestion gets a burn-down hint appended so
    reviewers know the entry can be removed from the list when the file
    is cleaned up.
    """
    if not is_grandfathered(finding.check_id, finding.file_path, grandfather):
        return finding
    return Finding(
        check_id=finding.check_id,
        check_name=finding.check_name,
        severity=Severity.WARN,
        file_path=finding.file_path,
        line_number=finding.line_number,
        message=f"[GRANDFATHERED] {finding.message}",
        suggestion=(
            f"{finding.suggestion}  "
            f"BURN-DOWN: once this file no longer triggers {finding.check_id}, "
            f"remove the matching entry from scripts/automation/.code_review_grandfather."
        ),
    )


def check_source_ref_in_governed_allowlist(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
    repo_root: Path | None = None,
) -> list[Finding]:
    """I5: Every source() must resolve to a governed database, and every
    cross-project ref() must point at a governed project.

    Closes a gap in I1 (which only catches hardcoded SCHEMA.TABLE literals).
    A properly-declared ``{{ source('bi_sandbox', 'foo') }}`` passes I1 today
    even though ``bi_sandbox`` is an ungoverned sandbox — I5 catches that
    by resolving the source via the project's sources YAML to its actual
    (database, schema) and checking against ``governance_allowlist.yml``.

    Companion to I2/I4 (layer-aware staging discipline): this check is the
    broad repo-wide governance backstop; I2/I4 are the per-layer narrower
    rules. Defense in depth — I5 still fires if a sandbox source is
    introduced into a layer I2/I4 doesn't cover (e.g., a one-off model at
    repo root that isn't under int_staging_views / raw_vault / bus_vault /
    info_mart).

    Triggers on:
      - source() whose database resolves outside the allowlist (after env-swap
        normalization) — FAIL with the resolved database in the message
      - source() referencing a name not declared in any _sources*.yml — FAIL
        with "undeclared source"
      - two-arg ref('project','model') whose project is not allowlisted — FAIL

    Skipped (no finding):
      - first-party single-arg ref('model') (compiles to project DB — governed)
      - source()/ref() inside /* */ blocks or after -- line comments
      - all matches when governance_allowlist.yml is missing or unparseable
        (fails open so a missing config doesn't block every PR)

    Architecture note: this is a CONTENT-ONLY check matching the existing
    module contract. No manifest load, no dbt parse, no network I/O. The
    sources YAML map and allowlist are memoized per ``repo_root`` (see
    ``load_source_resolver`` / ``load_governance_allowlist``).
    """
    if not file_path.endswith(".sql"):
        return []
    if repo_root is None:
        repo_root = _PROJECT_ROOT

    allowlist = load_governance_allowlist(repo_root)
    # Fail open: if the allowlist is empty, treat as "governance not configured"
    # and skip rather than failing every source() in the repo.
    if not allowlist.get("allowed_databases") and not allowlist.get("allowed_schemas"):
        return []

    source_map = load_source_resolver(repo_root)
    allowed_dbs_display = ", ".join(allowlist.get("allowed_databases", [])) or "(none)"
    allowed_projects = set(allowlist.get("allowed_projects", []))

    findings: list[Finding] = []

    # --- source() resolution ---
    for m in _I2_SOURCE_RE.finditer(sql_content):
        if _i2_is_in_comment(sql_content, m.start()):
            continue
        src_name = m.group(1).lower()
        tbl_name = m.group(2).lower()
        line_num = sql_content[: m.start()].count("\n") + 1
        key = (src_name, tbl_name)

        if key not in source_map:
            findings.append(Finding(
                check_id="I5",
                check_name="source_ref_in_governed_allowlist",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message=(
                    f"source() references undeclared source "
                    f"'{src_name}.{tbl_name}' — not found in any models/**/*sources*.yml"
                ),
                suggestion=(
                    f"Declare table '{tbl_name}' under source '{src_name}' "
                    f"in a _sources*.yml, OR fix the source() reference."
                ),
            ))
            continue

        database, schema, _yaml_basename = source_map[key]
        if is_database_allowed(database, schema, allowlist):
            continue

        resolved_display = (
            f"{normalize_database(database)}.{(schema or '').upper()}"
        )
        findings.append(Finding(
            check_id="I5",
            check_name="source_ref_in_governed_allowlist",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message=(
                f"source '{src_name}.{tbl_name}' resolves to {resolved_display} "
                f"— outside the governed allowlist ({allowed_dbs_display}). "
                f"Sandbox/manual artifacts cannot feed production models."
            ),
            suggestion=(
                f"Promote into a governed location (e.g. EDP_BRONZE_PROD) and "
                f"reference that, OR add the database/schema to "
                f"governance_allowlist.yml if it is in fact governed."
            ),
        ))

    # --- two-arg cross-project ref() (no-op in this repo as of 2026-06-22) ---
    # Verified zero usages via grep; this branch is here so that introducing
    # a cross-project ref later is immediately validated against allowed_projects.
    for m in _I2_CROSS_REF_RE.finditer(sql_content):
        if _i2_is_in_comment(sql_content, m.start()):
            continue
        project_name = m.group(1).lower()
        model_name = m.group(2).lower()
        if project_name in allowed_projects:
            continue
        line_num = sql_content[: m.start()].count("\n") + 1
        findings.append(Finding(
            check_id="I5",
            check_name="source_ref_in_governed_allowlist",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message=(
                f"cross-project ref('{project_name}', '{model_name}') references "
                f"project '{project_name}' which is not in the governed "
                f"allowlist (allowed_projects)."
            ),
            suggestion=(
                f"Use a first-party ref(), OR add '{project_name}' to "
                f"allowed_projects in governance_allowlist.yml if that upstream "
                f"project is governed."
            ),
        ))

    return findings


# Regex matching {{ source('x', 'y') }} (shared by I2 and I4).
# Identical to _I2_SOURCE_RE (I5's renamed regex) but named per-check for clarity
# when reading either function in isolation. Kept as a separate binding rather
# than reused so a future change to one check's match shape doesn't silently
# affect the other.
_I2_STAGING_SOURCE_RE = _I2_SOURCE_RE
_I4_SOURCE_RE = _I2_SOURCE_RE
# Regex matching {{ ref('name') }} (single OR two-arg form). Used by I2 to
# detect refs in staging; the BKCC exemption is matched separately below.
_I2_ANY_REF_RE = re.compile(
    r"\{\{\s*ref\s*\(\s*['\"]([^'\"]+)['\"]"
    r"(?:\s*,\s*['\"]([^'\"]+)['\"])?\s*\)\s*\}\}",
    re.IGNORECASE,
)
# The one ref() exemption permitted in staging — BKCC cross-join driver.
# Matches existing D2 check's expectation (ref_business_key_collision).
_I2_BKCC_REF_NAME = "ref_business_key_collision"


def check_staging_source_discipline(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
    repo_root: Path | None = None,
) -> list[Finding]:
    """I2: Staging models must source() from PSA_PROD (or EDP_BRONZE_PROD for
    sources registered in the legacy YAML), and must not ref() anything
    except ``ref_business_key_collision``.

    Enforces FBIN's two-layer raw-data convention:
      1. Raw data lands in PSA via Fivetran/SNP GLUE/etc.
      2. v_psa_stg models source() from PSA only \u2014 except legacy v_psa_stg
         models registered in ``_sources_base_legacy.yml`` may also source
         from EDP_BRONZE_PROD (grandfathered before the PSA-only rule).
      3. ref() is reserved for downstream layers; the BKCC cross-join driver
         (``ref('ref_business_key_collision')``) is the sole exception.

    Why a separate check from I5 (governed allowlist):
      - I5 catches sandbox dependencies *anywhere* in the repo.
      - I2 catches staging-specific discipline: a staging model that source()s
        from EDP_GOLD_PROD passes I5 (allowlisted) but FAILs I2 (not PSA and
        not legacy). A staging model that ref()s a hub passes I5 (first-party)
        but FAILs I2 (only BKCC ref allowed in staging).

    Triggers on (each → FAIL):
      - source() resolving to a DB other than ``staging_source_db_default``
        (default PSA_PROD), unless the source is registered in
        ``legacy_sources_yaml`` AND resolves to one of ``staging_source_db_legacy``
      - source() referencing an undeclared source name
      - source() resolving to EDP_BRONZE_PROD but registered in a non-legacy YAML
      - ref() to any model other than ``ref_business_key_collision`` AND any
        names in ``staging_ref_exemptions`` from governance_allowlist.yml.

    Skipped (no finding):
      - non-staging files (path lacks ``int_staging_views/``)
      - source()/ref() inside /* */ blocks or after -- line comments
      - all matches when governance_allowlist.yml is missing AND no sources
        are registered — fail-open for fresh-clone / test fixtures only.
        In production (allowlist present, OR any *sources*.yml registered),
        the check runs; if the allowlist is the missing signal, the staging
        discipline config falls back to defaults from
        ``load_staging_discipline_config()`` (PSA_PROD), which keeps the
        check enforcing rather than turning into a silent no-op.
      - ref() to ``ref_business_key_collision`` (BKCC, hardcoded exemption)
      - ref() to any model in ``staging_ref_exemptions`` (config-driven
        named exemptions — NOT wildcards; each entry exact-match)

    Architecture: CONTENT-ONLY, same contract as the other checks. Uses the
    memoized 3-tuple source resolver (database, schema, yaml_basename) to
    determine each source's registration YAML in O(1) per source().
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []
    if repo_root is None:
        repo_root = _PROJECT_ROOT

    cfg = load_staging_discipline_config(repo_root)
    source_map = load_source_resolver(repo_root)
    default_db = cfg["default_db"]
    legacy_dbs = set(cfg["legacy_dbs"])
    legacy_yaml = cfg["legacy_yaml"]
    # Combine the hardcoded BKCC exemption with the config-driven named
    # exemptions. Set-based comparison for O(1) lookups. All names lowercased
    # (cfg loader normalizes); BKCC constant is already lowercase.
    permitted_refs = {_I2_BKCC_REF_NAME, *cfg["ref_exemptions"]}

    # Fail open if governance config is missing AND no sources are registered
    # (likely a test/fresh-clone scenario where staging discipline isn't yet
    # configured). The check still runs when EITHER signal is present.
    allowlist_path = Path(repo_root) / "governance_allowlist.yml"
    if not allowlist_path.exists() and not source_map:
        return []

    findings: list[Finding] = []

    # --- source() resolution ---
    for m in _I2_STAGING_SOURCE_RE.finditer(sql_content):
        if _i2_is_in_comment(sql_content, m.start()):
            continue
        src_name = m.group(1).lower()
        tbl_name = m.group(2).lower()
        line_num = sql_content[: m.start()].count("\n") + 1
        key = (src_name, tbl_name)

        if key not in source_map:
            findings.append(Finding(
                check_id="I2",
                check_name="staging_source_discipline",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message=(
                    f"Staging source '{src_name}.{tbl_name}' is undeclared — "
                    f"not found in any models/**/*sources*.yml. Staging models "
                    f"must source() from a registered source."
                ),
                suggestion=(
                    f"Declare table '{tbl_name}' under source '{src_name}' "
                    f"in a _sources*.yml, OR fix the source() reference."
                ),
            ))
            continue

        database, _schema, yaml_basename = source_map[key]
        db_norm = normalize_database(database)
        is_legacy_registered = yaml_basename == legacy_yaml
        permitted = legacy_dbs if is_legacy_registered else {default_db}

        if db_norm in permitted:
            continue

        # Distinguish two failure shapes for actionable error messages:
        # (a) DB allowed for legacy sources only, but this source is new.
        # (b) DB outright forbidden (e.g. BI_SANDBOX).
        if db_norm in legacy_dbs and not is_legacy_registered:
            msg = (
                f"Staging source '{src_name}.{tbl_name}' resolves to {db_norm} "
                f"but is not registered in {legacy_yaml} — {db_norm} is only "
                f"permitted for legacy sources. New staging sources must "
                f"source() from {default_db}."
            )
            sugg = (
                f"Re-land the source in {default_db} (the PSA convention) and "
                f"reference that, OR add the source to {legacy_yaml} if it "
                f"genuinely predates the PSA-only rule."
            )
        else:
            legacy_clause = (
                f" (or {', '.join(sorted(legacy_dbs - {default_db}))} for "
                f"legacy sources registered in {legacy_yaml})"
                if legacy_dbs - {default_db} else ""
            )
            msg = (
                f"Staging source '{src_name}.{tbl_name}' resolves to {db_norm} "
                f"— staging may only source() from {default_db}{legacy_clause}."
            )
            sugg = (
                f"Land the data in {default_db} via Fivetran/SNP GLUE/etc. "
                f"first, then source() from PSA in staging."
            )
        findings.append(Finding(
            check_id="I2",
            check_name="staging_source_discipline",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message=msg,
            suggestion=sugg,
        ))

    # --- ref() in staging (BKCC + named exemptions permitted) ---
    for m in _I2_ANY_REF_RE.finditer(sql_content):
        if _i2_is_in_comment(sql_content, m.start()):
            continue
        # The model name is the LAST argument: group(2) for two-arg
        # `ref('project','model')`, group(1) for single-arg `ref('model')`.
        # Picking group(1) unconditionally would compare the project name
        # against the exemption list — both the error message AND the
        # exemption match would name the wrong thing.
        ref_name = (m.group(2) or m.group(1)).lower()
        if ref_name in permitted_refs:
            continue  # BKCC or a config-declared named exemption
        line_num = sql_content[: m.start()].count("\n") + 1
        # Build the "allowed refs" hint for the error message. BKCC always
        # included; named exemptions listed if configured.
        other_exempt = sorted(set(cfg["ref_exemptions"]))
        exempt_clause = (
            f" or one of the configured staging_ref_exemptions "
            f"({', '.join(other_exempt)})"
            if other_exempt else ""
        )
        findings.append(Finding(
            check_id="I2",
            check_name="staging_source_discipline",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message=(
                f"Staging must read raw data via source(); ref('{ref_name}') "
                f"is not permitted in staging except "
                f"ref('{_I2_BKCC_REF_NAME}'){exempt_clause}."
            ),
            suggestion=(
                f"Replace with source('<src>','<table>') against PSA, OR move "
                f"this logic to a downstream layer (raw vault / bus vault) "
                f"where ref() is appropriate. If this is a shared reference "
                f"model used across many staging models, add it to "
                f"`staging_ref_exemptions` in governance_allowlist.yml."
            ),
        ))

    # Apply burn-down-only grandfather downgrade to pre-existing debt entries.
    # See scripts/automation/.code_review_grandfather for the frozen list.
    grandfather = load_grandfather_list(repo_root)
    return [_apply_grandfather(f, grandfather) for f in findings]


def check_non_staging_uses_ref_only(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
    repo_root: Path | None = None,
) -> list[Finding]:
    """I4: Downstream layers (raw_vault, bus_vault, info_mart) must use ref()
    only — any source() bypasses the staging layer and FAILs.

    Companion to I2 (which enforces source-only discipline in staging). The
    two together form a complete layer-direction rule:
        staging:     source() only (+ BKCC ref exemption)  ← I2
        downstream:  ref() only                             ← I4

    Triggers on:
      - Any ``{{ source('x', 'y') }}`` in a file whose path contains
        ``raw_vault/``, ``bus_vault/``, or ``info_mart/`` — FAIL per occurrence

    Skipped (no finding):
      - non-downstream files
      - source() inside /* */ blocks or after -- line comments
      - findings capped at 5 per file to avoid review noise on bulk violations

    Permanent code-level exemption (NOT a grandfathered debt entry):
      - ``ref_business_key_collision.sql`` is the BKCC source-of-truth and
        legitimately MUST use ``source()`` to ingest raw BKCC registrations.
        This is correct-by-design and not eligible for the grandfather list —
        any future reorganization of the BKCC model preserves this exemption.

    Burn-down-only grandfather list:
      - Pre-existing debt enumerated in ``.code_review_grandfather`` is
        downgraded FAIL → WARN with a ``[GRANDFATHERED]`` prefix. New
        violations (file NOT on the list) FAIL normally.

    Pure content check — ``repo_root`` only consulted to load the
    grandfather list; if omitted, defaults to ``_PROJECT_ROOT``.
    """
    if not file_path.endswith(".sql"):
        return []
    if not any(seg in file_path for seg in (
        "raw_vault/", "bus_vault/", "info_mart/"
    )):
        return []

    # Permanent code-level exemption: BKCC reference table is the
    # source-of-truth for business-key collision codes. It MUST read from
    # raw data; ref() would be circular. Match basename only so directory
    # reorganization doesn't break the exemption.
    if Path(file_path).name == "ref_business_key_collision.sql":
        return []

    layer_label = (
        "raw vault" if "raw_vault/" in file_path
        else "bus vault" if "bus_vault/" in file_path
        else "info mart"
    )

    findings: list[Finding] = []
    for m in _I4_SOURCE_RE.finditer(sql_content):
        if _i2_is_in_comment(sql_content, m.start()):
            continue
        src_name = m.group(1).lower()
        tbl_name = m.group(2).lower()
        line_num = sql_content[: m.start()].count("\n") + 1
        findings.append(Finding(
            check_id="I4",
            check_name="non_staging_uses_ref_only",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message=(
                f"{layer_label} model uses source('{src_name}','{tbl_name}') "
                f"— only staging may use source(); downstream layers must use "
                f"ref() to a staging or upstream model."
            ),
            suggestion=(
                f"Replace with ref('v_psa_stg_<...>') or ref('<upstream_dv_model>'). "
                f"If raw data is needed and not yet in staging, create the "
                f"v_psa_stg model first."
            ),
        ))
        if len(findings) >= 5:
            break  # cap noise on bulk violations

    if not findings:
        return findings
    if repo_root is None:
        repo_root = _PROJECT_ROOT
    # Apply burn-down-only grandfather downgrade to pre-existing debt entries.
    grandfather = load_grandfather_list(repo_root)
    return [_apply_grandfather(f, grandfather) for f in findings]


# ═══════════════════════════════════════════════════════════════════════════════
# 11. CATEGORY J — INCREMENTAL MODEL CONFIG
# ═══════════════════════════════════════════════════════════════════════════════


def check_where_not_exists_uses_hashdiff(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """J1: Satellite WHERE NOT EXISTS must compare on HK AND HASHDIFF.

    Enforces: DV incremental load standard
    Triggers on: WHERE NOT EXISTS (SELECT 1 FROM existing WHERE existing.HK = new.HK) — misses HASHDIFF
    Correct: WHERE NOT EXISTS (... WHERE existing.HK = new.HK AND existing.HASHDIFF = new.HASHDIFF)
    """
    if not file_path.endswith(".sql"):
        return []
    if "raw_vault/sat/" not in file_path:
        return []

    # Find WHERE NOT EXISTS blocks
    findings = []
    for m in re.finditer(r'WHERE\s+NOT\s+EXISTS\s*\(', sql_content, re.IGNORECASE):
        # Get the block after WHERE NOT EXISTS
        block_start = m.end()
        # Find closing paren (simple approach — get next 500 chars)
        block = sql_content[block_start:block_start + 500]
        has_hk = re.search(r'_HK\s*=', block, re.IGNORECASE)
        has_hashdiff = re.search(r'HASHDIFF\s*=', block, re.IGNORECASE)

        if has_hk and not has_hashdiff:
            line_num = sql_content[:m.start()].count("\n") + 1
            findings.append(Finding(
                check_id="J1",
                check_name="where_not_exists_uses_hashdiff",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message="Satellite WHERE NOT EXISTS must compare on HK AND HASHDIFF, not just HK",
                suggestion="Add: AND existing.HASHDIFF = new.HASHDIFF",
            ))
    return findings


def check_hub_where_not_exists_hk_only(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """J2: Hub WHERE NOT EXISTS should compare on HK only (no HASHDIFF — hubs have none).

    Enforces: DV hub incremental standard
    Triggers on: AND existing.HASHDIFF = ... in a hub model
    Correct: WHERE NOT EXISTS (SELECT 1 FROM existing WHERE existing.HK = new.HK)
    """
    if not file_path.endswith(".sql"):
        return []
    if "raw_vault/hub/" not in file_path:
        return []

    findings = []
    for m in re.finditer(r'WHERE\s+NOT\s+EXISTS\s*\(', sql_content, re.IGNORECASE):
        block = sql_content[m.end():m.end() + 500]
        if re.search(r'HASHDIFF', block, re.IGNORECASE):
            line_num = sql_content[:m.start()].count("\n") + 1
            findings.append(Finding(
                check_id="J2",
                check_name="hub_where_not_exists_hk_only",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=line_num,
                message="Hub WHERE NOT EXISTS should compare HK only — hubs have no HASHDIFF",
                suggestion="Remove HASHDIFF comparison from WHERE NOT EXISTS in hub model",
            ))
    return findings


def check_watermark_scoped_per_rec_src(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """J5: Incremental watermark must be scoped per REC_SRC with GROUP BY REC_SRC.

    Enforces: DV 2.1 courseware §7 — per-REC_SRC watermark
    Triggers on: WHERE SRC.LOAD_DTS > (SELECT MAX(LOAD_DTS) FROM {{this}}) — global watermark
    Correct: INCR_WATERMARK AS (SELECT REC_SRC, DATEADD(DAY, -1, MAX(LOAD_DTS)) FROM {{this}} GROUP BY REC_SRC)

    Applied to new files as FAIL, modified files as WARN.
    Scoped to hubs and links only — satellites are single-source (one REC_SRC)
    by DV 2.0/2.1 standard, so a global watermark is functionally correct.
    V11 (303 sat pre-existing violations) was invalidated as a false positive.
    """
    if not file_path.endswith(".sql"):
        return []
    if "raw_vault/" not in file_path:
        return []

    # Satellites are single-source (one REC_SRC) — global watermark is safe.
    # Only hubs and links can have multiple sources feeding the same table.
    fname = file_path.rsplit("/", 1)[-1]
    if fname.startswith(("sat_", "msat_", "lsat_", "esat_", "lmsat_", "rsat_")):
        return []

    # Check for incremental marker
    if "{{this}}" not in sql_content and "{{ this }}" not in sql_content:
        return []

    # Check for global watermark pattern (MAX(LOAD_DTS) without GROUP BY REC_SRC)
    has_max_load_dts = re.search(r'MAX\s*\(\s*LOAD_DTS\s*\)', sql_content, re.IGNORECASE)
    if not has_max_load_dts:
        return []

    has_group_by_rec_src = re.search(r'GROUP\s+BY\s+REC_SRC', sql_content, re.IGNORECASE)
    if has_group_by_rec_src:
        return []

    severity = Severity.FAIL if file_status == FileStatus.NEW else Severity.WARN
    line_num = sql_content[:has_max_load_dts.start()].count("\n") + 1

    return [Finding(
        check_id="J5",
        check_name="watermark_scoped_per_rec_src",
        severity=severity,
        file_path=file_path,
        line_number=line_num,
        message="Incremental watermark must be scoped per REC_SRC (GROUP BY REC_SRC) — global MAX(LOAD_DTS) is unreliable",
        suggestion="Use: INCR_WATERMARK AS (SELECT REC_SRC, DATEADD(DAY, -1, MAX(LOAD_DTS)) FROM {{this}} GROUP BY REC_SRC)",
    )]


def check_sat_delete_scoped_watermark(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """J6: SNP GLUE SAT LOAD_DTS watermark must be delete-scoped + floored when GLCHANGETIME + PSA_DELETE_IND are present.

    Two-clock hazard (SNP GLUE): LOAD_DTS is event time for live rows but batch
    time (PSA_LOAD_DTS) for soft-deletes, so delete rows inflate max(load_dts)
    and silently exclude later live records from the incremental window. When a
    satellite materialises PSA_DELETE_IND and filters on max(load_dts), the
    watermark subquery MUST:
      (1) scope to live rows -- COALESCE(PSA_DELETE_IND,'N') = 'N', and
      (2) floor the result -- COALESCE(DATEADD(...MAX(LOAD_DTS)...), '1900-01-01')
          so an all-deleted / cold table cannot return NULL (which filters
          everything -> a zero-row incremental load).

    Applies to satellites only. This is the complement of J5 (which exempts
    satellites from the per-REC_SRC rule) -- a different, delete-scoping rule.
    Gated on the SNP GLUE fingerprint GLCHANGETIME (the SAT-visible proxy for the
    mixed-clock LOAD_DTS derivation): Fivetran / default sources are single-clock
    even when they materialise PSA_DELETE_IND, so they are correctly not flagged.
    No-op when there is no LOAD_DTS watermark (full-scan SATs are unaffected).
    FAIL on new files, WARN on modified.
    """
    if not file_path.endswith(".sql"):
        return []
    if "raw_vault/" not in file_path:
        return []
    fname = file_path.rsplit("/", 1)[-1]
    if not fname.startswith(("sat_", "msat_", "lsat_", "esat_", "lmsat_", "rsat_")):
        return []

    # The two-clock hazard lives in the upstream LOAD_DTS derivation, which this
    # SAT file does not contain (it SELECTs *). GLCHANGETIME is the SNP GLUE
    # fingerprint column and the SAT-visible proxy for that mixed-clock derivation.
    # Fivetran / default sources are single-clock even when they materialise
    # PSA_DELETE_IND, so gate on GLCHANGETIME to avoid false positives. (A custom-
    # LOAD_DTS two-clock SAT without GLCHANGETIME is not enforced here -- rare, and
    # this is a WARN-level net, not the generator.)
    if not re.search(r"\bGLCHANGETIME\b", sql_content, re.IGNORECASE):
        return []
    if not re.search(r"\bPSA_DELETE_IND\b", sql_content, re.IGNORECASE):
        return []

    findings: list[Finding] = []
    # Inspect EVERY LOAD_DTS watermark region (multi-source SATs have several).
    # Match both `>` and `>=`; each region runs from src.load_dts to its endif.
    for wm in re.finditer(
        r"src\.load_dts\s*>=?\s*\(.*?{%\s*endif\s*%}",
        sql_content, re.IGNORECASE | re.DOTALL,
    ):
        region = wm.group(0)
        # Scope must filter to LIVE rows specifically (= 'N'); an inverted = 'Y' or a
        # bare column mention is not a pass.
        has_scope = bool(re.search(
            r"coalesce\s*\(\s*PSA_DELETE_IND\s*,\s*'N'\s*\)\s*=\s*'N'"
            r"|PSA_DELETE_IND\s*=\s*'N'",
            region, re.IGNORECASE,
        ))
        # Floor must be the '1900-01-01' sentinel specifically -- a COALESCE that
        # defaults DATEADD(...) to some other value (or a non-flooring COALESCE) is
        # not the loss-safe floor the convention requires (#1929).
        has_floor = bool(
            re.search(r"coalesce\s*\(\s*dateadd", region, re.IGNORECASE)
        ) and "1900-01-01" in region
        if has_scope and has_floor:
            continue
        missing = []
        if not has_scope:
            missing.append("live-row scope (COALESCE(PSA_DELETE_IND,'N')='N')")
        if not has_floor:
            missing.append("COALESCE floor (COALESCE(DATEADD(...MAX(LOAD_DTS)...),'1900-01-01'))")
        severity = Severity.FAIL if file_status == FileStatus.NEW else Severity.WARN
        line_num = sql_content[:wm.start()].count("\n") + 1
        findings.append(Finding(
            check_id="J6",
            check_name="sat_delete_scoped_watermark",
            severity=severity,
            file_path=file_path,
            line_number=line_num,
            message=(
                "SNP GLUE SAT (GLCHANGETIME + PSA_DELETE_IND) has a LOAD_DTS watermark missing "
                + " and ".join(missing)
                + " -- soft-deletes inflate max(load_dts) and silently exclude live records"
            ),
            suggestion=(
                "where src.load_dts > (select coalesce(dateadd('HOUR',-1,max(load_dts)), "
                "'1900-01-01'::timestamp) from {{ this }} where coalesce(PSA_DELETE_IND,'N') = 'N')"
            ),
        ))
    return findings


# ═══════════════════════════════════════════════════════════════════════════════
# 12. CATEGORY K — GHOST RECORD STANDARDS
# ═══════════════════════════════════════════════════════════════════════════════


def _has_ghost_record(sql_content: str) -> bool:
    """Check if file contains a ghost record section."""
    return bool(re.search(r'strtok_split_to_table|GHOST\s+RECORD', sql_content, re.IGNORECASE))


def check_ghost_record_decode_pattern(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """K1: Ghost record BKCC pattern (fires only when model contains BKCC column).

    Enforces: FBIN ghost record standard
    Triggers on: Custom ghost BKCC strings in models that have BKCC
    Skips: Satellites without BKCC (137/379 sats legitimately omit it)
    Correct: DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required',
             -2, 'GHOST RECORD-nullkey-optional') AS BKCC
    """
    if not file_path.endswith(".sql"):
        return []
    if "raw_vault/" not in file_path:
        return []
    # Links do NOT have BKCC — skip this check for link tables
    if "raw_vault/link/" in file_path:
        return []
    if not _has_ghost_record(sql_content):
        return []
    # Some satellites don't have BKCC — only check models that actually use it
    if not re.search(r'\bBKCC\b', sql_content):
        return []

    # Check for the standard DECODE pattern
    if re.search(r"DECODE\s*\(\s*GR\.VALUE", sql_content, re.IGNORECASE):
        # Verify all three GHOST RECORD strings
        has_system = "GHOST RECORD-SYSTEM" in sql_content or "GHOST RECORD-system" in sql_content
        has_required = "GHOST RECORD-nullkey-required" in sql_content
        has_optional = "GHOST RECORD-nullkey-optional" in sql_content
        if has_system and has_required and has_optional:
            return []

    line_num = 1
    m = re.search(r'GHOST|strtok_split_to_table', sql_content, re.IGNORECASE)
    if m:
        line_num = sql_content[:m.start()].count("\n") + 1

    return [Finding(
        check_id="K1",
        check_name="ghost_record_decode_pattern",
        severity=Severity.FAIL,
        file_path=file_path,
        line_number=line_num,
        message="Ghost record BKCC must use DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, '...required', -2, '...optional')",
        suggestion="Use: DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC",
    )]


def check_ghost_record_three_sentinels(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """K2: Ghost records must include all three sentinel values (0, -1, -2).

    Enforces: FBIN ghost record standard
    Triggers on: Only sentinel 0 (SYSTEM) present
    Correct: strtok_split_to_table('0|-1|-2', '|')
    """
    if not file_path.endswith(".sql"):
        return []
    if "raw_vault/" not in file_path:
        return []
    if not _has_ghost_record(sql_content):
        return []

    if re.search(r"'0\|-1\|-2'", sql_content):
        return []

    line_num = 1
    m = re.search(r'strtok_split_to_table', sql_content, re.IGNORECASE)
    if m:
        line_num = sql_content[:m.start()].count("\n") + 1

    return [Finding(
        check_id="K2",
        check_name="ghost_record_three_sentinels",
        severity=Severity.FAIL,
        file_path=file_path,
        line_number=line_num,
        message="Ghost records must include all three sentinels (0, -1, -2)",
        suggestion="Use: strtok_split_to_table('0|-1|-2', '|')",
    )]


def check_ghost_record_hk_formula(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """K5: Ghost record HK must use MD5_BINARY(GR.VALUE) — not a binary literal.

    Enforces: FBIN ghost record standard
    Triggers on: x'0000000000000000' AS HK
    Correct: MD5_BINARY(GR.VALUE) AS INSTALLATION_HK
    """
    if not file_path.endswith(".sql"):
        return []
    if "raw_vault/" not in file_path:
        return []
    if not _has_ghost_record(sql_content):
        return []

    if re.search(r"MD5_BINARY\s*\(\s*GR\.VALUE\s*\)", sql_content, re.IGNORECASE):
        return []

    # Check for binary literal ghost HK
    if re.search(r"x'[0-9a-fA-F]+'", sql_content):
        line_num = 1
        m = re.search(r"x'[0-9a-fA-F]+'", sql_content)
        if m:
            line_num = sql_content[:m.start()].count("\n") + 1
        return [Finding(
            check_id="K5",
            check_name="ghost_record_hk_formula",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message="Ghost record HK must use MD5_BINARY(GR.VALUE), not a binary literal",
            suggestion="Use: MD5_BINARY(GR.VALUE) AS <entity>_HK",
        )]

    return []


# K6 — Ghost record keys must be populated (sibling to K5)
#
# K5 catches WRONG HK formulas (binary literals). It does NOT catch the
# adjacent failure mode where the author forgot the GHOST RECORD directive
# entirely on an _HK or hub _BK column and the generator (or hand-edit)
# emitted `NULL AS <col>` into the ghost row.
#
# The generator's defensive sweep (build.py::generate_union_all_block) now
# self-heals this case in NEW generation — it substitutes MD5_BINARY(GR.VALUE)
# for _HK and GR.VALUE::text|number for hub _BK when the directive is blank,
# so output is never broken. But "defensive sweep + warning" alone is not
# enough — warnings get ignored, and the underlying authoring gap (missing
# GHOST RECORD directive in the XLSX) persists. This reviewer check FAILs
# loudly so the gap gets fixed at source.
#
# Belt-and-suspenders contract:
#   - Generator self-heals so nothing broken ships downstream.
#   - Reviewer FAILs so authoring gaps are surfaced and corrected.
#
# Scope: hub/link models (per Kumar's instruction). Hub checks _HK and _BK;
# link checks _HK only (links have no BK). Sat HK is covered by the same
# generator self-heal but is NOT added to this reviewer check by design —
# sat ghost row patterns are more varied (multiple parent HKs, msat keys,
# rsat reference keys) and a stricter sat HK reviewer rule would need a
# separate spec round.

_GHOST_BLOCK_RE = re.compile(
    r"union\s+all\s+SELECT\s+(?P<body>.*?)\s+FROM\s+TABLE\s*\(\s*strtok_split_to_table",
    re.IGNORECASE | re.DOTALL,
)

# Match a `NULL AS <col>` segment. Anchored on word boundary to avoid hitting
# substrings inside larger expressions; the AS keyword is required (we are
# not matching bare NULLs).
_NULL_AS_COL_RE = re.compile(
    r"\bNULL\s+AS\s+([A-Z_][A-Z0-9_]*)\b",
    re.IGNORECASE,
)


def check_ghost_record_keys_not_null(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """K6: Ghost record _HK and hub _BK columns must NOT be NULL.

    A NULL HK in the ghost row breaks every FK join from child tables to the
    ghost parent (the join would have to match NULL = NULL, which never does
    in standard SQL). A NULL BK on a hub ghost row leaks NULL into anything
    that surfaces the business key downstream.

    Enforces: FBIN ghost record standard (companion to K5)
    Triggers on: `NULL AS <col>_HK` or (hub only) `NULL AS <col>_BK` inside
                 the `union all ... FROM TABLE(strtok_split_to_table(...))`
                 block.
    Correct:     `MD5_BINARY(GR.VALUE) AS <col>_HK` /
                 `GR.VALUE::text AS <col>_BK` (or `::number` for numeric BK)

    Scope: hub/link models only (`raw_vault/hub/`, `raw_vault/link/`).
    Sat HK is left to the generator's self-heal alone for now — see module
    note above for rationale.
    """
    if not file_path.endswith(".sql"):
        return []
    normalized = file_path.replace("\\", "/")
    is_hub = "raw_vault/hub/" in normalized
    is_link = "raw_vault/link/" in normalized
    if not (is_hub or is_link):
        return []
    if not _has_ghost_record(sql_content):
        return []

    findings: list[Finding] = []
    for ghost_match in _GHOST_BLOCK_RE.finditer(sql_content):
        body = ghost_match.group("body")
        body_start = ghost_match.start("body")
        for m in _NULL_AS_COL_RE.finditer(body):
            col_name = m.group(1).upper()
            abs_offset = body_start + m.start()
            line_num = sql_content[:abs_offset].count("\n") + 1

            is_hk = col_name.endswith("_HK")
            is_bk = col_name.endswith("_BK") and is_hub  # links have no BK

            if not (is_hk or is_bk):
                continue

            key_kind = "HK" if is_hk else "BK"
            if is_hk:
                correct = "MD5_BINARY(GR.VALUE)"
                directive = "hash"
            else:
                correct = "GR.VALUE::text (or ::number for numeric BK)"
                directive = "value_text (or value_number for numeric BK)"

            findings.append(Finding(
                check_id="K6",
                check_name="ghost_record_keys_not_null",
                severity=Severity.FAIL,
                file_path=file_path,
                line_number=line_num,
                message=(
                    f"Ghost row emits `NULL AS {col_name}` for a {key_kind} column. "
                    f"A NULL {key_kind} on a ghost row breaks FK joins to the ghost parent. "
                    "The author forgot the GHOST RECORD directive on this column "
                    "(the generator's defensive sweep would have substituted the correct "
                    "expression — this file was either hand-edited or generated from a spec "
                    "missing the directive)."
                ),
                suggestion=(
                    f"Set GHOST RECORD='{directive}' in the XLSX so the generator emits "
                    f"`{correct} AS {col_name}` in the ghost row; or fix the SQL directly "
                    f"to that expression."
                ),
            ))

    return findings


# ═══════════════════════════════════════════════════════════════════════════════
# 13. CATEGORY L — JOIN PATTERNS
# ═══════════════════════════════════════════════════════════════════════════════


def check_inner_join_has_comment(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """L1: Non-BKCC INNER JOIN should have an inline comment explaining why.

    Enforces: Lesson #9
    Triggers on: INNER JOIN dim_product ON ... — no explanation
    Correct: INNER JOIN dim_product ON ... -- required: 1:1 match guaranteed

    Scoped to: int_staging_views/, raw_vault/ only.
    Bus vault PB/PIT models legitimately use many INNER JOINs as standard pattern.
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path and "raw_vault/" not in file_path:
        return []

    findings = []
    for m in re.finditer(r'\bINNER\s+JOIN\b', sql_content, re.IGNORECASE):
        # Get rest of line
        line_end = sql_content.find("\n", m.end())
        if line_end == -1:
            line_end = len(sql_content)
        rest_of_line = sql_content[m.end():line_end]

        # Skip BKCC joins (ON '1' = '1')
        if "'1'" in rest_of_line:
            continue
        # Check the next line too for multi-line joins
        next_line_end = sql_content.find("\n", line_end + 1)
        if next_line_end == -1:
            next_line_end = len(sql_content)
        next_line = sql_content[line_end:next_line_end]
        if "'1'" in next_line:
            continue

        # Check for inline comment on this line or next
        if "--" not in rest_of_line and "--" not in next_line:
            line_num = sql_content[:m.start()].count("\n") + 1
            findings.append(Finding(
                check_id="L1",
                check_name="inner_join_has_comment",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=line_num,
                message="Non-BKCC INNER JOIN should have an inline comment explaining why",
                suggestion="Add: -- reason for INNER JOIN (e.g., '1:1 match guaranteed')",
            ))
    return findings


# ═══════════════════════════════════════════════════════════════════════════════
# 14. CATEGORY M — MISCELLANEOUS STANDARDS
# ═══════════════════════════════════════════════════════════════════════════════

_HARDCODED_ENV_RE = re.compile(
    r"'(DEV|QA|PRD|PROD|DEVELOPMENT|PRODUCTION)'",
    re.IGNORECASE,
)


def check_no_hardcoded_env(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """M1: No hardcoded environment names ('DEV', 'QA', 'PRD') — use env_var() or Jinja.

    Enforces: Environment portability
    Triggers on: WHERE environment = 'PRD'
    Correct: {{ env_var('DBT_ENVIRON') }}
    """
    if not file_path.endswith(".sql"):
        return []

    findings = []
    for m in _HARDCODED_ENV_RE.finditer(sql_content):
        # Skip if inside a comment
        prefix = sql_content[:m.start()]
        last_open = prefix.rfind("/*")
        last_close = prefix.rfind("*/")
        if last_open > last_close:
            continue
        line_start = prefix.rfind("\n") + 1
        line_prefix = prefix[line_start:]
        if "--" in line_prefix:
            continue
        # Skip if inside ghost record BKCC (e.g., DECODE value strings)
        if "GHOST RECORD" in sql_content[max(0, m.start() - 50):m.end() + 50]:
            continue

        line_num = prefix.count("\n") + 1
        findings.append(Finding(
            check_id="M1",
            check_name="no_hardcoded_env",
            severity=Severity.FAIL,
            file_path=file_path,
            line_number=line_num,
            message=f"Hardcoded environment name '{m.group(1)}' — use env_var() or Jinja variable",
            suggestion="Use: {{ env_var('DBT_ENVIRON') }} or {{ var('environment') }}",
        ))
    return findings


def check_no_select_star_outside_src(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """M2: SELECT * should only appear in SRC CTEs and passthrough RENAME/FILTER CTEs.

    Enforces: Lesson #3, #15
    Triggers on: SELECT * FROM hub_customer in a business vault model
    Correct: SELECT * only in SRC_S, SRC_A, RENAME_*, FILTER_* CTEs

    Note: In 6-layer pattern RENAME/FILTER use SELECT * as passthroughs — allowed.

    Scoped to: int_staging_views/ only.
    Hub/link/sat models don't have SRC CTEs. Bus vault uses SELECT * by design.
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    findings = []
    for m in re.finditer(r'\bSELECT\s+\*', sql_content, re.IGNORECASE):
        # Get context — which CTE is this SELECT * inside?
        prefix = sql_content[:m.start()]

        # Skip if inside a comment
        last_open = prefix.rfind("/*")
        last_close = prefix.rfind("*/")
        if last_open > last_close:
            continue
        line_start = prefix.rfind("\n") + 1
        line_prefix = prefix[line_start:]
        if "--" in line_prefix:
            continue

        # Find the nearest CTE name before this SELECT *
        cte_matches = list(_CTE_NAME_RE.finditer(prefix))
        if cte_matches:
            cte_name = cte_matches[-1].group(1).upper()
            # Allow SELECT * in SRC, RENAME, FILTER CTEs
            if any(cte_name.startswith(p) for p in ("SRC_", "RENAME_", "FILTER_")):
                continue
            # Allow in JOIN_RESULT (some legacy models)
            if cte_name == "JOIN_RESULT":
                continue

        # If we're in the final SELECT (after all CTEs), check file type
        # Bus vault dim/fact models are expected to be simple wrappers
        basename = file_path.rsplit("/", 1)[-1] if "/" in file_path else file_path
        if basename.startswith(("dim_", "fact_")):
            continue  # dim/fact are 1:1 wrappers — SELECT * is acceptable

        line_num = prefix.count("\n") + 1
        findings.append(Finding(
            check_id="M2",
            check_name="no_select_star_outside_src",
            severity=Severity.WARN,
            file_path=file_path,
            line_number=line_num,
            message="SELECT * should only appear in SRC/RENAME/FILTER CTEs, not in LOGIC or final SELECT",
            suggestion="Replace SELECT * with explicit column list",
        ))
    return findings


def check_rec_src_format(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """M3: REC_SRC should follow Location.System.Application.Table format (4 dot-separated parts).

    Enforces: FBIN REC_SRC format standard
    Triggers on: 'SAP' AS REC_SRC — too short
    Correct: 'USOHNO.SAP.ECCPRD.Z_LFA1' AS REC_SRC
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    findings = []
    for m in re.finditer(r"'([^']+)'\s+[Aa][Ss]\s+REC_SRC\b", sql_content):
        rec_src = m.group(1)
        parts = rec_src.split(".")
        if len(parts) < 4:
            line_num = sql_content[:m.start()].count("\n") + 1
            findings.append(Finding(
                check_id="M3",
                check_name="rec_src_format",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=line_num,
                message=f"REC_SRC '{rec_src}' should follow Location.System.Application.Table format (4 parts)",
                suggestion="Use: 'LOCATION.SYSTEM.APPLICATION.TABLE' AS REC_SRC",
            ))
    return findings


def check_header_comment_present(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """M4: SQL files should have a header comment (---- SRC LAYER ---- or equivalent).

    Enforces: Code documentation standard
    Triggers on: No comment at line 1
    Correct: ---- SRC LAYER ---- at top of file
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    first_line = sql_content.split("\n", 1)[0].strip()
    if first_line.startswith("----") or first_line.startswith("--") or first_line.startswith("/*"):
        return []

    # Also accept {{ config(...) }} as first line
    if first_line.startswith("{{"):
        return []

    return [Finding(
        check_id="M4",
        check_name="header_comment_present",
        severity=Severity.WARN,
        file_path=file_path,
        line_number=1,
        message="SQL file should have a header comment (e.g., '---- SRC LAYER ----')",
        suggestion="Add: ---- SRC LAYER ---- as the first line",
    )]


def check_fix_proof_atomicity_prompt(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """M5: Prompt reviewer to confirm fix+proof atomicity on triage source edits.

    Enforces: Approved lesson "Fix+proof must ship atomically" (warn-level reviewer assist)
    Trigger: Any changed file under scripts/automation/src/triage/*.py
    Framing: confirm-question only (human conclusion), never violation assertion
    """
    if not file_path.endswith(".py"):
        return []
    if not file_path.startswith("scripts/automation/src/triage/"):
        return []

    return [Finding(
        check_id="M5",
        check_name="fix_proof_atomicity_prompt",
        severity=Severity.WARN,
        file_path=file_path,
        message=(
            "Confirm fix+proof atomicity for this change: is the proving test "
            "for this fix included in this commit?"
        ),
        suggestion=(
            "Add or update the proving test in the same commit when behavior "
            "changes in triage source code."
        ),
    )]


# ═══════════════════════════════════════════════════════════════════════════════
# 14b. CATEGORY N — STAGING DATA INTEGRITY (Lessons #28, #58)
# ═══════════════════════════════════════════════════════════════════════════════

# Regex to match WHERE clauses referencing delete flags
_DELETE_FLAG_WHERE_RE = re.compile(
    r'\bWHERE\b[^)]*?\b(_FIVETRAN_DELETED|PSA_DELETE_IND)\b',
    re.IGNORECASE | re.DOTALL,
)

# Regex for AND clauses referencing delete flags (WHERE ... AND _FIVETRAN_DELETED)
_DELETE_FLAG_AND_RE = re.compile(
    r'\bAND\b[^)]*?\b(_FIVETRAN_DELETED|PSA_DELETE_IND)\b',
    re.IGNORECASE | re.DOTALL,
)

# Structured exception marker for N1 downgrade:
#   -- DV-EXCEPTION: <non-empty reason>
# A bare '-- DV-EXCEPTION' (no colon) or '-- DV-EXCEPTION:' with no reason
# does NOT match (the \S+ requires at least one non-whitespace char after).
_DV_EXCEPTION_RE = re.compile(r"--\s*DV-EXCEPTION:\s*\S+", re.IGNORECASE)


def _has_documenting_comment(body: str, keyword_pos: int) -> bool:
    """Return True if a -- comment or recent /* */ block sits on the same line
    as ``keyword_pos``, the previous line, the next line, or a /* */ block
    closes within 2 lines above.

    Extracted from N3's original inline definition so N1's DV-EXCEPTION
    downgrade can mirror the same proximity rule. Semantics unchanged.
    """
    line_start = body.rfind("\n", 0, keyword_pos) + 1
    line_end = body.find("\n", keyword_pos)
    if line_end == -1:
        line_end = len(body)
    line_text = body[line_start:line_end]

    if "--" in line_text:
        return True

    next_line_end = body.find("\n", line_end + 1)
    if next_line_end == -1:
        next_line_end = len(body)
    if "--" in body[line_end:next_line_end]:
        return True

    prev_line_start = body.rfind("\n", 0, line_start - 1) + 1 if line_start > 0 else 0
    prev_line = body[prev_line_start:line_start]
    if "--" in prev_line:
        return True

    above_text = body[:keyword_pos]
    if "/*" in above_text:
        last_open = above_text.rfind("/*")
        last_close = above_text.rfind("*/")
        if last_close < last_open:
            return True  # keyword is inside an unclosed block comment
        lines_between = above_text[last_close:].count("\n")
        if lines_between <= 2:
            return True

    return False


def _has_dv_exception_marker(body: str, keyword_pos: int) -> bool:
    """Return True if a `-- DV-EXCEPTION: <reason>` marker sits on the same
    line as ``keyword_pos``, the previous line, or the next line.

    Mirrors ``_has_documenting_comment``'s proximity rule (same/prev/next
    line) but requires the specific structured marker — a bare `--` or
    `-- DV-EXCEPTION:` (no reason) does NOT match.
    """
    line_start = body.rfind("\n", 0, keyword_pos) + 1
    line_end = body.find("\n", keyword_pos)
    if line_end == -1:
        line_end = len(body)

    if _DV_EXCEPTION_RE.search(body[line_start:line_end]):
        return True

    next_line_end = body.find("\n", line_end + 1)
    if next_line_end == -1:
        next_line_end = len(body)
    if _DV_EXCEPTION_RE.search(body[line_end:next_line_end]):
        return True

    prev_line_start = body.rfind("\n", 0, line_start - 1) + 1 if line_start > 0 else 0
    if _DV_EXCEPTION_RE.search(body[prev_line_start:line_start]):
        return True

    return False


def check_no_delete_flag_filter(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """N1: NEVER filter on _FIVETRAN_DELETED or PSA_DELETE_IND at the staging layer.

    Enforces: Lesson #28
    Triggers on: WHERE PSA_DELETE_IND = 'N' or WHERE ... AND _FIVETRAN_DELETED = FALSE
    Correct pattern: These columns are DATA — include in HASHDIFF, never filter on them.

    Structured-exception downgrade (FAIL → WARN):
      If the matched filter line, the line immediately above, or the line
      immediately below contains ``-- DV-EXCEPTION: <reason>`` (with a
      non-empty reason), the finding is downgraded to WARN. A bare ``--``
      or ``-- DV-EXCEPTION`` (no colon) or ``-- DV-EXCEPTION:`` (no reason)
      does NOT downgrade.
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []  # Only staging views — bus_vault CAN legitimately filter

    findings = []
    for pattern in (_DELETE_FLAG_WHERE_RE, _DELETE_FLAG_AND_RE):
        for m in pattern.finditer(sql_content):
            flag_col = m.group(1)
            # Skip if inside a SQL comment
            prefix = sql_content[:m.start()]
            last_open = prefix.rfind("/*")
            last_close = prefix.rfind("*/")
            if last_open > last_close:
                continue
            line_start = prefix.rfind("\n") + 1
            line_prefix = prefix[line_start:]
            if "--" in line_prefix:
                continue

            line_num = prefix.count("\n") + 1
            has_exception = _has_dv_exception_marker(sql_content, m.start())
            if has_exception:
                findings.append(Finding(
                    check_id="N1",
                    check_name="no_delete_flag_filter",
                    severity=Severity.WARN,
                    file_path=file_path,
                    line_number=line_num,
                    message=(
                        f"Staging filters on '{flag_col}' — permitted only "
                        f"with a documented DV-EXCEPTION reason. Verify "
                        f"deleted records are preserved in history."
                    ),
                    suggestion=(
                        f"Confirm '{flag_col}' is still captured in HASHDIFF "
                        f"so deleted-row history isn't lost."
                    ),
                ))
            else:
                findings.append(Finding(
                    check_id="N1",
                    check_name="no_delete_flag_filter",
                    severity=Severity.FAIL,
                    file_path=file_path,
                    line_number=line_num,
                    message=(
                        f"WHERE clause filters on '{flag_col}' — delete flags "
                        f"are DATA, not filter criteria at the staging layer"
                    ),
                    suggestion=(
                        f"Remove {flag_col} from WHERE clause and include it "
                        f"in HASHDIFF instead. If the filter is intentional "
                        f"(e.g., truncate-reload artifact), add an inline "
                        f"`-- DV-EXCEPTION: <reason>` comment to downgrade to WARN."
                    ),
                ))
    return findings


def check_coalesce_on_payload_in_staging(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """N2: COALESCE/IFNULL on payload columns in staging is prohibited.

    Enforces: Lesson #58
    Triggers on: COALESCE(VENDOR_STATUS, 'UNKNOWN') AS VENDOR_STATUS in LOGIC CTE
    Correct pattern: BK columns may use COALESCE (null BKs cause hub collisions).
                     Payload/optional columns: raw NULLs must be preserved through staging.
                     Null replacement for payload belongs in Business Vault (PIT/PB/REF).
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # Find LOGIC CTE blocks
    logic_pattern = re.compile(
        r',\s*LOGIC_\w+\s+[Aa][Ss]\s*\((.*?)(?=\n,\s*(?:LOGIC_|RENAME_|FILTER_|JOIN|FINAL|----)|$)',
        re.DOTALL,
    )

    # COALESCE/IFNULL aliased to a column name (not inside MD5_BINARY)
    coalesce_alias_re = re.compile(
        r'\b(COALESCE|IFNULL)\s*\([^)]+\)\s+[Aa][Ss]\s+(\w+)',
        re.IGNORECASE,
    )

    # Columns that legitimately use COALESCE
    _EXEMPT_SUFFIXES = ('_HK', '_BK', 'HASHDIFF', 'LOAD_DTS', 'REC_SRC', 'BKCC')

    findings = []
    for logic_m in logic_pattern.finditer(sql_content):
        logic_block = logic_m.group(1)
        block_start = logic_m.start(1)

        for coal_m in coalesce_alias_re.finditer(logic_block):
            alias = coal_m.group(2).upper()
            # Skip exempt columns (BK, HK, metadata)
            if any(alias.endswith(suffix) for suffix in _EXEMPT_SUFFIXES):
                continue
            # Skip if inside MD5_BINARY (part of HK/HASHDIFF formula)
            pre_in_block = logic_block[:coal_m.start()]
            if 'MD5_BINARY' in pre_in_block[max(0, len(pre_in_block) - 200):]:
                # Check if MD5_BINARY is still open (unmatched parens)
                snippet = pre_in_block[pre_in_block.rfind('MD5_BINARY'):]
                open_parens = snippet.count('(') - snippet.count(')')
                if open_parens > 0:
                    continue

            abs_pos = block_start + coal_m.start()
            line_num = sql_content[:abs_pos].count("\n") + 1
            findings.append(Finding(
                check_id="N2",
                check_name="coalesce_on_payload_in_staging",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=line_num,
                message=f"COALESCE/IFNULL on payload column '{alias}' in LOGIC CTE — null replacement belongs in Business Vault, not staging",
                suggestion=f"Remove COALESCE/IFNULL from '{alias}'. Preserve raw NULLs through staging and raw vault.",
            ))
            if len(findings) >= 5:
                return findings
    return findings


def check_primary_src_no_business_rules(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """N3: Primary source CTE must not have WHERE or QUALIFY without inline comment.

    Enforces: DV 2.0 principle — staging has no soft business rules.
    Context-specific filters (e.g. truncate-reload dedup) are allowed ONLY
    with an inline -- comment explaining the intent.

    The primary/driver source is determined by (in priority order):
      1. JOIN layer: JOIN_RESULT ... FROM FILTER_<suffix> or FROM LOGIC_<suffix>
         → primary source is SRC_<suffix>.
      2. LOGIC layer: first LOGIC_<suffix> CTE → primary is SRC_<suffix>.
      3. Last resort: first non-BKCC SRC_* CTE (positional).
    Secondary CTEs are exempt — they need QUALIFY for 1:1 join cardinality.
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # --- Determine primary source CTE name via JOIN layer ---
    cte_re = re.compile(r'\b(SRC_\w+)\s+as\s*\(', re.IGNORECASE)
    bkcc_indicators = re.compile(
        r'ref_business_key_collision|SELECT\s+BKCC\s*,\s*REC_SRC',
        re.IGNORECASE,
    )

    primary_cte_name: str | None = None

    # Strategy 1: Parse JOIN_RESULT FROM clause to identify the driver
    join_result_re = re.compile(
        r'JOIN_RESULT\s+as\s*\(\s*(?:SELECT\s+\*|SELECT\s+\w)[\s\S]*?FROM\s+(FILTER_\w+|LOGIC_\w+)',
        re.IGNORECASE,
    )
    jm = join_result_re.search(sql_content)
    if jm:
        driver_cte = jm.group(1)  # e.g. FILTER_S, LOGIC_promo
        # Strip the prefix (FILTER_ or LOGIC_) to get the suffix
        suffix = re.sub(r'^(?:FILTER|LOGIC)_', '', driver_cte, flags=re.IGNORECASE)
        primary_cte_name = f"SRC_{suffix}"

    # Strategy 2 (fallback): Parse first LOGIC_<suffix> CTE → SRC_<suffix> is driver
    if not primary_cte_name:
        logic_cte_re = re.compile(r'\b(LOGIC_\w+)\s+as\s*\(', re.IGNORECASE)
        for lm in logic_cte_re.finditer(sql_content):
            # Skip if inside a block comment
            pfx = sql_content[:lm.start()]
            if pfx.rfind("/*") > pfx.rfind("*/"):
                continue
            logic_suffix = re.sub(r'^LOGIC_', '', lm.group(1), flags=re.IGNORECASE)
            candidate = f"SRC_{logic_suffix}"
            # Verify it's not a BKCC CTE
            candidate_re = re.compile(
                rf'\b{re.escape(candidate)}\s+as\s*\(', re.IGNORECASE
            )
            cm = candidate_re.search(sql_content)
            if cm:
                body_start = cm.end()
                depth = 1
                pos = body_start
                while pos < len(sql_content) and depth > 0:
                    if sql_content[pos] == '(':
                        depth += 1
                    elif sql_content[pos] == ')':
                        depth -= 1
                    pos += 1
                body = sql_content[body_start:pos - 1]
                if not bkcc_indicators.search(body):
                    primary_cte_name = candidate
                    break

    # Strategy 3 (last resort): First non-BKCC SRC_* CTE
    if not primary_cte_name:
        for cm in cte_re.finditer(sql_content):
            prefix = sql_content[:cm.start()]
            last_open = prefix.rfind("/*")
            last_close = prefix.rfind("*/")
            if last_open > last_close:
                continue
            body_start = cm.end()
            depth = 1
            pos = body_start
            while pos < len(sql_content) and depth > 0:
                if sql_content[pos] == '(':
                    depth += 1
                elif sql_content[pos] == ')':
                    depth -= 1
                pos += 1
            body = sql_content[body_start:pos - 1]
            if bkcc_indicators.search(body):
                continue
            primary_cte_name = cm.group(1)
            break

    if not primary_cte_name:
        return []

    # Now find the SRC_<primary> CTE definition and extract its body
    match = None
    for cm in cte_re.finditer(sql_content):
        if cm.group(1).upper() == primary_cte_name.upper():
            # Skip if inside a block comment
            pfx = sql_content[:cm.start()]
            last_open = pfx.rfind("/*")
            last_close = pfx.rfind("*/")
            if last_open > last_close:
                continue
            match = cm
            break

    if not match:
        return []

    # Extract primary source CTE body (balance parens)
    start = match.end()
    depth = 1
    pos = start
    while pos < len(sql_content) and depth > 0:
        if sql_content[pos] == '(':
            depth += 1
        elif sql_content[pos] == ')':
            depth -= 1
        pos += 1
    src_s_body = sql_content[start:pos - 1]
    src_s_offset = start  # offset in the full SQL for line number calculation
    primary_cte_name = match.group(1)

    findings = []

    # N3's comment-proximity rule is shared with N1 via the module-level
    # `_has_documenting_comment` helper (extracted 2026-06-22 so N1 and N3
    # can't drift apart on what counts as a "documenting" inline comment).

    # Check for WHERE clause in SRC_S
    for wm in re.finditer(r'\bWHERE\b', src_s_body, re.IGNORECASE):
        if not _has_documenting_comment(src_s_body, wm.start()):
            abs_line = sql_content[:src_s_offset + wm.start()].count("\n") + 1
            findings.append(Finding(
                check_id="N3",
                check_name="primary_src_no_business_rules",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=abs_line,
                message=f"WHERE clause in primary source CTE ({primary_cte_name}) applies a business rule at staging layer — requires inline comment explaining intent",
                suggestion="Add an inline -- comment documenting why this filter is necessary, or move the filter to Business Vault",
            ))

    # Check for QUALIFY clause in primary source CTE
    for qm in re.finditer(r'\bQUALIFY\b', src_s_body, re.IGNORECASE):
        if not _has_documenting_comment(src_s_body, qm.start()):
            abs_line = sql_content[:src_s_offset + qm.start()].count("\n") + 1
            findings.append(Finding(
                check_id="N3",
                check_name="primary_src_no_business_rules",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=abs_line,
                message=f"QUALIFY in primary source CTE ({primary_cte_name}) applies a business rule at staging layer — requires inline comment explaining intent",
                suggestion="Add an inline -- comment documenting why this dedup/filter is necessary, or move to a downstream layer",
            ))

    return findings


# ═══════════════════════════════════════════════════════════════════════════════
# 14c. CHECK E3/C4 — ADDITIONAL QUALIFY & CTE CHECKS (Lessons #61, #20)
# ═══════════════════════════════════════════════════════════════════════════════

# Regex for QUALIFY ... ORDER BY <column> patterns
_QUALIFY_ORDER_BY_RE = re.compile(
    r'QUALIFY\s.*?ORDER\s+BY\s+(\w+)',
    re.IGNORECASE | re.DOTALL,
)

# Columns that should NOT appear in raw vault QUALIFY ORDER BY
_RAW_TIMESTAMP_COLS = {'_FIVETRAN_SYNCED', 'GLCHANGETIME', 'ZEXTRACTDATE',
                       'PSA_LOAD_DTS', 'PSA_RECORD_SOURCE'}


def check_qualify_order_by_load_dts(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """E3: Hub and LNK QUALIFY ORDER BY must always use LOAD_DTS.

    Enforces: Lesson #61
    Triggers on: QUALIFY ROW_NUMBER() OVER(... ORDER BY GLCHANGETIME) in a hub/link model
    Correct pattern: QUALIFY ROW_NUMBER() OVER(... ORDER BY LOAD_DTS)
    """
    if not file_path.endswith(".sql"):
        return []
    if not any(d in file_path for d in ("raw_vault/hub/", "raw_vault/link/")):
        return []

    findings = []
    for m in _QUALIFY_ORDER_BY_RE.finditer(sql_content):
        order_col = m.group(1).upper()
        if order_col == 'LOAD_DTS':
            continue
        # DECODE is used for multi-source precedence — intentional, not a violation
        if order_col == 'DECODE':
            continue
        if order_col in _RAW_TIMESTAMP_COLS or order_col not in (
            'LOAD_DTS', 'DECODE',
        ):
            # Only flag known raw ingestion columns to avoid false positives
            if order_col not in _RAW_TIMESTAMP_COLS:
                continue
            prefix = sql_content[:m.start()]
            # Skip if inside a comment
            last_open = prefix.rfind("/*")
            last_close = prefix.rfind("*/")
            if last_open > last_close:
                continue
            line_start = prefix.rfind("\n") + 1
            if "--" in prefix[line_start:]:
                continue

            line_num = prefix.count("\n") + 1
            findings.append(Finding(
                check_id="E3",
                check_name="qualify_order_by_load_dts",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=line_num,
                message=f"QUALIFY ORDER BY uses '{order_col}' — raw vault must use LOAD_DTS, not ingestion-specific columns",
                suggestion="Change ORDER BY to use LOAD_DTS",
            ))
    return findings


def check_where_in_src_cte_only(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """C4: WHERE clause must be applied in SRC CTE, not LOGIC layer.

    Enforces: Lesson #20
    Triggers on: WHERE <condition> inside a LOGIC_* CTE
    Correct pattern: WHERE <condition> inside SRC_* CTE
    Note: WHERE in FILTER_* CTEs is acceptable (legacy 6-layer pattern).
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []

    # Find LOGIC CTE blocks and check for WHERE clauses
    logic_cte_re = re.compile(
        r',\s*(LOGIC_\w+)\s+[Aa][Ss]\s*\((.*?)(?=\n,\s*(?:LOGIC_|RENAME_|FILTER_|JOIN|FINAL|----)|$)',
        re.DOTALL,
    )

    findings = []
    for m in logic_cte_re.finditer(sql_content):
        cte_name = m.group(1)
        cte_body = m.group(2)

        # Find WHERE in this CTE body (not inside subquery)
        # Simple approach: match WHERE at the start of a line (after whitespace)
        where_re = re.compile(r'^\s+WHERE\b', re.MULTILINE | re.IGNORECASE)
        for wm in where_re.finditer(cte_body):
            abs_pos = m.start(2) + wm.start()
            prefix = sql_content[:abs_pos]
            # Skip if inside a comment
            last_open = prefix.rfind("/*")
            last_close = prefix.rfind("*/")
            if last_open > last_close:
                continue
            line_start = prefix.rfind("\n") + 1
            if "--" in prefix[line_start:]:
                continue

            line_num = prefix.count("\n") + 1
            findings.append(Finding(
                check_id="C4",
                check_name="where_in_src_cte_only",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=line_num,
                message=f"WHERE clause in {cte_name} — filters should be in SRC CTE, not LOGIC layer",
                suggestion=f"Move the WHERE clause from {cte_name} to the corresponding SRC_* CTE",
            ))
    return findings


def check_qualify_dedup_with_secondary_join(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """E4: Models with secondary table JOINs (beyond BKCC) must have post-join QUALIFY dedup.

    Enforces: Lesson #14 (QUALIFY for dedup, never SELECT DISTINCT)
    Triggers on: New v_psa_stg model with LEFT JOIN to lookup tables but no QUALIFY
                 at or after the last secondary JOIN.
    Correct pattern: QUALIFY ROW_NUMBER() OVER (PARTITION BY <BK>, LOAD_DTS ORDER BY ...) = 1

    Logic:
      1. Find all JOINs that are NOT the BKCC join (ON '1' = '1')
      2. Locate the last secondary JOIN position
      3. Require at least one QUALIFY at or after that position
         (a QUALIFY only in SRC/LOGIC before all JOINs is source-dedup,
          not join-dedup — it doesn't protect against row multiplication)
    Only fires on NEW files in int_staging_views.
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []
    if file_status != FileStatus.NEW:
        return []

    # Find all JOIN statements (LEFT JOIN, INNER JOIN, JOIN)
    join_re = re.compile(
        r'\b(?:LEFT\s+(?:OUTER\s+)?|INNER\s+|RIGHT\s+(?:OUTER\s+)?|CROSS\s+)?JOIN\b',
        re.IGNORECASE,
    )
    joins = list(join_re.finditer(sql_content))
    if not joins:
        return []

    # Exclude BKCC joins: those have ON '1' = '1' within ~120 chars after JOIN
    # Also exclude JOINs inside comments (e.g. "---- JOIN LAYER ----")
    bkcc_on_re = re.compile(r"""ON\s+['"]1['"]\s*=\s*['"]1['"]""", re.IGNORECASE)
    secondary_joins = []
    for jm in joins:
        # Skip if inside a line comment (---- JOIN LAYER ----)
        line_start = sql_content.rfind("\n", 0, jm.start()) + 1
        line_prefix = sql_content[line_start:jm.start()]
        if "--" in line_prefix:
            continue
        # Skip if inside a block comment
        prefix = sql_content[:jm.start()]
        last_open = prefix.rfind("/*")
        last_close = prefix.rfind("*/")
        if last_open > last_close:
            continue
        after = sql_content[jm.end():jm.end() + 120]
        if bkcc_on_re.search(after):
            continue  # This is the BKCC join — skip
        secondary_joins.append(jm)

    if not secondary_joins:
        return []

    # Position of the last secondary JOIN
    last_secondary_pos = secondary_joins[-1].start()

    # Check if QUALIFY exists at or after the last secondary JOIN
    for qm in re.finditer(r'\bQUALIFY\b', sql_content, re.IGNORECASE):
        # Skip if inside a comment
        prefix = sql_content[:qm.start()]
        last_open = prefix.rfind("/*")
        last_close = prefix.rfind("*/")
        if last_open > last_close:
            continue
        line_start = prefix.rfind("\n") + 1
        if "--" in prefix[line_start:]:
            continue
        # Valid QUALIFY — check position relative to last secondary JOIN
        if qm.start() >= last_secondary_pos:
            return []  # Post-join QUALIFY covers all joins

    # Check if each secondary source CTE already has a QUALIFY (pre-join dedup).
    # If every non-BKCC SRC_* CTE deduplicates on its join key before the JOIN,
    # row multiplication is already prevented — no post-join QUALIFY needed.
    # This handles models where SRC_* → LOGIC_* → RENAME_* → FILTER_* → JOIN_RESULT.
    cte_re = re.compile(r'\b(SRC_\w+)\s+as\s*\(', re.IGNORECASE)
    cte_blocks: dict[str, str] = {}
    for cm in cte_re.finditer(sql_content):
        # Skip matches inside block comments
        prefix = sql_content[:cm.start()]
        last_open = prefix.rfind("/*")
        last_close = prefix.rfind("*/")
        if last_open > last_close:
            continue
        cte_name = cm.group(1).upper()
        # Extract the CTE body (find matching close paren)
        start = cm.end()
        depth = 1
        pos = start
        while pos < len(sql_content) and depth > 0:
            if sql_content[pos] == '(':
                depth += 1
            elif sql_content[pos] == ')':
                depth -= 1
            pos += 1
        cte_blocks[cte_name] = sql_content[start:pos - 1]

    # Identify non-BKCC SRC_* CTEs (BKCC CTE typically has ref('ref_business_key_collision')
    # or only selects BKCC/REC_SRC columns)
    bkcc_indicators = re.compile(
        r'ref_business_key_collision|SELECT\s+BKCC\s*,\s*REC_SRC',
        re.IGNORECASE,
    )
    non_bkcc_src_ctes = {
        name: body for name, body in cte_blocks.items()
        if not bkcc_indicators.search(body)
    }

    # If there are non-BKCC SRC_* CTEs and ALL of them have QUALIFY, suppress E4.
    # Require at least 2 non-BKCC sources (primary + lookups) to ensure the model
    # actually has dedicated deduped source CTEs for secondary joins.
    if len(non_bkcc_src_ctes) >= 2:
        all_src_have_qualify = all(
            re.search(r'\bQUALIFY\b', body, re.IGNORECASE)
            for body in non_bkcc_src_ctes.values()
        )
        if all_src_have_qualify:
            return []  # Every secondary source CTE already deduplicates

    # No QUALIFY at or after the last secondary JOIN — flag it
    first_secondary = secondary_joins[0]
    line_num = sql_content[:first_secondary.start()].count("\n") + 1

    # Determine message variant
    has_any_qualify = bool(re.search(r'\bQUALIFY\b', sql_content, re.IGNORECASE))
    if has_any_qualify:
        message = (
            f"Model has {len(secondary_joins)} secondary JOIN(s) but QUALIFY "
            f"only appears before the JOINs (source-dedup). Add a post-join "
            f"QUALIFY to cover all lookup JOINs against row multiplication"
        )
    else:
        message = (
            f"Model has {len(secondary_joins)} secondary JOIN(s) (beyond BKCC) "
            f"but no QUALIFY dedup — risk of row multiplication"
        )

    return [Finding(
        check_id="E4",
        check_name="qualify_dedup_with_secondary_join",
        severity=Severity.WARN,
        file_path=file_path,
        line_number=line_num,
        message=message,
        suggestion=(
            "Add QUALIFY ROW_NUMBER() OVER (PARTITION BY <BK>, LOAD_DTS "
            "ORDER BY LOAD_DTS DESC) = 1 after the last JOIN (in JOIN_RESULT or FINAL CTE)"
        ),
    )]


# ═══════════════════════════════════════════════════════════════════════════════
# 14c. CATEGORY Q — CONCEPTUAL MODELING (advisory, WARN)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Category Q covers DESIGN-level modeling issues that pass every syntactic check
# but corrupt data — the conceptual layer documented in
# .github/knowledge/data-vault/. These are all WARN (advisory): design decisions
# belong to the engineer, so the reviewer surfaces the risk and cites the trap,
# never blocks. See .github/knowledge/data-vault/08-modeling-traps.md.
#
# Extensible: cross-domain BKCC (TRAP-02) and non-co-occurring UoW links
# (TRAP-03) need cross-model context and are handled by the DV Knowledge Advisor
# agent rather than static analysis.

# PII column-name tokens (whole-word), curated for high precision (low noise).
_PII_TOKENS: tuple[str, ...] = (
    "EMAIL", "E_MAIL", "SSN", "SOCIAL_SECURITY", "PASSPORT",
    "NATIONAL_ID", "TAX_ID", "DATE_OF_BIRTH", "BIRTH_DATE",
    "DRIVERS_LICENSE", "DRIVER_LICENSE",
)
# Boundary = start/end OR any non-alphanumeric, so snake_case columns like
# CUSTOMER_EMAIL and EMAIL_ADDRESS match while embedded substrings like EMAILING
# do not. NOTE: `\b` is WRONG here — `_` is a word char, so `\bEMAIL\b` fails to
# match CUSTOMER_EMAIL (no boundary between `_` and `E`). Treat `_` as a separator.
_PII_TOKEN_RE = re.compile(
    r"(?<![A-Za-z0-9])(" + "|".join(_PII_TOKENS) + r")(?![A-Za-z0-9])",
    re.IGNORECASE,
)


def _strip_sql_comments_and_jinja(sql: str) -> str:
    """Remove SQL comments and Jinja so a token scan sees payload code, not prose.

    Q2 (satellite_pii_not_split) must not fire on a PII token that appears only
    in a ``--`` line comment, a ``/* ... */`` block comment, or Jinja — those are
    prose/templating, not payload columns (issue #1914). Scanning the stripped
    code (rather than only the literal final SELECT) preserves the real signal on
    ``SELECT *`` satellites, whose payload columns live in an upstream CTE.
    """
    sql = re.sub(r"\{#.*?#\}", " ", sql, flags=re.DOTALL)    # {# jinja comment #}
    sql = re.sub(r"\{%.*?%\}", " ", sql, flags=re.DOTALL)    # {% jinja statement %}
    sql = re.sub(r"\{\{.*?\}\}", " ", sql, flags=re.DOTALL)  # {{ jinja expr }}
    sql = re.sub(r"/\*.*?\*/", " ", sql, flags=re.DOTALL)     # /* block comment */
    sql = re.sub(r"--[^\n]*", " ", sql)                       # -- line comment
    return sql


def _concat_ws_component_count(block: str) -> int | None:
    """Count CONCAT_WS key components (arguments after the leading '||' separator)
    in an HK block, honoring nested parens and single-quoted literals.

    Returns None when CONCAT_WS is absent or parentheses are unbalanced — i.e.
    when completeness cannot be verified. Q1 uses this to avoid comparing HKs
    whose components were only partially extracted (e.g. a component using a
    non-'^^' null fallback like '-1', or a complex CAST expression, which the
    shared component regex does not match).
    """
    m = re.search(r"CONCAT_WS\s*\(", block, re.IGNORECASE)
    if not m:
        return None
    depth = 1
    top_level_commas = 0
    in_squote = False
    i = m.end()
    while i < len(block):
        ch = block[i]
        if in_squote:
            if ch == "'":
                in_squote = False
        elif ch == "'":
            in_squote = True
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                # args = top_level_commas + 1; drop the leading '||' separator.
                return top_level_commas
        elif ch == "," and depth == 1:
            top_level_commas += 1
        i += 1
    return None  # unbalanced parens — cannot verify


def check_link_hk_component_collision(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """Q1: Two distinct hash keys in one staging model must not share an
    identical ordered raw-column component list.

    Enforces: .github/knowledge/data-vault/08-modeling-traps.md TRAP-01.
    Because CONCAT_WS('||', 'A||B', 'C') == CONCAT_WS('||', 'A', 'B', 'C') == 'A||B||C',
    a link HK built from a composite BK's raw columns can hash BYTE-IDENTICAL to the
    line hub HK — two different objects, one hash key → silent join corruption.

    Triggers on: PO_ITEM_HK and LNK_PO_ITEM_HK both = [PO_HEADER_ID, LINE_NUM, BKCC].
    Fix: duplicate the shared leading component in the link HK, e.g.
         [PO_HEADER_ID, PO_HEADER_ID, LINE_NUM, BKCC] (the duplicate is intentional).

    Limitation: only raw COALESCE-wrapped components are compared. A link HK that
    MIXES component *_HK references with raw columns (non-conventional at FBIN) is
    not precisely modeled and could yield an advisory false positive. WARN severity
    keeps this non-blocking; cross-model precision is the DV Knowledge Advisor's job.
    """
    if not file_path.endswith(".sql"):
        return []
    if "int_staging_views/" not in file_path:
        return []  # HK formulas live in v_psa_stg models

    # Map each distinct HK name → its ordered raw-column component list.
    components_by_hk: dict[str, tuple[list[str], int]] = {}
    for block, hk_name, line_num in _extract_hk_blocks(sql_content):
        components = [m.group(1).upper() for m in _HK_COMPONENT_RE.finditer(block)]
        if not components:
            continue  # HK built from component *_HK columns (no raw components) — safe
        # Only compare when extraction is COMPLETE: the extracted component count
        # must equal the actual CONCAT_WS argument count. Otherwise a component
        # using a non-'^^' null fallback (e.g. '-1') or a complex CAST expression
        # is silently dropped, collapsing distinct HKs to a spurious match. Skip
        # when completeness cannot be verified — never risk a false positive.
        expected = _concat_ws_component_count(block)
        if expected is None or len(components) != expected:
            continue
        # First definition of a given HK name wins (multi-source CTEs repeat the name).
        components_by_hk.setdefault(hk_name.upper(), (components, line_num))

    findings: list[Finding] = []
    seen_pairs: set[frozenset[str]] = set()
    items = list(components_by_hk.items())
    for i in range(len(items)):
        name_a, (comp_a, line_a) = items[i]
        for j in range(i + 1, len(items)):
            name_b, (comp_b, line_b) = items[j]
            if comp_a != comp_b:
                continue
            pair_key = frozenset((name_a, name_b))
            if pair_key in seen_pairs:
                continue
            seen_pairs.add(pair_key)
            findings.append(Finding(
                check_id="Q1",
                check_name="link_hk_component_collision",
                severity=Severity.WARN,
                file_path=file_path,
                line_number=max(line_a, line_b),
                message=(
                    f"'{name_a}' and '{name_b}' hash IDENTICAL inputs "
                    f"[{', '.join(comp_a)}] — they will collide byte-for-byte "
                    f"(CONCAT_WS is associative over '||'). Two distinct keys must "
                    f"not share a component list."
                ),
                suggestion=(
                    "If one is a link HK over a composite-BK hub, duplicate the shared "
                    "leading component in the link HK (e.g. [ID, ID, LINE, BKCC]); the "
                    "duplicate is intentional. See knowledge/data-vault/08-modeling-traps.md TRAP-01."
                ),
            ))
    return findings


def check_satellite_pii_not_split(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """Q2: PII attributes in a satellite that is not a dedicated PII satellite
    should be split out for column-level masking.

    Enforces: .github/knowledge/data-vault/06-satellite-splits.md (privacy trigger).
    Advisory only — the engineer decides the split boundary.

    Triggers on: sat_customer__crm.sql containing EMAIL / SSN alongside other columns,
    where the model name does not contain 'pii'.
    """
    if not file_path.endswith(".sql"):
        return []
    if "raw_vault/sat/" not in file_path:
        return []
    stem = Path(file_path).stem.lower()
    # Only descriptive satellites (payload-bearing). esat_ has no payload; tlink_ is a link.
    if not stem.startswith(("sat_", "lsat_", "msat_", "lmsat_")):
        return []
    if "pii" in stem:
        return []  # already a dedicated PII satellite — split done

    # Scan payload code only — strip comments/Jinja so a PII token in prose
    # (a comment or docstring) does not false-fire (issue #1914).
    scan_text = _strip_sql_comments_and_jinja(sql_content)
    tokens_found = sorted({m.group(1).upper() for m in _PII_TOKEN_RE.finditer(scan_text)})
    if not tokens_found:
        return []

    return [Finding(
        check_id="Q2",
        check_name="satellite_pii_not_split",
        severity=Severity.WARN,
        file_path=file_path,
        message=(
            f"PII attribute(s) {tokens_found} detected in satellite '{stem}', which is "
            f"not a dedicated PII satellite — mixing PII with non-PII blocks column-level "
            f"masking policies."
        ),
        suggestion=(
            "Consider splitting PII columns into a sibling satellite (same parent HK) "
            "named '<entity>_pii__<source>' so a masking policy can target it. "
            "See knowledge/data-vault/06-satellite-splits.md. Advisory — confirm with the user."
        ),
    )]


# ═══════════════════════════════════════════════════════════════════════════════
# 15. CHECK REGISTRY
# ═══════════════════════════════════════════════════════════════════════════════

# Maps check_id → (function, applicable_file_patterns, category)
# File patterns use simple suffix matching, not glob.
CHECK_REGISTRY: dict[str, CheckEntry] = {
    # Category A — Hash Key (HK) Formula
    "A1": CheckEntry(check_hk_uses_concat_ws, [".sql"], "A"),
    "A2": CheckEntry(check_hk_coalesce_nullif_trim, [".sql"], "A"),
    "A3": CheckEntry(check_hk_uses_raw_column_names, [".sql"], "A"),
    "A4": CheckEntry(check_hk_bkcc_last_component, [".sql"], "A"),
    "A5": CheckEntry(check_hk_has_upper_wrapper, [".sql"], "A"),
    # Category B — HASHDIFF Formula
    "B1": CheckEntry(check_hashdiff_uses_nullif_concat, [".sql"], "B"),
    "B2": CheckEntry(check_hashdiff_ifnull_trim_pattern, [".sql"], "B"),
    "B3": CheckEntry(check_hashdiff_separator_pattern, [".sql"], "B"),
    "B4": CheckEntry(check_hashdiff_excludes_metadata, [".sql"], "B"),
    "B5": CheckEntry(check_hashdiff_includes_psa_delete_ind, [".sql"], "B"),
    "B6": CheckEntry(check_hashdiff_includes_fivetran_deleted, [".sql"], "B"),
    "B7": CheckEntry(check_hashdiff_ends_with_sentinel, [".sql"], "B"),
    "B8": CheckEntry(check_hashdiff_delete_flag_explicit_cast, [".sql"], "B"),
    # Category C — CTE Structure
    "C1": CheckEntry(check_cte_4layer_new_models, [".sql"], "C"),
    "C2": CheckEntry(check_cte_no_nonstandard_names, [".sql"], "C"),
    "C3": CheckEntry(check_final_select_from_join_result, [".sql"], "C"),
    # Category D — BKCC Standards
    "D1": CheckEntry(check_bkcc_join_on_1_equals_1, [".sql"], "D"),
    "D2": CheckEntry(check_bkcc_from_ref_table, [".sql"], "D"),
    "D3": CheckEntry(check_bkcc_column_present, [".sql"], "D"),
    # Category E — Dedup & QUALIFY
    "E1": CheckEntry(check_no_select_distinct, [".sql"], "E"),
    "E2": CheckEntry(check_qualify_has_row_number, [".sql"], "E"),
    # Category F — Date & Timezone
    "F1": CheckEntry(check_convert_timezone_utc, [".sql"], "F"),
    "F2": CheckEntry(check_null_date_1900_placeholder, [".sql"], "F"),
    "F3": CheckEntry(check_load_dts_derivation_fivetran, [".sql"], "F"),
    "F4": CheckEntry(check_load_dts_derivation_snp_glue, [".sql"], "F"),
    "F5": CheckEntry(check_load_dts_has_convert_timezone, [".sql"], "F"),
    # Category G — Naming Conventions
    "G1": CheckEntry(check_vpsa_stg_prefix, [".sql"], "G"),
    "G2": CheckEntry(check_hub_prefix, [".sql"], "G"),
    "G3": CheckEntry(check_sat_prefix, [".sql"], "G"),
    "G4": CheckEntry(check_link_prefix, [".sql"], "G"),
    "G5": CheckEntry(check_double_underscore_separator, [".sql"], "G"),
    "G6": CheckEntry(check_column_names_uppercase, [".sql"], "G"),
    # Category H — Test Coverage (YAML)
    "H2": CheckEntry(check_data_tests_not_deprecated, [".yml", ".yaml"], "H"),
    "H8": CheckEntry(check_no_constraints_on_views, [".yml", ".yaml"], "H"),
    "H9": CheckEntry(check_sat_grain_suggests_msat, [".yml", ".yaml"], "H"),
    "H10": CheckEntry(check_grain_excludes_metadata, [".yml", ".yaml"], "H"),
    "H11": CheckEntry(check_sat_has_foreign_key, [".yml", ".yaml"], "H"),
    # Category I — Source & Layer Integrity
    "I1": CheckEntry(check_uses_source_or_ref, [".sql"], "I"),
    "I2": CheckEntry(check_staging_source_discipline, [".sql"], "I"),
    "I3": CheckEntry(check_dim_fact_no_business_logic, [".sql"], "I"),
    "I4": CheckEntry(check_non_staging_uses_ref_only, [".sql"], "I"),
    "I5": CheckEntry(check_source_ref_in_governed_allowlist, [".sql"], "I"),
    # Category J — Incremental Model Config
    "J1": CheckEntry(check_where_not_exists_uses_hashdiff, [".sql"], "J"),
    "J2": CheckEntry(check_hub_where_not_exists_hk_only, [".sql"], "J"),
    "J5": CheckEntry(check_watermark_scoped_per_rec_src, [".sql"], "J"),
    "J6": CheckEntry(check_sat_delete_scoped_watermark, [".sql"], "J"),
    # Category K — Ghost Record Standards
    "K1": CheckEntry(check_ghost_record_decode_pattern, [".sql"], "K"),
    "K2": CheckEntry(check_ghost_record_three_sentinels, [".sql"], "K"),
    "K5": CheckEntry(check_ghost_record_hk_formula, [".sql"], "K"),
    "K6": CheckEntry(check_ghost_record_keys_not_null, [".sql"], "K"),
    # Category L — Join Patterns
    "L1": CheckEntry(check_inner_join_has_comment, [".sql"], "L"),
    # Category M — Miscellaneous
    "M1": CheckEntry(check_no_hardcoded_env, [".sql"], "M"),
    "M2": CheckEntry(check_no_select_star_outside_src, [".sql"], "M"),
    "M3": CheckEntry(check_rec_src_format, [".sql"], "M"),
    "M4": CheckEntry(check_header_comment_present, [".sql"], "M"),
    "M5": CheckEntry(check_fix_proof_atomicity_prompt, [".py"], "M"),
    # Category N — Staging Data Integrity (Lessons #28, #58)
    "N1": CheckEntry(check_no_delete_flag_filter, [".sql"], "N"),
    "N2": CheckEntry(check_coalesce_on_payload_in_staging, [".sql"], "N"),
    "N3": CheckEntry(check_primary_src_no_business_rules, [".sql"], "N"),
    # Additional Category E/C checks (Lessons #61, #20)
    "E3": CheckEntry(check_qualify_order_by_load_dts, [".sql"], "E"),
    "E4": CheckEntry(check_qualify_dedup_with_secondary_join, [".sql"], "E"),
    "C4": CheckEntry(check_where_in_src_cte_only, [".sql"], "C"),
    # Category Q — Conceptual Modeling (advisory, WARN)
    "Q1": CheckEntry(check_link_hk_component_collision, [".sql"], "Q"),
    "Q2": CheckEntry(check_satellite_pii_not_split, [".sql"], "Q"),
}


# Checks that opt into receiving ``repo_root`` (for loading config / sources YAML).
# Computed via signature inspection so additions are automatic — no manual upkeep.
_CHECKS_ACCEPTING_REPO_ROOT: frozenset[str] = frozenset(
    check_id for check_id, entry in CHECK_REGISTRY.items()
    if "repo_root" in inspect.signature(entry.fn).parameters
)


# ═══════════════════════════════════════════════════════════════════════════════
# 16. RUNNER
# ═══════════════════════════════════════════════════════════════════════════════

def _file_matches_patterns(file_path: str, patterns: list[str]) -> bool:
    """Check if a file path ends with any of the given suffix patterns."""
    return any(file_path.endswith(p) for p in patterns)


def _is_reviewable_changed_file(file_path: str) -> bool:
    """Return True if a changed file is in code review scope for default runs."""
    if file_path.startswith("models/") and file_path.endswith((".sql", ".yml", ".yaml")):
        return True
    if file_path.startswith("scripts/automation/src/triage/") and file_path.endswith(".py"):
        return True
    return False


def review_file(
    file_path: str,
    sql_content: str | None = None,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
    ignore_patterns: list[str] | None = None,
    category_filter: str | None = None,
    check_filter: str | None = None,
    repo_root: Path | None = None,
) -> list[Finding]:
    """Run all applicable checks against a single file.

    Args:
        file_path: Relative path from repo root (e.g. "models/raw_vault/hub/hub_foo.sql")
        sql_content: Raw SQL file content (for .sql files)
        yaml_content: Raw YAML file content (for .yml files, or paired YAML for .sql)
        file_status: NEW or MODIFIED (affects G4 severity)
        ignore_patterns: From .code_review_ignore (skips Category G if matched)
        category_filter: Only run checks in this category (e.g. "G")
        check_filter: Only run this specific check (e.g. "G4")

    Returns:
        List of Finding objects (empty = all checks passed)
    """
    findings: list[Finding] = []
    skip_naming = False

    if ignore_patterns and is_naming_ignored(file_path, ignore_patterns):
        skip_naming = True
        logger.debug("Skipping naming checks for %s (listed in .code_review_ignore)", file_path)

    content = sql_content or yaml_content or ""

    for check_id, entry in CHECK_REGISTRY.items():
        # Filter by category
        if category_filter and entry.category != category_filter:
            continue
        # Filter by specific check
        if check_filter and check_id != check_filter:
            continue
        # Skip Category G if file is in .code_review_ignore
        if skip_naming and entry.category == "G":
            continue
        # Skip if file type doesn't match
        if not _file_matches_patterns(file_path, entry.file_patterns):
            continue

        # Build kwargs; pass repo_root only to checks that declare it. This
        # keeps the existing 52 checks' signatures untouched while letting
        # I2 (and any future check) access the repo's config/sources YAML.
        kwargs = {
            "sql_content": content,
            "file_path": file_path,
            "yaml_content": yaml_content,
            "file_status": file_status,
        }
        if check_id in _CHECKS_ACCEPTING_REPO_ROOT:
            kwargs["repo_root"] = repo_root

        # Isolate each check: a single check raising (e.g. a missing optional
        # dependency, or an unhandled input shape) must not blind the other
        # 50+ checks. We catch Exception only — KeyboardInterrupt/SystemExit
        # still propagate — and surface the failure as a FAIL finding.
        # Fail-closed is deliberate: the registry carries no per-check
        # severity, and a crashed governance/security check (e.g. I5) must
        # block merge rather than silently pass.
        try:
            check_findings = entry.fn(**kwargs)
        except Exception as exc:  # noqa: BLE001 — intentional broad isolation
            logger.exception(
                "Check %s (%s) raised on %s — isolating and continuing",
                check_id, entry.fn.__name__, file_path,
            )
            findings.append(Finding(
                check_id=check_id,
                check_name=f"{entry.fn.__name__} (internal error)",
                severity=Severity.FAIL,
                file_path=file_path,
                message=(
                    f"Check {check_id} did not complete: "
                    f"{type(exc).__name__}: {exc}. The reviewer isolated this "
                    f"failure so the remaining checks still ran; this finding "
                    f"blocks merge until the check is fixed."
                ),
                suggestion=(
                    "Internal reviewer error, not a model defect. See the "
                    "workflow logs for the full traceback and fix the check "
                    "(e.g. a missing dependency or an unhandled input)."
                ),
            ))
            continue
        findings.extend(check_findings)

    return findings


def review_files(
    files: list[str],
    repo_root: Path | None = None,
    base_branch: str = "origin/main",
    category_filter: str | None = None,
    check_filter: str | None = None,
) -> ReviewResult:
    """Run all applicable checks against a list of files.

    Args:
        files: List of relative paths from repo root
        repo_root: Project root directory (for reading files and config)
        base_branch: Git ref for new-vs-modified detection
        category_filter: Only run checks in this category
        check_filter: Only run this specific check

    Returns:
        ReviewResult with all findings aggregated
    """
    if repo_root is None:
        repo_root = _PROJECT_ROOT

    result = ReviewResult()
    ignore_patterns = load_ignore_list(repo_root)
    file_statuses = get_file_statuses(base_branch)

    for file_path in files:
        # CD-2: Skip excluded paths entirely
        if is_excluded(file_path):
            result.files_skipped += 1
            logger.debug("Skipping %s (excluded path)", file_path)
            continue

        # Read file content
        abs_path = repo_root / file_path
        if not abs_path.exists():
            logger.warning("File not found: %s", abs_path)
            continue

        content = abs_path.read_text(encoding="utf-8", errors="replace")
        file_status = file_statuses.get(file_path, FileStatus.NEW)

        sql_content = content if file_path.endswith(".sql") else None
        yaml_content = content if file_path.endswith((".yml", ".yaml")) else None

        # For SQL files, try to load paired YAML
        paired_yaml = None
        if file_path.endswith(".sql"):
            yml_path = abs_path.with_suffix(".yml")
            if yml_path.exists():
                paired_yaml = yml_path.read_text(encoding="utf-8", errors="replace")

        file_findings = review_file(
            file_path=file_path,
            sql_content=sql_content,
            yaml_content=paired_yaml if sql_content else yaml_content,
            file_status=file_status,
            ignore_patterns=ignore_patterns,
            category_filter=category_filter,
            check_filter=check_filter,
            repo_root=repo_root,
        )
        result.findings.extend(file_findings)
        result.files_checked += 1

        # Count checks that were actually run against this file
        for check_id, entry in CHECK_REGISTRY.items():
            if category_filter and entry.category != category_filter:
                continue
            if check_filter and check_id != check_filter:
                continue
            if _file_matches_patterns(file_path, entry.file_patterns):
                result.checks_run += 1

    return result


# ═══════════════════════════════════════════════════════════════════════════════
# 17. OUTPUT FORMATTERS
# ═══════════════════════════════════════════════════════════════════════════════

def format_markdown(result: ReviewResult) -> str:
    """Format findings as a GitHub PR comment in markdown."""
    lines = ["## 🔍 Code Review — Automated Findings", ""]

    if not result.findings:
        lines.append(
            f"**Result**: ✅ All checks passed | {result.files_checked} files checked"
        )
        if result.files_skipped:
            lines.append(f"*({result.files_skipped} files skipped — excluded paths)*")
        return "\n".join(lines)

    status = "❌" if result.has_failures else "⚠️"
    lines.append(
        f"**Result**: {status} {result.fail_count} FAIL | "
        f"⚠️ {result.warn_count} WARN | "
        f"{result.files_checked} files checked"
    )
    if result.files_skipped:
        lines.append(f"*({result.files_skipped} files skipped — excluded paths)*")
    lines.append("")

    # Category summary checklist
    category_labels = {
        "A": "Hash Keys", "B": "HASHDIFF", "C": "CTE Structure",
        "D": "BKCC", "E": "Dedup/QUALIFY", "F": "Date/Timezone",
        "G": "Naming", "H": "Test Coverage", "I": "Source Integrity",
        "J": "Incremental", "K": "Ghost Records", "L": "Joins",
        "M": "Misc", "N": "Staging Integrity", "Q": "Conceptual Modeling",
    }
    failed_cats = {f.check_id[0] for f in result.findings if f.severity == Severity.FAIL}
    warned_cats = {f.check_id[0] for f in result.findings if f.severity == Severity.WARN} - failed_cats
    # Only show categories that had checks run (at least one finding or implicitly passed)
    all_cats_seen = {f.check_id[0] for f in result.findings}
    checklist_parts = []
    for cat in sorted(category_labels.keys()):
        if cat in failed_cats:
            checklist_parts.append(f"❌ {category_labels[cat]}")
        elif cat in warned_cats:
            checklist_parts.append(f"⚠️ {category_labels[cat]}")
        elif cat in all_cats_seen:
            checklist_parts.append(f"✅ {category_labels[cat]}")
    if checklist_parts:
        lines.append("**Checklist**: " + " | ".join(checklist_parts))
        lines.append("")

    # Group by severity
    fails = [f for f in result.findings if f.severity == Severity.FAIL]
    warns = [f for f in result.findings if f.severity == Severity.WARN]

    if fails:
        lines.append("### ❌ FAIL (blocks merge)")
        lines.append("")
        lines.append("| Check | File | Line | Finding |")
        lines.append("|-------|------|------|---------|")
        for f in fails:
            line_str = str(f.line_number) if f.line_number else "—"
            # Escape pipe characters in message
            msg = f.message.replace("|", "\\|")
            lines.append(f"| {f.check_id} | `{Path(f.file_path).name}` | {line_str} | {msg} |")
        lines.append("")

    if warns:
        lines.append("### ⚠️ WARN (advisory)")
        lines.append("")
        lines.append("| Check | File | Line | Finding |")
        lines.append("|-------|------|------|---------|")
        for f in warns:
            line_str = str(f.line_number) if f.line_number else "—"
            msg = f.message.replace("|", "\\|")
            lines.append(f"| {f.check_id} | `{Path(f.file_path).name}` | {line_str} | {msg} |")
        lines.append("")

    return "\n".join(lines)


def format_json(result: ReviewResult) -> str:
    """Format findings as JSON for machine consumption."""
    data = {
        "files_checked": result.files_checked,
        "files_skipped": result.files_skipped,
        "checks_run": result.checks_run,
        "fail_count": result.fail_count,
        "warn_count": result.warn_count,
        "has_failures": result.has_failures,
        "findings": [
            {
                "check_id": f.check_id,
                "check_name": f.check_name,
                "severity": f.severity.value,
                "file_path": f.file_path,
                "line_number": f.line_number,
                "message": f.message,
                "suggestion": f.suggestion,
            }
            for f in result.findings
        ],
    }
    return json.dumps(data, indent=2)


# ═══════════════════════════════════════════════════════════════════════════════
# 18. CLI ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════

def _validate_grandfather(repo_root: Path) -> int:
    """Burn-down validation: report grandfather entries whose underlying file
    no longer violates the matching check.

    Scans the WHOLE repo for I2, I4, H10, and H11 violations (the checks
    currently represented in the grandfather list), compares against the
    loaded list, and prints any entries that are now stale (file fixed →
    entry can be removed).

    Exit codes:
        0 — all grandfather entries still correspond to actual violations
        2 — stale entries found (informational; the list should be shrunk)
    """
    grandfather = load_grandfather_list(repo_root)
    if not grandfather:
        print("No .code_review_grandfather entries to validate.")
        return 0

    # Build set of currently-violating (check_id, file_path) pairs by re-running
    # I2, I4, H10, H11 on the whole repo. Note: we read files DIRECTLY here to
    # avoid the grandfather-downgrade applied by the check functions themselves —
    # we need the underlying FAIL state, not the downgraded WARN state.
    live: set[tuple[str, str]] = set()

    # I2: int_staging_views only
    stg_dir = repo_root / "models" / "int_staging_views"
    if stg_dir.is_dir():
        for sql in stg_dir.rglob("*.sql"):
            rel = str(sql.relative_to(repo_root))
            content = sql.read_text(encoding="utf-8", errors="replace")
            # Reconstruct the pre-downgrade FAIL set from the post-downgrade
            # findings list. The check functions apply the grandfather
            # downgrade themselves before returning, so a finding that
            # *would* have been FAIL is now WARN with a ``[GRANDFATHERED]``
            # message prefix. We accept both signals:
            #   - severity == FAIL: unlisted live violation
            #   - message startswith ``[GRANDFATHERED]``: listed live violation
            #     that was downgraded
            # Together they yield the (check_id, file_path) pairs that would
            # have FAILed absent the grandfather list — the correct reference
            # for burn-down validation.
            for f in check_staging_source_discipline(content, rel, repo_root=repo_root):
                if f.message.startswith("[GRANDFATHERED]") or f.severity == Severity.FAIL:
                    live.add((f.check_id, rel))

    # I4: downstream layers
    for layer in ("raw_vault", "bus_vault", "info_mart"):
        d = repo_root / "models" / layer
        if not d.is_dir():
            continue
        for sql in d.rglob("*.sql"):
            rel = str(sql.relative_to(repo_root))
            content = sql.read_text(encoding="utf-8", errors="replace")
            for f in check_non_staging_uses_ref_only(content, rel, repo_root=repo_root):
                if f.message.startswith("[GRANDFATHERED]") or f.severity == Severity.FAIL:
                    live.add((f.check_id, rel))

    # H10 (grain excludes metadata) + H11 (sat missing FK): raw_vault/sat YAML
    sat_dir = repo_root / "models" / "raw_vault" / "sat"
    if sat_dir.is_dir():
        for ymlf in sat_dir.rglob("*.yml"):
            rel = str(ymlf.relative_to(repo_root))
            try:
                yaml_text = ymlf.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            for f in check_grain_excludes_metadata(
                "", rel, yaml_text, FileStatus.NEW, repo_root=repo_root,
            ):
                if f.message.startswith("[GRANDFATHERED]") or f.severity == Severity.FAIL:
                    live.add((f.check_id, rel))
            for f in check_sat_has_foreign_key(
                "", rel, yaml_text, FileStatus.NEW, repo_root=repo_root,
            ):
                if f.message.startswith("[GRANDFATHERED]") or f.severity == Severity.FAIL:
                    live.add((f.check_id, rel))

    stale = sorted(grandfather - live)
    if not stale:
        print(f"All {len(grandfather)} grandfather entries still active. List unchanged.")
        return 0

    print(
        f"BURN-DOWN OPPORTUNITY: {len(stale)} of {len(grandfather)} grandfather "
        f"entries are stale (the file no longer violates the matching check):\n"
    )
    for cid, rel in stale:
        print(f"  {cid} {rel}")
    print(
        f"\nThese entries can be REMOVED from "
        f"scripts/automation/.code_review_grandfather. The frozen list shrinks "
        f"by {len(stale)} \u2014 burn-down progress."
    )
    return 2


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Deterministic pre-PR code review for dbt-datavault",
    )
    parser.add_argument(
        "--files", nargs="+", default=None,
        help="Specific files to review (relative to repo root). "
             "If omitted, reviews all changed files from git diff.",
    )
    parser.add_argument(
        "--category", default=None,
        help="Only run checks in this category (e.g. G, A, B)",
    )
    parser.add_argument(
        "--check", default=None,
        help="Only run this specific check (e.g. G4, A1)",
    )
    parser.add_argument(
        "--format", dest="output_format", default="markdown",
        choices=["markdown", "json"],
        help="Output format (default: markdown)",
    )
    parser.add_argument(
        "--base-branch", default="origin/main",
        help="Base branch for new-vs-modified detection (default: origin/main)",
    )
    parser.add_argument(
        "--repo-root", default=None,
        help="Project root directory (default: auto-detected)",
    )
    parser.add_argument(
        "--loglevel", default="WARNING",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        help="Logging level",
    )
    parser.add_argument(
        "--validate-grandfather", action="store_true",
        help="Burn-down validation mode: scan the whole repo and report any "
             "(check_id, file_path) entries in .code_review_grandfather that "
             "no longer correspond to actual violations. Those entries can be "
             "deleted from the list. Exits 0 if all entries are still needed; "
             "exits 2 if stale entries are found (the report is informational).",
    )

    args = parser.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.loglevel),
        format="%(levelname)s: %(message)s",
    )

    repo_root = Path(args.repo_root) if args.repo_root else _PROJECT_ROOT

    if args.validate_grandfather:
        return _validate_grandfather(repo_root)

    # Determine files to review
    if args.files:
        files = args.files
    else:
        # Get changed files from git diff
        file_statuses = get_file_statuses(args.base_branch)
        if not file_statuses:
            logger.info("No changed files found in git diff")
            print("No changed files found.")
            return 0
        files = [f for f in file_statuses if _is_reviewable_changed_file(f)]
        if not files:
            logger.info("No reviewable model or triage files in diff")
            print("No reviewable files changed.")
            return 0

    result = review_files(
        files=files,
        repo_root=repo_root,
        base_branch=args.base_branch,
        category_filter=args.category,
        check_filter=args.check,
    )

    # Output
    if args.output_format == "json":
        print(format_json(result))
    else:
        print(format_markdown(result))

    return 1 if result.has_failures else 0


if __name__ == "__main__":
    sys.exit(main())
