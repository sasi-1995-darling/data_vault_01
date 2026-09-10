---
description: "Check the current pipeline orchestrator state and show next steps"
---

# Check Pipeline Status

Show the current state of the pipeline orchestrator and what step is next.

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py status
```

## Output Interpretation

Present the output as a formatted summary:
- **Current step**: which stage the pipeline is at
- **Model name**: the model being generated
- **Next action**: what the user needs to do next (approve, run next command, etc.)
- **Blockers**: any STOP gates waiting for user input

If no pipeline is active, report: "No active pipeline. Run `init` to start a new model."
