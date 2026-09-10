# Implementation Plan — `code_reviewer.py`

> **Source of truth**: `scripts/automation/src/CODE_REVIEW_CHECKS.md` (63 checks, 52 implemented + 11 pending O/P categories)
> **Deliverable**: `scripts/automation/src/code_reviewer.py` + `tests/code_reviewer/` test suite

---

## 1. Architecture

### Module Structure

```
scripts/automation/src/
  code_reviewer.py          # All 46 check functions + CLI entry point
  code_review_config.py     # EXCLUDED_PATHS, .code_review_ignore loader, diff context

scripts/automation/
  .code_review_ignore       # Category G exceptions (CREATED)

tests/code_reviewer/
  conftest.py               # Shared fixtures (sample SQL/YAML strings)
  test_category_a.py        # HK checks (A1-A5)
  test_category_b.py        # HASHDIFF checks (B1-B7)
  test_category_c.py        # CTE structure (C1-C3)
  test_category_d.py        # BKCC (D1-D3)
  test_category_e.py        # Dedup/QUALIFY (E1-E2)
  test_category_f.py        # Date/Timezone (F1-F5)
  test_category_g.py        # Naming (G1-G6)
  test_category_h.py        # Test coverage/YAML (H1-H8)
  test_category_i.py        # Source/Layer (I1-I4)
  test_category_j.py        # Incremental config (J1-J5)
  test_category_k.py        # Ghost records (K1-K5)
  test_category_l.py        # Join patterns (L1-L2)
  test_category_m.py        # Miscellaneous (M1-M4)
```

### Core Data Structures

```python
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional

class Severity(Enum):
    FAIL = "FAIL"
    WARN = "WARN"

class FileStatus(Enum):
    NEW = "new"         # File does not exist on base branch
    MODIFIED = "modified"  # File exists on base branch, changed in PR

@dataclass
class Finding:
    check_id: str          # e.g. "A1", "B5", "J5"
    check_name: str        # e.g. "hk_uses_concat_ws"
    severity: Severity
    file_path: str         # Relative path from repo root
    line_number: Optional[int]  # 1-based, None if file-level
    message: str           # Human-readable description
    suggestion: str = ""   # Optional fix suggestion

@dataclass
class ReviewResult:
    findings: list[Finding] = field(default_factory=list)
    files_checked: int = 0
    files_skipped: int = 0  # Due to EXCLUDED_PATHS or .code_review_ignore

    @property
    def has_failures(self) -> bool:
        return any(f.severity == Severity.FAIL for f in self.findings)

    @property
    def fail_count(self) -> int:
        return sum(1 for f in self.findings if f.severity == Severity.FAIL)

    @property
    def warn_count(self) -> int:
        return sum(1 for f in self.findings if f.severity == Severity.WARN)
```

### Check Function Signature

Every check follows the same contract:

```python
def check_hk_uses_concat_ws(
    sql_content: str,
    file_path: str,
    yaml_content: str | None = None,
    file_status: FileStatus = FileStatus.NEW,
) -> list[Finding]:
    """A1: HK must use CONCAT_WS('||', ...) — not CONCAT or ||."""
    findings = []
    # ... regex/string matching logic ...
    return findings
```

- **Input**: raw file contents (no AST parsing — regex/string matching only)
- **Output**: list of `Finding` objects (empty = check passed)
- **No side effects**: pure function, no file I/O, no DB calls
- **`file_status`**: Used by G4 (link_ prefix) for WARN vs FAIL distinction (CD-1)

### Check Registry

```python
# Maps check_id → (function, applicable_file_patterns, category)
CHECK_REGISTRY: dict[str, CheckEntry] = {
    "A1": CheckEntry(check_hk_uses_concat_ws, ["*.sql"], "A"),
    "A2": CheckEntry(check_hk_coalesce_nullif, ["*.sql"], "A"),
    # ... 56 more ...
}
```

The registry enables:
- Running all checks: `for check_id, entry in CHECK_REGISTRY.items(): ...`
- Running one category: `--category A`
- Running one check: `--check A1`
- Filtering by file type: SQL-only checks skip YAML files

---

## 2. Configuration Layer (`code_review_config.py`)

### CD-2: Path Exclusion

```python
EXCLUDED_PATHS = [
    "models/staging/base/",
    "models/staging/stage/",
]

def is_excluded(file_path: str) -> bool:
    return any(file_path.startswith(p) for p in EXCLUDED_PATHS)
```

### CD-3: `.code_review_ignore` Loader

```python
def load_ignore_list(repo_root: Path) -> list[str]:
    """Load .code_review_ignore — paths exempt from Category G checks."""
    ignore_file = repo_root / "scripts" / "automation" / ".code_review_ignore"
    if not ignore_file.exists():
        return []
    patterns = []
    for line in ignore_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        patterns.append(line)
    return patterns

def is_naming_ignored(file_path: str, ignore_patterns: list[str]) -> bool:
    """Check if file matches any .code_review_ignore pattern."""
    from fnmatch import fnmatch
    return any(fnmatch(file_path, p) for p in ignore_patterns)
```

### CD-1: Git Diff Context

```python
import subprocess

def get_file_statuses(base_branch: str = "origin/main") -> dict[str, FileStatus]:
    """Get new vs modified status for each file in the PR diff."""
    result = subprocess.run(
        ["git", "diff", "--name-status", base_branch, "HEAD"],
        capture_output=True, text=True, check=True
    )
    statuses = {}
    for line in result.stdout.strip().splitlines():
        parts = line.split("\t")
        status_code, file_path = parts[0], parts[-1]
        if status_code.startswith("A"):
            statuses[file_path] = FileStatus.NEW
        else:
            statuses[file_path] = FileStatus.MODIFIED
    return statuses
```

---

## 3. CLI Interface

```
# Review all changed files in PR (default mode)
.venv/bin/python3 scripts/automation/src/code_reviewer.py

# Review specific files
.venv/bin/python3 scripts/automation/src/code_reviewer.py --files models/int_staging_views/foo/v_psa_stg_bar.sql

# Review one category
.venv/bin/python3 scripts/automation/src/code_reviewer.py --category A

# Review one check
.venv/bin/python3 scripts/automation/src/code_reviewer.py --check J5

# Output formats
.venv/bin/python3 scripts/automation/src/code_reviewer.py --format markdown  # PR comment (default)
.venv/bin/python3 scripts/automation/src/code_reviewer.py --format json      # Machine-readable
.venv/bin/python3 scripts/automation/src/code_reviewer.py --format table     # Rich terminal table

# Base branch override (for local testing)
.venv/bin/python3 scripts/automation/src/code_reviewer.py --base-branch main
```

Exit codes:
- `0` = no FAILs (WARNs are OK)
- `1` = one or more FAILs found
- `2` = configuration error (bad paths, missing files)

---

## 4. Output Format (PR Comment)

```markdown
## 🔍 Code Review — Automated Findings

**Result**: ❌ 2 FAIL | ⚠️ 3 WARN | 4 files checked

### ❌ FAIL (blocks merge)

| Check | File | Line | Finding |
|-------|------|------|---------|
| J5 | `sat_supplier__winn_sap.sql` | 45 | Watermark not scoped per REC_SRC — use `GROUP BY REC_SRC` |
| H8 | `v_psa_stg_bom_header__winn_sap.yml` | 12 | `dbt_constraints.primary_key` on view — remove constraint |

### ⚠️ WARN (advisory)

| Check | File | Line | Finding |
|-------|------|------|---------|
| L1 | `v_psa_stg_supplier__winn_sap.sql` | 89 | INNER JOIN without justification comment |
| B3 | `sat_foo.sql` | 34 | Leading `'||'` in HASHDIFF — verify separator placement |
| G4 | `link_plant_item_v1.sql` | — | Legacy `link_` prefix — standard is `lnk_` |
```

---

## 5. Implementation Order (Phase 1 Build Sequence)

Build order optimized for testability — core infrastructure first, then checks by category complexity:

| Step | What | Tests | Est. Checks |
|------|------|-------|-------------|
| 1 | `Finding`/`ReviewResult` dataclasses, `Severity`/`FileStatus` enums | `test_dataclasses.py` | 0 |
| 2 | `code_review_config.py` — EXCLUDED_PATHS, ignore loader, git diff | `test_config.py` | 0 |
| 3 | Check registry + runner loop + CLI scaffolding | `test_runner.py` | 0 |
| 4 | Category G — Naming (G1-G6) | `test_category_g.py` | 6 |
| 5 | Category A — HK (A1-A5) | `test_category_a.py` | 5 |
| 6 | Category B — HASHDIFF (B1-B7) | `test_category_b.py` | 7 |
| 7 | Category H — Test Coverage (H1-H8) | `test_category_h.py` | 8 |
| 8 | Category J — Incremental (J1-J5) | `test_category_j.py` | 5 |
| 9 | Category K — Ghost Records (K1-K5) | `test_category_k.py` | 5 |
| 10 | Categories C, D, E (structure/BKCC/dedup) | `test_category_c/d/e.py` | 8 |
| 11 | Category F — Dates (F1-F5) | `test_category_f.py` | 5 |
| 12 | Categories I, L, M (source/join/misc) | `test_category_i/l/m.py` | 9 |
| 13 | Markdown/JSON output formatters | `test_formatters.py` | 0 |
| 14 | Integration test: run all 46 checks on 1 real repo file | `test_integration.py` | — |

**Rationale for order**: G first because it exercises CD-1/CD-2/CD-3 config. A+B next because they're the most pattern-dense (regex-heavy). H next because it's YAML-only (different parser). J+K for incremental/ghost patterns. The rest follow naturally.

---

## 6. Test Strategy

### Unit Tests (per check)

Each check gets **2 test cases minimum**:
1. **Pass case**: SQL/YAML content that should produce zero findings
2. **Fail case**: SQL/YAML content that should produce exactly one finding with correct check_id, severity, and message substring

```python
# Example: test_category_j.py
def test_j5_pass_per_rec_src_watermark():
    sql = """
    INCR_WATERMARK AS (
        SELECT REC_SRC AS wm_REC_SRC,
               DATEADD(DAY, -1, MAX(LOAD_DTS)) AS watermark_dts
        FROM {{ this }}
        GROUP BY REC_SRC
    )
    """
    findings = check_watermark_scoped_per_rec_src(sql, "models/raw_vault/sat/sat_foo.sql")
    assert findings == []

def test_j5_fail_global_watermark():
    sql = """
    WHERE SRC.LOAD_DTS > (
        SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS))
        FROM {{ this }}
    )
    """
    findings = check_watermark_scoped_per_rec_src(sql, "models/raw_vault/sat/sat_foo.sql")
    assert len(findings) == 1
    assert findings[0].check_id == "J5"
    assert findings[0].severity == Severity.FAIL
```

### Configuration Tests

```python
def test_excluded_paths():
    assert is_excluded("models/staging/base/base_foo.sql") is True
    assert is_excluded("models/bus_vault/pit/stg_pit_foo.sql") is False

def test_naming_ignored():
    patterns = ["models/bus_vault/flat_logic/shipment.sql", "models/bus_vault/flat_logic/t_*.sql"]
    assert is_naming_ignored("models/bus_vault/flat_logic/shipment.sql", patterns) is True
    assert is_naming_ignored("models/bus_vault/flat_logic/t_foo.sql", patterns) is True
    assert is_naming_ignored("models/bus_vault/dim/dim_foo.sql", patterns) is False

def test_link_prefix_new_vs_modified():
    sql = "-- link model"
    # New file → FAIL
    findings = check_link_prefix(sql, "models/raw_vault/link/link_new_thing.sql", file_status=FileStatus.NEW)
    assert findings[0].severity == Severity.FAIL
    # Modified file → WARN
    findings = check_link_prefix(sql, "models/raw_vault/link/link_plant_item_v1.sql", file_status=FileStatus.MODIFIED)
    assert findings[0].severity == Severity.WARN
```

### Integration Test

One real file from the repo, run all 46 checks, assert the total finding count matches expected. This is the "smoke test" that validates the runner loop, registry, and output formatter work end-to-end.

---

## 7. Dependencies

**Python stdlib only** — no new pip packages:
- `re` for regex matching
- `pathlib` for file paths
- `subprocess` for `git diff`
- `dataclasses` for Finding/ReviewResult
- `json` for JSON output
- `fnmatch` for glob patterns in `.code_review_ignore`
- `argparse` for CLI

**Test dependencies** (already in dev requirements):
- `pytest`

**No dependency on**:
- Snowflake connector (not needed — reviewer is file-only, no DB calls)
- `rich` (optional — only for `--format table`)
- `dbt` (no dbt Python API calls — reviewer reads raw SQL/YAML text)

---

## 8. What This Plan Does NOT Cover (Deferred)

| Item | Deferred To |
|------|-------------|
| ~~GitHub Actions workflow~~ (`.github/workflows/code-review.yaml`) | ✅ Done (this PR) |
| ~~PR comment posting via GitHub API~~ | ✅ Done (this PR) |
| Auto-approve when 0 FAILs | Phase 2 |
| `manifest.json` lineage-aware checks | Phase 2 |
| `run_results.json` performance regression detection | Phase 2 |
| Audit logging (JSONL per PR) | Phase 2 |
| LLM-as-judge / semantic checks | Phase 3+ |
| Golden-file regression tests for pipeline_orchestrator | Parallel workstream |

---

## 9. Approval Gate

This plan is ready for implementation. Next action:

1. Create `code_review_config.py` (Step 2)
2. Create `code_reviewer.py` scaffold with dataclasses + registry + CLI (Steps 1+3)
3. Implement Category G checks first (exercises all 3 configuration decisions)
4. Iterate through remaining categories (Steps 5-12)
5. Add output formatters (Step 13)
6. Integration smoke test (Step 14)
