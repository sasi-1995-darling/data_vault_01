---
description: "Resume an interrupted pipeline from its last completed step"
---

# Resume Pipeline

Pick up an interrupted pipeline from its last completed step.

## Step 1 — Check State

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py status
```

## Step 2 — Identify Next Command

Based on the current state, determine what to run next:

| Last Completed | Next Command |
|----------------|--------------|
| `init` | `profile` |
| `profile` | `show-profile` (then user approves) |
| `approve-profile` | `generate-yaml` then `generate-xlsx` |
| `approve-xlsx` | `generate-code` then `show-code` |
| `approve-code` | `implement --domain <domain>` |

## Step 3 — Execute

Run the next pipeline command and present the output for user review.
If the next step is an approval gate, show the relevant output and ask for confirmation.

## Important

- Always use `.venv/bin/python3` (never bare `python3`)
- Do NOT skip approval gates — present output and wait for user confirmation
- If state is corrupted, suggest `init --force` to restart cleanly
