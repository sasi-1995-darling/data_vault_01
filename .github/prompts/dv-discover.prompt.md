---
name: dv-discover
description: "Name a source table (+ grain) → proposed DV Raw Vault design: hubs, links, satellites, with business-key disqualifiers and trap flags. Reasons over profiling output / DDL you provide — this command is read-only and cannot query the warehouse itself; every unverified claim is marked. Design only — no SQL/YAML generated."
mode: "agent"
tools: ["search", "read"]
---

# /dv-discover — Source → Raw Vault design proposal

**Invoke as:** `/dv-discover <db.schema.table[, table2]>[, grain = <one row = ?>]`
e.g. `/dv-discover PSA_PROD.ML_EBS_AP.AP_INVOICES_ALL, AP_INVOICE_LINES_ALL — grain: one invoice header / one invoice line`

You operate in **Source Profiler + Construct Selector** mode. Given a source table name (and
optionally its grain) plus whatever profiling you can supply, **analyze it and propose the
FBIN Raw Vault design**.

> **Tooling note — read-only.** This command has `search`/`read` tools only: it **cannot query
> the warehouse or pull DDL itself**. It reasons over profiling output, DDL, or sample rows
> **you paste in**. For any data point you haven't provided, say so up front and mark the
> claim `?` — **do not estimate or invent** row counts / null rates. A guessed null rate that
> looks authoritative is worse than a blank one. (Need live profiling? The pipeline
> orchestrator has warehouse reach — run it there, then bring the numbers back here.)

**Read first (`.github/knowledge/data-vault/`):** `03-construct-selection.md`,
`04-grain-and-bk-selection.md`, `07-link-modeling.md`, `08-modeling-traps.md`,
`02-fbin-deviations.md`

## Step 1 — Profile (evidence, not assumption)

For each named table, establish and **tag every claim VERIFIED (backed by profiling output,
query results, DDL, or sample rows you were given) or INFERRED (from source semantics / naming
only — no supporting data provided)**:

- Row count; distinct count of each candidate business key
- **Null rate** on every candidate BK
- **Uniqueness at business grain** — note if the landing table is versioned/append-only
  (PSA is), so uniqueness statements are about the grain *after* staging dedup
- **Mutability**: does the candidate BK ever change for the same entity across versions?
  (This is the TRAP-04 test — check it against the versioned data, don't assume)
- Relationship cardinality and, critically, **co-occurrence**: what % of child rows have a
  NULL parent key? Break down by type/category if one exists
- Ingestion signals (`_FIVETRAN_SYNCED` / `GLCHANGETIME` / PSA columns) → LOAD_DTS derivation

## Step 2 — Propose constructs

- **Hubs** — one per business concept with an **immutable, conformable** BK. Run the
  disqualifiers (`04` §"The disqualifiers (a candidate BK fails if ANY are true)"): user-editable?
  smart-coded? source-specific? non-unique? If any hold, flag **TRAP-04** and recommend the
  surrogate system id instead, namespaced by BKCC + REC_SRC. See `04` §"Natural vs surrogate".
- **Links** — apply the **co-occurrence test** (`07` §"The co-occurrence test"). If participants
  are NOT always present together (measured, not assumed), do **not** propose a wide UoW link:
  propose pairwise links and assemble the multi-way match in the Business Vault (**TRAP-03**).
  Also consider the non-standard link types when the data fits them:
  - **Same-as link (SAL)** — when the same real-world entity arrives under different keys
    across sources and must be reconciled (`07` §"Same-as links (SAL)").
  - **Transactional link** — an immutable event/transaction relationship that never changes
    once recorded (`07` §"Transactional links"); often pairs with a non-historized pattern.
- **Satellites** — single-parent, single-source, per source system.
- **Dependent children** — a composite-BK child (e.g. `PARENT_ID + LINE_NUMBER`) becomes its
  own hub with the composite BK (`04` §"Dependent children").

## Step 3 — Flag the traps with evidence

- **TRAP-01** — if a composite-BK entity feeds a link, the link HK **must** duplicate the
  shared leading component: `(PARENT_ID, PARENT_ID, LINE_NUMBER, BKCC)` → `'A||A||B||C'`.
  A naive `(PARENT_ID, LINE_NUMBER, BKCC)` hashes **byte-identical** to the line hub HK →
  silent join corruption. The duplicate is intentional; never "clean it up." See `08`
  §"TRAP-01 — Composite-BK link HK collides with the line hub HK". *(Category Q1 catches this
  only as a single-file syntactic subset — your cross-model reasoning is authoritative where
  they disagree.)*
- **TRAP-02** — any foreign hub HK must use the **owning hub's** BKCC and exact column order,
  not the local model's, or it silently never joins (`07` §"Cross-domain link HK composition").
- **TRAP-03** — measured co-occurrence failure → pairwise links + BV assembly.
- **TRAP-04** — mutable / non-conformable BK.

## FBIN mechanics (not generic DV)

MD5_BINARY → BINARY(16) · `MD5_BINARY(UPPER(CONCAT_WS('||', …)))` · `^^` in-hash sentinel ·
BKCC **last**, looked up from `ref_business_key_collision`, never hardcoded · delete+insert,
never MERGE · staging `source()`, downstream `ref()` · UPPERCASE columns, lowercase tables.

## Output shape

```
## /dv-discover — <source>

### Profile (VERIFIED / INFERRED tagged)
<table>: <rows>, BK <col> — <nulls>, <distinct>, mutable? <evidence>   [VERIFIED]
Relationship <a>→<b>: <cardinality>, co-occur <%>                      [VERIFIED]

### Confirmed grain
- <table>: one row = <grain>   [confirm?]

### Proposed constructs
HUB   hub_<x>            BK <…>        — <why>            (04 §…)
HUB   hub_<x>_line       BK <…>|<…>    — dependent child  (04 §…)
LINK  lnk_<x>_line       <a> ↔ <b>     — co-occur YES     (07 §…)
SAT   sat_<x>__<src>                   — single-parent    (05 §…)

### ⚠ Traps flagged (with evidence)
TRAP-0X  <what> — <measured evidence> — fix: <…>

### Options with trade-offs
Option 1 — <scope> · pro <…> · con <…>
Option 2 — <scope> · pro <…> · con <…>

### Decisions needed from you
1. <question>
```

**Never** emit SQL/YAML/XLSX and never run dbt. Design only. When the design is confirmed,
the **DV Pipeline Coordinator** generates it. Next step: `/dv-model <entity>`.
