# Day 4 — Early-Failure Evidence Pull Procedure

**Status:** Planning doc committed Day 3. Execute Day 4.

**Why this exists:** Day 3 shipped catalog *infrastructure* (loader,
matcher, 6 mutation-tested invariants) plus one artifact-mode pattern
(`fk_orphan_detection_failure_v1`, anchored to lessons.md #120). Day 3
explicitly **did not** ship early-failure patterns because no documented
provenance exists for the subclass list. ChatGPT's Day 2 cross-review
suggested 7 subclasses (`git_clone_failure`, `profile_setup_failure`,
etc.) but these are forward-looking guesses, not evidence. Inventing
provenance violates the Design Decision Delegation rule.

Day 4 closes the gap by pulling **live evidence** from the two
early-failure runs already identified in
[`gate-d-findings.md`](./gate-d-findings.md) §1 and deriving subclasses
from observed `status_message` + `truncated_debug_logs` content.

---

## Procedure

### Step 1 — Identify the two Gate-D early-failure run IDs

[`gate-d-findings.md`](./gate-d-findings.md) §1 documents:

> *Tested live against 5 artifact-mode runs + 2 early-failure runs in
> Gate D.*

And §1 lists `early_failure_full.json` (17 KB). Re-derive the source
run IDs from the Gate-D sample list (cross-reference the artifact-sample
table in §1).

### Step 2 — Re-pull via `dbt-mcp`

For each early-failure run ID, call:

```
mcp_dbt: get_job_run_details
  run_id: <ID>
  include_related: ["run_steps"]
```

This is the canonical Gate-D path — `get_job_run_error` 404s on
early-failure runs (documented in [`gate-d-findings.md`](./gate-d-findings.md)
§2). The `run_steps[]` payload contains `truncated_debug_logs` +
`status_humanized` per step.

### Step 3 — Redact and stage payloads

Pass each raw run payload through
`scripts/automation/src/triage/redact.py::redact_early_failure(...)`.
Stage the redacted output as a fixture under
`docs/triage-agent/fixtures/early-failure-N.json`.

**Sentinel check:** if `CredentialSentinelFired` raises during this
step, the early-failure payload contains a credential that escaped the
artifact-mode allowlist — that itself is a finding worth capturing
before continuing.

### Step 4 — Derive subclasses from observed evidence

Read each redacted payload's `status_message` + `run_steps[*].name` +
`run_steps[*].truncated_debug_logs`. Group by recurring failure
signature (regex over step name + log keywords). Each distinct group
becomes a candidate subclass.

**Discipline:** subclass names come from the evidence, not from
ChatGPT's preview list. If only two distinct signatures appear in the
2-sample set, that's 2 patterns — not 4, not 7. Backtest expansion in
Day 5+ can add more as new failure modes appear in production.

For comparison only, ChatGPT's suggested subclass list (use as a
checklist, not a target):

- `git_clone_failure`
- `git_clone_timeout`
- `profile_setup_failure`
- `dependency_install_failure`
- `credential_validation_failure`
- `container_startup_failure`
- `dbt_cloud_internal_error`

### Step 5 — Add patterns to `fbin_error_catalog.yml`

For each evidence-derived subclass, add a pattern entry following the
v1.0.0 schema documented at the top of
[`fbin_error_catalog.yml`](../../scripts/automation/configs/fbin_error_catalog.yml).

**Classification choice:** most early-failure subclasses will map to
`connection_error`, `dependency_error`, or `unknown`. Patterns
classified as `unknown` MUST omit `confidence_baseline` and set
`auto_retry_eligible: false` (the rca_schema Rule 3 propagates — UNKNOWN
defers to humans).

### Step 6 — Tests + 8-gate matrix

For each new pattern:

1. Add a happy-path matcher test using the redacted fixture
2. Add a non-matching counter-example
3. Verify the existing 6 mutation tests still catch all 6 mutations on
   the expanded catalog
4. Run the full 8-gate matrix (announce upfront, report against same
   format)

### Step 7 — Commit + cross-review

Commit message body must include:

- Source run IDs (redacted)
- Number of new patterns + evidence source for each
- Mutation evidence (all 6 still CAUGHT)
- Test count delta

Submit for ChatGPT cross-review before merge.

---

## Out of scope for Day 4

- Multi-pattern ambiguity resolution (multiple patterns match same
  payload) → Day 5
- Pattern learning / catalog suggestions from unmatched payloads → Day 6
- Orchestrator integration (`failure_triage_agent.py`) → Day 7

## Provenance pointers

- [`gate-d-findings.md`](./gate-d-findings.md) §1 — sample list
- [`gate-d-findings.md`](./gate-d-findings.md) §2 — early-failure PII
  surface map (confirms which fields are populated)
- [`v2-plan.md`](./v2-plan.md) — dual-mode evidence routing logic
- [`scripts/automation/configs/fbin_error_catalog.yml`](../../scripts/automation/configs/fbin_error_catalog.yml)
  — v1.0.0 pattern schema reference

---

# Day 4 Execution Report (2026-06-04)

**Status:** EXECUTED. 1 evidence-derived pattern shipped; 2 candidate
clusters deferred to Sprint 1 backtest. The "expected 2 patterns" from
the planning doc was over-optimistic — real evidence in this sample
window produced 1 shippable pattern given the current allowlist policy.

## Pre-flight verifications

| Check | Expected | Observed | Status |
|---|---|---|---|
| 1. Field `truncated_debug_logs` populated on errored runs | Yes (all 4 steps per run) | Yes — sizes 942 B → 3,773 B | PASS |
| 2. Gate-D run 487333396 still retrievable via Admin v2 API | HTTP 200 + run_steps[] populated | HTTP 200, step_4 has 2,885 B truncated_debug_logs | PASS |
| 3. `mcp_dbt_*` VS Code wrappers functional | Tool calls return data | All return empty errors despite server process running | FAIL — workaround: curl direct to `https://cloud.getdbt.com/api/v2/accounts/173296/runs/...` |
| 4. Mut8 + catalog-changelog.md status | Either shipped or deferred | Deferred — added as Sprint 1 items #10 + #11 (Day 3.5 commit) | DEFERRED |

## Step 1 — Sample window

Could not use only the 2 Gate-D early-failure runs (487333396, 487313189)
because they're both the same failure signature. Expanded to all
**status=20 (error)** runs from QA env (296453) returned by:

```
GET /api/v2/accounts/173296/runs/?environment_id=296453&status=20&limit=20&order_by=-created_at
```

Pulled 7 sample runs total (the 2 Gate-D + 5 most-recent QA errors).
DEV env (287190) had 0 errors in the window — likely low PR activity.
PROD env (296881) excluded (no PR-isolation signature).

## Step 2 — Redaction outcome

All 7 payloads processed through `redact_early_failure()`:

| Run ID | Sentinel fired | Redactions applied | Redacted size |
|---|---|---|---|
| 487333396 | False | 0 | 13.2 KB |
| 487313189 | False | 0 | 12.8 KB |
| 485851058 | False | 0 | 9.1 KB |
| 485850628 | False | 0 | 9.4 KB |
| 485821754 | False | 0 | 9.2 KB |
| 484675412 | False | 0 | 10.1 KB |
| 486060143 | False | 0 | 11.6 KB |

Zero sentinel fires, zero redactions applied — confirms the field-aware
allowlist holds: the populated fields (`message`, `truncated_debug_logs`,
`status_message`) in this sample window contain no credential-shaped
content. (`logs` field also examined separately — see Sprint 1 deferred
item #12 for findings.)

## Step 3 — Cluster derivation from evidence

Grouped by repeating signature in `truncated_debug_logs` OR `logs`
(the latter is 2.9 MB and NOT in `REGEX_ELIGIBLE_FIELDS` — see deferred
item #12). Three distinct clusters surfaced:

| Cluster | Runs (count) | Signature | Found in field | Shipped? |
|---|---|---|---|---|
| A — `manifest_parse_failure` | 485851058, 485850628, 485821754 (3) | `mashumaro.exceptions.InvalidFieldValue` + `'javascript' is not a valid ModelLanguage` (dbt version drift on deferred manifest) | `logs` only — NOT in `truncated_debug_logs` | DEFERRED (item #12) |
| B — `pr_isolated_schema_missing_upstream` | 487313189, 487333396 (2) | `Database Error` + `002003 (42S02) SQL compilation error: Object 'DATAVAULT_QA.DBT_CLOUD_PR_<N>_<N>_RAW_VAULT.<T>' does not exist` | `truncated_debug_logs` ✓ | **SHIPPED** as `pr_isolated_schema_missing_upstream_v1` |
| C — `dmf_model_compile_failure` | 484675412, 486060143 (2) | `Database Error in dbt_yml_test_inventory` + (variant 1) `SNOWFLAKE_DMF.DBT_YML_TEST_INVENTORY does not exist` OR (variant 2) `syntax error line N at position M unexpected ')'` | `logs` only — NOT in `truncated_debug_logs` | DEFERRED (item #12) |

## Step 4 — Shipped pattern

Added 1 pattern to `fbin_error_catalog.yml`:

```yaml
- pattern_id: pr_isolated_schema_missing_upstream_v1
  classification: compile_error
  sub_class: pr_schema_missing_upstream
  signal_sources: [truncated_debug_logs]
  match_logic:
    type: regex_and_substring
    requires_all:
      - field: truncated_debug_logs
        pattern: "Object\\s+'[^']+'\\s+does not exist or not authorized"
      - field: truncated_debug_logs
        pattern: "DBT_CLOUD_PR_\\d+_\\d+_RAW_VAULT"
  confidence_baseline: 0.90
  suggested_action: escalate_to_human
  root_cause_investigation_required: true
  auto_retry_eligible: false
  provenance:
    source_type: gate_d_evidence
    citation: "run_id=487333396"
```

**Why classification=compile_error** (not `test_failure`): Snowflake
emits `SQL compilation error: 002003 (42S02)`. Iron Rule does not
apply (Mut3a/Mut3b silent). Auto-retry off because the fix is operational
(rebuild PR raw vault), not code.

**Two confirming runs prove the pattern matches schema-path SHAPE not
object names** — 487333396 misses `LSAT_ITEM_INVENTORY_VC__AMAZON`,
487313189 misses `LNK_ITEM_INVENTORY`. Different missing objects, same
pattern fires.

## Step 5 — Why clusters A and C deferred

Both have errors only in the `logs` field (the 2.9 MB full
runtime log), not in `truncated_debug_logs` (the 1-4 KB dbt-Cloud-tail).
The current `REGEX_ELIGIBLE_FIELDS` allowlist intentionally excludes
`logs` to keep:

1. **PII surface bounded** — sentinel scan over 2.9 MB per run blows
   the field-aware allowlist's runtime budget
2. **Per-call cost predictable** — matcher walks ~10 KB max, not ~3 MB

Expanding the allowlist to include `logs` requires a Sprint-1 sub-task
that re-runs the Gate-D PII surface analysis on `logs` content, adds
size-cap + tail-truncation, and introduces a new mutation invariant.
**See deferred item #12.**

## Step 6 — Test + matrix evidence

| Gate | Result |
|---|---|
| Devil's Advocate review | PASS — caught: matcher would over-fire on a successful build referencing PR-schema name; added `test_pr_marker_alone_does_NOT_match` |
| Validator stress (5 negative + 2 positive fixtures) | PASS — 2/2 positive matches, 5/5 negative non-matches, 0 false positives |
| Code Reviewer (yml + py) | PASS — YAML follows header-prescribed schema, py tests follow existing class structure |
| Code Smell (new fns) | PASS — no new fns; tests are flat per-class |
| Regression (1026 → 1046) | PASS — `1046 passed, 2 skipped` (+20 from 1026) |
| Mutation harness (Mut1-Mut7) | PASS — all 8 invariants still CAUGHT (11 mutation tests in TestMutations) |
| Contract (PatternMatch ↔ RCARecord) | PASS — `test_pattern_match_classification_is_enum` covers it; pattern-2 path also tested |
| Snapshot (catalog count 1→2) | PASS — `test_shipped_catalog_count_snapshot` pins count=2 |

## Step 7 — Artifacts shipped

- `scripts/automation/configs/fbin_error_catalog.yml` — Pattern 2 added (1 → 2 patterns)
- `scripts/automation/tests/test_triage_catalog.py` — +20 tests (62 total)
- `docs/triage-agent/fixtures/early_failure_pr_schema_missing_487333396.json` — positive fixture (3,548 B)
- `docs/triage-agent/fixtures/early_failure_manifest_parse_485851058.json` — negative fixture (1,589 B)
- `docs/triage-agent/early-failure-evidence.md` — this report
- `docs/triage-agent/sprint-1-deferred.md` — item #12 added (`logs` allowlist expansion)

## Findings for Sprint 1 backlog

1. **`truncated_debug_logs` is sometimes too short** — for fast-failing
   runs (Cluster A, <1 min duration) the tail truncates BEFORE the
   error appears. Reliable matching needs the `logs` field OR a
   dbt-Cloud-side change to surface the error in `status_message`.
2. **Clusters A and C exist and are real** — once `logs` is allowlisted
   (item #12), both can ship as additional patterns in a follow-up
   commit. Provenance citations are pre-staged: A=run_id=485851058,
   C=run_id=484675412.
3. **DEV env had zero errors in the sample window.** PROD excluded by
   design. Sample is QA-only — generalization to other envs is a
   Sprint-1 validation step.

