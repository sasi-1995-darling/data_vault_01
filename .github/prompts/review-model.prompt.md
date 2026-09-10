---
description: "Run the 52-check DV standards code reviewer on a model file"
---

# Review Model Against DV Standards

Run the FBIN deterministic code reviewer against the specified file(s).

## How to Run

```bash
.venv/bin/python3 scripts/automation/src/code_reviewer.py --files $ARGUMENTS
```

If `$ARGUMENTS` is empty, review the currently open file (use its workspace-relative path).

## Interpret Results

- **FAIL** = blocks merge. Must be fixed before PR.
- **WARN** = advisory. Review and fix if appropriate.

Present findings grouped by severity (FAIL first, then WARN).
For each finding, show: check ID, file name, line number, what's wrong, and how to fix it.

If all checks pass, confirm:
```
✅ All checks passed. Model is standards-compliant.
```

## Common Check Categories

| Cat | Area | Examples |
|-----|------|----------|
| A | Hash Key formula | CONCAT_WS, COALESCE/NULLIF/TRIM, raw columns, BKCC last |
| B | HASHDIFF formula | IFNULL/TRIM, separator, exclusions, PSA_DELETE_IND |
| C | CTE structure | 4-layer pattern, no nonstandard names |
| D | BKCC standards | JOIN ON '1'='1', from ref table |
| E | Dedup & QUALIFY | No SELECT DISTINCT, ROW_NUMBER pattern |
| F | Date & timezone | CONVERT_TIMEZONE('UTC'), 1900-01-01 placeholder |
| G | Naming | Prefix rules, uppercase columns |
| H | Test coverage | data_tests (not deprecated tests:) |
| I | Source integrity | source()/ref() usage |
| J | Incremental config | NOT EXISTS guard patterns |
| K | Ghost records | DECODE pattern, 3 sentinels |
| L | Join patterns | INNER JOIN comment required |
| M | Miscellaneous | No hardcoded env, REC_SRC format |
| N | Staging integrity | No delete-flag filter, COALESCE on payload |
