# Sprint 1 — Deferred Items Tracker

**Status:** Living checklist. Updated as items close. Reviewed at Phase 1 exit gate.

**Purpose:** Single source of truth for everything that was correctly
deferred during the triage-agent build but MUST be addressed before
Phase 1 exit. Without consolidation, exit review discovers items at the
worst possible time. Each item: what / why deferred / who-when triggers
it / acceptance criteria.

---

## Open items (as of Day 3.7, 2026-06-04)

### 1. `webhook_verifier.py` — Sprint 1 Phase 2 plumbing

- **What:** HMAC signature verifier for dbt Cloud webhook callbacks.
- **Why deferred:** Webhook infrastructure (Phase 2) not stood up yet;
  building the verifier without a real webhook secret to test against
  invites speculative code.
- **Trigger:** When the dbt Cloud webhook endpoint is provisioned in DEV
  (Sprint 1 mid-phase).
- **Acceptance:**
  - HMAC-SHA256 verifier matching dbt Cloud's documented signature scheme
  - Constant-time comparison (no timing leaks)
  - Replay protection (timestamp window + nonce cache)
  - Unit tests with vector pulled from dbt Cloud webhook docs
  - Mutation tests: signature byte-flip → reject; replayed timestamp → reject

### 2. Webhook reliability measurement + replay semantics

- **What:** Define what "at least once" means for our webhook consumer
  and how to detect / handle duplicate deliveries.
- **Why deferred:** Needs production traffic to characterize duplicate
  rate; cannot derive from docs alone.
- **Trigger:** First week of webhook live traffic in DEV.
- **Acceptance:**
  - Documented duplicate-detection key (likely `run_id` + status)
  - Idempotency boundary defined (re-trigger same triage if same key?)
  - Dead-letter behaviour for malformed deliveries

### 3. HMAC signature scheme confirmation

- **What:** Confirm dbt Cloud uses HMAC-SHA256 (not SHA-1, not custom).
- **Why deferred:** Reading docs without access to a real webhook
  configuration is unreliable; vendor docs lag implementation.
- **Trigger:** During webhook creation in the dbt Cloud admin UI.
- **Acceptance:** Documented in `docs/triage-agent/webhook-setup.md` with
  screenshot of the admin signing-secret panel.

### 4. `mcp.json` setup doc consumers

- **What:** Currently `v2-plan.md` §7 references the dbt-mcp config. New
  developers joining the project need a standalone setup doc.
- **Why deferred:** v2-plan is a planning doc, not an onboarding doc;
  separating them is correct, just not urgent.
- **Trigger:** When the second engineer (Barrett or Sonya) starts
  contributing to the triage agent.
- **Acceptance:** `docs/triage-agent/setup.md` with:
  - `.venv` setup
  - dbt-mcp install + config
  - `mcp.json` template (with `<REDACTED>` placeholders, never real secrets)
  - First-run verification command

### 5. Backtest dataset inter-rater reliability (IRR) with Barrett/Sonya

- **What:** Have at least 2 humans independently classify the backtest
  dataset; measure agreement (Cohen's κ ≥ 0.7 target).
- **Why deferred:** Parallel work during Sprint 1; not a Day 3.5 blocker.
- **Trigger:** When backtest dataset is at 50+ labeled examples.
- **Acceptance:**
  - 2+ raters per example
  - Cohen's κ ≥ 0.7 for overall + per-classification breakdown
  - Disagreements adjudicated and documented

### 6. Phase 1 exit review calendar block

- **What:** Schedule the Phase 1 exit review meeting.
- **Why deferred:** Outstanding from earlier rounds; needs calendar
  coordination with DataOps lead.
- **Trigger:** When ≥80% of Sprint 1 items are closed.
- **Acceptance:** 90-min block scheduled with DataOps lead + Barrett +
  Sonya; agenda includes this checklist walkthrough.

### 7. `DATA_GOVERNANCE.OBSERVABILITY` schema existence check

- **What:** Confirm the Snowflake schema for `TRIAGE_INVOCATIONS` exists
  and the agent has WRITE permission.
- **Why deferred:** Schema provisioning is a DBA task; the agent code
  doesn't need it until first write attempt.
- **Trigger:** Before the agent's first end-to-end run in DEV.
- **Acceptance:** `mcp_snow-mcp_run_snowflake_query`-verified existence
  + WRITE grant; documented in `docs/triage-agent/setup.md`.

### 8. Old branch profile-persistence `make_yml.py` collision diff

- **What:** Outstanding from PR #1771 review — compare `make_yml.py`
  changes between `feature/profile-persistence-and-reconciliation` and
  this triage branch; document any unresolved divergence.
- **Why deferred:** PR #1771 not yet merged; collision check needs that
  branch as a stable baseline.
- **Trigger:** Immediately after PR #1771 merge.
- **Acceptance:** Either no divergence (close item) or a follow-up PR
  with a clear conflict-resolution diff.

### 9. `docs/triage-agent/setup.md` — net-new developer onboarding

- **What:** Standalone setup doc (overlaps item #4 above but broader —
  includes Python env, `.venv`, dbt-mcp, mcp.json, and first-run smoke).
- **Why deferred:** Onboarding doc needed when 2nd engineer joins; not
  before.
- **Trigger:** Same as item #4.
- **Acceptance:** New engineer can stand up the triage agent locally
  in ≤30 min from a clean clone using only this doc.

### 10. Mut8 — `provenance.citation` existence check for `lessons_md`

- **What:** New catalog invariant: when `source_type=lessons_md`, the
  citation (e.g., `lesson #120`) MUST resolve to an actual heading in
  `scripts/automation/lessons.md` at load time.
- **Why deferred:** Day 3.5 ships Mut7 (regex *format* check). Mut8
  (existence check) needs a small markdown-heading parser and lives
  one layer beyond schema validation. Catalog has only 1 lessons_md
  pattern today — mis-citation risk is low until Phase C adds more.
- **Trigger:** Before Day 4 Phase C if N>=2 lessons_md citations land;
  otherwise during the Day-5/6 multi-pattern hardening sweep.
- **Acceptance:**
  - `_validate_provenance` raises `CatalogValidationError(Mut8)` when
    `lessons_md` citation does not match a heading in `lessons.md`
  - Mutation harness adds a 9th row — must show CAUGHT
  - Unit test with a deliberately broken citation (e.g., `lesson #999`)
  - Performance: cache `lessons.md` parse so load_catalog stays O(1) per
    pattern

### 11. `docs/triage-agent/catalog-changelog.md` — schema rationale

- **What:** Dedicated changelog for `fbin_error_catalog.yml` schema
  bumps + pattern additions. Currently the v1.0.0 → v1.1.0 rationale
  lives only in commit `e90d6e41` body + the YAML header.
- **Why deferred:** Single-pattern + single-bump catalog doesn't need a
  dedicated changelog yet. Sprint 1 backtest will likely drive 5–10
  pattern additions — changelog earns its keep at that point.
- **Trigger:** When catalog hits >=3 patterns OR a second schema bump
  lands.
- **Acceptance:**
  - Keep-a-changelog format (Unreleased / Added / Changed / Removed)
  - Per-pattern entry includes pattern_id, provenance source, commit SHA
  - Per-schema-bump entry includes Mut additions and migration notes
  - Referenced from the YAML header (replacing the inline doc)

### 12. Expand `REGEX_ELIGIBLE_FIELDS` to include `logs` (with size cap)

- **What:** Allow catalog patterns to match against the `run_steps[*].logs`
  field (full runtime log, up to ~2.9 MB), not just `message`,
  `truncated_debug_logs`, `status_message`. Two Day-4 clusters
  (`manifest_parse_failure` and `dmf_model_compile_failure`) have their
  error keywords ONLY in `logs` because `truncated_debug_logs` truncates
  before the error for sub-1-min runs.
- **Why deferred:** Field-aware allowlist is a load-bearing security
  boundary (Gate-D §3.1). Adding a 2.9 MB field to the allowlist needs
  its own PII surface analysis, size-cap policy (tail-N-KB only?), and a
  new mutation invariant — a self-contained sub-sprint, not a Day-4 hot
  patch. Shipping Pattern 2 first lets us validate the matcher path
  end-to-end while item #12 is queued.
- **Trigger:** When Sprint 1 backtest demonstrates that ≥1 additional
  early-failure subclass is matchable ONLY through `logs` (Clusters A
  and C from Day 4 already meet this bar; pre-staged citations are
  `run_id=485851058` for A and `run_id=484675412` for C).
- **Acceptance:**
  - PII surface re-analyzed on a 10-sample `logs` corpus from QA+DEV
  - `logs` added to `REGEX_ELIGIBLE_FIELDS` with explicit max-bytes
    parameter (default proposal: last 64 KB)
  - New mutation invariant (Mut9-equivalent): a pattern citing `logs`
    without size cap rejected at load time
  - Matcher path size-capped before regex (no full-doc scan)
  - Mutation harness shows 9/9 (or higher) CAUGHT
  - At least 1 of Clusters A/C ships as a new pattern using `logs`
    successfully
  - Performance: matcher latency stays sub-10ms at p95 on 64 KB tail

### 13. Production token migration (BLOCKER for webhook activation)

- **Identified:** 2026-06-04 (during Day 3.8 prep, post-incident review).
- **Blocker for:** Phase 2 (webhook → auto-trigger). Phase 1 manual
  invocation works correctly with personal tokens; this item is
  intentionally NOT a Day 3.8 blocker.
- **What:** Personal PATs (current dev configuration for `dbt-mcp` and
  GitHub access) are unsuitable for production automation. Migrate to
  service identities before the webhook goes live. Drivers: bus factor,
  audit attribution, scope bounding, programmatic rotation, blast-radius
  containment (validated the hard way by `security-incident-2026-06-04`).
- **Migration components:**
  1. **dbt Cloud Service Token** (replaces personal PAT)
     - Account-scoped, not user-scoped
     - Role: Job Admin OR Read-Only (decide per Phase 2 scope review)
     - Created via Account Settings → Service Tokens
     - Same API surface (`kl673.us1.dbt.com/api/v2/...`) — zero code
       change required, only the token source changes
  2. **GitHub App for triage automation** (replaces personal PAT)
     - **Governance decision required** (Joe / FBIN GitHub Apps owner):
       new app `fbin-triage-agent` vs. extending the existing
       `fbin-snowflake-integration` (App ID 1243856).
     - Recommendation: **new app** for blast-radius isolation — a leak of
       the triage agent should NOT compromise Snowflake integration paths,
       and vice versa. Provisioning cost is one-time; isolation is
       permanent.
     - Identity in UI: `fbin-triage-agent[bot]`.
     - **Two-stage permissions grant** (do NOT grant Phase 3 perms in
       Phase 2):

       | Permission | Required for | Phase |
       |---|---|---|
       | `metadata:read` | Repo metadata (always required) | Phase 2 |
       | `contents:read` | Read manifest.json, model files for RCA context | Phase 2 |
       | `issues:write` | Auto-create GitHub issues with RCA | Phase 2 |
       | `contents:write` | Create branch for fix suggestion | Phase 3 only |
       | `pull-requests:write` | Open draft PR with fix | Phase 3 only |

       Rationale: Phase 2 is auto-trigger + RCA card + GitHub issue only.
       Write permissions for branches/PRs are Phase 3 additions that
       gate on CODEOWNERS approval. Granting them in Phase 2 expands
       blast radius without functional benefit.
  3. **`redact.py` credential-sentinel coverage**
     - dbt service tokens have a different prefix shape than user PATs;
       the sentinel regex must match BOTH shapes or service tokens leak
       through unchecked.
     - GitHub App installation tokens start with `ghs_`; classic PATs
       are `ghp_`; fine-grained PATs are `github_pat_`. Sentinel must
       match all three.
     - Add a new mutation invariant (Mut10-equivalent — successor to the
       Day 3.8 Mut9 floor): mutate the sentinel regex to drop service-
       token shape → fixtures with service tokens MUST trip the sentinel-
       halt path identical to existing PAT behaviour.
  4. **Rotation runbook**
     - Document at `docs/triage-agent/token-rotation-runbook.md`.
     - dbt service tokens: rotation cadence, who has rights, evidence of
       rotation.
     - GitHub App installation tokens: auto-refresh (1-hour TTL) — the
       runbook covers private-key rotation, not installation-token
       rotation.
     - Both: pre-rotation health check, post-rotation smoke test
       (matches the Gate A smoke-test pattern used during
       `security-incident-2026-06-04` recovery).
- **Why deferred:** Migration touches three different governance owners
  (dbt Cloud admin, FBIN GitHub Apps governance, FBIN security for
  rotation cadence). Coordinating that during Day 3.8 (a focused
  redact.py amendment) would conflate scopes. Phase 1 ships on personal
  tokens because Phase 1 is single-operator; Phase 2 ships on service
  identities because Phase 2 is unattended.
- **Trigger:** Before any Phase 2 webhook activation in QA. Earliest:
  immediately after Sprint 1 #1 (webhook_verifier.py) lands; latest:
  the PR that flips webhook traffic on.
- **Acceptance:**
  - dbt service token provisioned; role scope reviewed by Joe + Carina
    POD lead.
  - GitHub App provisioned (new or extended per governance decision);
    Phase 2 permission floor enforced.
  - `mcp.example.json` documents both new token sources via
    `${input:...}`; zero personal PAT references in any committed
    template, example, or runtime config.
  - `redact.py` credential-sentinel updated; regression tests confirm:
    - All existing Mut1–Mut7 + Mut9a–Mut9d fixtures still pass.
    - New service-token-shape fixtures trigger the sentinel.
    - New `ghs_*`, `ghp_*`, and `github_pat_*` fixtures trigger the
      sentinel.
  - Webhook live in QA against service token; zero personal PAT
    references in agent code path or runtime env (`grep -r ghp_ scripts/`
    and `grep -r 'kl673.*personal' scripts/` both empty).
  - Rotation runbook reviewed; first dry-run rotation completed.
  - Old personal PATs revoked; audit confirms agent runs on service
    identity (dbt Cloud audit log + GitHub App installation log both
    show bot identity, not `sganapat`).
- **Open questions (decide before implementation):**
  1. **dbt service token role:** Job Admin (Phase 2 retry capability) vs.
     Read-Only (Phase 2 RCA only, no retry)?
  2. **GitHub App: new or extend existing?** Recommendation = new for
     blast-radius isolation; defer to Joe / GitHub Apps governance.
  3. **Rotation cadence:** 90 days? Aligned with org SOC 2 / SOX
     schedule? Document the decision and rationale.

### 14. Day-4 Phase B/C catalog patterns — BLOCKED pending Gate-D Round 3

- **What:** Cluster A (`manifest_parse_failure`) and Cluster C
  (`dbt_database_error` on `__dmf_code` tests) catalog patterns that
  cite the `logs` field via `signal_sources: [logs]`.
- **Why blocked:** P0.1 empirical inspection of the 7 Day-4 sample
  payloads (2026-06-05) found that 3/7 — all Cluster A — place the
  actionable error block ≈ 2.67 MB outside the ±16 KB anchor window
  defined by `redact.py::truncate_logs`. The remaining 4/7 payloads
  land in-window but with margins 542 / 929 / 941 / 1,683 bytes (all
  below the 4 KB safety threshold). The hybrid truncation strategy as
  specified in `gate-d-logs-field-amendment.md` §3.2 is therefore
  falsified on this sample. Building catalog patterns against a
  falsified truncator would ship false-positive matches (LLM sees
  unrelated `\bfailed\b` noise from the dbt manifest dump instead of
  the real error block).
- **Trigger:** Gate-D Round 3 closes with a revised anchor-selection
  algorithm whose P0.1-equivalent inspection on the same 7 payloads
  yields zero out-of-window cases and minimum margin ≥ 4 KB.
- **Evidence:** `~/scratch/triage-day38/p0_1_inspection.json` plus the
  inspection script `~/scratch/triage-day38/p0_1_inspection.py` and
  Cluster A schema probe `~/scratch/triage-day38/p0_1_cluster_a_investigation.py`.
- **Acceptance:**
  - Gate-D Round 3 pre-announce document landed (separate session) with
    explicit anchor-selection-algorithm interrogation (not just
    same-position tie-breaks — see lessons-learned.md 2026-06-05 entry)
  - P0.1-equivalent inspection passes on all 7 payloads under the
    revised algorithm
  - `redact.py` NOTICE block (added in the same commit as this item)
    removed; `truncate_logs` docstring updated
  - Mut9d catalog-load-time gate remains in place; first `logs`-citing
    catalog pattern lands together with passing inspection evidence

### Update 2026-06-05 — Round 3 escalated to Round 3.5

Round 3 pre-announce iteration did not converge (5 revisions,
monotonically rising blocker count, same defect class recurring
across sections). Per Rev 5 pre-announce §3.2 lines 167-177 and
§10 step 3a, escalated to Round 3.5 methodology pivot. Round 3.5
inherits S1-S4 simplifications:
- S1: explicit per-branch margin aggregation rule
- S2: parameter-extension viability path deleted
- S3: binary operability check (threshold table removed)
- S4: doc-wide quantitative-bounds annotation rule

BLOCK posture extends through Round 3.5 closure.

### Update 2026-06-05 (final) — Round 3.5.5 CLOSED; item moved to Closed items

Round 3.5.5 was closed by a 5-rule algorithm spike (specifically:
generics removed from ERROR_ANCHORS, earliest-position-wins, 5-rule
flow). Spike ran 7/7 PASS on real P0.1 payloads and 8/8 PASS on
synthetic boundary fixtures (15/15 overall). The Round 3 → 3.5 → 3.5.5
methodology iteration was superseded by a 30-minute binary spike whose
acceptance criterion was pre-committed.

The empirical-cap-on-methodology-iteration lesson is captured in
lessons-learned.md 2026-06-05 entry 4. Item #14 has been moved to
"Closed items" below with the landing commit reference.

### 16. `REGEX_ELIGIBLE_FIELDS` expansion for `debug_logs` (4.3 MB) — Round-4 trigger gated on Day-6+ backtest evidence

- **Identified:** 2026-06-06 during Day-5 Q2-open validation probe
  (entry-5 probe-validation discipline applied to LITERAL_V2
  projection ahead of orchestrator skeleton design).
- **What:** Add `debug_logs` to `redact.REGEX_ELIGIBLE_FIELDS` so
  catalog patterns can match against the raw debug-log stream that
  dbt Cloud emits alongside (and separately from) the existing
  `logs` and `truncated_debug_logs` fields.
- **Producer-shape evidence** (Q2-open validation probe,
  `~/scratch/triage-day5/q2_open_validation_probe.py` —
  uncommitted, probe-only):
  - `debug_logs` is a real dbt Cloud Admin v2 API field present at
    `data.run_steps[*].debug_logs` on every step in every payload
    of the 7-payload P0.1 corpus
  - Sizes across the corpus: 94,900 B (Cluster C run 484675412),
    4,343,043 B – 4,344,306 B (Cluster A runs 485821754 /
    485850628 / 485851058), 4,343,043 B (Cluster C run 486060143),
    538,881 B – 538,916 B (Cluster B runs 487313189 / 487333396)
  - Stable across A/B/C clusters (uniform 27-key `run_step` schema;
    not a clustered anomaly)
  - Distinct from `truncated_debug_logs` (which sits at ~1–4 KB and
    is ALREADY in `REGEX_ELIGIBLE_FIELDS`)
- **Why deferred (Phase-1 correctness not blocked):**
  - All 7 P0.1 payloads classify correctly under the current
    `REGEX_ELIGIBLE_FIELDS = {logs, message, status_message,
    truncated_debug_logs}` set: Cluster A → Pattern 3 ×3,
    Cluster B → Pattern 2 ×2, Cluster C → 0 matches ×2, zero
    multi-pattern hits
  - The orchestrator does NOT need `debug_logs` to produce
    correct RCARecords on the Phase-1 corpus
  - Expanding `REGEX_ELIGIBLE_FIELDS` is a separate redactor
    amendment (analogous in scope to Sprint-1 #12 for `logs`):
    requires its own PII surface analysis, its own truncation
    strategy spike (truncate_logs v2 was empirically validated to
    2.9 MB log size; 4.3 MB debug_logs is 1.5× larger and needs
    re-validation), and its own Mut9-class load-time gate
    (`max_bytes` cap for any pattern citing `debug_logs`)
  - Shipping it as a Day-5 hot-patch would conflate scopes
    (Sprint-1 #12 precedent — `logs` field expansion was its own
    sub-sprint)
- **Round-4 trigger:** Day-6+ backtest harness produces ≥1 labeled
  failure whose actionable error context lives ONLY in `debug_logs`
  (not reproducible via `logs`, `truncated_debug_logs`, `message`,
  or `status_message`). Until that empirical signal exists,
  shipping the expansion is speculation per lesson 4 spike-or-
  iterate discipline.
- **Pre-staged scope** (do NOT ship until trigger met):
  - PII surface analysis on a 10+ sample `debug_logs` corpus
    (mirrors Sprint-1 #12 acceptance step 1)
  - `debug_logs` added to `REGEX_ELIGIBLE_FIELDS` with explicit
    `max_bytes` parameter; default proposal: same 64 KB cap as
    `logs` (re-uses `LOGS_MAX_BYTES`; if `debug_logs` truncation
    strategy diverges, introduce a separate `DEBUG_LOGS_MAX_BYTES`)
  - New Mut9-class invariant in `fbin_error_catalog.py`: a
    pattern citing `debug_logs` without `max_bytes` rejected at
    load time
  - `redact._redact_node` dispatcher branch for `debug_logs` that
    applies truncation BEFORE credential sentinel + email
    (mirrors the existing `logs` ordering — Gate 7 contract)
  - Truncation strategy validation at 4.3 MB scale: either re-use
    `truncate_logs` v2 unchanged (requires evidence that the
    5-rule algorithm picks correct anchors at 4.3 MB) or a new
    `truncate_debug_logs` function with its own anchor set + tests
  - At least 1 catalog pattern shipped that genuinely requires
    `debug_logs` to fire (proves the expansion earns its keep)
- **Why C3 (deferral as positive decision):** Same triad as item
  #15 — single-pattern shipping discipline + empirical-bar
  discipline + positive-audit-trail discipline all converge on
  deferral. The Q2-open probe surfaced this finding correctly per
  entry-5 (producer-shape inspection before adjudication); the
  finding does not invalidate any current behavior; it flags a
  Day-6+ catalog-evolution slot.
- **Cross-references:**
  - Sprint-1 #12 (closed) — `logs` field expansion precedent;
    same shape as this item
  - lessons-learned.md 2026-06-06 entry 5 — probe-validation
    discipline that surfaced the finding
  - PII surface analysis (pre-staged scope above) will need a
    fresh `debug_logs` corpus pull when the Round-4 trigger fires;
    no committed fixture in this repo preserves `debug_logs`
    content (Cluster C fixture committed alongside this entry
    strips `debug_logs` to bound fixture size — orchestrator does
    not read the field, so retaining 4.3 MB of raw content in a
    regression fixture is unjustifiable)

---

### 17. ORCH re-audit pending — same PARTIAL-as-DONE pattern as BACKTEST (BLOCKS next-deliverable opening)

**Status:** CLOSED 2026-06-08. See "Closed items" section below for the
landing commit reference. Re-audit decomposed ORCH (w3 PARTIAL-as-DONE)
into ORCH-EARLY-FAILURE (w2 DONE) + ORCH-CIRCUIT-OPEN (w1 NOT STARTED)
+ ORCH-ARTIFACT-MODE (w1 NOT STARTED contingent); ORCH-MULTI-PATTERN
moved to "Items NOT scored" per §1 explicit out-of-scope. Score
corrected 13/19 = 68% → 12/20 = 60.0% (pickup-memo predicted 58–63%
range). 3rd PARTIAL-as-DONE firing did NOT materialize during the
re-audit; tracker stays at 2/3. Empty-projection-after-redact coverage
gap surfaced honestly and queued as sprint-1-deferred #18.

**Spec-split update 2026-06-09 entry 4.** The ORCH-CIRCUIT-OPEN
sub-item from this decomposition was subsequently row-split per
`phase-1-exit-checklist.md` §7 entry 2026-06-09 entry 4. The L484
proposed-decomposition-shape paragraph for ORCH-CIRCUIT-OPEN ("Q2e-1
work: design + implement + test circuit-breaker open/close state
with retention + half-open probe semantics") is hereby Phase-2
work — the stateful breaker is class-3 phase-impossible in Phase-1
because the wrappable remote-API surface set is empty (no
DBT-CLOUD-CLIENT, no LLM client, OBS-DDL writer outside CB scope).
The v2-plan §1.8 *fail-open* property (Spec A — a stateless per-
invocation property the §1.8 header misnames "Fail-open circuit
breaker") was extracted as the new ORCH-FAIL-OPEN class-1 row in
the same entry-4 commit; the Q2e-1 decomposition retained here
refers only to the stateful Spec B/C feature. Item #17 itself
remains CLOSED; this note exists for forward-chain-of-custody so
a future reader sees Q2e-1's Phase-1 → Phase-2 reclassification
without re-deriving it from entry 4.

**Original block retained below for historical chain of custody.**

**What this is.** Devil's Advocate review of the Day-6 BACKTEST commit
(`68b980ad`) surfaced that BACKTEST had been scored PARTIAL with
full weight-3 credit by redefining the §1 acceptance criterion
mid-flight — a §2 anti-gaming violation. Resolution was decomposition:
BACKTEST (w3) → BACKTEST-HARNESS (w1 DONE) + BACKTEST-CORPUS (w2
NOT STARTED). Score honestly revised 79% → 68%.

ORCH (RCA orchestrator) was scored the same way one session earlier
(Day-5 commit `0e008580`): PARTIAL with weight-3 credit, with the
deferred sub-decisions (CIRCUIT_OPEN handling, artifact-mode path,
multi-pattern resolution) absorbed into a same-shape redefine-the-
criterion maneuver. The DA report flagged this explicitly. Day-6
session scope was BACKTEST-only, so the ORCH correction was deferred
rather than absorbed into the BACKTEST commit (which would have
diluted the audit trail).

**Why this BLOCKS next-deliverable opening.** Section §2 of the exit
checklist is the meta-discipline that keeps Phase-1 honest. Two
consecutive PARTIAL-as-DONE instances both caught by DA at adjudication
time (not at execution time) is a recurring-defect-class signal —
the same Round-3 → Round-3.5 escalation pattern. If a third instance
ships before the rule is enforced consistently, the discipline has
failed in practice regardless of what the document says.

The fix is mechanical and small. Apply the BACKTEST decomposition
shape to ORCH next session, before any new Phase-1 sub-item starts.

**Proposed decomposition shape (pre-drafted for next session).**

The Day-5 ORCH row reads (paraphrased): "RCA orchestrator
(`failure_triage_agent.py`) wiring the redact → matcher → emit
pipeline with circuit breaker, sentinel handling, artifact-mode
fallback, and multi-pattern resolution." Weight 3 (critical).

Suggested decomposition (subject to next-session adjudication):

- **ORCH-EARLY-FAILURE (weight 1 or 2, DONE)** — early-failure path:
  redact_early_failure → catalog matcher → _classified emission;
  sentinel boundary handling via `CredentialSentinelFired`; UNKNOWN
  fallback path. Validated via 1,184 tests including the 55 backtest
  tests landed this session. Confidence: high.
- **ORCH-CIRCUIT-OPEN (weight 1, NOT STARTED)** — Q2e-1 work: design
  + implement + test circuit-breaker open/close state with retention
  + half-open probe semantics. Acceptance: backtest emits
  `Outcome.CIRCUIT_OPEN` for at least one labelled case + sentinel-
  test corpus admits the outcome as labellable.
- **ORCH-ARTIFACT-MODE (weight 0.5, NOT STARTED, contingent)** —
  artifact-mode path (when run_results.json or other artifacts are
  available). Acceptance: at least one fixture with artifact-mode
  trigger + scoring path exercised end-to-end. Contingent on
  artifact corpus availability (which depends on the same Phase-2
  raw-payload-repository decision flagged in BACKTEST-CORPUS).
- **ORCH-MULTI-PATTERN (weight 0.5, NOT STARTED, contingent)** —
  resolution when two catalog patterns match the same payload.
  Acceptance: at least one fixture demonstrating multi-match +
  documented resolution rule (current code returns first-match;
  whether that is correct is contingent on backtest evidence
  showing multi-match frequency).

**Total weight unchanged (3).** Done credit net change after
adjudication: −1 to −2 weight points (vs current ORCH=DONE w3).
Estimated score impact: 68% → ~58% to ~63% pending which sub-weights
are awarded as DONE. Honest either way.

**Acceptance criteria for closing this item.**
1. ORCH row in `phase-1-exit-checklist.md` decomposed per (or
   adjudicated from) the proposed shape.
2. New §7 entry recording the decomposition with chain-of-custody
   reference back to this item.
3. Score column in §4 progress table updated to reflect the new
   weight distribution.
4. Distance-to-exit recomputed.
5. Commit message references this item by number.

**Closure criterion.** This item closes ONLY when commit lands on
the branch with the four artifacts above. No other action satisfies
it. Drift across multiple sessions is the failure mode this entry
exists to prevent.

**Meta-pattern flag.** Two PARTIAL-as-DONE instances in two
consecutive sessions, both caught by DA at adjudication, neither
at session-execution time. Two doesn't mean methodology failure —
both got caught and remediated cleanly. Three would be worth pausing
to ask whether the checklist scoring rule itself needs revision
(e.g., explicit guidance: PARTIAL items MUST decompose into DONE +
NOT-STARTED sub-items rather than receive partial credit on the
parent). Track this here so that if a third instance appears next
session, the meta-pattern is visible without re-derivation.

**Related artifacts.**
- BACKTEST commit: `68b980ad` (sets the precedent; cite in next-
  session adjudication)
- DA report excerpt: enumerated in the BACKTEST commit message body
  under "DA review surfaced lead-objection + 2 P0s + 4 P1s + 5 P2s"
- Checklist §7 entry (BACKTEST decomposition): canonical template
  for the ORCH §7 entry

---

### 18. ORCH-EARLY-FAILURE coverage gap — empty-projection-after-redact defensive branch

**Identified:** 2026-06-08 during ORCH re-audit (sprint-1-deferred #17
closure). Surfaced proactively rather than absorbed silently — honest
gap-tracking compounds (lesson: future readers see "DONE with coverage
gap (specific location, specific reason)" instead of "DONE (implied
complete coverage)").

**Branch:** `scripts/automation/src/triage/failure_triage_agent.py`
L243-250 (empty-projection-after-redact defensive fallthrough). Emits
`UNKNOWN_HANDED_TO_HUMAN` with rationale `"no extractable eligible
fields: redacted payload has no REGEX_ELIGIBLE content under
data.run_steps[-1] or data"`.

**Gap:** Structurally-hard-to-reach path (requires sentinel-driven
full-field redaction OR a payload that passes `_detect_mode` but whose
eligible fields are all stripped by the redactor before projection)
lacks dedicated test coverage. None of the 26 tests in
`tests/test_triage_orchestrator.py` exercise this specific branch.

**Impact:** Low. Branch is defensive; no current production correctness
concern. Documented in `phase-1-exit-checklist.md` ORCH-EARLY-FAILURE
row Evidence column.

**Resolution:** ~15 lines of synthetic-payload test exercising the
branch + mutation test on the branch's `if not projection:` guard.
Separate small follow-up commit; not Phase-1-exit-blocking.

**Trigger:** Do anytime before Phase-1 exit review; defer to end-of-
Phase-1 cleanup commit if convenient. If a future change adds a new
redaction path that strips eligible fields, prioritize this item
before that change lands.

**Acceptance:**
- One synthetic test demonstrating the branch is reachable (e.g.,
  construct a payload whose only eligible field is filled with content
  that the credential sentinel halts on — though sentinel raises
  CredentialSentinelFired, not strip; the more reachable path is a
  future redaction strategy that legitimately empties a field).
  Alternative: monkey-patch `_project_payload` to return `{}` in one
  test and assert the orchestrator emits the documented rationale.
- One mutation test: flip the `if not projection:` guard, verify a
  test fails.
- No production code changes required (branch already exists; only
  test coverage is missing).

**Related artifacts:**
- sprint-1-deferred #17 (ORCH re-audit closure entry — this item is
  spawned from that audit)
- `phase-1-exit-checklist.md` §7 entry 2026-06-08 (ORCH decomposition)

---

### 19. `TRIAGE_AGENT_WRITER` service-role narrowing for OPS_PROD.LOGS.TRIAGE_INVOCATIONS

**Identified:** 2026-06-08 during OBS-DDL drafting + cross-review.
Surfaced as an explicit follow-up (not silently absorbed) so the
least-privilege intent has a durable home outside the SQL header
comment alone.

**Current state:** `scripts/automation/src/triage/ddl/triage_invocations.sql`
header (f) + GRANT block grant `INSERT, SELECT` on the table to ROLE
`DATA_OPS`, which is the agent's runtime role per
`docs/triage-agent/setup.md §6`. Today's setup does not contain a
narrower service role.

**Gap:** RBAC best practice for an agent-write target is a dedicated
service role (e.g., `TRIAGE_AGENT_WRITER`) with only the privileges
needed (INSERT + SELECT on this single table). DATA_OPS is broader
than necessary for the agent's runtime needs.

**Impact:** Low. The agent runs in a restricted Snowflake context
already; the writer-role broadening is theoretical until the agent
has an executable surface (DBT-CLOUD-CLIENT, Phase-2 webhook). No
data-correctness risk.

**Resolution path (no schema change required):**
1. Provision `TRIAGE_AGENT_WRITER` role in OPS_PROD.
2. `GRANT INSERT, SELECT ON OPS_PROD.LOGS.TRIAGE_INVOCATIONS TO ROLE TRIAGE_AGENT_WRITER;`
3. Bind the agent's runtime service principal to the new role.
4. `REVOKE INSERT ON OPS_PROD.LOGS.TRIAGE_INVOCATIONS FROM ROLE DATA_OPS;`
   (preserve SELECT for operator interactive use per setup.md §6).
5. Update `setup.md §6` runtime-role line and OBS-DDL SQL header (f).

**Trigger:** Before DBT-CLOUD-CLIENT goes live in production, OR
before Phase-2 webhook activation — whichever comes first. Not a
Phase-1-exit blocker; OBS-DDL is `ready-to-deploy` against the
DATA_OPS-as-writer arrangement today.

**Acceptance:**
- New role exists in OPS_PROD with INSERT + SELECT only on this table.
- Agent's runtime principal is bound to the new role (verified via
  `SHOW GRANTS TO ROLE`).
- DATA_OPS retains SELECT (operator read access).
- SQL header (f) and `setup.md §6` updated to reflect post-narrowing
  state.

**Related artifacts:**
- `scripts/automation/src/triage/ddl/triage_invocations.sql` header (f)
  + GRANT block (substitution path documented in-place).
- `docs/triage-agent/setup.md §6` runtime-role declaration.
- `docs/triage-agent/v2-plan.md §6` landing-zone rationale.

### 20. DBT-CLOUD-CLIENT — design carry-overs for the eventual Phase-2 implementation brief

**Identified:** 2026-06-08 during DBT-CLOUD-CLIENT validation pass (lesson
5 probe-validation discipline + lesson 4 spike-or-iterate), BEFORE any code
was written.

**Resolution decided this session:** Option A — reclassified DBT-CLOUD-CLIENT
from SCORED/NOT-STARTED to NOT-SCORED with a Phase-2 trigger (webhook
activation). See `phase-1-exit-checklist.md §7 entry 2026-06-08 (entry 4)`
for the full adjudication chain. The wrapper has NO Phase-1 consumer
(`triage_failure(raw_payload: dict)` is the sole public entry per
`failure_triage_agent.py:216`; backtest replays via direct payload feed
per `backtest_scoring.py:161`); its real consumer is the Phase-2 webhook
handler. Option B (typed stub + new entry point) rejected as a spike-or-
iterate violation. Denominator drops 20 → 19; score 15/20 → 15/19 = 78.9%.

**Purpose of this entry:** the validation pass surfaced concrete design
concerns + a precedent + a naming-drift flag that would be lost if we only
recorded "DBT-CLOUD-CLIENT is Phase-2 now." Banking them here so the
eventual Phase-2 implementation brief inherits them.

**Design carry-over A — mode-selection must check artifact LIST, not just
the error-endpoint status.** v2-plan §1.1's `select_evidence_mode` sketch:

```python
try:
    error_data = client.get_job_run_error(run_id)
    if error_data and error_data.get("status") in ("error", "fail"):
        return EvidenceMode.ARTIFACT
except HTTPError as e:
    if e.status_code != 404:
        raise
return EvidenceMode.EARLY_FAILURE
```

The §1.1 table promises early-failure triggers on "`get_job_run_error`
returns 404 **OR** artifact list is empty." The sketch only handles the
404 branch and the status-check branch — it never inspects the artifact
list. A run that returns 200 with `status="error"` but produces no
`run_results.json` would route to ARTIFACT mode and then fail downstream
when the artifact fetch comes back empty. Phase-2 implementation must
check artifact availability, not just the error endpoint's status.

**Design carry-over B — acquisition-API errors must route to §1.8 fail-
open, not bare `raise`.** The §1.1 snippet re-raises non-404 HTTPErrors.
This contradicts §1.8 fail-open: the agent never blocks the pipeline and
emits `unknown` on infrastructure failure. §1.8's failure-mode enumeration
("LLM call times out" + "redact raises") is incomplete — "acquisition API
errors (dbt Cloud 5xx, network drop, timeout, connection reset)" must be
added and must route to the same fail-open path: `RCARecord` with
`outcome=UNKNOWN_HANDED_TO_HUMAN` + `requires_human_review=True` +
rationale carrying the acquisition error class + retry-attempt count.
The agent is a co-pilot, not a gate.

**House MCP-wrapper pattern (precedent, to be inherited):** when Phase-2
builds `dbt_cloud_client.py`, mirror the snow-mcp bridge pattern at
`scripts/automation/mcp_profile_patch.py:58-120`:

- Typed Python methods over the official Python MCP SDK (`ClientSession` +
  `stdio_client`). Each method (`get_job_run_error(run_id) -> dict | None`,
  `get_job_run_artifact(run_id, path: str) -> dict | None`,
  `get_job_run_details(run_id, include_related: list[str]) -> dict | None`)
  returns plain dicts; MCP invocation is internal to the method.
- NOT envelope pass-through (no tool-call envelope in / tool-result
  envelope out). Mocking at the MCP-protocol layer couples tests to
  dbt-mcp's wire format and breaks every time the MCP server's response
  envelope shifts.
- Fixture-replay shim = `FixtureReplayDbtCloudClient` subclass of
  `DbtCloudClient` returning fixture dicts keyed by `(run_id, operation)`.
  Mocks at the Python seam, not the wire — the only choice that gives
  deterministic replay.
- "Thin" in "thin wrapper" means *thin translation* (MCP call → dict),
  NOT *thin pass-through* (envelope in → envelope out).

**Naming-drift flag:** v2-plan §1.1 and §2 reference `triage_agent.py` as
the agent's Python module. The actual artifact is
`scripts/automation/src/triage/failure_triage_agent.py`. The Phase-2 brief
must use the actual filename to avoid the same drift that propagated into
the L125 row's "callable by ORCH" rationale.

**Implicit exit-bar problem (recorded for the eventual Phase-2 brief):**
the original L125 bar ("thin wrapper over dbt-mcp for payload retrieval")
was underspecified. When DBT-CLOUD-CLIENT is reopened in Phase 2, define
the bar before drafting (OBS-DDL's L124 DRAFTED + REVIEWED + READY-TO-
DEPLOY is the model). Proposed Phase-2 bar:
1. Four typed operations implemented (`get_job_run_error`,
   `get_job_run_artifact`, `get_job_run_details`, implicit artifact-list
   check).
2. Typed-method-not-envelope decision locked in design notes.
3. Fixture-replay shim covering both modes (artifact + early-failure —
   §1.1 says the official tooling doesn't handle early-failure and that
   gap is the agent's genuine value).
4. Fail-open behavior per §1.8: client raising must result in
   `unknown` + human-review, not an unhandled exception. Testable and
   load-bearing.

**Trigger:** Phase-2 webhook activation (Gate E follow-ups, v2-plan §4).
NOT before — opening DBT-CLOUD-CLIENT in Phase 1 with no consumer is the
exact failure mode this deferral prevents.

**Not a Phase-1-exit blocker.** Phase-1 exit math is now 15/19 = 78.9%
with +4 weight remaining (BACKTEST-CORPUS, ORCH-CIRCUIT-OPEN, ORCH-
ARTIFACT-MODE). DBT-CLOUD-CLIENT is genuinely Phase-2 scope and
reclassification is the honest accounting.

**Related artifacts:**
- `docs/triage-agent/phase-1-exit-checklist.md §3` Medium-tier row
  (RECLASSIFIED pointer) + Items-NOT-scored entry.
- `docs/triage-agent/phase-1-exit-checklist.md §7 entry 2026-06-08
  (entry 4)` — full adjudication chain + the four validation findings.
- `docs/triage-agent/v2-plan.md §1.1` — the `select_evidence_mode` sketch
  this entry's design carry-overs adjudicate.
- `docs/triage-agent/v2-plan.md §1.8` — the fail-open contract the
  acquisition-API errors must route to.
- `scripts/automation/src/triage/failure_triage_agent.py:216` — the sole
  current entry point that the wrapper does NOT integrate with.
- `scripts/automation/src/triage/backtest_scoring.py:161` — the sole
  non-test caller, proves backtest doesn't need a client.
- `scripts/automation/mcp_profile_patch.py:58-120` — the snow-mcp
  precedent the wrapper should mirror.

---

### 22. BACKTEST-CORPUS — Phase-2 work brief (design carry-overs from the 2026-06-09 entry 2 reclassification)

**CLOSED 2026-06-11** — sprint-1-deferred #22 done-state achieved
 via Commit B amended-and-pushed `33c7e9d7` (superseded local-only
 `bb18c015` per D4 cross-review verdict). Closure evidence:

 - **Done-state proven.** Backtest at label-schema v1.1.0 against
   the repointed corpus produced 7/7 = 1.000/1.000
   (`/tmp/backtest-commit-b-validation.md`), matching the §4 prose
   baseline pinned in `phase-1-exit-checklist.md`.
 - **Single-provenance corpus.** All 7 entries flipped
   `scratch → fixture` in Commit A's `label-schema.v1.1.0.yaml`; the
   backtest harness load path is now committed-bytes-only and
   reproducible from a clean clone (raws-only idempotency tests
   `pytest.skip` when `~/scratch/triage-day4/` absent).
 - **G7-1 retired by contract.** `scripts/automation/src/triage/`
   `fixture_loader.py` introduces the single chokepoint that
   explicitly pops `_fixture_metadata`; `_redact_node`'s
   dispatcher-drop branch is no longer load-bearing for
   metadata-strip semantics. Cross-consumer guarantees enforced by
   `test_fixture_loader.py` (12 tests, parametrized over all 7
   fixtures).
 - **Corpus-accretion runway laid.** `KNOWN_CLUSTERS` enumeration,
   glob-driven parametrization (`test_band_table_covers_all_committed_fixtures`),
   per-fixture `EXPECTED_BANDS` table (7 entries, ±20%), and the
   `TestRedactorPipelineIdempotency` re-emit-byte-compare suite mean
   new fixtures land via the pipeline and are auto-asserted by the
   existing test surface.

Residual carry-over to Phase-2 webhook activation: the held-out
production-failure floor (≥20 net-new payloads per the original
Phase-1 quality bar) remains gated on webhook acquisition channel;
the corpus-accretion machinery above is the runway, not the
attainment.

---

**Identified.** 2026-06-09 entry 2 (Phase-1 checklist §7). BACKTEST-
CORPUS (w2, NOT STARTED) reclassified from §3 critical-path to
"Items NOT scored" with Phase-2-webhook-trigger. The corpus-size
criterion of the original BACKTEST item (≥20 labeled held-out
production failures with precision/recall reported) is genuinely
Phase-2 work because all three acquisition channels for the ≥20
*net-new held-out* payloads the gate requires (the existing 7
in-sample payloads do NOT count toward the held-out floor per the
gate spec clause (b)) are Phase-2-gated: (a) PAT-driven manual
scratch pulls couple Phase-1 exit to an uncontrolled external
failure-arrival process; (b) `dbt_cloud_client.py` is itself
reclassified to NOT-scored in entry 4 (#20) with Phase-2 webhook
trigger; (c) synthetic violates the held-out criterion. Phase-2 webhook
activation is the only honest at-scale acquisition channel. See
§7 entry 2026-06-09 entry 2 for full validation findings.

**Resolution decided this session (β shape, the structural answer
the user chose over α manual-pull and γ second-decompose).** β was
selected because: (1) α makes Phase-1 exit a hostage to external
failure arrivals — a control-failure pattern; (2) γ would be the
third PARTIAL-as-DONE firing on a lineage that was already
decomposed once at §7 entry 2026-06-07 (BACKTEST → BACKTEST-HARNESS
DONE + BACKTEST-CORPUS NOT-STARTED), and re-decomposing because
completion is hard is forbidden by §2 of the checklist; (3) β
makes the no-held-out-accuracy-at-Phase-1-exit limitation explicit
and relocates the §1.3 quality bar to a named Phase-2 precondition
(see `docs/triage-agent/phase-2-backtest-corpus-gate.md`) rather
than silently deleting it.

**Design carry-overs (banked so Phase-2 open does not re-litigate
these decisions).**

- **Storage strategy A confirmed; B eliminated permanently.**
  Strategy A = commit redacted/minimized JSON fixtures under
  `docs/triage-agent/fixtures/**` (the path the entry-7 hook
  already watches per #21 closure). Strategy B (git-LFS) is
  permanently eliminated: LFS solves a size problem (~260–400 KB
  for 20–30 minimized payloads — not a size problem) and adds
  toolchain dependency (per-clone `git lfs install`, CI LFS auth)
  while leaving the PII story unchanged (LFS bytes ARE repo
  content). Re-opening Strategy B at Phase-2 is forbidden absent
  new evidence (e.g., per-payload size blowup > 50× current
  baseline).
- **Strategy C (synthetic) scope-limited.** Synthetic payloads are
  legitimate ONLY for sentinel-fire coverage scaffolding (e.g.,
  redaction-sentinel verification cases that no real production
  payload can produce by definition) and MUST be provenance-
  labeled `derivation: synthetic` in their label entry. Synthetic
  payloads NEVER count toward the ≥20 held-out production
  floor — they are explicitly excluded from the precision/recall
  denominator per the Phase-2 gate spec clause (b)/(c)/(e).
- **Day-zero minimizer target: close the in-sample reproducibility
  hole (4/7 committed → 7/7 committed).** This is a reproducibility
  hole, not a TODO. `p01_labels.yml` lists 7 label entries;
  `docs/triage-agent/fixtures/` holds only 4 redacted JSONs. The
  other 3 (`run_485850628_cluster_A`, `run_487313189_cluster_B`,
  `run_484675412_cluster_C` per their `payload_path:
  "~/scratch/triage-day4/run_*.json"` field) live in the author's
  uncommitted scratch dir. The β reclassification (the
  bfd97552 → b64d6c7b commit chain) affirmed the harness +
  7-payload in-sample baseline as the delivered Phase-1 work —
  but "delivered" implies reproducible-from-clean-clone, and the
  4 committed fixtures alone cannot regenerate the 7-payload
  baseline that `backtest-baseline-2026-06-07.md` reports. **The
  minimizer's day-zero job, before ANY new corpus accretion, is
  closing the in-sample baseline from 4/7 committed to 7/7
  committed** — making the β-affirmed "delivered Phase-1 baseline"
  actually reproducible from a clean clone, which is the bar a
  delivered-and-affirmed Phase-1 artifact has to meet.

  **Integration check: test-passing on re-emitted fixtures, NOT
  byte-equality against hand-sanitized.** The minimizer ALSO
  re-emits the existing 4 hand-sanitized fixtures from the
  `redact.py` contract (replacing hand-sanitization), and the
  assertion is: **the existing test consumers of those 4 fixtures
  stay green.** Passing tests demonstrate the production-redaction
  contract reproduces what hand-sanitization produced on the
  dimensions the tests check. A test break is the real signal —
  a property the hand fixture carried that the production
  contract doesn't — and is the first bug the minimizer surfaces.

  **Why NOT byte-for-byte against the hand fixtures (load-bearing
  distinction so a future reader doesn't reintroduce the trap):**
  (1) The minimizer does **redaction**, not **minimization**.
  `redact.py`'s contract is allowlist + truncate + sentinel +
  email pass — it does not subset-select fields the way the
  human did when hand-minimizing 4.6MB raw → 86KB fixture. So
  `redact.py`-piped output on the 4 raw inputs will be **redacted
  but not minimized**, containing fields the hand-minimizer
  dropped. Byte-for-byte against a hand-*minimized* fixture will
  never match — not because there's a bug, but because the two
  processes do different things. (2) Even setting minimization
  aside, byte-for-byte on JSON is fragile to key-ordering,
  whitespace, trailing newlines, and `VARIANT`-style serialization
  differences that carry no semantic content. Byte-matching
  cannot distinguish "meaningful redaction divergence" from "the
  minimizer doesn't minimize" or "JSON key order changed";
  test-passing can. Scope creep risk to flag: if a future reader
  reads "byte-equality" and adds minimization to the minimizer
  to make it match, that conflates two separate operations and
  defeats the production-contract reproduction claim entirely.
  Same validation discipline as every other deliverable
  (substrate → adjudicate → code → tests).
- **First Phase-2 work item: deterministic minimizer (~200 LOC
  estimate).** A standalone script that reads a raw payload from
  the Phase-2 webhook (or scratch PAT-pull), pipes it through the
  actual `scripts/automation/src/triage/redact.py` pipeline, emits
  the minimized fixture + label entry skeleton + sentinel-scan
  verification stamp. This closes a latent gap: the current 4
  committed fixtures were hand-minimized + sentinel-scan-verified
  but NOT `redact.py`-piped — hand-sanitization is not the
  production-redaction contract. (Naming clarification: "minimizer"
  is a slight misnomer — the script does redaction-contract
  reproduction, and minimization-of-size is a side effect of
  truncation policy, NOT field-subset-selection. Renaming to
  `redactor_pipeline` or similar at Phase-2 open is worth weighing
  to prevent the byte-equality trap above from re-emerging.)
  Same validation discipline as every other deliverable
  (substrate → adjudicate → code → tests).
- **Entry-7 hook coupling already in place.** The entry-7 hook
  installed in #21 closure watches `docs/triage-agent/fixtures/**`.
  Every corpus addition fires the hook and requires the §3
  checklist update + a §7 entry in the SAME commit. The
  minimizer's output discipline MUST stage the checklist update
  in the same commit as the fixture emission. This is the
  enforcement substrate Phase-2 corpus accretion runs on top of.
- **v2-plan addendum.** v2-plan has no dedicated corpus section
  (substrate Finding 1). The §3 row hardening done at entry 2
  + the standalone gate spec (this session's commit) are the
  authoritative corpus design. A small post-hoc v2-plan addendum
  commit should point v2-plan §1/§2 at the gate spec AND fix the
  v2-plan §2 path drift (`scripts/automation/tests/fixtures/
  triage/` written, `docs/triage-agent/fixtures/` actual).
- **Per-pattern minimum-n caveat in the gate spec.** Clause (e)
  of the gate spec carries an N≥10 minimum-n caveat: per-pattern
  precision/recall ≥0.90 is meaningless at n<10 (one bad call
  drops the rate below threshold). Patterns thinly represented in
  the held-out corpus (n<10) are reported with an explicit
  "underpowered" disposition rather than failing the gate. Phase-2
  corpus growth strategy should monitor this and prioritize
  acquisition of payloads for underpowered patterns.

**Trigger.** Phase-2 webhook activation (Gate E follow-ups,
v2-plan §4). The corpus accretes through the webhook handler
processing real production failures; the agent's outputs during
the accretion window are advisory-only per the Phase-2 precondition
spec.

**Not a Phase-1-exit blocker.** Per β adjudication. Phase-1 exit
explicitly carries the no-held-out-accuracy limitation; the
in-sample 7-payload baseline is the Phase-1 exit measurement, with
the explicit caveat that 100% precision/recall on that baseline is
construction-determined (these 7 payloads informed catalog design,
per `backtest-baseline-2026-06-07.md` and `p01_labels.yml v1.0.0`).

**Related artifacts.**

- `docs/triage-agent/phase-2-backtest-corpus-gate.md` — the five-
  clause Phase-2 acceptance gate spec (this session's commit).
- `docs/triage-agent/phase-1-exit-checklist.md` §1.3 (relocated
  quality bar), §3 Items NOT scored row (reclassified pointer),
  §7 entry 2026-06-09 entry 2 (full reclassification rationale).
- `docs/triage-agent/sprint-1-deferred.md` #20 (the DBT-CLOUD-CLIENT
  Phase-2 brief — paired side of the same Phase-2 dependency).
- `scripts/automation/src/triage/redact.py` v1.0.0 — the redaction
  contract the minimizer must pipe through.
- `scripts/automation/configs/fbin_error_catalog.yml` v1.2.0 — the
  catalog the corpus tests against.
- `scripts/automation/hooks/git/pre-commit` (entry-7 hook, #21
  closure) — the enforcement substrate corpus accretion runs on
  top of.

---

### 23. ORCH-FAIL-OPEN logger-output contract test (Test 5) — caplog assertion that `logger.error` emits no traceback

**Surfaced:** 2026-06-09 entry 4 during the broad-except design
adjudication. The Spec A fail-open handler in `triage_failure` uses
`logger.error("redactor_fail_open exc_type=%s", exc_type)` —
deliberately *not* `logger.exception(...)` — to enforce the
consistent-trust-boundary credential-safety posture (the traceback
includes `str(exc)`, which on the broad-except path is un-sentinel-
checked content by construction; routing it to logs would relocate
the leak that `exc_type`-only-in-rationale closes).

The four tests landing in Commit N+1 (`TestRedactorFailOpen` in
`tests/test_triage_orchestrator.py`) lock the *rationale-output*
contract structurally (`model_dump()` walk over every field), but
they do **not** lock the *log-output* contract. The logger choice
(`logger.error` vs `logger.exception`) is currently comment-enforced
at the handler site — a load-bearing inline comment documenting why
future "improve debuggability" edits must not flip `error` to
`exception`. Comment-enforcement is sufficient for Phase-1 (the
comment is at the code site and visible to the next person), but
it isn't test-locked.

**Deliverable.** Add Test 5 (`test_logger_error_emits_no_traceback`)
in the `TestRedactorFailOpen` class using pytest's `caplog` fixture:
- Inject a `RuntimeError` via `monkeypatch.setattr` on
  `redact_early_failure` (same injection pattern as Tests 1-4).
- Run `triage_failure(VALID_PAYLOAD)` inside `caplog.at_level(logging.ERROR,
  logger="scripts.automation.src.triage.failure_triage_agent")`.
- Locate the captured `LogRecord` whose `getMessage()` starts with
  `"redactor_fail_open exc_type="`.
- Assert `record.exc_info is None` (the load-bearing assertion —
  `logger.exception` would set `exc_info` to the active sys.exc_info
  triple, capturing the traceback; `logger.error` leaves it None).
- Assert `record.levelname == "ERROR"` (not `"CRITICAL"` or some
  future regression).

This closes the deferred-gap row in the entry-4 mutation table
("Flip `logger.error` → `logger.exception` — Not currently caught
by tests") by making it a test-detectable regression.

**Trigger event.** Phase-2 error-store channel design firms up.
The trigger is *not* arbitrary — it's the moment when the
architecture decides where redactor-bug debug detail (full
traceback + `str(exc)`) should be routed (separately-secured
error-store channel, encrypted log sink, dedicated triage-debug
topic, etc.). At that moment, the *log-output* contract becomes
architecturally meaningful (the logger choice expresses a routing
decision, not just an exception-emission style) and the test
should be added in lockstep with the channel design so the
contract is test-locked the moment it acquires real architectural
weight. Adding the test before that moment would lock an arbitrary
implementation detail; adding it at that moment locks a real
routing decision.

**Acceptance criteria for closing this item.**
1. Test 5 added to `TestRedactorFailOpen` class in
   `tests/test_triage_orchestrator.py` per the spec above.
2. Test passes; mutation gate verified (flipping `logger.error`
   → `logger.exception` in `failure_triage_agent.py` makes Test
   5 fail).
3. The entry-4 mutation table row ("Flip `logger.error` →
   `logger.exception` — Not currently caught by tests") is
   updated to reflect Test 5's coverage.
4. Commit message references this item by number.

**Closure criterion.** This item closes ONLY when commit lands
with Test 5 + the table update. Comment-only enforcement at the
handler site is *not* sufficient closure; the deferred-gap row
in the mutation table is the explicit acknowledgement that
comment-enforcement is a transitional state pending this test.

**Cross-references.**
- `phase-1-exit-checklist.md` §7 entry 2026-06-09 entry 4
  *Credential-safety design* paragraph (the architectural
  rationale this test locks).
- `failure_triage_agent.py` (post-Commit-N+1): the load-bearing
  comment at the handler site documents why `logger.error` not
  `logger.exception` — this test promotes that comment to a
  test-locked contract.
- `tests/test_triage_orchestrator.py` `TestRedactorFailOpen`
  class (post-Commit-N+1): four tests covering the rationale-
  output contract; Test 5 extends to the log-output contract.

---

## Closed items

### #21 — Artifact-ship + score-update enforcement hook

- **Closed:** 2026-06-09 by commit `a586b4f6` on
  `feature/dv-failure-triage-agent` ("docs(triage): close
  sprint-1-deferred #21 — entry-7 enforcement hook + harness +
  pytest wrapper + session-start verifier (own dogfood)").
- **Resolution:** Single path-matched `pre-commit` hook installed at
  `scripts/automation/hooks/git/pre-commit`, activated per-clone via
  `git config core.hooksPath scripts/automation/hooks/git`. No
  `pre-commit` framework adopted; raw git hook (per #21 scope —
  "NOT a general-purpose commit-policy framework").

**Acceptance criteria check-off (against the opened ticket's (a)-(d)):**

- **(a) hook installed:** `scripts/automation/hooks/git/pre-commit`
  (executable, 4357 bytes). Installation method = `git config
  core.hooksPath scripts/automation/hooks/git` (single command,
  per-clone, documented in SETUP_GUIDE.md §B step 4.5).
- **(b) reject on watched-path addition without checklist:** PASS
  via harness (`scripts/automation/hooks/git/test_pre_commit.sh`
  cases c1, c3, c4) AND verbatim worktree verification (see
  reject text reproduced below). Exit 1.
- **(c) accept on watched-path addition WITH checklist:** PASS
  via harness cases c2 + c5. Exit 0.
- **(d) corpus-ship-path coverage:** SATISFIED. Decision D1-A
  (adopted during FU1 substrate review): the watched-path
  predicate covers BOTH `scripts/automation/src/triage/**` (the
  original OBS-DDL class drift) AND `docs/triage-agent/fixtures/**`
  (the BACKTEST-CORPUS class). Harness case c3 directly proves the
  fixtures path is enforced. If BACKTEST-CORPUS lands at a path
  outside both prefixes, the watched-path regex MUST be extended
  in the same commit that lands the corpus (see "Path-coupling
  flag" below).

**Verbatim reject text (captured 2026-06-09 from a real `git diff
--cached` against this hook, staged file =
`docs/triage-agent/fixtures/worktree_test.json` alone):**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Blocked by lessons-learned entry 7
    (artifact-ship + score-update same-commit rule)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This commit stages NEW file(s) under a watched ship-artifact path:

    docs/triage-agent/fixtures/worktree_test.json

...but does NOT stage the scoring surface:

    docs/triage-agent/phase-1-exit-checklist.md

Per entry 7, ship-class commits must update the scoring surface
in the same commit. See: docs/triage-agent/lessons-learned.md
(entry 7) and docs/triage-agent/sprint-1-deferred.md #21.

──────────────────────────────────────────────────────────
  How to proceed:
──────────────────────────────────────────────────────────

  1. If this commit MOVES the score (ships a tracked deliverable):
     Stage the checklist row + §4 progress table + §7 entry
     update in this same commit, then re-commit.

  2. If this commit does NOT move the score (e.g., a refactor
     that adds a new helper file under triage/ but ships no
     deliverable): bypass with --no-verify AND add a
     'bypass-rationale:' line to the commit body explaining
     why this commit is score-neutral.

  Bypass syntax:
      git commit --no-verify -m "your message

      bypass-rationale: <why this is score-neutral>"

  Note: this hook CANNOT enforce the rationale text — it's an
  honor-system audit-trail check verified at review time
  (entry 6 reviewer-discipline backstop). Skipping the
  rationale defeats the audit trail.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Exit code 1. Same text appears whether the hook is invoked by `git
commit` directly (end-to-end) or by `bash
scripts/automation/hooks/git/pre-commit` against pre-staged content
(harness mode). End-to-end verification deferred until post-commit
of this closure (chicken-and-egg: the worktree created from the
pre-FU1 HEAD doesn't have the hook files, so the first end-to-end
verification can only happen after this commit lands; see
"Post-commit verification" below).

**Install method (recorded for reproducibility):**

```bash
# One-time setup per clone (also added to SETUP_GUIDE.md §B):
git config core.hooksPath scripts/automation/hooks/git
```

This sets `core.hooksPath` (a per-clone git config) so git looks for
hooks in the committed `scripts/automation/hooks/git/` directory
instead of the per-clone-untracked `.git/hooks/` directory. This
choice means the hook is **version-controlled** (lives in the repo,
reviewable in PRs, evolves with the code) rather than copy-installed
into `.git/hooks/` (per-clone, invisible to the team).

**Important coupling — `core.hooksPath` is all-or-nothing for the
hook directory.** Setting `core.hooksPath foo/` makes git look in
`foo/` for ALL git hooks (pre-commit, prepare-commit-msg,
post-commit, post-merge, pre-push, etc.), NOT just pre-commit.
Future hooks added to this enforcement system land in the same
directory (`scripts/automation/hooks/git/`). This directory is
distinct from `scripts/automation/hooks/` (without `/git`) which
holds Claude Code session-lifecycle hooks (PreToolUse, PostToolUse,
SessionStart, Stop) — those are a different mechanism that fires on
agent tool calls, not on `git commit`. The two cohabit cleanly
because git only reads the leaf directory, not its parent.

**BACKTEST-CORPUS falsification protocol.** Entry 7 is a Sprint-1
lesson; the next falsification event is the upcoming BACKTEST-CORPUS
ship. If the corpus is staged under `docs/triage-agent/fixtures/**`
or `scripts/automation/src/triage/**`, the hook will fire and either
accept (checklist staged) or reject. The falsification check is:
**does the hook produce the right verdict on the actual corpus
commit?** If yes → entry 7 holds. If no (e.g., hook rejects when it
should accept because the corpus commit DOES move the score and
DOES stage the checklist but the hook misreads the path) → the hook
has a real bug, NOT entry 7. If the corpus lands outside both
watched paths → the watched-path regex must be extended in the
**same commit** as the corpus (see clause (d) of the opened ticket
and the path-coupling flag below). Failing to extend the regex
silently passes the corpus through with no enforcement — that's the
residual gap β below.

**Residual gap β (recorded honestly).** This hook is a *path-
matched* approximation of entry 7, not a semantic check. It can
silently pass any commit that:

1. Adds a tracked deliverable at a path NOT in the watched-path
   regex. (Mitigation: per-deliverable path-coupling discipline at
   ship time; clause (d) extension; reviewer-discipline backstop
   per entry 6.)
2. Modifies (rather than adds) a watched file. The hook uses
   `--diff-filter=AR` (additions + renames into the path);
   pure modifications pass without checking the checklist. This
   is intentional — most modifications are refactors or fixes
   that don't move the Phase-1-exit score. C5 in the harness
   directly proves this is the designed behavior. Mitigation:
   reviewer-discipline backstop per entry 6.
3. Uses `--no-verify` without an honest `bypass-rationale:` line.
   The hook is honor-system on the bypass path; the rationale is
   verified by reviewers (entry 6), not by the hook. Mitigation:
   commit-message review at PR time; if abuse is observed, add a
   server-side check (e.g., a GitHub Actions check on the PR's
   commit messages) — that's the **upgrade path** for this gap,
   NOT a Phase-1 requirement.
4. **Ships, modifies, or weakens the enforcement machinery
   itself.** The hook lives at `scripts/automation/hooks/git/` and
   its tests at `scripts/automation/tests/`. Both directories are
   **outside** the watched-path regex. This is a structural blind
   spot, not a property of any particular commit: any future
   commit that ships *tooling* (a new hook, a CI mirror, an
   additional test) lands outside the watched paths and is
   unprotected by the very mechanism it extends. The nastier
   corollary: **a commit that modifies the hook to weaken it —
   broaden the bypass, narrow the watched paths, disable the
   check — also lands outside the watched paths and triggers no
   alarm.** The hook cannot guard against its own weakening.
   FU1's own landing commit (`a586b4f6` pre-amend → `2d97bfe6`
   on-branch) demonstrates this directly: it shipped no files
   under watched paths, so the hook (now installed) would have
   returned exit 0 on it. **The hook protects deliverable-
   artifact commits; it does not and cannot protect commits to
   the enforcement machinery itself, including commits that
   would weaken the hook — those rely entirely on entry-6
   reviewer discipline.** This is the honest boundary of what
   FU1 buys. Mitigation: PR review must scrutinize any diff
   touching `scripts/automation/hooks/git/` or
   `scripts/automation/tests/test_entry7_hook.py` with extra
   care — those are the changes the hook is structurally blind
   to. Upgrade path: a server-side check on the PR (GitHub
   Actions workflow) that re-runs the harness from the *pre*-
   merge tree, so weakening attempts surface as failing CI even
   if the local hook is bypassed or modified. NOT a Phase-1
   requirement.

**Path-coupling flag.** Two-way coupling exists between the watched-
path regex in the hook and the set of paths where Sprint-1
deliverables land:

- If a deliverable lands at a NEW path (not under
  `scripts/automation/src/triage/**` or `docs/triage-agent/
  fixtures/**`), the hook silently passes it. Reviewer at PR time
  must catch this and either extend the regex OR confirm the new
  path is not ship-class.
- If a watched path is removed (refactored away), the hook still
  matches its prefix. Harmless, but dead config. Periodic audit
  (e.g., at sprint close) keeps the regex aligned with reality.

The hook does **not** auto-discover ship paths. Path coverage is a
human-maintained decision. The harness's c3 case exists specifically
to ensure that if someone removes the fixtures-path coverage from
the regex, the harness fails loudly.

**Bug 1 reasoning correction (recorded in this closure rather than
re-touching lessons-learned entry 7).** During FU1 substrate review,
the initial reasoning for why the entry-7 landing commit `81823d99`
(itself the worked instance of artifact-ship-with-tracking-surface)
passed the enforcement rule was: "because it staged the checklist."
Re-reading the commit, that reasoning was wrong. `81823d99` shipped
`docs/triage-agent/lessons-learned.md` (the entry-7 text) plus
`docs/triage-agent/sprint-1-deferred.md` (the #21 row), but no files
under the watched paths (`scripts/automation/src/triage/**` or
`docs/triage-agent/fixtures/**`). The hook (had it existed) would
have returned exit 0 because `STAGED_NEW` was empty — no watched
file was staged. The checklist staging was incidental, not load-
bearing. The actual entry-7 protection for `81823d99` was the
**existing review-discipline** that ships lessons-learned changes
WITH their tracking surface updates as a matter of authorial
practice (entry 6 backstop). The hook covers the future cases where
the discipline is forgotten on a watched-path commit. This
correction matters because confusing the two mechanisms would
under-specify the residual gap (β.1 above): a deliverable at a new
unrelated path is NOT covered by the hook just because the author
"remembered" to update the checklist.

**Test harness.** `scripts/automation/hooks/git/test_pre_commit.sh`
runs 5 scenarios in an isolated scratch git repo (mktemp, trap-
cleanup, no parent-repo side effects): c1 (triage-src new alone →
REJECT), c2 (triage-src new + checklist → ACCEPT), c3 (fixtures new
alone → REJECT, proves D1-A coverage), c4 (fixtures rename INTO
watched path → REJECT, proves `--diff-filter=AR` catches renames),
c5 (existing-file modification → ACCEPT, proves `--diff-filter=AR`
does NOT fire on modifications). All 5 pass. Pytest wrapper
`scripts/automation/tests/test_entry7_hook.py::test_entry7_hook_
cases` calls the harness via subprocess and propagates failure
output. Wrapper runs in ~3 s (subprocess + 5 case branches) —
verified during FU1 substrate validation; a 0.01 s timing would
indicate the subprocess never fired.

**Three real bugs caught during FU1 harness execution (worth
recording because they were not predicted at design time):**

1. **State leakage between cases via `git checkout`.** Git's
   documented behavior carries staged uncommitted changes across
   branch checkouts when no conflict exists. C2 staged the
   checklist modification; cleanup `checkout testbase` propagated
   that into testbase's index; C3 branched from testbase and
   inherited the checklist in its index; hook saw "checklist
   staged" and incorrectly returned 0 on C3. Fix: `reset_to_base`
   helper runs `git reset --hard HEAD && git clean -fdq` before
   `checkout testbase`, fully discarding case state before
   switching.
2. **Pathspec filtering hides cross-boundary renames.** `git diff
   --cached --diff-filter=R -M --name-only -- docs/triage-agent/
   fixtures/` returned empty for a rename whose source was
   `elsewhere/` and destination was inside fixtures. With a
   pathspec, git drops renames whose source is outside the spec.
   The hook itself uses no pathspec (correct), but the C4 pre-
   check used one (incorrect — proved the wrong invariant). Fix:
   `--name-status` without pathspec, then grep for the destination
   prefix. The hook's own behavior was always correct; only the
   harness's verification was buggy.
3. **`git clean -fdq` wipes empty directories.** The init commit
   creates `scripts/automation/src/triage/` via `mkdir -p` but
   never adds a file there; git doesn't track empty directories,
   so after C1's `reset --hard HEAD` + `clean -fdq` the directory
   is gone. C2 then fails to `echo > scripts/automation/src/
   triage/new_helper.py` (no such directory). Fix: `mkdir -p` the
   parent before each write in C1 and C2 (the other cases use
   pre-committed directories).

These bugs surfaced ONLY because the harness was run end-to-end
with state-leak checks at every case boundary — not from reading
the code. Recording them defends the harness's case-isolation
discipline against future "simplifications."

**Closure criterion satisfied.** Acceptance (a)-(d) all green;
verbatim reject text captured; install method documented; harness
5/5; pytest 1185/2 (baseline 1184 + 1 new); session-start verifier
warns when `core.hooksPath` is OFF; SETUP_GUIDE.md updated; this
commit ships the FU1 deliverable + updates #21 row + records the
§7 checklist entry, all atomically. It demonstrates the entry-7
rule **at the discipline level** (artifact + tracking surface
together) but does **not** demonstrate the *hook* working on
itself — the hook structurally can't, per residual gap β.4. The
hook returns exit 0 on this commit because no watched-path files
are staged, which proves *no-op-on-unwatched* (correct by design),
not enforcement. The dog-fooding is real at the discipline level,
not the mechanical level.

**Post-commit verification.** Performed immediately after this
commit lands by adding a worktree on a throwaway branch from the
new HEAD and attempting a forbidden commit there. The captured exit
code + stderr is reported in the commit's PR conversation (not
re-recorded here, to keep this closure note bounded). If the
worktree end-to-end test fails — i.e., the installed hook does not
reject when invoked by real `git commit` — this closure note is
rolled back via revert + reopen.

### #17 — ORCH re-audit (PARTIAL-as-DONE decomposition)

- **Closed:** 2026-06-08 by commit `f5be1121` on
  `feature/dv-failure-triage-agent` ("docs(triage): close
  sprint-1-deferred #17 — ORCH decomposition (68% → 60.0%)").
- **Resolution:** ORCH (w3 PARTIAL with full-credit) decomposed per
  Proposal B into four sub-items: ORCH-EARLY-FAILURE (w2 high-tier
  DONE), ORCH-CIRCUIT-OPEN (w1 medium NOT STARTED), ORCH-ARTIFACT-MODE
  (w1 medium NOT STARTED contingent), ORCH-MULTI-PATTERN (moved to
  "Items NOT scored" per §1 explicit out-of-scope). Total scored
  denominator grew 19 → 20; done credit dropped 13 → 12. Score
  corrected 68% → 60.0% (pickup-memo predicted 58–63% range; landed
  cleanly in range).
- **Re-audit method:** Validation against actual code (entry 5 probe-
  validation discipline applied to the audit itself). Read
  `failure_triage_agent.py` + `test_triage_orchestrator.py` +
  `rca_schema.py`; `grep` for `CIRCUIT_OPEN`, `EvidenceMode.ARTIFACT`,
  and multi-pattern logic across `src/triage/`. All four pre-drafted
  sub-items aligned with actual code state — no discrepancies between
  claimed and actual.
- **Meta-pattern check:** Probed specifically whether ORCH-EARLY-
  FAILURE itself absorbed deferred sub-decisions (3rd PARTIAL-as-DONE
  firing would trigger §2 scoring-rule revision). It did not. Tracker
  stays at 2/3. Continue case-by-case decomposition discipline.
- **Coverage gap surfaced honestly:** Empty-projection-after-redact
  defensive branch (`failure_triage_agent.py` L243-250) lacks dedicated
  test — queued as sprint-1-deferred #18 with explicit gap location,
  impact assessment, and resolution scope. Not Phase-1-exit-blocking.
- **Cross-review:** DA at adjudication time caught one arithmetic
  error mid-report (denominator miscount: 12/19 = 63.2% corrected to
  12/20 = 60.0% after re-counting items in proper tier placement).
  Cross-review durability tracker incremented by one firing across a
  distinct context (audit work, not code work).
- **Closure criterion satisfied:** Checklist row decomposed (4 sub-
  items), §7 entry recorded, score column updated, distance-to-exit
  recomputed (+8 weight to 100%), commit message references item #17.

### #14 — Day-4 Phase B/C catalog patterns BLOCK lifted

- **Closed:** 2026-06-05 by commit `d72e20b5` on
  `feature/dv-failure-triage-agent` ("triage: land Round 3.5.5 5-rule
  truncate_logs v2 + close BLOCK")
- **Resolution:** 5-rule algorithm landed in
  `scripts/automation/src/triage/redact.py` replacing the Day-3.8
  hybrid. Generics (`\bfailed\b`, `^ERROR\b`) removed from
  ERROR_ANCHORS; earliest-position-wins replaces last-position-wins;
  Rule 3 head-window + Rule 4 centered-window + Rule 5 tail
  fallback. Acceptance criteria all met:
  - Round-3.5.5 design closure: ✅ (spike outcome doc
    `docs/triage-agent/round-3.5.5-spike-results.md` + final outcome
    block)
  - 7/7 P0.1 payloads in-window with anchor preserved: ✅
    (`scripts/automation/triage/spike_truncate_v2.py` 15/15 PASS)
  - `redact.py` NOTICE block removed + `truncate_logs` docstring
    updated: ✅
  - Mut9d catalog-load-time gate remains: ✅ (unchanged)
- **Mutation surveillance:** 7 new mutation tests in
  `TestTruncateLogsV2` (Mut_R1a/R1b/R2/R3/R3_boundary/R4/R5) +
  snapshot regression class `TestTruncateLogsSnapshots` pinning
  strategy + output_bytes for all 7 P0.1 payloads.
- **Documented limitations:** (a) Rule 3 head-boundary clipping
  (synth_01a' fixture) — regression-detector test asserts the
  current clipping; an upgrade would FAIL the test surfacing it for
  review. (b) Earliest-position-wins limitation when anchor literals
  appear in data rows (synth_04 fixture). Both deferred until Day-6+
  backtest evidence (>5% of failures exhibiting the pattern) justifies
  Round-4 work.
- **First catalog pattern citing `logs`:** still pending — to land in
  a SEPARATE follow-up commit (this commit lifts the BLOCK; it does
  not ship Day-4 Phase B/C content).

### #15 — Day-4 Phase C catalog pattern (Cluster C `dmf_code` failures) deferred

- **Status:** DEFERRED pending 2nd confirming sample per sub-mode
  (empirical-bar discipline; honors `ac2c384c` precedent which
  required 2 confirming runs before shipping Pattern 2).
- **Deferred:** 2026-06-06 during Day-4 Phase B execution. Cluster A
  shipped as Pattern 3
  (`manifest_parse_failure_invalid_model_language_v1`); Cluster C
  held back until evidence threshold met.
- **Why not C1 (single pattern, both SQL errors):** The two failures
  share a model path (`models/__dmf_code/dbt_yml_test_inventory.sql`)
  but root causes diverge meaningfully:
  - `Object does not exist or not authorized` (002003 / 42S02) →
    permissions issue OR missing upstream object. Resolution:
    grants, dependency review, or materialization order fix.
  - `syntax error line X at position Y` (001003 / 42000) → genuine
    SQL bug in the model file. Resolution: code edit.
  Conflating these into a single `suggested_action` would force
  lowest-common-denominator (probably `escalate_to_human` for both),
  losing the operational specificity that makes the catalog valuable.
- **Why not C2 (two patterns, one sample each):** Below the empirical-
  sample bar established by Pattern 2. Shipping 2 patterns each
  backed by 1 sample is speculation in the opposite direction from
  the Round-3.5.5 lesson about empirical-grounding over speculation
  (lessons-learned entry 4).
- **P0.1 corpus evidence:** 2 payloads (1 per sub-mode):
  - run **484675412** (Cluster C) — `dmf_missing_or_unauthorized_object`
    sub-mode. Strategy `head:Database Error`, anchor at byte 2255 of
    2795 total. Truncated output retains the actionable error.
  - run **486060143** (Cluster C) — `dmf_sql_syntax_error` sub-mode.
    Strategy `window:Database Error`, anchor at byte 77829 of 79512
    total, in-window margin 1683. Truncated output retains the
    actionable error.
- **Pattern candidates pre-staged** (do NOT ship until 2nd sample
  per sub-mode arrives):
  - `dmf_missing_or_unauthorized_object_v1` — matches
    `Object\s+'[^']+'\s+does not exist or not authorized` plus
    `models/__dmf_code/` path context. Reads `logs` field;
    `max_bytes=LOGS_MAX_BYTES`. Expected confidence_baseline 0.85-0.90.
  - `dmf_sql_syntax_error_v1` — matches
    `syntax error line\s+\d+(,\d+)?\s+at position\s+\d+` plus
    `models/__dmf_code/` path context. Reads `logs` field;
    `max_bytes=LOGS_MAX_BYTES`. Expected confidence_baseline 0.85-0.90.
- **Round-4 trigger:** Day-6+ backtest harness (20-30 labeled
  failures) produces 2nd confirming sample for either sub-mode.
  Draft and ship that pattern alone (single-pattern shipping
  discipline). The 2nd sub-mode follows when its 2nd sample arrives.
- **Why C3 was chosen (deferral as positive decision):**
  Single-pattern shipping discipline + empirical-bar discipline +
  positive-audit-trail discipline all converge on deferral. The
  pre-staged pattern candidates above ensure the deferral does not
  lose the design thinking; only the speculative ship is deferred,
  not the analysis.

---


## Sprint 1 exit criteria

This file is reviewed at Phase 1 exit. Exit blocked if:

- Any item in **Open items** lacks a clear trigger or acceptance criterion
- Any item with a met trigger has not been actioned
- The list has not been reviewed in the most recent 14 days

---

## Carina POD discipline note

**Pattern:** When a production-readiness concern surfaces during dev-phase
work, the correct response is **documented + deferred + acceptance criteria
+ blocker-status flagged**, not "fix now" or "remember to fix later."

Three reasons this discipline holds:

1. **Documented** survives session boundaries and personnel changes
   (`lessons.md` discipline applied to to-do items).
2. **Acceptance criteria** make future "done" measurable; without them,
   the item drifts indefinitely.
3. **Blocker-status flagged** prevents Phase 2 from accidentally shipping
   without resolving it.

This file is the canonical artifact catching these. Items #12 (logs-field
Gate-D) and #13 (production token migration) both follow this pattern:
identified during dev-phase work, documented immediately with measurable
acceptance criteria, not parked in conversation context.
