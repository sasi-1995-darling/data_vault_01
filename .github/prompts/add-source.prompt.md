---
name: add-source
description: "Add a new source to an existing HUB or LNK model"
mode: "agent"
tools: ["search", "read", "runInTerminal", "editFile", "createFile"]
---

# Add Source to Existing Hub or Link

Add a new source system to an existing hub or link model. The orchestrator detects
existing models via collision check and routes to the add-source workflow.

## Workflow

1. Run `init` with `--objects "stg,hub"` (or `"stg,lnk"`)
2. The collision check detects the existing hub/link and routes to add-source
3. The orchestrator shows BK column mapping for confirmation
4. After approval, surgical CTE insertion preserves existing sources

## Example

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py init \
  --schema NEW_SCHEMA --table NEW_TABLE \
  --bk "NEW_ID" --bk-name "ENTITY_BK" \
  --rec-src "LOC.SYS.APP.TABLE" \
  --model-name "v_psa_stg_entity__new_source" \
  --objects "stg,hub"
```

## Notes

- The collision check uses BKCC to detect whether a hub/link already exists
- Existing model SQL is preserved; new source is added as an additional CTE
- Always confirm the BK column mapping before proceeding
