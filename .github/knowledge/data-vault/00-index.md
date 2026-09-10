# FBIN Data Vault 2.x — Modeling Knowledge Base

> **Purpose**: The canonical, curated corpus of Data Vault 2.x **modeling** knowledge
> for FBIN, grounded in this repo's actual conventions. This is the "brain" that the
> **DV Knowledge Advisor** agent reads, and that humans consult during design.
>
> **Scope**: Conceptual / design-level modeling — construct choice, grain, business-key
> selection, satellite splits, link modeling, hashing traps. This is deliberately the
> layer that `code_reviewer.py` (syntax) and the pipeline orchestrator (mechanics)
> do **not** cover.

## How to use this knowledge base

| You are... | Read... |
|------------|---------|
| Deciding **hub vs link vs satellite** | [03-construct-selection.md](03-construct-selection.md) |
| Choosing the **grain / business key** | [04-grain-and-bk-selection.md](04-grain-and-bk-selection.md) |
| Picking a **satellite variant** (standard/MAS/effectivity/…) | [05-satellite-variants.md](05-satellite-variants.md) |
| Deciding whether to **split a satellite** | [06-satellite-splits.md](06-satellite-splits.md) |
| Modeling a **relationship / link** | [07-link-modeling.md](07-link-modeling.md) |
| Debugging a **hash collision / BKCC** problem | [08-modeling-traps.md](08-modeling-traps.md) |
| Writing **HK / HASHDIFF / ghost** logic | [09-hashing-and-ghosts.md](09-hashing-and-ghosts.md) |
| Building **PIT / Bridge / DIM / FACT** | [10-business-vault.md](10-business-vault.md) |
| Wanting a **worked example** | [11-worked-examples.md](11-worked-examples.md) |
| Checking **"is this an anti-pattern?"** | [12-anti-patterns.md](12-anti-patterns.md) |

## The two foundational files (read these first)

1. **[01-doctrine-dv21.md](01-doctrine-dv21.md)** — the vendor-neutral Data Vault 2.1
   doctrine (CDVP2.1). The "why" behind the rules.
2. **[02-fbin-deviations.md](02-fbin-deviations.md)** — **READ THIS.** Where FBIN's
   *actual implementation* differs from generic doctrine. Generic-but-repo-wrong advice
   is the #1 way an advisor misleads. When doctrine and FBIN conflict, **FBIN wins**
   inside this repo.

## Precedence (source of truth order)

When two sources disagree, resolve in this order:

1. `scripts/automation/lessons.md` → `## Approved` section (authoritative, versioned)
2. `.github/instructions/*` and `.claude/rules/*` (enforced standards)
3. `02-fbin-deviations.md` (this KB's reconciliation of repo reality)
4. `01-doctrine-dv21.md` (generic DV 2.1 doctrine)
5. External DV literature (Linstedt, Cuba/DVOS, Data Vault Alliance)

> If this KB ever contradicts an `## Approved` lesson, the lesson is correct and this
> KB must be corrected. File the discrepancy; do not silently follow the KB.

## Source provenance

This KB was curated from:

- **CDVP2.1 courseware digest** (`dv21_knowledge_bank.md`, P1A/P1B/P2A + study guides)
- **Repo standards**: `.claude/rules/01–05`, `.github/instructions/*`, `CLAUDE.md`,
  `.github/copilot-instructions.md`
- **Approved lessons**: `scripts/automation/lessons.md`
- **Design records**: `docs/dv_purchase_order.md`, `docs/dv_sales_invoice.md`,
  `docs/lessons_learned.md`
- **Verified modeling memory**: hard-won facts from prior sessions (e.g., the supplier /
  AP-invoice build, PR #1908 composite-BK collision).

### Enrichment TODO (sources offered, not yet ingested)

These would deepen specific sections when shared:

- [ ] **CDVP2.1 courseware** (P1B slides 285–338 hashing, 418–482 physical SAT + hard
      rules; P2A slides 7–52 BKCC, 244–277 driving key) → deepens
      [05](05-satellite-variants.md), [07](07-link-modeling.md), [09](09-hashing-and-ghosts.md).
- [ ] **SAT Automation Ruleset v6** (the 40-item checklist) → deepens
      [05](05-satellite-variants.md), [06](06-satellite-splits.md), [12](12-anti-patterns.md).

Drop those files anywhere in the repo (or share them) and the corresponding sections
will be expanded with slide-level traceability.

## Maintenance rules

- This KB is **descriptive of FBIN reality**, not aspirational. Do not add rules the repo
  does not actually follow.
- Every FBIN-specific claim should be traceable to a rule file, an Approved lesson, or a
  real model. Add the citation inline.
- When a modeling trap is discovered in production, add it to
  [08-modeling-traps.md](08-modeling-traps.md) with the symptom, root cause, and fix.
- The **DV Knowledge Advisor never edits models and never decides for the user** — it
  cites this KB and presents options. See `.github/agents/dv-knowledge-advisor.agent.md`.
