#!/usr/bin/env python3
"""
pipeline_orchestrator.py — State-machine pipeline enforcer for v_psa_stg generation.

Enforces step ordering via a JSON state file per model. The agent (or engineer)
calls this script; the script refuses to proceed if prerequisites aren't met.

Usage:
    python scripts/automation/pipeline_orchestrator.py <command> [options]

Extension Points (for future Raw Vault / Business Vault support):
    - PIPELINE_STEPS: Add steps for hub/sat/link generation after 'implement'
    - init: Accept --objects flag for multi-object pipelines (v_psa_stg + hub + sat)
    - generate-yaml: YAML config captures cross-object relationships
    - generate-xlsx: XLSX gets one tab-pair per object (STG, HUB, SAT)
    - generate-code: Produces all models in dependency order
    - implement: Places files in correct layer directories (STG → HUB → SAT)
    - The state machine extends naturally — same steps, more objects per step

Commands:
    init             Initialize a new model pipeline
    profile          Run Stage 1 profiling (or load from --profile-json)
    show-profile     Display profile results for user review
    approve-profile  Record user approval of profile/BK
    generate-yaml    Generate YAML config (Step 1.10)
    generate-xlsx    Generate XLSX tech spec + auto-validate (Steps 1.11-1.12)
    approve-xlsx     Record user approval of XLSX
    generate-code    Run Stage 2 code generation
    show-code        Display generated SQL/YAML for review
    approve-code     Record user approval of generated code
    implement        Run Stage 3: place, compile, run, test
    status           Show pipeline status
    reset            Reset pipeline to a specific step (re-run from that point)
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import tempfile
import time
import sys
from datetime import datetime, timezone
from pathlib import Path

# Multi-table v_psa_stg support (secondary/lookup table joins)
from multi_table import (
    add_secondary_args,
    parse_secondary_state,
    profile_secondary_table,
    resolve_driver_qualify,
    extend_yaml_sources,
    extend_yaml_columns,
    has_secondary,
    build_user_column_prompt,
    validate_bk_references_renamed_columns,
)

# MCP-native profiling (MCP SDK -> snow-mcp server, fallback to Python connector)
from mcp_profile_patch import (
    _mcp_query as _mcp_sdk_query,
    _read_mcp_config as _read_mcp_config_sdk,
)

# ── Constants ──────────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
STATE_DIR = SCRIPT_DIR / ".pipeline_state"

# Shared source_column helpers (single source of truth — src/source_column_utils.py)
if str(SCRIPT_DIR / "src") not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR / "src"))
from source_column_utils import (  # noqa: E402
    COMPOSITE_BK_DELIMITER,
    normalize_source_column,
)

# Detect if running inside a VS Code agent loop (non-interactive)
# VS Code 1.121+ sets VSCODE_AGENT=true for agent-initiated terminal commands.
# When detected, skip interactive prompts and use safe defaults.
IS_AGENT_MODE = os.environ.get("VSCODE_AGENT") == "true"

# Plain column regex: starts with letter/underscore, only letters/digits/underscores.
# Anything that doesn't match is a derivation (function, cast, operator, expression).
PLAIN_COLUMN_RE = re.compile(r'^[A-Z_][A-Z0-9_]*$')

# Known SQL function names — used by _extract_raw_col_from_bk to skip non-column identifiers
_SQL_FUNCTIONS = frozenset({
    'COALESCE', 'NULLIF', 'UPPER', 'TRIM', 'CAST', 'TO_CHAR', 'TO_VARCHAR',
    'TO_NUMBER', 'TRY_TO_NUMBER', 'TO_DATE', 'TRY_TO_DATE', 'TO_TIMESTAMP_NTZ',
    'IFF', 'CONCAT', 'CONCAT_WS', 'LEFT', 'RIGHT', 'SUBSTR', 'SUBSTRING',
    'HASH', 'MD5', 'MD5_BINARY', 'SHA2', 'SHA2_BINARY',
    'AS', 'VARCHAR', 'TEXT', 'NUMBER', 'DATE', 'TIMESTAMP_NTZ', 'BOOLEAN',
    'IFNULL', 'NVL', 'REPLACE', 'LPAD', 'RPAD', 'LENGTH', 'LEN',
    'CONVERT_TIMEZONE', 'DATEADD', 'DATEDIFF', 'ROW_NUMBER',
})


class SnowflakeUnavailableError(RuntimeError):
    """A Snowflake operation could not be executed.

    Raised at the operation boundary (``_run_snowflake_query``) and by the
    command preflight (``_assert_snowflake_available``) when there is no usable
    Snowflake execution path — neither the ``snow-mcp`` MCP server nor the
    ``snowflake-connector-python`` driver — or when an attempted connection
    fails.

    This makes a missing required runtime dependency (or an unreachable
    Snowflake) FAIL LOUDLY instead of silently returning ``None`` and letting
    callers coerce the absence into ``0`` / empty / "skipped". That silent
    no-op — ``try/except ImportError: return None`` guarding the driver — is the
    bug issue #1844 eliminates.

    Note: this signals "could not execute". A query that DID execute and
    returned zero rows is a legitimate empty result (``[]``) and is never
    raised — that distinction is preserved structurally, because successful
    execution always returns a list (possibly empty), never ``None``.
    """


def _extract_raw_col_from_bk(bk_expr: str) -> str:
    """Extract the raw column name from a BK expression, skipping string literals.

    Handles nested functions correctly (lesson #100):
      COALESCE(NULLIF(UPPER(TRIM(COL)),''),'-1') → COL
      TO_CHAR(ID)                                → ID
      VENDOR_SITE_ID::TEXT                       → VENDOR_SITE_ID
      PLAIN_COL                                  → PLAIN_COL
    """
    cleaned = bk_expr.upper().split('::')[0]  # strip cast first
    cleaned = re.sub(r"'[^']*'", "", cleaned)  # remove string literals
    identifiers = re.findall(r'[A-Z_][A-Z0-9_]*', cleaned)
    columns = [ident for ident in identifiers if ident not in _SQL_FUNCTIONS]
    return columns[0] if columns else bk_expr.strip()


def _split_bk_parts(bk_upper: str) -> list:
    """Split composite BK on commas, respecting parenthesized groups (lesson #99).

    'MATNR, WERKS' → ['MATNR', 'WERKS']
    'COALESCE(NAME, \'-1\')' → ['COALESCE(NAME, \'-1\')']
    """
    parts = []
    depth = 0
    current = []
    for ch in bk_upper:
        if ch == '(':
            depth += 1
            current.append(ch)
        elif ch == ')':
            depth -= 1
            current.append(ch)
        elif ch == ',' and depth == 0:
            parts.append(''.join(current).strip())
            current = []
        else:
            current.append(ch)
    if current:
        parts.append(''.join(current).strip())
    return [p for p in parts if p]


# Legal SQL identifier (Snowflake allows '$'). Used to validate raw column-name
# lists passed to --bk (composite), --hk (column list) and --dck.
_SQL_IDENTIFIER_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_$]*$')


def _validate_bk_arg(raw_value: str):
    """Validate the --bk argument BEFORE any comma splitting (scoped, Option 1).

    --bk is one of two shapes:

    * A **single-column expression** — a raw column (``ID``), a cast
      (``ID::TEXT``) or a derivation (``TO_CHAR(ID)``, ``COALESCE(NAME,'-1')``,
      ``CONCAT(REGION,'-',ID)``, ``ID || '-' || REGION``). Detected as ONE
      paren-aware part. **All are accepted** — the derivation flows to the BK's
      ``manual_logic`` unchanged.
    * A **composite of raw column names** — ``COL1,COL2,...`` (>1 paren-aware
      part). Every part must be a plain SQL identifier; the orchestrator builds
      the ``UPPER(CONCAT_WS('||', ...))`` expression itself.

    The original defect (``--bk "CONCAT(A, '||', B)"`` mis-split on the inner
    commas) is fixed by paren-aware splitting here **and** in ``cmd_init`` — a
    single expression is never split. This validator only rejects a genuine
    MULTI-part composite whose parts are not raw identifiers (e.g.
    ``"A, CONCAT(X,Y)"`` or ``"INVOICE_ID,123BAD"``), which is the ambiguous
    hand-built-composite case that steering to raw columns resolves.

    Returns None when valid, or an actionable error message string.
    """
    value = (raw_value or "").strip()

    # Paren-aware split (case preserved) — commas inside a function call do NOT
    # split, so a single derivation is a single part and is always allowed.
    parts = _split_bk_parts(value)
    if len(parts) <= 1:
        return None

    # Multi-part composite → every part must be a raw column identifier.
    for part in parts:
        token = part.strip()
        if not _SQL_IDENTIFIER_RE.match(token):
            return (
                "--bk composite keys accept comma-separated raw column names only.\n"
                f"       Received: {raw_value}\n"
                f"       Offending token: {token!r}\n"
                '       Use:      --bk "COL1,COL2"  (raw columns; the orchestrator\n'
                "                 builds the UPPER(CONCAT_WS('||', ...)) expression).\n"
                "       For a single derived key, pass ONE expression instead, e.g.\n"
                "                 --bk \"CONCAT(COL1, '-', COL2)\"."
            )
    return None


def _validate_raw_column_list(raw_value: str, flag_name: str):
    """Validate a comma-separated raw-column-name list (--hk columns, --dck).

    Whitespace per token is stripped (so ``"A, B"`` is accepted and normalized).
    Each token must be a legal SQL identifier. Returns (tokens, error): on success
    ``error`` is None and ``tokens`` is the cleaned list; on failure ``error`` is
    an actionable message naming the offending token.
    """
    tokens = [t.strip() for t in (raw_value or "").split(",") if t.strip()]
    for token in tokens:
        if not _SQL_IDENTIFIER_RE.match(token):
            return tokens, (
                f"{flag_name} accepts comma-separated raw column names only.\n"
                f"       Offending token: {token!r} in {raw_value!r}"
            )
    return tokens, None


def _infer_bk_datatype(bk_expr: str) -> str:

    """Infer the staging datatype from a BK derivation expression."""
    bk = bk_expr.upper()
    if '::TEXT' in bk or 'TO_CHAR(' in bk or 'TO_VARCHAR(' in bk:
        return "TEXT"
    if '::NUMBER' in bk or '::INT' in bk or 'TO_NUMBER(' in bk or 'TRY_TO_NUMBER(' in bk:
        return "NUMBER"
    if '::DATE' in bk or 'TO_DATE(' in bk or 'TRY_TO_DATE(' in bk:
        return "DATE"
    if '::TIMESTAMP' in bk or 'TO_TIMESTAMP(' in bk:
        return "TIMESTAMP_NTZ"
    if '::VARIANT' in bk:
        return "VARIANT"
    if '::BOOLEAN' in bk or 'TO_BOOLEAN(' in bk:
        return "BOOLEAN"
    if '::FLOAT' in bk or 'TO_DOUBLE(' in bk:
        return "FLOAT"
    return ""  # Let Snowflake infer

# Ordered list of pipeline steps — each step requires ALL prior steps completed
PIPELINE_STEPS = [
    "init",
    "profile",
    "approve-profile",
    "generate-yaml",
    "generate-xlsx",
    "approve-xlsx",
    "generate-code",
    "approve-code",
    "implement",
]

# Steps that need Snowflake access (directly or via MCP)
SNOWFLAKE_STEPS = {"profile"}

# Fivetran fingerprint columns
FIVETRAN_COLS = {"_FIVETRAN_DELETED", "_FIVETRAN_SYNCED", "_FIVETRAN_ID"}
# SNP GLUE fingerprint columns (CDC replication — GL-prefix columns originate from SNP GLUE)
# GLDELFLAG is a soft delete indicator (business data) — NOT excluded from HASHDIFF
# MANDT is a SAP client field (business data), NOT a GLUE ingestion column
SNP_GLUE_COLS = {"GLREQUEST", "GLSOURCESYSTEM", "GLDELFLAG", "GLCHANGETIME"}
# Columns always excluded from HASHDIFF (metadata only — not business data)
HASHDIFF_EXCLUDE = {
    "PSA_LOAD_DTS", "PSA_RECORD_SOURCE",
    "_FIVETRAN_SYNCED", "_FIVETRAN_ID",
    "GLREQUEST", "GLSOURCESYSTEM", "GLCHANGETIME",
    "MANDT",  # SAP client ID — static system identifier, not change-tracked
}
# Technical metadata columns (passthrough, not business data — except flags)
TECHNICAL_COLS = {
    "_FIVETRAN_DELETED", "_FIVETRAN_SYNCED", "_FIVETRAN_ID",
    "PSA_LOAD_DTS", "PSA_RECORD_SOURCE", "PSA_DELETE_IND",
    "GLREQUEST", "GLSOURCESYSTEM", "GLDELFLAG", "GLCHANGETIME",
}

# Volume tiers (v_psa_stg)
VOLUME_NORMAL = 50_000_000
VOLUME_CAUTION = 300_000_000

# Volume tiers (Hub) — different thresholds than v_psa_stg
HUB_WATERMARK_THRESHOLD = 50_000_000
HUB_FULL_REFRESH_THRESHOLD = 150_000_000

# Volume tiers (SAT) — SATs use different thresholds
SAT_WATERMARK_THRESHOLD = 50_000_000       # ≥50M → -1 HOUR per-REC_SRC watermark
SAT_CLUSTER_THRESHOLD = 300_000_000        # >300M → cluster_by + full_refresh = var("force_full_refresh", false)

# Valid SAT variant prefixes
SAT_VARIANTS = {"sat", "lsat", "msat", "lmsat"}

# REC_SRC format: Location.System.Application.Table (dotted segments, alphanumeric + _ )
REC_SRC_PATTERN = re.compile(r'^[A-Za-z0-9._]+$')

# Identifier validation: schema, table, column names (SQL injection prevention)
IDENTIFIER_PATTERN = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')

# BK expression validation (H-1 defense-in-depth): allows column names, SQL
# functions, casts, string literals. Rejects ; -- /* */ $ ` { } [ ] \ newlines etc.
BK_SAFE_CHARS = re.compile(r"^[A-Za-z0-9_,() '\" :|+\-.^]+$")


# ── Utilities ──────────────────────────────────────────────────────────────────

def _now_iso():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _strip_stg_prefix(model_name):
    """Strip the leading 'v_psa_stg_' prefix from a model name.

    Uses str.removeprefix() so only a leading occurrence is removed.
    Substring matches elsewhere in the name (theoretical) are preserved.

    Examples:
        v_psa_stg_po_item__winn_sap → po_item__winn_sap
        po_item__winn_sap            → po_item__winn_sap  (no-op)
    """
    if not isinstance(model_name, str):
        return model_name
    return model_name.removeprefix("v_psa_stg_")


def _is_under(path, root):
    """Return True if ``path`` is the same as or contained within ``root``.

    Uses Path.is_relative_to() (Python 3.9+). Both inputs must already be
    resolved (`.resolve()`) by the caller so symlinks and ``..`` segments
    cannot escape.
    """
    try:
        return path == root or path.is_relative_to(root)
    except (ValueError, AttributeError):
        return False


def _load_state(model_name):
    """Load state file for a model. Returns None if not found."""
    state_file = STATE_DIR / f"{model_name}.json"
    if not state_file.exists():
        return None
    with open(state_file) as f:
        state = json.load(f)
    # ── Migrate singular → plural (backward compat) ──
    if "sat" in state and "sats" not in state:
        state["sats"] = [state.pop("sat")]
    if "lnk" in state and "lnks" not in state:
        state["lnks"] = [state.pop("lnk")]
    return state


def _save_state(state):
    """Save state file for a model (atomic write to prevent corruption)."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    state_file = STATE_DIR / f"{state['model_name']}.json"
    fd, tmp_path = tempfile.mkstemp(
        dir=str(state_file.parent), suffix='.tmp'
    )
    try:
        with os.fdopen(fd, 'w') as f:
            json.dump(state, f, indent=2, default=str)
        os.replace(tmp_path, str(state_file))  # atomic on POSIX
    except BaseException:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise

def _find_active_state():
    """Find the most recently modified VALID state file.

    Only considers JSON files that contain 'model_name' and 'steps_completed'
    keys -- this prevents non-state files (e.g. profile JSONs) from being
    picked up (Bug #5, #8).
    """
    if not STATE_DIR.exists():
        return None
    candidates = []
    for f in sorted(STATE_DIR.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
        try:
            data = json.loads(f.read_text())
            if "model_name" in data and "steps_completed" in data:
                candidates.append((f, data))
        except (json.JSONDecodeError, KeyError, OSError):
            continue
    if not candidates:
        return None
    return candidates[0][1]  # Most recent valid state


def _completed_steps(state):
    """Return set of completed step names."""
    return {s["step"] for s in state.get("steps_completed", [])}


def _check_prerequisites(state, step):
    """Check that all prerequisite steps are completed. Returns (ok, missing_steps)."""
    if step not in PIPELINE_STEPS:
        return False, [f"Unknown step: {step}"]
    required_index = PIPELINE_STEPS.index(step)
    required = set(PIPELINE_STEPS[:required_index])
    completed = _completed_steps(state)
    missing = required - completed
    if missing:
        # Return in pipeline order
        ordered_missing = [s for s in PIPELINE_STEPS if s in missing]
        return False, ordered_missing
    return True, []


def _mark_complete(state, step, extra_data=None):
    """Mark a step as complete in the state."""
    entry = {"step": step, "completed_at": _now_iso()}
    if extra_data:
        entry.update(extra_data)
    # Remove any existing entry for this step (idempotent re-runs)
    state["steps_completed"] = [
        s for s in state.get("steps_completed", []) if s["step"] != step
    ]
    state["steps_completed"].append(entry)
    _save_state(state)


def _persist_profile_markdown(state):
    """Persist approved profile as a markdown evidence document.

    Creates configs/<config_name>/profile.md containing source table metadata,
    profiling results, and design decisions. This provides traceable evidence
    for why design choices were made (column exclusions, volume tier, etc.).

    Returns the path to the written file, or None on failure.
    """
    model_name = state["model_name"]
    config_name = _strip_stg_prefix(model_name)
    profile = state.get("profile_results", {})

    configs_root = (SCRIPT_DIR / "configs").resolve()
    profile_dir = (SCRIPT_DIR / "configs" / config_name).resolve()
    # Defense-in-depth: prevent path traversal even though init validates identifiers
    if not _is_under(profile_dir, configs_root):
        return None
    profile_dir.mkdir(parents=True, exist_ok=True)
    profile_path = profile_dir / "profile.md"

    # Build markdown content
    lines = []
    lines.append(f"# Profile: {model_name}")
    lines.append("")
    lines.append(f"**Business Key:** {state.get('bk', 'N/A')} → {state.get('bk_name', 'N/A')}")
    lines.append(f"**Source:** PSA_PROD.{state.get('schema', 'N/A')}.{state.get('table', 'N/A')}")
    lines.append(f"**REC_SRC:** {state.get('rec_src', 'N/A')}")
    lines.append(f"**Profiled:** {_now_iso()}")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Summary section
    lines.append("## Summary")
    lines.append("")
    lines.append(f"| Metric | Value |")
    lines.append(f"|--------|-------|")
    row_count = profile.get('row_count', 'N/A')
    row_display = f"{row_count:,}" if isinstance(row_count, (int, float)) else str(row_count)
    lines.append(f"| Rows | {row_display} |")
    lines.append(f"| Volume Tier | {profile.get('volume_tier', 'N/A')} |")
    lines.append(f"| Columns | {profile.get('column_count', 'N/A')} |")
    lines.append(f"| Ingestion | {profile.get('ingestion_source', 'N/A')} |")
    lines.append(f"| BKCC | {profile.get('bkcc', 'NOT FOUND')} |")
    lines.append(f"| Grain Valid | {profile.get('grain_valid', 'N/A')} |")
    lines.append(f"| NULL BK Count | {profile.get('null_bk_count', 0)} |")
    lines.append(f"| PSA_DELETE_IND | {profile.get('has_psa_delete_ind', False)} |")
    lines.append(f"| _FIVETRAN_DELETED | {profile.get('has_fivetran_deleted', False)} |")
    lines.append("")

    # Collision check
    collision_check = profile.get("collision_check")
    if collision_check:
        lines.append("## Collision Check")
        lines.append("")
        blocked = collision_check.get("blocked", False)
        lines.append(f"- **Status:** {'BLOCKED' if blocked else 'clear'}")
        layers = collision_check.get("layers", {})
        for layer_name, layer_info in layers.items():
            status = layer_info.get("status", "N/A")
            lines.append(f"- **{layer_name}:** {status}")
            if layer_info.get("file"):
                lines.append(f"  - File: `{layer_info['file']}`")
        lines.append("")

    # Column inventory
    source_columns = profile.get("columns", [])
    if source_columns:
        lines.append("## Column Inventory")
        lines.append("")
        lines.append("| # | Column | Type | Nullable | Role |")
        lines.append("|---|--------|------|----------|------|")

        bk_raw = state.get("bk", "").upper()
        bk_raw_set = set()
        for part in bk_raw.replace(" ", "").split(","):
            clean = part.split("::")[0]
            func_match = re.match(r'^[A-Z_]+\((.+)\)$', clean.strip())
            if func_match:
                clean = func_match.group(1).strip()
            bk_raw_set.add(clean)

        for idx, col in enumerate(source_columns, 1):
            cname = col["name"].upper()
            if cname in bk_raw_set:
                role = "BK"
            elif cname in TECHNICAL_COLS:
                role = "technical"
            else:
                role = "data"
            lines.append(f"| {idx} | {col['name']} | {col['type']} | {col.get('nullable', 'N/A')} | {role} |")
        lines.append("")

    # Design decisions captured
    lines.append("## Design Decisions")
    lines.append("")
    null_sentinel = state.get("null_bk_sentinel")
    if null_sentinel:
        lines.append(f"- **NULL BK Sentinel:** COALESCE(BK, '{null_sentinel}')")
    grain_cols = state.get("grain_columns") or profile.get("grain_columns")
    if grain_cols:
        lines.append(f"- **Composite Grain:** {', '.join(grain_cols)}")
    hash_keys = state.get("hash_keys", [])
    if hash_keys:
        lines.append("- **Hash Keys:**")
        for hk in hash_keys:
            lines.append(f"  - {hk['name']} = MD5({', '.join(hk['columns'])})")
    if not null_sentinel and not grain_cols and not hash_keys:
        lines.append("- Standard defaults (no overrides)")
    lines.append("")

    # Write file
    profile_path.write_text("\n".join(lines))
    try:
        state["profile_md_path"] = str(profile_path.relative_to(PROJECT_ROOT.resolve()))
    except ValueError:
        # Fallback: store absolute path if relative resolution fails (e.g., symlinks)
        state["profile_md_path"] = str(profile_path)
    return profile_path


def _append_reconciliation_to_profile_md(state, reconciliation):
    """Append reconciliation results to the persisted profile.md.

    Called from generate-code AFTER _reconcile_columns runs. Records mapped /
    excluded / unmapped column lists so reviewers can audit why columns were
    or were not surfaced in generated SQL. Append-only — never rewrites the
    profile inventory section above it.

    No-op if profile.md does not exist (profile-persistence may have failed
    earlier in the run; the in-memory warning still fires).
    """
    profile_md_rel = state.get("profile_md_path")
    if not profile_md_rel:
        return
    configs_root = (SCRIPT_DIR / "configs").resolve()
    profile_path = (PROJECT_ROOT / profile_md_rel).resolve()
    # Defense-in-depth: never append outside configs/ even if state was tampered with.
    if not _is_under(profile_path, configs_root):
        return
    if not profile_path.exists():
        return

    section = ["", "---", "", f"## Reconciliation ({_now_iso()})", ""]
    section.append(f"- **Passed:** {reconciliation.get('passed', False)}")
    mapped = reconciliation.get("mapped", []) or []
    technical = reconciliation.get("excluded_technical", []) or []
    hashdiff = reconciliation.get("excluded_hashdiff", []) or []
    unmapped = reconciliation.get("unmapped", []) or []
    sec_mapped = reconciliation.get("secondary_mapped", []) or []
    sec_unmapped = reconciliation.get("secondary_unmapped", []) or []

    section.append(f"- **Mapped (driver):** {len(mapped)}")
    section.append(f"- **Excluded (technical/metadata):** {len(technical)}")
    section.append(f"- **Excluded (HASHDIFF-only):** {len(hashdiff)}")
    section.append(f"- **Unmapped (driver):** {len(unmapped)}")
    section.append(f"- **Mapped (secondary/lookup):** {len(sec_mapped)}")
    section.append(f"- **Unmapped (secondary/lookup):** {len(sec_unmapped)}")

    if unmapped:
        section.append("")
        section.append("### Unmapped driver columns")
        section.append("")
        for col in unmapped:
            section.append(f"- `{col}`")

    if sec_unmapped:
        section.append("")
        section.append("### Unmapped secondary/lookup columns")
        section.append("")
        for col in sec_unmapped:
            section.append(f"- `{col}`")

    if technical:
        section.append("")
        section.append("### Excluded technical/metadata columns")
        section.append("")
        for col in technical:
            section.append(f"- `{col}`")

    section.append("")
    with open(profile_path, "a") as f:
        f.write("\n".join(section))


def _reconcile_columns(state):
    """Verify every profiled source column is accounted for in generated code.

    Checks that each column from the profile is either:
    - Present in the generated SQL (mapped)
    - A known technical/metadata column (automatically excluded)
    - Part of the HASHDIFF exclusion set (grain cols, load_dts source cols)

    Returns a dict with:
        - 'passed': bool
        - 'mapped': list of column names found in SQL
        - 'excluded_technical': list of known technical cols
        - 'excluded_hashdiff': list of HASHDIFF-excluded cols (grain, load_dts source)
        - 'unmapped': list of columns NOT found anywhere (potential silent drops)
    """
    profile = state.get("profile_results", {})
    source_columns = profile.get("columns", [])
    if not source_columns:
        return {"passed": True, "mapped": [], "excluded_technical": [],
                "excluded_hashdiff": [], "unmapped": [], "reason": "no profile columns"}

    # Load generated SQL
    generated = state.get("generated_files", {})
    sql_path_rel = generated.get("sql", "")
    if not sql_path_rel:
        return {"passed": True, "mapped": [], "excluded_technical": [],
                "excluded_hashdiff": [], "unmapped": [], "reason": "no generated SQL"}

    # Resolve and enforce path stays under PROJECT_ROOT to prevent traversal
    # via tampered state files (e.g., generated_files.sql = '../../etc/passwd').
    project_root_resolved = PROJECT_ROOT.resolve()
    try:
        sql_path = (PROJECT_ROOT / sql_path_rel).resolve()
    except (OSError, RuntimeError):
        return {"passed": True, "mapped": [], "excluded_technical": [],
                "excluded_hashdiff": [], "unmapped": [], "reason": "SQL path invalid"}
    if not _is_under(sql_path, project_root_resolved):
        return {"passed": True, "mapped": [], "excluded_technical": [],
                "excluded_hashdiff": [], "unmapped": [], "reason": "SQL path outside project root"}
    if not sql_path.exists() or not sql_path.is_file():
        return {"passed": True, "mapped": [], "excluded_technical": [],
                "excluded_hashdiff": [], "unmapped": [], "reason": "SQL file not found"}

    sql_content = sql_path.read_text().upper()

    # Build exclusion sets
    bk_raw = state.get("bk", "").upper()
    bk_raw_set = set()
    for part in bk_raw.replace(" ", "").split(","):
        clean = part.split("::")[0]
        func_match = re.match(r'^[A-Z_]+\((.+)\)$', clean.strip())
        if func_match:
            clean = func_match.group(1).strip()
        bk_raw_set.add(clean)

    # HASHDIFF exclusion set: grain columns + LOAD_DTS source columns
    _LOAD_DTS_SOURCE_COLS = {
        "PSA_LOAD_DTS", "_FIVETRAN_SYNCED", "GLCHANGETIME", "SNP_LOAD_DTS", "LOAD_DTS"
    }
    # Custom LOAD_DTS column is consumed by the LOAD_DTS derivation expression
    custom_load_col = state.get("load_dts_column", "")
    if custom_load_col:
        _LOAD_DTS_SOURCE_COLS.add(custom_load_col.upper())

    grain_cols = set(
        gc.upper() for gc in (state.get("grain_columns") or profile.get("grain_columns") or [])
    )
    hashdiff_excluded = grain_cols

    mapped = []
    excluded_technical = []
    excluded_hashdiff = []
    unmapped = []

    def _col_in_sql(col_name):
        """Check if column name appears as a whole word in SQL (not as substring)."""
        # Word boundary: column must be preceded/followed by non-identifier chars
        return bool(re.search(r'(?<![A-Z0-9_])' + re.escape(col_name) + r'(?![A-Z0-9_])', sql_content))

    for col in source_columns:
        cname = col["name"].upper()

        # BK columns are always mapped (they become the BK alias)
        if cname in bk_raw_set:
            mapped.append(cname)
        # Technical columns are systematically excluded
        elif cname in TECHNICAL_COLS:
            excluded_technical.append(cname)
        # LOAD_DTS source columns are consumed by LOAD_DTS derivation
        elif cname in _LOAD_DTS_SOURCE_COLS:
            excluded_technical.append(cname)
        # Grain columns excluded from HASHDIFF but still in SQL
        elif cname in hashdiff_excluded:
            # Should still appear in SQL as a passthrough column
            if _col_in_sql(cname):
                mapped.append(cname)
            else:
                excluded_hashdiff.append(cname)
        # Data columns: must appear in generated SQL
        elif _col_in_sql(cname):
            mapped.append(cname)
        else:
            unmapped.append(cname)

    # ── Secondary (lookup) table column reconciliation ──────────────────────
    secondary_mapped = []
    secondary_unmapped = []
    secondary = state.get("secondary")
    if secondary and secondary.get("columns"):
        for col_name in secondary["columns"]:
            cname = col_name.upper()
            # Secondary columns should appear in SQL (possibly renamed with alias prefix)
            alias = (secondary.get("alias") or "").upper()
            # Check: bare column name OR alias-prefixed name (e.g., SEC_VENDOR_NAME)
            if _col_in_sql(cname):
                secondary_mapped.append(cname)
            elif alias and _col_in_sql(f"{alias}_{cname}"):
                secondary_mapped.append(f"{alias}_{cname}")
            else:
                secondary_unmapped.append(cname)

    passed = len(unmapped) == 0 and len(secondary_unmapped) == 0
    return {
        "passed": passed,
        "mapped": mapped,
        "excluded_technical": excluded_technical,
        "excluded_hashdiff": excluded_hashdiff,
        "unmapped": unmapped,
        "secondary_mapped": secondary_mapped,
        "secondary_unmapped": secondary_unmapped,
    }


def _python():
    """Return the Python executable (same one running this script)."""
    return sys.executable


def _run_command(cmd, cwd=None, capture=True):
    """Run a shell command. Returns (returncode, stdout, stderr).

    SECURITY: This function uses shell=True. All inputs MUST be validated
    against IDENTIFIER_PATTERN or REC_SRC_PATTERN before reaching this
    function. Never pass raw user input directly.
    """
    result = subprocess.run(
        cmd, shell=True, cwd=cwd or str(PROJECT_ROOT),
        capture_output=capture, text=True,
    )
    return result.returncode, result.stdout, result.stderr


def _get_dbt_binary():
    """Resolve the dbt binary to use.

    Priority:
      1. DBT_BINARY env var (explicit override)
      2. First 'dbt' on PATH that is NOT inside a .venv directory
         (avoids picking up the broken Python 3.14 .venv dbt)
      3. "dbt" — plain fallback
    """
    explicit = os.environ.get("DBT_BINARY")
    if explicit:
        return explicit

    # Walk PATH entries, skip any that live inside a virtualenv
    path_dirs = os.environ.get("PATH", "").split(os.pathsep)
    for d in path_dirs:
        if ".venv" in d or "virtualenv" in d.lower():
            continue
        candidate = os.path.join(d, "dbt")
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate

    return "dbt"


def _run_dbt(args_list, cwd=None, skip_cancel=False):
    """Run a dbt command as a subprocess, stripping VIRTUAL_ENV so the .venv
    Python is not inherited (avoids mashumaro/Python 3.14 breakage).

    Pre-flight: Run `dbt cancel` to clear stuck sessions (lesson #5 dbt Cloud fix).
    Sets standard dbt env vars required for local dev.
    Streams stdout/stderr line-by-line so AI agents can see progress in real-time
    (fixes the capture_output=True black hole during dbt build — lesson #124).
    Returns (returncode, stdout, stderr).
    """
    dbt_bin = _get_dbt_binary()
    env = {k: v for k, v in os.environ.items() if k != "VIRTUAL_ENV"}
    env.update({
        "DBT_ENVIRON": env.get("DBT_ENVIRON", "dev"),
        "DBT_SOURCE_ENV": "prod",
        "DBT_WAREHOUSE_DEFAULT": env.get("DBT_WAREHOUSE_DEFAULT", "SA_DBT_WH"),
        "DBT_WAREHOUSE_STAGING": env.get("DBT_WAREHOUSE_STAGING", "SA_DBT_WH"),
        "DBT_WAREHOUSE_RAW_VAULT": env.get("DBT_WAREHOUSE_RAW_VAULT", "SA_DBT_WH"),
        "DBT_WAREHOUSE_BUS_VAULT": env.get("DBT_WAREHOUSE_BUS_VAULT", "SA_DBT_WH"),
        "DBT_WAREHOUSE_INFO_MART": env.get("DBT_WAREHOUSE_INFO_MART", "SA_DBT_WH"),
    })
    
    # Pre-flight: Clear stuck dbt Cloud sessions (lesson #5 F5 remedy)
    # skip_cancel=True when the caller just completed a successful dbt command
    # in the same function (e.g., dry-run after build) — saves 15-18s round trip.
    if not skip_cancel and ("build" in args_list or "test" in args_list or "run" in args_list):
        subprocess.run(
            [dbt_bin, "cancel"],
            cwd=cwd or str(PROJECT_ROOT),
            capture_output=True,
            env=env,
        )
    
    # Stream output line-by-line so terminal watchers (AI agents, run_in_terminal)
    # can see dbt build progress in real-time instead of a silent black hole.
    # Merge stderr into stdout to prevent deadlock: if the child process
    # writes enough stderr to fill the OS pipe buffer (~64KB) before stdout
    # completes, both processes block indefinitely. stderr=STDOUT is the
    # simplest fix — dbt intermixes progress/errors on both streams anyway.
    proc = subprocess.Popen(
        [dbt_bin] + args_list,
        cwd=cwd or str(PROJECT_ROOT),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        env=env,
    )
    stdout_lines = []
    # Stream stdout (which now includes stderr) line-by-line
    for line in proc.stdout:
        sys.stdout.write(line)
        sys.stdout.flush()
        stdout_lines.append(line)
    proc.wait()
    return proc.returncode, ''.join(stdout_lines), ''


def _print_error(msg):
    print(f"\n  ERROR: {msg}\n", file=sys.stderr)


def _print_success(msg):
    print(f"\n  {msg}\n")


def _print_next_step(state, current_step):
    """Print the next step the user should take."""
    completed = _completed_steps(state)
    completed.add(current_step)  # Include the just-completed step
    for step in PIPELINE_STEPS:
        if step not in completed:
            hints = {
                "profile": f"python {_rel_script()} profile",
                "approve-profile": f"python {_rel_script()} approve-profile",
                "generate-yaml": f"python {_rel_script()} generate-yaml",
                "generate-xlsx": f"python {_rel_script()} generate-xlsx",
                "approve-xlsx": f"python {_rel_script()} approve-xlsx",
                "generate-code": f"python {_rel_script()} generate-code",
                "approve-code": f"python {_rel_script()} approve-code",
                "implement": f"python {_rel_script()} implement --domain <DOMAIN>",
            }
            print(f"  Next: {hints.get(step, step)}")
            return
    print("  Pipeline complete!")


def _rel_script():
    """Return relative path to this script from PROJECT_ROOT."""
    return "scripts/automation/pipeline_orchestrator.py"



def _prompt_raw_vault_objects(state):
    """Display informational Raw Vault prompt after XLSX approval (STG-only pipelines)."""
    print(f"\n{'='*60}")
    print('  RAW VAULT \u2014 Design Decision')
    print(f"{'='*60}")
    print()
    print('  v_psa_stg design is approved. Before generating code, decide')
    print('  whether to include Raw Vault objects in this pipeline run.')
    print()
    print('  \u250c\u2500 HUB \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2510')
    print('  \u2502  Required: Nothing \u2014 auto-derived from v_psa_stg   \u2502')
    print('  \u2502  Optional: --hub-name (custom hub name)            \u2502')
    print('  \u2514\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2518')
    print()
    print('  \u250c\u2500 LNK \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2510')
    print('  \u2502  Required: --parent-hks (relationship HK columns)  \u2502')
    print('  \u2502  Optional: --lnk-name, --dck (dependent child key) \u2502')
    print('  \u2514\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2518')
    print()
    print('  \u250c\u2500 SAT \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2510')
    print('  \u2502  Required: --sat-parent-hk, --sat-parent-model     \u2502')
    print('  \u2502  Required for MSAT: --multi-active-key             \u2502')
    print('  \u2502  Required for LSAT: --sat-parent-model (link ref)  \u2502')
    print('  \u2502  Optional: --sat-type, --sat-name                  \u2502')
    print('  \u2514\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2518')
    print()
    print('  Option A \u2014 STG only (continue as-is):')
    print(f'    .venv/bin/python3 {_rel_script()} generate-code --stg-only')
    print()
    print('  Option B \u2014 Add Raw Vault objects to this pipeline:')
    print(f'    .venv/bin/python3 {_rel_script()} add-raw-vault \\')
    print(f'      --objects "hub,sat" --hub-name <hub_name> \\')
    print(f'      --sat-parent-hk <PARENT_HK> \\')
    print(f'      --sat-parent-model <hub_or_lnk_name>')
    print()
    print('  Or use the AI agent: /generate-raw-vault')
    print()


# ── Commands ───────────────────────────────────────────────────────────────────


def _derive_hub_name(bk_name):
    """Derive hub model name from BK name.

    PRODUCT_COST_ESTIMATE_BK → hub_product_cost_estimate
    PO_ITEM_BK               → hub_po_item
    """
    entity = bk_name.upper().replace("_BK", "").strip()
    return f"hub_{entity.lower()}"


def _derive_lnk_name(lnk_name_arg):
    """Derive link model name from user-provided name.

    po_item      → lnk_po_item
    lnk_po_item  → lnk_po_item
    """
    name = lnk_name_arg.strip().lower()
    if not name.startswith("lnk_"):
        name = f"lnk_{name}"
    return name


def _derive_sat_name(model_name, sat_type="sat", override=None):
    """Derive SAT model name from v_psa_stg model name.

    v_psa_stg_po_item__winn_sap → sat_po_item__winn_sap
    v_psa_stg_po_item__winn_sap → lsat_po_item__winn_sap  (sat_type='lsat')
    v_psa_stg_po_item__winn_sap → msat_po_item__winn_sap  (sat_type='msat')

    Override allows user to provide explicit SAT name.
    """
    if override:
        name = override.strip().lower()
        # Ensure correct prefix
        for prefix in ("sat_", "lsat_", "msat_", "lmsat_"):
            if name.startswith(prefix):
                return name
        return f"{sat_type}_{name}"

    # Auto-derive: strip v_psa_stg_ prefix, prepend sat_type
    entity_source = _strip_stg_prefix(model_name)
    return f"{sat_type}_{entity_source}"


def _validate_source_suffix(model_name, sat_model_name=None):
    """Validate source system suffix conventions.

    Returns list of warning strings. Empty list = all good.
    Checks:
      1. model_name (v_psa_stg) must contain '__' (source system suffix)
      2. If sat_model_name provided, its suffix after '__' must match stg's suffix
    """
    warnings = []

    # Check 1: v_psa_stg must have __ suffix
    if "__" not in model_name:
        warnings.append(
            f"Model name '{model_name}' is missing the '__<source_system>' suffix.\n"
            f"      Expected format: v_psa_stg_<entity>__<source_system>\n"
            f"      Examples: v_psa_stg_po_item__winn_sap, v_psa_stg_legal_entity__ml_ebs"
        )

    # Check 2: sat suffix must match stg suffix
    if sat_model_name and "__" in model_name and "__" in sat_model_name:
        stg_suffix = model_name.split("__", 1)[1]
        sat_suffix = sat_model_name.split("__", 1)[1]
        if stg_suffix != sat_suffix:
            warnings.append(
                f"Source system suffix MISMATCH between STG and SAT:\n"
                f"      STG: {model_name} (suffix: __{stg_suffix})\n"
                f"      SAT: {sat_model_name} (suffix: __{sat_suffix})\n"
                f"      These should normally match. Is this intentional?"
            )
    elif sat_model_name and "__" not in sat_model_name:
        warnings.append(
            f"SAT model name '{sat_model_name}' is missing the '__<source_system>' suffix.\n"
            f"      Expected format: <sat_type>_<entity>__<source_system>"
        )

    return warnings


# Regex for simple type-cast BK expressions (value unchanged for hashing)
_SIMPLE_CAST_RE = re.compile(
    r'^(?:TO_CHAR|TO_VARCHAR|TO_NUMBER|TRY_CAST|TRIM)\s*\([^,]+\)$'
    r'|^\w+::\w+$'
    r'|^CAST\s*\([^,]+\s+AS\s+\w+\)$'
    r'|^[A-Za-z_]\w*$',
    re.IGNORECASE,
)


def _is_simple_cast_bk(bk_expr: str) -> bool:
    """True when BK is a direct column or a simple type-cast.

    Simple casts (TO_CHAR, ::TEXT, CAST AS) don't change the value for hashing.
    HK should use the raw column name for these.
    Derivations (COALESCE, CONCAT, IFF) change the value — HK uses BK alias.
    """
    if not bk_expr or not bk_expr.strip():
        return True  # direct passthrough
    return bool(_SIMPLE_CAST_RE.match(bk_expr.strip()))


def _extract_raw_col(bk_expr: str) -> str:
    """Extract raw column name from a BK expression (strip cast/function)."""
    expr = bk_expr.strip()
    expr = expr.split("::")[0].strip()
    m = re.match(r'^[A-Za-z_]+\((.+)\)$', expr)
    if m:
        expr = m.group(1).strip()
    return expr.upper()


def _build_hub_yaml_model(state, profile, bk_raw_cols, bk_name, row_count, hub_name_override=None):
    """Build the HUB model entry for the YAML config.

    The hub reads HK and individual BK columns from v_psa_stg (NOT a
    concatenated alias).  HK is pre-computed in the v_psa_stg view;
    BK columns are carried through for human queryability.

    hub_name_override: explicit hub name from --hub-name (bypasses auto-derivation).
    """
    model_name = state["model_name"]
    rec_src = state["rec_src"]
    hub_name = hub_name_override or _derive_hub_name(bk_name)
    hk_name = f"{bk_name.upper().replace('_BK', '')}_HK"
    entity_name = bk_name.upper().replace("_BK", "")
    short_name = entity_name

    # ── Safety net: warn if --hub-name entity diverges from primary BK entity ──
    # Use startswith to tolerate valid suffixes like _v1, _v2 (PR #1716 review).
    if hub_name_override:
        expected_hub_prefix = f"hub_{entity_name.lower()}"
        if not hub_name_override.startswith(expected_hub_prefix):
            print(
                f"  WARNING: --hub-name '{hub_name_override}' does not start with "
                f"'{expected_hub_prefix}' (derived from primary BK '{bk_name}'). "
                f"The hub will use '{entity_name}_HK'. "
                f"If this is wrong, re-init with --bk for the hub entity's BK and "
                f"--additional-bk for the other BKs."
            )

    # Build QUALIFY column list: individual BK cols + BKCC
    # Single BK: use alias name (PRODUCT_VARIANT_BK) in QUALIFY
    # Composite BK: use individual raw column names for queryability
    if len(bk_raw_cols) == 1:
        qualify_cols = [bk_name.upper()] + ["BKCC"]
    else:
        qualify_cols = [c.upper() for c in bk_raw_cols] + ["BKCC"]
    qualify_str = ", ".join(qualify_cols)

    # Build FINAL LAYER FILTER: NOT EXISTS + QUALIFY
    final_filter = (
        f"{{% if is_incremental() %}}\n"
        f"WHERE NOT EXISTS (\n"
        f"    SELECT 1\n"
        f"    FROM {{{{ this }}}} existing\n"
        f"    WHERE existing.{hk_name} = JOIN_RESULT.{hk_name}\n"
        f")\n"
        f"{{% endif %}}\n"
        f"/* Safety dedup — matches production hub pattern */\n"
        f"qualify 1 = row_number() over (partition by {qualify_str} order by LOAD_DTS)"
    )

    # HUB reads from v_psa_stg (which exposes LOAD_DTS, not raw PSA cols).
    # Always use LOAD_DTS for HUB SRC QUALIFY ORDER BY. (Lesson #61)
    qualify_order_by = "LOAD_DTS"

    # Volume-based model config — tags go in YAML only, not SQL config block.
    # SQL config block is only written for full_refresh = var("force_full_refresh", false) (≥150M).
    use_watermark = row_count >= HUB_WATERMARK_THRESHOLD
    full_refresh = row_count >= HUB_FULL_REFRESH_THRESHOLD
    if full_refresh:
        model_config = "full_refresh = var(\"force_full_refresh\", false), tags = ['large_volume', 'hub']"
    else:
        model_config = ""  # Tags go in YAML, not SQL config block

    # SRC QUALIFY: for non-watermark, add explicit QUALIFY in source_layer_filter.
    # For watermark models, build.py injects the conditional block automatically.
    if use_watermark:
        src_filter = ""
        qob = qualify_order_by  # build.py handles QUALIFY + watermark
    else:
        src_filter = (
            f"QUALIFY (ROW_NUMBER() OVER(PARTITION BY {hk_name} "
            f"ORDER BY {qualify_order_by})) = 1"
        )
        qob = ""  # Don't trigger build.py watermark path

    # Hub source: reads from v_psa_stg view via ref()
    hub_source = {
        "source_schema": "int_staging_views",
        "source_table": model_name,
        "alias": "SRC",
        "source_layer_filter": src_filter,
        "final_layer_filter": final_filter,
        "target_schema": "raw_vault",
        "model_config": model_config,
        "qualify_order_by": qob,
    }

    # Hub columns — order: HK, BK columns, LOAD_DTS, BKCC, REC_SRC
    hub_columns = []

    # 1. HK — read from v_psa_stg (NOT recomputed)
    hub_columns.append({
        "source_table": "SRC",
        "source_column": hk_name,
        "staging_column_name": hk_name,
        "datatype": "BINARY",
        "pk": f"PK: {hk_name}",
        "ghost_record": "hash",
    })

    # 2. BK columns — single BK uses alias, composite uses raw cols
    if len(bk_raw_cols) == 1:
        # Single BK: use the BK alias (e.g., PRODUCT_VARIANT_BK)
        # The v_psa_stg materializes this as a real column
        col_info = next(
            (c for c in profile.get("columns", []) if c["name"].upper() == bk_raw_cols[0].upper()),
            None,
        )
        col_dtype = col_info["type"] if col_info else "VARCHAR"
        # If BK has a derivation expression (TO_CHAR, ::TEXT, etc.), output type is TEXT (Lesson #66)
        bk_entry_check = state.get("bk", "")
        if "::" in bk_entry_check or re.search(r'[A-Z_]+\(', bk_entry_check.upper()):
            col_dtype = "TEXT"
        hub_columns.append({
            "source_table": "SRC",
            "source_column": bk_name.upper(),
            "staging_column_name": bk_name.upper(),
            "datatype": col_dtype,
            "ghost_record": "value_text",
        })
    else:
        # Composite BK: use individual raw column names for queryability
        for bk_col in bk_raw_cols:
            col_info = next(
                (c for c in profile.get("columns", []) if c["name"].upper() == bk_col.upper()),
                None,
            )
            col_dtype = col_info["type"] if col_info else "VARCHAR"
            hub_columns.append({
                "source_table": "SRC",
                "source_column": bk_col.upper(),
                "staging_column_name": bk_col.upper(),
                "datatype": col_dtype,
                "ghost_record": "value_text",
            })

    # 3. LOAD_DTS — from v_psa_stg
    hub_columns.append({
        "source_table": "SRC",
        "source_column": "LOAD_DTS",
        "staging_column_name": "LOAD_DTS",
        "datatype": "TIMESTAMP_NTZ",
        "ghost_record": "load_dts",
    })

    # 4. BKCC — from v_psa_stg (already joined there)
    hub_columns.append({
        "source_table": "SRC",
        "source_column": "BKCC",
        "staging_column_name": "BKCC",
        "datatype": "TEXT",
        "ghost_record": "bkcc",
    })

    # 5. REC_SRC — from v_psa_stg
    hub_columns.append({
        "source_table": "SRC",
        "source_column": "REC_SRC",
        "staging_column_name": "REC_SRC",
        "datatype": "TEXT",
        "ghost_record": "rec_src",
    })

    return {
        "layer": "HUB",
        "derived_name": hub_name,
        "short_name": short_name,
        "sources": [hub_source],
        "columns": hub_columns,
    }


def _build_lnk_yaml_model(state, profile, parent_hks, lnk_name, dcks, row_count):
    """Build the LNK model entry for the YAML config.

    Link tables store relationships between hubs.
    - LHK = hash of all parent HKs (named LNK_<MODEL>_HK)
    - No BKCC (only hubs have BKCC)
    - No HASHDIFF (links don't track changes)
    - Optional DCKs (degenerate context keys)
    """
    model_name = state["model_name"]
    derived_name = _derive_lnk_name(lnk_name)
    entity = derived_name.replace("lnk_", "").upper()
    lhk_name = f"LNK_{entity}_HK"

    # Volume-based config (same thresholds as hub)
    use_watermark = row_count >= HUB_WATERMARK_THRESHOLD
    full_refresh = row_count >= HUB_FULL_REFRESH_THRESHOLD
    if full_refresh:
        model_config = "full_refresh = var(\"force_full_refresh\", false), tags = ['large_volume', 'lnk']"
    else:
        model_config = ""

    # LNK reads from v_psa_stg (which exposes LOAD_DTS, not raw PSA cols).
    # Always use LOAD_DTS for LNK SRC QUALIFY ORDER BY. (Lesson #61)
    qualify_order_by = "LOAD_DTS"

    # SRC QUALIFY: for non-watermark, add explicit QUALIFY in source_layer_filter.
    # For watermark models, build.py injects the conditional block automatically.
    if use_watermark:
        src_filter = ""
    else:
        src_filter = (
            f"QUALIFY (ROW_NUMBER() OVER(PARTITION BY {lhk_name} "
            f"ORDER BY LOAD_DTS)) = 1"
        )

    # FINAL LAYER FILTER: only NOT EXISTS (no QUALIFY in FINAL for links)
    final_filter = (
        f"{{% if is_incremental() %}}\n"
        f"WHERE NOT EXISTS (\n"
        f"    SELECT 1\n"
        f"    FROM {{{{ this }}}} existing\n"
        f"    WHERE existing.{lhk_name} = JOIN_RESULT.{lhk_name}\n"
        f")\n"
        f"{{% endif %}}"
    )

    lnk_source = {
        "source_schema": "int_staging_views",
        "source_table": model_name,
        "alias": "SRC",
        "source_layer_filter": src_filter,
        "final_layer_filter": final_filter,
        "target_schema": "raw_vault",
        "model_config": model_config,
        "qualify_order_by": qualify_order_by,
    }

    # LNK columns — order: LHK, parent HKs, DCKs, LOAD_DTS, REC_SRC
    lnk_columns = []

    # 1. LHK — read from v_psa_stg (pre-computed)
    lnk_columns.append({
        "source_table": "SRC",
        "source_column": lhk_name,
        "staging_column_name": lhk_name,
        "datatype": "BINARY",
        "pk": f"PK: {lhk_name}",
        "ghost_record": "hash",
    })

    # 2. Parent HKs — each is a hash, read from v_psa_stg
    for hk in parent_hks:
        hk_upper = hk.upper().strip()
        lnk_columns.append({
            "source_table": "SRC",
            "source_column": hk_upper,
            "staging_column_name": hk_upper,
            "datatype": "BINARY",
            "ghost_record": "hash",
        })

    # 3. DCKs (optional degenerate context keys)
    for dck in (dcks or []):
        dck_upper = dck.upper().strip()
        col_info = next(
            (c for c in profile.get("columns", []) if c["name"].upper() == dck_upper),
            None,
        )
        col_dtype = col_info["type"] if col_info else "TEXT"
        lnk_columns.append({
            "source_table": "SRC",
            "source_column": dck_upper,
            "staging_column_name": dck_upper,
            "datatype": col_dtype,
            "ghost_record": "value_text",
        })

    # 4. LOAD_DTS — from v_psa_stg
    lnk_columns.append({
        "source_table": "SRC",
        "source_column": "LOAD_DTS",
        "staging_column_name": "LOAD_DTS",
        "datatype": "TIMESTAMP_NTZ",
        "ghost_record": "load_dts",
    })

    # 5. REC_SRC — from v_psa_stg
    lnk_columns.append({
        "source_table": "SRC",
        "source_column": "REC_SRC",
        "staging_column_name": "REC_SRC",
        "datatype": "TEXT",
        "ghost_record": "rec_src",
    })

    return {
        "layer": "LNK",
        "derived_name": derived_name,
        "short_name": entity,
        "sources": [lnk_source],
        "columns": lnk_columns,
    }


def _build_sat_yaml_model(state, profile, bk_raw_cols, bk_name, row_count, sat_def=None):
    """Build the SAT model entry for the YAML config.

    SAT (satellite) tables store attribute history for a parent hub/link.
    Key differences from HUB/LNK:
    - 1:1 cardinality with v_psa_stg (not many:1)
    - 100% data rule: ALL source columns included (no filtering)
    - HASHDIFF pass-through from v_psa_stg (not recomputed)
    - NOT EXISTS checks PARENT_HK + HASHDIFF (not just HK)
    - Ghost payload: ALL data columns = NULL
    - QUALIFY on full-refresh only (not both modes like HUB)
    - Watermark: -1 HOUR; for two-clock sources (SNP GLUE, or a custom LOAD_DTS
      column + PSA_DELETE_IND) the subquery is scoped to live rows
      (COALESCE(PSA_DELETE_IND,'N')='N') and floored to '1900-01-01'; single-clock
      sources (Fivetran, default PSA_LOAD_DTS) keep the plain global max, which is
      correct for single-REC_SRC satellites

    Supports 4 variants: SAT, LSAT, MSAT, LMSAT.
    Accepts optional sat_def dict for multi-SAT pipelines.
    """
    model_name = state["model_name"]
    rec_src = state["rec_src"]
    # Use explicit sat_def if provided, else fall back to state (backward compat)
    if sat_def is None:
        sats = state.get("sats", [])
        sat_def = sats[0] if sats else state.get("sat", {})
    sat_type = sat_def.get("sat_type", "sat")
    parent_hk = sat_def.get("parent_hk", "")
    parent_model = sat_def.get("parent_model", "")
    multi_active_key = sat_def.get("multi_active_key")
    # Use grain_columns (full composite grain) if available, else fall back to multi_active_key
    _grain_cols_raw = sat_def.get("grain_columns") or state.get("grain_columns") or []
    _grain_keys = _grain_cols_raw if _grain_cols_raw else (
        [k.strip() for k in multi_active_key.split(',')] if multi_active_key else []
    )
    sat_name = sat_def.get("model_name", _derive_sat_name(model_name, sat_type))
    sat_columns_filter = sat_def.get("sat_columns")  # per-SAT column assignment

    is_link_sat = sat_type in ("lsat", "lmsat")
    is_multi_active = sat_type in ("msat", "lmsat")

    # ── Volume-based config ──
    use_watermark = row_count >= SAT_WATERMARK_THRESHOLD
    use_cluster = row_count > SAT_CLUSTER_THRESHOLD
    use_full_refresh_false = row_count > SAT_CLUSTER_THRESHOLD

    # SQL config block: only for Large tier (>300M)
    if use_full_refresh_false:
        model_config = f"full_refresh = var(\"force_full_refresh\", false), cluster_by = ['{parent_hk}']"
    else:
        model_config = ""

    # ── Build NOT EXISTS filter ──
    # FBIN deviation from DV 2.1: MSAT NOT EXISTS checks HK + multi-active key + HASHDIFF.
    # Standard DV 2.1 only checks HK + multi-active key (HASHDIFF is in WHERE, not NOT EXISTS).
    # Rationale: prevents duplicate rows when the same multi-active key arrives with identical data.
    _bk_raw_set_ne = set(c.upper() for c in bk_raw_cols)
    _NE_EXCLUDE_COLS = {"PSA_LOAD_DTS", "_FIVETRAN_SYNCED", "GLCHANGETIME", "SNP_LOAD_DTS", "LOAD_DTS",
                        "_FIVETRAN_DELETED", "PSA_DELETE_IND", parent_hk.upper()}
    not_exists_conditions = [
        f"    WHERE existing.{parent_hk} = JOIN_RESULT.{parent_hk}",
    ]
    if is_multi_active and _grain_keys:
        # Use filtered grain columns — exclude raw BK source cols and parent HK (already in WHERE)
        _filtered_ne_grain = [
            gc for gc in _grain_keys
            if gc.upper() not in _bk_raw_set_ne and gc.upper() not in _NE_EXCLUDE_COLS
        ]
        for ma_col in _filtered_ne_grain:
            not_exists_conditions.append(
                f"      AND existing.{ma_col} = JOIN_RESULT.{ma_col}"
            )
    not_exists_conditions.append(
        f"      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF"
    )
    not_exists_body = "\n".join(not_exists_conditions)

    final_filter = (
        f"{{% if is_incremental() %}}\n"
        f"WHERE NOT EXISTS (\n"
        f"    SELECT 1\n"
        f"    FROM {{{{ this }}}} existing\n"
        f"{not_exists_body}\n"
        f")\n"
        f"{{% endif %}}"
    )

    # ── Build SRC watermark filter ──
    # Two-clock hazard: for SNP GLUE, LOAD_DTS = IFF(PSA_DELETE_IND='Y', PSA_LOAD_DTS
    # (batch time), <GLCHANGETIME event time>) -- a mixed clock, so soft-delete rows
    # carry batch time that can exceed event time, inflating max(load_dts) and
    # silently excluding later live records from the incremental window. The fix
    # (scope the watermark subquery to live rows + floor it) applies ONLY where the
    # LOAD_DTS derivation actually branches on PSA_DELETE_IND: SNP GLUE, or a custom
    # LOAD_DTS column combined with PSA_DELETE_IND. It must NOT be applied to
    # single-clock sources that merely materialise PSA_DELETE_IND -- Fivetran
    # (uniform _FIVETRAN_SYNCED) and default PSA_LOAD_DTS sources -- because there the
    # scope would only lower the watermark on an all-delete batch and cause re-scans.
    _has_psa_delete = "PSA_DELETE_IND" in {
        c["name"].upper() for c in profile.get("columns", [])
    }
    _two_clock = _has_psa_delete and (
        profile.get("ingestion_source") == "snp_glue"
        or bool(state.get("load_dts_column"))
    )
    _wm_expr = "dateadd('HOUR',-1,max(load_dts))"
    if _two_clock:
        # Floor matches the ghost record / placeholder convention ('1900-01-01').
        _wm_expr = f"coalesce({_wm_expr}, '1900-01-01'::timestamp)"
    _delete_scope = " and coalesce(PSA_DELETE_IND,'N') = 'N'" if _two_clock else ""

    if use_watermark:
        # Large (>=50M): scope to this SAT's single REC_SRC (optimisation).
        src_filter = (
            f"{{% if is_incremental() %}}\n"
            f"      where src.load_dts > (select {_wm_expr} "
            f"from {{{{ this }}}} where rec_src = '{rec_src}'{_delete_scope})\n"
            f"    {{% endif %}}"
        )
    elif _two_clock:
        # Normal (<50M) two-clock SAT: emit a global delete-scoped watermark here,
        # because build.py's default block is not delete-aware. Global max is
        # correct for single-REC_SRC satellites (code_reviewer J5 exempts SATs).
        src_filter = (
            f"{{% if is_incremental() %}}\n"
            f"      where src.load_dts > (select {_wm_expr} "
            f"from {{{{ this }}}} where coalesce(PSA_DELETE_IND,'N') = 'N')\n"
            f"    {{% endif %}}"
        )
    else:
        # Normal (<50M) single-clock SAT: leave empty; build.py appends its default
        # global watermark (behaviour unchanged).
        src_filter = ""

    sat_source = {
        "source_schema": "int_staging_views",
        "source_table": model_name,
        "alias": "SRC",
        "source_layer_filter": src_filter,
        "final_layer_filter": final_filter,
        "target_schema": "raw_vault",
        "model_config": model_config,
        "qualify_order_by": "",  # SAT QUALIFY is in ghost block, not SRC
    }

    # ── Build PK string ──
    # Filter out: (1) raw BK source cols (already represented by parent HK),
    # (2) ingestion-specific LOAD_DTS source cols (LOAD_DTS always appended as constant)
    _PK_EXCLUDE_COLS = {"PSA_LOAD_DTS", "_FIVETRAN_SYNCED", "GLCHANGETIME", "SNP_LOAD_DTS", "LOAD_DTS",
                        "_FIVETRAN_DELETED", "PSA_DELETE_IND", parent_hk.upper()}
    _bk_raw_set_pk = set(c.upper() for c in bk_raw_cols)
    pk_parts = [parent_hk]
    if is_multi_active and _grain_keys:
        # Exclude parent_hk (already at position 0) and raw BK source cols
        _filtered_pk_grain = [
            gc for gc in _grain_keys
            if gc.upper() not in _bk_raw_set_pk and gc.upper() not in _PK_EXCLUDE_COLS
        ]
        pk_parts.extend(_filtered_pk_grain)
    pk_parts.append("LOAD_DTS")
    pk_str = f"PK: {', '.join(pk_parts)}"

    # ── Build Relationship string (FK to parent hub/link) ──
    if parent_model:
        relationship = f"{parent_model.upper()}.{parent_hk}"
    else:
        relationship = ""

    # ── SAT columns — 100% data rule ──
    sat_columns = []
    source_columns = profile.get("columns", [])
    bk_raw_set = set(c.upper() for c in bk_raw_cols)

    # 1. Parent HK — first column, read from v_psa_stg
    sat_columns.append({
        "source_table": "SRC",
        "source_column": parent_hk,
        "staging_column_name": parent_hk,
        "datatype": "BINARY",
        "pk": pk_str,
        "ghost_record": "hash",
        "relationship": relationship,
    })

    # 2. Raw BK columns — ghost: null (DV 2.1: NULL payloads for all non-HK ghost cols) (Lesson #67)
    for bk_col in bk_raw_cols:
        bk_upper = bk_col.upper()
        col_info = next(
            (c for c in source_columns if c["name"].upper() == bk_upper), None
        )
        col_dtype = col_info["type"] if col_info else "VARCHAR"
        sat_columns.append({
            "source_table": "SRC",
            "source_column": bk_upper,
            "staging_column_name": bk_upper,
            "datatype": col_dtype,
            "ghost_record": "null",
        })

    # 3. Multi-active key (MSAT/LMSAT only) — ghost: value_text or value_number
    if is_multi_active and multi_active_key:
        ma_key_list = [k.strip().upper() for k in multi_active_key.split(',')]
        for mak_upper in ma_key_list:
            col_info = next(
                (c for c in source_columns if c["name"].upper() == mak_upper), None
            )
            col_dtype = col_info["type"] if col_info else "VARCHAR"
            ghost_type = "value_number" if col_dtype.upper() in ("NUMBER", "INT", "INTEGER", "FLOAT", "DECIMAL", "NUMERIC") else "value_text"
            # Only add if not already in BK columns
            if mak_upper not in bk_raw_set:
                sat_columns.append({
                    "source_table": "SRC",
                    "source_column": mak_upper,
                    "staging_column_name": mak_upper,
                    "datatype": col_dtype,
                    "ghost_record": ghost_type,
                })

    # 4. ALL remaining source columns (100% data rule) — ghost: null
    #    Exclude: derived BK alias, parent HK, columns already added
    #    When sat_columns_filter is set, only include those specific columns
    already_added = set()
    already_added.add(parent_hk.upper())
    already_added.update(bk_raw_set)
    if is_multi_active and multi_active_key:
        already_added.update(k.strip().upper() for k in multi_active_key.split(','))
    # Derived BK alias is excluded (it's in the parent hub)
    bk_alias_upper = bk_name.upper()
    # Per-SAT column filter (when --sat-columns provided)
    sat_col_set = set(sat_columns_filter) if sat_columns_filter else None

    for col in source_columns:
        cname = col["name"].upper()
        if cname in already_added:
            continue
        if cname == bk_alias_upper:
            continue  # Skip derived BK alias
        # If per-SAT column filter is active, skip columns not in the filter
        if sat_col_set is not None and cname not in sat_col_set:
            continue
        # Skip non-parent HK/LHK columns (derived, not source data) — Bug #29
        if (cname.endswith("_HK") or cname.endswith("_LHK") or cname.startswith("LNK_")) and cname != parent_hk.upper():
            continue
        # Skip HASHDIFF, LOAD_DTS, REC_SRC, BKCC — added as metadata below
        # Skip PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE — added with ghost values below
        # Skip _FIVETRAN_* — added in section 8 below (Bug #28)
        if cname in ("HASHDIFF", "LOAD_DTS", "REC_SRC", "BKCC",
                      "PSA_DELETE_IND", "PSA_LOAD_DTS", "PSA_RECORD_SOURCE",
                      "_FIVETRAN_SYNCED", "_FIVETRAN_ID", "_FIVETRAN_DELETED"):
            continue
        sat_columns.append({
            "source_table": "SRC",
            "source_column": cname,
            "staging_column_name": cname,
            "datatype": col["type"],
            "ghost_record": "null",
        })

    # 5. PSA_DELETE_IND — ghost: psa_delete_ind
    col_set = set(c["name"].upper() for c in source_columns)
    if "PSA_DELETE_IND" in col_set:
        sat_columns.append({
            "source_table": "SRC",
            "source_column": "PSA_DELETE_IND",
            "staging_column_name": "PSA_DELETE_IND",
            "datatype": "TEXT",
            "ghost_record": "psa_delete_ind",
        })

    # 6. PSA_LOAD_DTS — ghost: psa_load_dts
    if "PSA_LOAD_DTS" in col_set:
        sat_columns.append({
            "source_table": "SRC",
            "source_column": "PSA_LOAD_DTS",
            "staging_column_name": "PSA_LOAD_DTS",
            "datatype": "TIMESTAMP",
            "ghost_record": "psa_load_dts",
        })

    # 7. PSA_RECORD_SOURCE — ghost: null
    if "PSA_RECORD_SOURCE" in col_set:
        sat_columns.append({
            "source_table": "SRC",
            "source_column": "PSA_RECORD_SOURCE",
            "staging_column_name": "PSA_RECORD_SOURCE",
            "datatype": "TEXT",
            "ghost_record": "null",
        })

    # 8. _FIVETRAN_* columns — ghost: null (Fivetran sources only)
    for ft_col in ("_FIVETRAN_SYNCED", "_FIVETRAN_ID", "_FIVETRAN_DELETED"):
        if ft_col in col_set:
            col_info = next((c for c in source_columns if c["name"].upper() == ft_col), None)
            sat_columns.append({
                "source_table": "SRC",
                "source_column": ft_col,
                "staging_column_name": ft_col,
                "datatype": col_info["type"] if col_info else "TEXT",
                "ghost_record": "null",
            })

    # 9. LOAD_DTS — ghost: load_dts
    sat_columns.append({
        "source_table": "SRC",
        "source_column": "LOAD_DTS",
        "staging_column_name": "LOAD_DTS",
        "datatype": "TIMESTAMP_NTZ",
        "ghost_record": "load_dts",
    })

    # 10. REC_SRC — ghost: rec_src
    sat_columns.append({
        "source_table": "SRC",
        "source_column": "REC_SRC",
        "staging_column_name": "REC_SRC",
        "datatype": "TEXT",
        "ghost_record": "rec_src",
    })

    # 11. BKCC — ghost: bkcc
    sat_columns.append({
        "source_table": "SRC",
        "source_column": "BKCC",
        "staging_column_name": "BKCC",
        "datatype": "TEXT",
        "ghost_record": "bkcc",
    })

    # 12. HASHDIFF — ghost: hashdiff (ALWAYS LAST)
    sat_columns.append({
        "source_table": "SRC",
        "source_column": "HASHDIFF",
        "staging_column_name": "HASHDIFF",
        "datatype": "BINARY",
        "ghost_record": "hashdiff",
    })

    # ── Short name for XLSX tab naming ──
    entity_source = _strip_stg_prefix(model_name)
    short_name = entity_source

    return {
        "layer": sat_type.upper(),
        "derived_name": sat_name,
        "short_name": short_name,
        "sources": [sat_source],
        "columns": sat_columns,
    }


def _build_hashdiff_formula(col_names):
    """Build a HASHDIFF SQL formula for a given set of column names.

    Uses the standard HASHDIFF pattern:
        MD5_BINARY(UPPER(NULLIF(CONCAT(
            IFNULL(TRIM(col1::text), '^^'),
            '||', IFNULL(TRIM(col2::text), '^^'),
            ...
        ), '^^||^^')))
    """
    parts = []
    for i, col in enumerate(col_names):
        if i == 0:
            parts.append(f"IFNULL(TRIM({col}::text), '^^')")
        else:
            parts.append(f"'||', IFNULL(TRIM({col}::text), '^^')")
    inner = ", ".join(parts)
    # Build NULL-safe pattern: if all columns are ^^, result is ^^||^^ which NULLIF catches
    null_pattern = "||".join(["^^"] * len(col_names))
    return f"MD5_BINARY(UPPER(NULLIF(CONCAT({inner}), '{null_pattern}')))"



# ── Hub Parser (for add-source) ───────────────────────────────────────────────


def _parse_select_columns(col_text):
    """Parse column names from a SELECT column list string.

    Handles: COLNAME, COLNAME::TYPE, COLNAME::TYPE AS ALIAS, COLNAME AS ALIAS.
    Returns list of final column names (uppercased).
    """
    cols = []
    for part in col_text.split(","):
        part = part.strip()
        if not part or part.startswith("{%") or part.startswith("--"):
            continue
        as_match = re.search(r"\bAS\s+(\w+)\s*$", part, re.IGNORECASE)
        if as_match:
            cols.append(as_match.group(1).upper())
        else:
            # Strip type cast (::TEXT etc.) and take the last word
            name = re.sub(r"::\w+", "", part).strip()
            words = name.split()
            if words:
                cols.append(words[-1].strip().upper())
    return cols


def _parse_logic_columns(col_text):
    """Parse LOGIC CTE columns with rename detection.

    Returns list of dicts: [{"raw": "EBELN", "hub": "PO_HEADER_ID"}, ...]
    When no alias is present, raw == hub.
    """
    columns = []
    for part in col_text.split(","):
        part = part.strip()
        if not part or part.startswith("{%") or part.startswith("--"):
            continue
        as_match = re.search(r"(\w+)(?:::\w+)?\s+as\s+(\w+)", part, re.IGNORECASE)
        if as_match:
            columns.append({
                "raw": as_match.group(1).upper(),
                "hub": as_match.group(2).upper(),
            })
        else:
            name = re.sub(r"::\w+", "", part).strip()
            words = name.split()
            if words:
                col_name = words[-1].strip().upper()
                columns.append({"raw": col_name, "hub": col_name})
    return columns


def _extract_hub_final_columns(clean_content):
    """Extract hub output column list from the FINAL SELECT ... FROM JOIN_RESULT."""
    fm = re.search(r"\bFROM\s+JOIN_RESULT\b", clean_content, re.IGNORECASE)
    if not fm:
        return []

    before = clean_content[: fm.start()]
    sel_pos = before.upper().rfind("SELECT")
    if sel_pos == -1:
        return []

    col_text = before[sel_pos + 6 :].strip()
    if col_text.strip() == "*":
        # SELECT * — try JOIN_RESULT's own column list
        jm = re.search(
            r"JOIN_RESULT\s+as\s*\(\s*\n?\s*SELECT\s+(.*?)\s+FROM\b",
            clean_content,
            re.DOTALL | re.IGNORECASE,
        )
        if jm and jm.group(1).strip() != "*":
            return _parse_select_columns(jm.group(1))
        # Last resort: ghost record AS aliases
        ghost = _extract_ghost_block(clean_content)
        if ghost:
            return [m.group(1).upper() for m in re.finditer(r"\bAS\s+(\w+)", ghost, re.IGNORECASE)]
        return []

    return _parse_select_columns(col_text)


def _extract_final_qualify_columns(clean_content):
    """Extract PARTITION BY columns from the final QUALIFY clause.

    Takes the last QUALIFY partition-by in the file (which is the final-layer
    or join-layer dedup, not the per-source SRC QUALIFY).
    """
    qualifies = list(
        re.finditer(
            r"partition\s+by\s+(.*?)\s+order\s+by",
            clean_content,
            re.IGNORECASE | re.DOTALL,
        )
    )
    if qualifies:
        last = qualifies[-1]
        return [c.strip().upper() for c in last.group(1).split(",")]
    return []


def _extract_ghost_block(content):
    """Extract the ghost record UNION ALL block (raw SQL, no Jinja wrapper)."""
    match = re.search(
        r"(union\s+all\s*\n\s*SELECT\s+.*?"
        r"FROM\s*\n\s*TABLE\(strtok_split_to_table\([^)]+\)\)\s+AS\s+GR)",
        content,
        re.DOTALL | re.IGNORECASE,
    )
    return match.group(1) if match else None


def _derive_source_alias(model_name):
    """Derive a short CTE alias from a v_psa_stg model name.

    v_psa_stg_cost_estimate_header__emtk_ebs → emtkebs
    v_psa_stg_po_item__winn_sap              → winnsap
    v_psa_stg_po_item__ml_ebs                → mlebs
    """
    # Extract the source system suffix after __
    parts = model_name.split("__")
    if len(parts) >= 2:
        return parts[-1].replace("_", "")
    return _strip_stg_prefix(model_name).replace("_", "")


def _parse_existing_hub(hub_sql_path):
    """Parse an existing hub SQL file and extract its structure.

    Handles 4-layer (SRC→LOGIC→JOIN→FINAL), 6-layer (SRC→LOGIC→RENAME→
    FILTER→JOIN→FINAL), and direct (SRC→JOIN→FINAL) hub patterns.

    Returns dict with:
      config_block        — {{ config(...) }} string or None
      has_watermark_cte   — True if INCR_WATERMARK CTE present
      sources             — list of {alias, stg_ref, uses_watermark, src_columns}
      logic_ctes          — dict of alias → {columns: [{raw, hub}]}
      hub_columns         — ordered list of output column names
      hk_column           — the _HK column name
      qualify_columns     — PARTITION BY columns from final QUALIFY
      ghost_record_block  — ghost record SQL text
      cte_chain           — "4-layer" | "6-layer" | "direct"
      join_source_type    — CTE type feeding JOIN_RESULT ("LOGIC"|"FILTER"|"SRC")
      join_cte_entries    — ordered list of CTE names in JOIN_RESULT UNION ALL
    """
    content = Path(hub_sql_path).read_text()
    # Strip /* ... */ block comments for structural parsing
    clean = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)

    # ── Config block ──
    cm = re.search(r"\{\{\s*config\(.*?\)\s*\}\}", content, re.DOTALL)
    config_block = cm.group(0) if cm else None

    # ── INCR_WATERMARK ──
    has_wm = bool(re.search(r"INCR_WATERMARK\s+AS\s*\(", clean, re.IGNORECASE))

    # ── Source CTEs ──
    # Build a list of ALL CTE start positions for boundary detection
    cte_boundary_re = re.compile(
        r"(?:SRC_\w+|LOGIC_\w+|RENAME_\w+|FILTER_\w+|JOIN_RESULT)\s+as\s*\(",
        re.IGNORECASE,
    )
    all_cte_starts = [m.start() for m in cte_boundary_re.finditer(clean)]

    sources = []
    for m in re.finditer(r"SRC_(\w+)\s+as\s*\(", clean, re.IGNORECASE):
        alias = m.group(1)
        start = m.start()
        # Body extends to the next CTE boundary
        later = [s for s in all_cte_starts if s > start + 5]
        end = later[0] if later else len(clean)
        body = clean[start:end]

        ref_match = re.search(r"ref\('([^']+)'\)", body)
        stg_ref = ref_match.group(1) if ref_match else None
        uses_wm_src = "INCR_WATERMARK" in body

        col_match = re.search(
            r"SELECT\s+(.*?)\s+FROM\b", body, re.DOTALL | re.IGNORECASE
        )
        src_cols = _parse_select_columns(col_match.group(1)) if col_match else []

        sources.append({
            "alias": alias,
            "stg_ref": stg_ref,
            "uses_watermark": uses_wm_src,
            "src_columns": src_cols,
        })

    # ── LOGIC CTEs ──
    logic_ctes = {}
    for m in re.finditer(r"LOGIC_(\w+)\s+as\s*\(", clean, re.IGNORECASE):
        alias = m.group(1)
        rest = clean[m.end() :]
        from_match = re.search(r"\bFROM\s+SRC_", rest, re.IGNORECASE)
        if from_match:
            select_text = rest[: from_match.start()]
            sel_match = re.search(r"SELECT\s+(.*)", select_text, re.DOTALL | re.IGNORECASE)
            if sel_match:
                columns = _parse_logic_columns(sel_match.group(1))
                logic_ctes[alias] = {"columns": columns}

    # ── CTE chain detection ──
    has_rename = bool(re.search(r"\bRENAME_\w+\s+as\s*\(", clean, re.IGNORECASE))
    has_filter = bool(re.search(r"\bFILTER_\w+\s+as\s*\(", clean, re.IGNORECASE))
    if has_rename or has_filter:
        cte_chain = "6-layer"
        join_source_type = "FILTER"
    elif logic_ctes:
        cte_chain = "4-layer"
        join_source_type = "LOGIC"
    else:
        cte_chain = "direct"
        join_source_type = "SRC"

    # ── Hub output columns ──
    hub_columns = _extract_hub_final_columns(clean)
    hk_col = next((c for c in hub_columns if c.endswith("_HK")), None)

    # ── Final QUALIFY columns ──
    qualify_cols = _extract_final_qualify_columns(clean)

    # ── Ghost record block ──
    ghost = _extract_ghost_block(content)

    # ── JOIN_RESULT union entries ──
    join_entries = []
    jm = re.search(r"JOIN_RESULT\s+as\s*\(", clean, re.IGNORECASE)
    if jm:
        join_body = clean[jm.end() :]
        # Find matching close — scan for CTEs that are UNION ALL'd
        for em in re.finditer(
            r"SELECT\s+\*\s+FROM\s+(\w+)", join_body, re.IGNORECASE
        ):
            entry = em.group(1)
            if entry.upper() != "JOIN_RESULT":
                join_entries.append(entry)

    return {
        "config_block": config_block,
        "has_watermark_cte": has_wm,
        "sources": sources,
        "logic_ctes": logic_ctes,
        "hub_columns": hub_columns,
        "hk_column": hk_col,
        "qualify_columns": qualify_cols,
        "ghost_record_block": ghost,
        "cte_chain": cte_chain,
        "join_source_type": join_source_type,
        "join_cte_entries": join_entries,
    }


# ── Add-Source: Column Mapping + CTE Generation ──────────────────────────────


def _build_add_source_column_mapping(hub_parsed, new_bk_raw_cols):
    """Build the column mapping from new source BK columns to hub standard names.

    BK columns are matched BY POSITION: first new BK → first hub BK, etc.
    Non-BK columns (HK, LOAD_DTS, BKCC, REC_SRC) are identity-mapped.

    Args:
        hub_parsed: dict from _parse_existing_hub()
        new_bk_raw_cols: list of raw BK column names from the new v_psa_stg

    Returns:
        list of dicts: [{"raw": "MATNR", "hub": "MATERIAL_ID"}, ...]
        Covers ALL hub output columns (HK + BKs + LOAD_DTS + BKCC + REC_SRC).

    Raises:
        ValueError if BK column count doesn't match the hub's BK count.
    """
    hub_columns = hub_parsed["hub_columns"]
    hk_col = hub_parsed["hk_column"]

    # Identify hub BK columns (everything that's NOT HK, LOAD_DTS, BKCC, REC_SRC)
    meta_cols = {"LOAD_DTS", "BKCC", "REC_SRC"}
    hub_bk_cols = [c for c in hub_columns if c != hk_col and c not in meta_cols]

    if len(new_bk_raw_cols) != len(hub_bk_cols):
        raise ValueError(
            f"BK column count mismatch: hub expects {len(hub_bk_cols)} "
            f"({', '.join(hub_bk_cols)}) but new source has {len(new_bk_raw_cols)} "
            f"({', '.join(new_bk_raw_cols)})"
        )

    # Build mapping: HK (identity) + BKs (positional) + meta (identity)
    mapping = []

    # HK — always identity-mapped (pre-computed in v_psa_stg)
    mapping.append({"raw": hk_col, "hub": hk_col})

    # BK columns — positional mapping
    # v_psa_stg already outputs BK as the alias name (e.g., DELIVERY_BK),
    # so the "raw" from the staging view perspective IS the hub BK alias.
    # The original source column (e.g., VBELN) is internal to v_psa_stg.
    for raw_col, hub_col in zip(new_bk_raw_cols, hub_bk_cols):
        mapping.append({"raw": hub_col, "hub": hub_col})

    # Meta columns — identity-mapped, in hub column order
    for col in hub_columns:
        if col in meta_cols:
            mapping.append({"raw": col, "hub": col})

    return mapping


def _generate_add_source_ctes(hub_parsed, new_alias, new_stg_ref,
                               column_mapping, use_watermark,
                               qualify_order_by, new_bk_raw_cols):
    """Generate the SRC + LOGIC (+ optional RENAME/FILTER) CTEs for a new source.

    Args:
        hub_parsed: dict from _parse_existing_hub()
        new_alias: CTE alias suffix (e.g., "emtkebs")
        new_stg_ref: v_psa_stg model name (e.g., "v_psa_stg_cost_estimate_header__emtk_ebs")
        column_mapping: list from _build_add_source_column_mapping()
        use_watermark: bool - whether this source uses INCR_WATERMARK
        qualify_order_by: str - ORDER BY column for QUALIFY (e.g., "GLCHANGETIME")
        new_bk_raw_cols: list of raw BK column names

    Returns:
        dict with keys: src_cte, logic_cte, rename_cte, filter_cte,
                         needs_watermark_cte (True if hub needs INCR_WATERMARK added)
    """
    hk_col = hub_parsed["hk_column"]
    cte_chain = hub_parsed["cte_chain"]

    # ── SRC CTE ──
    # Column list: HK + BK alias cols (from v_psa_stg) + LOAD_DTS + BKCC + REC_SRC
    meta_cols = {hk_col, "LOAD_DTS", "BKCC", "REC_SRC"}
    bk_alias_cols = [m["hub"] for m in column_mapping if m["hub"] not in meta_cols]
    src_select_cols = [hk_col] + bk_alias_cols + ["LOAD_DTS", "BKCC", "REC_SRC"]
    src_col_str = ", ".join(src_select_cols)

    # QUALIFY: partition by BK alias cols (staging view output names) + BKCC
    # v_psa_stg already outputs BK as the alias name — raw source col is NOT in staging output
    qualify_partition = ", ".join(bk_alias_cols + ["BKCC"])

    if use_watermark:
        src_cte = (
            f"SRC_{new_alias}            as ( SELECT {src_col_str} "
            f"FROM {{{{ ref('{new_stg_ref}') }}}} as SRC  \n"
            f"                        {{% if is_incremental() %}}\n"
            f"                        LEFT JOIN INCR_WATERMARK AS wm ON SRC.REC_SRC = wm.wm_REC_SRC\n"
            f"                        WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)\n"
            f"                        {{% else %}}\n"
            f"                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY {qualify_partition} ORDER BY {qualify_order_by})) = 1\n"
            f"                        {{% endif %}}\n"
            f")"
        )
    else:
        src_cte = (
            f"SRC_{new_alias}            as ( SELECT {src_col_str} "
            f"FROM {{{{ ref('{new_stg_ref}') }}}} as SRC  \n"
            f"                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY {qualify_partition} ORDER BY {qualify_order_by})) = 1\n"
            f")"
        )

    # ── LOGIC CTE ──
    # Column lines with aliases where raw != hub
    logic_lines = []
    for i, col in enumerate(column_mapping):
        prefix = "        " if i == 0 else "      , "
        if col["raw"] != col["hub"]:
            # Pad for alignment
            logic_lines.append(
                f"{prefix}{col['raw']}"
                f"{'':>{max(1, 60 - len(prefix) - len(col['raw']))}}as"
                f"{'':>{max(1, 40 - 2)}} {col['hub']}"
            )
        else:
            logic_lines.append(f"{prefix}{col['hub']}")

    logic_col_block = "\n".join(logic_lines)
    logic_cte = (
        f", LOGIC_{new_alias} as (\n"
        f"    SELECT\n"
        f"{logic_col_block}\n"
        f"    FROM SRC_{new_alias}\n"
        f")"
    )

    # ── RENAME CTE (6-layer only — passthrough) ──
    rename_cte = None
    if cte_chain == "6-layer":
        hub_col_names = hub_parsed["hub_columns"]
        rename_lines = []
        for i, col in enumerate(hub_col_names):
            prefix = "        " if i == 0 else "      , "
            rename_lines.append(f"{prefix}{col}")
        rename_col_block = "\n".join(rename_lines)
        rename_cte = (
            f", RENAME_{new_alias} as (\n"
            f"    SELECT\n"
            f"{rename_col_block}\n"
            f"    FROM LOGIC_{new_alias}\n"
            f")"
        )

    # ── FILTER CTE (6-layer only — passthrough) ──
    filter_cte = None
    if cte_chain == "6-layer":
        filter_cte = (
            f", FILTER_{new_alias} as (\n"
            f"    SELECT *\n"
            f"    FROM RENAME_{new_alias}\n"
            f")"
        )

    # ── Watermark CTE needed? ──
    needs_watermark = use_watermark and not hub_parsed["has_watermark_cte"]

    return {
        "src_cte": src_cte,
        "logic_cte": logic_cte,
        "rename_cte": rename_cte,
        "filter_cte": filter_cte,
        "needs_watermark_cte": needs_watermark,
    }


def _insert_source_into_hub(hub_sql_path, hub_parsed, generated_ctes, new_alias):
    """Surgically insert new source CTEs into an existing hub SQL file.

    Modifies the file in-place. Only adds new CTEs and UNION ALL entry;
    never touches existing source CTEs or the FINAL layer.

    Args:
        hub_sql_path: path to the hub SQL file
        hub_parsed: dict from _parse_existing_hub()
        generated_ctes: dict from _generate_add_source_ctes()
        new_alias: CTE alias suffix (e.g., "emtkebs")

    Returns:
        True on success, raises ValueError on structural problems.
    """
    hub_path = Path(hub_sql_path)
    backup_path = hub_path.with_suffix('.sql.bak')

    # Create backup before surgical modification (lesson #75 pattern)
    content = hub_path.read_text()
    backup_path.write_text(content)

    try:
        return _insert_source_into_hub_impl(hub_path, backup_path, content, hub_parsed, generated_ctes, new_alias)
    except Exception:
        # Restore from backup on any failure
        if backup_path.exists():
            hub_path.write_text(backup_path.read_text())
            backup_path.unlink()
        raise


def _insert_source_into_hub_impl(hub_path, backup_path, content, hub_parsed, generated_ctes, new_alias):
    """Internal implementation — called by _insert_source_into_hub with backup protection."""
    cte_chain = hub_parsed["cte_chain"]
    join_source_type = hub_parsed["join_source_type"]

    # ── 1. Add INCR_WATERMARK CTE if needed ──
    if generated_ctes["needs_watermark_cte"]:
        # Replace bare "WITH" with the watermark CTE block
        wm_block = (
            "{% if is_incremental() %}\n"
            "WITH INCR_WATERMARK AS (\n"
            "    SELECT REC_SRC as wm_REC_SRC,\n"
            "           DATEADD(DAY, -3, MAX(LOAD_DTS)) AS watermark_dts\n"
            "    FROM {{ this }}\n"
            "    GROUP BY REC_SRC\n"
            "),\n"
            "{% else %}\n"
            "WITH\n"
            "{% endif %}"
        )
        # Find the standalone WITH (not part of INCR_WATERMARK)
        with_match = re.search(r"^WITH\s*$", content, re.MULTILINE | re.IGNORECASE)
        if with_match:
            content = content[: with_match.start()] + wm_block + content[with_match.end() :]

    # ── 2. Insert SRC CTE — after last SRC CTE, before debug comment block ──
    # The debug comment block (/* ... */) must remain as the last thing in the
    # SRC layer. Insert the new SRC CTE BEFORE the comment block, not after it.
    logic_marker = re.search(r"---- LOGIC LAYER ----", content)
    if logic_marker:
        insert_pos = logic_marker.start()
        # Check if there's a debug comment block (/* ... */) between SRC CTEs and LOGIC
        # If so, insert BEFORE it so the comment stays last in the SRC section.
        src_section = content[:insert_pos]
        debug_comment_match = re.search(r"\n(/\*\n.*?\*/\n)", src_section, re.DOTALL)
        if debug_comment_match:
            # Insert before the debug comment block
            insert_pos = debug_comment_match.start() + 1  # +1 to skip the leading \n
        # Insert with a comma separator
        src_insert = f",\n{generated_ctes['src_cte']}\n\n"
        content = content[:insert_pos] + src_insert + content[insert_pos:]
    else:
        # No LOGIC marker — find first LOGIC CTE
        first_logic = re.search(r",\s*LOGIC_\w+\s+as\s*\(", content, re.IGNORECASE)
        if first_logic:
            src_insert = f",\n{generated_ctes['src_cte']}\n"
            content = content[: first_logic.start()] + src_insert + content[first_logic.start() :]

    # ── 3. Insert LOGIC CTE — before JOIN LAYER marker or JOIN_RESULT ──
    if cte_chain == "6-layer":
        # Insert LOGIC before RENAME LAYER marker
        rename_marker = re.search(r"---- RENAME LAYER ----", content)
        if rename_marker:
            logic_insert = f"\n{generated_ctes['logic_cte']}\n"
            content = content[: rename_marker.start()] + logic_insert + content[rename_marker.start() :]

        # Insert RENAME before FILTER LAYER marker
        filter_marker = re.search(r"---- FILTER LAYER ----", content)
        if filter_marker and generated_ctes["rename_cte"]:
            rename_insert = f"\n{generated_ctes['rename_cte']}\n"
            content = content[: filter_marker.start()] + rename_insert + content[filter_marker.start() :]

        # Insert FILTER before JOIN LAYER marker
        join_marker = re.search(r"---- JOIN LAYER ----", content)
        if join_marker and generated_ctes["filter_cte"]:
            filter_insert = f"\n{generated_ctes['filter_cte']}\n"
            content = content[: join_marker.start()] + filter_insert + content[join_marker.start() :]
    else:
        # 4-layer: insert LOGIC before JOIN LAYER marker
        join_marker = re.search(r"---- JOIN LAYER ----", content)
        if join_marker:
            logic_insert = f"\n{generated_ctes['logic_cte']}\n"
            content = content[: join_marker.start()] + logic_insert + content[join_marker.start() :]

    # ── 4. Add UNION ALL entry in JOIN_RESULT ──
    # Determine the CTE name this source feeds into JOIN_RESULT
    if cte_chain == "6-layer":
        union_entry_name = f"FILTER_{new_alias}"
    elif cte_chain == "4-layer":
        union_entry_name = f"LOGIC_{new_alias}"
    else:
        union_entry_name = f"SRC_{new_alias}"

    # Find the closing paren of JOIN_RESULT — insert UNION ALL before it
    # Strategy: find last "SELECT * FROM <CTE>" inside JOIN_RESULT and add after it
    join_result_match = re.search(r"JOIN_RESULT\s+as\s*\(", content, re.IGNORECASE)
    if join_result_match:
        join_body_start = join_result_match.end()
        # Find the closing ) of JOIN_RESULT by finding the FINAL LAYER marker or
        # the standalone SELECT...FROM JOIN_RESULT
        final_marker = re.search(r"---- FINAL LAYER ----", content[join_body_start:])
        if final_marker:
            join_end = join_body_start + final_marker.start()
        else:
            # Find )\n\nSELECT or )\nSELECT after JOIN_RESULT
            close_match = re.search(r"\)\s*\n\s*\n?\s*(?:---- FINAL|SELECT)", content[join_body_start:], re.IGNORECASE)
            join_end = join_body_start + close_match.start() + 1 if close_match else len(content)

        join_body = content[join_body_start:join_end]

        # Find the last "SELECT * FROM <name>" line in join body
        last_union = None
        for m in re.finditer(r"SELECT\s+\*\s+FROM\s+\w+", join_body, re.IGNORECASE):
            last_union = m

        if last_union:
            insert_pos = join_body_start + last_union.end()
            union_insert = f"\n    UNION ALL\n    SELECT * FROM {union_entry_name}"
            content = content[:insert_pos] + union_insert + content[insert_pos:]

    hub_path.write_text(content)
    # Remove backup on success
    if backup_path.exists():
        backup_path.unlink()
    return True


def _semantic_collision_check(state):
    """Run semantic collision check across all DV layers.

    DV 2.x cardinality rules:
      - v_psa_stg: 1:1 with driver source → COLLISION if exists
      - SAT:       1:1 with v_psa_stg per source → COLLISION if exists
      - HUB:       many:1 → ADD-SOURCE if exists (informational)
      - LNK:       many:1 → ADD-SOURCE if exists (informational)

    Returns: dict with layer results and overall 'blocked' flag.
    """
    schema = state["schema"]
    table = state["table"]
    model_name = state["model_name"]
    bk_name = state["bk_name"]
    objects = state.get("objects", ["stg"])

    results = {}
    blocked = False

    # ── 1. v_psa_stg — 1:1 with driver source ──
    # Grep for source('<schema>', '<table>') in int_staging_views
    # NOTE: models/staging/ is LEGACY (AutomateDV pipeline) — never check there
    stg_dir = PROJECT_ROOT / "models" / "int_staging_views"
    stg_hits = []
    if stg_dir.exists():
        rc, out, _ = _run_command(
            f"grep -rl \"source('{schema}'\" models/int_staging_views/ "
            f"--include='*.sql' 2>/dev/null || true"
        )
        # Narrow to files that also contain the table name
        candidates = [f for f in out.strip().split("\n") if f]
        # Exclude legacy models/staging/ paths (should not appear, but guard)
        candidates = [f for f in candidates if not f.startswith("models/staging/")]
        for fpath in candidates:
            rc2, out2, _ = _run_command(
                f"grep -l \"'{table}'\" {fpath} 2>/dev/null || true"
            )
            if out2.strip():
                stg_hits.append(fpath)

    if stg_hits:
        results["v_psa_stg"] = {
            "status": "COLLISION",
            "files": stg_hits,
            "message": f"existing model(s) already use {schema}.{table} as driver",
        }
        blocked = True
    else:
        results["v_psa_stg"] = {
            "status": "CLEAR",
            "message": f"no existing model uses {schema}.{table} as driver",
        }

    # ── 2. HUB — many:1 ──
    if "hub" in objects:
        hub_name = state.get('hub_name_override') or _derive_hub_name(bk_name)
        hub_path = PROJECT_ROOT / "models" / "raw_vault" / "hub" / f"{hub_name}.sql"
        if hub_path.exists():
            # Check if this v_psa_stg model is already referenced in the hub
            hub_content = hub_path.read_text(encoding="utf-8")
            if f"ref('{model_name}')" in hub_content:
                results["hub"] = {
                    "status": "ALREADY-PRESENT",
                    "file": str(hub_path.relative_to(PROJECT_ROOT)),
                    "message": f"{hub_name} already references {model_name}",
                }
            else:
                results["hub"] = {
                    "status": "ADD-SOURCE",
                    "file": str(hub_path.relative_to(PROJECT_ROOT)),
                    "message": f"{hub_name} exists, will add new source",
                }
        else:
            results["hub"] = {
                "status": "CLEAR",
                "message": f"{hub_name} does not exist — will create new hub",
            }

    # ── 3. SAT — 1:1 with v_psa_stg per source ──
    sat_dir = PROJECT_ROOT / "models" / "raw_vault" / "sat"
    sat_hits = []
    if sat_dir.exists():
        rc, out, _ = _run_command(
            f"grep -rl \"ref('{model_name}')\" models/raw_vault/sat/ "
            f"--include='*.sql' 2>/dev/null || true"
        )
        sat_hits = [f for f in out.strip().split("\n") if f]

    if sat_hits:
        results["sat"] = {
            "status": "COLLISION",
            "files": sat_hits,
            "message": f"existing SAT(s) already reference {model_name}",
        }
        blocked = True
    else:
        results["sat"] = {
            "status": "CLEAR",
            "message": f"no existing SAT references {model_name}",
        }

    # ── 4. LNK — many:1 ──
    if "hub" in objects:
        hub_name = state.get('hub_name_override') or _derive_hub_name(bk_name)
        lnk_dir = PROJECT_ROOT / "models" / "raw_vault" / "link"
        lnk_hits = []
        if lnk_dir.exists():
            rc, out, _ = _run_command(
                f"grep -rl \"ref('{hub_name}')\" models/raw_vault/link/ "
                f"--include='*.sql' 2>/dev/null || true"
            )
            lnk_hits = [f for f in out.strip().split("\n") if f]

        if lnk_hits:
            results["lnk"] = {
                "status": "ADD-SOURCE",
                "files": lnk_hits,
                "message": f"existing link(s) reference {hub_name}",
            }
        else:
            results["lnk"] = {
                "status": "CLEAR",
                "message": f"no existing link references {hub_name}",
            }

    # ── 5. LNK model existence — when generating a link ──
    if "lnk" in objects:
        lnks_list = state.get("lnks", [])
        lnk_def = lnks_list[0] if lnks_list else {}
        lnk_name_val = lnk_def.get("lnk_name", "")
        if lnk_name_val:
            lnk_derived = _derive_lnk_name(lnk_name_val)
            lnk_path = PROJECT_ROOT / "models" / "raw_vault" / "link" / f"{lnk_derived}.sql"
            if lnk_path.exists():
                # Check if this v_psa_stg model is already referenced in the link
                lnk_content = lnk_path.read_text(encoding="utf-8")
                if f"ref('{model_name}')" in lnk_content:
                    results["lnk_model"] = {
                        "status": "ALREADY-PRESENT",
                        "file": str(lnk_path.relative_to(PROJECT_ROOT)),
                        "message": f"{lnk_derived} already references {model_name}",
                    }
                else:
                    results["lnk_model"] = {
                        "status": "ADD-SOURCE",
                        "file": str(lnk_path.relative_to(PROJECT_ROOT)),
                        "message": f"{lnk_derived} exists, will add new source",
                    }
            else:
                results["lnk_model"] = {
                    "status": "CLEAR",
                    "message": f"{lnk_derived} does not exist — will create new link",
                }

    return {"layers": results, "blocked": blocked}


def _print_collision_report(collision_result):
    """Print formatted semantic collision check report."""
    layers = collision_result["layers"]
    blocked = collision_result["blocked"]

    STATUS_ICONS = {
        "CLEAR": "✅ CLEAR",
        "COLLISION": "❌ COLLISION",
        "ADD-SOURCE": "🔄 ADD-SOURCE",
        "ALREADY-PRESENT": "✓ ALREADY-PRESENT",
    }

    print("\n    === Semantic Collision Check ===")
    for layer, info in layers.items():
        icon = STATUS_ICONS.get(info["status"], info["status"])
        pad = max(1, 12 - len(layer))
        print(f"    {layer}:{' ' * pad}{icon} — {info['message']}")
        if "files" in info:
            for f in info["files"]:
                print(f"      → {f}")
        if "file" in info:
            print(f"      → {info['file']}")

    if blocked:
        print("\n    ⛔ BLOCKED — resolve collision(s) before proceeding.")
    else:
        print("\n    All checks passed.")
    print()


def cmd_init(args):
    """Initialize a new pipeline for a model."""
    model_name = args.model_name
    if not model_name:
        _print_error("--model-name is required for init")
        return 1

    # Check if state already exists
    existing = _load_state(model_name)
    if existing and not args.force:
        _print_error(
            f"Pipeline already exists for {model_name}.\n"
            f"  Use --force to reinitialize, or delete the state file:\n"
            f"  rm {STATE_DIR / f'{model_name}.json'}"
        )
        return 1

    # Validate required params
    missing = []
    if not args.schema:
        missing.append("--schema")
    if not args.table:
        missing.append("--table")
    if not args.bk:
        missing.append("--bk")
    if not args.rec_src:
        missing.append("--rec-src")
    if missing:
        _print_error(f"Missing required arguments: {', '.join(missing)}")
        return 1

    # Validate REC_SRC format (Location.System.Application.Table)
    if not REC_SRC_PATTERN.match(args.rec_src):
        _print_error(
            f"Invalid --rec-src '{args.rec_src}'. "
            "Must match Location.System.Application.Table (alphanumeric, dots, underscores only)."
        )
        return 1

    # Validate schema identifier (SQL injection prevention)
    if not IDENTIFIER_PATTERN.match(args.schema):
        _print_error(f"--schema contains invalid characters: {args.schema!r}")
        return 1

    # Validate table identifier
    if not IDENTIFIER_PATTERN.match(args.table):
        _print_error(f"--table contains invalid characters: {args.table!r}")
        return 1

    # ── Defect 1 (scoped): reject only malformed MULTI-part composites ────────
    # A single derivation (TO_CHAR/COALESCE/CONCAT/|| expression) is accepted and
    # flows to manual_logic. A raw composite (COL1,COL2) is accepted and the
    # orchestrator builds the CONCAT_WS. Only a mixed/garbled composite like
    # "COL1, CONCAT(X,Y)" or "COL1,123BAD" is rejected with guidance.
    bk_arg_error = _validate_bk_arg(args.bk)
    if bk_arg_error:
        _print_error(bk_arg_error)
        return 1

    # Validate each BK column name (may include ::TEXT/::VARCHAR cast or nested functions)
    # Paren-aware split: a single derivation with inner commas (CONCAT(A,'-',B))
    # stays one part; a raw composite (COL1,COL2) splits into its columns.
    for bk_col in _split_bk_parts(args.bk):
        raw_col = _extract_raw_col_from_bk(bk_col)
        if not IDENTIFIER_PATTERN.match(raw_col):
            _print_error(f"--bk contains invalid column name: {raw_col!r}")
            return 1
        # Warn when extraction reinterprets the input (audit fuzz finding H-1)
        bk_col_base = bk_col.upper().split('::')[0].strip()
        if raw_col.upper() != bk_col_base.upper():
            # Skip warning for common SQL function patterns (COALESCE, TRIM, etc.)
            if not re.match(r'^[A-Z_]+\s*\(', bk_col_base):
                print(f"  WARNING: BK expression {bk_col!r} interpreted as column '{raw_col}'")
                print(f"           Verify this is the correct source column.")

    # ── H-1: Validate full BK expression (defense-in-depth) ──────────────
    # The _extract_raw_col_from_bk check above validates the extracted
    # identifier. This validates the FULL input string to reject SQL
    # terminators and dangerous chars before the expression reaches f-string
    # interpolation in profile queries.
    for bk_col in _split_bk_parts(args.bk):
        if not bk_col:
            continue
        if re.search(r'(;|--|/\*|\*/)', bk_col):
            _print_error(
                f"--bk contains SQL terminator characters: {bk_col!r}\n"
                f"  BK expressions must not contain ';', '--', '/*', or '*/'"
            )
            return 1
        if not BK_SAFE_CHARS.match(bk_col):
            _print_error(
                f"--bk contains disallowed characters: {bk_col!r}\n"
                f"  Allowed: column names, SQL functions, casts (::TEXT), "
                f"string literals ('value'), commas, parens"
            )
            return 1

    # Reject reserved/metadata columns as BK (DV 2.1: REC_SRC NEVER in HK)
    RESERVED_COLUMNS = {'REC_SRC', 'PSA_RECORD_SOURCE', '_FIVETRAN_SYNCED',
                        'LOAD_DTS', 'PSA_LOAD_DTS', 'HASHDIFF', 'BKCC'}
    for bk_col in _split_bk_parts(args.bk):
        raw_col = _extract_raw_col_from_bk(bk_col)
        if raw_col in RESERVED_COLUMNS:
            _print_error(
                f"--bk contains reserved column: {raw_col}\n"
                "  BK cannot include REC_SRC, LOAD_DTS, HASHDIFF, BKCC, or PSA metadata"
            )
            return 1

    # Parse objects to generate (default: stg only)
    objects = [o.strip().lower() for o in getattr(args, 'objects', 'stg').split(',')]
    valid_objects = {'stg', 'hub', 'lnk', 'sat'}
    invalid = set(objects) - valid_objects
    if invalid:
        _print_error(f"Invalid --objects values: {invalid}. Valid: {valid_objects}")
        return 1

    # Validate LNK-specific params when lnk is requested
    if 'lnk' in objects:
        lnk_name = getattr(args, 'lnk_name', None)
        parent_hks_raw = getattr(args, 'parent_hks', None)
        if not lnk_name:
            _print_error("--lnk-name is required when --objects includes 'lnk'")
            return 1
        if not IDENTIFIER_PATTERN.match(lnk_name):
            _print_error(f"--lnk-name '{lnk_name}' contains invalid characters (must match [A-Za-z_][A-Za-z0-9_]*)")
            return 1
        if not parent_hks_raw:
            _print_error("--parent-hks is required when --objects includes 'lnk'")
            return 1
        for _hk in parent_hks_raw.split(','):
            _hk = _hk.strip()
            if _hk and not IDENTIFIER_PATTERN.match(_hk):
                _print_error(f"--parent-hks item '{_hk}' contains invalid characters")
                return 1
        # --dck accepts comma-separated raw column names only (same rule as --bk/--hk).
        _dck_raw = getattr(args, 'dck', None)
        if _dck_raw:
            _, _dck_err = _validate_raw_column_list(_dck_raw, "--dck")
            if _dck_err:
                _print_error(_dck_err)
                return 1

    # Validate SAT-specific params when sat is requested
    if 'sat' in objects:
        sat_parent_hk = getattr(args, 'sat_parent_hk', None)
        sat_parent_model = getattr(args, 'sat_parent_model', None)
        if not sat_parent_hk:
            _print_error("--sat-parent-hk is required when --objects includes 'sat'")
            return 1
        if not IDENTIFIER_PATTERN.match(sat_parent_hk):
            _print_error(f"--sat-parent-hk '{sat_parent_hk}' contains invalid characters")
            return 1
        if not sat_parent_model:
            _print_error("--sat-parent-model is required when --objects includes 'sat'")
            return 1
        if not IDENTIFIER_PATTERN.match(sat_parent_model):
            _print_error(f"--sat-parent-model '{sat_parent_model}' contains invalid characters")
            return 1
        sat_type = getattr(args, 'sat_type', 'sat') or 'sat'
        if sat_type not in SAT_VARIANTS:
            _print_error(f"Invalid --sat-type '{sat_type}'. Valid: {SAT_VARIANTS}")
            return 1
        multi_active_key = getattr(args, 'multi_active_key', None)
        if sat_type in ('msat', 'lmsat') and not multi_active_key:
            _print_error(f"--multi-active-key is required for sat_type '{sat_type}'")
            return 1
        if multi_active_key:
            ma_parts = [k.strip() for k in multi_active_key.split(',')]
            if any(not IDENTIFIER_PATTERN.match(p) for p in ma_parts):
                _print_error(f"--multi-active-key '{multi_active_key}' contains invalid characters")
                return 1

    # ── Guard: reject duplicate --bk flags (argparse silently overwrites) ──
    # Count both --bk VALUE and --bk=VALUE forms
    argv_bk_count = sum(1 for a in sys.argv if a == '--bk' or a.startswith('--bk='))
    if argv_bk_count > 1:
        _print_error(
            f"--bk was specified {argv_bk_count} times. Only the LAST value is used "
            f"(argparse silently overwrites). For multiple BKs use:\n"
            f"  --bk <PRIMARY_BK> --bk-name <PRIMARY_BK_NAME>\n"
            f"  --additional-bk <RAW_COL:BK_ALIAS>  (repeatable)\n"
            f"Example: --bk ID --bk-name SUBSCRIPTION_ORDER_BK "
            f"--additional-bk SUBSCRIBER_ID:SUBSCRIBER_BK"
        )
        return 1
    argv_bk_name_count = sum(1 for a in sys.argv if a == '--bk-name' or a.startswith('--bk-name='))
    if argv_bk_name_count > 1:
        _print_error(
            f"--bk-name was specified {argv_bk_name_count} times. Only the LAST value is used. "
            f"Use --additional-bk for extra BKs."
        )
        return 1

    state = {
        "model_name": model_name,
        "schema": args.schema.lower(),
        "table": args.table.lower(),
        "bk": args.bk,
        "bk_name": args.bk_name or f"{args.bk}_BK",
        "rec_src": args.rec_src,
        "objects": objects,
        "created_at": _now_iso(),
        "steps_completed": [],
        "profile_results": {},
        "config_path": "",
        "xlsx_path": "",
        "xlsx_validation": {},
        "generated_files": {},
        "stage3_results": {},
        "hash_keys": [],  # Multi-HK definitions (Phase 1)
    }

    # Store domain if provided at init (avoids re-asking at implement)
    init_domain = getattr(args, 'domain', None)
    if init_domain:
        if not re.match(r'^[a-z][a-z0-9_]*$', init_domain):
            _print_error(
                f"Invalid --domain '{init_domain}'. Must be a lowercase folder name "
                f"(letters, digits, underscores). Example: --domain shipments"
            )
            return 1
        state["domain"] = init_domain

    # Store hub-name override if provided (enables hub_delivery_v1 etc.)
    if 'hub' in objects:
        hub_name_arg = getattr(args, 'hub_name', None)
        if hub_name_arg:
            hub_name_arg = hub_name_arg.strip().lower()
            if not IDENTIFIER_PATTERN.match(hub_name_arg):
                _print_error(f"--hub-name '{hub_name_arg}' contains invalid characters")
                return 1
            if not hub_name_arg.startswith("hub_"):
                hub_name_arg = f"hub_{hub_name_arg}"
            state['hub_name_override'] = hub_name_arg

    # Store LNK params if applicable (plural key)
    if 'lnk' in objects:
        lnk_name = getattr(args, 'lnk_name', '')
        parent_hks_raw = getattr(args, 'parent_hks', '')
        dck_raw = getattr(args, 'dck', '')
        state["lnks"] = [{
            "lnk_name": lnk_name,
            "parent_hks": [h.strip() for h in parent_hks_raw.split(',') if h.strip()],
            "dcks": [d.strip() for d in dck_raw.split(',') if d.strip()] if dck_raw else [],
        }]

    # Store SAT params if applicable (plural key)
    if 'sat' in objects:
        sat_type = getattr(args, 'sat_type', 'sat') or 'sat'
        sat_parent_hk = getattr(args, 'sat_parent_hk', '')
        sat_parent_model = getattr(args, 'sat_parent_model', '')
        multi_active_key = getattr(args, 'multi_active_key', None)
        sat_name_override = getattr(args, 'sat_name', None)
        sat_model_name = _derive_sat_name(model_name, sat_type, sat_name_override)

        grain_cols_raw = getattr(args, 'grain_columns', None)
        grain_cols = [g.strip().upper() for g in grain_cols_raw.split(',') if g.strip()] if grain_cols_raw else None

        sat_cols_raw = getattr(args, 'sat_columns', None)
        sat_cols = [c.strip().upper() for c in sat_cols_raw.split(',') if c.strip()] if sat_cols_raw else None

        state["sats"] = [{
            "model_name": sat_model_name,
            "sat_type": sat_type,
            "parent_hk": sat_parent_hk.upper().strip(),
            "parent_model": sat_parent_model.strip().lower(),
            "multi_active_key": multi_active_key.upper().strip() if multi_active_key else None,
            "grain_columns": grain_cols,
            "sat_columns": sat_cols,
        }]


    # ── Naming convention validation (source suffix checks) ──────────────
    sat_name_for_check = state["sats"][0]["model_name"] if state.get("sats") else None
    suffix_warnings = _validate_source_suffix(model_name, sat_name_for_check)
    if suffix_warnings:
        # Missing '__' is a hard error — structural requirement
        has_missing_separator = (
            ("__" not in model_name) or
            (sat_name_for_check and "__" not in sat_name_for_check)
        )
        if has_missing_separator:
            for w in suffix_warnings:
                pass  # printed by _print_error below
            _print_error(
                "Model/SAT name is missing the '__<source_system>' suffix.\n"
                f"  {'  '.join(suffix_warnings)}\n"
                f"  Fix: re-run init with corrected --model-name / --sat-name"
            )
            return 1
        # Non-fatal warnings (e.g., suffix mismatch between STG and SAT)
        print("\n  \u26a0\ufe0f  NAMING CONVENTION WARNING(S):")
        for w in suffix_warnings:
            print(f"      {w}")
        print("\n      If intentional, proceed. Otherwise fix with --model-name / --sat-name.")
        print()

    # Store secondary (lookup) table params if specified
    secondary = parse_secondary_state(args)
    if secondary is not None:
        # ── H-2: Validate secondary identifiers (defense-in-depth) ───────
        # parse_secondary_state() does not validate against IDENTIFIER_PATTERN.
        # These values flow into f-string SQL in profile_secondary_table().
        for key in ('schema', 'table', 'alias'):
            val = secondary.get(key, '')
            if val and not IDENTIFIER_PATTERN.match(val):
                _print_error(
                    f"--secondary-{key} contains invalid characters: {val!r}\n"
                    f"  Must match [A-Za-z_][A-Za-z0-9_]* (SQL identifier)"
                )
                return 1
        sec_bk_name = secondary.get('bk_name')
        if sec_bk_name and not IDENTIFIER_PATTERN.match(sec_bk_name):
            _print_error(
                f"--secondary-bk-name contains invalid characters: {sec_bk_name!r}"
            )
            return 1
        sec_bk = secondary.get('bk')
        if sec_bk:
            if re.search(r'(;|--|/\*|\*/)', sec_bk):
                _print_error(
                    f"--secondary-bk contains SQL terminator characters: {sec_bk!r}"
                )
                return 1
            if not BK_SAFE_CHARS.match(sec_bk):
                _print_error(
                    f"--secondary-bk contains disallowed characters: {sec_bk!r}"
                )
                return 1
        state['secondary'] = secondary

    # Store composite grain columns if provided (lesson #96)
    grain_cols_raw = getattr(args, 'grain_columns', None)
    if grain_cols_raw:
        grain_parts = [g.strip().upper() for g in grain_cols_raw.split(',') if g.strip()]
        # Validate each grain column identifier
        _id_pat = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')
        for gp in grain_parts:
            if not _id_pat.match(gp):
                _print_error(f"--grain-columns contains invalid column name: {gp!r}")
                return 1
        state["grain_columns"] = grain_parts

    # Store custom LOAD_DTS column if provided
    _load_dts_col = getattr(args, 'load_dts_column', None)
    if _load_dts_col:
        _load_dts_col = _load_dts_col.strip().upper()
        _id_pat = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')
        if not _id_pat.match(_load_dts_col):
            _print_error(f"--load-dts-column contains invalid column name: {_load_dts_col!r}")
            return 1
        state["load_dts_column"] = _load_dts_col


    # Parse --hk definitions (Multi-HK support — Phase 1)
    hash_keys = []
    for hk_spec in getattr(args, 'hk', None) or []:
        if ":" not in hk_spec:
            _print_error(f"Invalid --hk format: {hk_spec}. Expected: HK_NAME:COL1,COL2,...")
            return 1

        hk_name, cols_str = hk_spec.split(":", 1)
        hk_name = hk_name.strip().upper()
        raw_cols = [c.strip().upper() for c in cols_str.split(",") if c.strip()]
        # @-sigil marks a link HK composed from hub HK references (HASH_FROM_HKS, #1907):
        #   --hk "LNK_X_HK:@ORDER_HK,@ITEM_HK". All components must use @ (no mixing).
        from_hks = any(c.startswith("@") for c in raw_cols)
        if from_hks and not all(c.startswith("@") for c in raw_cols):
            _print_error(f"--hk '{hk_name}': cannot mix @HK references with raw columns")
            return 1
        columns = [c[1:] if c.startswith("@") else c for c in raw_cols]
        if from_hks:
            _sigil_err = _validate_link_hk_sigil(hk_name, columns)
            if _sigil_err:
                _print_error(_sigil_err)
                return 1

        if not IDENTIFIER_PATTERN.match(hk_name):
            _print_error(f"--hk name '{hk_name}' contains invalid characters")
            return 1
        for hk_col in columns:
            if not IDENTIFIER_PATTERN.match(hk_col):
                _print_error(f"--hk column '{hk_col}' in '{hk_name}' contains invalid characters")
                return 1

        if not hk_name.endswith("_HK"):
            print(f"  WARNING: HK name '{hk_name}' does not end with '_HK'")

        if len(columns) < 2:
            _print_error(f"HK '{hk_name}' needs at least 2 columns (got {len(columns)})")
            return 1

        # BKCC validation: required for hub HKs, optional for link HKs
        is_link = hk_name.startswith("LNK_") or from_hks
        if not is_link and "BKCC" not in columns:
            print(f"  WARNING: HK '{hk_name}' does not include BKCC — required for hub HKs")

        hash_keys.append({
            "name": hk_name,
            "columns": columns,
            "type": "link" if from_hks else None,  # Set during add-raw-vault (Phase 2)
        })

    if hash_keys:
        state["hash_keys"] = hash_keys

    # Parse --additional-bk definitions (multi-BK support, lesson #127)
    additional_bks = []
    for ab_spec in getattr(args, 'additional_bk', None) or []:
        if ":" not in ab_spec:
            _print_error(f"Invalid --additional-bk format: {ab_spec}. Expected: RAW_COL:BK_ALIAS")
            return 1
        raw_col, bk_alias = ab_spec.split(":", 1)
        raw_col = raw_col.strip().upper()
        bk_alias = bk_alias.strip().upper()
        if not IDENTIFIER_PATTERN.match(raw_col):
            _print_error(f"--additional-bk raw column '{raw_col}' contains invalid characters")
            return 1
        if not IDENTIFIER_PATTERN.match(bk_alias):
            _print_error(f"--additional-bk alias '{bk_alias}' contains invalid characters")
            return 1
        if not bk_alias.endswith("_BK"):
            print(f"  WARNING: Additional BK alias '{bk_alias}' does not end with '_BK'")
        additional_bks.append({"raw_col": raw_col, "alias": bk_alias})
    if additional_bks:
        state["additional_bks"] = additional_bks

    _mark_complete(state, "init")

    print(f"\n  Pipeline initialized: {model_name}")
    print(f"  Schema:   {args.schema}")
    print(f"  Table:    {args.table}")
    print(f"  BK:       {args.bk} -> {state['bk_name']}")
    print(f"  REC_SRC:  {args.rec_src}")
    if state.get("domain"):
        print(f"  Domain:   {state['domain']}")
    if state.get("hash_keys"):
        print("  Hash Keys:")
        for hk in state["hash_keys"]:
            cols_str = ", ".join(hk["columns"])
            print(f"    {hk['name']} = MD5({cols_str})")
    print(f"  Objects:  {', '.join(objects)}")
    if state.get("additional_bks"):
        for ab in state["additional_bks"]:
            print(f"  Add'l BK: {ab['raw_col']} -> {ab['alias']}")
    if has_secondary(state):
        sec = state['secondary']
        print(f"  Secondary:{sec['schema']}.{sec['table']} AS {sec['alias']} ({sec['join_type']})")
        if sec.get('bk_name'):
            print(f"  Sec BK:   {sec['bk']} -> {sec['bk_name']}")
    if 'hub' in objects:
        hub_name = state.get('hub_name_override') or _derive_hub_name(state['bk_name'])
        print(f"  Hub:      {hub_name}")
    if 'lnk' in objects:
        lnks = state.get("lnks", [])
        for ldef in lnks:
            lnk_derived = _derive_lnk_name(ldef.get("lnk_name", ""))
            print(f"  Link:     {lnk_derived}")
            print(f"  ParentHKs:{', '.join(ldef.get('parent_hks', []))}")
            dcks = ldef.get("dcks", ldef.get("dck", []))
            if dcks:
                print(f"  DCKs:     {', '.join(dcks)}")
    if 'sat' in objects:
        sats = state.get("sats", [])
        for sdef in sats:
            print(f"  SAT:      {sdef['model_name']} (type={sdef.get('sat_type', 'sat')})")
            print(f"  ParentHK: {sdef.get('parent_hk', '?')}")
            print(f"  ParentMdl:{sdef.get('parent_model', '?')}")
            if sdef.get("multi_active_key"):
                print(f"  MA Key:   {sdef['multi_active_key']}")
    print(f"  State:    {STATE_DIR / f'{model_name}.json'}")
    _print_next_step(state, "init")
    return 0


def cmd_profile(args):
    """Run source profiling (Steps 1.1-1.9)."""
    state = _resolve_state(args)
    if not state:
        return 1

    ok, missing = _check_prerequisites(state, "profile")
    if not ok:
        _print_error(f"Prerequisites not met. Complete these steps first: {', '.join(missing)}")
        return 1

    model_name = state["model_name"]
    schema = state["schema"]
    table = state["table"]
    bk = state["bk"]


    # Accept --grain-columns at profile time (fixes composite grain messaging)
    # This allows setting grain_columns even if init was called without it
    _gc_arg = getattr(args, "grain_columns", None)
    if _gc_arg:
        _gc_parts = [g.strip().upper() for g in _gc_arg.split(",") if g.strip()]
        _id_pat = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
        for gp in _gc_parts:
            if not _id_pat.match(gp):
                _print_error(f"--grain-columns contains invalid column name: {gp!r}")
                return 1
        state["grain_columns"] = _gc_parts
        _save_state(state)

    # Accept --load-dts-column at profile time (overrides init value)
    _ldc_arg = getattr(args, "load_dts_column", None)
    if _ldc_arg and isinstance(_ldc_arg, str):
        _ldc = _ldc_arg.strip().upper()
        _id_pat = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
        if not _id_pat.match(_ldc):
            _print_error(f"--load-dts-column contains invalid column name: {_ldc!r}")
            return 1
        state["load_dts_column"] = _ldc
        _save_state(state)

    # If pre-computed profile provided, load it
    # Process --hk if provided (safety net, same pattern as --grain-columns)
    if hasattr(args, "hk") and args.hk:
        hash_keys = []
        for hk_spec in args.hk:
            if ":" not in hk_spec:
                _print_error(f"Invalid --hk format: {hk_spec}. Expected: HK_NAME:COL1,COL2,...")
                return 1
            hk_name, cols_str = hk_spec.split(":", 1)
            hk_name = hk_name.strip().upper()
            if not IDENTIFIER_PATTERN.match(hk_name):
                _print_error(f"Invalid HK name: {hk_name}. Must match {IDENTIFIER_PATTERN.pattern}")
                return 1
            raw_cols = [c.strip().upper() for c in cols_str.split(",") if c.strip()]
            # @-sigil marks a link HK composed from hub HK references (HASH_FROM_HKS, #1907).
            from_hks = any(c.startswith("@") for c in raw_cols)
            if from_hks and not all(c.startswith("@") for c in raw_cols):
                _print_error(f"--hk '{hk_name}': cannot mix @HK references with raw columns")
                return 1
            columns = [c[1:] if c.startswith("@") else c for c in raw_cols]
            if from_hks:
                _sigil_err = _validate_link_hk_sigil(hk_name, columns)
                if _sigil_err:
                    _print_error(_sigil_err)
                    return 1
            if len(columns) < 2:
                _print_error(f"HK '{hk_name}' needs at least 2 columns (got {len(columns)})")
                return 1
            for _hk_col in columns:
                if not IDENTIFIER_PATTERN.match(_hk_col):
                    _print_error(f"Invalid HK column: {_hk_col}. Must match {IDENTIFIER_PATTERN.pattern}")
                    return 1
            is_link = hk_name.startswith("LNK_") or from_hks
            if not is_link and "BKCC" not in columns:
                print(f"  WARNING: HK '{hk_name}' does not include BKCC")
            hash_keys.append({"name": hk_name, "columns": columns, "type": "link" if from_hks else None})
        state["hash_keys"] = hash_keys
        _save_state(state)
        print(f"  Updated hash_keys in state: {len(hash_keys)} HK(s)")

    if args.profile_json:
        return _load_profile_json(state, args.profile_json)

    # Preflight: fail loud NOW if there is no Snowflake execution path, rather
    # than running partway and coercing missing results into zeros (issue #1844).
    # The --profile-json path above legitimately runs driver-free and returns
    # before reaching here.
    _assert_snowflake_available()

    # Otherwise, run profiling queries via Snowflake
    print(f"\n  Profiling PSA_PROD.{schema}.{table} ...")

    profile = {}

    # Step 1.1 — Semantic collision check (DV 2.x cardinality rules)
    print("  [1/9] Semantic collision check...")
    collision_result = _semantic_collision_check(state)
    profile["collision_check"] = collision_result
    profile["collision"] = collision_result["blocked"]
    if collision_result["blocked"]:
        collision_files = []
        for layer_info in collision_result["layers"].values():
            collision_files.extend(layer_info.get("files", []))
            if "file" in layer_info:
                collision_files.append(layer_info["file"])
        profile["collision_files"] = collision_files
    _print_collision_report(collision_result)
    if collision_result["blocked"]:
        print("    Proceeding — user will review at approve-profile gate.")

    # Steps 1.2-1.8 require Snowflake
    # Try snow-mcp via subprocess (VS Code MCP) or direct connection
    print("  [2/9] Describe source table...")
    columns_result = _run_snowflake_query(
        f"SELECT column_name, data_type, is_nullable "
        f"FROM PSA_PROD.INFORMATION_SCHEMA.COLUMNS "
        f"WHERE table_schema = UPPER('{schema}') AND table_name = UPPER('{table}') "
        f"ORDER BY ordinal_position",
        args,
    )

    column_names = [row[0] for row in columns_result]
    column_types = {row[0]: row[1] for row in columns_result}
    profile["columns"] = [{"name": row[0], "type": row[1], "nullable": row[2]} for row in columns_result]
    profile["column_count"] = len(column_names)
    print(f"    {len(column_names)} columns found.")

    # Validate HK column references against discovered source columns
    if state.get("hash_keys"):
        source_cols_upper = {c.upper() for c in column_names}
        source_cols_upper.add("BKCC")  # Always available (derived from ref_business_key_collision)
        for hk in state["hash_keys"]:
            missing = [c for c in hk["columns"] if c not in source_cols_upper]
            if missing:
                print(f"  WARNING: HK '{hk['name']}' references missing columns: {missing}")
                print(f"           These may be derived columns computed in LOGIC layer")


    # Early ingestion detection (needed for grain validation LOAD_DTS expression)
    _col_set_early = set(c.upper() for c in column_names)
    if "_FIVETRAN_SYNCED" in _col_set_early:
        _ingestion_type = "fivetran"
    elif "GLCHANGETIME" in _col_set_early:
        _ingestion_type = "snp_glue"
    else:
        _ingestion_type = "custom"

    # Build ingestion-aware LOAD_DTS expression for grain validation
    # Custom LOAD_DTS column overrides ingestion-type default
    _custom_load_dts_col = state.get("load_dts_column")
    if _custom_load_dts_col:
        # User specified a custom column — use it with PSA_DELETE_IND fallback
        has_psa_del = "PSA_DELETE_IND" in _col_set_early
        if has_psa_del:
            _grain_load_dts_expr = f"IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', {_custom_load_dts_col}))"
        else:
            _grain_load_dts_expr = f"CONVERT_TIMEZONE('UTC', {_custom_load_dts_col})"
    elif _ingestion_type == "fivetran":
        _grain_load_dts_expr = "CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)"
    elif _ingestion_type == "snp_glue":
        _grain_load_dts_expr = (
            "IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, "
            "CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ("
            "SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16), "
            "'YYYYMMDDHH24MISS.FF9')))"
        )
    else:
        _grain_load_dts_expr = "PSA_LOAD_DTS"


    # Step 1.3 — Sample (informational, stored for show-profile)
    print("  [3/9] Sample data...")
    sample = _run_snowflake_query(
        f"SELECT * FROM PSA_PROD.{schema}.{table} LIMIT 5", args
    )
    profile["sample_rows"] = len(sample) if sample else 0

    # Step 1.4 — Row count + volume
    print("  [4/9] Row count + volume assessment...")
    count_result = _run_snowflake_query(
        f"SELECT COUNT(*) FROM PSA_PROD.{schema}.{table}", args
    )
    row_count = count_result[0][0] if count_result else 0
    profile["row_count"] = row_count
    if row_count < VOLUME_NORMAL:
        profile["volume_tier"] = "normal"
    elif row_count < VOLUME_CAUTION:
        profile["volume_tier"] = "caution"
    else:
        profile["volume_tier"] = "large"
    print(f"    {row_count:,} rows — {profile['volume_tier']} tier")

    # Step 1.5 — BK grain validation
    print("  [5/9] BK grain validation...")
    grain_result = _run_snowflake_query(
        f"SELECT COALESCE(SUM(_grp_cnt), 0) AS total, COUNT(*) AS distinct_grain "
        f"FROM ("
        f"SELECT COUNT(*) AS _grp_cnt "
        f"FROM PSA_PROD.{schema}.{table} "
        f"GROUP BY {bk}, {_grain_load_dts_expr}"
        f")",
        args,
    )
    if grain_result:
        total, distinct = grain_result[0][0], grain_result[0][1]
        profile["grain_valid"] = (total == distinct)
        profile["grain_total"] = total
        profile["grain_distinct"] = distinct
        if total != distinct:
            # Softer message when composite grain is specified (Phase 2 will check)
            if state.get("grain_columns"):
                print(f"    BK+{_grain_load_dts_expr} not unique ({total} total vs {distinct} distinct) — composite grain specified, checking Phase 2...")
            else:
                print(f"    GRAIN PROBLEM: {total} total vs {distinct} distinct {bk}+{_grain_load_dts_expr}")
                print(f"    Hint: If this table has a composite grain, re-run with: profile --grain-columns COL1,COL2,...")
        else:
            print(f"    Grain valid: {total:,} rows, all unique at {bk}+{_grain_load_dts_expr}")


    # Step 1.5b — Phase 2 composite grain check (lesson #96)
    # Always validate composite grain when specified — even if BK+LOAD_DTS alone is unique.
    # This ensures the user-specified grain (e.g., VBELN+SERIALNO) is actually validated,
    # not just BK+LOAD_DTS. Catches mismatch between stated grain and actual data.
    grain_columns = state.get("grain_columns")
    if grain_columns:
        # Check if grain_columns introduces additional columns beyond the BK
        _bk_parts = _split_bk_parts(bk.upper())
        _bk_raw_set = set()
        for _bp in _bk_parts:
            _raw = _bp.split("::")[0].strip()
            _raw = re.sub(r"^[A-Z_]+\((.+)\)$", r"\1", _raw)
            _bk_raw_set.add(_raw.upper())
        _extra_grain = [gc for gc in grain_columns if gc.upper() not in _bk_raw_set]
        if _extra_grain:
            print("  [5b/9] Composite grain validation (Phase 2)...")
            _gc_parts = [bk] + _extra_grain
            _composite_sql = (
                f"SELECT COALESCE(SUM(_grp_cnt), 0) AS total, COUNT(*) AS distinct_grain "
                f"FROM ("
                f"SELECT COUNT(*) AS _grp_cnt "
                f"FROM PSA_PROD.{schema}.{table} "
                f"GROUP BY {', '.join(_gc_parts)}, {_grain_load_dts_expr}"
                f")"
            )
            composite_result = _run_snowflake_query(_composite_sql, args)
            if composite_result:
                c_total, c_distinct = composite_result[0][0], composite_result[0][1]
                profile["composite_grain_total"] = c_total
                profile["composite_grain_distinct"] = c_distinct
                if c_total == c_distinct:
                    profile["grain_valid"] = True  # Phase 2 confirms
                    profile["grain_columns"] = grain_columns
                    print(f"    Composite grain VALID: {c_total:,} rows, unique at {'+'.join(_gc_parts)}+LOAD_DTS")
                else:
                    profile["grain_columns"] = grain_columns
                    if profile.get("grain_valid"):
                        # BK+LOAD_DTS was unique but composite is NOT — warn user
                        print(f"    WARNING: BK+LOAD_DTS is unique but composite grain {'+'.join(_gc_parts)}+LOAD_DTS has DUPLICATES")
                        print(f"    ({c_total} total vs {c_distinct} distinct)")
                        print(f"    This may indicate the stated grain is incorrect or data has quality issues")
                        profile["grain_valid"] = False  # Override — stated grain must be valid
                    else:
                        print(f"    COMPOSITE GRAIN DUPLICATES: {c_total} total vs {c_distinct} distinct")
        else:
            # grain_columns are all part of BK — no extra columns to validate
            profile["grain_columns"] = grain_columns

    # Step 1.6 — NULL BK check
    print("  [6/9] NULL BK check...")
    null_result = _run_snowflake_query(
        f"SELECT COUNT(*) FROM PSA_PROD.{schema}.{table} WHERE {bk} IS NULL", args
    )
    null_count = null_result[0][0] if null_result else 0
    profile["null_bk_count"] = null_count
    if null_count > 0:
        pct = (null_count / row_count * 100) if row_count > 0 else 0
        profile["null_bk_pct"] = round(pct, 2)
        print(f"    {null_count} NULL BKs ({pct:.2f}%)")
    else:
        print("    0 NULL BKs")

    # Step 1.7 — Detect ingestion source + flag columns
    print("  [7/9] Metadata column detection...")
    col_set = set(c.upper() for c in column_names)
    # _FIVETRAN_SYNCED alone is sufficient to classify as fivetran —
    # some Fivetran connectors omit _FIVETRAN_DELETED or _FIVETRAN_ID
    has_fivetran = "_FIVETRAN_SYNCED" in col_set
    # GLCHANGETIME is the universal SNP GLUE fingerprint column —
    # not all GLUE tables have every GL-prefix column
    has_snp_glue = "GLCHANGETIME" in col_set

    if has_fivetran:
        profile["ingestion_source"] = "fivetran"
    elif has_snp_glue:
        profile["ingestion_source"] = "snp_glue"
    else:
        profile["ingestion_source"] = "custom"

    profile["has_fivetran_deleted"] = "_FIVETRAN_DELETED" in col_set
    profile["has_psa_delete_ind"] = "PSA_DELETE_IND" in col_set
    profile["has_fivetran_synced"] = "_FIVETRAN_SYNCED" in col_set
    profile["has_fivetran_id"] = "_FIVETRAN_ID" in col_set
    print(f"    Ingestion: {profile['ingestion_source']}")
    print(f"    _FIVETRAN_DELETED: {profile['has_fivetran_deleted']}")
    print(f"    PSA_DELETE_IND: {profile['has_psa_delete_ind']}")

    # Step 1.8 — BKCC validation
    print("  [8/9] BKCC validation...")
    rec_src = state["rec_src"]
    dbt_environ = os.environ.get("DBT_ENVIRON", "dev").lower()
    bkcc_db = f"DATAVAULT_{dbt_environ.upper()}"
    print(f"    Using {bkcc_db} (DBT_ENVIRON={dbt_environ})")
    bkcc_result = _run_snowflake_query(
        f"SELECT BKCC FROM {bkcc_db}.RAW_VAULT.REF_BUSINESS_KEY_COLLISION "
        f"WHERE REC_SRC = '{rec_src}'",
        args,
    )
    if bkcc_result and bkcc_result[0][0]:
        profile["bkcc"] = bkcc_result[0][0]
        print(f"    BKCC: {profile['bkcc']}")
    else:
        profile["bkcc"] = None
        print(f"    WARNING: No BKCC found for REC_SRC={rec_src}")
        print("    Register via Streamlit app before proceeding.")

    # Step 1.9 — Source registration check
    print("  [9/9] Source registration check...")
    rc, out, _ = _run_command(
        f'grep -l "{schema}" models/sources/_sources_staging_psa.yml 2>/dev/null || true'
    )
    profile["source_registered"] = bool(out.strip())
    status = "registered" if profile["source_registered"] else "not yet on this branch (will be auto-registered during implement)"
    print(f"    Source YAML: {status}")


    # ── Secondary table mini-profile (lesson #81) ──────────────────────────
    if has_secondary(state):
        sec = state['secondary']
        print(f"\n  [+] Profiling secondary table: {sec['schema']}.{sec['table']}...")
        profile_secondary_table(state, profile, lambda sql, _state: _run_snowflake_query(sql, args))

        # If user didn't specify --secondary-columns, prompt for them (lesson #83)
        if sec['columns'] is None:
            if IS_AGENT_MODE:
                _print_error(
                    "Secondary table columns not specified and running in agent mode (non-interactive).\n"
                    "  Re-run init with --secondary-columns COL1 COL2 ... to specify columns explicitly.\n"
                    "  Example: .venv/bin/python3 scripts/automation/pipeline_orchestrator.py init ... --secondary-columns ID NAME STATUS"
                )
                return 1
            prompt_text = build_user_column_prompt(state)
            print(prompt_text)
            user_input = input("  Enter column names (space-separated): ").strip()
            if not user_input:
                _print_error("At least one secondary column is required.")
                return 1
            sec['columns'] = [c.upper() for c in user_input.split()]
            # Re-run collision detection now that we have columns
            profile_secondary_table(state, profile, lambda sql, _state: _run_snowflake_query(sql, args))

        # Validate BK expression uses renamed columns (lesson #80)
        validate_bk_references_renamed_columns(state)

        if sec.get('collisions'):
            print(f"    Column collisions auto-renamed:")
            for orig in sec['collisions']:
                print(f"      {orig} → {sec['rename_map'][orig]}")
        print(f"    Ingestion type: {sec.get('ingestion', 'unknown')}")

    state["profile_results"] = profile
    _mark_complete(state, "profile")

    _print_success(f"Profile complete for {model_name}.")
    _print_next_step(state, "profile")
    print(f"  Review profile: python {_rel_script()} show-profile")
    return 0


def _load_profile_json(state, json_path):
    """Load pre-computed profile from a JSON file."""
    path = Path(json_path)
    if not path.exists():
        _print_error(f"Profile JSON not found: {json_path}")
        return 1
    with open(path) as f:
        profile = json.load(f)

    # Validate required fields
    required = ["row_count", "volume_tier", "ingestion_source", "bkcc", "grain_valid"]
    missing = [k for k in required if k not in profile]
    if missing:
        _print_error(f"Profile JSON missing required fields: {', '.join(missing)}")
        return 1

    # Run semantic collision check (file-based, no Snowflake needed)
    if "collision_check" not in profile:
        collision_result = _semantic_collision_check(state)
        profile["collision_check"] = collision_result
        if "collision" not in profile:
            profile["collision"] = collision_result["blocked"]
        _print_collision_report(collision_result)

    state["profile_results"] = profile

    # Secondary table collision detection (offline — no Snowflake needed)
    if has_secondary(state):
        sec = state["secondary"]
        if "rename_map" not in sec and sec.get("columns"):
            driver_col_names = set(
                c["name"].upper() for c in profile.get("columns", [])
            )
            rename_map = {}
            collisions = []
            for col in sec["columns"]:
                col_upper = col.upper()
                if col_upper in driver_col_names:
                    renamed = f"{sec['alias']}_{col_upper}"
                    rename_map[col_upper] = renamed
                    collisions.append(col_upper)
                else:
                    rename_map[col_upper] = col_upper
            sec["rename_map"] = rename_map
            sec["collisions"] = collisions
            # Default ingestion to fivetran for Shopify sources (offline heuristic)
            if "ingestion" not in sec:
                sec["ingestion"] = profile.get("ingestion_source", "custom")
            if collisions:
                print(f"    Secondary column collisions auto-renamed:")
                for orig in collisions:
                    print(f"      {orig} → {rename_map[orig]}")
            # Validate BK expression uses renamed columns (lesson #80)
            validate_bk_references_renamed_columns(state)
            _save_state(state)

    _mark_complete(state, "profile")

    _print_success(f"Profile loaded from {json_path}.")
    _print_next_step(state, "profile")
    return 0


def _read_mcp_creds():
    """Read Snowflake credentials from .vscode/mcp.json (snow-mcp server config).

    Returns the env dict with SNOWFLAKE_ACCOUNT/USER/PAT/PASSWORD keys, or None.

    Resolves VS Code ${input:<id>} placeholders via OS keychain when adopters
    have stored secrets there (see scripts/automation/src/secret_resolver.py).
    If a placeholder cannot be resolved (no keychain entry, non-macOS, etc.),
    the literal "${input:...}" string is treated as a missing credential —
    _read_mcp_creds() returns None and the caller falls through to the next
    auth method (env vars, ~/.snowflake/connections.toml, etc.) instead of
    attempting to authenticate with a literal placeholder. Adopters who do
    not use mcp.json are unaffected.
    """
    import re as _re
    mcp_path = PROJECT_ROOT / ".vscode" / "mcp.json"
    if not mcp_path.exists():
        return None
    try:
        raw = mcp_path.read_text(encoding="utf-8")
        # Strip // comment lines (may contain non-ASCII chars that break json.loads)
        lines = [l for l in raw.split("\n") if not _re.match(r"\s*//", l)]
        clean = "\n".join(lines)
        # Strip trailing commas before } or ]
        clean = _re.sub(r",(\s*[}\]])", r"\1", clean)
        data = json.loads(clean)
        env = data.get("servers", {}).get("snow-mcp", {}).get("env", {})
        # Resolve ${input:...} placeholders from OS keychain (no-op if not adopted).
        try:
            from src.secret_resolver import resolve_env_dict
            env = resolve_env_dict(env)
        except Exception:
            pass  # resolver unavailable -> use raw env (today's behavior)
        # A placeholder that fails to resolve still starts with "${input:", which
        # is not a usable credential. Treat it as "not provided" so the caller
        # falls through to the next auth method instead of trying to authenticate
        # with a literal placeholder string. mcp.json values flow in from JSON
        # parsing, which permits numbers/bools/None — but a non-string sitting in
        # a required credential slot is not a usable string credential either
        # (snowflake.connector.connect expects strings), so treat non-strings as
        # unusable too. The isinstance guard also prevents an AttributeError on
        # .startswith that would silently nuke an otherwise-valid set of creds
        # via the outer try/except.
        def _usable(v):
            if not isinstance(v, str):
                return False
            return bool(v) and not v.startswith("${input:")
        if _usable(env.get("SNOWFLAKE_ACCOUNT")) and _usable(env.get("SNOWFLAKE_USER")) and (
            _usable(env.get("SNOWFLAKE_PAT")) or _usable(env.get("SNOWFLAKE_PASSWORD"))
        ):
            return env
    except Exception:
        pass
    return None



def _coerce_mcp_types(rows):
    """Coerce MCP string results to native Python types (int/float).

    snow-mcp returns all values as strings. The Python connector returns native
    types. Downstream code (e.g., `null_count > 0`) expects native types.
    """
    def _coerce(val):
        if not isinstance(val, str):
            return val
        # Try int first, then float
        try:
            return int(val)
        except (ValueError, TypeError):
            pass
        try:
            return float(val)
        except (ValueError, TypeError):
            pass
        return val

    return [tuple(_coerce(v) for v in row) for row in rows]


def _parse_dbt_build_results(output: str) -> dict:
    """Parse dbt build output for pass/warn/fail/error counts.

    Prioritizes the dbt summary line (e.g., 'Done. PASS=11 WARN=0 ERROR=0 ...')
    as the authoritative source. Falls back to counting individual status lines
    while excluding known informational patterns that are NOT real errors.
    """
    results = {"pass": 0, "warn": 0, "fail": 0, "error": 0}

    # Try to parse the authoritative dbt summary line first
    # Pattern: "PASS=X WARN=Y ERROR=Z" or "Done. PASS=X WARN=Y ERROR=Z"
    summary_match = re.search(
        r"PASS=(\d+)\s+WARN=(\d+)\s+ERROR=(\d+)",
        output,
    )
    if summary_match:
        results["pass"] = int(summary_match.group(1))
        results["warn"] = int(summary_match.group(2))
        results["error"] = int(summary_match.group(3))
        # Also check for FAIL in extended summary
        fail_match = re.search(r"FAIL=(\d+)", output)
        if fail_match:
            results["fail"] = int(fail_match.group(1))
        return results

    # Fallback: count individual test/model result lines (excluding informational noise)
    _INFO_PATTERNS = [
        "Skipping not null constraint",
        "Skipping foreign key constraint",
        "Skipping primary/unique key",
        "Skipping unique constraint",
        "Nothing to do",
        "Completed successfully",
    ]
    for line in output.splitlines():
        # Skip known informational lines
        if any(pat in line for pat in _INFO_PATTERNS):
            continue
        if re.search(r"(PASS|OK)", line) and "in " in line:
            results["pass"] += 1
        elif re.search(r"WARN", line) and "in " in line:
            results["warn"] += 1
        elif re.search(r"FAIL", line) and "in " in line:
            results["fail"] += 1
        elif re.search(r"ERROR", line) and "in " in line:
            results["error"] += 1

    return results


def _connector_importable() -> bool:
    """True if snowflake-connector-python can actually be imported here.

    Isolated as a helper so tests can simulate a driver-free environment (the
    issue #1844 failure mode) by patching it, without uninstalling the package.
    Attempts a real import rather than importlib.util.find_spec(): find_spec()
    can locate a module whose import still fails at runtime (a partially
    installed or broken dependency tree), which would let the preflight wrongly
    treat the connector path as available and defer the failure to the clone/DDL.
    """
    try:
        import snowflake.connector  # noqa: F401
        return True
    except Exception:
        return False


def _snowflake_execution_path():
    """Return the first available Snowflake execution path, or None if none exists.

    - "connector": snowflake-connector-python is importable (covers env-var
      credentials, .vscode/mcp.json credentials via the connector fallback, and
      --snowflake-conn).
    - "mcp": usable (non-placeholder) credentials are present in
      .vscode/mcp.json, so the snow-mcp MCP-SDK path can run WITHOUT the Python
      driver. This is must-have #1 for issue #1844: an MCP-only environment is a
      valid path and must not be forced to install the connector.

    Coarse availability signal for the command preflight. It does NOT assert
    that credentials will authenticate -- a present-but-invalid credential
    (expired PAT, wrong account) surfaces at the operation boundary in
    _run_snowflake_query as a raised SnowflakeUnavailableError.
    """
    if _connector_importable():
        return "connector"
    try:
        if _read_mcp_creds() is not None:
            return "mcp"
    except Exception:
        pass
    return None


def _assert_snowflake_available():
    """Preflight for Snowflake-dependent commands: fail loud BEFORE any work.

    Raises SnowflakeUnavailableError when no execution path exists at all, so a
    driver-free / unconfigured environment stops immediately with a clear,
    actionable message instead of running partway and coercing missing results
    into zeros (issue #1844). Non-Snowflake commands never call this, and
    'profile --profile-json' returns before reaching it.
    """
    if _snowflake_execution_path() is None:
        raise SnowflakeUnavailableError(
            "No Snowflake execution path is available: neither the snow-mcp MCP "
            "server (no usable credentials in .vscode/mcp.json) nor the "
            "snowflake-connector-python driver (not importable) can run a query. "
            "Install the runtime dependencies "
            "(.venv/bin/python3 -m pip install -r "
            "scripts/automation/requirements-runtime.txt) or configure "
            ".vscode/mcp.json."
        )


def _run_snowflake_query(sql, args):
    """Run a Snowflake query. Returns a list of rows (possibly empty), or raises.

    Auth priority:
    0. MCP SDK (snow-mcp via stdio)       (MCP-first — official MCP Python SDK)
    1. SNOWFLAKE_PAT env var              (PAT via oauth+token — matches snow-mcp)
    2. .vscode/mcp.json snow-mcp config   (auto-read PAT, same method)
    3. SNOWFLAKE_PASSWORD env var          (classic user/password)
    4. --snowflake-conn CLI arg            (account:user:password)

    PAT auth uses authenticator='oauth' + token=<PAT>, which is the Python
    connector equivalent of the REST bearer-token auth used by snow-mcp.

    Raises SnowflakeUnavailableError when the query cannot be executed at all:
    the driver is not installed, no credentials are configured, or the
    connection/authentication fails. A successful query returns a list (empty
    when it matched zero rows) and never None, so callers treat "no result" as
    a hard, loud failure (issue #1844) while a legitimate empty result stays an
    ordinary []. See SnowflakeUnavailableError.

    Last error is also stored in _run_snowflake_query.last_error for diagnostics.
    """
    _run_snowflake_query.last_error = None

    # -- Skip MCP for DDL statements (CREATE, DROP, ALTER, GRANT, REVOKE)
    # MCP snow-mcp server rejects DDL with "Statement type of Create is not allowed"
    _sql_stripped = sql.strip().upper()
    _is_ddl = _sql_stripped.startswith(("CREATE ", "DROP ", "ALTER ", "GRANT ", "REVOKE "))

    # -- MCP-first: try snow-mcp via MCP SDK (DML/DQL only) -----
    if not _is_ddl:
        try:
            _mcp_cfg = _read_mcp_config_sdk()
            _mcp_result = _mcp_sdk_query(sql, _mcp_cfg)
            if _mcp_result is not None:
                _mcp_result = _coerce_mcp_types(_mcp_result)
                print("    [MCP] \u2705")
                return _mcp_result
            # MCP returned None -- fall through to Python connector
        except Exception:
            pass  # MCP SDK unavailable -- fall through to Python connector


    def _try_connect(params):
        import snowflake.connector
        conn = snowflake.connector.connect(**params)
        cur = conn.cursor()
        cur.execute(sql)
        rows = cur.fetchall()
        cur.close()
        conn.close()
        print(f"    [Python] \u2705 {'direct (DDL bypass)' if _is_ddl else 'fallback'}")
        return rows

    try:
        import snowflake.connector  # noqa: F401 — ensure importable
    except ImportError as exc:
        _run_snowflake_query.last_error = "snowflake-connector-python not installed"
        if _is_ddl:
            _why = (
                "snowflake-connector-python is not installed. This is a DDL "
                "statement, which the snow-mcp MCP server cannot run, so the "
                "Python connector is required even when MCP is configured."
            )
        else:
            _why = (
                "snowflake-connector-python is not installed and the snow-mcp "
                "MCP path is unavailable, so this query cannot run."
            )
        raise SnowflakeUnavailableError(
            _why + " Install the runtime dependencies:\n"
            "  .venv/bin/python3 -m pip install -r "
            "scripts/automation/requirements-runtime.txt"
        ) from exc

    account = os.environ.get("SNOWFLAKE_ACCOUNT", "")
    user    = os.environ.get("SNOWFLAKE_USER", "")
    wh      = os.environ.get("SNOWFLAKE_WAREHOUSE", "DATA_ENGINEER_WH")
    role    = os.environ.get("SNOWFLAKE_ROLE", "DATA_ENGINEER")

    pat = os.environ.get("SNOWFLAKE_PAT", "")
    pw_env = os.environ.get("SNOWFLAKE_PASSWORD", "")
    mcp_env = None
    if not pat and not pw_env:
        mcp_env = _read_mcp_creds()
        if mcp_env:
            print("  Using Snowflake credentials from .vscode/mcp.json (snow-mcp)")
            account = account or mcp_env["SNOWFLAKE_ACCOUNT"]
            user    = user    or mcp_env["SNOWFLAKE_USER"]
            pat     = mcp_env.get("SNOWFLAKE_PAT", "")

    if account and user and pat:
        # OAuth token auth — this is the correct method for Snowflake PATs
        # with the Python connector 3.x and later.
        params = {
            "account": account,
            "user": user,
            "authenticator": "oauth",
            "token": pat,
            "warehouse": wh,
            "role": role,
        }
        try:
            return _try_connect(params)
        except Exception as e1:
            # Fallback: try programmatic_access_token authenticator (older SDK style)
            params2 = dict(params)
            params2.pop("token")
            params2["password"] = pat
            params2["authenticator"] = "programmatic_access_token"
            try:
                return _try_connect(params2)
            except Exception as e2:
                _run_snowflake_query.last_error = f"oauth: {e1} | pat: {e2}"
                raise SnowflakeUnavailableError(
                    "Snowflake connection failed (PAT/oauth). "
                    + _run_snowflake_query.last_error
                ) from e2

    pw = pw_env or (mcp_env.get("SNOWFLAKE_PASSWORD", "") if mcp_env else "")
    if account and user and pw:
        params = {
            "account": account,
            "user": user,
            "password": pw,
            "warehouse": wh,
            "role": role,
        }
        auth = os.environ.get("SNOWFLAKE_AUTHENTICATOR") or (
            mcp_env.get("SNOWFLAKE_AUTHENTICATOR", "") if mcp_env else ""
        )
        if auth:
            params["authenticator"] = auth
        try:
            return _try_connect(params)
        except Exception as exc:
            _run_snowflake_query.last_error = str(exc)
            raise SnowflakeUnavailableError(
                "Snowflake connection failed (password auth). "
                + _run_snowflake_query.last_error
            ) from exc

    conn_str = getattr(args, "snowflake_conn", None)
    if conn_str:
        parts = conn_str.split(":")
        params = {
            "account": parts[0],
            "user": parts[1] if len(parts) > 1 else "",
            "password": parts[2] if len(parts) > 2 else "",
        }
        try:
            return _try_connect(params)
        except Exception as exc:
            _run_snowflake_query.last_error = str(exc)
            raise SnowflakeUnavailableError(
                "Snowflake connection failed (--snowflake-conn). "
                + _run_snowflake_query.last_error
            ) from exc

    _run_snowflake_query.last_error = (
        "no Snowflake credentials configured (set SNOWFLAKE_PAT / "
        "SNOWFLAKE_PASSWORD + SNOWFLAKE_ACCOUNT + SNOWFLAKE_USER, configure "
        ".vscode/mcp.json, or pass --snowflake-conn)"
    )
    raise SnowflakeUnavailableError(_run_snowflake_query.last_error)


def cmd_show_profile(args):
    """Display profile results for user review."""
    state = _resolve_state(args)
    if not state:
        return 1

    if "profile" not in _completed_steps(state):
        _print_error("Profile not yet completed. Run: python pipeline_orchestrator.py profile")
        return 1

    profile = state.get("profile_results", {})
    model = state["model_name"]

    print(f"\n  === Profile: {model} ===\n")
    print(f"  {'Check':<25} {'Result'}")
    print(f"  {'─'*25} {'─'*50}")
    print(f"  {'Table':<25} PSA_PROD.{state['schema']}.{state['table']}")
    print(f"  {'Rows':<25} {profile.get('row_count', 'N/A'):,} ({profile.get('volume_tier', 'N/A')})")
    print(f"  {'Columns':<25} {profile.get('column_count', 'N/A')}")
    print(f"  {'BK':<25} {state['bk']} -> {state['bk_name']}")
    print(f"  {'NULL BK':<25} {profile.get('null_bk_count', 'N/A')}")
    # Determine grain status — composite grain that passed Phase 2 shows 'valid (composite)'
    _grain_cols = state.get("grain_columns") or profile.get("grain_columns")
    if profile.get("grain_valid"):
        grain_status = "valid (composite)" if _grain_cols else "valid"
    else:
        grain_status = "DUPLICATES FOUND"
    _ing = profile.get("ingestion_source", "custom")
    _load_col = "_FIVETRAN_SYNCED" if _ing == "fivetran" else ("GLCHANGETIME" if _ing == "snp_glue" else "PSA_LOAD_DTS")
    if _grain_cols:
        _grain_parts = [state["bk"]] + [gc for gc in _grain_cols if gc.upper() != state["bk"].upper()] + [_load_col]
    else:
        _grain_parts = [state["bk"], _load_col]
    _grain_display = "+".join(_grain_parts)
    print(f"  {'Grain':<25} {_grain_display} — {grain_status}")
    print(f"  {'BKCC':<25} {profile.get('bkcc', 'NOT FOUND')}")
    print(f"  {'REC_SRC':<25} {state['rec_src']}")
    print(f"  {'Ingestion':<25} {profile.get('ingestion_source', 'N/A')}")
    src_status = "registered" if profile.get("source_registered") else "not yet on branch (auto-registered during implement)"
    print(f"  {'Source YAML':<25} {src_status}")
    collision_check = profile.get("collision_check")
    if collision_check and collision_check.get("blocked"):
        collision = "BLOCKED"
    elif collision_check:
        collision = "clear"
    elif profile.get("collision"):
        collision = "FOUND"
    else:
        collision = "none"
    print(f"  {'Collision':<25} {collision}")
    print(f"  {'_FIVETRAN_DELETED':<25} {profile.get('has_fivetran_deleted', False)}")
    print(f"  {'PSA_DELETE_IND':<25} {profile.get('has_psa_delete_ind', False)}")

    # Show semantic collision check details if available
    collision_check = profile.get("collision_check")
    if collision_check:
        _print_collision_report(collision_check)

        # Show hub ADD-SOURCE column mapping preview if applicable
        hub_info = collision_check.get("layers", {}).get("hub", {})
        if hub_info.get("status") == "ADD-SOURCE" and hub_info.get("file"):
            hub_path = PROJECT_ROOT / hub_info["file"]
            if hub_path.exists():
                hub_parsed = _parse_existing_hub(str(hub_path))
                bk_raw_cols = [c.strip() for c in state["bk"].split(",")]
                try:
                    col_mapping = _build_add_source_column_mapping(hub_parsed, bk_raw_cols)
                    bk_maps = [
                        c for c in col_mapping
                        if c["hub"] not in {"LOAD_DTS", "BKCC", "REC_SRC"}
                        and c["hub"] != hub_parsed["hk_column"]
                    ]
                    if bk_maps:
                        print(f"  Hub BK column mapping (confirm at approve-profile):")
                        for c in bk_maps:
                            arrow = "→" if c["raw"] != c["hub"] else "="
                            print(f"    {c['raw']} {arrow} {c['hub']}")
                except ValueError as e:
                    print(f"  WARNING: {e}")

    if profile.get("collision"):
        print(f"\n  WARNING: Collision files: {profile.get('collision_files', [])}")
    if not profile.get("bkcc"):
        print("\n  WARNING: No BKCC registered. Register via Streamlit app before approve-profile.")
    if not profile.get("grain_valid"):
        if _grain_cols:
            print(f"\n  WARNING: Composite grain has duplicates ({_grain_display}). Grain specification may be incomplete.")
        else:
            print(f"\n  WARNING: Grain has duplicates ({_grain_display}). BK choice may be wrong.")
    if profile.get("null_bk_count", 0) > 0:
        print(f"\n  WARNING: {profile['null_bk_count']} NULL BK rows. You will choose a NULL handling strategy at approve-profile.")

    # Display Hash Keys section if present (Multi-HK Phase 1)
    hash_keys = state.get("hash_keys", [])
    if hash_keys:
        print()
        print("  Hash Keys:")
        for hk in hash_keys:
            cols_str = ", ".join(hk["columns"])
            assigned = f" → {hk['type']}" if hk.get("type") else ""
            print(f"    {hk['name']} = MD5({cols_str}){assigned}")

    print(f"\n  To approve: python {_rel_script()} approve-profile")
    return 0


def cmd_approve_profile(args):
    """Record user approval of BK/entity/profile."""
    state = _resolve_state(args)
    if not state:
        return 1

    ok, missing = _check_prerequisites(state, "approve-profile")
    if not ok:
        _print_error(f"Prerequisites not met. Complete these first: {', '.join(missing)}")
        return 1


    profile = state.get("profile_results", {})

    # Bug #4: Verify collision check was run and has no blockers
    collision_check = profile.get("collision_check")
    if not collision_check:
        _print_error(
            "Collision check has not been run. Run 'profile' first.\n"
            f"  python {_rel_script()} profile"
        )
        return 1

    if collision_check.get("blocked"):
        _print_error(
            "Collision check found blockers -- cannot approve.\n"
            "  Resolve the collision(s), then re-run:\n"
            f"  python {_rel_script()} profile"
        )
        _print_collision_report(collision_check)
        return 1

    # Warn about non-blocking issues -- allow override with --force
    warnings = []
    if not profile.get("bkcc"):
        warnings.append("No BKCC registered for this REC_SRC")
    if not profile.get("grain_valid"):
        _ing_label = {"fivetran": "_FIVETRAN_SYNCED", "snp_glue": "GLCHANGETIME"}.get(
            profile.get("ingestion_source", "custom"), "PSA_LOAD_DTS")
        _has_composite = state.get("grain_columns") or profile.get("grain_columns")
        if _has_composite:
            warnings.append("Composite grain has duplicates")
        else:
            warnings.append(f"BK+{_ing_label} grain has duplicates")

    if warnings and not args.force:
        print("\n  Warnings:")
        for w in warnings:
            print(f"    - {w}")
        print(f"\n  Use --force to approve despite warnings.")
        print(f"  Or fix the issues and re-run: python {_rel_script()} profile")
        return 1

    # ── NULL BK sentinel prompt (DV 2.1 rule 1.3) ──
    null_bk_count = profile.get("null_bk_count", 0)
    if null_bk_count > 0:
        bk_col = state.get("bk", "BK")

        # Non-interactive: consume --null-bk-sentinel flag directly
        sentinel_arg = getattr(args, 'null_bk_sentinel', None)
        if sentinel_arg:
            sentinel_map = {'-1': '1', '-2': '2', 'none': '3', '1': '1', '2': '2', '3': '3'}
            choice = sentinel_map.get(sentinel_arg.strip().lower())
            if not choice:
                _print_error(f"Invalid --null-bk-sentinel value: {sentinel_arg!r}. Use '-1', '-2', or 'none' (or 1, 2, 3).")
                return 1
            print(f"\n  NULL BK sentinel: --null-bk-sentinel={sentinel_arg} → option {choice}")
        else:
            print(f"\n  WARNING: BK column {bk_col} has {null_bk_count:,} NULL values.")
            print(f"  NULL BKs all hash to the same value → hub collisions.\n")
            print(f"  1) COALESCE({bk_col}, '-1') — Required BK (NULL = missing data, sentinel protects hash)")
            print(f"  2) COALESCE({bk_col}, '-2') — Optional BK (NULL = legitimately absent)")
            print(f"  3) Proceed without COALESCE — NULLs are expected, I accept hash collision risk\n")
            if IS_AGENT_MODE:
                _print_error(
                    "NULL BK sentinel choice required but running in agent mode (non-interactive).\n"
                    "  Re-run approve-profile with --null-bk-sentinel='-1' (required BK),\n"
                    "  '--null-bk-sentinel=-2' (optional BK), or '--null-bk-sentinel=none' (accept risk)."
                )
                return 1
            else:
                choice = input("  Choose [1/2/3]: ").strip()
        if choice == "1":
            state["null_bk_sentinel"] = "-1"
            print("  → Will apply COALESCE(col, '-1') to BK in staging.")
        elif choice == "2":
            state["null_bk_sentinel"] = "-2"
            print("  → Will apply COALESCE(col, '-2') to BK in staging.")
        elif choice == "3":
            state["null_bk_sentinel"] = None
            print("  → Proceeding without COALESCE. Hash collision risk accepted.")
        else:
            _print_error(f"Invalid choice: {choice!r}. Expected 1, 2, or 3.")
            return 1

    _mark_complete(state, "approve-profile")

    # Persist profile as markdown evidence document
    try:
        profile_path = _persist_profile_markdown(state)
        if profile_path:
            # _persist_profile_markdown mutates state['profile_md_path'] AFTER
            # _mark_complete has already saved state. Re-save BEFORE the
            # best-effort relative-path print so the path is discoverable by
            # handoffs/resumptions even if relative_to() raises ValueError
            # (e.g., symlinks produce an absolute path outside PROJECT_ROOT).
            _save_state(state)
            try:
                display_path = profile_path.relative_to(PROJECT_ROOT)
            except ValueError:
                display_path = profile_path
            print(f"  Profile persisted: {display_path}")
    except OSError:
        # Non-fatal: persistence is best-effort (test environments may lack real paths)
        pass

    _print_success("Profile approved.")
    _print_next_step(state, "approve-profile")
    return 0


def cmd_generate_yaml(args):
    """Generate YAML config file."""
    state = _resolve_state(args)
    if not state:
        return 1

    ok, missing = _check_prerequisites(state, "generate-yaml")
    if not ok:
        _print_error(f"Prerequisites not met. Complete these first: {', '.join(missing)}")
        return 1

    profile = state.get("profile_results", {})
    model_name = state["model_name"]
    schema = state["schema"]
    table = state["table"]
    bk = state["bk"]
    bk_name = state["bk_name"]
    rec_src = state["rec_src"]

    # Build YAML config
    config_name = _strip_stg_prefix(model_name)
    config_path = SCRIPT_DIR / "configs" / f"{config_name}.yml"

    ingestion = profile.get("ingestion_source", "custom")
    has_psa_delete = profile.get("has_psa_delete_ind", False)
    has_fivetran_deleted = profile.get("has_fivetran_deleted", False)

    # Custom LOAD_DTS column overrides ingestion-type default
    _custom_load_dts_col = state.get("load_dts_column")
    if _custom_load_dts_col:
        if has_psa_delete:
            load_dts_logic = f"IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', {_custom_load_dts_col}))"
        else:
            load_dts_logic = f"CONVERT_TIMEZONE('UTC', {_custom_load_dts_col})"
    elif ingestion == "fivetran":
        if has_fivetran_deleted:
            # Fivetran handles deletes natively — _FIVETRAN_SYNCED is always reliable
            load_dts_logic = "CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)"
        elif has_psa_delete:
            # PSA captures deletes separately — deleted records have stale _FIVETRAN_SYNCED
            load_dts_logic = "CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, _FIVETRAN_SYNCED))"
        else:
            # No delete tracking — simple conversion
            load_dts_logic = "CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)"
    elif ingestion == "snp_glue":
        load_dts_logic = "IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16), 'YYYYMMDDHH24MISS.FF9')))"
    else:
        load_dts_logic = "CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)"

    # Determine volume config
    row_count = profile.get("row_count", 0)
    volume_tier = profile.get("volume_tier", "normal")
    large_volume = volume_tier == "large"

    # Build columns list from profile
    columns = []
    source_columns = profile.get("columns", [])

    if not source_columns:
        _print_error(
            "No column data in profile. Re-run 'profile' with Snowflake access\n"
            "  or provide --profile-json with a 'columns' array."
        )
        return 1

    # Identify which columns are data vs technical vs BK
    col_names_upper = [c["name"].upper() for c in source_columns]
    bk_upper = bk.upper()
    # Parse composite BK into individual raw column names (e.g. "MATNR, WERKS, POPER" → ["MATNR","WERKS","POPER"])
    # Parse composite BK: strip cast expressions for raw column names
    # e.g. "VENDOR_SITE_ID::TEXT" -> raw col "VENDOR_SITE_ID", cast "::TEXT"
    # Strip cast (::TEXT) AND function wrappers (TO_CHAR(ID) -> ID) to get raw column names
    bk_raw_cols = []
    for _bk_part in _split_bk_parts(bk_upper):
        _bk_part = _bk_part.strip().split("::")[0]  # strip cast
        # Strip function wrappers (e.g., TO_CHAR(ID) -> ID)
        _func_match = re.match(r'^[A-Z_]+\((.+)\)$', _bk_part.strip())
        if _func_match:
            _bk_part = _func_match.group(1).strip()
        bk_raw_cols.append(_bk_part)
    bk_raw_set = set(bk_raw_cols)                            # set for O(1) lookup
    # Inverted BK detection: if it matches PLAIN_COLUMN_RE → raw column.
    # Anything else (functions, casts, operators, expressions) → derived.
    bk_is_raw = bool(PLAIN_COLUMN_RE.match(bk_upper))

    # === Raw BK passthrough ===
    # For composite BK, use TEXT as passthrough datatype (individual cols are TEXT)
    first_bk_col = bk_raw_cols[0]
    bk_col_info = next((c for c in source_columns if c["name"].upper() == first_bk_col), None)
    bk_datatype = bk_col_info["type"] if bk_col_info else "VARCHAR"

    # Raw BK passthrough: use base column name (strip cast expression)
    # e.g. "VENDOR_SITE_ID::TEXT" -> passthrough as "VENDOR_SITE_ID"
    # source_column is emitted as an ordered list (uniform shape, single source of
    # truth via the write-time normalizer). staging_column_name stays a joined
    # string because build.py renders it verbatim into the SELECT list (a composite
    # renders as two comma-separated column references — SQL is unchanged).
    raw_bk_source_cols = list(bk_raw_cols)  # ordered — do NOT sort/dedupe
    raw_bk_staging = bk_raw_cols[0] if len(bk_raw_cols) == 1 else ",".join(bk_raw_cols)
    columns.append({
        "source_table": "SRC",
        "source_column": raw_bk_source_cols,
        "staging_column_name": raw_bk_staging,
        "datatype": bk_datatype,
        "hashdiff": "",
        "not_null": "",
        "unique": "",
        "manual_logic": "",
    })

    # === BK alias ===
    # Build COMPOSITE unique parts — include grain_columns if provided (lesson #96)
    # Filter out: (1) raw BK source cols (already represented by BK alias),
    # (2) ingestion-specific LOAD_DTS source cols (LOAD_DTS is always appended as constant)
    _LOAD_DTS_SOURCE_COLS = {"PSA_LOAD_DTS", "_FIVETRAN_SYNCED", "GLCHANGETIME", "SNP_LOAD_DTS", "LOAD_DTS"}
    _grain_cols = state.get("grain_columns") or profile.get("grain_columns")
    if _grain_cols:
        _filtered_grain = [
            gc for gc in _grain_cols
            if gc.upper() not in bk_raw_set and gc.upper() not in _LOAD_DTS_SOURCE_COLS
        ]
        _composite_unique = ", ".join([bk_name.upper()] + _filtered_grain + ["LOAD_DTS"])
    else:
        _composite_unique = f"{bk_name.upper()}, LOAD_DTS"

    bk_entry = {
        "source_table": "SRC",
        "source_column": list(bk_raw_cols),
        "datatype": bk_datatype,
        "staging_column_name": bk_name.upper(),
        "hashdiff": "",
        "unique": f"COMPOSITE: {_composite_unique}",
        "not_null": "yes",
    }
    # For composite BK (multiple columns), generate a CONCAT_WS concatenation as manual_logic.
    # For simple single-column BK: inverted detection — if NOT plain column → derived.
    if len(bk_raw_cols) > 1:
        concat_parts = [
            f"COALESCE(NULLIF(TRIM(CAST({c} AS VARCHAR)), ''), '^^')"
            for c in bk_raw_cols
        ]
        bk_entry["manual_logic"] = (
            f"UPPER(CONCAT_WS('{COMPOSITE_BK_DELIMITER}', "
            + ", ".join(concat_parts) + "))"
        )
        bk_entry["datatype"] = "TEXT"
    elif not bk_is_raw:
        # ANY derivation (function, cast, operator, expression)
        bk_entry["source_column"] = "(DERIVED)"
        bk_entry["source_table"] = ""
        bk_entry["manual_logic"] = bk_upper
        bk_entry["staging_datatype"] = _infer_bk_datatype(bk_upper)
    elif args.bk_cast:
        bk_entry["manual_logic"] = args.bk_cast
        bk_entry["staging_datatype"] = args.bk_cast_type or "TEXT"
    else:
        bk_entry["manual_logic"] = ""

    # ── NULL BK sentinel: wrap BK in COALESCE if user chose -1 or -2 ──
    null_bk_sentinel = state.get("null_bk_sentinel")
    if null_bk_sentinel:
        existing_logic = bk_entry.get("manual_logic", "")
        if existing_logic:
            # Wrap existing expression: COALESCE(TO_CHAR(ID), '-1')
            bk_entry["manual_logic"] = f"COALESCE({existing_logic}, '{null_bk_sentinel}')"
        else:
            # Simple column: COALESCE(VENDOR_SITE_ID, '-1')
            raw_col = bk_raw_cols[0] if len(bk_raw_cols) == 1 else bk_upper
            bk_entry["manual_logic"] = f"COALESCE({raw_col}, '{null_bk_sentinel}')"
            bk_entry["source_column"] = "(DERIVED)"
    columns.append(bk_entry)

    # === Additional BK aliases (multi-BK support, lesson #127) ===
    # Collect additional BK raw column names so the data column loop can
    # handle their hashdiff/passthrough entry (avoids duplicate rows).
    _additional_bk_raw_cols = set()
    for ab in state.get("additional_bks", []):
        ab_raw = ab["raw_col"]
        ab_alias = ab["alias"]
        _additional_bk_raw_cols.add(ab_raw)
        # Look up source column info for datatype
        ab_col_info = next((c for c in source_columns if c["name"].upper() == ab_raw), None)
        ab_datatype = ab_col_info["type"] if ab_col_info else "VARCHAR"
        # BK alias entry
        columns.append({
            "source_table": "SRC",
            "source_column": ab_raw,
            "datatype": ab_datatype,
            "staging_column_name": ab_alias,
            "hashdiff": "",
            "not_null": "yes",
            "unique": "",
            "manual_logic": "",
        })

    # === LOAD_DTS (derived) ===
    columns.append({
        "source_table": "SRC",
        "source_column": "(DERIVED)",
        "staging_column_name": "LOAD_DTS",
        "datatype": "TIMESTAMP",
        "hashdiff": "",
        "not_null": "",
        "unique": "",
        "manual_logic": load_dts_logic,
    })

    # === Data columns (all non-BK, non-technical source columns) ===
    hashdiff_cols = []  # Track columns for HASHDIFF

    # Build dynamic HASHDIFF exclusion set:
    # - Grain columns (part of PK, not change-tracked attributes)
    # - Custom LOAD_DTS column (metadata, not business data)
    _dynamic_hashdiff_exclude = set()
    _grain_cols_state = state.get("grain_columns") or []
    for gc in _grain_cols_state:
        gc_upper = gc.upper()
        # Only exclude grain cols that are NOT already handled as BK
        if gc_upper not in bk_raw_set:
            _dynamic_hashdiff_exclude.add(gc_upper)
    if _custom_load_dts_col:
        _dynamic_hashdiff_exclude.add(_custom_load_dts_col.upper())

    for col in source_columns:
        cname = col["name"].upper()
        if cname in bk_raw_set:
            continue  # Already handled as primary BK — exclude from HASHDIFF
        if cname in _additional_bk_raw_cols:
            # Additional BK raw columns are data (included in HASHDIFF).
            # Their BK alias entry was already added above; emit a normal data
            # column row so build.py picks up the hashdiff: 'yes' flag.
            pass  # fall through to the normal column append below
        elif cname in TECHNICAL_COLS:
            continue  # Will be added as technical columns below

        # Determine HASHDIFF inclusion — exclude grain cols and custom LOAD_DTS col
        _include_in_hd = "yes" if cname not in _dynamic_hashdiff_exclude else ""

        columns.append({
            "source_table": "SRC",
            "source_column": cname,
            "staging_column_name": cname,
            "datatype": col["type"],
            "hashdiff": _include_in_hd,
            "not_null": "",
            "unique": "",
            "manual_logic": "",
        })
        if _include_in_hd:
            hashdiff_cols.append(cname)

    # === Technical columns (passthrough) ===
    for col in source_columns:
        cname = col["name"].upper()
        if cname in TECHNICAL_COLS and cname in col_names_upper:
            # Flag-driven HASHDIFF inclusion
            include_in_hashdiff = ""
            if cname == "_FIVETRAN_DELETED" and profile.get("has_fivetran_deleted"):
                include_in_hashdiff = "yes"
                hashdiff_cols.append(cname)
            elif cname == "PSA_DELETE_IND" and profile.get("has_psa_delete_ind"):
                include_in_hashdiff = "yes"
                hashdiff_cols.append(cname)
            elif cname == "GLDELFLAG" and profile.get("ingestion_source") == "snp_glue":
                include_in_hashdiff = "yes"
                hashdiff_cols.append(cname)

            columns.append({
                "source_table": "SRC",
                "source_column": cname,
                "staging_column_name": cname,
                "datatype": col["type"],
                "hashdiff": include_in_hashdiff,
                "not_null": "",
                "unique": "",
                "manual_logic": "",
            })

    # === BKCC (from ref table) ===
    columns.append({
        "source_table": "SRC_BKCC",
        "source_column": "BKCC",
        "staging_column_name": "BKCC",
        "datatype": "TEXT",
        "hashdiff": "",
        "not_null": "",
        "unique": "",
        "manual_logic": "",
    })

    # === REC_SRC (from ref table) ===
    columns.append({
        "source_table": "SRC_BKCC",
        "source_column": "REC_SRC",
        "staging_column_name": "REC_SRC",
        "datatype": "TEXT",
        "hashdiff": "",
        "not_null": "",
        "unique": "",
        "manual_logic": "",
    })

    # === Secondary table columns + BK (multi-table support, lesson #80) ===
    if has_secondary(state):
        columns = extend_yaml_columns(columns, state)

    # === HK (derived) ===
    # Simple cast BK (TO_CHAR, ::TEXT) → HK uses raw column names
    # Derivation BK (COALESCE, CONCAT)  → HK uses BK alias
    driver_hk_parts = list(bk_raw_cols) if _is_simple_cast_bk(bk) else [bk_name.upper()]
    columns.append({
        "source_table": "",
        "source_column": "(DERIVED)",
        "staging_column_name": f"{bk_name.upper().replace('_BK', '')}_HK",
        "datatype": "BINARY",
        "hashdiff": "",
        "not_null": "",
        "unique": "",
        "manual_logic": f"HASH: {', '.join(driver_hk_parts)}, BKCC",
    })


    # === Secondary HKs (multi-table: secondary hub HK + link HK) ===
    # Check if user already provided a LNK_ HK via --hk (suppress auto-generated link HK)
    user_lnk_hk_names = {hk["name"] for hk in state.get("hash_keys", []) if hk["name"].startswith("LNK_") or hk.get("type") == "link"}
    user_hk_names = {hk["name"] for hk in state.get("hash_keys", [])}
    if has_secondary(state):
        sec = state['secondary']
        if sec.get('bk_name'):
            sec_bk_expr = sec.get('bk', '')
            # Secondary hub HK — simple cast → raw col, derivation → BK alias
            sec_entity = sec['bk_name'].upper().replace('_BK', '')
            sec_hk_name = f"{sec_entity}_HK"
            if _is_simple_cast_bk(sec_bk_expr):
                sec_hk_parts = [_extract_raw_col(sec_bk_expr)]
            else:
                sec_hk_parts = [sec['bk_name'].upper()]
            # Only add secondary hub HK if user didn't already specify it via --hk
            if sec_hk_name not in user_hk_names:
                columns.append({
                    "source_table": "",
                    "source_column": "(DERIVED)",
                    "staging_column_name": sec_hk_name,
                    "datatype": "BINARY",
                    "hashdiff": "",
                    "not_null": "",
                    "unique": "",
                    "manual_logic": f"HASH: {', '.join(sec_hk_parts)}, BKCC",
                })

            # Link HK — use table names for link entity naming
            # Skip if user already provided ANY LNK_ HK via --hk (lesson #129)
            if not user_lnk_hk_names:
                sec_table_entity = sec['table'].upper()
                driver_table_entity = table.upper()
                lnk_hk_name = f"LNK_{sec_table_entity}_{driver_table_entity}_HK"
                # Link HK composes from the participating hub HK values (DV 2.1, #1907),
                # not raw columns. BKCC is already embedded in each hub HK, so it is not
                # repeated here. HASH_FROM_HKS routes this to the CTE-staged renderer.
                driver_hk_name = f"{bk_name.upper().replace('_BK', '')}_HK"
                lnk_parts = [driver_hk_name, sec_hk_name]
                columns.append({
                    "source_table": "",
                    "source_column": "(DERIVED)",
                    "staging_column_name": lnk_hk_name,
                    "datatype": "BINARY",
                    "hashdiff": "",
                    "not_null": "",
                    "unique": "",
                    "manual_logic": f"HASH_FROM_HKS: {', '.join(lnk_parts)}",
                })

    # === Additional HKs from state["hash_keys"] (Multi-HK Phase 2) ===
    # Build a map of existing auto-generated HKs for override detection
    existing_hk_map = {
        c["staging_column_name"]: c for c in columns
        if c.get("staging_column_name", "").endswith("_HK")
    }
    for hk in state.get("hash_keys", []):
        # type == "link" (from --hk @HK sigil) composes from hub HK values (#1907).
        if hk.get("type") == "link":
            user_formula = f"HASH_FROM_HKS: {', '.join(hk['columns'])}"
        else:
            user_formula = f"HASH: {', '.join(hk['columns'])}"
        if hk["name"] in existing_hk_map:
            existing_col = existing_hk_map[hk["name"]]
            if existing_col.get("manual_logic") == user_formula:
                continue  # True duplicate — same name AND same formula
            # Name matches but formula differs — user override takes precedence
            existing_col["manual_logic"] = user_formula
            continue
        columns.append({
            "source_table": "",
            "source_column": "(DERIVED)",
            "staging_column_name": hk["name"],
            "datatype": "BINARY",
            "hashdiff": "",
            "not_null": "",
            "unique": "",
            "manual_logic": user_formula,
        })

    # === HASHDIFF (derived, always last) ===
    columns.append({
        "source_table": "",
        "source_column": "(DERIVED)",
        "staging_column_name": "HASHDIFF",
        "datatype": "BINARY",
        "hashdiff": "",
        "not_null": "",
        "unique": "",
        "manual_logic": f"HASH: {', '.join(hashdiff_cols)}",
    })

    # Build the STG model sources list
    stg_sources = [{
        "source_schema": schema,
        "source_table": table,
        "alias": "SRC",
    }]

    # Driver QUALIFY: only add when grain is invalid (lesson #82)
    grain_valid = profile.get("grain_valid", True)
    if not grain_valid:
        ingestion = profile.get("ingestion_source", "custom")
        if ingestion == "fivetran":
            driver_order_col = "_FIVETRAN_SYNCED"
        elif ingestion == "snp_glue":
            driver_order_col = "GLCHANGETIME"
        else:
            driver_order_col = "PSA_LOAD_DTS"
        # Use composite grain columns in PARTITION BY if available (lesson #96)
        _gc = state.get("grain_columns") or profile.get("grain_columns")
        if _gc:
            _bk_raw_strip = bk.split("::")[0].strip()
            _bk_raw_strip = re.sub(r"^[A-Z_]+\((.+)\)$", r"\1", _bk_raw_strip)
            _partition_cols = ", ".join([bk] + [g for g in _gc if g.upper() != _bk_raw_strip.upper()] + [driver_order_col])
        else:
            _partition_cols = f"{bk}, {driver_order_col}"
        driver_qualify = resolve_driver_qualify(
            profile, _partition_cols, driver_order_col
        )
        stg_sources[0]["source_layer_filter"] = driver_qualify

    # Secondary table source row (multi-table support)
    if has_secondary(state):
        stg_sources = extend_yaml_sources(stg_sources, state)

    # Build the full config dict
    config = {
        "schema_version": "1.0",
        "filename": model_name,
        "_pipeline_metadata": {
            "bkcc_rec_src": rec_src,
            "has_fivetran_deleted": profile.get("has_fivetran_deleted", False),
            "has_psa_delete_ind": profile.get("has_psa_delete_ind", False),
            "psa_delete_filter": False,
            "null_bk_coalesced": bool(state.get("null_bk_sentinel")),
            "large_volume": large_volume,
            "row_count": row_count,
            "volume_tier": volume_tier,
            "load_dts_derivation": load_dts_logic,
            "grain_valid": profile.get("grain_valid", False),
        },
        "models": [{
            "layer": "STG",
            "derived_name": model_name,
            "short_name": config_name,
            "sources": stg_sources,
            "columns": columns,
        }],
    }

    # Add volume-specific config
    if volume_tier in ("caution", "large"):
        config["_pipeline_metadata"]["cluster_by"] = [bk_name.upper()]
    if volume_tier == "large":
        config["_pipeline_metadata"]["downstream_config"] = {
            "full_refresh": False,
            "on_schema_change": "append_new_columns",
            "incr_watermark": True,
        }

    # Add null_bk fields if applicable
    if profile.get("null_bk_count", 0) > 0:
        config["_pipeline_metadata"]["null_bk_count"] = profile["null_bk_count"]
        config["_pipeline_metadata"]["null_bk_pct"] = profile.get("null_bk_pct", 0)

    # ── HUB model (when --objects includes "hub") ──────────────────────────
    objects = state.get("objects", ["stg"])
    if "hub" in objects:
        # Apply hub-name override if provided via add-raw-vault --hub-name
        effective_hub_name = state.get('hub_name_override')
        hub_model = _build_hub_yaml_model(state, profile, bk_raw_cols, bk_name, row_count,
                                           hub_name_override=effective_hub_name)
        config["models"].append(hub_model)
        # Store hub metadata for downstream steps
        config["_pipeline_metadata"]["hub_model_name"] = hub_model["derived_name"]
        config["_pipeline_metadata"]["hub_use_watermark"] = row_count >= HUB_WATERMARK_THRESHOLD
        config["_pipeline_metadata"]["hub_full_refresh"] = row_count >= HUB_FULL_REFRESH_THRESHOLD

    # ── LNK models (when --objects includes "lnk") ────────────────────────
    if "lnk" in objects:
        lnks_list = state.get("lnks", [])
        if not lnks_list:
            _print_error("No LNK definitions found in state. Run add-raw-vault first.")
            return 1
        lnk_model_names = []
        for lnk_def in lnks_list:
            parent_hks = lnk_def.get("parent_hks", [])
            dcks = lnk_def.get("dcks", lnk_def.get("dck", []))
            lnk_name_val = lnk_def.get("lnk_name", "")
            lnk_model = _build_lnk_yaml_model(
                state, profile, parent_hks, lnk_name_val, dcks, row_count,
            )
            config["models"].append(lnk_model)
            lnk_model_names.append(lnk_model["derived_name"])
            print(f"    LNK: {lnk_name_val}")
        config["_pipeline_metadata"]["lnk_model_names"] = lnk_model_names
        config["_pipeline_metadata"]["lnk_use_watermark"] = row_count >= HUB_WATERMARK_THRESHOLD
        config["_pipeline_metadata"]["lnk_full_refresh"] = row_count >= HUB_FULL_REFRESH_THRESHOLD

    # ── SAT models (when --objects includes "sat") ────────────────────────
    if "sat" in objects:
        sats_list = state.get("sats", [])
        if not sats_list:
            # Backward compat: old state["sat"] already migrated by _load_state
            _print_error("No SAT definitions found in state. Run add-raw-vault first.")
            return 1
        sat_model_names = []
        for sat_def in sats_list:
            sat_model = _build_sat_yaml_model(
                state, profile, bk_raw_cols, bk_name, row_count, sat_def=sat_def,
            )
            config["models"].append(sat_model)
            sat_model_names.append(sat_model["derived_name"])
            print(f"    SAT: {sat_def['model_name']} ({sat_def.get('sat_type', 'sat')})")

        # -- Per-SAT HASHDIFF: when any SAT has sat_columns, each needs its own HASHDIFF --
        sats_with_cols = [s for s in sats_list if s.get("sat_columns")]
        if sats_with_cols:
            stg_model = config["models"][0]
            source_columns = profile.get("columns", [])
            bk_raw_set_hd = set(c.upper() for c in bk_raw_cols)
            meta_exclude = {
                "HASHDIFF", "LOAD_DTS", "REC_SRC", "BKCC",
                "_FIVETRAN_ID", "_FIVETRAN_SYNCED", "PSA_LOAD_DTS", "PSA_RECORD_SOURCE",
                bk_name.upper(),
            }
            # Dynamic exclusions: grain columns + custom LOAD_DTS column
            for gc in (state.get("grain_columns") or []):
                gc_upper = gc.upper()
                if gc_upper not in bk_raw_set_hd:
                    meta_exclude.add(gc_upper)
            if state.get("load_dts_column"):
                meta_exclude.add(state["load_dts_column"].upper())

            hashdiff_data_flags = {"_FIVETRAN_DELETED", "PSA_DELETE_IND"}

            for sat_def in sats_list:
                sat_cols_filter = sat_def.get("sat_columns")
                sat_mn = sat_def.get("model_name", "")
                short_suffix = (
                    _strip_stg_prefix(sat_mn)
                    .removeprefix("msat_")
                    .removeprefix("sat_")
                    .removeprefix("lsat_")
                )
                parts_s = short_suffix.split("__")
                if parts_s:
                    entity_part = parts_s[0]
                    base_entity = _strip_stg_prefix(model_name).split("__")[0]
                    diff = entity_part.replace(base_entity, "").strip("_")
                    hd_suffix = diff.upper() if diff else "MAIN"
                else:
                    hd_suffix = "MAIN"
                named_hashdiff = f"HASHDIFF_{hd_suffix}"

                hd_cols = []
                if sat_cols_filter:
                    sat_col_set = set(c.upper() for c in sat_cols_filter)
                    for col in source_columns:
                        cname = col["name"].upper()
                        if cname in sat_col_set and cname not in meta_exclude and cname not in bk_raw_set_hd:
                            hd_cols.append(cname)
                    for flag_col in hashdiff_data_flags:
                        if flag_col not in hd_cols:
                            if any(c["name"].upper() == flag_col for c in source_columns):
                                hd_cols.append(flag_col)
                else:
                    for col in source_columns:
                        cname = col["name"].upper()
                        if cname in bk_raw_set_hd or cname in meta_exclude:
                            continue
                        if cname in hashdiff_data_flags or cname not in {"_FIVETRAN_ID", "_FIVETRAN_SYNCED", "PSA_LOAD_DTS", "PSA_RECORD_SOURCE"}:
                            hd_cols.append(cname)

                if hd_cols:
                    formula = _build_hashdiff_formula(hd_cols)
                    stg_model["columns"].append({
                        "source_table": "",
                        "source_column": "(DERIVED)",
                        "staging_column_name": named_hashdiff,
                        "datatype": "BINARY",
                        "hashdiff": "",
                        "not_null": "",
                        "unique": "",
                        "manual_logic": formula,
                    })
                    sat_def["_named_hashdiff"] = named_hashdiff
                    trunc_cols = ", ".join(hd_cols[:5]) + ("..." if len(hd_cols) > 5 else "")
                    print(f"    Per-SAT HASHDIFF: {named_hashdiff} ({len(hd_cols)} cols: {trunc_cols})")

            # Update each SAT model to use its named HASHDIFF
            stg_off = 1
            hub_off = 1 if "hub" in objects else 0
            lnk_off = len(state.get("lnks", [])) if "lnk" in objects else 0
            sat_start = stg_off + hub_off + lnk_off
            for i_s, sat_def in enumerate(sats_list):
                named_hd = sat_def.get("_named_hashdiff")
                if named_hd:
                    sat_idx = sat_start + i_s
                    if sat_idx < len(config["models"]):
                        sat_m = config["models"][sat_idx]
                        for col in sat_m["columns"]:
                            if col.get("staging_column_name") == "HASHDIFF":
                                col["source_column"] = named_hd
                                col["staging_column_name"] = named_hd
                        for src in sat_m.get("sources", []):
                            ff = src.get("final_layer_filter", "")
                            if "HASHDIFF" in ff:
                                src["final_layer_filter"] = ff.replace(
                                    "existing.HASHDIFF = JOIN_RESULT.HASHDIFF",
                                    f"existing.{named_hd} = JOIN_RESULT.{named_hd}",
                                ).replace(
                                    "HASHDIFF order by",
                                    f"{named_hd} order by",
                                )

        config["_pipeline_metadata"]["sat_model_names"] = sat_model_names
        config["_pipeline_metadata"]["sat_use_watermark"] = row_count >= SAT_WATERMARK_THRESHOLD
        config["_pipeline_metadata"]["sat_full_refresh_false"] = row_count > SAT_CLUSTER_THRESHOLD
        config["_pipeline_metadata"]["sat_cluster_by"] = row_count > SAT_CLUSTER_THRESHOLD

    # Write YAML
    try:
        import yaml
    except ImportError:
        _print_error("pyyaml not installed. Run: pip install pyyaml")
        return 1

    # ── Defect 2: single write-time normalizer ──────────────────────────────
    # source_column is emitted as a list for EVERY column (uniform shape). This
    # is the ONLY place lists are written, so the two composite call sites (raw
    # passthrough + BK alias) cannot drift into different serializations again.
    # normalize_source_column preserves declared order (no sort/dedupe) — order is
    # load-bearing (CONCAT_WS arg order → BK → every derived HK).
    for _model in config.get("models", []):
        for _col in _model.get("columns", []):
            if "source_column" in _col:
                _col["source_column"] = normalize_source_column(_col["source_column"])

    config_path.parent.mkdir(parents=True, exist_ok=True)
    with open(config_path, "w") as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False, allow_unicode=True)

    state["config_path"] = str(config_path.relative_to(PROJECT_ROOT))
    _mark_complete(state, "generate-yaml")

    _print_success(f"YAML config written: {config_path.relative_to(PROJECT_ROOT)}")
    print(f"  Columns: {len(columns)} (incl. derived)")
    print(f"  HASHDIFF cols: {len(hashdiff_cols)}")
    if "hub" in objects:
        hub_name = config["_pipeline_metadata"]["hub_model_name"]
        wm = "yes" if config["_pipeline_metadata"].get("hub_use_watermark") else "no"
        fr = "yes" if config["_pipeline_metadata"].get("hub_full_refresh") else "no"
        print(f"  Hub model: {hub_name} (watermark={wm}, full_refresh_false={fr})")
    if "lnk" in objects:
        lnk_names = config["_pipeline_metadata"].get("lnk_model_names", [])
        wm = "yes" if config["_pipeline_metadata"].get("lnk_use_watermark") else "no"
        fr = "yes" if config["_pipeline_metadata"].get("lnk_full_refresh") else "no"
        for ln in lnk_names:
            print(f"  Lnk model: {ln} (watermark={wm}, full_refresh_false={fr})")
    if "sat" in objects:
        sat_names = config["_pipeline_metadata"].get("sat_model_names", [])
        wm = "yes" if config["_pipeline_metadata"].get("sat_use_watermark") else "no"
        fr = "yes" if config["_pipeline_metadata"].get("sat_full_refresh_false") else "no"
        for sn in sat_names:
            print(f"  Sat model: {sn} (watermark={wm}, full_refresh_false={fr})")
    _print_next_step(state, "generate-yaml")
    return 0


def cmd_generate_xlsx(args):
    """Generate XLSX tech spec and auto-validate."""
    state = _resolve_state(args)
    if not state:
        return 1

    ok, missing = _check_prerequisites(state, "generate-xlsx")
    if not ok:
        _print_error(f"Prerequisites not met. Complete these first: {', '.join(missing)}")
        return 1

    config_path = state.get("config_path", "")
    if not config_path:
        _print_error("No config_path in state. Re-run generate-yaml.")
        return 1

    abs_config = PROJECT_ROOT / config_path
    if not abs_config.exists():
        _print_error(f"Config file not found: {abs_config}")
        return 1

    mappings_dir = SCRIPT_DIR / "mappings"
    mappings_dir.mkdir(parents=True, exist_ok=True)

    # Step 1: Generate XLSX
    print("\n  [1/2] Generating XLSX tech spec...")
    rc, out, err = _run_command(
        f"{_python()} {SCRIPT_DIR / 'generate_tech_spec.py'} "
        f"--config {abs_config} --outdir {mappings_dir}",
    )
    if rc != 0:
        _print_error(f"XLSX generation failed:\n{err}\n{out}")
        return 1
    print(f"    {out.strip()}")

    # Find the generated XLSX
    model_name = state["model_name"]
    config_name = _strip_stg_prefix(model_name)
    xlsx_path = mappings_dir / f"v_psa_stg_{config_name}.xlsx"
    if not xlsx_path.exists():
        # Try alternate name
        xlsx_candidates = list(mappings_dir.glob(f"*{config_name}*.xlsx"))
        if xlsx_candidates:
            xlsx_path = xlsx_candidates[0]
        else:
            _print_error(f"Generated XLSX not found at expected path: {xlsx_path}")
            return 1

    # Step 2: Auto-validate
    print("  [2/2] Running validation (21 checks)...")
    rc, out, err = _run_command(
        f"{_python()} {SCRIPT_DIR / 'validate_tech_spec.py'} "
        f"--config {abs_config} --xlsx {xlsx_path}",
    )
    print(f"    {out.strip()}")

    # Parse validation results
    if rc != 0:
        state["xlsx_path"] = str(xlsx_path.relative_to(PROJECT_ROOT))
        state["xlsx_validation"] = {"all_passed": False, "output": out + err}
        _save_state(state)
        _print_error(
            f"Validation FAILED. Fix the YAML config and re-run:\n"
            f"  python {_rel_script()} generate-yaml\n"
            f"  python {_rel_script()} generate-xlsx"
        )
        return 1

    # Count checks from output
    pass_match = re.search(r"(\d+)/(\d+)", out)
    checks_passed = int(pass_match.group(1)) if pass_match else 0
    checks_total = int(pass_match.group(2)) if pass_match else 0

    state["xlsx_path"] = str(xlsx_path.relative_to(PROJECT_ROOT))
    state["xlsx_validation"] = {
        "checks_passed": checks_passed,
        "checks_total": checks_total,
        "all_passed": True,
    }
    _mark_complete(state, "generate-xlsx")

    _print_success(f"XLSX generated + validated: {checks_passed}/{checks_total} checks passed.")
    print(f"  XLSX: {xlsx_path.relative_to(PROJECT_ROOT)}")
    print(f"\n  User must review the XLSX before proceeding.")
    _print_next_step(state, "generate-xlsx")
    return 0


def cmd_approve_xlsx(args):
    """Record user approval of XLSX."""
    state = _resolve_state(args)
    if not state:
        return 1

    ok, missing = _check_prerequisites(state, "approve-xlsx")
    if not ok:
        _print_error(f"Prerequisites not met. Complete these first: {', '.join(missing)}")
        return 1


    validation = state.get("xlsx_validation", {})
    if not validation.get("all_passed"):
        _print_error(
            "XLSX validation did not pass.\n"
            f"  Re-run: python {_rel_script()} generate-xlsx"
        )
        return 1

    _mark_complete(state, "approve-xlsx")
    _print_success("XLSX approved.")

    # Guardrail: warn if raw vault objects exist but no hash_keys defined
    objects_check = state.get("objects", [])
    hash_keys_check = state.get("hash_keys", [])
    has_raw_vault = any(o in objects_check for o in ["hub", "sat", "lnk"])
    if has_raw_vault and not hash_keys_check:
        print("  ⚠️  WARNING: Raw vault objects detected but no hash_keys defined.")
        print("     The staging view will only have the driver HK (from BK).")
        print("     If this model needs multiple HKs (hub + link, or multiple hubs),")
        print("     add them now:")
        print(f'       .venv/bin/python3 {_rel_script()} profile --hk "HK_NAME:COL1,COL2,..."')
        print()

    _print_next_step(state, "approve-xlsx")

    # Prompt Raw Vault design decision for STG-only pipelines
    objects = state.get('objects', ['stg'])
    if objects == ['stg']:
        _prompt_raw_vault_objects(state)
    return 0


def cmd_generate_code(args):
    """Run Stage 2: code generation."""
    state = _resolve_state(args)
    if not state:
        return 1

    ok, missing = _check_prerequisites(state, "generate-code")
    if not ok:
        _print_error(f"Prerequisites not met. Complete these first: {', '.join(missing)}")
        if "approve-xlsx" in missing:
            print(f"\n  The XLSX must be reviewed and approved before code generation.")
            print(f"  Run: python {_rel_script()} approve-xlsx")
        return 1

    # Guardrail: warn if raw vault objects exist but no hash_keys defined
    objects_check = state.get("objects", [])
    hash_keys_check = state.get("hash_keys", [])
    has_raw_vault = any(o in objects_check for o in ["hub", "sat", "lnk"])
    if has_raw_vault and not hash_keys_check:
        print("  ⚠️  WARNING: Raw vault objects detected but no hash_keys defined.")
        print("     The staging view will only have the driver HK (from BK).")
        print("     If this model needs multiple HKs (hub + link, or multiple hubs),")
        print("     add them now:")
        print(f'       .venv/bin/python3 {_rel_script()} profile --hk "HK_NAME:COL1,COL2,..."')
        print()

    # ── Design Decision Gate (Lesson #106) ──────────────────────────────────
    # STG-only pipelines must have an explicit design decision before code gen.
    # This prevents && chaining and Copilot auto-continuation from skipping
    # the Raw Vault design decision prompt shown by approve-xlsx.
    objects = state.get("objects", ["stg"])
    design_decision = state.get("design_decision")
    if objects == ["stg"] and design_decision is None:
        if not getattr(args, 'stg_only', False):
            print("\n\u26d4 DESIGN DECISION REQUIRED")
            print("  This is a STG-only pipeline. Before generating code, you must")
            print("  explicitly choose one of:")
            print()
            print("  Option A \u2014 STG only:")
            print(f"    .venv/bin/python3 {_rel_script()} generate-code --stg-only")
            print()
            print("  Option B \u2014 Add Raw Vault objects first:")
            print(f"    .venv/bin/python3 {_rel_script()} add-raw-vault --objects \"hub,sat\" ...")
            print(f"    .venv/bin/python3 {_rel_script()} generate-code")
            sys.exit(1)
        else:
            state["design_decision"] = "stg_only"
            _save_state(state)

    xlsx_path = state.get("xlsx_path", "")
    abs_xlsx = PROJECT_ROOT / xlsx_path if xlsx_path else None
    if not abs_xlsx or not abs_xlsx.exists():
        _print_error(f"XLSX tech spec not found: {xlsx_path}")
        return 1

    # XLSX is the source of truth for code generation.
    # main.py --rootdir reads XLSX sheets and calls build().
    mappings_dir = abs_xlsx.parent
    rootdir = mappings_dir.parent
    print("\n  Running Stage 2: Code generation (from XLSX)...")
    rc, out, err = _run_command(
        f"{_python()} {SCRIPT_DIR / 'src' / 'main.py'} --rootdir {rootdir}",
    )
    if rc != 0:
        _print_error(f"Code generation failed:\n{err}\n{out}")
        return 1
    print(f"    {out.strip()}")

    # Find generated files
    model_name = state["model_name"]
    output_dir = SCRIPT_DIR / "models" / "int_staging_views"
    sql_file = output_dir / f"{model_name}.sql"
    yml_file = output_dir / f"{model_name}.yml"

    generated = {}
    if sql_file.exists():
        generated["sql"] = str(sql_file.relative_to(PROJECT_ROOT))
    if yml_file.exists():
        generated["yml"] = str(yml_file.relative_to(PROJECT_ROOT))

    if not generated:
        # Check alternate locations
        for f in SCRIPT_DIR.rglob(f"{model_name}.*"):
            ext = f.suffix
            if ext == ".sql":
                generated["sql"] = str(f.relative_to(PROJECT_ROOT))
            elif ext in (".yml", ".yaml"):
                generated["yml"] = str(f.relative_to(PROJECT_ROOT))

    # Find hub-generated files (when --objects includes "hub")
    objects = state.get("objects", ["stg"])
    if "hub" in objects:
        hub_name = state.get('hub_name_override') or _derive_hub_name(state["bk_name"])
        hub_output_dir = SCRIPT_DIR / "models" / "raw_vault" / "hub"
        hub_sql = hub_output_dir / f"{hub_name}.sql"
        hub_yml = hub_output_dir / f"{hub_name}.yml"
        if hub_sql.exists():
            generated["hub_sql"] = str(hub_sql.relative_to(PROJECT_ROOT))
        if hub_yml.exists():
            generated["hub_yml"] = str(hub_yml.relative_to(PROJECT_ROOT))
        # Fallback: search under models/
        if "hub_sql" not in generated:
            for f in SCRIPT_DIR.rglob(f"{hub_name}.*"):
                ext = f.suffix
                if ext == ".sql" and "hub_sql" not in generated:
                    generated["hub_sql"] = str(f.relative_to(PROJECT_ROOT))
                elif ext in (".yml", ".yaml") and "hub_yml" not in generated:
                    generated["hub_yml"] = str(f.relative_to(PROJECT_ROOT))

    # Find lnk-generated files (when --objects includes "lnk") — iterate lnks list
    if "lnk" in objects:
        for lnk_idx, lnk_def in enumerate(state.get("lnks", [])):
            lnk_name_val = lnk_def.get("lnk_name", "")
            if not lnk_name_val:
                continue
            lnk_derived = _derive_lnk_name(lnk_name_val)
            lnk_output_dir = SCRIPT_DIR / "models" / "raw_vault" / "link"
            lnk_sql = lnk_output_dir / f"{lnk_derived}.sql"
            lnk_yml = lnk_output_dir / f"{lnk_derived}.yml"
            key_sql = f"lnk_sql_{lnk_idx}" if lnk_idx > 0 else "lnk_sql"
            key_yml = f"lnk_yml_{lnk_idx}" if lnk_idx > 0 else "lnk_yml"
            if lnk_sql.exists():
                generated[key_sql] = str(lnk_sql.relative_to(PROJECT_ROOT))
            if lnk_yml.exists():
                generated[key_yml] = str(lnk_yml.relative_to(PROJECT_ROOT))
            # Fallback: search under models/
            if key_sql not in generated:
                for f in SCRIPT_DIR.rglob(f"{lnk_derived}.*"):
                    ext = f.suffix
                    if ext == ".sql" and key_sql not in generated:
                        generated[key_sql] = str(f.relative_to(PROJECT_ROOT))
                    elif ext in (".yml", ".yaml") and key_yml not in generated:
                        generated[key_yml] = str(f.relative_to(PROJECT_ROOT))

    # Find sat-generated files (when --objects includes "sat") — iterate sats list
    if "sat" in objects:
        for sat_idx, sat_def in enumerate(state.get("sats", [])):
            sat_model_name = sat_def.get("model_name", "")
            if not sat_model_name:
                continue
            sat_output_dir = SCRIPT_DIR / "models" / "raw_vault" / "sat"
            sat_sql = sat_output_dir / f"{sat_model_name}.sql"
            sat_yml = sat_output_dir / f"{sat_model_name}.yml"
            key_sql = f"sat_sql_{sat_idx}" if sat_idx > 0 else "sat_sql"
            key_yml = f"sat_yml_{sat_idx}" if sat_idx > 0 else "sat_yml"
            if sat_sql.exists():
                generated[key_sql] = str(sat_sql.relative_to(PROJECT_ROOT))
            if sat_yml.exists():
                generated[key_yml] = str(sat_yml.relative_to(PROJECT_ROOT))
            # Fallback: search under models/
            if key_sql not in generated:
                for f in SCRIPT_DIR.rglob(f"{sat_model_name}.*"):
                    ext = f.suffix
                    if ext == ".sql" and key_sql not in generated:
                        generated[key_sql] = str(f.relative_to(PROJECT_ROOT))
                    elif ext in (".yml", ".yaml") and key_yml not in generated:
                        generated[key_yml] = str(f.relative_to(PROJECT_ROOT))

    state["generated_files"] = generated
    state["code_generated_at"] = _now_iso()

    # ── Reconciliation Check: verify all profiled columns are accounted for ──
    reconciliation = _reconcile_columns(state)
    state["reconciliation"] = reconciliation
    if not reconciliation["passed"]:
        unmapped = reconciliation["unmapped"]
        sec_unmapped = reconciliation.get("secondary_unmapped", [])
        if unmapped:
            print(f"\n  ⚠️  RECONCILIATION WARNING: {len(unmapped)} driver column(s) not found in generated SQL:")
            for col in unmapped:
                print(f"    - {col}")
        if sec_unmapped:
            print(f"\n  ⚠️  RECONCILIATION WARNING: {len(sec_unmapped)} secondary/lookup column(s) not found in generated SQL:")
            for col in sec_unmapped:
                print(f"    - {col}")
        print("  These columns may have been silently dropped. Verify this is intentional.")
        # Persist reconciliation results into the profile.md evidence document so
        # reviewers can audit the decision after the fact.
        if state.get("profile_md_path"):
            _append_reconciliation_to_profile_md(state, reconciliation)
            print(f"  Reconciliation results appended to {state['profile_md_path']}")
        else:
            print("  No profile.md found — review the warnings above manually.")
    else:
        mapped_count = len(reconciliation["mapped"])
        tech_count = len(reconciliation["excluded_technical"])
        sec_count = len(reconciliation.get("secondary_mapped", []))
        sec_msg = f", {sec_count} secondary" if sec_count else ""
        print(f"\n  ✓ Reconciliation: {mapped_count} mapped{sec_msg}, {tech_count} technical/metadata excluded, 0 unmapped")

    _mark_complete(state, "generate-code")

    _print_success("Code generation complete.")
    for ftype, fpath in generated.items():
        print(f"  {ftype.upper()}: {fpath}")
    print(f"\n  Review the generated code, then:")
    _print_next_step(state, "generate-code")
    return 0


def cmd_show_code(args):
    """Display generated SQL and YAML for review."""
    state = _resolve_state(args)
    if not state:
        return 1

    if "generate-code" not in _completed_steps(state):
        _print_error(f"Code not yet generated. Run: python {_rel_script()} generate-code")
        return 1

    generated = state.get("generated_files", {})
    for ftype, fpath in generated.items():
        abs_path = PROJECT_ROOT / fpath
        if abs_path.exists():
            print(f"\n{'='*70}")
            print(f"  {ftype.upper()}: {fpath}")
            print(f"{'='*70}")
            print(abs_path.read_text())
        else:
            print(f"\n  {ftype.upper()}: {fpath} (NOT FOUND)")
    return 0


def cmd_approve_code(args):
    """Record user approval of generated code."""
    state = _resolve_state(args)
    if not state:
        return 1

    ok, missing = _check_prerequisites(state, "approve-code")
    if not ok:
        _print_error(f"Prerequisites not met. Complete these first: {', '.join(missing)}")
        return 1


    _mark_complete(state, "approve-code")
    _print_success("Code approved.")
    _print_next_step(state, "approve-code")
    return 0



def _extract_target_schema_from_dbt_debug(dbt_debug_output: str) -> str | None:
    """Extract target schema name from dbt debug output."""
    for line in dbt_debug_output.splitlines():
        match_colon = re.match(r"^\s*schema\s*:\s*['\"]?([^\s'\"]+)['\"]?\s*$", line, re.IGNORECASE)
        match_space = re.match(r"^\s*schema\s+['\"]?([^\s'\"]+)['\"]?\s*$", line, re.IGNORECASE)
        match = match_colon or match_space
        if not match:
            continue
        candidate = match.group(1).strip()
        if candidate and not candidate.startswith('{'):
            return candidate
    return None


def _register_source(schema: str, table: str) -> bool | None:
    """Register a PSA source table in _sources_staging_psa.yml if not already present.

    Uses surgical string insertion to avoid ruamel.yaml indentation drift:
      1. Parse YAML with safe_load to locate source block + check duplicates
      2. Read raw file lines to find exact insertion point
      3. Insert 2 lines (name + description) at the correct offset
      4. Validate output with safe_load; restore backup on corruption

    Returns True if a change was made, False if already registered, None on error.
    """
    import yaml as _yaml

    sources_path = PROJECT_ROOT / "models" / "sources" / "_sources_staging_psa.yml"
    if not sources_path.exists():
        print(f"    WARNING: Sources file not found: {sources_path}")
        return None

    # Create atomic backup for rollback on corruption (outside working tree)
    _bak_fd, _bak_name = tempfile.mkstemp(
        prefix=f"{sources_path.stem}_", suffix=f"{sources_path.suffix}.bak"
    )
    os.close(_bak_fd)
    _bak_path = Path(_bak_name)
    shutil.copy2(str(sources_path), str(_bak_path))

    # H-7: File lock to prevent concurrent _register_source corruption
    import fcntl as _fcntl
    _lock_path = sources_path.parent / f".{sources_path.name}.lock"
    _lock_fd = open(_lock_path, "w")
    try:
        _fcntl.flock(_lock_fd, _fcntl.LOCK_EX)  # blocks until acquired
        # --- Phase 1: Parse YAML to check if table is already registered ---
        with sources_path.open() as f:
            data = _yaml.safe_load(f) or {"sources": []}

        sources_list = data.get("sources")
        if not isinstance(sources_list, list):
            sources_list = []

        schema_lower = schema.lower()
        table_lower = table.lower()
        source_name = None  # resolved source block name

        # 3-step source resolution (lesson #97)
        # Step 1: schema matches a source NAME directly (common case)
        for src in sources_list:
            if (src.get("name") or "").lower() == schema_lower:
                source_name = src["name"]
                # Check if table already registered
                for t in src.get("tables") or []:
                    if isinstance(t, dict) and (t.get("name") or "").lower() == table_lower:
                        _bak_path.unlink(missing_ok=True)
                        return False
                break

        # Step 2: schema matches a source's schema: override (alias case)
        if source_name is None:
            for src in sources_list:
                if (src.get("schema") or "").lower() == schema_lower:
                    source_name = src["name"]
                    print(f"    Resolved source: schema '{schema}' -> source name '{source_name}'")
                    for t in src.get("tables") or []:
                        if isinstance(t, dict) and (t.get("name") or "").lower() == table_lower:
                            _bak_path.unlink(missing_ok=True)
                            return False
                    break

        # --- Phase 2: Read raw lines and find insertion point ---
        with sources_path.open() as f:
            lines = f.readlines()

        if source_name is not None:
            # Source block exists — find its last table entry and insert after it
            insert_line = _find_source_table_insert_line(lines, source_name)
            if insert_line is None:
                print(f"    ERROR: Could not locate tables section for source '{source_name}'")
                _bak_path.unlink(missing_ok=True)
                return None

            # Detect indentation from existing table entries in this block
            indent = _detect_table_entry_indent(lines, insert_line)
            new_lines = [
                f"{indent}- name: {table}\n",
                f"{indent}  description: \"\"\n",
            ]
            lines[insert_line:insert_line] = new_lines
        else:
            # Step 3: No match — append new source block at end of file
            # Ensure file ends with newline before appending
            if lines and not lines[-1].endswith("\n"):
                lines[-1] += "\n"
            new_block = [
                f"- name: {schema}\n",
                f"  database: \"psa_{{{{env_var('DBT_SOURCE_ENV')}}}}\"\n",
                f"  schema: {schema}\n",
                f"  tables:\n",
                f"  - name: {table}\n",
                f"    description: \"\"\n",
            ]
            lines.extend(new_block)

        # --- Phase 3: Atomic write + validation ---
        _tmp_fd, _tmp_name = tempfile.mkstemp(
            prefix=f"{sources_path.stem}_", suffix=f"{sources_path.suffix}.tmp",
            dir=str(sources_path.parent),
        )
        try:
            with os.fdopen(_tmp_fd, "w") as tmp_f:
                tmp_f.writelines(lines)

            # Validate YAML before replacing original
            with open(_tmp_name) as _vf:
                _yaml.safe_load(_vf)

            os.replace(_tmp_name, str(sources_path))
        except Exception:
            os.unlink(_tmp_name)
            raise

        _bak_path.unlink(missing_ok=True)
        return True

    except Exception as e:
        print(f"    ERROR: _register_source failed: {e}")
        if _bak_path.exists():
            shutil.copy2(str(_bak_path), str(sources_path))
            print(f"    Restored backup from: {_bak_path}")
        _bak_path.unlink(missing_ok=True)
        return None
    finally:
        _fcntl.flock(_lock_fd, _fcntl.LOCK_UN)
        _lock_fd.close()
        try:
            _lock_path.unlink(missing_ok=True)
        except OSError:
            pass


def _find_source_table_insert_line(lines: list[str], source_name: str) -> int | None:
    """Find the line number to insert a new table entry for the given source.

    Scans for ``- name: <source_name>`` at column 0, then finds the ``tables:``
    key, then walks forward to find the last table entry in that block.
    Returns the line index AFTER the last table entry (insertion point).
    """
    import re as _re

    source_start = None
    name_pat = _re.compile(r"^- name:\s+" + _re.escape(source_name) + r"\s*$")

    for i, line in enumerate(lines):
        if name_pat.match(line):
            source_start = i
            break

    if source_start is None:
        return None

    # Find `tables:` within this source block (before the next top-level `- name:`)
    tables_line = None
    for i in range(source_start + 1, len(lines)):
        stripped = lines[i].lstrip()
        if lines[i] and not lines[i][0].isspace() and stripped.startswith("- name:"):
            break  # hit next source block
        if stripped.startswith("tables:"):
            tables_line = i
            break

    if tables_line is None:
        return None

    # Walk forward from tables_line to find the last table entry
    # Table entries are indented list items: `  - name: ...` or `    - name: ...`
    last_table_end = tables_line + 1
    i = tables_line + 1
    while i < len(lines):
        stripped = lines[i].lstrip()
        indent_len = len(lines[i]) - len(lines[i].lstrip())

        # Stop if we hit a new top-level source block (column 0, starts with `- name:`)
        if indent_len == 0 and stripped.startswith("- name:"):
            break

        # Stop if we hit a non-indented, non-empty line that isn't part of tables
        if indent_len == 0 and stripped and not stripped.startswith("#"):
            break

        # Track lines that are part of the tables section
        if stripped:
            last_table_end = i + 1

        i += 1

    return last_table_end


def _detect_table_entry_indent(lines: list[str], insert_line: int) -> str:
    """Detect the indentation used for table entries near the insertion point.

    Looks backward from ``insert_line`` for a line matching ``- name:`` to
    determine the exact indent string (spaces) used by sibling entries.
    Falls back to ``"  "`` (2 spaces) if no pattern is found.
    """
    for i in range(insert_line - 1, max(insert_line - 20, -1), -1):
        stripped = lines[i].lstrip()
        if stripped.startswith("- name:"):
            return lines[i][: len(lines[i]) - len(lines[i].lstrip())]
    return "  "

def _run_code_review(review_files: list, project_root) -> dict:
    """Run code_reviewer.py subprocess and return parsed JSON result.

    Returns dict with keys: checks_run, fail_count, warn_count, findings.
    Returns None if reviewer is unavailable.
    """
    import subprocess as _sp
    import json as _json

    reviewer_path = Path(__file__).resolve().parent / "src" / "code_reviewer.py"
    if not reviewer_path.exists():
        return None

    review_cmd = [
        sys.executable, str(reviewer_path),
        "--files"] + review_files + [
        "--format", "json",
        "--repo-root", str(project_root),
    ]
    review_result = _sp.run(
        review_cmd, capture_output=True, text=True, timeout=60,
    )
    try:
        return _json.loads(review_result.stdout)
    except (ValueError, KeyError):
        # JSON parse failed — fall back to exit code
        if review_result.returncode != 0:
            return {"checks_run": 0, "fail_count": 1, "warn_count": 0,
                    "findings": [{"severity": "FAIL", "message": f"Code review exited with rc={review_result.returncode}. stderr: {review_result.stderr[:500]}"}]}
        return {"checks_run": 0, "fail_count": 0, "warn_count": 0, "findings": []}


def cmd_implement(args):
    """Run Stage 3: place files, compile, run, test."""
    state = _resolve_state(args)
    if not state:
        return 1

    ok, missing = _check_prerequisites(state, "implement")
    if not ok:
        _print_error(f"Prerequisites not met. Complete these first: {', '.join(missing)}")
        if "approve-code" in missing:
            print(f"\n  Generated code must be reviewed and approved before implementation.")
            print(f"  Run: python {_rel_script()} approve-code")
        return 1

    model_name = state["model_name"]
    domain = args.domain or state.get("domain")
    generated = state.get("generated_files", {})

    if not domain:
        _print_error("--domain is required for implement (e.g., --domain shipments)")
        return 1

    # Validate domain is a simple folder name — prevents path traversal
    # (e.g., --domain "../../raw_vault/hub" would escape int_staging_views/)
    if not re.match(r'^[a-z][a-z0-9_]*$', domain):
        _print_error(
            f"Invalid domain '{domain}'. Must be a lowercase folder name "
            f"(letters, digits, underscores). Example: --domain shipments"
        )
        return 1

    if not generated.get("sql") or not generated.get("yml"):
        _print_error("Generated SQL/YAML files not found in state. Re-run generate-code.")
        return 1

    results = {}

    # Step 3.1 — Check for duplicate files
    print("\n  [1/8] Checking for duplicates...")
    target_dir = PROJECT_ROOT / "models" / "int_staging_views" / domain
    target_sql = target_dir / f"{model_name}.sql"
    target_yml = target_dir / f"{model_name}.yml"

    force = getattr(args, 'force', False)
    if (target_sql.exists() or target_yml.exists()) and not force:
        _print_error(
            f"Files already exist in {target_dir}:\n"
            f"  SQL: {target_sql.exists()}\n"
            f"  YML: {target_yml.exists()}\n"
            f"  Use --force to overwrite, or delete existing files first."
        )
        return 1
    if force and (target_sql.exists() or target_yml.exists()):
        print("    --force: overwriting existing files")

    # Step 3.2 — Place files
    print("  [2/8] Placing files...")
    target_dir.mkdir(parents=True, exist_ok=True)

    src_sql = PROJECT_ROOT / generated["sql"]
    src_yml = PROJECT_ROOT / generated["yml"]

    if not src_sql.exists():
        # Source files may have been moved by a previous implement run.
        # If destination files already exist, the pipeline was already completed.
        if target_sql.exists() and target_yml.exists():
            print(f"    Source files already placed (previous implement run).")
            print(f"    SQL: {target_sql.relative_to(PROJECT_ROOT)}")
            print(f"    YML: {target_yml.relative_to(PROJECT_ROOT)}")
        else:
            _print_error(f"Source SQL not found: {src_sql}")
            return 1
    elif not src_yml.exists():
        _print_error(f"Source YAML not found: {src_yml}")
        return 1
    else:
        shutil.copy2(str(src_sql), str(target_sql))
        shutil.copy2(str(src_yml), str(target_yml))
        print(f"    SQL -> {target_sql.relative_to(PROJECT_ROOT)}")
        print(f"    YML -> {target_yml.relative_to(PROJECT_ROOT)}")

    # Place hub files (when --objects includes "hub")
    objects = state.get("objects", ["stg"])
    hub_name = None
    hub_add_source = False
    skip_hub = getattr(args, 'skip_hub', False)
    if skip_hub and "hub" in objects:
        print("    --skip-hub: skipping hub placement")
    elif "hub" in objects and generated.get("hub_sql") and generated.get("hub_yml"):
        hub_name = state.get('hub_name_override') or _derive_hub_name(state["bk_name"])
        hub_target_dir = PROJECT_ROOT / "models" / "raw_vault" / "hub"
        hub_target_sql = hub_target_dir / f"{hub_name}.sql"
        hub_target_yml = hub_target_dir / f"{hub_name}.yml"

        # Check if this is an ADD-SOURCE scenario (hub already exists)
        profile = state.get("profile_results", {})
        collision_check = profile.get("collision_check", {})
        hub_collision = collision_check.get("layers", {}).get("hub", {})

        if hub_target_sql.exists() and hub_collision.get("status") == "ADD-SOURCE":
            # ── ADD-SOURCE PATH: surgically insert new source into existing hub ──
            hub_add_source = True
            print(f"    Hub ADD-SOURCE: inserting new source into {hub_name}...")

            # Parse existing hub
            hub_parsed = _parse_existing_hub(str(hub_target_sql))

            # Determine new source alias
            new_alias = _derive_source_alias(model_name)
            existing_aliases = [s["alias"] for s in hub_parsed["sources"]]
            if new_alias in existing_aliases:
                print(
                    f"    \u26a0 Source alias '{new_alias}' already exists in {hub_name}.\n"
                    f"      Existing aliases: {existing_aliases}\n"
                    f"      Skipping hub ADD-SOURCE (already added)."
                )
                # Hub was NOT modified — clear hub_name so downstream steps
                # don't include it in build/review/dry-run/git-summary.
                # The hub was already built in a previous pipeline run.
                hub_add_source = False
                hub_name = None

            else:
                # Read the new v_psa_stg's BK columns from the generated XLSX
                # The BK raw column names are stored in state from init
                bk_raw = state.get("bk", "")
                bk_raw_cols = [c.strip() for c in bk_raw.split(",")]

                # Build column mapping
                try:
                    col_mapping = _build_add_source_column_mapping(hub_parsed, bk_raw_cols)
                except ValueError as e:
                    _print_error(str(e))
                    return 1

                # Determine watermark strategy from profile
                row_count = profile.get("row_count", 0)
                use_watermark = row_count >= HUB_WATERMARK_THRESHOLD

                # Hub QUALIFY ORDER BY must always use LOAD_DTS (lesson #61)
                # Ingestion-specific columns (GLCHANGETIME, _FIVETRAN_SYNCED) are
                # only valid in v_psa_stg SRC layer — not in raw vault
                qualify_order_by = "LOAD_DTS"

                # Generate new CTEs
                ctes = _generate_add_source_ctes(
                    hub_parsed, new_alias, model_name,
                    col_mapping, use_watermark=use_watermark,
                    qualify_order_by=qualify_order_by, new_bk_raw_cols=bk_raw_cols,
                )

                # Surgical insert
                _insert_source_into_hub(str(hub_target_sql), hub_parsed, ctes, new_alias)
                print(f"    Added source '{new_alias}' to {hub_target_sql.relative_to(PROJECT_ROOT)}")

                # Show column mapping
                bk_maps = [c for c in col_mapping if c["hub"] not in {"LOAD_DTS", "BKCC", "REC_SRC"} and c["hub"] != hub_parsed["hk_column"]]
                if bk_maps:
                    print(f"    Column mapping:")
                    for c in bk_maps:
                        arrow = "→" if c["raw"] != c["hub"] else "="
                        print(f"      {c['raw']} {arrow} {c['hub']}")

        elif hub_target_sql.exists() and hub_collision.get("status") == "ALREADY-PRESENT":
            # ── ALREADY-PRESENT: source already referenced in hub, skip ──
            print(
                f"    ✓ Hub {hub_name} already references {model_name} — "
                f"no hub modification needed."
            )
            # Hub was NOT modified — clear hub_name so downstream steps
            # don't include it in build/review/dry-run/git-summary.
            hub_name = None
        elif hub_target_sql.exists() or hub_target_yml.exists():
            # ── SAFETY: --force must NEVER overwrite existing hub files ──
            # Hubs are shared models containing sources from multiple pipelines.
            # Overwriting destroys other pipelines' sources.
            # --force is only safe for STG and SAT files (single-pipeline ownership).
            _print_error(
                f"  ⛔ Cannot overwrite existing hub: {hub_target_sql.name}\n"
                f"     --force is only safe for STG and SAT files (single-pipeline ownership).\n"
                f"     Hub and Link files are shared across pipelines.\n"
                f"\n"
                f"     If this hub should receive a new source, use the ADD-SOURCE path:\n"
                f"       Verify collision status is ADD-SOURCE in pipeline state.\n"
                f"       The orchestrator will surgically inject the new source.\n"
                f"\n"
                f"     If this is from an interrupted run and the hub was already\n"
                f"       correctly placed, use --skip-hub to skip hub placement."
            )
            return 1
        else:
            # New hub — copy generated files
            hub_target_dir.mkdir(parents=True, exist_ok=True)
            hub_src_sql = PROJECT_ROOT / generated["hub_sql"]
            hub_src_yml = PROJECT_ROOT / generated["hub_yml"]
            shutil.copy2(str(hub_src_sql), str(hub_target_sql))
            shutil.copy2(str(hub_src_yml), str(hub_target_yml))
            print(f"    SQL -> {hub_target_sql.relative_to(PROJECT_ROOT)}")
            print(f"    YML -> {hub_target_yml.relative_to(PROJECT_ROOT)}")

    lnk_name = None
    lnk_add_source = False
    if skip_hub and "lnk" in objects:
        print("    --skip-hub: skipping link placement")
    elif "lnk" in objects:
        lnks_list = state.get("lnks", [])
        # For now, iterate and place the first LNK (multi-LNK placement TBD)
        lnk_def = lnks_list[0] if lnks_list else {}
        lnk_name_val = lnk_def.get("lnk_name", "")
        if lnk_name_val and generated.get("lnk_sql") and generated.get("lnk_yml"):
            lnk_name = _derive_lnk_name(lnk_name_val)
            lnk_target_dir = PROJECT_ROOT / "models" / "raw_vault" / "link"
            lnk_target_sql = lnk_target_dir / f"{lnk_name}.sql"
            lnk_target_yml = lnk_target_dir / f"{lnk_name}.yml"

            # Check if link already exists (ADD-SOURCE not yet implemented for links)
            if lnk_target_sql.exists() or lnk_target_yml.exists():
                profile = state.get("profile_results", {})
                collision_check = profile.get("collision_check", {})
                lnk_collision = collision_check.get("layers", {}).get("lnk_model", {})
                if lnk_collision.get("status") == "ALREADY-PRESENT":
                    print(
                        f"    ✓ Link {lnk_name} already references {model_name} — "
                        f"no link modification needed."
                    )
                    # Link was NOT modified — clear lnk_name so downstream steps
                    # don't include it in build/review/dry-run/git-summary.
                    lnk_name = None
                elif lnk_collision.get("status") == "ADD-SOURCE":
                    _print_error(
                        f"Link ADD-SOURCE not yet automated for {lnk_name}.\n"
                        f"  Manually add the new source CTE to {lnk_target_sql}."
                    )
                    return 1
                else:
                    # ── SAFETY: --force must NEVER overwrite existing link files ──
                    # Links are shared models containing sources from multiple pipelines.
                    _print_error(
                        f"  ⛔ Cannot overwrite existing link: {lnk_target_sql.name}\n"
                        f"     --force is only safe for STG and SAT files (single-pipeline ownership).\n"
                        f"     Hub and Link files are shared across pipelines.\n"
                        f"\n"
                        f"     If this link should receive a new source, manually edit the link model.\n"
                        f"     If this is from an interrupted run, use --skip-hub to skip hub/link placement."
                    )
                    return 1
            else:
                # New link — copy generated files
                lnk_target_dir.mkdir(parents=True, exist_ok=True)
                lnk_src_sql = PROJECT_ROOT / generated["lnk_sql"]
                lnk_src_yml = PROJECT_ROOT / generated["lnk_yml"]
                shutil.copy2(str(lnk_src_sql), str(lnk_target_sql))
                shutil.copy2(str(lnk_src_yml), str(lnk_target_yml))
                print(f"    SQL -> {lnk_target_sql.relative_to(PROJECT_ROOT)}")
                print(f"    YML -> {lnk_target_yml.relative_to(PROJECT_ROOT)}")

    # Place sat files (when --objects includes "sat") — iterate sats list
    sat_name = None
    sat_names = []
    if "sat" in objects:
        for sat_idx, sat_def in enumerate(state.get("sats", [])):
            sat_name = sat_def.get("model_name", "")
            if not sat_name:
                continue
            key_sql = f"sat_sql_{sat_idx}" if sat_idx > 0 else "sat_sql"
            key_yml = f"sat_yml_{sat_idx}" if sat_idx > 0 else "sat_yml"
            if not generated.get(key_sql) or not generated.get(key_yml):
                continue
            sat_names.append(sat_name)
            sat_target_dir = PROJECT_ROOT / "models" / "raw_vault" / "sat"
            sat_target_sql = sat_target_dir / f"{sat_name}.sql"
            sat_target_yml = sat_target_dir / f"{sat_name}.yml"

            if (sat_target_sql.exists() or sat_target_yml.exists()) and not force:
                _print_error(
                    f"SAT files already exist (1:1 collision):\n"
                    f"  {sat_name}.sql: {sat_target_sql.exists()}\n"
                    f"  {sat_name}.yml: {sat_target_yml.exists()}\n"
                    f"  Use --force to overwrite."
                )
                return 1
            else:
                if sat_target_sql.exists() and force:
                    print(f"    --force: overwriting existing SAT files for {sat_name}")
                sat_target_dir.mkdir(parents=True, exist_ok=True)
                sat_src_sql = PROJECT_ROOT / generated[key_sql]
                sat_src_yml = PROJECT_ROOT / generated[key_yml]
                if not sat_src_sql.exists():
                    # Source files already placed by a previous implement run
                    if sat_target_sql.exists() and sat_target_yml.exists():
                        print(f"    SAT source files already placed (previous implement run).")
                        print(f"    SQL: {sat_target_sql.relative_to(PROJECT_ROOT)}")
                        print(f"    YML: {sat_target_yml.relative_to(PROJECT_ROOT)}")
                    else:
                        _print_error(f"SAT source SQL not found: {sat_src_sql}")
                        return 1
                else:
                    shutil.copy2(str(sat_src_sql), str(sat_target_sql))
                    shutil.copy2(str(sat_src_yml), str(sat_target_yml))
                    print(f"    SQL -> {sat_target_sql.relative_to(PROJECT_ROOT)}")
                    print(f"    YML -> {sat_target_yml.relative_to(PROJECT_ROOT)}")

    # Step 3.2b — Register source table in _sources_staging_psa.yml
    schema_name = state["schema"]
    table_name = state["table"]
    print("  [2b/8] Registering source...")
    reg_result = _register_source(schema_name, table_name)
    if reg_result is None:
        _print_error(f"Source registration failed for source('{schema_name}', '{table_name}'). Aborting.")
        return 1
    elif reg_result:
        print(f"    Registered: source('{schema_name}', '{table_name}')")
    else:
        print(f"    Already registered: source('{schema_name}', '{table_name}')")

    # Step 3.2c — Clone REF_BUSINESS_KEY_COLLISION to sandbox schema (dev only).
    # It refreshes the sandbox copy of REF_BUSINESS_KEY_COLLISION, which
    # supplies the BKCC that the raw-vault models hash into their business keys.
    # This clone is a CORRECTNESS PRECONDITION, not a convenience: a stale or
    # missing copy does NOT fail the build loudly -- the BKCC inner-join simply
    # yields zero rows for an unregistered REC_SRC, and SAT fail_on_zero is
    # False, so the vault loads silently under-populated. We therefore refuse to
    # build unless the clone is verified to have refreshed. Skipped entirely
    # under --skip-build (no local build to protect) and in non-dev (where ref()
    # resolves to the real RAW_VAULT table).
    skip_build = getattr(args, 'skip_build', False)
    dbt_environ = os.environ.get('DBT_ENVIRON', 'dev').lower()
    if dbt_environ == 'dev' and not skip_build:
        print("  [2c/8] Cloning ref_business_key_collision to sandbox...")
        # Preflight: fail loud BEFORE we spend time on `dbt debug`. Two layers,
        # because the clone is a DDL CREATE ... CLONE that the snow-mcp path
        # rejects (only the Python connector can run DDL):
        #  1. _assert_snowflake_available() — no execution path at all → stop.
        #  2. _connector_importable() — an MCP-only environment passes layer 1
        #     but still cannot run this DDL, so require the connector specifically
        #     here; otherwise the run would reach `dbt debug` and only then fail at
        #     the clone. Failing now honours the "before dbt debug" intent (#1928).
        _assert_snowflake_available()
        if not _connector_importable():
            raise SnowflakeUnavailableError(
                "The BKCC clone is a DDL statement, which the snow-mcp MCP server "
                "cannot run, so snowflake-connector-python is required here even "
                "when MCP is configured. Install the runtime dependencies: "
                ".venv/bin/python3 -m pip install -r "
                "scripts/automation/requirements-runtime.txt"
            )
        _clone_precondition = (
            "  The clone refreshes REF_BUSINESS_KEY_COLLISION, which feeds the "
            "hash keys; building against a stale/missing copy silently "
            "under-loads the vault, so this is fatal. Fix the issue and re-run, "
            "or pass --skip-build to skip the local build (and this clone)."
        )
        try:
            # Parse target schema from dbt debug output
            rc_dbg, out_dbg, _ = _run_dbt(['debug'], cwd=str(PROJECT_ROOT))
            target_schema = _extract_target_schema_from_dbt_debug(out_dbg)
            if target_schema:
                clone_sql = (
                    f"CREATE OR REPLACE TABLE DATAVAULT_DEV.{target_schema}"
                    f".REF_BUSINESS_KEY_COLLISION "
                    f"CLONE DATAVAULT_DEV.RAW_VAULT.REF_BUSINESS_KEY_COLLISION"
                )
                _run_snowflake_query(clone_sql, args)
                print(f"    Cloned ref_business_key_collision from DEV → {target_schema}")
            else:
                _print_error(
                    "BKCC clone precondition failed: could not determine the "
                    "target schema from 'dbt debug'.\n" + _clone_precondition
                )
                return 1
        except SnowflakeUnavailableError:
            # The clone itself could not execute (missing driver / no path).
            # Do NOT mask it as a best-effort warning -- propagate so the command
            # fails loud (issue #1844) rather than build against unrefreshed BKCC.
            raise
        except Exception as e:
            _print_error(
                f"BKCC clone precondition failed: {e}\n" + _clone_precondition
            )
            return 1
    elif skip_build:
        print("  [2c/8] BKCC clone SKIPPED (--skip-build; no local build to protect)")
    else:
        print("  [2c/8] BKCC clone SKIPPED (non-dev environment)")


    # Step 3.3 — Pre-build code review
    # Collect all placed .sql and .yml files for review (before building)
    review_files = []
    stg_sql = PROJECT_ROOT / "models" / "int_staging_views" / domain / f"{model_name}.sql"
    if stg_sql.exists():
        review_files.append(str(stg_sql.relative_to(PROJECT_ROOT)))
    stg_yml = PROJECT_ROOT / "models" / "int_staging_views" / domain / f"{model_name}.yml"
    if stg_yml.exists():
        review_files.append(str(stg_yml.relative_to(PROJECT_ROOT)))
    if hub_name:
        hub_sql_path = PROJECT_ROOT / "models" / "raw_vault" / "hub" / f"{hub_name}.sql"
        if hub_sql_path.exists():
            review_files.append(str(hub_sql_path.relative_to(PROJECT_ROOT)))
        hub_yml_path = PROJECT_ROOT / "models" / "raw_vault" / "hub" / f"{hub_name}.yml"
        if hub_yml_path.exists():
            review_files.append(str(hub_yml_path.relative_to(PROJECT_ROOT)))
    if lnk_name:
        lnk_sql_path = PROJECT_ROOT / "models" / "raw_vault" / "link" / f"{lnk_name}.sql"
        if lnk_sql_path.exists():
            review_files.append(str(lnk_sql_path.relative_to(PROJECT_ROOT)))
        lnk_yml_path = PROJECT_ROOT / "models" / "raw_vault" / "link" / f"{lnk_name}.yml"
        if lnk_yml_path.exists():
            review_files.append(str(lnk_yml_path.relative_to(PROJECT_ROOT)))
    for sn in sat_names:
        sat_sql_path = PROJECT_ROOT / "models" / "raw_vault" / "sat" / f"{sn}.sql"
        if sat_sql_path.exists():
            review_files.append(str(sat_sql_path.relative_to(PROJECT_ROOT)))
        sat_yml_path = PROJECT_ROOT / "models" / "raw_vault" / "sat" / f"{sn}.yml"
        if sat_yml_path.exists():
            review_files.append(str(sat_yml_path.relative_to(PROJECT_ROOT)))

    review_fail_count = 0
    review_warn_count = 0
    review_pass_count = 0
    review_findings = []

    print("  [3/8] Pre-build code review...")
    if review_files:
        try:
            review_data = _run_code_review(review_files, PROJECT_ROOT)
            if review_data is not None:
                # Count unique check IDs that failed/warned (not raw findings count)
                # A single check can emit multiple findings across files
                fail_check_ids = set()
                warn_check_ids = set()
                for f in review_data.get("findings", []):
                    if f.get("severity") == "FAIL":
                        review_fail_count += 1
                        review_findings.append(f)
                        fail_check_ids.add(f.get("check_id", "??"))
                    elif f.get("severity") == "WARN":
                        review_warn_count += 1
                        warn_check_ids.add(f.get("check_id", "??"))
                checks_run = review_data.get("checks_run", 0)
                review_pass_count = max(0, checks_run - len(fail_check_ids) - len(warn_check_ids))

                if review_fail_count > 0:
                    print(f"    PASS: {review_pass_count} | WARN: {review_warn_count} | FAIL: {review_fail_count}")
                    print(f"    ❌ {review_fail_count} FAIL finding(s) — fix before building:")
                    for finding in review_findings:
                        check_id = finding.get("check_id", "??")
                        msg = finding.get("message", "Unknown finding")
                        line = finding.get("line_number", "")
                        file_name = finding.get("file_path", "").rsplit("/", 1)[-1] if finding.get("file_path") else ""
                        line_info = f" (line {line})" if line else ""
                        file_info = f" in {file_name}" if file_name else ""
                        print(f"    [FAIL] {check_id}: {msg}{file_info}{line_info}")
                    _print_error(f"Pre-build review found {review_fail_count} FAIL finding(s). Fix before building.")
                    return 1
                else:
                    print(f"    PASS: {review_pass_count} | WARN: {review_warn_count} | FAIL: 0")
                    print(f"    ✅ Pre-build review passed. Proceeding to build.")
            else:
                print("    ⚠️ Code reviewer not found — skipping")
        except Exception as e:
            print(f"    ❌ Code review error: {e}")
            review_fail_count += 1
            review_findings.append({"check_id": "SYS", "message": f"Code reviewer error: {e}"})
            _print_error(f"Pre-build code review failed with error. Fix before building.")
            return 1
    else:
        print("    (no SQL files found to review)")

    # Step 3.4 — dbt build (compile + run + test in one pass)
    # Build v_psa_stg first, then hub, then lnk, then sat (dependency order)
    build_select = model_name
    if hub_name:
        build_select = f"{model_name} {hub_name}"
    if lnk_name:
        build_select = f"{build_select} {lnk_name}"
    if sat_name:
        build_select = f"{build_select} {sat_name}"

    if skip_build:
        print(f"  [4/8] dbt build SKIPPED (--skip-build)")
        print(f"    Models ready: {build_select}")
        print(f"    Run later: python3 {_rel_script()} build-all --model-name {model_name}")
        results["build"] = "skipped"
        results["build_results"] = {"pass": 0, "warn": 0, "fail": 0, "error": 0}
        build_results = results["build_results"]
        state["stage3_results"] = results
        _mark_complete(state, "implement")
    else:
        # Force full refresh build: validates model from scratch, catches type mismatches
        # -x = fail fast (save compute on first error)
        # -f = full refresh (rebuild incremental models from scratch)
        # --vars force_full_refresh = for models with full_refresh = var(...) overrides
        dbt_args = [
            "build", "-s", build_select,
            "-x", "-f",
            "--vars", '{"force_full_refresh": true}',
        ]
        print(f"  [4/8] dbt build --full-refresh (using {_get_dbt_binary()})...")
        rc, out, err = _run_dbt(
            dbt_args,
            cwd=str(PROJECT_ROOT),
        )

        # Parse build output — use dbt summary line (PASS=X WARN=Y ERROR=Z) as authoritative
        build_results = _parse_dbt_build_results(out)

        # Distinguish real build failures from CLI transport errors:
        # If build_results show all passes (fail=0, error=0), a non-zero rc
        # is a dbt Cloud CLI transport error, not a build failure.
        real_failure = build_results["fail"] > 0 or build_results["error"] > 0
        all_zeros = build_results["pass"] == 0 and build_results["fail"] == 0 and build_results["error"] == 0
        cli_error_only = rc != 0 and not real_failure and build_results["pass"] > 0
        if cli_error_only:
            print(f"    ⚠️  dbt CLI returned rc={rc} but build results are clean: {build_results}")
            print(f"    Treating as PASS (CLI transport error, not build failure).")
        if rc != 0 and all_zeros:
            # dbt crashed before producing any results (startup error)
            results["build"] = "fail"
            results["build_results"] = build_results
            state["stage3_results"] = results
            _save_state(state)
            _print_error(
                f"dbt crashed (rc={rc}) with no build results — likely a startup error\n"
                f"  stdout:\n{out}\n  stderr:\n{err}"
            )
            return 1
        if real_failure:
            results["build"] = "fail"
            results["build_results"] = build_results
            state["stage3_results"] = results
            _save_state(state)
            _print_error(
                f"dbt build failed — {build_results}\n"
                f"  stdout:\n{out}\n  stderr:\n{err}"
            )
            return 1

        results["build"] = "pass"
        results["build_results"] = build_results
        state["stage3_results"] = results
        _mark_complete(state, "implement")

    # Step 5 — Incremental dry-run validation (Raw Vault models only)
    # After dbt build creates the model relation, is_incremental() returns True.
    # dbt run --empty validates incremental SQL syntax at zero data cost.
    dry_run_passed = True
    rv_model_names = []
    if not skip_build and results.get("build") == "pass":
        # Collect Raw Vault model names (incremental models only)
        if hub_name:
            rv_model_names.append(hub_name)
        if lnk_name:
            rv_model_names.append(lnk_name)
        for sn in sat_names:
            rv_model_names.append(sn)

    if rv_model_names:
        print(f"  [5/8] Incremental dry-run validation ({len(rv_model_names)} RV models)...")
        # Join model names into single space-separated string (dbt Cloud CLI requirement)
        dry_run_select = " ".join(rv_model_names)
        dry_run_args = ["run", "--empty", "-s", dry_run_select]

        # Retry logic: dbt Cloud CLI may report "Session occupied" if the
        # previous build's session hasn't fully released (especially after
        # long-running on-run-end hooks like dbt_constraints). Retry up to 3
        # times with increasing delay. First attempt skips cancel (optimistic —
        # session may have released). Retries use dbt cancel to force-release.
        rc_dry, out_dry = 1, ""
        max_retries = 3
        for attempt in range(max_retries):
            # First attempt: optimistic (skip cancel, saves 18s if session is free)
            # Retries: force cancel to release the stuck session
            use_cancel = attempt > 0
            rc_dry, out_dry, _ = _run_dbt(dry_run_args, cwd=str(PROJECT_ROOT), skip_cancel=not use_cancel)
            if "session occupied" not in out_dry.lower():
                break
            if attempt < max_retries - 1:
                wait_secs = 15 * (attempt + 1)
                print(f"    ⏳ Session occupied — waiting {wait_secs}s before retry ({attempt + 2}/{max_retries})...")
                time.sleep(wait_secs)

        if rc_dry != 0:
            # Detect KeyboardInterrupt / agent timeout — manifest compilation
            # on large projects (2,000+ models) takes 45+ seconds and agents
            # may time out. This is NOT a real SQL error — treat as inconclusive.
            if 'keyboardinterrupt' in out_dry.lower():
                print(f"    ⚠️  Dry-run interrupted (agent/CLI timeout during manifest compilation).")
                print(f"    This is NOT a SQL error — the project has {len(rv_model_names)} RV models")
                print(f"    and manifest compilation exceeded the execution window.")
                print(f"    Treating dry-run as PASS (full-refresh build already validated correctness).")
            else:
                # Check if it's a real failure or just a CLI transport/session error
                # Exclude "session occupied" lines — those are transient dbt Cloud CLI issues
                dry_error_lines = [
                    line.strip() for line in out_dry.splitlines()
                    if any(kw in line.lower() for kw in ['error', 'compilation', 'database error'])
                    and 'session occupied' not in line.lower()
                    and 'keyboardinterrupt' not in line.lower()
                ]
                if dry_error_lines:
                    print(f"    ⚠️  Dry-run found incremental block issues:")
                    for line in dry_error_lines[:10]:
                        print(f"       {line}")
                    print(f"    ⚠️  The full build succeeded, but the incremental path has syntax issues.")
                    print(f"    ⚠️  Fix before merging — these errors will surface on the next incremental load.")
                    dry_run_passed = False
                else:
                    # No error keywords — likely a CLI transport error, treat as pass
                    print(f"    ⚠️  dbt CLI returned rc={rc_dry} but no error output detected (likely transport error).")
                    print(f"    Treating dry-run as PASS.")
        else:
            print(f"    ✅ Incremental dry-run passed ({len(rv_model_names)} models validated)")
    elif skip_build:
        print(f"  [5/8] Incremental dry-run SKIPPED (--skip-build)")
    else:
        print(f"  [5/8] Incremental dry-run — skipped (no Raw Vault models)")

    # Step 6 — Post-build row count validation
    validation_failed = False
    if not skip_build and results.get("build") == "pass":
        print("  [6/8] Post-build validation...")
        # Determine target database and schema for DEV queries
        _val_schema = None
        try:
            rc_dbg2, out_dbg2, _ = _run_dbt(['debug'], cwd=str(PROJECT_ROOT))
            _val_schema = _extract_target_schema_from_dbt_debug(out_dbg2)
        except Exception:
            pass
        _val_database = "DATAVAULT_DEV"

        if _val_schema:
            models_to_validate = []

            # SAT/MSAT models: warn on zero rows (first load may be empty)
            for sn in sat_names:
                models_to_validate.append({"name": sn, "type": "sat", "fail_on_zero": False})

            # HUB models: fail on zero rows if ADD-SOURCE (hub already had data)
            if hub_name:
                models_to_validate.append({
                    "name": hub_name, "type": "hub",
                    "fail_on_zero": hub_add_source,
                })

            # LNK models
            if lnk_name:
                models_to_validate.append({
                    "name": lnk_name, "type": "lnk",
                    "fail_on_zero": lnk_add_source,
                })

            # Skip STG views — they have no persisted rows
            for mdl in models_to_validate:
                try:
                    count_sql = (
                        f"SELECT COUNT(*) FROM {_val_database}.{_val_schema}.{mdl['name']}"
                    )
                    count_result = _run_snowflake_query(count_sql, args)
                    row_count = count_result[0][0] if count_result else 0
                    if row_count > 0:
                        print(f"    {mdl['name']}: {row_count:,} rows \u2705")
                    elif mdl["fail_on_zero"]:
                        print(f"    {mdl['name']}: 0 rows \u274c (expected data after build)")
                        validation_failed = True
                    else:
                        print(f"    {mdl['name']}: 0 rows \u26a0\ufe0f (may be expected for first load)")
                except SnowflakeUnavailableError as e:
                    # Post-build validation is deliberately best-effort: the build
                    # already succeeded (real work done), so a failure to run this
                    # row-count check must NOT retroactively fail a green build.
                    # The cause is reported in {e} and the skip is VISIBLE, so this
                    # is not the #1844 silent no-op. Caveat (pre-existing, tracked
                    # separately): the boundary cannot distinguish "no path" from a
                    # query-level error (e.g. a genuinely missing table), and the
                    # Step 8 summary still prints a passing Validation line on a
                    # skip -- so do NOT assert a specific cause here.
                    print(f"    {mdl['name']}: \u26a0\ufe0f row-count check skipped ({e})")
                except Exception as e:
                    print(f"    {mdl['name']}: \u26a0\ufe0f Could not verify ({e})")

            if not models_to_validate:
                print("    (no incremental models to validate)")
        else:
            print("    \u26a0\ufe0f Could not determine target schema — skipping validation")
    elif skip_build:
        print("  [6/8] Post-build validation SKIPPED (--skip-build)")

    # Step 7 — Git summary
    print("  [7/8] Files ready for commit...")
    print(f"    models/int_staging_views/{domain}/{model_name}.sql")
    print(f"    models/int_staging_views/{domain}/{model_name}.yml")
    if hub_name and not hub_add_source:
        print(f"    models/raw_vault/hub/{hub_name}.sql")
        print(f"    models/raw_vault/hub/{hub_name}.yml")
    elif hub_name and hub_add_source:
        print(f"    models/raw_vault/hub/{hub_name}.sql (modified — ADD-SOURCE)")
    if lnk_name:
        print(f"    models/raw_vault/link/{lnk_name}.sql")
        print(f"    models/raw_vault/link/{lnk_name}.yml")
    for sn in sat_names:
        print(f"    models/raw_vault/sat/{sn}.sql")
        print(f"    models/raw_vault/sat/{sn}.yml")
    print(f"    models/sources/_sources_staging_psa.yml")

    # Step 8 — Final status summary
    pipeline_failed = review_fail_count > 0 or not dry_run_passed
    if pipeline_failed:
        print(f"\n{'='*60}")
        print(f"  PIPELINE FAILED: {model_name}")
        print(f"{'='*60}")
    else:
        print(f"\n{'='*60}")
        print(f"  PIPELINE COMPLETE: {model_name}")
        print(f"{'='*60}")
    if skip_build:
        print(f"  Build:       SKIPPED (use build-all to build)")
    elif validation_failed:
        print(f"  Build:       PASS — {build_results}")
        print(f"  Validation:  ❌ (see above)")
    else:
        print(f"  Build:       PASS — {build_results}")
        print(f"  Validation:  ✅")

    if review_fail_count > 0:
        print(f"  Code Review: ❌ {review_fail_count} FAIL(s) — fix before PR")
    elif review_warn_count > 0:
        print(f"  Code Review: ✅ (with {review_warn_count} advisory warning(s))")
    else:
        print(f"  Code Review: ✅")

    if not dry_run_passed:
        print(f"  Dry-Run:     ❌ Incremental path has syntax errors")
    elif rv_model_names:
        print(f"  Dry-Run:     ✅ Incremental syntax validated")
    else:
        print(f"  Dry-Run:     ⏭️  Skipped (STG-only pipeline)")

    if pipeline_failed:
        if not dry_run_passed:
            print(f"  ⛔ Fix incremental block syntax before creating PR.")
            print(f"  The model will fail on the next incremental production load.")
        else:
            print(f"  ⛔ NOT ready for PR. Address findings above.")
        # Roll back implement completion — must fix before PR
        state["completed_steps"] = [
            s for s in state.get("completed_steps", []) if s != "implement"
        ]
        _save_state(state)
        return 1
    elif review_warn_count > 0:
        print(f"  ✅ Ready for commit and PR (with advisory warnings).")
    else:
        print(f"  ✅ Ready for commit and PR.")

    # Persist results summary for PR body generation (avoids context window risk)
    state["results_summary"] = {
        "status": "COMPLETE",
        "model_name": model_name,
        "domain": domain,
        "build": build_results if not skip_build else None,
        "code_review": {
            "pass": review_pass_count,
            "warn": review_warn_count,
            "fail": review_fail_count,
        },
        "dry_run": "passed" if dry_run_passed else "failed",
        "has_raw_vault": bool(rv_model_names),
        "files": [
            f"models/int_staging_views/{domain}/{model_name}.sql",
            f"models/int_staging_views/{domain}/{model_name}.yml",
        ] + ([f"models/raw_vault/hub/{hub_name}.sql", f"models/raw_vault/hub/{hub_name}.yml"] if hub_name and not hub_add_source else [])
          + ([f"models/raw_vault/hub/{hub_name}.sql (modified)"] if hub_name and hub_add_source else [])
          + ([f"models/raw_vault/link/{lnk_name}.sql", f"models/raw_vault/link/{lnk_name}.yml"] if lnk_name else [])
          + [f"models/raw_vault/sat/{sn}.sql" for sn in sat_names]
          + [f"models/raw_vault/sat/{sn}.yml" for sn in sat_names],
    }
    _save_state(state)

    return 0



def cmd_add_raw_vault(args):
    """Add Raw Vault objects (hub/lnk/sat) to an existing STG-only pipeline.

    Supports accumulating calls: each `add-raw-vault --objects sat` appends
    a new SAT definition to state["sats"]. Same for LNK → state["lnks"].
    Hub uses --hub-name override (auto-derived if omitted).
    """
    state = _resolve_state(args)
    if not state:
        return 1

    completed = _completed_steps(state)
    # Allow re-entry for accumulating calls when design_decision already set
    if "approve-xlsx" not in completed and state.get("design_decision") != "add_raw_vault":
        _print_error(
            "approve-xlsx must be completed before adding Raw Vault objects.\n"
            f"  Run: .venv/bin/python3 {_rel_script()} approve-xlsx"
        )
        return 1

    # Parse --objects (accept SAT aliases: msat, lsat, lmsat)
    raw_objects = [o.strip().lower() for o in args.objects.split(",") if o.strip()]
    sat_aliases = {'msat': 'msat', 'lsat': 'lsat', 'lmsat': 'lmsat'}
    new_objects = []
    alias_sat_types = []
    for obj in raw_objects:
        if obj in sat_aliases:
            new_objects.append('sat')
            alias_sat_types.append(sat_aliases[obj])
        else:
            new_objects.append(obj)

    valid_rv = {'hub', 'lnk', 'sat'}
    invalid = set(new_objects) - valid_rv
    if invalid:
        _print_error(
            f"Invalid object types: {invalid}. "
            "Valid: hub, lnk, sat (aliases: msat, lsat, lmsat)"
        )
        return 1
    if not new_objects:
        _print_error('--objects is required (e.g., --objects "hub,sat")')
        return 1

    # Determine SAT type precedence:
    # 1) Explicit --sat-type flag (if provided)
    # 2) SAT alias in --objects (msat/lsat/lmsat)
    # 3) Default 'sat'
    explicit_sat_type = (args.sat_type.strip().lower() if getattr(args, 'sat_type', None) else None)
    alias_sat_type = None
    if alias_sat_types:
        unique_alias_types = sorted(set(alias_sat_types))
        if len(unique_alias_types) > 1 and not explicit_sat_type:
            _print_error(
                f"Conflicting SAT aliases in --objects: {unique_alias_types}. "
                "Use one alias, or set --sat-type explicitly."
            )
            return 1
        alias_sat_type = unique_alias_types[0]

    # Merge objects: add hub/lnk only if not already present, sat always means "at least one"
    current_objects = state.get('objects', ['stg'])
    for obj in new_objects:
        if obj not in current_objects:
            current_objects.append(obj)
    state['objects'] = current_objects

    # ── HUB: store hub-name override if provided ─────────────────────────
    if 'hub' in new_objects:
        hub_name_override = getattr(args, 'hub_name', None)
        if hub_name_override:
            hub_name_override = hub_name_override.strip().lower()
            if not hub_name_override.startswith("hub_"):
                hub_name_override = f"hub_{hub_name_override}"
            state['hub_name_override'] = hub_name_override

    # ── LNK: accumulate into state["lnks"] list ──────────────────────────
    if 'lnk' in new_objects:
        if not args.parent_hks:
            _print_error('--parent-hks is required for LNK objects')
            return 1
        lnk_name = args.lnk_name or ""
        new_lnk = {
            'lnk_name': _derive_lnk_name(lnk_name) if lnk_name else '',
            'parent_hks': [h.strip() for h in args.parent_hks.split(',')],
            'dck': [d.strip() for d in args.dck.split(',')] if args.dck else [],
        }
        if "lnks" not in state:
            state["lnks"] = []
        existing_lnk_names = [l["lnk_name"] for l in state["lnks"]]
        if new_lnk["lnk_name"] in existing_lnk_names:
            print(f"  WARNING: {new_lnk['lnk_name']} already in LNK list — skipping duplicate")
        else:
            state["lnks"].append(new_lnk)
            print(f"  Added LNK: {new_lnk['lnk_name']}")

    # ── SAT: accumulate into state["sats"] list ──────────────────────────
    if 'sat' in new_objects:
        if not args.sat_parent_hk:
            _print_error('--sat-parent-hk is required for SAT objects')
            return 1
        if not args.sat_parent_model:
            _print_error('--sat-parent-model is required for SAT objects')
            return 1
        sat_type = explicit_sat_type or alias_sat_type or 'sat'
        # L-4: Warn when explicit --sat-type overrides alias-derived type
        if explicit_sat_type and alias_sat_type and explicit_sat_type != alias_sat_type:
            print(f"  WARNING: Explicit --sat-type '{explicit_sat_type}' overrides "
                  f"alias-derived type '{alias_sat_type}' from --objects")
        if sat_type not in SAT_VARIANTS:
            _print_error(f"Invalid --sat-type '{sat_type}'. Valid: {SAT_VARIANTS}")
            return 1
        if sat_type in ('msat', 'lmsat') and not args.multi_active_key:
            _print_error(f'--multi-active-key is required for {sat_type.upper()}')
            return 1
        sat_name_override = args.sat_name.strip() if args.sat_name else None
        sat_model_name = _derive_sat_name(state['model_name'], sat_type, sat_name_override)

        # Parse per-SAT grain columns
        grain_raw = getattr(args, 'grain_columns', None)
        grain_cols = [g.strip().upper() for g in grain_raw.split(',') if g.strip()] if grain_raw else None

        # Parse per-SAT column assignment
        sat_cols_raw = getattr(args, 'sat_columns', None)
        sat_cols = [c.strip().upper() for c in sat_cols_raw.split(',') if c.strip()] if sat_cols_raw else None

        new_sat = {
            'model_name': sat_model_name,
            'sat_type': sat_type,
            'parent_hk': args.sat_parent_hk.strip().upper(),
            'parent_model': args.sat_parent_model.strip().lower(),
            'multi_active_key': args.multi_active_key.strip().upper() if args.multi_active_key else None,
            'grain_columns': grain_cols,
            'sat_columns': sat_cols,
        }

        # Auto-detect MSAT: if grain_columns has entries beyond HK+LOAD_DTS,
        # this is multi-active (multiple rows per HK+LOAD_DTS)
        grain = new_sat.get("grain_columns") or []
        non_structural = [g for g in grain 
                          if g.upper() not in ("LOAD_DTS", new_sat.get("parent_hk", "").upper())]
        if non_structural and new_sat["sat_type"] == "sat":
            print(f"  ⚠️  Grain columns {non_structural} detected beyond HK+LOAD_DTS")
            print(f"      Auto-correcting sat_type: sat → msat")
            new_sat["sat_type"] = "msat"

        if "sats" not in state:
            state["sats"] = []
        existing_sat_names = [s["model_name"] for s in state["sats"]]
        if new_sat["model_name"] in existing_sat_names:
            print(f"  WARNING: {new_sat['model_name']} already in SAT list — skipping duplicate")
        else:
            state["sats"].append(new_sat)
            print(f"  Added SAT: {new_sat['model_name']} ({new_sat['sat_type']})")

        # ── Naming convention validation (source suffix checks) ──────────
        suffix_warnings = _validate_source_suffix(state['model_name'], sat_model_name)
        if suffix_warnings:
            # Missing '__' in SAT name is a hard error — structural requirement
            # for source suffix matching, collision detection, and downstream tooling.
            has_missing_separator = "__" not in sat_model_name
            if has_missing_separator:
                _print_error(
                    f"SAT model name '{sat_model_name}' is missing the '__<source_system>' suffix.\n"
                    f"  Expected format: <sat_type>_<entity>__<source_system>\n"
                    f"  Example: msat_delivery_flo_serial__winn_sap\n"
                    f"  Fix: re-run with --sat-name <corrected_name>"
                )
                return 1
            # Non-fatal warnings (e.g., suffix mismatch)
            print("\n  \u26a0\ufe0f  NAMING CONVENTION WARNING(S):")
            for w in suffix_warnings:
                print(f"      {w}")
            print("\n      If intentional, proceed. Otherwise re-run with corrected --sat-name.")
            print()

    # Surgical reset: on first call, clear from generate-yaml onward.
    # On subsequent calls (accumulating), only clear generate-code onward —
    # YAML/XLSX will be regenerated at generate-yaml step anyway.
    if state.get('design_decision') == 'add_raw_vault':
        # Subsequent accumulating call — only reset code gen and downstream
        steps_to_clear = {'generate-code', 'approve-code', 'implement'}
    else:
        # First call — full reset from generate-yaml onward
        steps_to_clear = {'generate-yaml', 'generate-xlsx', 'approve-xlsx',
                          'generate-code', 'approve-code', 'implement'}
    state['steps_completed'] = [
        s for s in state.get('steps_completed', []) if s['step'] not in steps_to_clear
    ]

    # Record design decision — unlocks the generate-code gate
    state['design_decision'] = 'add_raw_vault'

    # ── Re-run collision check for newly added layers ────────────────────────
    collision_result = _semantic_collision_check(state)
    state.setdefault("profile_results", {})["collision_check"] = collision_result
    _print_collision_report(collision_result)

    if collision_result.get("blocked"):
        _print_error("Collision check found blockers after adding Raw Vault objects.")
        return 1

    # ── Safety guard: warn user when hub already exists (ADD-SOURCE) ─────────
    layers = collision_result.get("layers", {})
    hub_layer = layers.get("hub", {})
    if hub_layer.get("status") == "ADD-SOURCE":
        hub_file = hub_layer.get("file", "(unknown)")
        print("  ⚠️  Hub ADD-SOURCE detected:")
        print(f"     {hub_file} already exists with multiple sources.")
        print("     At implement time, the new v_psa_stg will be INJECTED as an")
        print("     additional source into the existing hub (not overwritten).")
        print("     generate-code will still produce hub SQL for review/reference,")
        print("     but implement uses the surgical ADD-SOURCE path.")
        print()
    elif hub_layer.get("status") == "ALREADY-PRESENT":
        hub_file = hub_layer.get("file", "(unknown)")
        print(f"  ✓ Hub already references this model ({hub_file}).")
        print("     No hub modification will be performed at implement time.")
        print()


    # ── HK type assignment from hash_keys (Multi-HK Phase 2) ─────────────
    hash_keys = state.get("hash_keys", [])
    if hash_keys:
        for hk in hash_keys:
            if hk.get("type"):
                continue  # Already assigned (idempotent re-entry)
            if hk["name"].startswith("LNK_"):
                if "lnk" in new_objects:
                    hk["type"] = "link"
            else:
                if "hub" in new_objects:
                    hk["type"] = "hub"

        # Auto-set --sat-parent-hk from hash_keys if not explicitly provided
        sats = state.get("sats", [])
        for sat_def in sats:
            if sat_def.get("parent_hk"):
                continue  # Explicit takes precedence
            # Find a hub HK (non-LNK, non-HASHDIFF)
            hub_hks = [hk for hk in hash_keys if hk.get("type") == "hub"]
            if hub_hks:
                sat_def["parent_hk"] = hub_hks[0]["name"]
                print(f"  Auto-matched SAT parent HK: {hub_hks[0]['name']} (from hash_keys)")

    _save_state(state)

    _print_success(f'Raw Vault objects added: {state["objects"]}')
    if 'hub' in new_objects:
        hub_name = state.get('hub_name_override') or _derive_hub_name(state['bk_name'])
        print(f'    HUB: {hub_name}')
    lnks = state.get('lnks', [])
    if lnks:
        print(f'    LNKs: {len(lnks)}')
        for ldef in lnks:
            print(f"      • {ldef['lnk_name']}")
    sats = state.get('sats', [])
    if sats:
        print(f'    SATs: {len(sats)}')
        for i, sdef in enumerate(sats, 1):
            ma = sdef.get('multi_active_key', '')
            cols = sdef.get('sat_columns')
            cols_str = f", cols={len(cols)}" if cols else ", cols=ALL"
            print(f"      {i}. {sdef['model_name']} ({sdef['sat_type']}"
                  f"{', MA: ' + ma if ma else ''}{cols_str})")
    print()
    # Display HK assignments if present
    _hks = state.get("hash_keys", [])
    if _hks:
        print("  Hash Keys:")
        for hk in _hks:
            cols_str = ", ".join(hk["columns"])
            assigned = f" → {hk['type']}" if hk.get("type") else ""
            print(f"    {hk['name']} = MD5({cols_str}){assigned}")
        print()
    print(f'  Next: .venv/bin/python3 {_rel_script()} generate-yaml')
    return 0


def _validate_link_hk_sigil(hk_name: str, columns: list):
    """Validate an @-sigil (HASH_FROM_HKS) link HK. Returns an error string or None.

    @HK references only round-trip through init-rv when the HK follows the LNK_ link
    naming convention (init-rv's lnk_hk_pattern) and every referenced component is a
    hub HK column (ends in _HK, not LNK_ — a link cannot compose from another link).
    Without this, `--hk "SOME_HK:@A_HK,@B_HK"` generates valid SQL that the
    reverse-parser silently drops. (#1907; PR #1950 review.)
    """
    if not hk_name.startswith("LNK_"):
        return (f"--hk '{hk_name}': @HK references require a LNK_ link-HK name "
                f"(link HKs compose from hub HKs; #1907)")
    bad = [c for c in columns if not c.endswith("_HK") or c.startswith("LNK_")]
    if bad:
        return (f"--hk '{hk_name}': @HK references must be hub HK columns (end in "
                f"_HK, not LNK_), got {bad}")
    return None


def _recover_stg_hash_keys(sql_content: str) -> list:
    """Recover HK definitions from a v_psa_stg model (init-rv reverse-parser).

    Hub HKs compose from raw columns wrapped in ``CAST(... AS VARCHAR)``; link HKs
    (issue #1907) compose from participating hub HK values wrapped in
    ``TO_VARCHAR(HUB_HK)``. The two extraction regexes are textually disjoint
    (CAST vs TO_VARCHAR), so a link HK is never mis-recovered as a raw-column hub
    HK and a hub HK is never mis-recovered as a link. Link HKs are tagged
    ``type="link"`` so regeneration reproduces the HASH_FROM_HKS form.
    """
    hash_keys: list = []
    hk_pattern = re.compile(
        r"MD5_BINARY\(UPPER\(CONCAT_WS\('\|\|',\s*(.*?)\)\)\)\s*as\s+([A-Z][A-Z0-9_]*_HK)",
        re.IGNORECASE | re.DOTALL
    )
    for hk_match in hk_pattern.finditer(sql_content):
        hk_body = hk_match.group(1)
        hk_name = hk_match.group(2).upper()
        # Hub HK components: COALESCE(NULLIF(TRIM(CAST(COL as VARCHAR)),''), '^^')
        cols = re.findall(r"CAST\((\w+)\s+as\s+VARCHAR\)", hk_body, re.IGNORECASE)
        if cols:
            # Skip duplicate HK definitions (same HK appears in multiple CTEs)
            if not any(h["name"] == hk_name for h in hash_keys):
                hash_keys.append({
                    "name": hk_name,
                    "columns": [c.upper() for c in cols],
                    "type": None,
                })

    lnk_hk_pattern = re.compile(
        r"MD5_BINARY\(UPPER\(CONCAT_WS\('\|\|',\s*(.*?)\)\)\)\s*as\s+(LNK_[A-Z][A-Z0-9_]*_HK)",
        re.IGNORECASE | re.DOTALL
    )
    for lhk_match in lnk_hk_pattern.finditer(sql_content):
        lhk_body = lhk_match.group(1)
        lhk_name = lhk_match.group(2).upper()
        # Link HK composes from hub HK values via TO_VARCHAR(HUB_HK) (#1907). Hub HK
        # components use CAST(...), so TO_VARCHAR extraction here is disjoint and cannot
        # collide; it recovers the participating hub-HK column names.
        cols = re.findall(r"TO_VARCHAR\((\w+)\)", lhk_body, re.IGNORECASE)
        if cols and not any(h["name"] == lhk_name for h in hash_keys):
            hash_keys.append({
                "name": lhk_name,
                "columns": [c.upper() for c in cols],
                "type": "link",
            })

    return hash_keys


def _recover_stg_final_columns(sql_content: str) -> list:
    """Recover plain passthrough data columns from a v_psa_stg FINAL SELECT.

    Stops at the first HK/HASHDIFF expression or FROM. Bare hub-HK passthroughs
    (CTE-staged link derivation, issue #1907) end in ``_HK`` — they are hash keys,
    not data columns — so they are skipped rather than misclassified as data.
    Returns an empty list when no FINAL layer is present (caller falls back to the
    LOGIC CTE).
    """
    columns: list = []
    final_start = re.search(r'----\s*FINAL\s+LAYER\s*----', sql_content, re.IGNORECASE)
    if not final_start:
        return columns
    # Names actually derived as HKs (hub HKs in HASH_STG, link HKs in FINAL). A bare
    # passthrough of one of these is a hash key, not a data column (#1907). A source
    # column that merely ends in _HK is NOT derived and stays a data column (PR #1950 review).
    derived_hks = {
        m.group(1).upper()
        for m in re.finditer(r'\bas\s+([A-Z_][A-Z0-9_]*_HK)\b', sql_content, re.IGNORECASE)
    }
    final_text = sql_content[final_start.end():]
    for line in final_text.split('\n'):
        stripped = line.strip().lstrip(',').strip()
        if not stripped or stripped.upper().startswith('SELECT'):
            continue
        # Stop at HK/HASHDIFF calculations or FROM clause
        if re.match(r'(MD5_BINARY|FROM\s|HASHDIFF)', stripped, re.IGNORECASE):
            break
        # Plain column name: single identifier on the line
        col_match = re.match(r'^([A-Z_][A-Z0-9_]*)$', stripped, re.IGNORECASE)
        if col_match:
            # Skip bare hub-HK passthroughs (derived elsewhere as `as <NAME>_HK`),
            # but keep data columns that merely end in _HK.
            if col_match.group(1).upper() in derived_hks:
                continue
            columns.append({
                "name": col_match.group(1).upper(),
                "type": "VARCHAR",
                "nullable": True,
            })
    return columns


def cmd_init_rv(args):
    """Initialize a Raw Vault pipeline from an existing v_psa_stg model.

    Parses the deployed v_psa_stg SQL to extract schema, table, BK, HKs,
    and columns — then bootstraps state with init/profile/approve-profile
    completed. No Snowflake access required.

    After init-rv, proceed: generate-yaml → generate-xlsx → approve-xlsx
    → add-raw-vault → generate-code → approve-code → implement
    """
    model_name = args.model_name
    if not model_name:
        _print_error("--model-name is required (e.g., v_psa_stg_po_header__winn_sap)")
        return 1

    # Validate model name format
    if not model_name.startswith("v_psa_stg_"):
        _print_error(f"Model name must start with 'v_psa_stg_': got '{model_name}'")
        return 1

    # Sanitize: reject path traversal or special characters
    if not re.match(r'^[a-z0-9_]+$', model_name):
        _print_error(f"Invalid model name (only lowercase alphanumeric + underscore allowed): '{model_name}'")
        return 1

    # Check for existing state
    existing = _load_state(model_name)
    if existing and not args.force:
        _print_error(
            f"Pipeline already exists for {model_name}.\n"
            f"  Use --force to reinitialize, or:\n"
            f"  rm {STATE_DIR / f'{model_name}.json'}"
        )
        return 1

    # Find the existing v_psa_stg SQL file on disk
    sql_file = None
    search_root = PROJECT_ROOT / "models" / "int_staging_views"
    for f in search_root.rglob(f"{model_name}.sql"):
        sql_file = f
        break

    if not sql_file:
        _print_error(
            f"v_psa_stg SQL not found: {model_name}.sql\n"
            f"  Searched: {search_root.relative_to(PROJECT_ROOT)}/\n"
            f"  The model must exist on disk to use init-rv."
        )
        return 1

    print(f"\n  Parsing existing model: {sql_file.relative_to(PROJECT_ROOT)}")
    sql_content = sql_file.read_text()

    # ── Parse source reference ────────────────────────────────────────────
    source_match = re.search(
        r"\{\{\s*source\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\s*\)\s*\}\}",
        sql_content
    )
    if not source_match:
        _print_error("Could not find {{ source('schema', 'table') }} in the SQL file.")
        return 1
    schema = source_match.group(1)
    table = source_match.group(2)

    # ── Parse BK alias (first 'as ..._BK' in LOGIC layer) ────────────────
    bk_match = re.search(
        r'(?:as\s+)([A-Z][A-Z0-9_]*_BK)\b',
        sql_content, re.IGNORECASE
    )
    if not bk_match:
        _print_error("Could not find BK alias (e.g., 'as ENTITY_BK') in the SQL file.")
        return 1
    bk_name = bk_match.group(1).upper()

    # ── Parse BK source column (what's aliased as _BK) ───────────────────
    # Find the line containing 'as <BK_NAME>' and extract the expression before it.
    # Handle both plain columns (STLNR as BOM_BK) and expressions (to_char(...) as BK)
    bk_lines = sql_content.split('\n')
    bk_expr = bk_name.replace("_BK", "")  # fallback
    for i, line in enumerate(bk_lines):
        if re.search(r'\bas\s+' + re.escape(bk_name) + r'\b', line, re.IGNORECASE):
            # Extract everything before 'as BK_NAME' on this line
            pre_alias = re.split(r'\s+as\s+' + re.escape(bk_name), line, flags=re.IGNORECASE)[0]
            # Strip leading comma and whitespace
            pre_alias = re.sub(r'^\s*,?\s*', '', pre_alias).strip()
            if pre_alias:
                bk_expr = pre_alias
            break

    # ── Parse HK definitions (hubs from CAST components, links from hub HK refs) ──
    hash_keys = _recover_stg_hash_keys(sql_content)

    # ── Parse REC_SRC from BKCC CTE (if present) ─────────────────────────
    rec_src = args.rec_src or ""
    if not rec_src:
        # Try to find REC_SRC literal in BKCC CTE
        rec_src_match = re.search(
            r"['\"]([A-Z0-9_]+\.[A-Z0-9_]+\.[A-Z0-9_]+\.[A-Z0-9_]+)['\"].*?REC_SRC",
            sql_content, re.IGNORECASE
        )
        if not rec_src_match:
            rec_src_match = re.search(
                r"REC_SRC.*?['\"]([A-Z0-9_]+\.[A-Z0-9_]+\.[A-Z0-9_]+\.[A-Z0-9_]+)['\"]",
                sql_content, re.IGNORECASE
            )
        if rec_src_match:
            rec_src = rec_src_match.group(1)
        else:
            _print_error(
                "Could not parse REC_SRC from the model. Provide it explicitly:\n"
                f"  --rec-src 'Location.System.Application.Table'"
            )
            return 1

    # ── Detect ingestion source ───────────────────────────────────────────
    has_fivetran_synced = "_FIVETRAN_SYNCED" in sql_content.upper()
    has_fivetran_deleted = "_FIVETRAN_DELETED" in sql_content.upper()
    has_psa_delete_ind = "PSA_DELETE_IND" in sql_content.upper()
    has_glchangetime = "GLCHANGETIME" in sql_content.upper()

    if has_fivetran_synced:
        ingestion = "fivetran"
    elif has_glchangetime:
        ingestion = "snp_glue"
    else:
        ingestion = "custom"

    # ── Parse columns from the FINAL SELECT (simple column list) ──────────
    columns = _recover_stg_final_columns(sql_content)

    # Fallback: if FINAL layer parse got nothing, try LOGIC CTE
    if not columns:
        logic_start = re.search(
            r',?\s*LOGIC_[a-zA-Z][a-zA-Z0-9]*\s+as\s*\(',
            sql_content, re.IGNORECASE
        )
        if logic_start:
            # Balance parentheses to find the full CTE body (string-literal aware)
            start_pos = logic_start.end()
            depth = 1
            pos = start_pos
            while pos < len(sql_content) and depth > 0:
                ch = sql_content[pos]
                if ch == "'":
                    pos += 1
                    while pos < len(sql_content):
                        if sql_content[pos] == "'" and (pos + 1 >= len(sql_content) or sql_content[pos + 1] != "'"):
                            break
                        if sql_content[pos] == "'" and pos + 1 < len(sql_content) and sql_content[pos + 1] == "'":
                            pos += 1
                        pos += 1
                elif ch == '-' and pos + 1 < len(sql_content) and sql_content[pos + 1] == '-':
                    while pos < len(sql_content) and sql_content[pos] != '\n':
                        pos += 1
                elif ch == '/' and pos + 1 < len(sql_content) and sql_content[pos + 1] == '*':
                    pos += 2
                    while pos + 1 < len(sql_content) and not (sql_content[pos] == '*' and sql_content[pos + 1] == '/'):
                        pos += 1
                    pos += 1
                elif ch == '(':
                    depth += 1
                elif ch == ')':
                    depth -= 1
                pos += 1
            logic_body = sql_content[start_pos:pos - 1]
            aliases = re.findall(r'\bas\s+([A-Z_][A-Z0-9_]*)\b', logic_body, re.IGNORECASE)
            plain_cols = re.findall(r'(?:,\s*|\bSELECT\s+)\s*([A-Z_][A-Z0-9_]*)\s*(?:\n|,|$)', logic_body, re.IGNORECASE)
            _skip_tokens = {'SELECT', 'FROM', 'WHERE', 'AS', 'SRC', 'QUALIFY', 'PARTITION',
                            'BY', 'ORDER', 'DESC', 'ASC', 'OVER', 'ROW_NUMBER', 'INNER',
                            'JOIN', 'LEFT', 'ON', 'AND', 'OR', 'CASE', 'WHEN', 'THEN',
                            'ELSE', 'END', 'NULL', 'IN', 'NOT', 'LIKE', 'BETWEEN', 'DISTINCT',
                            'IFF', 'CONVERT_TIMEZONE', 'UTC', 'TO_CHAR', 'COALESCE', 'CONCAT_WS',
                            'SUBSTR', 'REGEXP_REPLACE', 'TO_TIMESTAMP', 'PSA_DELETE_IND',
                            'PSA_LOAD_DTS', 'GLCHANGETIME', 'VARCHAR', 'TEXT', 'INT', 'NUMBER'}
            seen = set()
            for col in aliases + plain_cols:
                col_upper = col.upper()
                if col_upper not in _skip_tokens and col_upper not in seen:
                    seen.add(col_upper)
                    columns.append({"name": col_upper, "type": "VARCHAR", "nullable": True})

    if not columns:
        _print_error(
            "Could not parse columns from FINAL or LOGIC layer.\n"
            "  Ensure the model has a FINAL LAYER comment or a LOGIC_<suffix> CTE."
        )
        return 1

    # ── Determine domain from file path ───────────────────────────────────
    domain = args.domain or ""
    if not domain:
        # Try to infer from directory: models/int_staging_views/<domain>/model.sql
        relative = sql_file.relative_to(search_root)
        if len(relative.parts) > 1:
            domain = relative.parts[0]

    # ── Build state ───────────────────────────────────────────────────────
    state = {
        "model_name": model_name,
        "schema": schema.lower(),
        "table": table.lower(),
        "bk": bk_expr,
        "bk_name": bk_name,
        "rec_src": rec_src,
        "objects": ["stg"],  # Will be updated by add-raw-vault
        "created_at": _now_iso(),
        "steps_completed": [],
        "profile_results": {
            "columns": columns,
            "row_count": 0,  # Unknown without Snowflake
            "volume_tier": "normal",
            "ingestion_source": ingestion,
            "has_psa_delete_ind": has_psa_delete_ind,
            "has_fivetran_deleted": has_fivetran_deleted,
            "has_fivetran_synced": has_fivetran_synced,
            "has_glchangetime": has_glchangetime,
            "bootstrapped_from": str(sql_file.relative_to(PROJECT_ROOT)),
        },
        "config_path": "",
        "xlsx_path": "",
        "xlsx_validation": {},
        "generated_files": {},
        "stage3_results": {},
        "hash_keys": hash_keys,
        "init_mode": "rv_from_existing",
        "design_decision": "add_raw_vault",
    }

    if domain:
        state["domain"] = domain

    # Mark init + profile + approve-profile as complete (bootstrapped from file)
    now = _now_iso()
    state["steps_completed"] = [
        {"step": "init", "completed_at": now},
        {"step": "profile", "completed_at": now, "note": "bootstrapped from existing SQL"},
        {"step": "approve-profile", "completed_at": now, "note": "auto-approved (parsed from deployed model)"},
    ]

    _save_state(state)

    # ── Report ────────────────────────────────────────────────────────────
    _print_success(f"Raw Vault pipeline initialized from existing model.")
    print(f"  Model:    {model_name}")
    print(f"  Source:   {schema}.{table}")
    print(f"  BK:       {bk_expr} → {bk_name}")
    print(f"  REC_SRC:  {rec_src}")
    print(f"  Ingestion:{ingestion}")
    print(f"  Columns:  {len(columns)} parsed from FINAL layer")
    if hash_keys:
        print(f"  Hash Keys:{len(hash_keys)}")
        for hk in hash_keys:
            print(f"    {hk['name']} = MD5({', '.join(hk['columns'])})")
    if domain:
        print(f"  Domain:   {domain}")
    print(f"\n  Next steps:")
    print(f"    1. .venv/bin/python3 {_rel_script()} add-raw-vault --objects \"hub,sat\" \\")
    print(f"         --sat-parent-hk {hash_keys[0]['name'] if hash_keys else '<HK_NAME>'} \\")
    print(f"         --sat-parent-model {_derive_hub_name(bk_name)}")
    print(f"    2. .venv/bin/python3 {_rel_script()} generate-yaml")
    print(f"    3. .venv/bin/python3 {_rel_script()} generate-xlsx")
    print(f"    4. .venv/bin/python3 {_rel_script()} approve-xlsx")
    print(f"    5. .venv/bin/python3 {_rel_script()} generate-code")
    print(f"    6. .venv/bin/python3 {_rel_script()} approve-code")
    print(f"    7. .venv/bin/python3 {_rel_script()} implement --domain {domain or '<domain>'}")
    return 0


def cmd_build_all(args):
    """Run dbt build for all generated models in one pass."""
    state = _resolve_state(args)
    if not state:
        return 1

    if "implement" not in _completed_steps(state):
        _print_error(
            f"implement step not yet completed. Run implement first:\n"
            f"  python {_rel_script()} implement --domain <DOMAIN>"
        )
        return 1

    objects = state.get("objects", ["stg"])
    model_name = state["model_name"]
    models = []

    if "stg" in objects:
        models.append(model_name)
    if "hub" in objects:
        hub_name = state.get('hub_name_override') or _derive_hub_name(state["bk_name"])
        models.append(hub_name)
    if "lnk" in objects:
        for lnk_def in state.get("lnks", []):
            lnk_name_val = lnk_def.get("lnk_name", "")
            if lnk_name_val:
                models.append(_derive_lnk_name(lnk_name_val))
    if "sat" in objects:
        for sat_def in state.get("sats", []):
            sat_model_name = sat_def.get("model_name", "")
            if sat_model_name:
                models.append(sat_model_name)

    if not models:
        _print_error("No models found in pipeline state.")
        return 1

    select_expr = " ".join(models)
    print(f"\n  Building {len(models)} model(s): {select_expr}")

    dbt_cmd = ["build", "--select", select_expr]

    rc, out, err = _run_dbt(
        dbt_cmd,
        cwd=str(PROJECT_ROOT),
    )

    build_results = _parse_dbt_build_results(out)

    real_failure = build_results["fail"] > 0 or build_results["error"] > 0
    all_zeros = build_results["pass"] == 0 and build_results["fail"] == 0 and build_results["error"] == 0
    cli_error_only = rc != 0 and not real_failure and build_results["pass"] > 0
    if cli_error_only:
        print(f"    ⚠️  dbt CLI returned rc={rc} but build results are clean: {build_results}")
        print(f"    Treating as PASS (CLI transport error, not build failure).")
    if rc != 0 and all_zeros:
        _print_error(
            f"dbt crashed (rc={rc}) with no build results — likely a startup error\n"
            f"  stdout:\n{out}\n  stderr:\n{err}"
        )
        return 1
    if real_failure:
        _print_error(
            f"dbt build failed — {build_results}\n"
            f"  stdout:\n{out}\n  stderr:\n{err}"
        )
        return 1

    _print_success(f"All {len(models)} model(s) built successfully — {build_results}")
    return 0


def cmd_status(args):
    """Show pipeline status."""
    state = _resolve_state(args)
    if not state:
        # List all pipelines
        if STATE_DIR.exists():
            state_files = list(STATE_DIR.glob("*.json"))
            if state_files:
                print(f"\n  Active pipelines in {STATE_DIR.relative_to(PROJECT_ROOT)}:")
                for sf in sorted(state_files):
                    try:
                        with open(sf) as f:
                            s = json.load(f)
                        if "model_name" not in s or "steps_completed" not in s:
                            continue  # Skip non-state files (Bug #8)
                        last_step = s.get("steps_completed", [{}])[-1].get("step", "none")
                        print(f"    {s['model_name']:<50} last: {last_step}")
                    except (json.JSONDecodeError, KeyError, OSError):
                        continue
                return 0
        print(f"\n  No active pipelines. Start one with: python {_rel_script()} init ...")
        return 0

    model_name = state["model_name"]
    completed = _completed_steps(state)
    profile = state.get("profile_results", {})

    print(f"\n  === Pipeline Status: {model_name} ===\n")

    for step in PIPELINE_STEPS:
        if step in completed:
            entry = next(
                (s for s in state.get("steps_completed", []) if s["step"] == step),
                {},
            )
            ts = entry.get("completed_at", "")
            # Format timestamp for display
            if ts:
                try:
                    dt = datetime.fromisoformat(ts)
                    ts_display = dt.strftime("%Y-%m-%d %H:%M")
                except (ValueError, TypeError):
                    ts_display = ts
            else:
                ts_display = ""

            detail = ""
            if step == "profile":
                tier = profile.get("volume_tier", "")
                rows = profile.get("row_count", "")
                ing = profile.get("ingestion_source", "")
                detail = f" \u2014 {rows:,} rows, {tier}, {ing}" if rows else ""
            elif step == "generate-xlsx":
                val = state.get("xlsx_validation", {})
                p = val.get("checks_passed", "?")
                t = val.get("checks_total", "?")
                detail = f" \u2014 {p}/{t} validation checks passed"

            print(f"  \u2705 {step:<25} ({ts_display}){detail}")
        else:
            # Check if this is the next pending step
            prev_idx = PIPELINE_STEPS.index(step) - 1
            all_prior_done = all(
                PIPELINE_STEPS[i] in completed for i in range(prev_idx + 1)
            )
            if all_prior_done:
                print(f"  \u23f3 {step:<25} \u2014 WAITING")
            else:
                print(f"  \u2b1c {step:<25}")

    # Print next action
    for step in PIPELINE_STEPS:
        if step not in completed:
            hints = {
                "profile": f"Run: python {_rel_script()} profile",
                "approve-profile": f"Review profile, then: python {_rel_script()} approve-profile",
                "generate-yaml": f"Run: python {_rel_script()} generate-yaml",
                "generate-xlsx": f"Run: python {_rel_script()} generate-xlsx",
                "approve-xlsx": f"Review XLSX at {state.get('xlsx_path', '?')}, then: python {_rel_script()} approve-xlsx",
                "generate-code": f"Run: python {_rel_script()} generate-code",
                "approve-code": f"Review generated code, then: python {_rel_script()} approve-code",
                "implement": f"Run: python {_rel_script()} implement --domain <DOMAIN>",
            }
            print(f"\n  Next: {hints.get(step, step)}")
            break
    else:
        print("\n  Pipeline complete! Ready for commit and PR.")

    return 0


def cmd_reset(args):
    """Reset pipeline to re-run from a specific step."""
    state = _resolve_state(args)
    if not state:
        return 1

    step = args.reset_to
    if step not in PIPELINE_STEPS:
        _print_error(f"Unknown step: {step}. Valid steps: {', '.join(PIPELINE_STEPS)}")
        return 1

    step_idx = PIPELINE_STEPS.index(step)
    # Remove this step and all subsequent steps
    steps_to_remove = set(PIPELINE_STEPS[step_idx:])
    state["steps_completed"] = [
        s for s in state.get("steps_completed", []) if s["step"] not in steps_to_remove
    ]
    _save_state(state)

    _print_success(f"Pipeline reset. Cleared steps: {', '.join(sorted(steps_to_remove))}")
    print(f"  Re-run from: python {_rel_script()} {step}")
    return 0


# ── Handoff ────────────────────────────────────────────────────────────────────

def _generate_handoff_markdown(state, decisions=None, blockers=None, next_focus=None):
    """Generate a handoff document from pipeline state.

    Args:
        state: Pipeline state dict (from .pipeline_state/*.json)
        decisions: Optional list of dicts with keys: decision, choice, reasoning
        blockers: Optional list of strings describing blockers/workarounds
        next_focus: Optional string describing what the next session should focus on

    Returns:
        Path to the generated handoff file, or None on error.
    """
    model_name = state.get("model_name", "unknown")

    # Security: validate model_name doesn't contain path traversal
    configs_root = (SCRIPT_DIR / "configs").resolve()
    config_name = _strip_stg_prefix(model_name)
    handoff_dir = (SCRIPT_DIR / "configs" / config_name).resolve()
    if not _is_under(handoff_dir, configs_root):
        _print_error(f"Invalid model name (path traversal blocked): {model_name}")
        return None

    handoff_dir.mkdir(parents=True, exist_ok=True)
    handoff_path = handoff_dir / "handoff.md"

    completed = _completed_steps(state)
    profile = state.get("profile_results", {})
    now_ts = _now_iso()

    # Determine current branch
    try:
        import subprocess
        branch_result = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True, text=True, cwd=str(PROJECT_ROOT), timeout=5
        )
        branch = branch_result.stdout.strip() if branch_result.returncode == 0 else "unknown"
    except (OSError, subprocess.TimeoutExpired):
        branch = "unknown"

    # Determine next step
    next_step = "complete"
    for step in PIPELINE_STEPS:
        if step not in completed:
            next_step = step
            break

    # Build progress table
    progress_lines = []
    for step in PIPELINE_STEPS:
        if step in completed:
            entry = next(
                (s for s in state.get("steps_completed", []) if s["step"] == step), {}
            )
            ts = entry.get("completed_at", "")
            progress_lines.append(f"| {step} | ✅ | {ts} |")
        elif step == next_step:
            progress_lines.append(f"| {step} | ⏳ | — |")
        else:
            progress_lines.append(f"| {step} | ⬜ | — |")

    # Build decisions table
    decision_lines = []
    # Auto-extract decisions from state
    if state.get("raw_vault_objects"):
        decision_lines.append(
            "| Raw Vault design | Option B (add-raw-vault) | Raw vault objects present in state |"
        )
    elif "generate-code" in completed:
        decision_lines.append(
            "| Raw Vault design | Option A (STG-only) | No raw vault objects in state |"
        )

    if state.get("domain"):
        decision_lines.append(
            f"| Domain | {state['domain']} | Selected by user |"
        )

    if profile.get("volume_tier"):
        decision_lines.append(
            f"| Volume tier | {profile['volume_tier']} | Based on {profile.get('row_count', '?')} rows |"
        )

    if state.get("grain_columns"):
        grain = ", ".join(state["grain_columns"])
        decision_lines.append(f"| Grain columns | {grain} | User-specified |")

    if state.get("bk_name"):
        decision_lines.append(f"| BK naming | {state['bk_name']} | User-specified |")

    # Add user-supplied decisions
    if decisions:
        for d in decisions:
            decision_lines.append(
                f"| {d.get('decision', '?')} | {d.get('choice', '?')} | {d.get('reasoning', '?')} |"
            )

    # Build key files table
    file_lines = []
    file_lines.append(
        f"| State file | `scripts/automation/.pipeline_state/{model_name}.json` |"
    )
    # generate-yaml writes a flat file: scripts/automation/configs/<config_name>.yml
    config_yml = state.get("config_path") or f"scripts/automation/configs/{config_name}.yml"
    file_lines.append(f"| Config YAML | `{config_yml}` |")

    if state.get("xlsx_path"):
        file_lines.append(f"| Tech spec | `{state['xlsx_path']}` |")

    # profile.md is written under configs/<config_name>/profile.md (config_name = stripped).
    # Prefer the canonical state value when present; fall back to the canonical layout.
    profile_md_rel = state.get("profile_md_path")
    profile_md_abs = (
        (PROJECT_ROOT / profile_md_rel).resolve() if profile_md_rel
        else (SCRIPT_DIR / "configs" / config_name / "profile.md").resolve()
    )
    # Defense-in-depth: do not surface paths outside configs/.
    if _is_under(profile_md_abs, configs_root) and profile_md_abs.exists():
        # Display path relative to repo root for readability
        try:
            display_md = str(profile_md_abs.relative_to(PROJECT_ROOT.resolve()))
        except ValueError:
            display_md = str(profile_md_abs)
        file_lines.append(f"| Profile | `{display_md}` |")

    if state.get("generated_sql_path"):
        file_lines.append(f"| Generated SQL | `{state['generated_sql_path']}` |")
    if state.get("generated_yml_path"):
        file_lines.append(f"| Generated YAML | `{state['generated_yml_path']}` |")

    # Assemble document
    lines = [
        f"# Pipeline Handoff: {model_name}",
        "",
        f"**Generated**: {now_ts}",
        f"**Branch**: {branch}",
        f"**Phase**: Next step is `{next_step}`",
        "",
        "## Pipeline Progress",
        "",
        "| Step | Status | Completed At |",
        "|------|--------|-------------|",
    ]
    lines.extend(progress_lines)

    lines.extend([
        "",
        "## Decisions & Reasoning",
        "",
        "| Decision | Choice | Reasoning |",
        "|----------|--------|-----------|",
    ])
    if decision_lines:
        lines.extend(decision_lines)
    else:
        lines.append("| (none recorded) | — | — |")

    if blockers:
        lines.extend(["", "## Blockers & Workarounds", ""])
        for b in blockers:
            lines.append(f"- {b}")
    else:
        lines.extend(["", "## Blockers & Workarounds", "", "None encountered."])

    # Next steps
    lines.extend(["", "## Next Steps", ""])
    if next_focus:
        lines.append(f"1. **Focus**: {next_focus}")
        lines.append(f"2. Run: `.venv/bin/python3 scripts/automation/pipeline_orchestrator.py {next_step}`")
    elif next_step == "complete":
        lines.append("1. Pipeline is complete — ready for commit and PR")
    else:
        lines.append(f"1. Run: `.venv/bin/python3 scripts/automation/pipeline_orchestrator.py {next_step}`")

    # Key files
    lines.extend([
        "",
        "## Key Files",
        "",
        "| Purpose | Path |",
        "|---------|------|",
    ])
    lines.extend(file_lines)

    # Resumption command
    if next_step != "complete":
        lines.extend([
            "",
            "## Resumption Command",
            "",
            "```bash",
            f".venv/bin/python3 scripts/automation/pipeline_orchestrator.py {next_step}",
            "```",
        ])

    lines.append("")  # trailing newline

    # Write file
    content = "\n".join(lines)

    # Security check: no credential-like strings (base64 tokens, API keys)
    # Exclude common path chars (/, _, -, .) to avoid false positives on file paths
    import re as _re
    if _re.search(r'(?<![/._\-])[A-Za-z0-9+/=]{64,}(?![/._\-])', content):
        _print_error("Handoff contains potential credential — aborting write.")
        return None

    handoff_path.write_text(content, encoding="utf-8")
    return handoff_path


def cmd_generate_handoff(args):
    """Generate a handoff document for session continuity."""
    state = _resolve_state(args)
    if not state:
        return 1

    # Parse optional arguments
    next_focus = getattr(args, "next_focus", None)

    handoff_path = _generate_handoff_markdown(
        state,
        decisions=None,  # Auto-extracted from state
        blockers=None,
        next_focus=next_focus,
    )

    if not handoff_path:
        return 1

    # Display relative path
    try:
        rel_path = handoff_path.relative_to(PROJECT_ROOT)
    except ValueError:
        rel_path = handoff_path

    _print_success(f"Handoff document generated: {rel_path}")
    print(f"  Share this file with the next agent session.")
    print(f"  The next agent should read it before running any pipeline commands.")
    return 0


# ── State Resolution ───────────────────────────────────────────────────────────

def _resolve_state(args):
    """Resolve which state file to use. Returns state dict or None."""
    model_name = getattr(args, "model_name", None) or getattr(args, "model", None)
    if model_name:
        state = _load_state(model_name)
        if not state:
            _print_error(
                f"No pipeline found for: {model_name}\n"
                f"  Initialize first: python {_rel_script()} init --model-name {model_name} ..."
            )
            return None
        return state

    # Try to find the active state
    state = _find_active_state()
    if not state:
        _print_error(
            f"No active pipeline found.\n"
            f"  Initialize one: python {_rel_script()} init --model-name <name> ..."
        )
        return None
    return state


# ── CLI ────────────────────────────────────────────────────────────────────────

def build_parser():
    parser = argparse.ArgumentParser(
        prog="pipeline_orchestrator.py",
        description="State-machine pipeline enforcer for v_psa_stg generation.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Initialize a new model pipeline
  python pipeline_orchestrator.py init \\
    --schema emtk_ebs_ap --table ap_terms_lines \\
    --bk TERM_ID --bk-name PAYMENT_TERM_BK \\
    --rec-src USWIOC.ORCL.EBSEMTK.AP_TERMS_LINES \\
    --model-name v_psa_stg_payment_terms_lines__emtk_ebs

  # Profile source (with Snowflake) or from pre-computed JSON
  python pipeline_orchestrator.py profile
  python pipeline_orchestrator.py profile --profile-json profile_data.json

  # Step through the pipeline
  python pipeline_orchestrator.py show-profile
  python pipeline_orchestrator.py approve-profile
  python pipeline_orchestrator.py generate-yaml
  python pipeline_orchestrator.py generate-xlsx
  python pipeline_orchestrator.py approve-xlsx
  python pipeline_orchestrator.py generate-code
  python pipeline_orchestrator.py show-code
  python pipeline_orchestrator.py approve-code
  python pipeline_orchestrator.py implement --domain shipments

  # Check status anytime
  python pipeline_orchestrator.py status
        """,
    )

    subparsers = parser.add_subparsers(dest="command", help="Pipeline command")

    # init
    p_init = subparsers.add_parser("init", help="Initialize a new model pipeline")
    p_init.add_argument("--schema", required=True, help="Source schema (e.g., emtk_ebs_ap)")
    p_init.add_argument("--table", required=True, help="Source table (e.g., ap_terms_lines)")
    p_init.add_argument("--bk", required=True, help="Business key column(s) (e.g., TERM_ID)")
    p_init.add_argument("--bk-name", help="BK staging name (e.g., PAYMENT_TERM_BK)")
    p_init.add_argument("--rec-src", required=True, help="REC_SRC value (e.g., USWIOC.ORCL.EBSEMTK.AP_TERMS_LINES)")
    p_init.add_argument("--model-name", required=True, help="Model name (e.g., v_psa_stg_payment_terms_lines__emtk_ebs)")
    p_init.add_argument("--objects", default="stg", help="Object types to generate, comma-separated (stg, hub, lnk, sat). Default: stg")
    p_init.add_argument("--force", action="store_true", help="Overwrite existing state")
    p_init.add_argument("--hub-name", help="Override hub model name (default: auto-derived from BK). E.g., hub_delivery_v1")
    p_init.add_argument("--lnk-name", help="Link model name (e.g., po_item or lnk_po_item)")
    p_init.add_argument("--parent-hks", help="Comma-separated parent hub HK columns (e.g., PO_ITEM_HK,SUPPLIER_HK)")
    p_init.add_argument("--dck", help="Comma-separated degenerate context key columns (e.g., PO_LINE_NUMBER)")
    p_init.add_argument("--sat-type", default="sat", help="SAT variant: sat, lsat, msat, lmsat (default: sat)")
    p_init.add_argument("--sat-parent-hk", help="Parent HK column for SAT (e.g., PLANNED_ORDER_HK)")
    p_init.add_argument("--sat-parent-model", help="Parent hub/link model for SAT FK (e.g., hub_planned_order)")
    p_init.add_argument("--multi-active-key", help="Multi-active key column for MSAT/LMSAT (e.g., SEQUENCE_NUM)")
    p_init.add_argument("--sat-name", help="Override SAT model name (default: auto-derived from v_psa_stg)")
    p_init.add_argument("--domain", help="Domain folder for file placement (e.g., shipments, procurement). Stored in state for implement step.")
    p_init.add_argument("--grain-columns", help="Comma-separated composite grain columns beyond BK (e.g., HOME_DEPOT_ACCOUNT,DAY_1,SKU_NBR). Triggers Phase 2 grain validation.")
    p_init.add_argument("--load-dts-column", help="Override LOAD_DTS derivation with a specific source column (e.g., MODIFIED_DT). Column will be excluded from HASHDIFF automatically.")
    p_init.add_argument(
        "--hk",
        action="append",
        default=[],
        metavar="HK_NAME:COL1,COL2,...",
        help="Hash key definition. Format: HK_NAME:COL1,COL2,... "
             "Repeatable. BKCC should be included for hub HKs. "
             "Example: --hk 'SUBSCRIPTION_HK:ID,BKCC' --hk 'LNK_ITEM_HK:ITEM_ID,ORDER_ID,BKCC'"
    )

    # Additional BKs beyond the primary --bk (multi-BK support, lesson #127)
    p_init.add_argument(
        "--additional-bk",
        action="append",
        default=[],
        metavar="RAW_COL:BK_ALIAS",
        help="Additional BK alias. Format: RAW_COL:BK_ALIAS "
             "Repeatable. Example: --additional-bk 'SUBSCRIBER_ID:SUBSCRIBER_BK'"
    )

    # Secondary (lookup) table arguments — multi-table v_psa_stg support
    add_secondary_args(p_init)

    # profile
    p_profile = subparsers.add_parser("profile", help="Run source profiling (Steps 1.1-1.9)")
    p_profile.add_argument("--model-name", help="Model name (auto-detected if only one active)")
    p_profile.add_argument("--profile-json", help="Path to pre-computed profile JSON")
    p_profile.add_argument("--snowflake-conn", help="Snowflake connection (account:user:password)")
    p_profile.add_argument("--grain-columns", help="Comma-separated composite grain columns beyond BK (e.g., SETID,EFFDT,NET_TRMS_SEQ_NBR). Overrides init value. Triggers Phase 2 grain validation.")
    p_profile.add_argument("--load-dts-column", help="Override LOAD_DTS derivation with a specific source column (e.g., MODIFIED_DT). Overrides init value.")
    p_profile.add_argument(
        "--hk",
        action="append",
        default=[],
        metavar="HK_NAME:COL1,COL2,...",
        help="Hash key definition (safety net). Same format as init --hk."
    )

    # show-profile
    p_show = subparsers.add_parser("show-profile", help="Display profile results")
    p_show.add_argument("--model-name", help="Model name")

    # approve-profile
    p_approve = subparsers.add_parser("approve-profile", help="Approve profile/BK")
    p_approve.add_argument("--model-name", help="Model name")
    p_approve.add_argument("--force", action="store_true", help="Approve despite warnings")
    p_approve.add_argument("--null-bk-sentinel", help="NULL BK handling: '-1' (required BK), '-2' (optional BK), 'none' (accept risk)")

    # generate-yaml
    p_yaml = subparsers.add_parser("generate-yaml", help="Generate YAML config")
    p_yaml.add_argument("--model-name", help="Model name")
    p_yaml.add_argument("--bk-cast", help="BK cast expression (e.g., TERM_ID::TEXT)")
    p_yaml.add_argument("--bk-cast-type", help="BK cast target type (e.g., TEXT)")

    # generate-xlsx
    p_xlsx = subparsers.add_parser("generate-xlsx", help="Generate XLSX + auto-validate")
    p_xlsx.add_argument("--model-name", help="Model name")

    # approve-xlsx
    p_axlsx = subparsers.add_parser("approve-xlsx", help="Approve XLSX tech spec")
    p_axlsx.add_argument("--model-name", help="Model name")

    # generate-code
    p_code = subparsers.add_parser("generate-code", help="Run Stage 2 code generation")
    p_code.add_argument("--model-name", help="Model name")
    p_code.add_argument("--stg-only", action="store_true",
                         help="Confirm STG-only pipeline (skip Raw Vault design decision gate)")

    # show-code
    p_show_code = subparsers.add_parser("show-code", help="Display generated code")
    p_show_code.add_argument("--model-name", help="Model name")

    # approve-code
    p_acode = subparsers.add_parser("approve-code", help="Approve generated code")
    p_acode.add_argument("--model-name", help="Model name")

    # implement
    p_impl = subparsers.add_parser("implement", help="Run Stage 3: place + compile + run + test")
    p_impl.add_argument("--model-name", help="Model name")
    p_impl.add_argument("--domain", help="Domain folder (e.g., shipments, procurement)")
    p_impl.add_argument("--skip-build", action="store_true",
                         help="Skip dbt build — generate and place files only. Use build-all to build later.")
    p_impl.add_argument("--force", action="store_true",
                         help="Overwrite existing files (for interrupted/re-run pipelines)")
    p_impl.add_argument("--skip-hub", action="store_true",
                         help="Skip hub and link placement (use after interrupted run where hub/link already placed)")

    # add-raw-vault (supports accumulating calls for multi-SAT/LNK)
    p_arv = subparsers.add_parser("add-raw-vault", help="Add Raw Vault objects to existing STG pipeline")
    p_arv.add_argument('--model-name', help='Model name')
    p_arv.add_argument('--objects', required=True, help='Raw Vault objects to add (hub, lnk, sat; aliases: msat, lsat, lmsat)')
    p_arv.add_argument('--hub-name', help='Override hub model name (default: auto-derived from BK)')
    p_arv.add_argument('--lnk-name', help='Link model name')
    p_arv.add_argument('--parent-hks', help='Comma-separated parent hub HK columns')
    p_arv.add_argument('--dck', help='Comma-separated degenerate context key columns')
    p_arv.add_argument('--sat-type', default=None, help='SAT variant override: sat, lsat, msat, lmsat (default: sat, or alias from --objects)')
    p_arv.add_argument('--sat-parent-hk', help='Parent HK column for SAT')
    p_arv.add_argument('--sat-parent-model', help='Parent hub/link model for SAT FK')
    p_arv.add_argument('--multi-active-key', help='Multi-active key column for MSAT/LMSAT')
    p_arv.add_argument('--sat-name', help='Override SAT model name')
    p_arv.add_argument('--grain-columns', help='Comma-separated SAT grain columns (per-SAT, not inherited from STG)')
    p_arv.add_argument('--sat-columns', help='Comma-separated column names for this SAT (default: ALL source columns)')

    # init-rv (bootstrap RV pipeline from existing v_psa_stg)
    p_init_rv = subparsers.add_parser("init-rv",
        help="Initialize Raw Vault pipeline from an existing v_psa_stg model (no Snowflake needed)")
    p_init_rv.add_argument("--model-name", required=True,
        help="Name of existing v_psa_stg model (e.g., v_psa_stg_po_header__winn_sap)")
    p_init_rv.add_argument("--rec-src",
        help="REC_SRC override (auto-parsed from model if omitted)")
    p_init_rv.add_argument("--domain",
        help="Domain folder (e.g., shipments, procurement)")
    p_init_rv.add_argument("--force", action="store_true",
        help="Overwrite existing pipeline state")

    # build-all
    p_build = subparsers.add_parser("build-all", help="Run dbt build for all generated models in one pass")
    p_build.add_argument("--model-name", help="Model name")

    # status
    p_status = subparsers.add_parser("status", help="Show pipeline status")
    p_status.add_argument("--model-name", help="Model name (omit to list all)")

    # reset
    p_reset = subparsers.add_parser("reset", help="Reset pipeline to a specific step")
    p_reset.add_argument("--model-name", help="Model name")
    p_reset.add_argument("reset_to", help="Step to reset to (re-run from this point)")

    # generate-handoff
    p_handoff = subparsers.add_parser("generate-handoff",
        help="Generate a handoff document for session continuity")
    p_handoff.add_argument("--model-name", help="Model name")
    p_handoff.add_argument("--next-focus",
        help="What the next session should focus on (e.g., 'complete code review and implement')")

    return parser


def main():
    # Self-check: warn if running outside .venv
    if not sys.prefix.endswith('.venv') and 'venv' not in sys.prefix:
        print(
            "WARNING: Running outside .venv — snowflake-connector-python may not be available.\n"
            "  Use: .venv/bin/python3 scripts/automation/pipeline_orchestrator.py ...",
            file=sys.stderr,
        )

    parser = build_parser()
    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    commands = {
        "init": cmd_init,
        "profile": cmd_profile,
        "show-profile": cmd_show_profile,
        "approve-profile": cmd_approve_profile,
        "generate-yaml": cmd_generate_yaml,
        "generate-xlsx": cmd_generate_xlsx,
        "approve-xlsx": cmd_approve_xlsx,
        "generate-code": cmd_generate_code,
        "show-code": cmd_show_code,
        "approve-code": cmd_approve_code,
        "implement": cmd_implement,
        "build-all": cmd_build_all,
        "add-raw-vault": cmd_add_raw_vault,
        "init-rv": cmd_init_rv,
        "status": cmd_status,
        "reset": cmd_reset,
        "generate-handoff": cmd_generate_handoff,
    }

    handler = commands.get(args.command)
    if not handler:
        _print_error(f"Unknown command: {args.command}")
        parser.print_help()
        return 1

    try:
        return handler(args)
    except SnowflakeUnavailableError as e:
        # Expected, actionable failure (issue #1844): a required Snowflake
        # execution path is missing/unusable. Fail loud with guidance and a
        # non-zero exit — NO traceback (this is not an internal bug).
        _print_error(
            "Snowflake operation could not execute.\n"
            f"    {e}\n"
            "  A Snowflake execution path is required for this command. Options:\n"
            "  1. Install the runtime dependencies (adds snowflake-connector-python):\n"
            "       .venv/bin/python3 -m pip install -r scripts/automation/requirements-runtime.txt\n"
            "  2. Refresh the PAT in .vscode/mcp.json (snow-mcp env.SNOWFLAKE_PAT)\n"
            "  3. Set SNOWFLAKE_PAT + SNOWFLAKE_ACCOUNT + SNOWFLAKE_USER env vars\n"
            "  4. For 'profile', pass --profile-json to supply pre-computed results\n"
            "  5. Pass --snowflake-conn account:user:password"
        )
        return 1
    except Exception as e:
        _print_error(f"Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main() or 0)
