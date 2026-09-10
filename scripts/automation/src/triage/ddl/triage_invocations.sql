-- =============================================================================
-- OPS_PROD.LOGS.TRIAGE_INVOCATIONS — RCA persistence for the DV Failure Triage
-- Agent. One row per invocation of triage_failure(raw_payload).
--
-- (a) Schema source of truth
--     The RCARecord-derived columns (eight fields, identifiable by name from
--     RCARecord in scripts/automation/src/triage/rca_schema.py) carry the
--     contract. Snowflake binding is by name, not ordinal — physical column
--     order here is by-group and semantically irrelevant. SCHEMA_VERSION is
--     pinned 'v1.0.0' at that module and persisted per-row so future read-
--     side queries can filter (`WHERE schema_version = 'v1.0.0'`); bumping
--     the contract bumps SCHEMA_VERSION there — never coerce silently on read.
--
-- (b) Clustering — DEFERRED this pass.
--     Phase-1 query workload is empirically unknown until BACKTEST-CORPUS
--     Phase 2 (≥20 labelled production failures) is in place. Adding a
--     clustering key later (ALTER TABLE OPS_PROD.LOGS.TRIAGE_INVOCATIONS
--     CLUSTER BY (created_at) — or (job_id, created_at) for failure-streak
--     queries supporting Q2e-1 / ORCH-CIRCUIT-OPEN) is SCHEMA-non-breaking
--     but incurs ongoing automatic-reclustering credit cost — evaluate
--     against actual query workload post-corpus before adding.
--
-- (c) Enum + cross-field invariant enforcement
--     classification / suggested_action / evidence_mode / outcome are stored
--     as VARCHAR. NO Snowflake CHECK constraints — Snowflake does not
--     enforce CHECK on regular tables (informational only); a CHECK here
--     would mislead future maintainers. Write-side enforcement lives in
--     RCARecord._enforce_invariants (Pydantic model_validator). The
--     cross-field invariant `confidence IS NULL iff classification='unknown'`
--     (Rule 3 of the schema) is ALSO write-side-enforced, NOT enforced at
--     the table. Read-side queries treating `confidence IS NULL` as a
--     proxy for `classification='unknown'` must verify against the
--     classification column directly.
--
-- (d) Deploy mechanism — schema is unconditionally re-runnable.
--     This file (`triage_invocations.sql`) is the SCHEMA file:
--         CREATE TABLE IF NOT EXISTS  → idempotent under any role
--         GRANT INSERT, SELECT       → idempotent (re-grant of a held
--                                       privilege returns a notice, not
--                                       an error)
--     Safe to re-apply on every deploy. For column changes, use a
--     separate ALTER TABLE migration script — CREATE TABLE IF NOT
--     EXISTS will NOT alter an existing table.
--
--     The one-time ownership transfer (GRANT OWNERSHIP TO ROLE
--     DATA_OPS COPY CURRENT GRANTS) lives in
--     `triage_invocations_grants_bootstrap.sql` — applied ONCE at
--     initial table creation, NEVER included in an automated
--     re-apply path. Same-role re-runs of GRANT OWNERSHIP return a
--     notice (not an error) per current Snowflake behavior, but the
--     conditional non-idempotency (different-role re-run errors;
--     strict-mode tooling treating notices as failures errors) is
--     why the split exists. Keep them split.
--
--     Run as the DATA_OPS role (steady-state re-apply):
--         USE ROLE DATA_OPS;
--         USE DATABASE OPS_PROD;
--         USE SCHEMA LOGS;
--         <paste this file's contents>
--     Initial deploy (one-time): apply this file first, then
--     `triage_invocations_grants_bootstrap.sql` — see that file's
--     header for the full sequence and required role.
--
-- (e) PII / masking analysis — no masking policy required.
--     RATIONALE content by Outcome (see failure_triage_agent.py):
--       CLASSIFIED → "pattern_id={...} sub_class={...} provenance={src_type}:{citation}"
--       UNKNOWN_HANDED_TO_HUMAN → module-authored strings (no payload-derived content)
--       CREDENTIAL_SENTINEL_FIRED → "credential_sentinel_fired: pattern={name}
--           field_path={...} offset={int} length={int}" — NEVER the matched
--           credential value (gate-d §5.6 item #6)
--     EVIDENCE_JSON column content is post-redact.py output (field-aware
--     allowlist + truncate_logs + credential sentinel + email pass).
--     Credential exclusion is enforced by audit_raw_for_credentials() running
--     before any lossy transform (credential-threat-model.md R1), verified by
--     TestRawAudit in scripts/automation/tests/test_triage_redact.py (R3).
--     No masking policy required under the current contract.
--     Re-litigate only if the redact contract changes.
--
-- (f) Forward-compat: writer-role narrowing
--     Today's writer = DATA_OPS (per docs/triage-agent/setup.md §6 — the
--     agent's runtime role). Intended hardening: a dedicated
--     TRIAGE_AGENT_WRITER service role with INSERT + SELECT only on this
--     table. Substitutable later via REVOKE INSERT ... FROM ROLE DATA_OPS;
--     GRANT INSERT, SELECT ... TO ROLE TRIAGE_AGENT_WRITER; — NO schema
--     change required. Tracked as a follow-up; not done here.
-- =============================================================================

CREATE TABLE IF NOT EXISTS OPS_PROD.LOGS.TRIAGE_INVOCATIONS (
    invocation_id           VARCHAR(26)   PRIMARY KEY,                    -- ULID, fixed 26 chars (PK is documentary; Snowflake does not enforce)
    run_id                  INTEGER       NOT NULL,                       -- dbt Cloud run id
    job_id                  INTEGER       NOT NULL,                       -- dbt Cloud job id
    environment_id          INTEGER       NOT NULL,                       -- dbt Cloud environment id
    git_sha                 VARCHAR(40)   NULL,                           -- full SHA1 from manifest; NULL when manifest unavailable
    unique_id               VARCHAR(512)  NULL,                           -- dbt node unique_id; NULL on early-failure (no manifest)
    error_signature_hash    VARCHAR(16)   NULL,                           -- xxhash64 hex of normalised error message
    evidence_mode           VARCHAR(32)   NOT NULL,                       -- EvidenceMode enum: 'artifact' | 'early_failure' | 'artifact_projection' | 'undetected' (writer MUST use mode.value, NOT str(mode)/f"{mode}" — see rca_schema.EvidenceMode docstring)
    classification          VARCHAR(64)   NOT NULL,                       -- Classification enum (incl. 'unknown')
    confidence              FLOAT         NULL,                           -- 0..1; NULL iff classification='unknown' (write-side, Rule 3)
    suggested_action        VARCHAR(64)   NULL,                           -- SuggestedAction enum; never 'modify_test' on test_failure (Rule 2)
    requires_human_review   BOOLEAN       NOT NULL,
    rationale               VARCHAR(2000) NULL,                           -- Pydantic max_length=2000 — MUST stay exact (off-by-one = write failure)
    redaction_events        INTEGER       NOT NULL DEFAULT 0,             -- from RedactionResult.redaction_events
    sentinel_fired          BOOLEAN       NOT NULL DEFAULT FALSE,         -- TRUE iff outcome='credential_sentinel_fired'; RedactionResult.sentinel_fired removed v1.2.0 (field always () in production — sentinel fires raise, not accumulate; outcome enum is source of truth)
    outcome                 VARCHAR(64)   NOT NULL,                       -- Outcome enum: classified | unknown_handed_to_human | credential_sentinel_fired | circuit_open | triage_attempted_but_failed (C6 per-run retrieval-failure dead-letter — get_job_run_error raised K times; row carries the real run_id so MAX(run_id) advances and cursor doesn't re-poll the same run forever)
    schema_version          VARCHAR(16)   NOT NULL,                       -- pinned 'v1.0.0' (rca_schema.SCHEMA_VERSION)
    evidence_json           VARIANT       NULL,                           -- post-redact payload; NULL when redaction did not complete (mode-not-detected, sentinel_fired) — fail-open contract per v2-plan §1.8
    -- created_at: SYSDATE() returns UTC TIMESTAMP_NTZ directly; no session-TZ
    -- dependency. Chosen over CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ
    -- (same value, fewer moving parts). Do NOT "simplify" back to CURRENT_TIMESTAMP()
    -- — that reintroduces session-TZ dependence. SYSDATE() also ignores
    -- MOCK_CURRENT_TIME / time-travel session overrides, which is correct for an
    -- audit table (real wall-clock always; feeds Q-Streak window queries).
    created_at              TIMESTAMP_NTZ NOT NULL DEFAULT SYSDATE()
);

-- -----------------------------------------------------------------------------
-- Grants — re-runnable. Re-granting a held privilege returns a notice,
-- not an error; safe in any automated re-apply path.
--
-- DATA_OPS owns and writes today; narrowing to TRIAGE_AGENT_WRITER per
-- header (f) is a follow-up, substitutable without schema change.
--
-- The one-time GRANT OWNERSHIP transfer lives in
-- `triage_invocations_grants_bootstrap.sql` — see header (d).
-- -----------------------------------------------------------------------------
GRANT INSERT, SELECT ON TABLE OPS_PROD.LOGS.TRIAGE_INVOCATIONS TO ROLE DATA_OPS;
