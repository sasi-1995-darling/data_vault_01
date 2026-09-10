# DV Failure Triage Agent — v2 Plan (Phase 1 Build Specification)

**Status:** Pre-build planning. All gate validations except Gate E complete.
**Date:** 2026-06-03
**Branch:** `feature/profile-persistence-and-reconciliation`
**Prereq docs:** [gate-d-findings.md](./gate-d-findings.md)

This plan supersedes the original v1 sketch. Decisions below are locked unless explicitly marked as graduation triggers.

---

## 1. Architectural decisions (LOCKED)

### 1.1 Dual-mode RCA evidence extraction

The agent operates in two modes depending on whether dbt Cloud produced artifacts:

| Mode | Trigger | API call | Primary evidence fields |
|---|---|---|---|
| **artifact-mode** | `get_job_run_error` returns 200 | `get_job_run_error` + `get_job_run_artifact?path=run_results.json` | `results[].message`, `results[].status`, `results[].relation_name`, `results[].compiled_code` (→ preview) |
| **early-failure-mode** | `get_job_run_error` returns 404 OR artifact list is empty | `get_job_run_details?include_related=["run_steps"]` | `status_message`, `run_steps[].name`, `run_steps[].truncated_debug_logs`, `run_steps[].status_humanized` |

**Empirical validation:** Tested live against 5 artifact-mode runs + 2 early-failure runs in Gate D. Both modes return actionable RCA signal. The upstream `dbt-agent-skills` skill does not address early-failure mode — this is a genuine gap in the official tooling, filled here.

**Mode selection logic** (in `triage_agent.py`):
```python
def select_evidence_mode(run_id: int, client: DbtCloudClient) -> EvidenceMode:
    try:
        error_data = client.get_job_run_error(run_id)
        if error_data and error_data.get("status") in ("error", "fail"):
            return EvidenceMode.ARTIFACT
    except HTTPError as e:
        if e.status_code != 404:
            raise
    # Fallback: pull run_steps for early-failure analysis
    return EvidenceMode.EARLY_FAILURE
```

### 1.2 Single-phase LLM payload with literal-stripped preview

One LLM round-trip per RCA. The redacted payload includes a `literal_stripped_preview` (≤500 chars; produced via sqlparse — see `scripts/automation/requirements.txt` for the pinned version) of failing `compiled_code` — sufficient context for both classification AND fix-suggestion in one call.

**Two-phase design (classify → re-fetch SQL → suggest) explicitly rejected for v1.** Rationale documented in [gate-d-findings.md §6](./gate-d-findings.md#6-agent-payload-architecture-single-phase-locked).

**Graduation trigger:** Phase 1 exit review tracks fix-suggestion quality on the backtest. Poor quality → consider two-phase in v2. Good quality → two-phase never ships.

### 1.3 Field-aware redaction (`redact.py` v1.0.0)

Full spec in [gate-d-findings.md §5](./gate-d-findings.md#5-redactpy-v100-architecture-locked). Highlights:

- Field allowlist FIRST: `compiled_code` / `raw_code` → preview only; non-allowlisted fields dropped
- Regex SECOND: only on `REGEX_ELIGIBLE_FIELDS` frozenset (`message`, `truncated_debug_logs`, `status_message`)
- Active patterns: `email` + credential family
- Excluded patterns with negative-evidence comments coded inline: `phone_us`, `cc_like`, `ssn`, `ip_address`
- Environment-agnostic single policy (DEV runs same compiled SQL as PROD)

**Round 3.5.5 closed (2026-06-05):** Day-3.8 `logs`-field hybrid
truncation was empirically falsified on P0.1 payloads (Cluster A
placed actionable error ≈ 2.67 MB outside the ±16 KB window because
generic `\bfailed\b` anchor matched manifest-dump noise and beat the
specific `Encountered an error:` anchor). Replaced by 5-rule v2
algorithm (generics removed + earliest-position-wins + Rule 3 head
window + Rule 4 centered window + Rule 5 tail fallback). Spike
evidence: 15/15 PASS (7 real + 8 synthetic). See
[round-3.5.5-spike-results.md](./round-3.5.5-spike-results.md),
[sprint-1-deferred.md Closed item #14](./sprint-1-deferred.md), and
[lessons-learned.md 2026-06-05 entry 4](./lessons-learned.md).

### 1.4 Credential sentinel

Highest-leverage safety control. Halt + alert + classify-as-unknown + **never log the value, only the fact**. Full spec in [gate-d-findings.md §5.6](./gate-d-findings.md#56-credential-sentinel-locked-tightened-spec).

### 1.5 No content hash on compiled_code

Decision-not-taken, recorded so it isn't relitigated. Identity already covered by `unique_id + invocation_id + run_id`. See [gate-d-findings.md §5.5](./gate-d-findings.md#55-no-sha256-hash-on-compiled_code-decision-not-taken).

### 1.6 Iron Rule (LOCKED, not new)

`rca_schema.py` enum forbids `suggested_action == "modify_test"` for test failures. `fbin_error_catalog.yml` carries `root_cause_investigation_required: true` flag. Test-modifying PRs require human approval regardless of classification confidence.

### 1.7 Cold-start behavior

When the agent has no classification history for a `unique_id + error_signature_hash` pair, default classification = `unknown`, `requires_human_review = true`. Avoids confident-but-wrong outputs on first encounter with a failure pattern.

### 1.8 Fail-open circuit breaker

If `redact.py` raises, if LLM call times out, or if observability DDL write fails → agent emits `unknown` classification + human-review flag, never blocks the calling pipeline. The agent is a co-pilot, not a gate.

### 1.9 Schema version policy

`rca_record` schema = SemVer `v1.0.0`. Breaking changes bump major; new optional fields bump minor; doc-only changes bump patch. Schema version embedded in every persisted record for forward-compat.

---

## 2. Phase 1 build scope

| Component | LOC est. | Owner artifact |
|---|---|---|
| `triage_agent.py` (agent file + entry point) | ~300 | `.github/agents/dv-failure-triage.agent.md` + Python entry |
| `redact.py` (per §1.3) | ~150 + sqlparse | `scripts/automation/src/triage/redact.py` |
| `rca_schema.py` (Pydantic v1.0.0) | ~80 | `scripts/automation/src/triage/rca_schema.py` |
| `fbin_error_catalog.yml` (seed ~10 patterns) | ~200 lines YAML | `scripts/automation/src/triage/fbin_error_catalog.yml` |
| `dbt_cloud_client.py` (thin wrapper over dbt-mcp) | ~200 | `scripts/automation/src/triage/dbt_cloud_client.py` |
| Observability DDL (TRIAGE_INVOCATIONS table) | ~50 | `scripts/automation/src/triage/ddl/triage_invocations.sql` |
| Backtest harness | ~250 | `scripts/automation/src/triage/backtest.py` |
| Tests (unit + fixture-based) | ~500 | `scripts/automation/tests/test_triage_*.py` |
| Fixtures (sanitized from Gate D samples) | 6 files | `scripts/automation/tests/fixtures/triage/` |

**Estimate: ~2 weeks** (unchanged from pre-Gate-D estimate; Gate D shifted complexity from PII patterns to payload phasing, net-zero).

---

## 3. Observability DDL (sketch — finalize during build)

```sql
CREATE TABLE IF NOT EXISTS TRIAGE_INVOCATIONS (
    invocation_id        VARCHAR PRIMARY KEY,         -- ulid
    run_id               INTEGER NOT NULL,
    job_id               INTEGER NOT NULL,
    environment_id       INTEGER NOT NULL,
    git_sha              VARCHAR,                     -- commit SHA from manifest
    unique_id            VARCHAR,                     -- dbt node unique_id (NULL on early-failure)
    error_signature_hash VARCHAR,                     -- xxhash64 of normalized error message
    evidence_mode        VARCHAR NOT NULL,            -- 'artifact' | 'early_failure'
    classification       VARCHAR NOT NULL,            -- enum, includes 'unknown'
    confidence           FLOAT,                       -- 0..1, NULL when classification=unknown
    suggested_action     VARCHAR,                     -- enum, never 'modify_test' on test failures
    requires_human_review BOOLEAN NOT NULL,
    redaction_events     INTEGER DEFAULT 0,
    sentinel_fired       BOOLEAN DEFAULT FALSE,
    outcome              VARCHAR NOT NULL,            -- 'classified', 'unknown_handed_to_human',
                                                       -- 'credential_sentinel_fired', 'circuit_open'
    schema_version       VARCHAR NOT NULL,            -- 'v1.0.0'
    evidence_json        VARIANT,                     -- redacted payload only, NEVER raw
    created_at           TIMESTAMP_NTZ NOT NULL
);
```

`git_sha` included per ChatGPT's earlier ask — enables "which commit introduced this failure pattern?" queries.

---

## 4. Gates traceability

| Gate | Status | Output |
|---|---|---|
| A — Plan + API surface | PASS | Inline in transcript |
| B — dbt-mcp install + live tool validation | PASS | `.vscode/mcp.json` configured; tested live |
| C — Skill format compatibility | PASS | Inline in transcript |
| D — PII / credential surface analysis | PASS | [gate-d-findings.md](./gate-d-findings.md) |
| E — Webhook availability | PASS (2026-06-03) | dbt Cloud UI inspection confirmed: webhook console reachable, `Run errored` is a discrete event, multi-job subscription supported, signature mechanism present (exact HMAC scheme TBD Sprint 1), existing webhook on account proves delivery works. Reliability measurement deferred to Sprint 1. |

### Gate E follow-ups (Sprint 1)

1. **HMAC signature scheme**: confirm whether dbt Cloud auto-generates a signing secret on webhook creation or accepts a user-provided one. Implement `webhook_verifier.py` accordingly. Reject unsigned payloads.
2. **Delivery reliability**: log webhook arrival count vs. `Run errored` count from Admin API over Sprint 1. If miss rate > 0.5%, add polling fallback as defense in depth.
3. **Replay semantics**: document dbt Cloud's retry policy (intervals, max attempts) so the agent's idempotency key handles duplicates correctly.
4. **Webhook subscription**: create the production webhook subscribing to `Run errored` on jobs 786806 / 786808 / 786800 → GitHub `repository_dispatch`. Filter at dbt Cloud side, not in agent.

---

## 5. Cross-review history

This plan reflects two rounds of ChatGPT cross-review on Gate D:

**Round 1 — five sharpenings (all accepted):**
1. `COMPILED_CODE_PREVIEW` with explicit `strip_string_literals=True` inside the preview
2. `REGEX_ELIGIBLE_FIELDS` as enforced frozenset invariant
3. `EXCLUDED_PATTERNS` coded inline with negative-evidence comments
4. Single environment-agnostic policy rationale documented
5. Credential sentinel: log "pattern X fired in field Y at offset Z" — NEVER the value

**Round 2 — two counter-proposals (both accepted by ChatGPT after pushback):**
1. **Single-phase payload** beats two-phase classify→re-fetch. Avoids second round-trip, calibration gate, and parser-as-phase-boundary failure surface.
2. **Drop SHA256 hash on compiled_code.** Identity already covered by `unique_id + invocation_id`; 21KB bloat/run for no consumer.

**Working principle banked:**
> A review process that produces only "yes good" outputs from both sides isn't a review process, it's a rubber stamp. The right shape is asymmetric corrections in both directions: cross-reviewer catches security/audit gaps; author catches over-engineering. Different failure modes, different strengths.

When future designs propose multi-phase / gated / multi-round mechanisms, heuristic flag: "is there a single-phase payload-level fix that does the same job?"

---

## 6. Next step

All gates (A–E) PASS. Begin Phase 1 build per §2.

**Reviewer assignment:** Phase 1 PR is reviewed by the **DataOps team** (team-level review, not specific named individuals).

**Exit review:** the Phase 1 exit review (§1.5 graduation trigger) is conducted asynchronously on the PR — no separate calendar meeting required.

**Landing zone for RCA records:** `OPS_PROD.LOGS.*` (owned by `DATA_OPS`, semantic match with existing append-only event-log tables). No external approval required — DataOps owns the database. See [setup.md §6](./setup.md) for rationale.
