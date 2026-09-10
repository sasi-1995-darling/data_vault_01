---
description: "Generate Raw Vault objects (HUB, LNK, SAT) from a v_psa_stg model"
mode: "agent"
tools: ["search", "editFile", "createFile", "runInTerminal"]
---

# Generate Raw Vault Objects

Read the skill at `.github/skills/dv-raw-vault-generator/SKILL.md` first.

Then follow this workflow:

1. Ask which v_psa_stg model to build Raw Vault for (or use $ARGUMENTS)
2. Check if the v_psa_stg exists in `models/int_staging_views/`
3. Ask which objects to generate: HUB / LNK / SAT / ALL
4. For LNK: ask "Which entity HKs does this link connect?"
5. For MSAT: ask "What is the multi-active key column?"
6. For SAT: ask "What is the parent HK and parent model?"
7. Run the pipeline orchestrator with `--objects` and all required params:
   ```bash
   .venv/bin/python3 scripts/automation/pipeline_orchestrator.py init \
     --schema <schema> --table <table> \
     --bk "<bk>" --bk-name "<bk_name>" \
     --rec-src "<rec_src>" \
     --model-name "<v_psa_stg_name>" \
     --objects "stg,hub,sat" \
     --sat-parent-hk "<parent_hk>" \
     --sat-parent-model "<hub_name>" \
     --force
   ```
8. STOP at each approval gate for user review
9. Use `--skip-build` during implement, then run `build-all` once

## Required inputs summary
- **HUB**: nothing (auto-derived from BK name)
- **LNK**: `--parent-hks` + `--lnk-name` (MUST be user-provided)
- **SAT**: `--sat-parent-hk` + `--sat-parent-model`
- **MSAT**: add `--multi-active-key` + `--sat-type msat`
- **LSAT**: add `--sat-parent-model <lnk_name>` + `--sat-type lsat`
