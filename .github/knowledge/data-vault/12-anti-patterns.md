# Anti-Patterns Catalog (Quick Reference)

> A scannable "don't do this" index. Each entry links to the fuller treatment. Use this as a
> fast pre-generation checklist; use [08-modeling-traps.md](08-modeling-traps.md) for the
> deep symptom→cause→fix analysis.

## Modeling shape

| Anti-pattern | Why it's wrong | Do instead |
|--------------|----------------|-----------|
| **One hub per source table** | Hubs are business keys, not tables; blocks integration | One hub per business key; many sources feed it → [03](03-construct-selection.md) |
| **Hub for a dependent child** (line number alone) | Not unique without its parent | Composite BK, degenerate attr, or SAT-PK → [04](04-grain-and-bk-selection.md#dependent-children) |
| **Descriptive attributes on a link** | Links hold keys, not descriptions | Move to a `lsat_` → [07](07-link-modeling.md) |
| **Collapsed wide UoW link** across non-co-occurring keys | Orphans rows | Separate pairwise links; assemble in BV → [07](07-link-modeling.md#the-co-occurrence-test-wide-uow-vs-separate-links) |
| **N-way match as one raw link** | Interpretive logic in the RV | Assemble in PIT/Bridge → [10](10-business-vault.md) |
| **SAT with two parents / snowflaked** | Breaks single-parent rule | One parent per sat; different concept → different sat → [05](05-satellite-variants.md) |
| **MAS reached for a dependent child** | Wrong pattern for the problem | Line-as-hub or link → [04](04-grain-and-bk-selection.md), [05](05-satellite-variants.md) |

## Keys & hashing

| Anti-pattern | Why it's wrong | Do instead |
|--------------|----------------|-----------|
| **Mutable / smart / source-specific natural key** as hub BK | History re-keys; can't conform | Surrogate immutable ID + BKCC/REC_SRC → [04](04-grain-and-bk-selection.md#the-disqualifiers-a-candidate-bk-fails-if-any-are-true) |
| **Naive composite-BK link HK** | Byte-collides with the line hub HK | Compose from hub HK values (`TO_VARCHAR(hub_HK)`, post-#1907) — no raw components, no collision; legacy fix duplicated the leading component → [08 TRAP-01](08-modeling-traps.md#trap-01--composite-bk-link-hk-collides-with-the-line-hub-hk) |
| **Foreign HK built with local BKCC** | Silent non-join | Use the owning hub's BKCC → [08 TRAP-02](08-modeling-traps.md#trap-02--cross-domain-foreign-hk-built-with-the-wrong-bkcc) |
| **BKCC hardcoded in SQL** | Drifts from governance | Look up `REF_BUSINESS_KEY_COLLISION` → [09](09-hashing-and-ghosts.md) |
| **REC_SRC or BKCC inside a HASHDIFF** | Structural in a payload hash | Exclude from HASHDIFF → [09](09-hashing-and-ghosts.md) |
| **BK/HK/grain columns in the sat PK / grain test** | Masks true duplicates | PK = `*_HK` + `LOAD_DTS` only → [08 TRAP-07](08-modeling-traps.md#trap-07--hashdiff-or-grain-test-placed-in-the-satellite-pk) |
| **BKCC concatenated into the BK column** | Parsing tech debt | Keep BKCC in its own column → [01](01-doctrine-dv21.md) |

## Loads & layer discipline

| Anti-pattern | Why it's wrong | Do instead |
|--------------|----------------|-----------|
| **Filtering `PSA_DELETE_IND` / `_FIVETRAN_DELETED` at staging** | Drops deletion history; breaks 100% data | Keep as data in HASHDIFF → [08 TRAP-08](08-modeling-traps.md#trap-08--filtering-delete-flags-at-the-staging-layer) |
| **MSAT `NOT EXISTS` without HASHDIFF** (FBIN) | Duplicate multi-active rows | Include HASHDIFF in the guard → [02](02-fbin-deviations.md), [08 TRAP-09](08-modeling-traps.md#trap-09--multi-active-satellite-missing-the-hashdiff-guard-fbin) |
| **`source()` inside the raw vault** | Layer-direction violation | `ref('v_psa_stg_…')`; only BKCC ref model is exempt → [08 TRAP-11](08-modeling-traps.md#trap-11--reference-source-source-used-inside-the-raw-vault) |
| **Business logic in DIM/FACT** | Diverging report logic | All logic in PIT/PB; DIM/FACT select+alias → [10](10-business-vault.md) |
| **`SELECT DISTINCT` for dedup** | Non-deterministic, hides grain problems | `QUALIFY ROW_NUMBER()` → [02](02-fbin-deviations.md) |
| **Exposing hash keys in the Information Mart** | Leaks internal surrogates | Business keys + attributes only → [10](10-business-vault.md) |
| **Converting legacy 6-layer CTEs to 4-layer** | Needless churn/risk on 448+ models | 4-layer for **new** models only → [02](02-fbin-deviations.md) |

## Process

| Anti-pattern | Why it's wrong | Do instead |
|--------------|----------------|-----------|
| **Advisor auto-deciding** construct/grain/BK/domain/naming | Violates the delegation mandate | Present options; the user decides → `CLAUDE.md` |
| **Generating SQL/YAML/XLSX by hand** | Bypasses the state machine & checks | Use `pipeline_orchestrator.py` → `03-pipeline-automation` rule |
| **Skipping BKCC registration** before `dbt build` | HKs regenerate; build fails | Register REC_SRC+BKCC in DEV first → [09](09-hashing-and-ghosts.md) |
| **Reasoning from generic DV** without checking FBIN deviations | Canon-correct, repo-wrong | Cross-read [02-fbin-deviations.md](02-fbin-deviations.md) every time |

## The 60-second pre-generation checklist

1. Grain stated in one sentence? BK survives the five disqualifiers?
2. Every hub a business key; every link passes co-occurrence; every sat single-parent + single-source?
3. Link HK composed from hub HK values (no raw-component collision)? Foreign HKs use owning-hub BKCC?
4. Satellite splits considered (rate-of-change / PII / type / source)?
5. Multi-way matches deferred to the BV? DIM/FACT logic-free?
6. HASHDIFF include/exclude correct? Delete flags kept as data?
7. FBIN deviations checked ([02](02-fbin-deviations.md))? BKCC registered?
8. Did you present the decisions to the user instead of deciding for them?
