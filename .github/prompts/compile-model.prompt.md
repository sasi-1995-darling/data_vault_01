---
description: "Compile a single dbt model and show the rendered SQL"
---

# Compile Model

Compile a dbt model and display the rendered SQL output.

```bash
dbt compile -s $ARGUMENTS
```

If `$ARGUMENTS` is empty, use the currently open file's model name (derive from filename).

## After Compilation

1. Read the compiled SQL from `target/compiled/dbt_datavault/models/...`
2. Display the full compiled SQL to the user
3. Highlight any Jinja rendering issues or missing refs
