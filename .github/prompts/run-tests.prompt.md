---
description: "Run the automation test suite"
---

Run the full test suite for the automation platform.

```bash
.venv/bin/python3 -m pytest scripts/automation/tests/ -v --tb=short
```

Expected: the test run completes successfully with no failures.
