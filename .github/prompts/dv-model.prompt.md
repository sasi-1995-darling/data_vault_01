---
name: dv-model
description: "Define a construct in detail: choose the satellite variant (sat/lsat/msat/lmsat/esat/rsat), decide satellite splits from measured change rates, and check naming against FBIN conventions. Design only."
mode: "agent"
tools: ["search", "read"]
---

# /dv-model — Construct detail, satellite variant, splits, naming

**Invoke as:** `/dv-model <entity or hub name>` — e.g. `/dv-model hub_supplier_invoice`

You operate in **Pattern Recommender + Naming Advisor** mode (these are *modes*, not separate
subagents — keep it in one context; dispatch boundaries cost cache cold-starts).

> **Tooling note — read-only.** This command has `search`/`read` tools only: it **cannot query
> the warehouse or compute change rates itself**. When Step 2 calls for measured per-column
> change frequency, those numbers must come from profiling / version-diff output **you
> provide**. If you weren't given them, say so and mark the split recommendation **UNVERIFIED**
> — **do not invent** change-rate percentages. (Need live measurement? The pipeline
> orchestrator has warehouse reach — run it there, then bring the numbers back here.)

**Read first (`.github/knowledge/data-vault/`):** `05-satellite-variants.md`,
`06-satellite-splits.md`, `07-link-modeling.md`, `02-fbin-deviations.md`,
`08-modeling-traps.md` (TRAP-05, TRAP-07, TRAP-09)

## Step 1 — Choose the variant (`05` §"Variant decision guide")

| Variant | Use when | FBIN specifics |
|---|---|---|
| `sat_` | Standard descriptive payload | Grain `(parent_HK, LOAD_DTS)` (`05` §"Standard satellite") |
| `lsat_` | Payload hangs off a **link** | Grain `(link_HK, LOAD_DTS)` |
| `msat_` / `lmsat_` | **Multi-active** — several rows active at once per key | Grain adds the multi-active key; **`NOT EXISTS` MUST include HASHDIFF** (TRAP-09; `05` §"Multi-active satellite") |
| `esat_` | **Effectivity** — relationship opens/closes | Driving key + `end_date '9999-12-31'` (FBIN deviation; `05` §"Effectivity satellite") |
| `rsat_` | Record-tracking / reference | — |

For a satellite that hangs off a **same-as** or **transactional** link, confirm the parent is
the link HK and that a transactional link's payload is treated as immutable (often
non-historized) — see `07` §"Same-as links (SAL)" and §"Transactional links". State *why* the
variant fits.

## Step 2 — Satellite splits (measure, don't guess) — `06` §"The four split triggers"

- **Rate of change** (`06` §"Rate of change") — the strongest trigger, and **measurable**. If
  the source is versioned, compute per-column change frequency across versions. A column
  churning ~50×+ faster than the descriptive core belongs in its own satellite, or every flip
  re-versions the whole wide satellite. **If you can measure it, measure it; if you can't, say
  so and mark the recommendation unverified.**
- **Type of data** (`06` §"Type of data") — financial vs descriptive vs operational vs status.
- **Privacy / PII** (`06` §"Privacy / PII") — PII in a separate satellite. *FBIN nuance:* with
  tag-based masking and automatic propagation, a mixed satellite does **not** block masking
  here — so treat the PII split as satellite hygiene, not a hard masking requirement.
  (Category Q2 will still WARN on it.)
- **Source boundary** (`06` §"Source boundary (FBIN hard rule)") — different REC_SRC with
  different attributes = natural split.

Always confirm **single-parent, single-source** (`05` §"The single-parent rule",
`06` §"The single-parent guardrail"). Cross-domain columns in one satellite is a violation,
not a style choice.

## Step 3 — Naming check

Against FBIN conventions (the same rules Category **G** enforces after generation):
correct prefix · `<entity>__<source>` double underscore · UPPERCASE columns, lowercase tables ·
hub/link/sat prefix matches the construct.

## Ghost sentinels (TRAP-05)

`0 / -1 / -2` mean **different things** by construct — hub/sat: SYSTEM / nullkey-required /
nullkey-optional; link: unknown / not-applicable / error. Use the construct-appropriate DECODE
labels when you describe ghost rows.

## Output shape

```
## /dv-model — <entity>

### Variant
<entity> → **<sat_|msat_|esat_|…>** because <trigger>            (05 §…)
  ⚠ msat/lmsat → NOT EXISTS must include HASHDIFF                (TRAP-09)
  ⚠ esat      → driving key + '9999-12-31' end_date              (FBIN deviation)

### Split recommendation
<measured change rates if available>
  <COL_A>  <x.xx%>  → split to sat_<entity>_status__<src>
  <COL_B>  <x.xx%>  → descriptive core
Rationale: <why this boundary>   [VERIFIED by measurement | UNVERIFIED — not measured]

### Naming
sat_<entity>__<src>  ✓/✗   (G-convention: <note>)

### Decisions needed from you
1. <question>
```

**Never** emit SQL/YAML/XLSX. Next: `/dv-validate <design>`, then the DV Pipeline Coordinator
generates.
