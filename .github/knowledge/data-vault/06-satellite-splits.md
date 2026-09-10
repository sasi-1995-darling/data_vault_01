# Satellite Splits — When One Satellite Becomes Many

> **Priority topic** (top pain point). Splitting is about *rate of change*, *data type*,
> *privacy*, and *source*. Under-splitting causes HASHDIFF churn and masking headaches;
> over-splitting causes join sprawl. This is a judgment call — the advisor **presents the
> trigger analysis and lets the user decide**.

## The four split triggers

Split one logical satellite into multiple physical satellites when **any** of these apply:

| Trigger | Symptom if you DON'T split | Example |
|---------|----------------------------|---------|
| **Rate of change** | Every price tick rewrites the whole wide row → HASHDIFF churn, storage blowup | Fast: `price`, `score`, `qty_on_hand`. Slow: `name`, `address` → separate sats |
| **Type of data** | Unrelated domains version together; hard to reason about | Descriptive vs financial vs contact vs operational |
| **Privacy / PII** | Cannot apply column-level masking to a subset | `email`, `ssn`, `phone` → dedicated PII satellite |
| **Source boundary** | Two sources with different attrs fight over one HASHDIFF/watermark | Different `REC_SRC` = different satellite (FBIN hard rule) |

## Rate of change (the most common miss)

If a satellite mixes a column that changes **hourly** with columns that change **yearly**,
every hourly change forces a new full version row (because HASHDIFF covers the whole
payload). Split the volatile columns into their own satellite so the stable columns version
only when they actually change.

- **Heuristic**: if you can name one column that changes on a *different cadence* than the
  rest, that is a split candidate.
- **Trade-off**: more satellites = more joins in PIT/marts. Split on *meaningful* cadence
  boundaries, not every column.

## Type of data

Group columns by business domain, not by source table layout:

- **Descriptive** — name, description, category.
- **Financial** — amounts, terms, limits.
- **Contact** — addresses, phones, emails (often also PII).
- **Operational** — status, flags, processing metadata.

A satellite that spans all four is a smell; the domains change independently and are read by
different consumers.

## Privacy / PII

PII (`email`, `phone`, `ssn`, national IDs, DOB) goes in a **dedicated satellite** so a
masking policy can be applied at the physical-table/column level without touching
non-sensitive attributes. This is both a modeling rule and a governance rule.

- The PII satellite has the **same parent HK** as its sibling — it is a *split*, not a new
  concept.
- In the Information Mart, PII is typically **excluded** or served through a separate secure
  view.

## Source boundary (FBIN hard rule)

**One satellite = one `REC_SRC`.** FBIN names satellites `sat_<entity>__<source>`. Even if
two sources describe the same hub with overlapping columns, they are **separate
satellites**, because:

- Each carries its own per-source watermark and HASHDIFF.
- Passive integration means the *hub* conforms the key; the *satellites* stay
  source-faithful (100% data rule).
- Merging sources into one satellite is a Business Vault concern, never Raw Vault.

## The single-parent guardrail (do not violate while splitting)

Splitting is **horizontal** (columns of the same parent into multiple satellites). It is
**never** an excuse to:

- Point a satellite at a different parent (single-parent rule).
- Snowflake (SAT-to-SAT).
- Merge two sources (source-boundary rule).

## How to present a split recommendation (advisor behavior)

1. List the columns and label each with its **cadence**, **domain**, and **PII** flag.
2. Show the candidate split groups and the trade-off (fewer HASHDIFF rewrites vs more joins).
3. **Ask the user** to confirm the split boundaries. Do not auto-split — it changes the
   physical model and downstream PIT/mart joins.

## Quick self-check

1. Any column on a different change cadence than its neighbors? → rate-of-change split.
2. Any PII mixed with non-PII? → PII split (governance-required).
3. More than one `REC_SRC`? → already must be separate satellites.
4. After splitting: does every satellite still have one parent and one source?
