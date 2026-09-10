> **PARKED**: Phase 4 work (PRs #1635-#1640) completed. Retained for
> Business Vault automation phase — reactivate when BV automation begins.
> See lessons #39–#48 for the implemented design decisions.

# Phase 4: Satellite + Business Vault Layers & PR Review Fixes

## Context

PR #1635 (Phase 3 automation scripts) has been merged. Copilot code review
flagged 2 issues that need fixing in this iteration, alongside the next
feature work: extending the automation pipeline to support Satellite (SAT)
and Business Vault (PIT/PB/DIM/FACT) layers.

---

## Part A: PR Review Fixes (from PR #1635)

### Fix 1: Defensive metadata logging in `main.py`

**File**: `scripts/automation/src/main.py` (lines 28–33)  
**Issue**: Direct `meta['key']` indexing — should use `.get()` for safety.  
**Note**: `get_pipeline_metadata()` already returns defaults for all keys,
so this is defensive hardening, not a bug fix.

```python
# BEFORE
logger.info(f"  schema_version: {meta['schema_version']}")
logger.info(f"  bkcc_rec_src: {meta['bkcc_rec_src']}")
logger.info(f"  has_fivetran_deleted: {meta['has_fivetran_deleted']}")
logger.info(f"  has_psa_delete_ind: {meta['has_psa_delete_ind']}")
logger.info(f"  null_bk_coalesced: {meta['null_bk_coalesced']}")
logger.info(f"  large_volume: {meta['large_volume']}")

# AFTER
logger.info(f"  schema_version: {meta.get('schema_version', '1.0')}")
logger.info(f"  bkcc_rec_src: {meta.get('bkcc_rec_src')}")
logger.info(f"  has_fivetran_deleted: {meta.get('has_fivetran_deleted', False)}")
logger.info(f"  has_psa_delete_ind: {meta.get('has_psa_delete_ind', True)}")
logger.info(f"  null_bk_coalesced: {meta.get('null_bk_coalesced', False)}")
logger.info(f"  large_volume: {meta.get('large_volume', False)}")
```

### Fix 2: Misleading auto-commit language in conventional-commit SKILL.md

**File**: `.github/skills/conventional-commit/SKILL.md` (step 5)  
**Issue**: Says "Copilot will automatically run" `git commit` — misleading.  
**Fix**: Reword to instruct user to run the command or confirm before executing.

```markdown
# BEFORE (step 5)
5. After generating your commit message, Copilot will automatically run
   the following command in your integrated terminal (no confirmation needed):

# AFTER (step 5)
5. After generating your commit message, run the following command in your
   integrated terminal to commit:
```

Also update step 6 accordingly:
```markdown
# BEFORE
6. Just execute this prompt and Copilot will handle the commit for you in the terminal.

# AFTER
6. Review the generated message, then execute the git commit command above.
```

**Remember**: After editing `.github/skills/`, run `bash scripts/sync_skills.sh`
and `git add .claude/skills/` to keep the mirror in sync.

---

## Part B: Satellite Layer Automation

### Goal
Extend the pipeline orchestrator to support SAT model generation from the
same YAML config used for v_psa_stg models.

### Design Considerations
- SAT models are **incremental** (not views like v_psa_stg)
- SAT inherits columns from the parent v_psa_stg (data columns + HASHDIFF)
- SAT requires FK constraint to parent hub
- SAT ghost record pattern: `UNION ALL` wrapped in `{% if not is_incremental() %}`
- SAT needs `WHERE NOT EXISTS` for incremental dedup on `<parent>_HK + HASHDIFF`
- SAT YAML needs: `dbt_constraints.primary_key`, `dbt_constraints.foreign_key`,
  `dbt_expectations.expect_table_row_count_to_be_between`

### Tasks
1. Add `generate-sat` command to `pipeline_orchestrator.py`
2. Extend `build.py` SAT layer to read from YAML config (currently XLSX-only)
3. Add SAT sheet generation to `make_yml.py` / XLSX generator
4. Add SAT validation checks to `validate_tech_spec.py`
5. Create SAT-specific tests in `tests/`
6. Update SKILL.md with SAT workflow

---

## Part C: Hub "Add Source" XLSX Workflow

### Gap Identified
During Phase 3 testing, adding a new source to an existing hub (`hub_payment_term`)
was done manually without an XLSX design spec. The XLSX generator already supports
HUB sheets (seen in `v_psa_stg_cost_estimate_header__moen_sap.xlsx`), but the
orchestrator doesn't have a dedicated "add source to existing hub" workflow.

### Tasks
1. Add `hub-add-source` command to orchestrator
2. Auto-detect existing hub model from v_psa_stg model name pattern
3. Generate XLSX with HUB sheet showing new source alongside existing sources
4. Validate: HK formula consistency, DECODE priority, ghost record pattern
5. Generate updated hub SQL preserving existing sources + adding new one

---

## Part D: Business Vault Layers (PIT/PB/DIM/FACT)

### Future scope — design only in this iteration
- PIT: table materialization, joins hub + satellites, business logic lives here
- PB (PIT Bridge): joins multiple hubs/links, complex business rules
- DIM: 1:1 view on PIT — column selection and aliasing only
- FACT: 1:1 view on PB — column selection and aliasing only
- No business logic in DIM/FACT (anti-pattern per CLAUDE.md)

---

## Execution Order

1. Create feature branch: `feature/phase4-sat-bv-automation`
2. Apply Fix 1 + Fix 2 (PR review items)
3. Run `bash scripts/sync_skills.sh` after SKILL.md edit
4. Implement SAT automation (Part B)
5. Implement hub-add-source workflow (Part C)
6. Document Business Vault design decisions (Part D — design only)
7. End-to-end test with a real model
8. PR to main
