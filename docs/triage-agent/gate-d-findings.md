# Gate D Findings — PII / Credential Surface Analysis

**Scope:** 6 dbt Cloud artifact samples (DEV PR, QA PR, PROD scheduled ×2, PROD PR, early-failure run) pulled live from `cloud.getdbt.com` Admin API via `dbt-mcp` v1.19.2.
**Date:** 2026-06-03
**Branch:** `feature/profile-persistence-and-reconciliation`
**Status:** PASS — field-aware redaction architecture locked as Phase 1 prerequisite.
**Reviewers:** Author (Sonnet 4.6 working session) + cross-review (two rounds: initial design challenge → counter-proposal refinement).

This document is the audit trail for `redact.py` v1.0.0 design decisions. Do not delete; the negative-evidence patterns (§5) prevent future engineers from relitigating excluded regex patterns.

---

## 1. Per-artifact PII surface map

| Artifact | Size | Real PII | False-positive patterns | Notes |
|---|---|---|---|---|
| `prod_scheduled_487548221.json` | 1.7 MB | 2 emails (in `.results[].compiled_code`) | 24 phone-shaped, 307 cc-shaped | Emails are internal: SME comment + WHERE clause filter on `created_by` |
| `prod_error_468003114.json` | 1.1 MB | 2 emails (same as above — same models) | 25 phone-shaped, 231 cc-shaped | Emails recur across PROD runs because they live in committed SQL |
| `dev_pr_error_487614831.json` | 209 KB | None | 1 phone-shaped, 64 cc-shaped | Smaller blast radius — PR-isolated schema |
| `qa_pr_error_487333396.json` | 299 KB | None | 0 phone, 26 cc-shaped | Clean |
| `prod_scheduled_alt_487350999.json` | 4 KB | None | None | Narrow rebuild — minimal artifact |
| `early_failure_full.json` | 17 KB | None | 1 cc-shaped | No `run_results.json`; only `status_message` + `truncated_debug_logs` |

### Real-PII locations (verified by `find_in_dict`)
- **Field:** `results[].compiled_code` (always)
- **Forms:** internal FBIN business emails embedded in:
  - SQL comments (`-- AS per the Larson SME: "becky.anderson@fbin.com"`)
  - `WHERE created_by IN ('lynzee.eddins@fiberondecking.com')`
- **Implication:** PII source = committed model SQL, not runtime payload. Same emails will appear in every artifact for those models.

### False-positive analysis (validated by context inspection)
| Pattern | Match volume | Actual content |
|---|---|---|
| `phone_us` (000-XXX-XXXX) | 24-25 per artifact | 10-digit zero-padded business IDs (customer numbers like `'0000001016'`) literal-listed in SQL `IN(...)` clauses |
| `cc_like` (13-16 digits) | 26-307 per artifact | `execution_time` floats (e.g. `18.03371024131775`) in `adapter_response` metadata |

**Conclusion:** Naive regex-only redaction would generate ~95% false positives. Field-aware redaction is mandatory.

---

## 2. Early-failure PII surface map

**Source:** `get_job_run_details?include_related=["run_steps"]` (NOT `get_job_run_error` — that 404s on early-failure runs).

| Field | PII risk | Sample content |
|---|---|---|
| `status_message` | Low — generic ("dbt command failed") | Static string, no user data |
| `run_steps[].name` | None | Step names ("dbt build --select pit_") |
| `run_steps[].finished_at` | None | Timestamps |
| `run_steps[].truncated_debug_logs` | Medium — may contain SQL snippets | 2-5KB tail of stderr; could include compiled SQL fragments → same email risk as artifact mode |
| `run_steps[].status_humanized` | None | "Error", "Success" |

**Implication for dual-mode RCA:** Early-failure mode's `truncated_debug_logs` has the SAME PII surface as artifact-mode `compiled_code` because dbt prints failing SQL to stderr. Redaction policy must apply uniformly to both inputs.

---

## 3. Environment calibration

| Environment | Email-in-SQL incidence | Recommendation |
|---|---|---|
| PROD | Present (2 unique, repeating across runs) | **Always-redact** before any persistence or LLM call |
| QA PR | None observed in this sample | Default-redact (cheap insurance; same code paths run) |
| DEV PR | None observed in this sample | Default-redact (same) |
| Early-failure | None in this sample, possible in `truncated_debug_logs` | Default-redact |

**Decision: single environment-agnostic policy.** The architectural reason DEV ≠ "no PII risk" is that **DEV runs the same compiled SQL as PROD**. Hardcoded emails in source code don't get redacted by environment; they get into every environment because they're in the source. This finding invalidates any environment-tiered redaction design. Recorded explicitly so it is not relitigated.

---

## 4. Credentials / connection-string leak findings

Ran patterns: `snowflake_pwd`, `bearer_token`, `private_key`, `aws_access_key`, `snowflake_url`, `dbt_token`, `jwt`.

**Results: ZERO matches across all 6 artifacts.**

This is consistent with dbt Cloud's design — credentials live in `profiles.yml`-equivalent connection config, never in `run_results.json` or compiled SQL. The Admin API does not return connection passwords/keys.

**Implication:** Credential redaction is defensive-only (cheap to include, not load-bearing). Iron Rule still applies (no `modify_test` regardless), but the credential exfiltration risk via artifacts is empirically ~zero.

---

## 5. `redact.py` v1.0.0 architecture (LOCKED)

### Design principle
**Field-aware allowlist FIRST, narrow regex SECOND.** Pattern-only redaction on these artifacts produces 95%+ false positives. Strip or selectively redact known-risky fields, then apply patterns only where signal is needed.

### 5.1 Field policy table

| JSON path | Action | Rationale |
|---|---|---|
| `results[].compiled_code` | **Replace with `literal_stripped_preview` (≤500 chars, sqlparse-versioned)** | Largest payload, real PII surface. Preview gives LLM enough SQL context for fix suggestions without full literal exposure. |
| `results[].raw_code` | Replace with `literal_stripped_preview` (same spec) | Same risk profile as `compiled_code`. |
| `results[].message` | **Pass through** + apply email/credential regex | Primary RCA signal; tiny (avg <2KB total per run) |
| `results[].relation_name` | Pass through | Schema/table FQN — already public via lineage |
| `results[].adapter_response.*` | Pass through except `query_id` (keep) | Diagnostic gold; no PII observed |
| `results[].timing[]` | Pass through | Numeric only |
| `results[].execution_time` | Pass through | Numeric (this was the `cc_like` false-positive source) |
| `run_steps[].truncated_debug_logs` | **Apply email + credential regex** | Last 5KB stderr; may contain failing SQL |
| `run_steps[].name` / `.status_humanized` | Pass through | Metadata only |
| `status_message` | Pass through + regex | Generic but apply defense in depth |
| Anything else not in allowlist | **Drop** | Defense in depth |

### 5.2 Literal-stripped preview spec

```python
COMPILED_CODE_PREVIEW = {
    "hash_algorithm": None,               # See §5.5 — no hash, identity covered by unique_id + invocation_id
    "preview_max_chars": 500,
    "preview_strategy": "first_n_chars_then_ellipsis",   # not random sample
    "literal_strip_method": "sqlparse_v0.4.4",           # versioned for regression traceability
    "strip_string_literals": True,                        # belt-and-suspenders inside the preview too
    "preview_truncated_flag": True,                       # explicit "preview_truncated": true in payload
}
```

Reason `strip_string_literals=True` applies inside the preview: a 500-char head of compiled SQL frequently lands in the `SELECT ... FROM ... WHERE x IN (...)` clause where literals re-appear. Don't trust truncation alone.

Output payload shape (single-phase LLM call, see §6):
```python
{
    "evidence_mode": "artifact",
    "node_id": "model.fbin_dv.sat_order_line",
    "literal_stripped_preview": "WITH src AS (SELECT col1, col2 FROM {{ ref('stg_x') }} WHERE rec_src = <LIT> ...",
    "preview_chars": 500,
    "preview_truncated": True,
    "literal_strip_method": "sqlparse_v0.4.4",
}
```

### 5.3 Regex eligibility (enforced invariant)

```python
REGEX_ELIGIBLE_FIELDS = frozenset([
    "message",                  # run_results[].results[].message
    "truncated_debug_logs",     # run.run_steps[].truncated_debug_logs
    "status_message",           # run.status_message (early-failure mode)
])
# Any field name NOT in this set is NOT subject to regex.
# New fields require an explicit PR amendment.
```

Converts "we only scan certain fields" from a documented rule into an enforced code invariant.

### 5.4 Active vs excluded patterns

**Active patterns (apply only to REGEX_ELIGIBLE_FIELDS):**
- `email`: `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}` → replace with `<EMAIL_REDACTED>`
- Credential family — fires sentinel (§5.6):
  - `snowflake_pwd`, `bearer_token`, `private_key`, `aws_access_key`, `dbt_token`, `jwt`, `url_with_creds`

**Excluded patterns — DO NOT silently omit; keep this block in code:**

```python
# Patterns intentionally NOT applied — see docs/triage-agent/gate-d-findings.md (2026-06-03)
# - phone_us:     10-digit zero-padded customer IDs (e.g., '0000001016') produce 24+ FPs per artifact
# - cc_like:      Luhn-passing float fragments from execution_time (e.g., 18.03371024131775) produce 26-307 FPs
# - ssn:          Zero real matches across stratified sample (DEV/QA/PROD × scheduled/PR)
# - ip_address:   Zero real matches; would catch internal Snowflake account locators (already covered by url_with_creds)
EXCLUDED_PATTERNS = frozenset(["phone_us", "cc_like", "ssn", "ip_address"])
```

The negative evidence is as important as the positive. Coded in to prevent future re-introduction.

### 5.5 No SHA256 hash on compiled_code (decision-not-taken)

**Decision: do NOT emit a content hash of `compiled_code` or `raw_code`.** Recorded as a deliberate choice, not an oversight.

Rationale:
- Identity is already covered by `unique_id` + `invocation_id` + `run_id` from the dbt manifest.
- SHA256 × 336 nodes/run ≈ 21KB of payload bloat for no consumer.
- "Same SQL failed before" detection is better served by `unique_id + error_signature_hash` (idempotency key in observability DDL) than by hashing compiled code — the same `unique_id` can fail for different reasons at different times.

**Graduation trigger to revisit:** an explicit downstream consumer asks for compiled-SQL-level dedup that `unique_id + error_signature_hash` cannot satisfy. Until then, no hash.

### 5.6 Credential sentinel (LOCKED, tightened spec)

```python
CREDENTIAL_SENTINEL_PATTERNS = [
    "snowflake_pwd", "bearer_token", "private_key",
    "aws_access_key", "dbt_token", "jwt", "url_with_creds",
]

# If ANY credential pattern matches in ANY REGEX_ELIGIBLE field, the agent:
#  1. Halts further analysis (no LLM call)
#  2. Sets classification = "unknown"
#  3. Sets requires_human_review = True (enforced in rca_schema validator)
#  4. Emits a P1 alert to DV-Triage-Alerts Teams channel
#  5. Logs to TRIAGE_INVOCATIONS with outcome = "credential_sentinel_fired"
#  6. Writes only "pattern <X> fired in field <Y> at offset <Z>" — NEVER the matched value
#  7. Returns a sanitized error to caller
```

**Item #6 is the most important rule in this entire document.** If a credential ever does appear in artifacts, the *worst* response is logging the credential to the observability table for forensics. Log the *fact* of the match (pattern name, field name, byte offset, length), never the value.

---

## 6. Agent payload architecture (single-phase, LOCKED)

**Decision: single LLM call per RCA invocation.** The literal-stripped preview from §5.2 is included in the initial payload — sufficient SQL context for both classification AND fix-suggestion in one round-trip.

**Two-phase design (classify → re-fetch SQL → suggest) was considered and rejected for v1** because:
- Second round-trip = real cost (tokens, latency) for hypothetical benefit
- SQL literal-stripping is a parser problem (nested literals, `$$` dollar-quoting, escapes, hex literals) — making it a phase boundary doubles failure surface for no safety gain
- Confidence-gate calibration (where does threshold 0.80 come from?) requires its own backtest we don't have data for

**Graduation trigger to two-phase:** Phase 1 exit review measures fix-suggestion quality on the backtest as a side-output. If quality is empirically poor, that's the trigger for v2 two-phase consideration. If quality is fine, two-phase never ships.

---

## 7. Recommendations for Phase 1 build

1. **`redact.py` v1.0.0**: Implement §5 architecture. Estimated ~150 LOC + sqlparse dependency.
2. **No environment branching** — single policy across PROD/QA/DEV (see §3).
3. **Observability:** Add `redaction_events INT` column + `sentinel_fired BOOL` to RCA record schema; increment when sentinels fire.
4. **Test budget:** 6 fixture artifacts × 12 patterns = 72 assertions. Snapshot the redacted output. Include literal-strip unit tests with nested-quote and dollar-quote edge cases.
5. **Backtest harness:** include `redact.py` as a mandatory pre-step on every backtest invocation. Track fix-suggestion quality as side-output for two-phase graduation decision.
6. **Delete raw artifacts from `/tmp/triage-gate-d/`** after this report is committed (only sanitized fixtures go in the repo, under `scripts/automation/tests/fixtures/triage/` when Phase 1 begins).

---

## Gate D status: **PASS**

Architecture locked. Proceed to Gate E (webhook reliability).
