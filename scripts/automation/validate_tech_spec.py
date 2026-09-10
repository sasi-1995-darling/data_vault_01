"""
validate_tech_spec.py — Post-generation validation for XLSX tech specs.

Validates that a generated XLSX tech spec conforms to DV 2.x standards:
- BK row exists with correct staging name and manual_logic
- Raw source column retained alongside BK when cast is applied
- HK uses raw source column name (not BK alias)
- All grain columns have unique: "yes"
- LOAD_DTS derivation matches ingestion source
- HASHDIFF excludes metadata columns, includes data flags
- Column count matches YAML (no dropped columns)
- Column ordering: BK → HK → data → technical → BKCC → REC_SRC → LOAD_DTS → HASHDIFF

Usage:
    python scripts/automation/validate_tech_spec.py \\
        --config scripts/automation/configs/<entity>__<source>.yml \\
        --xlsx scripts/automation/mappings/<entity>__<source>.xlsx

Can also be called programmatically after generate_tech_spec.py.
"""

import argparse
import re
import sys
from pathlib import Path

import openpyxl
import yaml

# Shared source_column helpers (single source of truth — src/source_column_utils.py)
sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))
from source_column_utils import get_source_columns, source_columns_to_str  # noqa: E402


class ValidationError:
    """A single validation finding."""

    def __init__(self, severity, rule, message):
        self.severity = severity  # "ERROR" or "WARN"
        self.rule = rule
        self.message = message

    def __str__(self):
        return f"[{self.severity}] {self.rule}: {self.message}"


class TechSpecValidator:
    """Validates an XLSX tech spec against its YAML config."""

    def __init__(self, config, xlsx_path):
        self.config = config
        self.metadata = config.get("_pipeline_metadata", {})
        self.wb = openpyxl.load_workbook(xlsx_path, read_only=True)
        self.errors = []

    def validate(self):
        """Run all validation checks. Returns list of ValidationError."""
        for model in self.config.get("models", []):
            layer = model.get("layer", "")
            if layer == "STG":
                self._validate_stg_model(model)
            elif layer == "HUB":
                self._validate_hub_model(model)
            elif layer == "LNK":
                self._validate_lnk_model(model)
            elif layer.upper() in ("SAT", "LSAT", "MSAT", "LMSAT"):
                self._validate_sat_model(model)
            elif layer.upper() == "ESAT":
                self._validate_esat_model(model)
        return self.errors

    def _find_columns_sheet(self, model):
        """Find the Columns sheet for this model."""
        layer = model.get("layer", "").upper()
        short_name = model.get("short_name", "")
        # Try layer-prefixed match first (e.g., "SAT cost_est_h" Columns)
        for name in self.wb.sheetnames:
            if "Columns" in name and name.upper().startswith(layer) and short_name[:10] in name:
                return name
        # Fallback: match by short_name only (for STG models that use "STG" prefix)
        for name in self.wb.sheetnames:
            if "Columns" in name and short_name[:10] in name:
                return name
        return None

    def _find_tables_sheet(self, model):
        """Find the Tables sheet for this model."""
        layer = model.get("layer", "").upper()
        short_name = model.get("short_name", "")
        # Try layer-prefixed match first
        for name in self.wb.sheetnames:
            if "Tables" in name and name.upper().startswith(layer) and short_name[:10] in name:
                return name
        # Fallback
        for name in self.wb.sheetnames:
            if "Tables" in name and short_name[:10] in name:
                return name
        return None

    def _validate_stg_model(self, model):
        """Validate a STG model's XLSX output."""
        columns_sheet = self._find_columns_sheet(model)
        if not columns_sheet:
            self.errors.append(ValidationError(
                "ERROR", "SHEET_MISSING",
                f"No Columns sheet found for model {model.get('derived_name', '?')}"
            ))
            return

        ws = self.wb[columns_sheet]
        rows = list(ws.iter_rows(min_row=2, values_only=True))  # skip header

        if not rows:
            self.errors.append(ValidationError(
                "ERROR", "EMPTY_SHEET",
                f"Columns sheet '{columns_sheet}' has no data rows"
            ))
            return

        # Build lookup structures from YAML
        yaml_cols = model.get("columns", [])
        bk_col = self._find_bk_column(yaml_cols)
        grain_columns = self.metadata.get("grain_columns", [])

        # Run individual checks
        self._check_duplicate_staging_columns(rows)
        self._check_bk_exists(rows, bk_col)
        self._check_bk_manual_logic(rows, bk_col)
        self._check_raw_bk_retained(rows, bk_col)
        self._check_composite_bk_columns_split(rows, bk_col)
        self._check_hk_uses_raw_source(rows, bk_col)
        self._check_hk_uniqueness(rows)
        self._check_hashdiff_uniqueness(rows)
        self._check_grain_unique(rows, grain_columns)
        self._check_load_dts_derivation(rows)
        self._check_hashdiff_last(rows)
        self._check_hashdiff_excludes_metadata(rows)
        self._check_column_ordering(rows)
        self._check_column_count(rows, yaml_cols)
        self._check_manual_logic_rules(rows)

        # Validate Tables sheet
        tables_sheet = self._find_tables_sheet(model)
        if tables_sheet:
            tables_rows = list(self.wb[tables_sheet].iter_rows(min_row=2, values_only=True))
            self._check_bkcc_table_entry(tables_rows)
            self._check_stg_no_delete_filter(tables_rows)
            self._check_driver_table_exists(tables_rows)
            self._check_join_columns_in_columns_sheet(tables_rows, rows)

        # Check #22: Hashdiff column header consistency
        self._check_hashdiff_column_header(ws)

        # Multi-table validation checks (MT1-MT8) — only when secondary table present
        if tables_sheet:
            sec_detected = self._detect_secondary_table(tables_rows)
            if sec_detected:
                self._run_mt_checks(model, tables_rows, rows)

    def _validate_hub_model(self, model):
        """Validate a HUB model's XLSX output."""
        columns_sheet = self._find_columns_sheet(model)
        if not columns_sheet:
            self.errors.append(ValidationError(
                "ERROR", "SHEET_MISSING",
                f"No Columns sheet found for HUB model {model.get('derived_name', '?')}"
            ))
            return

        ws = self.wb[columns_sheet]
        rows = list(ws.iter_rows(min_row=2, values_only=True))
        if not rows:
            self.errors.append(ValidationError(
                "ERROR", "EMPTY_SHEET",
                f"HUB Columns sheet '{columns_sheet}' has no data rows"
            ))
            return

        # HUB/LNK format: Ghost Record at index 13 (PK, Unique, Not Null, Ghost Record, Hashdiff)
        ghost_idx = 13
        min_row_width = 14
        short_rows = [r for r in rows if len(r) < min_row_width]
        if short_rows:
            self.errors.append(ValidationError(
                "ERROR", "HUB_ROW_TOO_SHORT",
                f"HUB Columns sheet has rows with fewer than 14 columns (ghost_idx=13 requires at least 14). Check XLSX format."))
            return


        # Hub-specific checks
        self._check_duplicate_staging_columns(rows)

        # 1. HK must be first column with PK and ghost=hash
        hk_count = sum(1 for r in rows if (r[8] or "").upper().endswith("_HK"))
        if hk_count == 0:
            self.errors.append(ValidationError(
                "ERROR", "HUB_HK_MISSING", "Hub model has no _HK column"))
        elif hk_count > 1:
            self.errors.append(ValidationError(
                "ERROR", "HUB_HK_DUPLICATE", f"Hub has {hk_count} _HK columns (expected 1)"))

        first_row = rows[0] if rows else None
        if first_row:
            first_staging = (first_row[8] or "").upper()
            first_ghost = (first_row[ghost_idx] or "").strip().lower()
            if not first_staging.endswith("_HK"):
                self.errors.append(ValidationError(
                    "ERROR", "HUB_HK_NOT_FIRST",
                    f"Hub first column '{first_staging}' is not HK (_HK suffix)"))
            if first_ghost != "hash":
                self.errors.append(ValidationError(
                    "ERROR", "HUB_HK_GHOST",
                    f"Hub HK '{first_staging}' ghost_record should be 'hash', got '{first_ghost}'"))

        # 2. At least one BK column (value_text ghost record)
        bk_count = sum(
            1 for r in rows
            if (r[ghost_idx] or "").strip().lower() == "value_text"
        )
        if bk_count == 0:
            self.errors.append(ValidationError(
                "ERROR", "HUB_BK_MISSING",
                "Hub model has no BK columns (ghost_record=value_text)"))

        # 3. No HASHDIFF column (hubs don't have HASHDIFF)
        hashdiff_count = sum(1 for r in rows if (r[8] or "").upper() == "HASHDIFF")
        if hashdiff_count > 0:
            self.errors.append(ValidationError(
                "ERROR", "HUB_HAS_HASHDIFF",
                "Hub model must NOT have a HASHDIFF column"))

        # 4. No payload/data columns (hubs only have HK, BK, BKCC, LOAD_DTS, REC_SRC)
        allowed_ghosts = {"hash", "value_text", "value_number", "bkcc",
                          "load_dts", "rec_src"}
        for r in rows:
            staging = (r[8] or "").upper()
            ghost = (r[ghost_idx] or "").strip().lower()
            if ghost and ghost not in allowed_ghosts and ghost != "null":
                self.errors.append(ValidationError(
                    "WARN", "HUB_UNEXPECTED_COLUMN",
                    f"Hub column '{staging}' has unexpected ghost_record='{ghost}'"))

        # 5. Validate Tables sheet — must have FINAL LAYER FILTER with NOT EXISTS
        tables_sheet = self._find_tables_sheet(model)
        if tables_sheet:
            tables_rows = list(self.wb[tables_sheet].iter_rows(min_row=2, values_only=True))
            self._check_driver_table_exists(tables_rows)
            # Check for NOT EXISTS in final layer filter
            has_not_exists = False
            for tr in tables_rows:
                if not tr:
                    continue
                final_filter = (tr[9] or "").upper()
                if "NOT EXISTS" in final_filter:
                    has_not_exists = True
            if not has_not_exists:
                self.errors.append(ValidationError(
                    "ERROR", "HUB_MISSING_NOT_EXISTS",
                    "Hub Tables sheet missing NOT EXISTS in Final Layer Filter"))

        # 6. Column headers should match HUB/LNK format (20 cols)
        headers = [cell.value for cell in ws[1]]
        if len(headers) != 20:
            self.errors.append(ValidationError(
                "ERROR", "HUB_HEADER_COUNT",
                f"HUB Columns sheet has {len(headers)} headers, expected 20"))
        elif headers[13] != "Ghost Record":
            self.errors.append(ValidationError(
                "ERROR", "HUB_HEADER_ORDER",
                f"HUB header at position 14 is '{headers[13]}', expected 'Ghost Record'"))

    def _validate_lnk_model(self, model):
        """Validate a LNK model's XLSX output."""
        columns_sheet = self._find_columns_sheet(model)
        if not columns_sheet:
            self.errors.append(ValidationError(
                "ERROR", "SHEET_MISSING",
                f"No Columns sheet found for LNK model {model.get('derived_name', '?')}"
            ))
            return

        ws = self.wb[columns_sheet]
        rows = list(ws.iter_rows(min_row=2, values_only=True))
        if not rows:
            self.errors.append(ValidationError(
                "ERROR", "EMPTY_SHEET",
                f"LNK Columns sheet '{columns_sheet}' has no data rows"
            ))
            return

        # HUB/LNK format: Ghost Record at index 13
        ghost_idx = 13
        min_row_width = 14
        short_rows = [r for r in rows if len(r) < min_row_width]
        if short_rows:
            self.errors.append(ValidationError(
                "ERROR", "LNK_ROW_TOO_SHORT",
                f"LNK Columns sheet has rows with fewer than 14 columns (ghost_idx=13 requires at least 14). Check XLSX format."))
            return


        self._check_duplicate_staging_columns(rows)

        # 1. LHK must exist (LNK_ prefix + _HK suffix)
        lhk_count = sum(
            1 for r in rows
            if (r[8] or "").upper().startswith("LNK_") and (r[8] or "").upper().endswith("_HK")
        )
        if lhk_count == 0:
            self.errors.append(ValidationError(
                "ERROR", "LNK_LHK_MISSING",
                "Link model has no LHK column (LNK_*_HK)"))
        elif lhk_count > 1:
            self.errors.append(ValidationError(
                "ERROR", "LNK_LHK_DUPLICATE",
                f"Link has {lhk_count} LHK columns (expected 1)"))

        # 2. At least 2 parent HKs (hash ghost records, excluding LHK)
        parent_hk_count = sum(
            1 for r in rows
            if (r[ghost_idx] or "").strip().lower() == "hash"
            and (r[8] or "").upper().endswith("_HK")
            and not ((r[8] or "").upper().startswith("LNK_") and (r[8] or "").upper().endswith("_HK"))
        )
        if parent_hk_count < 2:
            self.errors.append(ValidationError(
                "ERROR", "LNK_PARENT_HK_COUNT",
                f"Link model needs ≥2 parent HKs, found {parent_hk_count}"))

        # 3. No HASHDIFF column (links don't have HASHDIFF)
        hashdiff_count = sum(1 for r in rows if (r[8] or "").upper() == "HASHDIFF")
        if hashdiff_count > 0:
            self.errors.append(ValidationError(
                "ERROR", "LNK_HAS_HASHDIFF",
                "Link model must NOT have a HASHDIFF column"))

        # 4. No BKCC column (links don't have BKCC)
        bkcc_count = sum(1 for r in rows if (r[8] or "").upper() == "BKCC")
        if bkcc_count > 0:
            self.errors.append(ValidationError(
                "ERROR", "LNK_HAS_BKCC",
                "Link model must NOT have a BKCC column"))

        # 5. All parent HK columns have ghost_record=hash
        for r in rows:
            staging = (r[8] or "").upper()
            ghost = (r[ghost_idx] or "").strip().lower()
            if staging.endswith("_HK") and ghost != "hash":
                self.errors.append(ValidationError(
                    "ERROR", "LNK_HK_GHOST",
                    f"LNK HK column '{staging}' ghost_record should be 'hash', got '{ghost}'"))

        # 6. Validate Tables sheet — must have NOT EXISTS
        tables_sheet = self._find_tables_sheet(model)
        if tables_sheet:
            tables_rows = list(self.wb[tables_sheet].iter_rows(min_row=2, values_only=True))
            self._check_driver_table_exists(tables_rows)
            has_not_exists = False
            for tr in tables_rows:
                if not tr:
                    continue
                final_filter = (tr[9] or "").upper()
                if "NOT EXISTS" in final_filter:
                    has_not_exists = True
            if not has_not_exists:
                self.errors.append(ValidationError(
                    "ERROR", "LNK_MISSING_NOT_EXISTS",
                    "Link Tables sheet missing NOT EXISTS in Final Layer Filter"))

        # 7. Column headers should match HUB/LNK format (20 cols)
        headers = [cell.value for cell in ws[1]]
        if len(headers) != 20:
            self.errors.append(ValidationError(
                "ERROR", "LNK_HEADER_COUNT",
                f"LNK Columns sheet has {len(headers)} headers, expected 20"))
        elif headers[13] != "Ghost Record":
            self.errors.append(ValidationError(
                "ERROR", "LNK_HEADER_ORDER",
                f"LNK header at position 14 is '{headers[13]}', expected 'Ghost Record'"))

    def _validate_sat_model(self, model):
        """Validate a SAT/LSAT/MSAT/LMSAT model's XLSX output."""
        layer = model.get("layer", "").upper()
        derived_name = model.get("derived_name", "?")
        columns_sheet = self._find_columns_sheet(model)
        if not columns_sheet:
            self.errors.append(ValidationError(
                "ERROR", "SHEET_MISSING",
                f"No Columns sheet found for {layer} model {derived_name}"
            ))
            return

        ws = self.wb[columns_sheet]
        rows = list(ws.iter_rows(min_row=2, values_only=True))
        if not rows:
            self.errors.append(ValidationError(
                "ERROR", "EMPTY_SHEET",
                f"{layer} Columns sheet '{columns_sheet}' has no data rows"
            ))
            return

        # SAT format: Ghost Record at index 12 (PK, Unique, Ghost Record, Not Null)
        # Relationship at index 18 (19 columns total, no Hashdiff header)
        ghost_idx = 12
        rel_idx = 18
        min_row_width = 13
        short_rows = [r for r in rows if len(r) < min_row_width]
        if short_rows:
            self.errors.append(ValidationError(
                "ERROR", "SAT_ROW_TOO_SHORT",
                f"SAT Columns sheet has rows with fewer than 13 columns (ghost_idx=12 requires at least 13). Check XLSX format."))
            return


        self._check_duplicate_staging_columns(rows)

        # 1. Parent HK must exist (first row, ghost=hash)
        first_row = rows[0] if rows else None
        if first_row:
            first_staging = (first_row[8] or "").upper()
            first_ghost = (first_row[ghost_idx] or "").strip().lower()
            if not first_staging.endswith(("_HK", "_LHK")):
                self.errors.append(ValidationError(
                    "ERROR", "SAT_PARENT_HK_NOT_FIRST",
                    f"{layer} first column '{first_staging}' is not a parent HK (_HK or _LHK suffix)"))
            if first_ghost != "hash":
                self.errors.append(ValidationError(
                    "ERROR", "SAT_PARENT_HK_GHOST",
                    f"{layer} parent HK '{first_staging}' ghost_record should be 'hash', got '{first_ghost}'"))

        # 2. HASHDIFF (or named variant HASHDIFF_*) must exist
        def _is_hashdiff_col(name):
            u = (name or "").upper()
            return u == "HASHDIFF" or u.startswith("HASHDIFF_")
        hashdiff_count = sum(1 for r in rows if _is_hashdiff_col(r[8]))
        if hashdiff_count == 0:
            self.errors.append(ValidationError(
                "ERROR", "SAT_HASHDIFF_MISSING",
                f"{layer} model has no HASHDIFF column"))
        elif hashdiff_count > 1:
            self.errors.append(ValidationError(
                "ERROR", "SAT_HASHDIFF_DUPLICATE",
                f"{layer} has {hashdiff_count} HASHDIFF columns (expected 1)"))

        # 3. HASHDIFF ghost should be 'hashdiff'
        for r in rows:
            if _is_hashdiff_col(r[8]):
                hd_ghost = (r[ghost_idx] or "").strip().lower()
                if hd_ghost != "hashdiff":
                    self.errors.append(ValidationError(
                        "ERROR", "SAT_HASHDIFF_GHOST",
                        f"{layer} HASHDIFF ghost_record should be 'hashdiff', got '{hd_ghost}'"))

        # 4. LOAD_DTS, REC_SRC, BKCC must exist
        staging_names = set((r[8] or "").upper() for r in rows)
        for required_col in ("LOAD_DTS", "REC_SRC", "BKCC"):
            if required_col not in staging_names:
                self.errors.append(ValidationError(
                    "ERROR", f"SAT_{required_col}_MISSING",
                    f"{layer} model missing required column: {required_col}"))

        # 5. PK value must match expected format
        pk_found = False
        for r in rows:
            pk_val = (r[10] or "").strip()
            if pk_val.upper().startswith("PK:"):
                pk_found = True
                pk_parts = pk_val.split(":", 1)[1].strip()
                pk_cols = [p.strip().upper() for p in pk_parts.split(",")]
                # Must contain parent HK and LOAD_DTS
                if not any(c.endswith(("_HK", "_LHK")) for c in pk_cols):
                    self.errors.append(ValidationError(
                        "ERROR", "SAT_PK_MISSING_HK",
                        f"{layer} PK does not contain parent HK: {pk_val}"))
                if "LOAD_DTS" not in pk_cols:
                    self.errors.append(ValidationError(
                        "ERROR", "SAT_PK_MISSING_LOAD_DTS",
                        f"{layer} PK does not contain LOAD_DTS: {pk_val}"))
        if not pk_found:
            self.errors.append(ValidationError(
                "ERROR", "SAT_PK_MISSING",
                f"{layer} model has no PK definition (expected 'PK: HK, LOAD_DTS')"))

        # 6. Relationship column must exist for FK to parent hub/link
        has_relationship = False
        for r in rows:
            rel_val = (r[rel_idx] or "").strip() if len(r) > rel_idx else ""
            if rel_val:
                has_relationship = True
        if not has_relationship:
            self.errors.append(ValidationError(
                "ERROR", "SAT_FK_MISSING",
                f"{layer} model has no Relationship value (FK to parent hub/link)"))

        # 7. Ghost records: HK=hash, LOAD_DTS=load_dts, REC_SRC=rec_src, BKCC=bkcc
        ghost_checks = {
            "LOAD_DTS": "load_dts",
            "REC_SRC": "rec_src",
            "BKCC": "bkcc",
        }
        for r in rows:
            staging = (r[8] or "").upper()
            ghost = (r[ghost_idx] or "").strip().lower()
            if staging in ghost_checks:
                expected = ghost_checks[staging]
                if ghost != expected:
                    self.errors.append(ValidationError(
                        "WARN", "SAT_GHOST_MISMATCH",
                        f"{layer} column '{staging}' ghost_record='{ghost}', expected '{expected}'"))

        # 8. No derived BK alias (SAT uses raw source columns only)
        for r in rows:
            staging = (r[8] or "").upper()
            if staging.endswith("_BK"):
                self.errors.append(ValidationError(
                    "WARN", "SAT_HAS_BK_ALIAS",
                    f"{layer} has BK alias column '{staging}' — SAT should only have raw source columns"))

        # 9. Validate Tables sheet
        tables_sheet = self._find_tables_sheet(model)
        if tables_sheet:
            tables_rows = list(self.wb[tables_sheet].iter_rows(min_row=2, values_only=True))
            self._check_driver_table_exists(tables_rows)

            # NOT EXISTS must reference HASHDIFF
            has_not_exists = False
            has_hashdiff_in_not_exists = False
            for tr in tables_rows:
                if not tr:
                    continue
                final_filter = (tr[9] or "")
                if "NOT EXISTS" in final_filter.upper():
                    has_not_exists = True
                    if "HASHDIFF" in final_filter.upper():
                        has_hashdiff_in_not_exists = True
            if not has_not_exists:
                self.errors.append(ValidationError(
                    "ERROR", "SAT_MISSING_NOT_EXISTS",
                    f"{layer} Tables sheet missing NOT EXISTS in Final Layer Filter"))
            elif not has_hashdiff_in_not_exists:
                self.errors.append(ValidationError(
                    "ERROR", "SAT_NOT_EXISTS_MISSING_HASHDIFF",
                    f"{layer} NOT EXISTS must include HASHDIFF comparison"))

        # 10. Column headers should match SAT format (19 cols)
        headers = [cell.value for cell in ws[1]]
        if len(headers) != 19:
            self.errors.append(ValidationError(
                "ERROR", "SAT_HEADER_COUNT",
                f"{layer} Columns sheet has {len(headers)} headers, expected 19"))
        elif headers[12] != "Ghost Record":
            self.errors.append(ValidationError(
                "ERROR", "SAT_HEADER_ORDER",
                f"{layer} header at position 13 is '{headers[12]}', expected 'Ghost Record'"))

    def _validate_esat_model(self, model):
        """Validate effectivity satellite — minimal checks (out of scope for automation)."""
        # TODO: ESAT validation is a stub — only checks sheet existence.
        # Full ESAT validation (no HASHDIFF, no payload, only relationship
        # columns) is out of scope for this release. See known gap #8.
        derived_name = model.get("derived_name", "?")
        columns_sheet = self._find_columns_sheet(model)
        if not columns_sheet:
            self.errors.append(ValidationError(
                "ERROR", "ESAT_COLUMNS_MISSING",
                f"Could not find Columns sheet for ESAT model {derived_name}"))
        tables_sheet = self._find_tables_sheet(model)
        if not tables_sheet:
            self.errors.append(ValidationError(
                "ERROR", "ESAT_TABLES_MISSING",
                f"Could not find Tables sheet for ESAT model {derived_name}"))

    @staticmethod
    def _find_bk_column(yaml_cols):
        """Find the BK column from YAML (unique set AND not_null=yes)."""
        for col in yaml_cols:
            unique_val = str(col.get("unique", "")).strip()
            not_null_val = str(col.get("not_null", "")).strip().lower()
            if unique_val and not_null_val == "yes":
                return col
        return None

    def _check_duplicate_staging_columns(self, rows):
        """Check that no staging column name appears more than once."""
        staging_names = {}

        for row_idx, row in enumerate(rows):
            staging_name = (row[8] or "").strip()
            if not staging_name:
                continue

            if staging_name in staging_names:
                self.errors.append(ValidationError(
                    "ERROR", "DUPLICATE_STAGING_COLUMN",
                    f"Staging column '{staging_name}' appears in multiple rows "
                    f"(row {staging_names[staging_name] + 2} and row {row_idx + 2}). "
                    f"Each staging column must be unique."
                ))
            else:
                staging_names[staging_name] = row_idx

    def _check_bk_exists(self, rows, bk_col):
        """Check that BK row exists in XLSX with correct staging name."""
        if not bk_col:
            self.errors.append(ValidationError(
                "ERROR", "BK_MISSING_YAML",
                "No BK column found in YAML (requires both unique=yes AND not_null=yes)"
            ))
            return

        bk_staging_name = bk_col.get("staging_column_name", "")
        found = any(
            row[8] == bk_staging_name  # col index 8 = Staging Layer Column Name
            for row in rows if row[8]
        )
        if not found:
            self.errors.append(ValidationError(
                "ERROR", "BK_MISSING_XLSX",
                f"BK column '{bk_staging_name}' not found in XLSX Staging Layer Column Name"
            ))

    def _check_raw_bk_retained(self, rows, bk_col):
        """When BK has manual_logic (cast), raw source column must be retained."""
        if not bk_col or not bk_col.get("manual_logic"):
            return  # No cast, no passthrough needed

        raw_cols = get_source_columns(bk_col)
        # Skip check when source_column is (DERIVED) - raw passthroughs exist as separate rows (Lesson #54)
        if not raw_cols or raw_cols == ["(DERIVED)"]:
            return

        # The raw passthrough is retained either as the joined composite staging name
        # (e.g. "INVOICE_ID,LINE_NUMBER") or as each individual raw column name.
        raw_joined = source_columns_to_str(raw_cols)
        staging_names = [row[8] for row in rows if row[8]]
        retained = raw_joined in staging_names or all(t in staging_names for t in raw_cols)
        if not retained:
            self.errors.append(ValidationError(
                "ERROR", "RAW_BK_MISSING",
                f"Raw source column(s) '{raw_joined}' not retained as passthrough "
                f"(BK has manual_logic '{bk_col.get('manual_logic')}'). "
                f"Both raw column and BK alias must appear in output."
            ))

    def _check_composite_bk_columns_split(self, rows, bk_col):
        """XLSX_COMPOSITE_BK_COLUMNS_SPLIT: a composite BK's source columns must be
        rendered so multiplicity is unambiguous. The independent source of truth is
        the YAML ``bk_col.source_column`` list — the XLSX is asserted AGAINST it,
        never against itself.

        Two rendering requirements for a composite (len >= 2):
          1. The BK-alias row's 'Source Column' cell holds the raw columns one per
             line (never comma-joined), in declared order.
          2. Each raw column also appears as its own staging row (the passthrough
             rendered one-row-per-source-column).
        """
        if not bk_col:
            return
        raw_cols = get_source_columns(bk_col)  # YAML — the source of truth
        if len(raw_cols) < 2:
            return  # Not a composite BK — nothing to split

        bk_alias = (bk_col.get("staging_column_name", "") or "").upper()
        staging_names = {(r[8] or "").upper() for r in rows if r[8]}

        # (1) BK-alias row cell must be newline-split and match the YAML list exactly.
        for row in rows:
            if (row[8] or "").upper() != bk_alias:
                continue
            cell = row[2] or ""
            if "," in cell and "\n" not in cell:
                self.errors.append(ValidationError(
                    "ERROR", "XLSX_COMPOSITE_BK_COLUMNS_SPLIT",
                    f"Composite BK '{bk_alias}' Source Column cell is comma-joined "
                    f"({cell!r}) — render one column per line so it is distinguishable "
                    f"from a single column whose name contains a comma."
                ))
                break
            rendered = [t.strip() for t in str(cell).split("\n") if t.strip()]
            if rendered != raw_cols:
                self.errors.append(ValidationError(
                    "ERROR", "XLSX_COMPOSITE_BK_COLUMNS_SPLIT",
                    f"Composite BK '{bk_alias}' renders source columns {rendered} but "
                    f"YAML declares {raw_cols} (order-sensitive). Cell: {cell!r}"
                ))
            break

        # (2) Each raw column must also appear as its own staging (passthrough) row.
        missing = [c for c in raw_cols if c.upper() not in staging_names]
        if missing:
            self.errors.append(ValidationError(
                "ERROR", "XLSX_COMPOSITE_BK_COLUMNS_SPLIT",
                f"Composite BK '{bk_alias}' raw column(s) {missing} not rendered as "
                f"individual passthrough staging rows (expected one row per source "
                f"column, YAML declares {raw_cols})."
            ))

    def _check_hk_uses_raw_source(self, rows, bk_col):
        """HK HASH: formula must use raw source column name, not BK alias.
        
        Exception (lesson #79): When BK uses COALESCE/CONCAT (value-changing
        derivation), the HK must hash the BK alias instead. Simple casts
        (TO_CHAR, ::TEXT) don't change the value, so raw column is used.
        """
        if not bk_col:
            return

        raw_source = source_columns_to_str(get_source_columns(bk_col))
        raw_is_derived = get_source_columns(bk_col) == ["(DERIVED)"]
        bk_alias = bk_col.get("staging_column_name", "")
        bk_logic = bk_col.get("manual_logic", "").upper()

        # Determine if BK is a value-changing derivation (COALESCE/CONCAT)
        # vs a simple cast (TO_CHAR, ::TEXT) — lesson #79
        import re as _re
        is_value_changing = bool(_re.search(r"COALESCE|CONCAT|IFF|CASE|NVL|IFNULL", bk_logic))

        for row in rows:
            staging_name = row[8] or ""
            manual_logic = row[5] or ""
            if staging_name.endswith("_HK") and manual_logic.startswith("HASH:"):
                hash_components = manual_logic.replace("HASH:", "").strip()
                # (DERIVED) source columns are valid for secondary BKs (lesson #70)
                if raw_is_derived:
                    continue
                if is_value_changing:
                    # Value-changing BK: HK MUST use BK alias (not raw column)
                    if raw_source in hash_components and bk_alias not in hash_components:
                        self.errors.append(ValidationError(
                            "ERROR", "HK_SHOULD_USE_BK_ALIAS",
                            f"HK '{staging_name}' HASH formula uses raw column '{raw_source}' "
                            f"but BK '{bk_alias}' uses COALESCE/CONCAT — must hash BK alias "
                            f"for consistent hash values. Got: {manual_logic}"
                        ))
                else:
                    # Simple cast BK: HK must use raw source column
                    if bk_alias in hash_components and raw_source not in hash_components:
                        self.errors.append(ValidationError(
                            "ERROR", "HK_USES_BK_ALIAS",
                            f"HK '{staging_name}' HASH formula uses BK alias '{bk_alias}' "
                            f"instead of raw source column '{raw_source}'. "
                            f"Got: {manual_logic}"
                        ))
                    elif raw_source and raw_source not in hash_components:
                        self.errors.append(ValidationError(
                            "WARN", "HK_MISSING_RAW_SOURCE",
                            f"HK '{staging_name}' HASH formula may not contain raw source "
                            f"column '{raw_source}'. Got: {manual_logic}"
                        ))

    def _check_grain_unique(self, rows, grain_columns):
        """All grain columns must have unique='yes' or appear in a COMPOSITE unique string."""
        if not grain_columns:
            return

        # Collect all columns mentioned in COMPOSITE unique strings
        composite_columns = set()
        # Also map source_column → staging_column for BK alias resolution
        source_to_staging = {}
        for row in rows:
            unique_val = (row[11] or "").strip()
            source_col = (row[2] or "").upper()
            staging_name = (row[8] or "").upper()
            if source_col and staging_name:
                source_to_staging[source_col] = staging_name
            if "COMPOSITE:" in unique_val.upper():
                parts = unique_val.split(":", 1)[1].strip()
                for part in parts.split(","):
                    composite_columns.add(part.strip().upper())

        for grain_col in grain_columns:
            grain_upper = grain_col.upper()

            # A grain column is satisfied if:
            # 1. Any matching row has unique='yes' or COMPOSITE, OR
            # 2. The grain column appears in a COMPOSITE unique string, OR
            # 3. The grain column's BK alias appears in a COMPOSITE string
            if grain_upper in composite_columns:
                continue  # Satisfied via COMPOSITE
            # Check if the grain col is a source column whose BK alias is in COMPOSITE
            bk_alias = source_to_staging.get(grain_upper, "")
            if bk_alias and bk_alias in composite_columns:
                continue  # Satisfied — grain source col mapped to BK alias in COMPOSITE

            unique_satisfied = False
            any_match = False

            for row in rows:
                staging_name = (row[8] or "").upper()
                source_col = (row[2] or "").upper()

                if staging_name == grain_upper or source_col == grain_upper:
                    any_match = True
                    unique_val = (row[11] or "").strip()
                    # Accept "yes" or any COMPOSITE string as satisfying uniqueness
                    if unique_val.lower() == "yes" or "COMPOSITE:" in unique_val.upper():
                        unique_satisfied = True
                        break

            if not any_match and grain_upper not in composite_columns:
                self.errors.append(ValidationError(
                    "WARN", "GRAIN_COL_NOT_FOUND",
                    f"Grain column '{grain_col}' not found in XLSX columns"
                ))
            elif not unique_satisfied:
                self.errors.append(ValidationError(
                    "ERROR", "GRAIN_NOT_UNIQUE",
                    f"Grain column '{grain_col}' should have Unique='yes' on at least one "
                    f"matching row but none found"
                ))

    def _check_load_dts_derivation(self, rows):
        """LOAD_DTS Manual Logic must match ingestion source."""
        ingestion = self.metadata.get("ingestion_source", "").lower()

        for row in rows:
            if (row[8] or "") == "LOAD_DTS":
                manual_logic = row[5] or ""
                if ingestion == "fivetran":
                    if "_FIVETRAN_SYNCED" not in manual_logic:
                        self.errors.append(ValidationError(
                            "ERROR", "LOAD_DTS_WRONG_SOURCE",
                            f"Fivetran source but LOAD_DTS doesn't derive from _FIVETRAN_SYNCED. "
                            f"Got: {manual_logic}"
                        ))
                elif not ingestion:
                    if "PSA_LOAD_DTS" not in manual_logic and "_FIVETRAN_SYNCED" not in manual_logic:
                        self.errors.append(ValidationError(
                            "WARN", "LOAD_DTS_UNKNOWN_SOURCE",
                            f"LOAD_DTS Manual Logic doesn't reference PSA_LOAD_DTS or _FIVETRAN_SYNCED. "
                            f"Got: {manual_logic}"
                        ))
                break

    def _check_hashdiff_last(self, rows):
        """HASHDIFF must be the last column in the sheet."""
        if not rows:
            return

        last_row = rows[-1]
        last_staging = (last_row[8] or "").upper()
        if last_staging != "HASHDIFF":
            self.errors.append(ValidationError(
                "ERROR", "HASHDIFF_NOT_LAST",
                f"HASHDIFF must be the last column but last is '{last_staging}'"
            ))

    def _check_hashdiff_excludes_metadata(self, rows):
        """HASHDIFF HASH: formula must not include metadata/technical columns."""
        metadata_cols = {"_FIVETRAN_SYNCED", "_FIVETRAN_ID", "PSA_LOAD_DTS",
                         "PSA_RECORD_SOURCE", "BKCC", "REC_SRC", "LOAD_DTS"}

        for row in rows:
            if (row[8] or "").upper() == "HASHDIFF":
                manual_logic = row[5] or ""
                if manual_logic.startswith("HASH:"):
                    hash_list = manual_logic.replace("HASH:", "").strip()
                    hash_cols = [c.strip().upper() for c in hash_list.split(",")]
                    for mc in metadata_cols:
                        if mc.upper() in hash_cols:
                            self.errors.append(ValidationError(
                                "ERROR", "HASHDIFF_INCLUDES_METADATA",
                                f"HASHDIFF includes metadata column '{mc}' which should be excluded"
                            ))
                break

    def _check_column_ordering(self, rows):
        """Verify column ordering follows the 8-step sequence."""
        if not rows:
            return

        expected_order = ["BK", "HK", "DATA", "TECHNICAL", "BKCC", "REC_SRC", "LOAD_DTS", "HASHDIFF"]
        current_section_idx = 0

        for row in rows:
            staging_name = (row[8] or "").upper()
            source_col = (row[2] or "").upper()

            if staging_name.endswith("_BK"):
                section = "BK"
            elif staging_name.endswith("_HK"):
                section = "HK"
            elif staging_name == "BKCC":
                section = "BKCC"
            elif staging_name == "REC_SRC":
                section = "REC_SRC"
            elif staging_name == "LOAD_DTS":
                section = "LOAD_DTS"
            elif staging_name == "HASHDIFF":
                section = "HASHDIFF"
            elif staging_name.startswith("_FIVETRAN") or staging_name.startswith("PSA_"):
                section = "TECHNICAL"
            else:
                # Raw BK passthrough row — its staging name is one of a BK row's
                # source columns. For a composite BK the source cell is newline-
                # (or comma-) joined (e.g. "INVOICE_ID\nLINE_NUMBER"), so match
                # membership in the split set, not equality (issue #1906).
                is_raw_bk = any(
                    (r[8] or "").upper().endswith("_BK")
                    and staging_name in {
                        t.strip().upper()
                        for t in re.split(r"[\n,]", r[2] or "")
                        if t.strip()
                    }
                    for r in rows
                )
                section = "BK" if is_raw_bk else "DATA"

            if section in expected_order:
                section_idx = expected_order.index(section)
                # KEYS band: BK (idx 0) and HK (idx 1) may swap relative to
                # each other but must appear before DATA and later sections.
                _keys_max_idx = max(expected_order.index("BK"), expected_order.index("HK"))
                if section_idx < current_section_idx:
                    if section in ("BK", "HK") and current_section_idx <= _keys_max_idx:
                        # Still within the KEYS band — suppress warning
                        pass
                    else:
                        self.errors.append(ValidationError(
                            "WARN", "COLUMN_ORDER",
                            f"Column '{staging_name}' (section {section}) appears after "
                            f"section {expected_order[current_section_idx]} — expected order: "
                            f"{' → '.join(expected_order)}"
                        ))
                # Advance section index, but BK/HK only advance within the KEYS band
                if section not in ("BK", "HK"):
                    current_section_idx = max(current_section_idx, section_idx)
                else:
                    # Keep current_section_idx within the KEYS band ceiling
                    current_section_idx = max(current_section_idx, min(section_idx, _keys_max_idx))

    def _check_column_count(self, rows, yaml_cols):
        """XLSX should have at least as many columns as YAML source columns (non-derived)."""
        # Count only non-derived YAML columns (source_column != "(DERIVED)")
        yaml_source_count = sum(
            1 for c in yaml_cols
            if get_source_columns(c) != ["(DERIVED)"]
        )
        xlsx_count = len(rows)

        if xlsx_count < yaml_source_count:
            self.errors.append(ValidationError(
                "ERROR", "COLUMN_COUNT_LOW",
                f"XLSX has {xlsx_count} data rows but YAML defines {yaml_source_count} source columns. "
                f"Some columns may have been dropped."
            ))

    def _check_manual_logic_rules(self, rows):
        """Manual Logic must be blank for direct columns, populated for derived."""
        for row in rows:
            source_col = row[2] or ""
            manual_logic = row[5] or ""
            staging_name = (row[8] or "").upper()

            # Derived columns should have Manual Logic
            if source_col == "(DERIVED)" and not manual_logic:
                self.errors.append(ValidationError(
                    "WARN", "MANUAL_LOGIC_MISSING_DERIVED",
                    f"Derived column '{staging_name}' has no Manual Logic — "
                    f"expected transformation formula (HASH:, CONVERT_TIMEZONE, etc.)"
                ))

    def _check_bkcc_table_entry(self, tables_rows):
        """Tables sheet should have BKCC reference table entry."""
        bkcc_rec_src = self.metadata.get("bkcc_rec_src", "")
        if not bkcc_rec_src:
            return

        found = any(
            (row[1] or "") == "ref_business_key_collision"
            for row in tables_rows if row
        )
        if not found:
            self.errors.append(ValidationError(
                "ERROR", "BKCC_TABLE_MISSING",
                "Tables sheet missing ref_business_key_collision entry"
            ))

    def _check_stg_no_delete_filter(self, tables_rows):
        """STG models should NOT have psa_delete_ind = 'N' filter."""
        for row in tables_rows:
            if not row:
                continue
            filter_conditions = (row[4] or "").lower()
            if "psa_delete_ind" in filter_conditions and "= 'n'" in filter_conditions:
                self.errors.append(ValidationError(
                    "ERROR", "STG_HAS_DELETE_FILTER",
                    "STG models must not filter psa_delete_ind = 'N'. "
                    "All records (including deletes) should be retained in staging."
                ))

    def _check_driver_table_exists(self, tables_rows):
        """Driver table row should exist in Tables sheet."""
        if not tables_rows:
            self.errors.append(ValidationError(
                "ERROR", "DRIVER_TABLE_MISSING",
                "Tables sheet has no rows (driver table missing)"
            ))


    def _check_join_columns_in_columns_sheet(self, tables_rows, column_rows):
        """Join predicate columns must exist in Columns sheet (lesson #84).

        build.py constructs JOIN as: LOGIC_{alias}.{col} — the col must appear
        as a staging_column_name for that alias in the Columns sheet, because
        the LOGIC CTE renames columns before the JOIN layer uses them.

        For child_table_join (secondary table side): column must use the
        post-rename staging_column_name from Columns sheet.
        For parent_table_join (driver table side): column must exist as a
        staging_column_name for SRC (or any source_table) in Columns sheet.
        """
        if not tables_rows or not column_rows:
            return

        # Build lookup: alias -> set of staging_column_names
        alias_columns = {}
        for row in column_rows:
            src_table = (row[1] or "").strip().upper()  # Source Table (col idx 1)
            staging_name = (row[8] or "").strip().upper()  # Staging Layer Column Name (col idx 8)
            if src_table and staging_name:
                alias_columns.setdefault(src_table, set()).add(staging_name)

        # Also add derived columns (source_table='') to all aliases
        for row in column_rows:
            src_table = (row[1] or "").strip()
            staging_name = (row[8] or "").strip().upper()
            if not src_table and staging_name:
                for alias_set in alias_columns.values():
                    alias_set.add(staging_name)

        for trow in tables_rows:
            alias = (trow[2] or "").strip().upper()
            parent_join = (trow[7] or "").strip()  # Parent Table Join
            child_join = (trow[8] or "").strip()   # Child Table Join

            if not child_join or not parent_join:
                continue  # Driver table — no join predicate

            # Skip BKCC cross-join row (ON '1' = '1')
            if 'BKCC' in alias or parent_join.strip("'") == '1':
                continue

            # Check child_table_join: "ORD_ID" (preferred) or legacy "ORD.ORD_ID"
            if '.' in child_join:
                child_alias, child_col = child_join.split('.', 1)
                child_alias = child_alias.upper()
            else:
                child_alias = alias  # Use alias from table row
                child_col = child_join
            child_col = child_col.upper()
            child_cols = alias_columns.get(child_alias, set())
            if child_col not in child_cols:
                self.errors.append(ValidationError(
                    "ERROR", "JOIN_COL_MISSING_IN_COLUMNS",
                    f"Child join column '{child_col}' "
                    f"but no column with staging_column_name='{child_col}' exists "
                    f"in Columns sheet for source_table='{child_alias}'. "
                    f"The join happens after LOGIC layer — column must be renamed there first."
                ))

            # Check parent_table_join: "ORDER_ID" -> must exist as staging_column_name for SRC
            parent_col = parent_join.upper()
            if '.' in parent_join:
                _, parent_col = parent_join.split('.', 1)
                parent_col = parent_col.upper()
            # Parent col should exist in SRC columns or any alias columns
            found = any(parent_col in cols for cols in alias_columns.values())
            if not found:
                self.errors.append(ValidationError(
                    "ERROR", "JOIN_COL_MISSING_IN_COLUMNS",
                    f"Parent join column '{parent_join}' references '{parent_col}' "
                    f"but no column with staging_column_name='{parent_col}' exists "
                    f"in Columns sheet for any source table."
                ))

    def _check_bk_manual_logic(self, rows, bk_col):
        """BK row must populate manual_logic if YAML has a CAST."""
        if not bk_col or not bk_col.get("manual_logic"):
            return  # No CAST, no manual_logic needed

        # Find BK row in XLSX
        bk_staging = bk_col.get("staging_column_name", "")
        for row in rows:
            if (row[8] or "") == bk_staging:
                manual_logic = row[5] or ""
                if not manual_logic:
                    self.errors.append(ValidationError(
                        "WARN", "BK_MANUAL_LOGIC_MISSING",
                        f"BK '{bk_staging}' has manual_logic in YAML but Manual Logic is blank in XLSX. "
                        f"Expected: {bk_col.get('manual_logic')}"
                    ))
                break

    def _check_hk_uniqueness(self, rows):
        """HK column should appear exactly once."""
        hk_count = 0
        for row in rows:
            staging_name = (row[8] or "").upper()
            if staging_name.endswith("_HK"):
                hk_count += 1

        if hk_count == 0:
            self.errors.append(ValidationError(
                "ERROR", "HK_MISSING",
                "No hash key (_HK) column found in XLSX"
            ))
        elif hk_count > 1:
            # Multiple HKs are valid when model has hub HKs + link HK (e.g. PRODUCT_VARIANT_HK + PRODUCT_HK + LNK_PRODUCT_VARIANT_HK)
            pass

    def _check_hashdiff_uniqueness(self, rows):
        """HASHDIFF column should appear exactly once."""
        hashdiff_count = sum(1 for row in rows if (row[8] or "").upper() == "HASHDIFF")

        if hashdiff_count == 0:
            self.errors.append(ValidationError(
                "WARN", "HASHDIFF_MISSING",
                "No HASHDIFF column found (may be intentional for non-SAT models)"
            ))
        elif hashdiff_count > 1:
            self.errors.append(ValidationError(
                "ERROR", "HASHDIFF_DUPLICATE",
                f"HASHDIFF appears {hashdiff_count} times (should be 0 or 1)"
            ))

    def _check_hashdiff_column_header(self, ws):
        """Check #22: Columns sheet headers include Hashdiff at position 14 (0-indexed: 13).
        
        Ensures XLSX has the 20-column format required for round-trip code generation.
        The Hashdiff column must exist between Not Null and Ghost Record headers.
        """
        headers = [cell.value for cell in ws[1]]
        expected_20 = [
            "Source Schema", "Source Table", "Source Column", "Datatype",
            "Automated Logic", "Manual Logic", "Mapping Notes", "Order#",
            "Staging Layer Column Name", "Staging Layer Datatype",
            "PK", "Unique", "Not Null", "Hashdiff", "Ghost Record",
            "Remove Column", "Set Default", "Test Expression", "Accepted Values", "Relationship",
        ]

        if len(headers) < 20:
            self.errors.append(ValidationError(
                "ERROR", "COLUMN_HEADER_COUNT",
                f"Columns sheet has {len(headers)} headers, expected 20. "
                f"Missing 'Hashdiff' column may cause code generation failures."
            ))
        elif headers[13] != "Hashdiff":
            self.errors.append(ValidationError(
                "ERROR", "HASHDIFF_HEADER_POSITION",
                f"Column header at position 14 is '{headers[13]}', expected 'Hashdiff'. "
                f"The Hashdiff column must be between 'Not Null' and 'Ghost Record'."
            ))

        # Also verify the column data rows have hashdiff flags for data columns
        data_rows_with_hashdiff = 0
        for row in ws.iter_rows(min_row=2, values_only=True):
            staging_name = (row[8] or "").upper() if len(row) > 8 else ""
            hashdiff_val = (row[13] or "").lower() if len(row) > 13 else ""
            if hashdiff_val in ("yes", "y"):
                data_rows_with_hashdiff += 1

        if data_rows_with_hashdiff == 0:
            self.errors.append(ValidationError(
                "WARN", "NO_HASHDIFF_FLAGS",
                "No columns have Hashdiff='yes'. Check that data columns are flagged for HASHDIFF."
            ))


    # ── Multi-Table (MT) Validation Checks ─────────────────────────────────

    def _detect_secondary_table(self, tables_rows):
        """Detect secondary table row in Tables sheet.

        Returns the secondary row tuple or None if no secondary table found.
        A secondary row has: alias != SRC, alias != ref_bkcc, and Join Type set.
        """
        for row in tables_rows:
            alias = (row[2] or "").strip().lower()
            join_type = (row[10] or "").strip()
            if alias and alias not in ("src", "ref_bkcc") and join_type:
                return row
        return None

    def _run_mt_checks(self, model, tables_rows, column_rows):
        """Run all multi-table validation checks. Only called when secondary table detected."""
        sec_row = self._detect_secondary_table(tables_rows)
        if not sec_row:
            return  # No secondary table — skip all MT checks silently

        sec_alias = (sec_row[2] or "").strip().upper()
        self._check_mt1_tables_row_count(tables_rows, sec_alias)
        self._check_mt2_secondary_qualify(sec_row, sec_alias)
        self._check_mt3_join_predicate_valid(tables_rows, column_rows, sec_row, sec_alias)
        self._check_mt4_collision_renamed(column_rows, sec_alias)
        self._check_mt5_secondary_bk_refs(column_rows, sec_alias)
        self._check_mt6_hk_formulas(column_rows)
        self._check_mt7_hashdiff_excludes(column_rows)
        self._check_mt8_driver_qualify_gating(tables_rows, model)

    def _check_mt1_tables_row_count(self, tables_rows, sec_alias):
        """MT1: Tables tab has exactly 3 rows for multi-table STG models."""
        if len(tables_rows) != 3:
            self.errors.append(ValidationError(
                "ERROR", "MT1_TABLE_ROW_COUNT",
                f"Expected 3 Tables rows, found {len(tables_rows)}. "
                f"Secondary table row may be missing."
            ))
            return

        # Check row types
        aliases = [(r[2] or "").strip().lower() for r in tables_rows]
        if aliases[0] != "src":
            self.errors.append(ValidationError(
                "ERROR", "MT1_TABLE_ROW_COUNT",
                f"Row 1 alias should be 'SRC', got '{aliases[0]}'"
            ))
        if aliases[2] != "ref_bkcc":
            self.errors.append(ValidationError(
                "ERROR", "MT1_TABLE_ROW_COUNT",
                f"Row 3 alias should be 'ref_bkcc', got '{aliases[2]}'"
            ))
        # Check BKCC row join type
        bkcc_join = (tables_rows[2][10] or "").strip().lower()
        if "inner" not in bkcc_join:
            self.errors.append(ValidationError(
                "ERROR", "MT1_TABLE_ROW_COUNT",
                f"BKCC row join type should be INNER JOIN, got '{bkcc_join}'"
            ))

    def _check_mt2_secondary_qualify(self, sec_row, sec_alias):
        """MT2: Secondary table has QUALIFY in Source Layer Filter."""
        src_filter = (sec_row[3] or "").strip()
        if not src_filter:
            self.errors.append(ValidationError(
                "ERROR", "MT2_SECONDARY_QUALIFY",
                f"Secondary table {sec_alias} missing QUALIFY in Source Layer Filter"
            ))
            return

        upper_filter = src_filter.upper()
        if "QUALIFY" not in upper_filter:
            self.errors.append(ValidationError(
                "ERROR", "MT2_SECONDARY_QUALIFY",
                f"Secondary table {sec_alias} Source Layer Filter missing QUALIFY keyword"
            ))
        if "PARTITION BY" not in upper_filter:
            self.errors.append(ValidationError(
                "ERROR", "MT2_SECONDARY_QUALIFY",
                f"Secondary table {sec_alias} QUALIFY missing PARTITION BY"
            ))
        if "ORDER BY" not in upper_filter:
            self.errors.append(ValidationError(
                "ERROR", "MT2_SECONDARY_QUALIFY",
                f"Secondary table {sec_alias} QUALIFY missing ORDER BY"
            ))

    def _check_mt3_join_predicate_valid(self, tables_rows, column_rows, sec_row, sec_alias):
        """MT3: Join predicate columns are valid."""
        parent_join = (sec_row[7] or "").strip().upper()
        child_join = (sec_row[8] or "").strip()

        if not parent_join or not child_join:
            self.errors.append(ValidationError(
                "ERROR", "MT3_JOIN_PREDICATE",
                f"Secondary table {sec_alias} missing Parent/Child Table Join values"
            ))
            return

        # Check parent join column exists in driver (SRC) columns
        driver_cols = set()
        for row in column_rows:
            src_table = (row[1] or "").strip().upper()
            staging_name = (row[8] or "").strip().upper()
            if src_table == "SRC" and staging_name:
                driver_cols.add(staging_name)
        # Also include derived columns
        for row in column_rows:
            src_table = (row[1] or "").strip()
            staging_name = (row[8] or "").strip().upper()
            if not src_table and staging_name:
                driver_cols.add(staging_name)

        if parent_join not in driver_cols:
            self.errors.append(ValidationError(
                "ERROR", "MT3_JOIN_PREDICATE",
                f"Parent join column {parent_join} not found in driver (SRC) columns"
            ))

        # Check child join column — format: "ORD_ID" (preferred) or legacy "ORD.ORD_ID"
        if "." in child_join:
            child_alias, child_col = child_join.split(".", 1)
            if child_alias.upper() != sec_alias:
                self.errors.append(ValidationError(
                    "ERROR", "MT3_JOIN_PREDICATE",
                    f"Child join alias '{child_alias}' doesn't match secondary alias '{sec_alias}'"
                ))
        else:
            child_col = child_join  # No alias prefix — column name only

        # Check child column exists in secondary table columns
        sec_cols = set()
        for row in column_rows:
            src_table = (row[1] or "").strip().upper()
            staging_name = (row[8] or "").strip().upper()
            if src_table == sec_alias and staging_name:
                sec_cols.add(staging_name)
        if child_col.upper() not in sec_cols:
            self.errors.append(ValidationError(
                "ERROR", "MT3_JOIN_PREDICATE",
                f"Child join column '{child_col}' not found in {sec_alias} columns"
            ))

    def _check_mt4_collision_renamed(self, column_rows, sec_alias):
        """MT4: Secondary columns with collisions are renamed."""
        driver_source_cols = set()
        for row in column_rows:
            src_table = (row[1] or "").strip().upper()
            source_col = (row[2] or "").strip().upper()
            if src_table == "SRC" and source_col:
                driver_source_cols.add(source_col)

        for row in column_rows:
            src_table = (row[1] or "").strip().upper()
            source_col = (row[2] or "").strip().upper()
            staging_name = (row[8] or "").strip().upper()
            if src_table != sec_alias or not source_col or source_col == "(DERIVED)":
                continue

            if source_col in driver_source_cols:
                expected_name = f"{sec_alias}_{source_col}"
                if staging_name == source_col:
                    self.errors.append(ValidationError(
                        "ERROR", "MT4_COLLISION_RENAME",
                        f"Column {source_col} collides with driver but not renamed "
                        f"(staging name = {staging_name}, expected {expected_name})"
                    ))

    def _check_mt5_secondary_bk_refs(self, column_rows, sec_alias):
        """MT5: Secondary BK uses renamed column references."""
        # Find collision renames
        driver_source_cols = set()
        for row in column_rows:
            src_table = (row[1] or "").strip().upper()
            source_col = (row[2] or "").strip().upper()
            if src_table == "SRC" and source_col:
                driver_source_cols.add(source_col)

        rename_map = {}
        for row in column_rows:
            src_table = (row[1] or "").strip().upper()
            source_col = (row[2] or "").strip().upper()
            staging_name = (row[8] or "").strip().upper()
            if src_table == sec_alias and source_col in driver_source_cols and source_col != "(DERIVED)":
                rename_map[source_col] = staging_name

        if not rename_map:
            return  # No collision renames — nothing to validate

        # Find secondary BK rows (derived BKs referencing secondary columns)
        for row in column_rows:
            staging_name = (row[8] or "").strip().upper()
            source_col = (row[2] or "").strip().upper()
            manual_logic = (row[5] or "").strip()
            if not staging_name.endswith("_BK") or source_col != "(DERIVED)":
                continue
            if not manual_logic:
                continue

            # Determine if this BK references any secondary-specific columns
            # (renamed columns or unique secondary columns). If it only
            # references columns that also exist in the driver, it's a
            # driver BK — not a secondary BK.
            renamed_vals = set(v.upper() for v in rename_map.values())
            refs_secondary = any(
                re.search(r'\b' + re.escape(rv) + r'\b', manual_logic, re.IGNORECASE)
                for rv in renamed_vals
            )
            if not refs_secondary:
                continue  # Driver BK — skip

            for original, renamed in rename_map.items():
                # Check if manual_logic references the original (pre-rename) name
                pattern = r'\b' + re.escape(original) + r'\b'
                if re.search(pattern, manual_logic, re.IGNORECASE):
                    renamed_pattern = r'\b' + re.escape(renamed) + r'\b'
                    if not re.search(renamed_pattern, manual_logic, re.IGNORECASE):
                        self.errors.append(ValidationError(
                            "ERROR", "MT5_BK_RENAME_REF",
                            f"Secondary BK {staging_name} references '{original}' which was "
                            f"renamed to '{renamed}' — use {renamed} in the expression"
                        ))

    def _check_mt6_hk_formulas(self, column_rows):
        """MT6: All HK HASH formulas reference correct columns."""
        for row in column_rows:
            staging_name = (row[8] or "").strip().upper()
            source_col = (row[2] or "").strip().upper()
            manual_logic = (row[5] or "").strip()

            if not staging_name.endswith("_HK") or source_col != "(DERIVED)":
                continue

            if not manual_logic.upper().startswith("HASH:"):
                continue

            # Parse HASH: col1, col2, ...
            hash_parts = [p.strip().upper() for p in manual_logic[5:].split(",")]
            if not hash_parts:
                continue

            # BKCC must be last component (lesson #12)
            if hash_parts[-1] != "BKCC":
                self.errors.append(ValidationError(
                    "ERROR", "MT6_HK_FORMULA",
                    f"{staging_name} — BKCC must be last component in HASH formula"
                ))

    def _check_mt7_hashdiff_excludes(self, column_rows):
        """MT7: HASHDIFF excludes BK columns and secondary columns."""
        # Find HASHDIFF row
        hashdiff_logic = None
        for row in column_rows:
            if (row[8] or "").strip().upper() == "HASHDIFF":
                hashdiff_logic = (row[5] or "").strip()
                break

        if not hashdiff_logic or not hashdiff_logic.upper().startswith("HASH:"):
            return  # No HASHDIFF to check

        hd_parts = set(p.strip().upper() for p in hashdiff_logic[5:].split(","))

        # Collect BK alias names and HK names
        bk_names = set()
        hk_names = set()
        for row in column_rows:
            staging_name = (row[8] or "").strip().upper()
            if staging_name.endswith("_BK"):
                bk_names.add(staging_name)
            if staging_name.endswith("_HK"):
                hk_names.add(staging_name)

        excluded = {"BKCC", "REC_SRC", "LOAD_DTS", "PSA_LOAD_DTS", "PSA_RECORD_SOURCE",
                     "_FIVETRAN_SYNCED", "_FIVETRAN_ID"}

        for col in hd_parts:
            if col in bk_names:
                self.errors.append(ValidationError(
                    "ERROR", "MT7_HASHDIFF_CONTENT",
                    f"HASHDIFF contains {col} — BK aliases must be excluded"
                ))
            if col in hk_names:
                self.errors.append(ValidationError(
                    "ERROR", "MT7_HASHDIFF_CONTENT",
                    f"HASHDIFF contains {col} — HK columns must be excluded"
                ))
            if col in excluded:
                self.errors.append(ValidationError(
                    "ERROR", "MT7_HASHDIFF_CONTENT",
                    f"HASHDIFF contains {col} — metadata column must be excluded"
                ))

        # Check PSA_DELETE_IND included if present in source
        source_has_psa_delete = any(
            (row[8] or "").strip().upper() == "PSA_DELETE_IND" for row in column_rows
        )
        if source_has_psa_delete and "PSA_DELETE_IND" not in hd_parts:
            self.errors.append(ValidationError(
                "ERROR", "MT7_HASHDIFF_CONTENT",
                "PSA_DELETE_IND present in source but missing from HASHDIFF (lesson #4)"
            ))

    def _check_mt8_driver_qualify_gating(self, tables_rows, model):
        """MT8: Driver table has NO QUALIFY when grain is valid."""
        grain_valid = self.metadata.get("grain_valid", True)

        # Find driver row (alias=SRC, first row typically)
        driver_filter = ""
        for row in tables_rows:
            alias = (row[2] or "").strip().lower()
            if alias == "src":
                driver_filter = (row[3] or "").strip()
                break

        has_qualify = "QUALIFY" in driver_filter.upper() if driver_filter else False

        if grain_valid and has_qualify:
            self.errors.append(ValidationError(
                "ERROR", "MT8_DRIVER_QUALIFY",
                "Driver has QUALIFY but grain_valid=True — remove unnecessary dedup (lesson #84)"
            ))
        elif not grain_valid and not has_qualify:
            self.errors.append(ValidationError(
                "ERROR", "MT8_DRIVER_QUALIFY",
                "grain_valid=False but driver has no QUALIFY — add dedup to prevent duplicates"
            ))


def validate(config_path, xlsx_path):
    """Convenience function for programmatic use."""
    with open(config_path) as f:
        config = yaml.safe_load(f)
    validator = TechSpecValidator(config, xlsx_path)
    return validator.validate()


def main():
    parser = argparse.ArgumentParser(description="Validate XLSX tech spec against YAML config")
    parser.add_argument("--config", required=True, help="Path to YAML config")
    parser.add_argument("--xlsx", required=True, help="Path to generated XLSX")
    args = parser.parse_args()

    config_path = Path(args.config)
    xlsx_path = Path(args.xlsx)

    if not config_path.exists():
        print(f"ERROR: Config not found: {config_path}")
        sys.exit(1)
    if not xlsx_path.exists():
        print(f"ERROR: XLSX not found: {xlsx_path}")
        sys.exit(1)

    with open(config_path) as f:
        config = yaml.safe_load(f)

    validator = TechSpecValidator(config, str(xlsx_path))
    errors = validator.validate()

    # Build report
    derived_name = config.get("models", [{}])[0].get("derived_name", "unknown")
    print(f"\n=== XLSX Validation Report ===")
    print(f"Model: {derived_name}")
    print(f"XLSX:  {xlsx_path}")
    print()

    # Map errors to check numbers
    check_results = {}
    check_names = {
        "DUPLICATE_STAGING_COLUMN": "1. No duplicate staging names",
        "COLUMN_COUNT_LOW": "2. Column count matches YAML",
        "COLUMN_COUNT_OK": "2. Column count matches YAML",
        "BK_MISSING_YAML": "4. BK row exists",
        "BK_MISSING_XLSX": "4. BK row exists",
        "BK_MANUAL_LOGIC_MISSING": "5. BK manual_logic when CAST",
        "RAW_BK_MISSING": "6. Raw BK retained with alias",
        "HK_MISSING": "8. HK row exists",
        "HK_USES_BK_ALIAS": "9. HK uses raw source names",
        "HK_MISSING_RAW_SOURCE": "9. HK uses raw source names",
        "HK_DUPLICATE": "10. HK appears exactly once",
        "HASHDIFF_DUPLICATE": "11. HASHDIFF appears exactly once",
        "HASHDIFF_EXCLUDES_METADATA": "12. HASHDIFF excludes metadata",
        "HASHDIFF_INCLUDES_METADATA": "12. HASHDIFF excludes metadata",
        "LOAD_DTS_WRONG_SOURCE": "15. LOAD_DTS correct derivation",
        "LOAD_DTS_UNKNOWN_SOURCE": "15. LOAD_DTS correct derivation",
        "HASHDIFF_NOT_LAST": "20. LOAD_DTS appears exactly once",
        "COLUMN_ORDER": "21. Derived fields at bottom",
        "BKCC_TABLE_MISSING": "16. BKCC source row exists",
        "STG_HAS_DELETE_FILTER": "17. No psa_delete_ind=N filter",
        "DRIVER_TABLE_MISSING": "18. Driver table row exists",
        "COLUMN_HEADER_COUNT": "22. Hashdiff column in XLSX header",
        "HASHDIFF_HEADER_POSITION": "22. Hashdiff column in XLSX header",
        "NO_HASHDIFF_FLAGS": "22. Hashdiff column in XLSX header",
        "MT1_TABLE_ROW_COUNT": "MT1. Tables tab row count",
        "MT2_SECONDARY_QUALIFY": "MT2. Secondary QUALIFY dedup",
        "MT3_JOIN_PREDICATE": "MT3. Join predicate valid",
        "MT4_COLLISION_RENAME": "MT4. Collision columns renamed",
        "MT5_BK_RENAME_REF": "MT5. Secondary BK uses renames",
        "MT6_HK_FORMULA": "MT6. HK HASH formulas valid",
        "MT7_HASHDIFF_CONTENT": "MT7. HASHDIFF excludes BK/HK",
        "MT8_DRIVER_QUALIFY": "MT8. Driver QUALIFY gating",
    }

    for error in errors:
        check = check_names.get(error.rule, error.rule)
        check_results[check] = error

    # List all 21 checks
    all_checks = [
        "1. No duplicate staging names",
        "2. Column count matches YAML",
        "3. All source columns present",
        "4. BK row exists",
        "5. BK manual_logic when CAST",
        "6. Raw BK retained with alias",
        "7. All BK columns have unique+not_null",
        "8. HK row exists",
        "9. HK uses raw source names",
        "10. HK appears exactly once",
        "11. HASHDIFF appears exactly once",
        "12. HASHDIFF excludes metadata",
        "13. HASHDIFF includes PSA_DELETE_IND",
        "14. HASHDIFF includes _FIVETRAN_DELETED",
        "15. LOAD_DTS correct derivation",
        "16. BKCC source row exists",
        "17. No psa_delete_ind=N filter",
        "18. Driver table row exists",
        "19. BKCC/REC_SRC from ref_bkcc",
        "20. LOAD_DTS appears exactly once",
        "21. Derived fields at bottom",
        "22. Hashdiff column in XLSX header",
    ]

    # Detect if any MT checks were triggered (multi-table model)
    mt_check_rules = {"MT1_TABLE_ROW_COUNT", "MT2_SECONDARY_QUALIFY", "MT3_JOIN_PREDICATE",
                      "MT4_COLLISION_RENAME", "MT5_BK_RENAME_REF", "MT6_HK_FORMULA",
                      "MT7_HASHDIFF_CONTENT", "MT8_DRIVER_QUALIFY"}
    has_mt_checks = any(e.rule in mt_check_rules for e in errors)

    # Also detect from config: any source with alias not SRC/ref_bkcc and join_type
    if not has_mt_checks:
        for model_cfg in config.get("models", []):
            for src in model_cfg.get("sources", []):
                alias = src.get("alias", "").lower()
                if alias not in ("src", "ref_bkcc", "") and src.get("join_type"):
                    has_mt_checks = True
                    break

    mt_checks = []
    if has_mt_checks:
        mt_checks = [
            "MT1. Tables tab row count",
            "MT2. Secondary QUALIFY dedup",
            "MT3. Join predicate valid",
            "MT4. Collision columns renamed",
            "MT5. Secondary BK uses renames",
            "MT6. HK HASH formulas valid",
            "MT7. HASHDIFF excludes BK/HK",
            "MT8. Driver QUALIFY gating",
        ]
        all_checks.extend(mt_checks)

    passed = 0
    failed = 0
    for check in all_checks:
        if check in check_results:
            error = check_results[check]
            symbol = "❌" if error.severity == "ERROR" else "⚠️"
            print(f"{symbol} {check}")
            print(f"   {error.message}")
            if error.severity == "ERROR":
                failed += 1
            else:
                passed += 1
        else:
            print(f"✅ {check}")
            passed += 1

    print(f"\n=== RESULT: {passed}/{len(all_checks)} PASSED, {failed} FAILED ===")

    # Print any errors from HUB/SAT/LNK model validation (not in numbered checks)
    mapped_rules = set(check_names.keys())
    extra_errors = [e for e in errors if e.rule not in mapped_rules]
    if extra_errors:
        print("\n--- Raw Vault Model Validation ---")
        for e in extra_errors:
            symbol = "❌" if e.severity == "ERROR" else "⚠️"
            print(f"  {symbol} [{e.rule}] {e.message}")

    if not errors:
        print("PASS: All validation checks passed.")
        sys.exit(0)

    error_count = sum(1 for e in errors if e.severity == "ERROR")
    warn_count = sum(1 for e in errors if e.severity == "WARN")

    if error_count > 0:
        print(f"\nFAIL: {error_count} error(s) found. Fix before proceeding to Stage 2.")
        sys.exit(1)
    else:
        print(f"\nWARN: {warn_count} warning(s). Review before proceeding.")
        sys.exit(0)


if __name__ == "__main__":
    main()
