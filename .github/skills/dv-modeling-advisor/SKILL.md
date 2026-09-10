---
name: dv-modeling-advisor
description: >
  Conceptual Data Vault 2.x modeling guidance for FBIN — construct choice
  (hub/link/satellite), grain and business-key selection, satellite splits,
  link modeling, and the hash-collision / BKCC traps that pass syntax review
  but corrupt data. Use when designing or generating DV models, choosing a
  grain or business key, deciding a satellite variant or split, or modeling a
  relationship. This is the DESIGN layer that the syntactic code reviewer and
  the mechanical pipeline orchestrator do not cover. Points to the canonical
  knowledge base at .github/knowledge/data-vault/.
allowed-tools: "Read Grep Glob"
activation: auto
disable-model-invocation: false
paths:
  - "models/raw_vault/**"
  - "models/int_staging_views/**"
  - "models/bus_vault/**"
  - "scripts/automation/configs/**"
arguments: "$ARGUMENTS may contain a source table, model name, or design question"
metadata:
  author: FBIN Data Engineering
  version: 1.0.0
  category: data-vault
---

# DV Modeling Advisor (skill)

> **Canonical knowledge lives in `.github/knowledge/data-vault/`.** This skill is a thin
> activator that brings the *conceptual* modeling checklists into view while you work on
> model files. Read the KB files it points to — do not improvise FBIN specifics.
>
> For interactive Q&A / design review, the **DV Knowledge Advisor** agent
> (`.github/agents/dv-knowledge-advisor.agent.md`) is the full read-only expert.

## When this matters

You are about to make a **design decision** that the pipeline will faithfully generate —
right or wrong. The orchestrator enforces *mechanics*; `code_reviewer.py` enforces *syntax*;
**neither checks whether the model is conceptually correct.** That's this skill's job.

## The 60-second pre-generation checklist

1. **Grain** — can you state it in one sentence? (`04-grain-and-bk-selection.md`)
2. **Business key** — does it survive the five disqualifiers (mutable / non-conformable /
   needs-missing-column / recycled / smart-key)? (`04`)
3. **Construct** — every hub a business key (not a table); every link passes the
   **co-occurrence test**; every satellite single-parent + single-source? (`03`, `07`)
4. **Satellite variant** — standard / `msat_` / `esat_` / `lmsat_` / `lsat_` / `tlink_`?
   (`05`) And should it **split** (rate-of-change / PII / type / source)? (`06`)
5. **Hashing traps** —
   - Link HK composed from hub HK values (no raw-component byte-collision with the line hub HK)? (**TRAP-01**)
   - Foreign HKs built with the **owning hub's** BKCC, not the local one? (**TRAP-02**)
   - HASHDIFF include/exclude correct; delete flags kept as **data**? (`09`, TRAP-06/08)
6. **Layer discipline** — multi-way matches deferred to the Business Vault; DIM/FACT
   logic-free? (`10`, TRAP-03/10)
7. **FBIN deviations** — checked `02-fbin-deviations.md`? BKCC registered in
   `REF_BUSINESS_KEY_COLLISION`?
8. **Delegation** — are you **presenting** the design decisions to the user rather than
   deciding for them? (`CLAUDE.md` mandate)

## Fast routing

| The decision in front of you | Read |
|------------------------------|------|
| Hub vs link vs satellite | `03-construct-selection.md` |
| Grain / natural vs surrogate BK / composite / dependent child | `04-grain-and-bk-selection.md` |
| Which satellite flavor | `05-satellite-variants.md` |
| Split or not | `06-satellite-splits.md` |
| Wide UoW vs separate links / driving key / SAL / cross-domain HK | `07-link-modeling.md` |
| "Is this a known trap?" | `08-modeling-traps.md` |
| HK / HASHDIFF / ghost / LOAD_DTS mechanics | `09-hashing-and-ghosts.md` |
| PIT / Bridge / DIM / FACT placement | `10-business-vault.md` |

## Hard rules this skill reinforces

- **Never decide for the user.** Present options + trade-offs + a recommendation, then ask.
- **Never generate models by hand.** Design here; generate via `pipeline_orchestrator.py`.
- **Never give generic-DV advice without checking `02-fbin-deviations.md`.**
- **Never edit models** to "fix" a conceptual finding — surface it and let the user decide.

## Handoff

- Ready to generate → **DV Pipeline Coordinator** (enforces the state machine + STOP gates).
- Want deep Q&A / conceptual review → **DV Knowledge Advisor** agent.
- Syntactic / formula compliance → `dv-code-reviewer` skill + `code_reviewer.py`.
