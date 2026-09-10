# Data Vault 2.1 Doctrine (Vendor-Neutral)

> Curated from the CDVP2.1 courseware digest (P1A/P1B/P2A + study guides). This is the
> **"why"** behind the rules. For **FBIN's actual implementation**, always cross-read
> [02-fbin-deviations.md](02-fbin-deviations.md) — several doctrine defaults are
> implemented differently here.

## 1. Core principles

- **100% of the data, 100% of the time.** No filtering at the Raw Vault layer. If you are
  tempted to drop rows, that is a Business Vault or Information Mart concern.
- **Insert-only Raw Vault.** No UPDATEs, no DELETEs. New versions are appended.
  *(FBIN deviation: hubs/links/sats are dbt `incremental` with `delete+insert`; see
  [02](02-fbin-deviations.md).)*
- **Delta (CDC) only in satellites.** Satellites store *changed* rows, never full
  snapshots, never duplicates. Change is detected by `HASHDIFF`.
- **Single parent.** A satellite has exactly ONE parent (a hub HK **or** a link HK).
  Never snowflaked, never SAT-to-SAT.
- **`LOAD_DTS` is a system timestamp** (UTC) of insertion into the vault. It has **no
  business meaning**. Business dates are payload attributes.

## 2. The three (plus) core constructs

| Construct | Holds | Never holds |
|-----------|-------|-------------|
| **Hub** | A business key + its surrogate HK | Descriptive attributes; relationships |
| **Link** | Relationship between 2+ hubs (their HKs) | Descriptive attributes*; business keys |
| **Satellite** | Descriptive attributes for ONE parent | Business keys; relationships |

\* A **transactional / non-historized link** may carry the transaction payload directly
(no satellite) because the event is immutable — see [07-link-modeling.md](07-link-modeling.md).

## 3. Hashing rules (doctrine)

| Rule | Requirement |
|------|-------------|
| Function | Consistent across the entire vault (doctrine default SHA1; **FBIN uses MD5**) |
| Storage | `BINARY(n)` — never `CHAR`/`VARCHAR` |
| NULL handling | `COALESCE(TRIM(CAST(col AS VARCHAR)), '')` before hashing |
| TRIM | Mandatory — whitespace changes the hash |
| Delimiter | A delimiter between every field (`'AB'+'C'` must not equal `'A'+'BC'`) |
| Case | `UPPER()` the concatenated HK string for case-insensitive BK matching |
| **REC_SRC never in HK** | System names change → would force full HK regeneration |
| **BKCC never in HASHDIFF** | BKCC is a structural HK identifier, not a payload descriptor |
| **BK never in HASHDIFF** | BKs live in the hub; repeating them in HASHDIFF is a violation |

## 4. NULL business-key handling (staging layer only)

| Scenario | Rule |
|----------|------|
| Required BK arrives NULL | Replace with sentinel **before** hashing (doctrine `-1`) |
| Optional BK arrives NULL | Replace with sentinel **before** hashing (doctrine `-2`) |
| Never use `'0'` for a real key | Zero may carry business meaning |

*(FBIN uses `^^` as the in-hash NULL/empty sentinel and 0/-1/-2 as **ghost** keys — see
[09-hashing-and-ghosts.md](09-hashing-and-ghosts.md).)*

## 5. Satellite physical column order (authoritative)

`PARENT_HK` → `LOAD_DTS` → `[SUB_SQN / TYPE_CODE]` → `[TENANT_ID]` → `REC_SRC` →
`[HASHDIFF]` → payload columns. **No `LEDT` (Load End Date)** — removed in DV2.1;
end-dating is a *view* concern, not stored.

## 6. Satellite types (doctrine → FBIN prefix)

| Doctrine type | Trigger | FBIN prefix |
|---------------|---------|-------------|
| Standard | Default; delta via HASHDIFF; one per source per parent | `sat_` |
| Link satellite | Descriptive attrs describing a *relationship* | `lsat_` |
| Multi-active (MAS) | Multiple rows active at the same time (e.g. phone numbers) | `msat_` |
| Effectivity | Tracks relationship open/close; driving key; **no payload** | `esat_` |
| Link multi-active | Multi-active attributes on a link | `lmsat_` |
| Non-historized | Immutable event/reference; payload folded into a transactional link | `tlink_` |
| Record-tracking / status | Presence or status column over time | (modeled as `sat_` variants) |

See [05-satellite-variants.md](05-satellite-variants.md) for the full decision guide.

## 7. Satellite split triggers (doctrine)

Split one logical satellite into multiple physical satellites when:

- **Rate of change** — high-frequency columns (scores, prices) separated from
  low-frequency (name, address). Prevents HASHDIFF churn.
- **Type of data** — descriptive vs financial vs contact vs operational.
- **Privacy / PII** — email, SSN, phone segregated for column-level masking.
- **Source boundary** — a different `REC_SRC` with different attributes is a natural split.

Never snowflake; never span two parents. See [06-satellite-splits.md](06-satellite-splits.md).

## 8. Delta load pattern (doctrine)

- Satellites load via **anti-semi join** (`NOT EXISTS` / `WHERE NOT EXISTS`) on
  `PARENT_HK + HASHDIFF`.
- **MAS exception**: no HASHDIFF delta; the full current active set is inserted per batch
  (*FBIN deviation: MSAT `NOT EXISTS` **does** include HASHDIFF — see [02](02-fbin-deviations.md)*).
- Watermark scoped per `REC_SRC`.

## 9. Ghost records (doctrine)

One (doctrine) zero-key ghost per satellite so PIT/outer-join queries never return NULLs:
zero-byte HK, epoch `LOAD_DTS` (`1900-01-01`), NULL payload, full PK populated. *(FBIN
deploys **three** ghosts — 0/-1/-2 — see [09-hashing-and-ghosts.md](09-hashing-and-ghosts.md).)*

## 10. BKCC — Business Key Collision Code

- Resolves enterprise-level BK **non-uniqueness** across source systems.
- Any business concept **except** record source (org/country/brand codes). **Never** the
  system name.
- Stored in its **own column**, never concatenated into the BK.
- **In** the HK (doctrine + FBIN: last component). **Not** in HASHDIFF.

## 11. Effectivity satellite (doctrine)

Tracks a *driving-key* relationship's lifecycle. Columns: `LNK_HK`, `LOAD_DTS`, `REC_SRC`,
`EFFECTIVE_START`, `EFFECTIVE_END` (NULL/open when active), optional `STATUS`. **Never**
descriptive payload — that belongs in standard satellites. *(FBIN's `load_esat` macro uses
`end_date = '9999-12-31'` for the open record rather than NULL — see [05](05-satellite-variants.md).)*

## 12. Same-as link (SAL) & entity resolution

A **same-as link** asserts that two hub records (usually from different sources) are the
*same* real-world entity. It lives in the **Raw Vault** alongside hubs and links.
Survivorship ("which record wins") is an **Information Mart** concern, not the SAL itself.

## 13. Where business logic belongs

- **Raw Vault** = passive integration only (hash + land, no interpretation).
- **Business Vault** = soft rules, derived attributes, multi-source assembly, 3-way
  matches, PIT/Bridge.
- **Information Mart** = business-friendly names, survivorship, filtering. Hash keys are
  **never exposed** in the mart.

## Source traceability

| Topic | CDVP2.1 source |
|-------|----------------|
| Architecture zones, Delta/CDC, LOAD_DTS, Hard Rules | P1A |
| Physical SAT spec, hashing, hard rules | P1B (slides 285–338, 418–482) |
| BKCC, driving key, dependent child | P2A (slides 7–52, 244–277) |
| Effectivity SAT, split rules, MAS | "Satellites in Depth" |
| FBIN production standards, 40-item checklist | SAT Automation Ruleset v6 |
