# DV Failure Triage Agent — Phase 1 Exit Checklist

**Created:** 2026-06-06 (Day-5 session open)
**Branch:** `feature/dv-failure-triage-agent`
**HEAD at creation:** `68de998f`
**Purpose:** Replace "vibes-based" Phase 1 progress estimates (~80% →
~85% → ~88% → ~90% over Rounds 3 → 3.5 → 3.5.5 → Day-4 Phase B) with
a concrete, scored exit definition. Establishes a baseline so future
progress claims are auditable.

This is the response to the Phase-1 measurement-debt flag in
`triage-day4-phase-d-pickup.md` §"Session-open agenda" (repo memory,
not in `docs/`). It is also the prerequisite for any further design
work; per the same pickup doc, "Defer until session open — not
urgent now," and this session is that open.

---

## 1. Exit-criteria scope (what "Phase 1 done" means)

Phase 1 = **the agent can be invoked end-to-end on a real dbt Cloud
failure and emit a schema-valid RCA record whose accuracy is
measurable against a labeled corpus.**

That sentence resolves three ambiguities that the vibes estimates
papered over:

1. **End-to-end invocation, not just modules.** A passing test suite
   on `rca_schema`, `redact`, and `fbin_error_catalog` is *necessary
   but not sufficient*. The orchestrator that wires them together is
   itself a Phase-1 deliverable, not a Phase-2 nice-to-have.

2. **Schema-valid emission, not just structurally-correct match.**
   The agent must produce an `RCARecord` (frozen, `extra=forbid`,
   Iron-Rule-validated). A multi-pattern match that cannot be
   collapsed into a single record is a *Phase-1 design hole*, not
   a Phase-1 deliverable. (Q1 probe results — see
   `phase-1-q1-probe-results.md` (TBD if probe surfaces multi-hit)
   — will tell us whether this hole needs filling in Day 5 or can
   stay deferred to Day 6+.)

3. **Measurable accuracy, not anecdotal.** "It worked on the 3
   committed fixtures" is not Phase-1 exit. The backtest harness
   (v2-plan §2) running over **≥20 labeled failures** with
   precision/recall reported is the exit measurement. (Reconciled
   2026-06-09 entry 2: previously read "20–30"; the "30" was
   aspirational and was silently dropped between §1.3 and §3.
   Reconciled to "≥20, more is better, no upper cap." Without it,
   Phase-2 webhook activation has no quality signal. **Per the
   2026-06-09 entry 2 reclassification, this quality bar is
   relocated to a named Phase-2 precondition** (see
   `docs/triage-agent/phase-2-backtest-corpus-gate.md`) for trusting
   agent outputs in any non-advisory capacity; Phase-1 exits with the
   in-sample 7-payload baseline only, an explicitly accepted
   limitation, not a deferred TODO.

### Out of Phase 1 (intentional, see §4 for deferral rationale)

- Phase 2 webhook activation (gated on Phase-1 exit + Sprint-1 #13)
- Catalog beyond ~3–5 patterns (the empirical-bar discipline will
  add patterns when backtest surfaces them, not on speculation)
- Observability DDL deployed to OPS_PROD.LOGS.TRIAGE_INVOCATIONS
  (DDL design is Phase 1; deploy is Phase-1.5 / Phase-2 boundary —
  see §3 item OBS-DDL)
- Multi-pattern disambiguation framework (gated on Q1 probe;
  see lessons-learned entry 4 spike-or-iterate discipline)
- dbt_cloud_client.py for live job-API integration (Phase 2 —
  webhook hands the agent a payload; live polling is fallback)
- Production token migration (Sprint-1 #13, parallel track)

---

## 2. Scoring rule

**Chosen: criticality-weighted-count (hybrid).** Justification follows.

| Candidate | Rejected because |
|---|---|
| Pure count (N/total) | Treats `dbt_cloud_client` shim (~200 LOC, low-risk) as equivalent to orchestrator (gates ALL downstream behavior). Distorts the picture. |
| Pure effort (LOC or hours) | LOC estimates from v2-plan §2 are pre-build guesses; converting them into a denominator masks that uncertainty. Hours are not tracked. |
| Pure criticality | Subjective without an enumerated scale. |
| **Criticality-weighted count** | Each item gets a weight (1, 2, or 3) tied to a written rule. Sum of weights = denominator. Done weights = numerator. |

### Weight scale

| Weight | Definition |
|---|---|
| **3 (critical)** | Item is on the runtime critical path AND blocks measurement of all later items. Failure here means Phase 1 cannot exit by definition. |
| **2 (high)** | Item is on the runtime critical path but does not block measurement of others — they can proceed with a stub. |
| **1 (medium)** | Item is required for Phase-1 exit but is not on the runtime critical path (auxiliary tooling, fixtures, deployment artifacts). |

### Anti-gaming rules

- An item is **only counted as done** when (a) the artifact exists,
  (b) tests gate it (mutation tests where applicable per Iron Rule
  discipline), and (c) there is at least one end-to-end use of it
  by another Phase-1 item or a fixture-driven integration test.
- Re-weighting an item retroactively requires a session-open note
  in this doc explaining why the original weight was wrong. (Defeats
  "moving the goalposts" failure mode.)
- Splitting a single item into sub-items to inflate count is
  forbidden. Decomposition is fine; *scoring* still happens at the
  granularity defined here.

---

## 3. Item enumeration with status

### Critical-path items (weight 3)

| ID | Item | Status | Evidence |
|---|---|---|---|
| RCA-SCHEMA | `rca_schema.py` v1.0.0 with Pydantic frozen contract, 3 Iron-Rule invariants, mutation-tested | **DONE** | `scripts/automation/src/triage/rca_schema.py`; `tests/test_triage_rca_schema.py` |
| REDACT | `redact.py` v1.0.0 with field-aware allowlist, credential sentinel, truncate_logs v2 (Round-3.5.5 5-rule algorithm), mutation-tested | **DONE** | `scripts/automation/src/triage/redact.py`; `tests/test_triage_redact.py`; landing commit `d72e20b5` |
| ORCH (legacy row) | _Decomposed 2026-06-08 — see ORCH-EARLY-FAILURE (w2 high-tier) + ORCH-CIRCUIT-OPEN (w1 medium) + ORCH-ARTIFACT-MODE (w1 medium); ORCH-MULTI-PATTERN moved to "Items NOT scored" per §1 explicit out-of-scope. See §7 entry 2026-06-08 for full rationale and chain of custody._ | DECOMPOSED | sprint-1-deferred #17 (closure). |
| BACKTEST-HARNESS | Backtest harness + scoring framework + label schema + baseline emission infrastructure | **DONE** | Day-6 session 2026-06-07. Files: `scripts/automation/src/triage/backtest.py` (core scoring), `scripts/automation/src/triage/backtest_report.py` (rendering + CLI), `scripts/automation/tests/test_triage_backtest.py` (41 tests, all verdict branches covered, path-traversal defended, per-pattern rationale contract tested), `docs/triage-agent/fixtures/p01_labels.yml` (label spec v1.0.0 with per-entry provenance), `docs/triage-agent/backtest-baseline-2026-06-07.md` (committed baseline). Harness is REPRODUCIBLE: any user runs `.venv/bin/python3 -m scripts.automation.src.triage.backtest_report --output <path>` and the baseline regenerates. |
| BACKTEST-CORPUS | _Reclassified to NOT scored on 2026-06-09 — see Items NOT scored below; rationale + Phase-2 acceptance gate spec in §7 entry 2026-06-09 (entry 2)._ | RECLASSIFIED | See sprint-1-deferred #22 + `docs/triage-agent/phase-2-backtest-corpus-gate.md`. |
| BACKTEST (legacy row) | _Decomposed 2026-06-07 — see BACKTEST-HARNESS + BACKTEST-CORPUS_ | DECOMPOSED | See §7 entry 2026-06-07 "BACKTEST decomposition" for rationale and DA chain of custody. |

### High-criticality items (weight 2)

| ID | Item | Status | Evidence |
|---|---|---|---|
| CATALOG | `fbin_error_catalog.yml` + loader with ≥3 production patterns, 8+ mutation gates (Mut1–Mut9d), provenance-laundering defense | **DONE** | 3 patterns shipped (`fk_orphan_detection_failure_v1`, `pr_isolated_schema_missing_upstream_v1`, `manifest_parse_failure_invalid_model_language_v1`); commit `68de998f` |
| AGENT-FILE | `.github/agents/dv-failure-triage.agent.md` declaring tool restrictions, invocation surface, design-decision-delegation rules | **DONE** | `.github/agents/dv-failure-triage.agent.md` (Shape A — documentation agent, `tools: ["read"]`, `user-invocable: true`). Body documents boundary contract, RCARecord enum interpretation, escalation semantics (`UNKNOWN_HANDED_TO_HUMAN`, `CREDENTIAL_SENTINEL_FIRED`, `requires_human_review`), Iron Rule, multi-pattern placeholder, known limitations (`synth_01a'`, `synth_04`), and an explicit "Current invocation status" section honestly recording the absence of an executable surface (no `__main__`, no CLI, no webhook today). Executable surface is genuinely future work, scoped to DBT-CLOUD-CLIENT and Phase-2 WEBHOOK — not absorbed into AGENT-FILE. See §7 entry 2026-06-08 (AGENT-FILE scoring) for the non-PARTIAL-as-DONE adjudication. |
| ORCH-EARLY-FAILURE | Orchestrator early-failure path: `_detect_mode` + `redact_early_failure` + `_project_payload` + matcher → `_classified`/`_unknown` emission; sentinel-as-outcome boundary | **DONE** | `scripts/automation/src/triage/failure_triage_agent.py`; `tests/test_triage_orchestrator.py` (26 tests, 9 classes; live Cluster C raw-fixture integration). Weight: 2 (high — runtime critical path; unblocked BACKTEST-HARNESS; not w3 because RCA-SCHEMA/REDACT/CATALOG are independently measurable). Coverage gap: empty-projection-after-redact defensive branch (`failure_triage_agent.py` L243-250) lacks dedicated test (structurally hard-to-reach path requiring sentinel-driven full-field redaction) — tracked as sprint-1-deferred #18; not Phase-1-exit-blocking. |

### Medium-criticality items (weight 1)

| ID | Item | Status | Evidence |
|---|---|---|---|
| FIXTURES | End-to-end-redacted P0.1 fixtures committed under `docs/triage-agent/fixtures/`, sentinel-scan clean | **PARTIAL** | 4/7 P0.1 incidents committed as fixtures (`485821754`, `485851058`, `487333396` flattened; `486060143` raw-shape Cluster C for orchestrator zero-match integration test); remaining 3 not committed because no Phase-1 pattern reads them. Counts as DONE for current catalog scope; flagged for re-evaluation if a Phase-1 pattern is added that needs them. **Not a precedent for general corpus growth:** the 3/7 → 4/7 expansion is justified by a specific test need (orchestrator zero-match integration), not by a general goal of committing more fixtures. Future fixture additions must cite a specific consumer (catalog pattern, regression test, contract test) that exercises the new fixture — fixtures with no consumer are speculation per lesson 4. |
| OBS-DDL | `triage_invocations.sql` DDL drafted, reviewed, ready to deploy to `OPS_PROD.LOGS` | **DONE** | `scripts/automation/src/triage/ddl/triage_invocations.sql` shipped 2026-06-08 (commit `ce6fcc8c`). 19-column DDL targeting `OPS_PROD.LOGS.TRIAGE_INVOCATIONS`, idempotent `CREATE TABLE IF NOT EXISTS`, 100/100 lines under surface cap. Header (a)-(f) covers schema source-of-truth, clustering deferral with FinOps note, write-side enum/cross-field enforcement, deploy mechanism, PII analysis, writer-role narrowing. `created_at TIMESTAMP_NTZ NOT NULL DEFAULT SYSDATE()` (F1 fix: SYSDATE over CURRENT_TIMESTAMP — TIMESTAMP_LTZ session-TZ defect closed). GRANT block: DATA_OPS OWNERSHIP + INSERT/SELECT per setup.md §6. Writer-role narrowing (TRIAGE_AGENT_WRITER) logged as sprint-1-deferred #19 (substitutable without schema change). See §7 entry 2026-06-08 (entry 3) for ship rationale + F1 adjudication chain. |
| DBT-CLOUD-CLIENT | _Reclassified to NOT scored on 2026-06-08 — see Items NOT scored below; rationale + design carry-overs in §7 entry 2026-06-08 (entry 4)._ | RECLASSIFIED | See sprint-1-deferred #20. |
| ORCH-CIRCUIT-OPEN | _Reclassified to NOT scored (class-3, phase-impossible) on 2026-06-09 entry 4 — see Items NOT scored below; row-split adjudication record + spec-A/B/C drift identification + class-3 phase-impossibility justification in §7 entry 2026-06-09 (entry 4). The original row text (stateful circuit-breaker open/close + half-open probe semantics for downstream API calls — Spec B/C per §7 entry 4) is preserved in the Items NOT scored row as audit trail, mirroring the BACKTEST-CORPUS preservation pattern._ | RECLASSIFIED | See sprint-1-deferred #17 spec-split note. |
| ORCH-FAIL-OPEN | §1.8 stateless fail-open property: `triage_failure` wraps `redact_early_failure` in a broad `except Exception` handler emitting `Outcome.UNKNOWN_HANDED_TO_HUMAN` with rationale prefix `redactor_fail_open:` and `exc_type` only — the agent stays a co-pilot, not a gate, when the redactor raises any non-sentinel exception | **DONE** | Shipped 2026-06-09 entry 5. Handler at `failure_triage_agent.py` `triage_failure` (post-`except CredentialSentinelFired`) catches `Exception` (not `BaseException` — KeyboardInterrupt / SystemExit propagate); emits rationale `redactor_fail_open: exc_type=<TypeName>` (`exc_type` only, never `str(exc)`); routes via `logger.error` (not `logger.exception` — traceback would carry `str(exc)`). Locked by 4 tests in `tests/test_triage_orchestrator.py::TestRedactorFailOpen`: (1) generic-exception fail-open + rationale-prefix-no-leak; (2) KeyboardInterrupt propagation; (3) sentinel-still-wins handler-precedence; (4) structural `model_dump()` walk no-credential-substring across all fields. Deferred Test 5 (caplog `record.exc_info is None`) banked as sprint-1-deferred #23 with Phase-2 error-store-channel trigger. Spec source: `v2-plan.md` §1.8 L85-87. Surfaced via exception-surface audit in §7 entry 2026-06-09 (entry 4); shipped §7 entry 2026-06-09 (entry 5). |
| ORCH-ARTIFACT-MODE | `EvidenceMode.ARTIFACT` branch — orchestrator handling for `run_results.json` / manifest-shape payloads | **NOT STARTED** (correctly-deferred carry-forward — class 2 per §4 exit-definition) | **Gate (double-conditioned).** Revisit only when BOTH conditions hold: **(i)** ≥1 artifact-mode payload surfaces in backtest corpus (gated on Phase-2 raw-payload strategy), AND **(ii)** the artifact-mode handling branch is built in `failure_triage_agent.py` AND exercised by that payload through `triage_failure()`. Payload arrival is necessary but not sufficient — satisfying (i) without (ii) leaves the deliverable unbuilt and the item must remain open. The (i)-only framing would permit a future session to mark this item satisfied by pointing at a payload's presence (data-shape) rather than its execution through built handling code (branch-coverage); the double-condition closes that gap. The deliverable is **build-the-branch, not test-existing-branch**. **Why it's not built yet (source evidence, verified 2026-06-09 entry 3).** `EvidenceMode.ARTIFACT` defined (`rca_schema.py:76`); zero implementation paths in `failure_triage_agent.py` — `_detect_mode` (L91-117) returns only `EARLY_FAILURE` or `None`; `_classified` (L207) hardcodes `evidence_mode=EARLY_FAILURE`; the orchestrator imports `redact_early_failure` only and never `redact_artifact` despite the latter existing at `redact.py:528`; module docstring (L14-16, L231-233) explicitly cites "zero P0.1 evidence supports an artifact branch today (lesson 4 spike-or-iterate)" as the deferral rationale. Weight: 1 (medium — contingent on both clauses). |

### Items NOT scored (parallel-track or post-Phase-1)

| ID | Item | Reason excluded |
|---|---|---|
| WEBHOOK | dbt Cloud webhook subscription + HMAC verification | Phase-2 activation; gated on Phase-1 exit |
| PROD-TOKEN | Sprint-1 #13 production token migration | Parallel track, separate calendar (Aug 31) |
| CLUSTER-C | Cluster C dmf_code patterns | Deferred per sprint-1-deferred #15; Day-6+ trigger |
| DBT-CLOUD-CLIENT | `dbt_cloud_client.py` thin wrapper over dbt-mcp for payload retrieval | Reclassified 2026-06-08 (entry 4): the L125 "STUB callable by ORCH for backtest replays" rationale was circular — read-validation against `failure_triage_agent.py` confirmed `triage_failure(raw_payload: dict)` is the sole public entry and takes a payload dict, NOT a client; the backtest already replays via direct payload feed (`backtest_scoring.py:161`). The wrapper has NO Phase-1 consumer; its real consumer is the Phase-2 webhook handler. Trigger: Phase-2 webhook activation (Gate E follow-ups, v2-plan §4). Design carry-overs + naming-drift flag + MCP-wrapper-style precedent recorded in sprint-1-deferred #20. |
| ORCH-CIRCUIT-OPEN | Stateful circuit-breaker (open/close + retention + half-open probe semantics) for downstream API calls — the Spec B/C feature per §7 entry 2026-06-09 (entry 4); originally framed as Q2e-1 work in sprint-1-deferred #17 | Reclassified 2026-06-09 entry 4: row-split adjudication identified that "CIRCUIT-OPEN" was conflating three artifacts — Spec A (v2-plan §1.8 *Fail-open circuit breaker* — a misnomer for a stateless per-invocation property, now extracted as ORCH-FAIL-OPEN class-1), Spec B (sprint-1-deferred #17 L484 — genuine stateful breaker), Spec C (this row's original text — same as Spec B). The stateful breaker (Spec B/C) is **phase-impossible** per the §4 separating test: it requires *remote downstream API calls* to wrap (rate limits, timeouts, cascading-failure profile), and the Phase-1 set of remote downstream API calls is empty (DBT-CLOUD-CLIENT reclassified class-3 entry 4; no LLM client built; OBS-DDL writer is a local Snowflake write, not a remote API — its failure mode is fail-open's job per Spec A, and stateful CB semantics may not be the right architecture for local writes at all). A breaker needs something to wrap; Spec B/C has nothing to wrap because every wrappable remote dependency is itself Phase-2 or unbuilt. Phase-2 re-entry trigger: when at least one of {dbt-Cloud-pull client, LLM client} — the remote dependencies whose failure profile warrants stateful CB semantics — exists as a real downstream API call, ORCH-CIRCUIT-OPEN becomes adjudicable against the §4 taxonomy again, at which point it may re-enter as class-1 or stay class-3 for some narrower reason. The OBS-DDL writer is *not* counted toward re-entry per the architectural rationale above. See §7 entry 2026-06-09 entry 4 for full row-split adjudication record, spec-A/B/C citation chain, exception-surface audit, two-independent-moves arithmetic, and credential-safety design rationale; sprint-1-deferred #17 carries the spec-split update note. |
| BACKTEST-CORPUS | ≥20 labeled held-out failures with precision/recall reported — the corpus-size criterion of the original BACKTEST item | Reclassified 2026-06-09 entry 2: substrate review surfaced that the only honest acquisition channels for the ≥20 *net-new held-out* payloads the gate requires (the existing 7 in-sample payloads do NOT count toward the held-out floor per `phase-2-backtest-corpus-gate.md` clause (b)) are: (i) manual PAT-pulls gated on uncontrolled external failure-arrival; (ii) the Phase-2 webhook — both Phase-2-bound; synthetic violates the held-out criterion. BACKTEST-CORPUS is the *accumulate* side of the same Phase-2 dependency DBT-CLOUD-CLIENT (entry 4) is the *fetch* side of — both gated on Phase-2 webhook activation. Decomposition (Shape γ) rejected as third-firing PARTIAL-as-DONE; manual-pull plan (Shape α) rejected as coupling Phase-1 exit to an uncontrolled stochastic process. The harness + 7-payload in-sample baseline remain DONE under BACKTEST-HARNESS (w1, §7 entry 2026-06-07); this reclassification touches only the corpus-size criterion (w2). Phase-2 acceptance gate spec drafted this session at `docs/triage-agent/phase-2-backtest-corpus-gate.md` (five clauses: ≥20 held-out floor, in-sample exclusion, pattern-coverage breadth, label-provenance shape, precision/recall pinned at ≥0.90 / ≥0.70 with N≥10 minimum-n caveat). Trigger: Phase-2 webhook activation (Gate E follow-ups, v2-plan §4). Phase-1 exit explicitly accepts a no-held-out-accuracy limitation; §1.3 quality bar relocated to a named Phase-2 precondition. Design carry-overs (deterministic minimizer as first Phase-2 work item, storage strategy A confirmed, strategy B eliminated, strategy C is coverage-scaffolding only) recorded in sprint-1-deferred #22. |
| ORCH-MULTI-PATTERN | Multi-pattern resolution policy when ≥2 catalog patterns match a payload | §1 explicitly excludes "Multi-pattern disambiguation framework" from Phase-1. Placeholder code at `failure_triage_agent.py` L274-282 emits `Outcome.UNKNOWN_HANDED_TO_HUMAN` with sorted matched `pattern_id`s in rationale; tested in `TestMultiMatch.test_multi_match_emits_unknown_with_listed_ids`. Backtest evidence to date shows zero multi-pattern hits on the 7-payload P0.1 corpus (Q1 verdict). Revisit trigger: backtest co-fire frequency >5% across labelled corpus. |

---

## 4. Current progress against this baseline

| Tier | Items | Done | Weight done | Weight total |
|---|---|---|---|---|
| Critical (×3) | 2 (RCA-SCHEMA, REDACT) | 2 | 6 | 6 |
| High (×2) | 3 (CATALOG, AGENT-FILE, ORCH-EARLY-FAILURE) | 3 (CATALOG, AGENT-FILE, ORCH-EARLY-FAILURE) | 6 | 6 |
| Medium (×1) | 5 (FIXTURES, OBS-DDL, BACKTEST-HARNESS, ORCH-FAIL-OPEN, ORCH-ARTIFACT-MODE) | 4 (FIXTURES partial-counts-as-done, BACKTEST-HARNESS, OBS-DDL, ORCH-FAIL-OPEN) | 4 | 5 |
| **Total** | **10** | **9** | **16** | **17** |

**Phase 1 progress = 16 / 17 = 94.1%.** ORCH-FAIL-OPEN shipped
2026-06-09 entry 5 (Commit N+1) — the sole remaining class-1
incomplete-work item closed; ARTIFACT-MODE remains the sole class-2
carry-forward (does NOT block exit per §4 rule). **Phase-1 exits.**

Move note (§7 entry 2026-06-09 entry 4): the table records the **sequenced** end state of this commit (denominator path 17 → 16 → 17). Move 1 (CIRCUIT-OPEN out, class-3) shrank denominator 17→16. Move 2 (ORCH-FAIL-OPEN in, class-1) grew it 16→17. Net denominator unchanged at 17; net done-credit unchanged at 15; **net score unchanged at 88.2% by coincidence, not by contrivance** — each move is independently justified and the standalone counterfactuals close at different numbers (Move 1 alone: 15/16 = 93.75%; Move 2 alone, on pre-commit denominator 17 without Move 1: 15/18 = 83.3%). See §7 entry 4 for the full two-moves-not-net-zero arithmetic walk and the standalone-vs-sequenced reconciliation that prevents the table's 16→17 from contradicting the entry's 15/18 standalone.

Decomposition note (§7 entry 2026-06-08): the original ORCH item
(weight 3, PARTIAL with full-credit) was decomposed into ORCH-EARLY-
FAILURE (weight 2, high-tier, DONE), ORCH-CIRCUIT-OPEN (weight 1,
medium, NOT STARTED), and ORCH-ARTIFACT-MODE (weight 1, medium, NOT
STARTED — contingent). ORCH-MULTI-PATTERN moved to "Items NOT scored"
per §1 explicit out-of-scope ruling (placeholder code sufficient;
zero co-fire evidence on the 7-payload corpus). Total scored
denominator grew 19 → 20 (honest acknowledgement that the original w3
row under-weighted the deferred work it absorbed). Done credit dropped
13 → 12 (only EARLY-FAILURE actually shipped). Score moves 68% → 60.0%.

Decomposition note (§7 entry 2026-06-07): the original BACKTEST item
(weight 3) was decomposed into BACKTEST-HARNESS (weight 1, DONE) and
BACKTEST-CORPUS (weight 2, NOT STARTED) after Devil's Advocate review
flagged that awarding full weight-3 credit for a 7-payload baseline
violated the §1 criterion ("≥20 labeled failures") and the §2
anti-gaming rule. Decomposition preserves total weight (3) but honestly
separates the shipped scope (infrastructure that regenerates evidence)
from the unshipped scope (the corpus size that justifies the
precision/recall claim). Net effect on score: previous 79% claim
downward-revised to 68% (-3 weight points of in-sample credit removed).

By raw count: 8/10 = 80.0%. Criticality weighting (88.2%) reflects the
two critical-path items each carrying weight 3, plus CATALOG + AGENT-
FILE + ORCH-EARLY-FAILURE (weight 2 each), plus FIXTURES + BACKTEST-
HARNESS + OBS-DDL (weight 1 each). Outstanding (updated 2026-06-09
entry 4 post-row-split): ORCH-FAIL-OPEN (weight 1, class-1 incomplete-
work — blocks exit), ORCH-ARTIFACT-MODE (weight 1, class-2 carry-
forward — does NOT block exit per §4 rule) — collectively 2 weight,
12% of total — **but see cascade flag below: only the class-1 piece
blocks exit.**

### Distance to exit

- **Closest exit:** ORCH-FAIL-OPEN (+1, class-1 incomplete-work — the
  sole remaining Phase-1-exit-blocker per the §4 *Exit definition*
  rule) = +1 weight → 16/17 = 94.1%, at which point ARTIFACT-MODE
  remains the sole class-2 carry-forward (does NOT block exit) and
  **Phase-1 exits**. (Updated 2026-06-09 entry 4 after CIRCUIT-OPEN
  row-split: Spec B/C reclassified to class-3 phase-impossible — denominator
  was going to go 17→16, but Spec A surfaced as new class-1 ORCH-FAIL-OPEN —
  denominator returns to 17. Net distance dropped from +2 weight to +1
  weight because ARTIFACT-MODE is class-2 carry-forward and never
  blocked exit under the §4 rule introduced entry 3; the +2 estimate
  was pre-§4-taxonomy framing. Earlier estimates: +2 weight 2026-06-09
  entry 2 (post-BACKTEST-CORPUS reclassification, pre-§4 taxonomy);
  +4 weight when BACKTEST-CORPUS was scored NOT STARTED; +5 weight
  when DBT-CLOUD-CLIENT was scored NOT STARTED; +6 weight pre-OBS-DDL
  ship 2026-06-08; +8 weight when AGENT-FILE was NOT STARTED.)
- **Cascade flag (fully resolved 2026-06-09 entry 4).**
  Under β, the two remaining Phase-1 items each originally carried
  corpus-evidence dependencies framed as a binary in-sample-vs-
  held-out fork. **ARTIFACT-MODE** adjudicated 2026-06-09 entry 3:
  Option A, correctly-deferred carry-forward (class 2) —
  the proposed branch-coverage grep dissolved because the
  artifact-mode branch is aspirational, not built; carries forward
  without blocking exit per the §4 rule. **CIRCUIT-OPEN** adjudicated
  2026-06-09 entry 4 as a **row-split**: existence check revealed
  the row was conflating three artifacts — Spec A (v2-plan §1.8
  *Fail-open circuit breaker* — a misnomer for a stateless per-
  invocation property), Spec B (sprint-1-deferred #17 L484 stateful
  breaker design), Spec C (this checklist's original row text, same
  feature as Spec B). Resolution: Spec B/C → class-3 phase-impossible
  (no remote downstream API calls exist in Phase-1 to wrap; the
  wrappable surface set is empty by virtue of DBT-CLOUD-CLIENT
  class-3 + no LLM client + OBS-DDL writer being a local write
  outside CB scope); Spec A → new ORCH-FAIL-OPEN class-1 incomplete-
  work (the one real piece of remaining Phase-1 code surfaced by
  the exception-surface audit). **No outstanding Phase-1-exit
  decisions remain.** Distance to exit: +1 weight (ORCH-FAIL-OPEN).
  After Commit N+1 ships the broad-except handler + 4 tests:
  16/17 = 94.1%, ARTIFACT-MODE the sole class-2 carry-forward,
  Phase-1 exits. See §7 entry 2026-06-09 entry 4 for full row-split
  adjudication, spec-vs-spec drift identification, two-independent-
  moves arithmetic, credential-safety design rationale, and the
  two-commit shape (this docs commit + the FAIL-OPEN code commit).
- No calendar commitment offered here; estimates are not outputs of
  this checklist.

### Exit definition — three-class taxonomy and the carry-forward rule

Phase-1 exit is defined as: **all incomplete-work shipped, with
correctly-deferred items explicitly listed as event-or-Phase-2
carry-forwards.** Any item that originated in Phase-1 scope can
hold one of three dispositions, and the boundaries between them
carry the denominator-honesty discipline:

1. **Incomplete-work (in denominator, blocks exit).** Scored,
   shippable in Phase-1 against existing evidence, not yet shipped.
   Must ship before exit. Example today: `ORCH-FAIL-OPEN` (added
   2026-06-09 entry 4 as the Spec A half of the CIRCUIT-OPEN row
   split — the §1.8 stateless fail-open property; the one real
   piece of remaining Phase-1 code surfaced by the exception-
   surface audit).

2. **Correctly-deferred carry-forward (in denominator, does NOT
   block exit).** Scored, with explicit §3-recorded reasoning that
   the deliverable is **deferred under a named project discipline**
   (e.g., spike-or-iterate / lesson 4) and is **gated on an event
   that could occur in either Phase-1 or Phase-2**. Carries forward
   without blocking exit, provided the §3 row carries: (a) a named
   deferral discipline, (b) an explicit trigger (event), and (c) a
   gate that distinguishes the deliverable being built from its
   triggering condition being present (the double-condition pattern
   — see ARTIFACT-MODE L136). Example today: `ORCH-ARTIFACT-MODE`.

3. **Reclassified out-of-scope (REMOVED from denominator).** The
   Phase-1 bar itself requires a **phase-gated channel that cannot
   exist in Phase-1** regardless of effort. The work is *impossible*
   in Phase-1, not merely *unshipped*. Item leaves the scored
   denominator entirely; documented under "Items NOT scored" with
   explicit phase-impossibility rationale and §7 entry chain-of-
   custody. Examples today: `BACKTEST-CORPUS` (the ≥20 held-out
   floor required the Phase-2 webhook channel — 19→17 denominator
   shrink); `DBT-CLOUD-CLIENT` (same class); `ORCH-CIRCUIT-OPEN`
   (added 2026-06-09 entry 4 as the Spec B/C half of the CIRCUIT-
   OPEN row split — stateful breaker for remote downstream API
   calls; the wrappable remote-API surface set is empty in Phase-1
   because DBT-CLOUD-CLIENT is class-3 and no LLM client is built;
   OBS-DDL writer is a local write outside CB scope per the
   architectural rationale in the Items NOT scored row).

**The load-bearing boundary is class 2 vs class 3** (both look
like "deferred to later," but they differ on denominator treatment,
and misclassifying at this boundary is exactly how an item gets
reclassified-out — score goes up — when it should carry-forward —
score unchanged — or vice versa). The separating test, stated
operationally:

- **Class 3 (out-of-scope, REMOVE from denominator):** the bar
  itself requires a *phase-gated channel* that cannot exist in
  Phase-1. The work is *phase-impossible*.
- **Class 2 (carry-forward, STAYS in denominator):** the
  deliverable is deferred under a discipline and gated on an
  *event that could occur in either phase*. The work is
  *event-deferred but possible* if the trigger fires.

**The separating question to ask at every classification:** *"Is
the bar phase-impossible (class 3, remove) or event-deferred
(class 2, carry)?"* ARTIFACT-MODE is event-deferred (a triggering
artifact-mode payload could arrive in either phase) → class 2 →
stays in denominator → 15/17 unchanged. BACKTEST-CORPUS was
phase-impossible (the held-out corpus requires the Phase-2 webhook
channel that does not exist in Phase-1) → class 3 → removed →
15/17.

**Rationale.** Treating correctly-deferred items as exit-blocking
would force one of two distortions: (a) build speculative handling
against synthetic fixtures to "ship" the item (the spike-or-
iterate violation already rejected in `failure_triage_agent.py`'s
own docstring for ARTIFACT-MODE), or (b) reclassify event-
contingent items as phase-impossible (the class 2→3 category
error explicitly rejected by the separating-test above). Both
distortions are dishonest scoring dressed as completeness; the
deferred-with-named-discipline-and-double-conditioned-gate state
is the *correct* state for such items and must not be penalized
as if it were incomplete work, nor "promoted" to removal as if it
were phase-impossible.

**Score arithmetic.** Class-2 items remain in the scored
denominator (they are real Phase-1-eligible scope, just not
currently triggered); their "open" state does not block exit.
Class-3 items leave the denominator entirely (they were never
Phase-1 scope). Phase-1 exit threshold is therefore: `100% of
incomplete-work weight shipped`, NOT `100% of total scored weight
shipped`. The denominator stays honest (class-2 items still count
— their presence in the denominator tracks the reality that
triggered work might yet materialize); the gate stays honest
(correctly-deferred ≠ unfinished).

**Today's reading (updated 2026-06-09 entry 4).** Of the 2 weight
points outstanding (15/17): ARTIFACT-MODE (w1) is correctly-deferred
per the criteria above — class 2, carries forward, does not block.
ORCH-FAIL-OPEN (w1) is class-1 incomplete-work — the §1.8 stateless
fail-open property surfaced by the entry-4 exception-surface audit,
must ship before exit. **CIRCUIT-OPEN (Spec B/C, stateful breaker)
is no longer in the scored denominator — reclassified to class-3
phase-impossible per entry 4 row-split** (no remote downstream API
calls exist in Phase-1 to wrap). When ORCH-FAIL-OPEN ships (Commit
N+1), the score moves 15/17 = 88.2% → 16/17 = 94.1%, ARTIFACT-MODE
becomes the sole class-2 carry-forward, **Phase-1 exits on
incomplete-work=0**. The CIRCUIT-OPEN row-split itself meets the
phase-impossibility test of the separating-question above — a
higher bar than "the threshold needs calibration data"
(which is event-deferred, not phase-impossible).

**Falsifiability and audit trigger.** This definition is falsified
if a future "correctly-deferred" item turns out to have been
Phase-1-shippable against existing evidence all along (i.e., the
deferral was a dodge, not a discipline). Mitigation: every class-2
classification requires the §3 row to cite (a)+(b)+(c) above, AND
a Devil's Advocate review of the classification before it lands.

The **operational audit trigger** for a class-2 item: the
*legitimate* path from class-2-deferred to DONE is **(real
triggering event fires) → (build against the now-real trigger) →
(ship)**. The *illegitimate* path is **(someone decides to build
it anyway, no trigger) → (ship against a manufactured/synthetic
substrate) → DONE**. The audit catches the second by checking, at
any class-2 → DONE transition: *did a real triggering event
precede the build?* For ARTIFACT-MODE specifically: *did a real
artifact-mode payload arrive in the corpus before the branch was
built?* If the branch gets built and the item marked DONE and
there is no real artifact-mode payload in the corpus that
triggered it — that is the dodge.

**The audit trigger and lesson-4 spike-or-iterate are the same
guard from two angles.** A class-2 item reaching DONE without a
real triggering event is simultaneously (i) a *dodge* — the
original deferral was cover for work that someone later decided
to do anyway, exposing the deferral as unprincipled — AND (ii) a
*spike-or-iterate violation* — speculative handling built against
a manufactured fixture for a code path with no production evidence
it is needed. Either framing condemns it; their coincidence makes
the guard harder to evade. Surface any such transition as a
lessons-learned entry of the entry-6/entry-8 class.

---

## 5. What this checklist does NOT do

- **Does not pre-commit to a delivery date.** Calendar commitments
  for Phase 1 exit go in `sprint-1-deferred.md` if needed, not here.
- **Does not authorize starting ORCH.** Q1 probe runs first; if Q1
  surfaces multi-pattern hits in the existing 7-payload corpus,
  ORCH design must address them. If not, ORCH skeleton can proceed
  with disambiguation deferred (per pickup doc framing).
- **Does not freeze the item list.** New Phase-1 items can be added
  if a real need emerges (e.g., a security review demands an
  additional sentinel). Each addition gets its weight assigned at
  the time of addition, with the rationale recorded inline in §3.
- **Does not replace the v2-plan.** v2-plan §2 remains the
  architectural spec; this checklist is a *measurement layer* over
  it, recording which §2 items are in Phase-1 scope, deferred, or
  parallel-track.

---

## 6. Re-scoring policy

Update §4 (progress table) whenever an item flips status. Update
§3 (status column + Evidence) in the same edit. Do NOT update
the percentage in isolation — always cite which item changed
state and which commit moved it.

Re-weighting (changing an item from weight 2 → 3, or splitting an
item) requires a session-open note in §7 below explaining the
trigger. This defeats silent goalpost-moving.

---

## 7. Re-weighting log (append-only)

### 2026-06-07 — BACKTEST decomposition (Devil's Advocate adjudication)

**Trigger.** Day-6 Devil's Advocate review of the backtest harness commit
flagged that the BACKTEST row's flip NOT STARTED → PARTIAL (with full
weight-3 credit) violated two checklist rules simultaneously:

1. **§1 criterion:** Phase-1 exit requires "the backtest harness running
   over 20–30 labeled failures with precision/recall reported." The
   shipped harness scores 7. Awarding DONE-equivalent credit for <⅓ of
   the spec'd corpus is criterion-redefinition.
2. **§2 anti-gaming rule:** "Re-weighting an item retroactively requires
   a session-open note explaining why the original weight was wrong."
   The original flip neither reweighted (formal mechanism) nor decomposed
   (also forbidden if it inflates count) — it silently redefined what
   the weight measured. Strictly worse than reweighting because
   un-auditable.

**Resolution.** Decompose BACKTEST (weight 3) into:

- BACKTEST-HARNESS (weight 1, DONE) — the infrastructure that
  regenerates evidence: harness, scoring framework, label schema,
  baseline file. Reproducible, tested, audit-trail intact.
- BACKTEST-CORPUS (weight 2, NOT STARTED) — the corpus-size criterion
  the original item carried. Requires ≥20 labeled failures; only 7
  shipped (and all in-sample).

**Total weight unchanged (3).** Done credit net change: −2 weight points
(previously 3 awarded under "partial-counts-as-done"; now 1 awarded for
HARNESS only). Score moves 79% → 68%.

**Decomposition is honest under §2** because the count of inflated items
is NEGATIVE (one PARTIAL split into one smaller DONE + one explicit
NOT-STARTED, total shipped weight DECREASES). §2's "splitting forbidden"
clause targets splitting to INFLATE; the inverse use — splitting to
separate shipped from unshipped honestly — is permitted and required
when the two have distinct acceptance criteria.

**ORCH re-audit flag.** The same redefine-the-criterion maneuver was
applied to ORCH (PARTIAL with weight-3 credit, deferring CIRCUIT_OPEN +
artifact-mode + multi-pattern resolution). DA review did not require
immediate ORCH correction (user-prompt scope was BACKTEST), but flagged
that the same decomposition discipline should be applied to ORCH in
a next session. Pending until user adjudicates.

**Commit chain of custody.** This entry records adjudication. Code
changes land in the same commit as the harness; checklist update lands
with both. DA report preserved in commit message.

### 2026-06-08 — ORCH decomposition (sprint-1-deferred #17 closure)

**Trigger.** Day-6 BACKTEST DA review (commit `68b980ad`) flagged that
ORCH (Day-5 commit `0e008580`) had been scored PARTIAL with full
weight-3 credit via the same redefine-the-criterion maneuver that
BACKTEST has now been corrected for. Sprint-1-deferred #17 pre-drafted
the decomposition shape and gated the next-session deliverable on
closure. This entry records the closure.

**Validation findings (re-audit against actual code, not checklist
claims; entry 5 probe-validation discipline applied to the audit
itself).** Read `failure_triage_agent.py` + `test_triage_orchestrator.py`
+ `rca_schema.py`. `grep` for `CIRCUIT_OPEN`, `EvidenceMode.ARTIFACT`,
and multi-pattern logic across `src/triage/`. All four pre-drafted
sub-items align with actual code state:

- **ORCH-EARLY-FAILURE (DONE):** 7 documented branches all implemented
  in `triage_failure()`; 26 tests across 9 test classes; live Cluster C
  raw-fixture integration. One defensive branch (empty-projection-after-
  redact, `failure_triage_agent.py` L243-250) lacks a dedicated test —
  surfaced honestly in the Evidence column above and queued as
  sprint-1-deferred #18. Minor coverage gap, not a hidden deferred
  decision.
- **ORCH-CIRCUIT-OPEN (NOT STARTED):** `Outcome.CIRCUIT_OPEN` enum
  value exists at `rca_schema.py:86`; `grep` returns zero references
  outside the enum definition and a comment in `backtest_schema.py`.
  Zero emit paths in orchestrator.
- **ORCH-ARTIFACT-MODE (NOT STARTED, contingent):** `EvidenceMode.
  ARTIFACT` defined at `rca_schema.py:76`; the only mentions in
  `failure_triage_agent.py` are docstring-only (L14-16, L231-233),
  explaining the deferral rationale per lesson 4 spike-or-iterate.
  No branch logic exists.
- **ORCH-MULTI-PATTERN (PLACEHOLDER, moved to NOT scored):**
  `failure_triage_agent.py` L274-282 emits `UNKNOWN_HANDED_TO_HUMAN`
  with sorted matched `pattern_id`s in rationale when ≥2 patterns
  match; covered by `TestMultiMatch.test_multi_match_emits_unknown_
  with_listed_ids`. No richer logic snuck in. §1 explicitly excludes
  multi-pattern disambiguation from Phase-1; moved to "Items NOT
  scored" with explicit revisit criterion (backtest co-fire frequency
  >5% across labelled corpus).

**Meta-pattern check.** Probed specifically whether ORCH-EARLY-FAILURE
itself contains rolled-up deferred sub-decisions that were absorbed
into DONE credit (which would be a 3rd PARTIAL-as-DONE firing and
trigger §2 scoring-rule revision per the pickup memo's meta-pattern
threshold). It does not — all seven documented `triage_failure()`
branches are implemented; only one minor defensive fallthrough lacks
a dedicated test, and that gap is surfaced explicitly rather than
absorbed silently. **3rd PARTIAL-as-DONE firing did NOT materialize.**
Tracker stays at 2/3; §2 scoring-rule revision NOT triggered this
session. Continue case-by-case decomposition discipline.

**Resolution.** Decompose ORCH (weight 3) into four sub-items per
Proposal B (pre-draft shape, integer weights):

| Sub-item | Tier | Weight | Status |
|---|---|---|---|
| ORCH-EARLY-FAILURE | High (×2) | 2 | DONE |
| ORCH-CIRCUIT-OPEN | Medium (×1) | 1 | NOT STARTED |
| ORCH-ARTIFACT-MODE | Medium (×1) | 1 | NOT STARTED (contingent) |
| ORCH-MULTI-PATTERN | NOT SCORED | — | PLACEHOLDER (revisit-gated) |

**Weight accounting.** Original ORCH: weight 3 (critical tier), all 3
awarded as done. Decomposed: 4 scored sub-items totalling weight 4;
2 awarded as done (only EARLY-FAILURE actually shipped). Net done
credit: −1 weight point. Total scored denominator: +1 weight point
(honest acknowledgement that the original w3 row under-weighted the
deferred work it absorbed). EARLY-FAILURE moves from critical (×3)
to high (×2) because it does not block all other measurement — RCA-
SCHEMA, REDACT, CATALOG were independently completed and tested
before ORCH skeleton landed.

**Score impact.** Previous 13/19 = 68% → new 12/20 = 60.0%. Pickup-
memo prediction was 58–63%; landing at 60% sits cleanly in range.
Honest baseline.

**Decomposition is honest under §2** because the count of inflated
items is NEGATIVE relative to actual shipped scope: one PARTIAL-as-
DONE w3 row becomes one DONE w2 + two explicit NOT-STARTED w1 + one
NOT-SCORED placeholder. §2's "splitting forbidden" clause targets
splitting to INFLATE done credit; the inverse use — splitting to
separate shipped from unshipped honestly when sub-items have distinct
acceptance criteria — is permitted and required. Same pattern as the
2026-06-07 BACKTEST decomposition.

**Coverage-gap honesty (proactive discipline).** The empty-projection-
after-redact defensive branch (`failure_triage_agent.py` L243-250)
lacks dedicated test coverage. Surfaced in the ORCH-EARLY-FAILURE
Evidence column and queued as sprint-1-deferred #18 with explicit
gap location, impact assessment (low — defensive branch, no current
production correctness concern), resolution scope (~15 lines test +
mutation test), and trigger (anytime before Phase-1 exit; not exit-
blocking). Surfaced rather than absorbed because honest gap-tracking
compounds: future readers see "DONE with coverage gap (specific
location, specific reason)" instead of "DONE (implied complete
coverage)."

**Distance-to-exit recomputed.** +8 weight: AGENT-FILE (+2) + BACKTEST-
CORPUS (+2) + OBS-DDL (+1) + DBT-CLOUD-CLIENT (+1) + ORCH-CIRCUIT-
OPEN (+1) + ORCH-ARTIFACT-MODE (+1) → 20/20 = 100%.

**Closes sprint-1-deferred #17** per its explicit closure criterion:
checklist row decomposed (4 sub-items), §7 entry recorded, score
column updated, distance-to-exit recomputed, commit message
references item #17.

**Commit chain of custody.** Doc-only commit (no code changes). Devil's
Advocate review at adjudication time caught one arithmetic error
mid-report (denominator miscount: 12/19 = 63.2% corrected to 12/20 =
60.0% after re-counting items in proper tier placement) — cross-review
durability tracker increments by one firing across a distinct context
(audit work, not code work). Senior-director sanity check on audit-
trail artifacts (checklist + sprint-1-deferred #17 closure + #18
creation + memory update) included.

### 2026-06-08 (entry 2) — AGENT-FILE Shape A flip to DONE w2

**Trigger.** Day-6+ session opened AGENT-FILE (+2 weight) as the next
deliverable. Validation step (lesson 5 probe-validation discipline)
surfaced that `triage_failure(raw_payload: dict) -> RCARecord` is a
library function with **no shell-shaped invoker** today (single
non-test caller: `backtest_scoring.py`; no `__main__`, no CLI, no
webhook handler, no agent-file reference). Two coherent shapes
followed: Shape A (documentation agent, `tools: ["read"]`, no new
code) vs Shape B (operational agent, `tools: ["execute"]`, requires
shipping a fixture-replay CLI shim as predecessor). Shape A
selected per entry 4 (spike-or-iterate) — the empirical default
when no executable surface exists.

**Resolution.** AGENT-FILE flips NOT STARTED → DONE w2. New artifact:
`.github/agents/dv-failure-triage.agent.md` (Shape A, 176 lines).
Body documents boundary contract, RCARecord enum interpretation,
escalation semantics, Iron Rule, multi-pattern placeholder, known
limitations (`synth_01a'` head-boundary clipping; `synth_04`
earliest-position-wins / anchor-in-data-row), plus an explicit
"Current invocation status" section honestly recording the absence
of executable surface and naming the pending deliverables
(DBT-CLOUD-CLIENT, Phase-2 WEBHOOK) that would gain it.

**Why DONE per literal exit criteria, not PARTIAL.** The §3 row text
is "declaring tool restrictions, invocation surface,
design-decision-delegation rules". Shape A:

- Declares tool restrictions (`tools: ["read"]`) — verifiable in
  frontmatter.
- Declares invocation surface — read-only documentation surface,
  `user-invocable: true`, discoverable from the VS Code Copilot
  agent dropdown. A user can invoke this agent right now; the
  agent loads, reads context, produces output. That is an
  invocation surface, just a read-only one.
- The agent file enumerates design-decision-delegation rules
  inline (Iron Rule + escalation semantics + multi-pattern
  placeholder + credential-sentinel handling — all decisions
  documented for the downstream consumer).

The row's literal text does NOT require executable surface; reading
that requirement in would be retroactive criterion-redefinition
(the failure mode the BACKTEST DA and ORCH re-audit both caught
this sprint).

**Why this is NOT a 3rd PARTIAL-as-DONE firing.** PARTIAL-as-DONE
means: *deferred sub-decisions get rolled up into DONE credit
without explicit decomposition.* That is not what is happening here.
What is happening: *the deliverable is DONE per its literal exit
criteria; adjacent work (executable invocation surface) is
explicitly scoped to OTHER deliverables (DBT-CLOUD-CLIENT,
Phase-2 WEBHOOK), not absorbed into AGENT-FILE.*
Adjacent-work-explicitly-scoped-to-other-deliverables is a
different shape from sub-decisions-deferred-but-credited. The
honest test: removing AGENT-FILE from the checklist would NOT
make Phase-1 less complete in any way Shape A does not already
address — Shape A provides everything the row text describes.
Meta-pattern tracker: stays at 2/3.

**Future-reader misread guard.** Future readers (or future
Claude/Copilot sessions) MUST NOT interpret AGENT-FILE DONE w2
as "no further invocation work needed". The executable surface
is genuinely future work, tracked under DBT-CLOUD-CLIENT
(checklist row, NOT STARTED) and WEBHOOK (Items NOT scored,
Phase-2 activation). The agent file's "Current invocation status"
section is the in-artifact audit-trail for this distinction;
this §7 entry is the cross-artifact audit-trail. If a future
session proposes adding executable surface "to AGENT-FILE" as
scope expansion, surface this entry and route the work to its
correct deliverable instead.

**Size acceptance.** Agent file landed at 176 lines vs the ~150
surface-area guideline (17% over). Trim options enumerated
(drop cross-references, compress known-limitations, drop
vendored-skill paragraph, combine boundary bullets, or accept).
Each compression option loses load-bearing content (audit trail,
fixture-name precision, A6 answer, scan-ability). Accepted at
176 lines because every section maps to a substantive Shape-A
requirement, G1 DA verified factual claims against source, and
the cap is a "surface when triggered" heuristic, not a numeric
verdict. Density verified; accretion not present.

**Score impact.** 12/20 = 60.0% → 14/20 = 70.0%. Distance-to-exit
recomputed: +6 weight (BACKTEST-CORPUS +2, OBS-DDL +1,
DBT-CLOUD-CLIENT +1, ORCH-CIRCUIT-OPEN +1, ORCH-ARTIFACT-MODE +1).

**Commit chain of custody.** Single commit: agent file +
checklist row + §4 progress table + §7 entry. G1 DA self-caught
one wording inaccuracy ("mutation-tested" → "contract-tested"
on the TypeError boundary line) before commit; correction
applied in the same artifact. Cross-review durability tracker
increments by one firing in a distinct context (Shape A vs B
adjudication grounded in validation findings against actual
calling-system state).

### 2026-06-08 (entry 3) — OBS-DDL ship to DONE w1

**Trigger.** Day-6+ session opened OBS-DDL (+1 weight) as the next
deliverable. v2-plan §3 contained a sketch; the checklist row
required DRAFTED + REVIEWED + READY-TO-DEPLOY for credit. Drafted
to 100/100 lines under the surface-area cap.

**Resolution.** OBS-DDL flips NOT STARTED → DONE w1. New artifact:
`scripts/automation/src/triage/ddl/triage_invocations.sql` (raw
Snowflake DDL, NOT a dbt model). 19 columns derived from
`RCARecord` (8 fields) + `RedactionResult` (2 fields) + caller-
context (8 fields including ULID PK `invocation_id`) + 1 default
(`created_at`). Targets `OPS_PROD.LOGS.TRIAGE_INVOCATIONS`,
idempotent `CREATE TABLE IF NOT EXISTS`. Header sections (a)-(f)
cover schema source-of-truth + SCHEMA_VERSION pinning contract,
clustering deferral with FinOps revisit path, write-side enum +
cross-field invariant enforcement (Pydantic — not table-side;
Snowflake doesn't enforce CHECK on regular tables), manual one-
shot deploy mechanism, PII analysis (no masking policy required
— rationale carries metadata only, evidence_json is post-
redact.py output), writer-role narrowing forward-compat path.
GRANT block: DATA_OPS OWNERSHIP (with COPY CURRENT GRANTS) +
INSERT/SELECT per `setup.md §6`.

**F1 adjudication chain.** Implementation brief locked `DEFAULT
CURRENT_TIMESTAMP()`. Implementation-layer DA (cross-review)
flagged: `CURRENT_TIMESTAMP()` returns TIMESTAMP_LTZ; implicit
cast to TIMESTAMP_NTZ is session-TZ-dependent → UTC-correctness
defect on an audit column feeding Q-Streak window queries.
Resolution: `DEFAULT SYSDATE()` — returns UTC TIMESTAMP_NTZ
directly with no session-TZ dependency and ignores
`MOCK_CURRENT_TIME` / time-travel session overrides (correct for
an audit table). In-place no-revert comment prevents future
"simplification" regression. F1 resolved in-turn before commit.

**Why DONE per L124 exit criteria, not PARTIAL.** Three sub-
criteria each met:
- DRAFTED: file exists, exact 19-column shape, GRANT block,
  full (a)-(f) header.
- REVIEWED: DA surfaced F1 (TZ defect — applied), F2 (COPY
  CURRENT GRANTS — confirmed correct), F3 (rationale column —
  confirmed correct).
- READY-TO-DEPLOY: UTC-correctness defect closed, deploy command
  sequence in header (d), idempotent CREATE TABLE IF NOT EXISTS.

**Why this is NOT a 3rd PARTIAL-as-DONE firing.** PARTIAL-as-DONE
means: *deferred sub-decisions get rolled up into DONE credit
without explicit decomposition.* F1 was the only adjudicated
sub-decision and it was resolved in-turn, not deferred. Adjacent
follow-ups are explicitly scoped to other deliverables:
TRIAGE_AGENT_WRITER role narrowing → sprint-1-deferred #19
(substitutable later, no schema change). Meta-pattern tracker:
stays at 2/3.

**Verifications.** `rationale VARCHAR(2000)` matches Pydantic
`max_length=2000` exactly (boundary alignment — write-time off-
by-one risk closed). `Outcome.CIRCUIT_OPEN` enum confirmed
defined at `rca_schema.py:86` (column comment is NOT ahead of
code; the emit path is the deferred work tracked under ORCH-
CIRCUIT-OPEN).

**Size acceptance.** 100/100 lines exactly under the surface-area
cap. Header (a) col-order nit caught by reviewer (positional
"Columns 1-8" claim didn't match physical layout) and re-worded
to "RCARecord-derived columns (eight fields, identifiable by
name)" — fix consumed the 1-line margin without going over.

**Score impact.** 14/20 = 70.0% → 15/20 = 75.0% pre-DBT-CLOUD-
CLIENT reclassification. (Final post-reclassification: 15/19 =
78.9% — see entry 4 below.) Distance-to-exit dropped from +6
to +5 weight at the time of this ship.

**Commit chain of custody.** Single commit `ce6fcc8c`: SQL DDL
(new file) + sprint-1-deferred.md #19 (TRIAGE_AGENT_WRITER
narrowing). Tests: 1184 passed / 2 skipped baseline preserved
(DDL has zero Python touchpoints). NOTE: §3 OBS-DDL row + §4
progress table + this §7 entry were *not* updated in commit
`ce6fcc8c` — caught as doc-drift in entry-4 reconciliation and
folded into the entry-4 commit. Future ships must update the
row + table + §7 entry in the same commit as the artifact (the
AGENT-FILE pattern at entry 2 is the model; this row drifting
untreated for one commit is exactly the audit-trail-sanity-check
failure mode lessons-learned entry 6 promotion is queued to
capture).

### 2026-06-08 (entry 4) — DBT-CLOUD-CLIENT reclassification to NOT scored

**Trigger.** Day-6+ session opened DBT-CLOUD-CLIENT (+1 weight)
as the next-deliverable candidate after OBS-DDL ship. Validation
pass (lesson 5 probe-validation discipline + lesson 4 spike-or-
iterate) BEFORE any code went to Copilot. Four-point read of
`failure_triage_agent.py`, `backtest_scoring.py`, v2-plan §1.1/§2,
and the L125 row.

**Validation findings.** Recorded so the reclassification rationale
is durable, not just the verdict:

1. **Public entry-point shape.** `triage_failure(raw_payload: dict)
   -> RCARecord` at `failure_triage_agent.py:216` is the sole
   public entry. No `client` parameter, no `run_id` parameter, no
   second entry point. Module docstring (L3-L5) explicitly calls
   it the "Single public entrypoint". The agent is pure payload-
   in / record-out today.
2. **`select_evidence_mode` existence.** Zero matches in
   `scripts/automation/src/triage/**`. What exists instead:
   `_detect_mode(raw: dict) -> Optional[EvidenceMode]` at
   `failure_triage_agent.py:91` — a pure dict-shape inspector,
   no API calls, no client. The v2-plan §1.1 snippet is pure
   aspirational sketch.
3. **Backtest call site.** `backtest_scoring.py:161` calls
   `triage_failure(raw)` directly with a pre-loaded payload dict.
   No client is constructed, passed, or invoked. The backtest
   exercises the agent's classification path, not its evidence-
   acquisition path.
4. **dbt-mcp wrapper precedent in repo.** Zero triage-related MCP
   code exists. The closest precedent is `scripts/automation/
   mcp_profile_patch.py:58-120` (snow-mcp bridge for the
   orchestrator's profile step): typed methods over the Python
   MCP SDK (`ClientSession` + `stdio_client`), MCP invocation
   internal to the method, callers get plain `list | None`. NOT
   envelope pass-through.
5. **Naming drift.** v2-plan §1.1 / §2 call the agent file
   `triage_agent.py`; actual artifact is `failure_triage_agent.py`.

**Adjudication.** Option A (drop from Phase 1) selected. The L125
rationale ("STUB callable by ORCH for backtest replays") is
circular against the code state: ORCH calls no client and the
backtest already replays via direct payload feed. The wrapper has
NO Phase-1 consumer; its real consumer is the Phase-2 webhook
handler. Option B (typed stub + new `triage_failure_from_run_id`
entry) rejected as a spike-or-iterate violation: building the
acquisition seam now requires designing the acquisition contract
+ §1.8 fail-open boundary on speculation, with no live payload,
no webhook contract, no 2nd sample. Option C (full wrapper)
rejected as out of scope for Phase 1.

**Denominator-honesty discipline.** Dropping a NOT-STARTED item
raises the score (15/19 > 15/20) with zero work. This is
justified by the consumer analysis, NOT the arithmetic — the
same reclassification would hold if it LOWERED the score.
Explicitly stated so the score bump isn't mistaken for progress.

**Design carry-overs to the eventual Phase-2 implementation brief**
(banked in sprint-1-deferred #20, not lost):
- Mode selection must check artifact-LIST availability, not just
  the error-endpoint status — v2-plan §1.1 `select_evidence_mode`
  sketch omits the empty-artifact-list branch its own table
  promises ("`get_job_run_error` returns 404 OR artifact list is
  empty").
- Acquisition-API errors (dbt Cloud 5xx, network drop) must route
  to §1.8 fail-open (unknown + human-review), NOT the bare
  `raise` in the §1.1 sketch — the agent is a co-pilot, not a
  gate. §1.8's "LLM call times out" + "redact raises" enumeration
  is incomplete; "acquisition API errors" must be added.
- House MCP-wrapper pattern when it IS built: typed methods over
  the Python MCP SDK (precedent: `mcp_profile_patch.py:58-120`),
  NOT envelope pass-through. Implies the fixture-replay shim is a
  `DbtCloudClient` subclass returning fixture dicts keyed by
  `(run_id, operation)` — mocks at the Python seam, not the wire.
- Naming drift: v2-plan references `triage_agent.py` but the
  agent file is `failure_triage_agent.py`. The Phase-2 brief must
  use the actual filename.

**Score impact.** 15/20 = 75.0% → 15/19 = 78.9%. Total scored
denominator drops 20 → 19 (honest acknowledgement that the L125
row was admitting a Phase-1 consumer it never had). Done credit
unchanged at 15 (no work shipped this session). Distance-to-exit
drops +5 → +4 weight (BACKTEST-CORPUS +2, ORCH-CIRCUIT-OPEN +1,
ORCH-ARTIFACT-MODE +1).

**PARTIAL-as-DONE tracker.** Unchanged at 2/3. Nothing marked
DONE this session; reclassification is a denominator adjustment
with explicit rationale, not a credit grant.

**Commit chain of custody.** Single docs-only commit: §3 row
(OBS-DDL drift fix → DONE + DBT-CLOUD-CLIENT row → RECLASSIFIED
pointer) + §3 "Items NOT scored" table (DBT-CLOUD-CLIENT row
added) + §4 progress table + §4 prose paragraph + §4 distance
section + §7 entries 3 and 4 + sprint-1-deferred.md #20 entry +
pickup memory update. No code. Tests: 1184 passed / 2 skipped
baseline preserved (docs-only, no Python touchpoints).

### 2026-06-09 — entry-7 enforcement hook (sprint-1-deferred #21 closure)

**Trigger.** Lessons-learned entry 7 (shipped 2026-06-09 in commit
`81823d99`) documented the artifact-ship + score-update same-commit
rule and named its own known gap: no mechanical enforcement.
Sprint-1-deferred #21 pre-drafted the enforcement-hook ticket with
hard deadline "before BACKTEST-CORPUS ships." This entry records
the closure.

**Resolution.** Single path-matched `pre-commit` hook installed at
`scripts/automation/hooks/git/pre-commit`, activated per-clone via
`git config core.hooksPath scripts/automation/hooks/git`. Watched
paths: `scripts/automation/src/triage/**` (the original OBS-DDL
class drift) AND `docs/triage-agent/fixtures/**` (the BACKTEST-
CORPUS class — D1-A coverage decision adopted during FU1 substrate
review, before harness). Hook uses `--diff-filter=AR -M` (additions
+ renames into the watched paths; pure modifications pass —
proven by harness case c5). Honor-system `--no-verify` bypass with
optional `bypass-rationale:` audit-trail line; honest rationale is
verified by reviewers (entry 6), not by the hook.

**Acceptance criteria check-off.** All four clauses (a)-(d) of the
opened ticket satisfied:

- **(a) hook installed:** `scripts/automation/hooks/git/pre-commit`,
  executable, 4357 bytes. Install method = single `git config`
  command (documented in SETUP_GUIDE.md §B step 4.5).
- **(b) reject on watched-path addition without checklist:** PASS
  via harness c1, c3, c4 + verbatim worktree-equivalent reject
  text captured (full text in sprint-1-deferred.md #21 closure).
  Exit 1.
- **(c) accept on watched-path addition WITH checklist:** PASS via
  harness c2, c5. Exit 0.
- **(d) corpus-ship-path coverage:** SATISFIED. `docs/triage-
  agent/fixtures/**` covered by the regex; harness c3 directly
  proves enforcement on that path. If BACKTEST-CORPUS lands at a
  third path, the watched-path regex MUST be extended in the same
  commit (path-coupling flag documented in sprint-1-deferred.md
  #21 closure).

**Test harness.** `scripts/automation/hooks/git/test_pre_commit.sh`
runs 5 isolated scenarios in a `mktemp` scratch repo (trap-cleanup,
no parent-repo side effects). Pytest wrapper at
`scripts/automation/tests/test_entry7_hook.py` calls the harness
via subprocess. Test count moved 1184 → 1185 (1 new test), all
passing. New test execution ~3 s — verified during FU1 substrate
review; a 0.01 s timing would indicate the subprocess never fired.

**Session-start verifier.** `scripts/automation/hooks/session_
start_digest.sh` patched with a slash-normalized check that warns
when `core.hooksPath` is unset or pointing elsewhere. Catches the
"freshly-cloned-repo-forgot-the-one-time-setup" failure mode at
session start rather than at the first failed commit.

**Three real bugs caught during harness execution** (not predicted
at design time, fully detailed in sprint-1-deferred.md #21
closure): (1) `git checkout` carries staged changes across
branches, leaking case state — fix: `reset --hard HEAD + clean
-fdq` before checkout; (2) pathspec filtering drops cross-boundary
renames — fix: `--name-status` without pathspec in the harness pre-
check (the hook itself was always correct); (3) `git clean -fdq`
wipes empty directories that the init commit set up via `mkdir -p`
— fix: `mkdir -p` before each write in cases that depend on
transient directories.

**Bug 1 reasoning correction.** Initial draft reasoning for why
`81823d99` (own-dogfood entry-7 landing commit) passed enforcement
was: "because it staged the checklist." Re-reading proved that
wrong: `81823d99` shipped no files under the watched paths, so the
hook (had it existed) would have returned exit 0 because
`STAGED_NEW` was empty — checklist staging was incidental, not
load-bearing. The actual entry-7 protection for `81823d99` was
authorial review-discipline (entry 6 backstop). The hook covers
the future cases where discipline is forgotten on a watched-path
commit. Full reasoning in sprint-1-deferred.md #21 closure.

**Score impact.** None. FU1 is closing #21 (a deferred-list ticket,
NOT a §3 checklist row); the Phase-1 score remains 15/19 = 78.9%.
Distance-to-exit unchanged at +4 weight (BACKTEST-CORPUS +2, ORCH-
CIRCUIT-OPEN +1, ORCH-ARTIFACT-MODE +1). The hook is now in place
for BACKTEST-CORPUS, satisfying #21's hard deadline.

**PARTIAL-as-DONE tracker.** Unchanged at 2/3. Nothing marked DONE
this session; #21 closure ships an enforcement tool, not a §3
deliverable.

**Commit chain of custody.** Single atomic commit (own dogfood —
the FU1 deliverable + §3 enforcement-tool changes + tracking-
surface updates ship together): `scripts/automation/hooks/git/pre-
commit` (new) + `scripts/automation/hooks/git/test_pre_commit.sh`
(new) + `scripts/automation/tests/test_entry7_hook.py` (new) +
`scripts/automation/hooks/session_start_digest.sh` (verifier
patch) + `SETUP_GUIDE.md` (one-time setup step) + this §7 entry +
sprint-1-deferred.md (#21 moved Open → Closed with full closure
note). Tests: 1185 passed / 2 skipped (was 1184/2; +1 from the new
pytest wrapper).

### 2026-06-09 (entry 2) — BACKTEST-CORPUS reclassification to NOT scored

**Trigger.** Substrate review for BACKTEST-CORPUS (Phase-1's last
w2 NOT-STARTED row) opened with the user's OBS-DDL-D4b /
DBT-CLOUD-CLIENT-#20 validation-first pattern: gather acquisition-
channel + storage-strategy + exit-bar substrate, deliver to user,
adjudicate before any code. Substrate surfaced three candidate
shapes (α manual-pull, β reclassify, γ second-decompose). User
adjudicated to β with explicit structure: reclassify the corpus-
size criterion to Phase-2, affirm the harness + 7-payload in-sample
baseline as delivered Phase-1 work, state the no-held-out-accuracy
limitation explicitly, and relocate the §1 quality bar to a named
Phase-2 precondition for trusting the agent's outputs.

**Validation findings.** Recorded so the reclassification rationale
is durable, not just the verdict:

1. **Acquisition channel.** The gate requires ≥20 *net-new
   held-out* payloads (the existing 7 in-sample payloads do NOT
   count toward the held-out floor per `phase-2-backtest-corpus-
   gate.md` clause (b) — "reading '≥20' as '7 in-sample + 13
   held-out' silently contaminates the measurement with the 7
   payloads the patterns were designed against"). Only three
   sources can deliver those ≥20 net-new held-out payloads:
   (a) PAT-driven manual scratch pulls — gated on FBIN
   production failures actually happening AND being of catalogued
   patterns within the Phase-1 window (an uncontrolled external
   arrival process, not a plan); (b) the `dbt_cloud_client.py`
   wrapper just reclassified to NOT-scored in entry 4 above;
   (c) synthetic payloads — author-writes-test-and-thing-tested,
   the worst-case in-sample. The Phase-2 webhook handler is the
   only honest acquisition channel at scale. BACKTEST-CORPUS is the *accumulate*
   side of the same Phase-2 dependency DBT-CLOUD-CLIENT is the
   *fetch* side of; both are gated on Phase-2 webhook activation
   (Gate E follow-ups, v2-plan §4).
2. **Lineage trap.** BACKTEST was already decomposed once
   (legacy BACKTEST → BACKTEST-HARNESS + BACKTEST-CORPUS, §7 entry
   2026-06-07). A second decomposition of the same lineage at the
   point where completion is hard would be the third PARTIAL-as-
   DONE firing — the precise pattern the tracker has been watching
   for since 2/3. Decomposing because completing is hard is
   forbidden by §2; decomposing because the work contains two
   separable units is permitted. "Ship storage + ship the ≥20
   criterion" is one deliverable artificially cut at the expensive
   point, not two natural units. Second-decompose (Shape γ)
   rejected.
3. **Already-shipped Phase-1 scope is real.** The harness + 7-
   payload in-sample baseline are not the reclassified scope —
   they were scored DONE under BACKTEST-HARNESS (w1) at §7 entry
   2026-06-07 and remain DONE. β reclassifies only the corpus-size
   criterion (BACKTEST-CORPUS w2 row); the harness scoring is
   undisturbed. This distinguishes β from #20 where the whole
   item moved.
4. **§1 "20–30 → ≥20" drift.** §1.3 ("≥20–30 labeled failures")
   and §3 row ("≥20 labeled failures") disagreed. Aspirational
   "30" was silently dropped between §1 and §3. Reconciled to
   "≥20, more is better, no upper cap" in this same commit
   (audit-trail-sanity-check, lessons-learned entry 6).
5. **Quality-bar deletion check.** §1.3's exit bar reads "the
   backtest harness running over 20–30 labeled failures with
   precision/recall reported is the exit measurement. Without it,
   Phase-2 webhook activation has no quality signal." β does NOT
   delete this bar — it relocates it to a named Phase-2 gate (see
   "Phase-2-precondition relocation" below). The quality signal
   §1 demanded still gets demanded; it gets demanded at the point
   where it's achievable.

**Adjudication.** β selected: reclassify BACKTEST-CORPUS (w2,
NOT-STARTED) to "Items NOT scored" with Phase-2-webhook-trigger.
Affirm BACKTEST-HARNESS (w1, DONE) + 7-payload in-sample baseline
as delivered Phase-1 work; they remain scored as before. Shapes
α (manual-pull plan, couples Phase-1 exit to an uncontrolled
external failure-arrival process) and γ (second-decompose, third-
firing PARTIAL-as-DONE wearing a decomposition costume) both
rejected for the reasons in findings 1 and 2.

**Denominator-honesty discipline (falsifiability test).** Dropping
a NOT-STARTED w2 item raises the score (15/17 > 15/19) with zero
work. This is justified by the acquisition-channel analysis,
NOT the arithmetic — the same reclassification would hold if it
LOWERED the score. Same falsifiability framing as entry 4 (#20),
verbatim by intent: the discipline is to reject any reclassification
that's only honest when the arithmetic helps.

**No-held-out-accuracy-at-Phase-1-exit limitation (explicitly
stated, not papered over).** β reclassifies the held-out corpus
to Phase-2. This means **Phase-1 exits with no measured accuracy
on held-out data.** The Phase-1 backtest report carries only the
7-payload in-sample baseline (100% precision/recall by construction,
since these 7 informed catalog design — explicitly captioned in
`backtest-baseline-2026-06-07.md` and `p01_labels.yml v1.0.0`).
This is a known, accepted limitation of Phase-1 exit under β. It is
NOT a deferred TODO that will be quietly closed; it is the explicit
consequence of acknowledging that the corpus-acquisition channel is
Phase-2. The Phase-1 exit report MUST surface this limitation
verbatim — "this Phase-1 exit does NOT carry held-out accuracy
measurement" — so downstream consumers cannot mistake the in-sample
baseline for generalization evidence.

**Phase-2-precondition relocation.** The §1.3 quality bar
("≥20–30 labeled failures with precision/recall reported... without
it, Phase-2 webhook activation has no quality signal") is relocated
to a named Phase-2 precondition: **before the agent's outputs are
trusted in any non-advisory capacity (i.e., before any agent
suggestion is treated as anything but human-reviewable advice), the
held-out corpus MUST reach the Phase-2 BACKTEST-CORPUS gate spec
(this commit, `docs/triage-agent/phase-2-backtest-corpus-gate.md`).
Phase-2 webhook activation is permitted before this gate is met,
because webhook activation is what *produces* the corpus accretion —
but the agent's outputs during the accretion window are
advisory-only.** This is the §1.3 quality signal preserved verbatim
at the point where it's achievable.

**Design carry-overs to Phase-2 BACKTEST-CORPUS work (banked in
sprint-1-deferred #22, not lost):**

- **Storage strategy decided in principle.** Strategy B (git-LFS)
  permanently eliminated: LFS solves the size problem, not the
  content problem. Raw payloads contain production credentials by
  the gate-d-findings §5 design assumption; LFS bytes are repo
  content, so the PII story is unchanged while a toolchain
  dependency (per-clone `git lfs install`, CI LFS auth) is added
  to solve a size problem (260–400 KB for 20–30 minimized
  payloads) that Strategy A solves at zero cost. Banked so this
  is not re-litigated at Phase-2 open. Strategy A (commit
  redacted/minimized JSON under `docs/triage-agent/fixtures/**`)
  is the corpus mechanism. Strategy C (synthetic) is coverage-
  scaffolding only — legitimate for sentinel-fire edge cases when
  provenance-labeled `derivation: synthetic`, NEVER counted toward
  the ≥20 held-out production floor.
- **Minimizer is the first Phase-2 work item.** A deterministic
  minimizer (read raw → pipe through the actual `redact.py`
  pipeline → emit minimized fixture + label entry + sentinel-scan
  verification) is the correctness fix that makes Phase-2 corpus
  accretion cheap and correct. The current 4 committed fixtures
  were hand-minimized + sentinel-scan-verified, NOT
  `redact.py`-piped — that is a latent gap (hand-sanitization is
  not the production-redaction contract). The minimizer closes
  the gap AND doubles the fixtures as `redact.py` regression
  tests. ~200 LOC estimate; same validation discipline as every
  other deliverable. Banked as Phase-2 BACKTEST-CORPUS first item,
  NOT pulled into Phase 1.
- **Entry-7 hook coupling.** `docs/triage-agent/fixtures/**` is
  watched by the entry-7 hook installed in #21 closure. Every
  corpus addition fires the hook and requires the checklist update
  in the same commit. This is the entry-7 falsification protocol
  named in #21 closure executing as designed. The minimizer's
  output discipline must include staging the checklist update
  in the same commit as the fixture emission.
- **v2-plan addendum.** v2-plan has no dedicated corpus section
  (Finding 1 of this session's substrate). The §3 row hardening
  done here + the standalone gate spec (this commit) become the
  authoritative corpus design; v2-plan addendum is banked as a
  small post-hoc commit pointing v2-plan §1/§2 at the now-
  authoritative gate spec, and correcting the §2 path drift
  (`scripts/automation/tests/fixtures/triage/` written, `docs/
  triage-agent/fixtures/` actual) at the same time.
- **§1.3 quality-bar reconciliation.** "≥20–30" reconciled to
  "≥20, more is better, no upper cap" in §1 prose AND in the
  Phase-2 gate spec's clause (a). Aspirational "30" retired with
  this note so a future reader does not treat its absence as a
  regression.

**Cascade flag for next adjudication (not resolved here, but
sharpened into a testable per-item fork).** Under β, the two
remaining Phase-1 items each carry corpus-evidence dependencies in
their §3 evidence cells (real disposition strings, not paraphrased):

- **ORCH-CIRCUIT-OPEN** (§3 disposition: **"NOT STARTED"**, evidence
  cell at L135 says "Q2e-1 work; gated on Day-6+ corpus evidence
  showing breaker need"). The gate is **threshold/policy design**:
  what failure-streak distribution warrants opening the breaker?
  This is a *size and distribution* question — in-sample n=7 is
  insufficient to characterize a streak distribution at any honest
  confidence interval. Per-item provisional read: **leans
  Phase-2-blocked**, but the threshold could ship as a deferred
  config knob (default-conservative) with the calibration deferred
  to Phase-2 corpus arrival — a third option the next-session
  adjudication should weigh.
- **ORCH-ARTIFACT-MODE** (§3 disposition: **"NOT STARTED
  (correctly-deferred carry-forward — class 2 per §4 exit-
  definition)"** — disposition hardened in this same commit;
  evidence cell at L136 originally said "Revisit when ≥1
  artifact-mode payload surfaces in backtest corpus" and was
  hardened to a double-conditioned gate (see §3 L136 current
  text) in the same commit as this entry's correction). The gate
  is **build-presence**, not data-presence: the deliverable is
  **build-the-branch, not test-existing-branch**. Source
  verification (in this same commit's adjudication, recorded in
  §7 entry 2026-06-09 entry 3): `_detect_mode` (L91-117) returns
  only `EARLY_FAILURE` or `None`; `_classified` (L207) hardcodes
  `evidence_mode=EARLY_FAILURE`; the orchestrator never imports
  `redact_artifact` despite the function existing at `redact.
  py:528`; the module docstring (L14-16) explicitly cites "zero
  P0.1 evidence supports an artifact branch today (lesson 4
  spike-or-iterate)" as the deferral rationale. There is no
  artifact-mode-specific code path to grep-instrument. The
  earlier framing in this same entry (now-corrected by entry 3,
  preserved here as audit trail of the reasoning evolution)
  proposed a branch-coverage grep on the 7 in-sample payloads
  to decide Phase-1-satisfiable vs Phase-2-blocked; that framing
  was upstream of the real question — no grep can satisfy an
  item whose deliverable doesn't exist. **The correct
  adjudication is Option A: leave deferred-as-labeled (class 2
  carry-forward per §4 exit-definition).** Option B (build
  minimal handling now) was rejected by the codebase itself when
  the spike-or-iterate deferral was written into the module
  docstring with the lesson number cited; reopening that
  deferral to build speculative handling against a manufactured
  fixture is the exact spike-or-iterate violation lesson 4
  names. Option C (reclassify out-of-scope, class 3) was
  rejected as a category error per the §4 separating-test:
  ARTIFACT-MODE is event-deferred (a triggering payload could
  arrive in Phase-1 or Phase-2), not phase-impossible the way
  BACKTEST-CORPUS was (its ≥20-held-out floor required the
  Phase-2 webhook channel). ARTIFACT-MODE remains in the
  scored denominator as a class-2 correctly-deferred item with
  the §3 row's gate now double-conditioned (payload AND build)
  to close the data-shape-satisfies-the-item gap the original
  single-condition language permitted. **Per-item resolution:
  A, scoring unchanged at 15/17, item carries forward without
  blocking exit per the §4 exit-definition rule.**

**Next-session adjudication required, per item separately:**
(i) for ORCH-CIRCUIT-OPEN, is the deferred-config-knob third
option acceptable Phase-1 scope (correctly-deferred carry-
forward, class 2 under §4 exit-definition), does the threshold
need calibration data before any ship (incomplete-work, class 1,
blocks exit), or does the bar meet phase-impossibility for class
3 removal (higher bar than "needs calibration")? (ii) for ORCH-
ARTIFACT-MODE: **resolved in this commit as Option A** — see §7
entry 2026-06-09 entry 3 for the source-verification finding
that the artifact-mode branch is aspirational (not built), which
dissolved the proposed branch-coverage grep because there is no
branch to instrument. The §3 row was hardened in this commit
(double-condition: payload AND build) and the §4 exit-definition
section was added in this commit to formalize how correctly-
deferred items interact with exit. Outstanding decision is
CIRCUIT-OPEN only.

Operational implications differ by item:

- **If ORCH-CIRCUIT-OPEN ships as deferred-knob:** Phase-1 takes
  the +1; the calibration deferral itself becomes a Phase-2
  precondition documented alongside the BACKTEST-CORPUS gate.
- **ORCH-ARTIFACT-MODE: resolved in this commit as Option A —
  correctly-deferred carry-forward (class 2 per §4 exit-
  definition).** Scoring unchanged at 15/17 (item stays in
  denominator, does not block exit per §4 exit-definition). No
  +1 is taken; no reclassification occurs; the deliverable is
  genuinely future work gated on both payload arrival AND build,
  neither speculatively-build-now nor remove-from-scope. See
  §7 entry 2026-06-09 entry 3 for full adjudication and source
  verification.
- **If CIRCUIT-OPEN also resolves to class 2 (deferred-knob):**
  Phase-1 exits on `incomplete-work=0` per §4 exit-definition;
  both items carry forward as class-2 items; the "no held-out
  accuracy at Phase-1 exit" limitation this entry records for
  BACKTEST-CORPUS extends to both, AND each carries the class-2
  audit-trigger discipline (any future DONE transition without a
  real triggering event surfaces as a dodge + spike-or-iterate
  violation, both framings condemning).

This is the validation-before-code discipline applied to the *exit
itself*: do not start either ORCH item until the fork is resolved,
because starting ORCH-CIRCUIT-OPEN on the assumption that
in-sample suffices, then discovering held-out is required, builds
the wrong artifact. Resolve the fork first, then act.

Do NOT preemptively reclassify either ORCH item in this commit.
Recording the fork is the deliverable here; resolving it is the
next session's deliverable.

**Score impact.** 15/19 = 78.9% → 15/17 = 88.2%. Total scored
denominator drops 19 → 17 (honest acknowledgement that the L108
row was admitting a Phase-1 deliverable whose acquisition channel
is Phase-2). Done credit unchanged at 15 (no work shipped this
session). Distance-to-exit drops +4 → +2 weight (ORCH-CIRCUIT-OPEN
+1, ORCH-ARTIFACT-MODE +1) — pending the cascade flag above.

**PARTIAL-as-DONE tracker.** Unchanged at 2/3. Nothing marked
DONE this session; reclassification is a denominator adjustment
with explicit rationale, not a credit grant. (Contrast γ which
WOULD have triggered #3 by marking a half-deliverable DONE; that
shape was rejected for exactly this reason.)

**Commit chain of custody.** Single docs-only commit:

- §1.3 prose: "20–30" → "≥20, more is better, no upper cap" with
  inline reconciliation note pointing to this entry.
- §3 High-tier table: BACKTEST-CORPUS row → reclassified pointer
  (mirrors L125 DBT-CLOUD-CLIENT row formatting from entry 4).
- §3 "Items NOT scored" table: BACKTEST-CORPUS row added with
  the validation findings 1-3 summarized + Phase-2-webhook-trigger
  + reference to gate spec + reference to sprint-1-deferred #22.
- §4 progress table: High-tier row 4 → 3 items, weight total 8 → 6;
  Total 11 → 10 items, weight total 19 → 17. Percentage 78.9% →
  88.2%.
- §4 prose paragraph + Distance-to-exit section: updated arithmetic
  + cascade flag noted.
- §7 entry (this entry, 2026-06-09 entry 2).
- New file: `docs/triage-agent/phase-2-backtest-corpus-gate.md` —
  the five-clause acceptance gate spec, drafted this session
  (clauses (a) size and (e) precision/recall threshold pinned per
  user adjudication; clauses (b) in/out ratio, (c) pattern coverage,
  (d) provenance shape codified from existing discipline).
- `docs/triage-agent/sprint-1-deferred.md`: #22 entry added
  (BACKTEST-CORPUS Phase-2 brief — first work item: deterministic
  minimizer; storage strategy = A; B eliminated; gate spec link).
- Pickup memory update: `/memories/repo/triage-day6-pickup.md`
  HEAD update + β reclassification recorded + cascade fork named
  as next-session opener.

No code. Tests: baseline preserved (docs-only, no Python touchpoints).

---

### 2026-06-09 entry 3 — ARTIFACT-MODE Option A adjudication + §4 exit-definition introduction (3-class taxonomy)

**Trigger.** Entry 2's cascade flag named the next-session adjudication
as "per-item, does the contingency resolve against in-sample (Phase-1-
completable) or held-out (Phase-2-blocked)?" Adjudicating ARTIFACT-MODE
required first checking whether the artifact-mode branch *exists in
code* to be tested — Gemini's point-2 ordering: check built-vs-
aspirational before designing the empirical check, because if
aspirational, the empirical check dissolves entirely.

**Source verification (neutral, no pre-conclusion).** The artifact-mode
branch in `failure_triage_agent.py` is **aspirational, not built**.
Evidence:

- `_detect_mode` (L91-117) returns only `EvidenceMode.EARLY_FAILURE`
  or `None`. No code path produces `EvidenceMode.ARTIFACT`.
- `_classified` (L207) **hardcodes** `evidence_mode=EvidenceMode.
  EARLY_FAILURE` — no parameterization for ARTIFACT.
- Orchestrator imports `redact_early_failure` only (L69-73); never imports `redact_artifact`
  despite the latter existing at `redact.py:528`.
- Module docstring (L1, L14-16) reads *"Day-5 Q2 skeleton (early-
  failure only)"* and *"Artifact mode (`run_results.json`) is out of
  Phase-1 scope per sprint-1-deferred — zero P0.1 evidence supports an
  artifact branch today (lesson 4 spike-or-iterate)"*.
- Triage entrypoint at L226-235 (mode=None handler) rationale text
  itself reads *"no artifact-mode fixture available (all 7 P0.1
  payloads were early-failure shape; lesson 4 spike-or-iterate)"*.

**Consequence: the proposed branch-coverage grep dissolves.** Entry 2
framed the resolution as "does the 7-payload coverage grep find
branch-exercise on the artifact-mode path?" — but there is no branch
to instrument. Coverage on a non-existent code path is undefined; any
empirical check would either (a) collapse to the data-shape grep the
entry-2 prose explicitly warned against, or (b) measure lines that
don't exist. The deliverable is reframed: **build-the-branch, not
test-existing-branch.**

**Adjudication — Option A (leave deferred-as-labeled), with the
alternatives rejected on the record.**

- **Option B (build minimal handling now): rejected.** Building the
  artifact-mode branch now would require a fixture to build against,
  and no artifact-mode fixture exists — all 7 P0.1 payloads are
  early-failure shape. B would mean building a handler for a payload
  shape never seen, tested against a manufactured fixture, for a
  code path with zero P0.1 evidence it is needed. **The codebase has
  already adjudicated this** — the module docstring writes the
  spike-or-iterate deferral inline with the lesson number cited. B
  would overturn a documented spike-or-iterate deferral to build
  speculative handling against synthetic data: the exact thing DBT-
  CLOUD-CLIENT's Option B was rejected for (smuggling an unbuilt
  seam into the deliverable on speculation).

- **Option C (reclassify out-of-scope, remove from scoring):
  rejected as category error.** C looks parallel to the BACKTEST-
  CORPUS β reclassification but isn't. BACKTEST-CORPUS reclassified
  because its *acquisition channel* (the ≥20 held-out corpus)
  required the Phase-2 webhook channel — *phase-impossible* in
  Phase-1 regardless of effort. ARTIFACT-MODE is different: its
  trigger (an artifact-mode payload surfaces) could occur in
  *Phase-1* (a production artifact-mode failure could be harvested
  before webhook activation) or *Phase-2*. It is not phase-gated
  on the failure-channel; it is event-gated on payload arrival. Per
  the §4 separating-test ("is the bar phase-impossible or event-
  deferred?"), ARTIFACT-MODE is event-deferred → class 2 → stays
  in denominator. Reclassifying it as class 3 (out-of-scope,
  removed) would be precisely the unprincipled denominator move
  the falsifiability discipline exists to prevent.

- **Option A (leave deferred-as-labeled, with gate hardening):
  correct.** The item's current disposition was already honest;
  spike-or-iterate deferral is documented in code with the lesson
  cited; the trigger is event-not-phase. Nothing to *do* except
  (i) recognize the existing state is right, and (ii) close the
  one real defect Gemini's review surfaced: the §3 gate was
  **single-conditioned** on payload arrival, permitting the
  failure mode where a payload arrives and the item gets marked
  satisfied without code being built. Gate hardened in this
  commit to **double-condition**: (i) ≥1 artifact-mode payload
  surfaces AND (ii) the handling branch is built and exercised
  by that payload. Closes the data-shape-satisfies-the-item gap;
  payload arrival is necessary but not sufficient.

**§4 exit-definition introduction — 3-class taxonomy.** The
ARTIFACT-MODE adjudication surfaced a Phase-1-exit-definition
question that needed explicit resolution before CIRCUIT-OPEN's
adjudication: do correctly-deferred items block exit, or carry
forward? Resolved by introducing a 3-class taxonomy in §4:

1. **Incomplete-work** (in denominator, blocks exit until shipped)
2. **Correctly-deferred carry-forward** (in denominator, does NOT
   block exit — class 2)
3. **Reclassified out-of-scope** (removed from denominator — class 3)

The **load-bearing boundary is class 2 vs class 3** — both look
like "deferred to later" but differ on denominator treatment, and
misclassifying at this boundary is exactly how an item gets
reclassified-out (score rises) when it should carry-forward
(score unchanged), or vice versa. Separating test: *"is the bar
phase-impossible (class 3, remove) or event-deferred (class 2,
carry)?"* See §4 *Exit definition* subsection for the full
rationale, score arithmetic, falsifiability, and the operational
audit trigger (coupled with lesson-4 spike-or-iterate: a class-2
item reaching DONE without a real triggering event is
simultaneously a dodge AND a spike-or-iterate violation — same
guard, two angles, both framings condemn).

**Why both pieces ship together (entry-6 same-commit discipline).**
The §3 gate hardening, §4 exit-definition introduction, §4 cascade-
flag bullet update, and §7 entry 2 corrections all depend on the
same finding (artifact-mode branch is aspirational; ARTIFACT-MODE
is class 2, not phase-2-blocked). Shipping them across separate
commits would leave intermediate states where sections of one
file disagree on the same item's disposition — the audit-trail-
sanity-check failure mode entry 6 names. All seven edits in one
commit per the same-commit discipline.

**Score impact: none.** ARTIFACT-MODE stays at "NOT STARTED
(correctly-deferred carry-forward)" weight 1 in the scored
denominator. **Phase-1 still 15/17 = 88.2%.** The exit-definition
introduction is infrastructure for *interpreting* the score, not
a score adjustment.

**Cascade-flag consequence.** Cascade flag now partially resolved
(ARTIFACT-MODE done; CIRCUIT-OPEN remains). CIRCUIT-OPEN's three
options (deferred-config-knob = class 2; ship-now = class 1
incomplete-work; reclassify = class 3 only if phase-impossibility
test is met — a higher bar than "needs calibration data") each
map cleanly onto the §4 taxonomy. CIRCUIT-OPEN adjudication is
now the sole remaining Phase-1-exit decision, and it will be
adjudicated against the scoring framework this commit establishes.
**Right order: define how deferred items interact with exit
BEFORE creating another one.**

**Pre-push DA discipline (entry 8 applied).** This commit's draft
pieces (Drafts 1, 2, 3 + locked-scope §4 bullet + §7 entry 3) were
reviewed by user-DA before any file edit landed (per the entry-8
lesson banked in c95c770b). DA findings 1-5 incorporated into the
revised drafts that landed: three-class taxonomy made explicit
(Finding 1); audit-trigger coupled with spike-or-iterate (Finding 2);
Draft 1 reordered to lead with the operative rule (Finding 3);
locked §4 cascade-flag bullet to same-commit scope (Finding 4);
memory sync flagged as post-commit follow-up (Finding 5). Pre-push
self-DA pass on the assembled 7 edits run before commit per
quality-gates.md self-Copilot pass discipline. **β-chain pattern
broken: this is a single-commit, DA-before-push docs-only edit,
in contrast to the bfd97552 → b64d6c7b → c95c770b three-commit
chain caused by skipping pre-push DA on bfd97552.** Falsifiability
bar for entry 8 (next 3 docs-only >200 LOC commits clean on first
post-push read) starts counting with this commit.

**Commit chain of custody.** Single docs-only commit:

- §3 L136 ARTIFACT-MODE row: gate hardened to double-condition,
  rule-first ordering (operative rule before source-evidence
  recitation per Finding 3).
- §4: new *Exit definition — three-class taxonomy and the carry-
  forward rule* subsection (Finding 1 + Finding 2 incorporated).
- §4 cascade-flag bullet: ARTIFACT-MODE resolution + class-2 vs
  class-3 mapping for CIRCUIT-OPEN's pending decision
  (Finding 4 — same-commit drift prevention).
- §7 entry 2026-06-09 entry 2 ARTIFACT-MODE bullet: Option A
  resolution + audit trail of reasoning evolution.
- §7 entry 2026-06-09 entry 2 Next-session adjudication clause:
  item (ii) marked resolved with pointer to entry 3.
- §7 entry 2026-06-09 entry 2 operational-implications bullets:
  item (ii) corrected; "both reclassify" bullet rewritten as
  "both class-2" path.
- §7 entry 2026-06-09 entry 3 (this entry): full adjudication
  record + exit-definition introduction rationale.

No code. Tests: baseline preserved (docs-only, no Python
touchpoints).

### 2026-06-09 entry 4 — CIRCUIT-OPEN row split: Spec A FAIL-OPEN promoted to class-1 + Spec B/C stateful CB reclassified to class-3

**Trigger.** Entry 3 left CIRCUIT-OPEN as the sole outstanding
Phase-1-exit decision, with its three options pre-mapped onto the
§4 taxonomy. Adjudicating it required first running the existence
check entry 3 established for ARTIFACT-MODE: does the thing the
row names (a circuit breaker) *exist in code* to be tested, or is
it aspirational? The existence check did not just answer that
question — it dissolved the row's framing entirely by revealing
that "CIRCUIT-OPEN" is **two unrelated features wearing one name**.
The adjudication therefore became a row-split, not a single up/
down vote.

**Source verification — what "CIRCUIT-OPEN" actually refers to in
the artifacts.** Three citations, all on the branch HEAD before
this commit:

- **Spec A — stateless fail-open property.** `docs/triage-agent/v2-plan.md`
  L85 titles §1.8 *"Fail-open circuit breaker"* and L87 reads:
  *"If `redact.py` raises, if LLM call times out, or if observability
  DDL write fails → agent emits `unknown` classification + human-
  review flag, never blocks the calling pipeline. The agent is a
  co-pilot, not a gate."* This is a stateless per-invocation
  property: an unexpected exception in one of three named
  dependencies must convert to UNKNOWN + human-review rather than
  propagate. No state, no open/close, no probes. **The word "circuit
  breaker" in the §1.8 header is the misnomer that seeded the drift**
  — the property §1.8 describes is "fail-open on exception," which
  is not what a circuit breaker is.

- **Spec B — stateful breaker, design.** `docs/triage-agent/sprint-1-deferred.md`
  L484 (item #17, the ORCH decomposition) defines ORCH-CIRCUIT-OPEN as:
  *"Q2e-1 work: design + implement + test circuit-breaker open/close
  state with retention + half-open probe semantics. Acceptance:
  backtest emits `Outcome.CIRCUIT_OPEN` for at least one labelled
  case + sentinel-test corpus admits the outcome as labellable."*
  This is genuine circuit-breaker semantics — open/close state
  machine, retention, half-open probes. Stateful, multi-invocation.
  Defensive resilience on downstream API calls.

- **Spec C — stateful breaker, checklist row text.** `docs/triage-agent/phase-1-exit-checklist.md`
  L135 (the ORCH-CIRCUIT-OPEN row this entry adjudicates) reads:
  *"`Outcome.CIRCUIT_OPEN` handling — circuit-breaker open/close +
  half-open probe semantics for downstream API calls"*. Identical
  scope to Spec B.

Spec B and Spec C describe the same stateful circuit-breaker
feature; Spec A describes a different, stateless fail-open
property. The row labels itself with Spec C and inherits Spec B's
gate, but the v2-plan §1.8 the row implicitly invokes is Spec A.
**Same deliverable name, three artifacts, two unrelated features —
spec-vs-spec drift within one row's own definition.** Methodology
lesson banked separately as a follow-up entry, not folded into
this commit's body (see *Closeout — methodology observation*).

**Code-evidence dissolve for Spec B/C (the stateful breaker).** The
stateful CB is *aspirational and phase-impossible*, not deferred:

- `rca_schema.Outcome.CIRCUIT_OPEN` exists at `rca_schema.py:86`.
  Single enum slot. No emit paths anywhere in
  `scripts/automation/src/triage/**` (re-grep on branch HEAD
  before this commit confirms).
- Spec B/C calls out **downstream API calls** as the thing being
  wrapped. In the Phase-1 codebase, the **set of remote downstream
  API calls is empty**:
  - `triage_failure(raw_payload: dict) -> RCARecord`
    (`failure_triage_agent.py:216`) is the sole entrypoint and
    takes a pre-loaded dict — no client construction, no API call.
  - DBT-CLOUD-CLIENT was reclassified class-3 in entry 2026-06-08
    entry 4: the dbt-Cloud-pull client doesn't exist in Phase-1
    scope.
  - LLM call: §1.8 names it as a fail-open trigger, but no LLM
    client is built in Phase-1 (catalog patterns match
    deterministically).

  OBS-DDL is explicitly *out of scope* for this enumeration: it's
  a local Snowflake write, not a remote API call. Its exception
  surface is the fail-open property (Spec A) territory, not
  stateful-CB territory. (The OBS-DDL writer is also unbuilt in
  Phase-1 — only the DDL ships in `ce6fcc8c` — but that's a
  separate fact; even if it shipped, stateful CB semantics for a
  local warehouse write may not be the right architecture at all.)

A circuit breaker needs something to wrap. Spec B/C has nothing
to wrap because every wrappable remote dependency is itself
Phase-2 or unbuilt. This is **phase-impossible by the §4
separating test** — not "we chose to defer it"; "the wrappable
remote-API surface required for it to be a real feature does not
exist in Phase-1 regardless of effort." Same shape as
BACKTEST-CORPUS (the ≥20 held-out corpus required the Phase-2
webhook channel) and DBT-CLOUD-CLIENT (the executable invocation
surface routes to other deliverables).

**Spec A status: ~60% shipped, gap audited.** The stateless
fail-open property has partial coverage in `triage_failure` today
but a real, structural gap on the `redact_early_failure`
exception surface. Exception-surface audit summary:

| Gap | Where | Today | Status |
|---|---|---|---|
| #1 — non-sentinel exception in `redact_early_failure` | `failure_triage_agent.py` L239-250 (the `try` / `except CredentialSentinelFired` block in `triage_failure`) | only `CredentialSentinelFired` caught; any other exception propagates to caller | **real Phase-1 gap, §1.8 violation** |
| #2 — `truncate_logs` TypeError on non-str | `redact.py` L402-405 (the `isinstance` gate + `raise TypeError(...)`) | gated upstream by `_redact_node`'s `isinstance(value, str)` check; unreachable today, coupling-fragile | theoretical |
| #3 — catalog `CatalogValidationError` at runtime | `fbin_error_catalog.py:116` (`class CatalogValidationError(ValueError)`) | catalog pre-validated at module import (Mut1-7, Mut9d); raised only at load time | theoretical |

**Citation note (point-in-time-as-of-Commit-N).** The line numbers in
the gap table reflect HEAD as of *this commit*. **Commit N+1 will
shift them** when the broad-except handler is inserted into
`triage_failure` (the handler adds ~25 LOC at L239-250, shifting all
below). The structural anchors in parentheses ("the `try` / `except
CredentialSentinelFired` block in `triage_failure`", "the `isinstance`
gate + `raise`", "`class CatalogValidationError(ValueError)`") survive
the shift; the line numbers don't. **Future readers should trust the
structural anchors over the line numbers after Commit N+1 lands.**
This is the *citation half* of the documented-vs-actual drift class
(three line-citation drifts in three commits — c95c770b off-by-4 on
the redact import; the entry-3 self-DA caught it; this entry's draft
off-by-18 on the try/except block, caught by the entry-4 verification
pass) — banked as methodology observation in *Closeout* below.

Gap #1 is the one Spec A actually fails on today. Gaps #2 and #3
are theoretical (one isinstance gate away, one import-time-only).
The audit's conclusion: **one mechanism — a broad `except Exception`
around `redact_early_failure` in `triage_failure` — closes the
real gap and passively covers the theoretical ones, with zero
speculative defense.** No anticipatory guards on #2 or #3: per the
spike-or-iterate discipline (lesson 4), no real failure has
surfaced for either, and adding isinstance re-checks duplicating
the dispatcher's existing gates would be exactly the speculative
build that discipline prevents. The broad-except is the single
mechanism; #2 and #3 ride along.

**Row split — three independent dispositions, one row.**

- **CIRCUIT-OPEN (the stateful CB, Spec B/C) → reclassify to class-3
  (Items NOT scored).** Justification: phase-impossible per §4
  separating test (no remote downstream API calls exist in Phase-1
  to wrap; the wrappable remote-API surface set is empty because
  DBT-CLOUD-CLIENT is class-3, no LLM client is built, and the
  OBS-DDL writer is a local Snowflake write outside CB scope per
  the architectural rationale above). Same shape as BACKTEST-CORPUS
  and DBT-CLOUD-CLIENT class-3 dispositions. Phase-2 re-entry
  trigger: when at least one of {dbt-Cloud-pull client, LLM client}
  — the *remote* downstream dependencies whose failure profile
  (rate limits, timeouts, cascading failure) warrants stateful
  circuit-breaker semantics — exists as a real downstream API call,
  ORCH-CIRCUIT-OPEN becomes adjudicable against the §4 taxonomy
  again. The OBS-DDL writer (local Snowflake write — a different
  failure profile, fail-open's job per Spec A) is *not* counted
  toward this re-entry trigger: a local write failure is what the
  broad-except handler converts to UNKNOWN today, and stateful CB
  semantics may not be warranted for it at all. At Phase-2 re-
  adjudication, ORCH-CIRCUIT-OPEN may re-enter as class-1 (real
  remote-API surface exists; build the breaker) or stay class-3
  (some narrower reason still phase-impossible). The row text and
  §3 row are preserved as audit trail with a "reclassified per §7
  entry 4" pointer, mirroring the BACKTEST-CORPUS preservation
  pattern.

- **ORCH-FAIL-OPEN (new, the stateless fail-open property, Spec A)
  → class-1 incomplete-work, weight 1 medium, blocks exit.**
  Acceptance: handler shipped + 4 tests passing — specifically
  (a) `triage_failure` wraps `redact_early_failure` in a broad
  `except Exception` handler that catches `Exception` (not
  `BaseException`, so `KeyboardInterrupt` / `SystemExit`
  propagate); emits `Outcome.UNKNOWN_HANDED_TO_HUMAN` with
  rationale prefix `redactor_fail_open:` carrying `exc_type` only
  — never `str(exc)` — for rate-spike-per-exc_type observability
  without credential leak risk; routes only `exc_type` to
  application logs via `logger.error` (NOT `logger.exception` —
  see *Credential-safety design* below); AND (b) four tests in
  `tests/test_triage_orchestrator.py` lock the contract (generic-
  exception fail-open, KeyboardInterrupt propagation, sentinel-
  still-wins, structural `model_dump()` walk no-credential-
  substring).

- **ARTIFACT-MODE: untouched.** Stays at class-2 carry-forward
  per entry 3.

**§4 progress-table arithmetic — two independent honest moves,
sequenced in this commit; standalones reconcile to the pre-commit
denominator.** Pre-commit state: 15/17 = 88.2%. The two moves are
independent in justification but **sequenced in the actual commit**:
the denominator path is 17 → 16 (Move 1 removes CIRCUIT-OPEN) → 17
(Move 2 adds ORCH-FAIL-OPEN). The standalone counterfactuals below
each operate on the **pre-commit denominator of 17 independently** —
they describe "what if only this move shipped, alone, without the
other?" — which is why the standalone Move-2 reads 15/18 (adding
ORCH-FAIL-OPEN to the pre-commit 17 without removing CIRCUIT-OPEN),
not 15/17 (which is the *sequenced* Move-2 result, after Move 1
already shrank the denominator to 16). Stating both denominators
explicitly so the actual-sequence numbers (used in the §4 table)
and the standalone-counterfactual numbers (used in the
falsifiability check) reconcile cleanly:

1. **Move 1 (CIRCUIT-OPEN out — Spec B/C reclassified class-3):**
   - *In sequence*: denominator 17 → 16. Score becomes **15/16 = 93.75%**.
   - *Standalone counterfactual* (on pre-commit denominator 17):
     denominator 17 → 16 (same — Move 1 doesn't depend on Move 2
     having happened). Standalone result identical to sequenced:
     15/16 = 93.75%.
   - Justification: phase-impossible per §4 separating test,
     source-verified. Same justification holds whether the move
     raises or lowers the score.

2. **Move 2 (ORCH-FAIL-OPEN in — Spec A class-1 added):**
   - *In sequence*: denominator 16 → 17. Score becomes **15/17 = 88.2%**.
   - *Standalone counterfactual* (on pre-commit denominator 17,
     without Move 1): denominator 17 → 18. Standalone result:
     **15/18 = 83.3%**. The standalone differs from sequenced
     because Move 1 has not shrunk the denominator first.
   - Justification: exception-surface audit found a real §1.8
     violation that is *newly named, not pre-existing-and-credited*.
     The audit-surfaced work is class-1 incomplete-work; it enters
     the denominator as NOT STARTED.

The score returning to 88.2% in the *sequenced* commit is
coincidental, not contrived: each move stands on its own evidence
and each standalone counterfactual produces a different number
(93.75% and 83.3%) than the sequenced result (88.2%). The §4
progress table records the sequenced denominator path (17 → 16 →
17) since that's the actual end state of this commit; the
standalone counterfactuals above exist only for the falsifiability
check (would each move survive on its own evidence? yes,
independently). **The §4 table number and the standalone-Move-2
number are not in contradiction — they are different denominators
by construction, and this paragraph names which is which.**

**Why this is not net-zero arithmetic theater.** The §2 anti-gaming
discipline forbids denominator manipulation that produces a
target score; the two moves produce a coincident pre-commit value,
which is a different shape. The discipline's bite is on a *single*
move whose justification is the score it produces. Here, each
move's justification (phase-impossibility for Move 1; audit-
surfaced real work for Move 2) is independent of the other, and
the standalone counterfactuals above demonstrate this concretely:
if only Move 1 shipped, the commit would close at 15/16 = 93.75%
honestly; if only Move 2 shipped, the commit would close at
15/18 = 83.3% honestly. The coincidence at 17 in the sequenced
commit reflects two facts about the codebase that happened to
surface in the same audit session, not a manipulation toward a
target.

**Note on exposition volume (banked for next entry).** This
reconciliation runs ~40 LOC for a denominator that goes 17→16→17.
It's *correct* — and correctness on the arithmetic axis earned
thorough treatment after Finding 1's verified contradiction risk
— but the *honest version* of this is four lines: "the commit
sequences two moves (17→16→17); each is independently justified
(Move 1 phase-impossible; Move 2 audit-surfaced); standalone
they'd close at 93.75% and 83.3%, so the 88.2% isn't contrived."
Future arithmetic reconciliations should be the four-line
version, not the proof. The expansion stays in this entry because
retrofitting it now would risk re-introducing the contradiction
the expansion just closed; the bookkeeping-axis efficiency lesson
is banked here for next time.

**Credential-safety design — consistent trust-boundary posture
across rationale AND log paths.** The broad-except handler's
rationale carries `exc_type` only (always-safe Python identifier),
never `str(exc)`. Reason: on the broad-except path the exception
message is **un-sentinel-checked content by construction** — the
redactor's credential guarantees do not hold for exceptions
raised before or around the sentinel pass, so `str(exc)` may
carry raw input fragments that would land in
`TRIAGE_INVOCATIONS.rationale`. A char cap is not a credential
mitigation (a 200-char credential is still a leaked credential).
The application-log path applies the **same posture for the same
reason**: `logger.error` (NOT `logger.exception`), because
`logger.exception` would emit the traceback, and the traceback
includes `str(exc)` — which would relocate the leak from one
trust boundary to another. Production payloads are credential-
bearing by assumption (the sentinel's premise); that posture is
applied **consistently** to both the agent's output store and
the application log, not asymmetrically. Debug detail (full
traceback + message) for diagnosing redactor bugs is deferred to
a separately-secured channel; that channel is not built in
Phase-1. The decision is recorded inline as a load-bearing
comment at the handler site to prevent regression by future
"improve debuggability" edits, and the deferred test that would
lock the logger choice in tests (caplog assertion that
`record.exc_info is None`) is banked as `sprint-1-deferred.md`
item #23 with the trigger event named (Phase-2 error-store
channel design firms up).

**Why this lands as two commits, not one.** Commit N (this docs
commit) ships the row split and §4 arithmetic — a docs-only edit,
entry-7 hook fires exit-0 (no `src/triage/**` or `fixtures/**`
files staged). Commit N+1 (the FAIL-OPEN code commit) ships the
broad-except handler + 4 tests + the §3 ORCH-FAIL-OPEN row flip
NOT STARTED → DONE + the §4 progress-table tick to 16/17. **The
two-commit split protects the audit trail**: row-split rationale
and code implementation are different decisions with different
review needs (docs DA vs full-gate code DA + DV Validator stress-
test against the live tests). Folding them into one commit would
risk the row-split being lost in code-review focus, or the code
being approved on docs-DA grounds. The order is strict: docs
first, code second.

**Entry-7 same-commit discipline on Commit N+1.** The code commit
will touch `scripts/automation/src/triage/**`, which fires the
entry-7 pre-commit hook. The hook validates that touching
watched code paths requires a corresponding checklist row update
in the same commit. Commit N+1 will stage the handler + tests +
ORCH-FAIL-OPEN row flip + §4 progress-table update **together**.
This is a clean entry-7 own-dogfood instance; the hook's exit-0
on a code+row+table commit is the entry-7 contract being met by
the agent itself.

**Closeout — two methodology observations banked separately, NOT
in this commit's body.**

1. *Spec-vs-spec drift within one deliverable's own definition.*
   The CIRCUIT-OPEN row's existence-check did not just answer
   "is the breaker built?" — it surfaced that the row's own
   *definition* drifted across three artifacts (v2-plan §1.8 =
   Spec A stateless property; sprint-1-deferred #17 + checklist
   L135 = Spec B/C stateful breaker; "CIRCUIT-OPEN" name conflates
   both). This is the same documented-vs-actual drift class
   that's recurred all sprint, but on a new artifact axis (intra-
   deliverable rather than doc-vs-code).

2. *Prefer structural anchors over line numbers in durable docs.*
   Three line-citation drifts in three commits (c95c770b off-by-4
   on the redact import; entry-3 self-DA caught it; entry-4 draft
   off-by-18 on the try/except block, entry-4 verification pass
   caught it). A positional reference drifts against a moving
   file; a structural reference doesn't. The durable fix isn't
   "verify line numbers harder each time" — it's "stop citing
   line numbers where a structural anchor works." Same drift
   class as #1, applied to citations.

Both observations worth banking as methodology entries in
`docs/triage-agent/lessons-learned.md`; banked as follow-up
entries, NOT folded into this commit's body, to keep the row-
split adjudication record focused and reviewable.

**Pre-push DA discipline (entry 8 applied).** This entry's draft
was reviewed by user-DA before any file edit landed (per the
entry-8 lesson banked in `c95c770b` and ratified by entry 3's
clean β-chain break). User-DA findings on the broad-except
design incorporated upstream into the code-commit drafts
(logger choice corrected from `logger.exception` to `logger.error`
for trust-boundary consistency; Test 4 upgraded from single-field
`evidence_json` assertion to structural `model_dump()` walk
across all current and future fields; deferred Test 5 banked as
sprint-1-deferred #23, not left in prose). User-DA findings on
this docs entry incorporated into the revision that landed:
Finding 1 (arithmetic reconciliation with sequencing sentence +
standalone-vs-sequenced explicit walk); Finding 2 (gap-table
citations re-grep-verified on HEAD, two real drifts caught and
corrected — `failure_triage_agent.py:L221-247` → `L239-250` off
by 18, `redact.py:402` → `L402-405` span-corrected, `fbin_error_catalog.py:116`
verified clean); Finding 3 (CIRCUIT-OPEN Phase-2 re-entry trigger
tightened to remote dependencies only, OBS-DDL excluded on
architectural grounds — local-write failure profile may not
warrant stateful CB at all); Finding 4 ("double-conditioned
gate" term-of-art reserved exclusively for §4 class-2 ARTIFACT-
MODE sense; FAIL-OPEN acceptance phrased as "handler + 4 tests"
without the colliding term). Post-revision hostile re-read on
the assembled file run before commit per quality-gates.md
self-Copilot pass discipline. **Falsifiability bar for entry 8
(next 3 docs-only >200 LOC commits clean on first post-push
read): 1 of 3 with entry 3 — if this commit ships clean, 2 of 3.**

**Score impact.** 15/17 = 88.2% → **15/17 = 88.2%** (Move 1:
15/16 = 93.75% standalone-and-sequenced; Move 2 sequenced:
15/17 = 88.2%; Move 2 standalone: 15/18 = 83.3%; presented as
two independent moves, not net-zero). The Phase-1 exit threshold
(100% of incomplete-work weight shipped per §4 *Exit definition*)
requires ORCH-FAIL-OPEN to ship before exit; the score returning
to 88.2% reflects the honest accounting that **the audit surfaced
one new piece of real Phase-1 work** that must close before exit.
**Distance to exit: +1 weight** (ORCH-FAIL-OPEN class-1 must
ship; ARTIFACT-MODE class-2 carry-forward does NOT block per §4
rule). After Commit N+1: 16/17 = 94.1%, ARTIFACT-MODE is the
sole class-2 carry-forward, **Phase-1 exits.**

**Cascade-flag consequence.** ARTIFACT-MODE resolved class-2
(entry 3). CIRCUIT-OPEN resolved as row-split (this entry): Spec
B/C → class-3, Spec A → new ORCH-FAIL-OPEN class-1. **Cascade
flag fully resolved.** No outstanding Phase-1-exit decisions
remain after Commit N+1 lands.

**Commit chain of custody.** Single docs-only commit:

- §3 L135 ORCH-CIRCUIT-OPEN row: reclassified to class-3, moved
  to *Items NOT scored* with Phase-2 re-entry trigger (remote
  downstream API calls must exist; OBS-DDL local-write excluded
  on architectural grounds), original row text preserved as
  audit trail with reclassification pointer.
- §3: new ORCH-FAIL-OPEN row added under *Medium-criticality
  items (weight 1)* — class-1 NOT STARTED, acceptance is
  handler + 4 tests.
- §4 *Current progress against this baseline* table: Move 1 +
  Move 2 walked explicitly as two independent honest moves with
  sequenced-vs-standalone reconciliation; coincidental pre-
  commit value flagged non-contrived.
- §4 *Distance to exit*: recomputed +1 weight (ORCH-FAIL-OPEN
  sole class-1 blocker; ARTIFACT-MODE class-2 carry-forward
  doesn't block).
- §4 cascade-flag bullet: updated to *"fully resolved"* —
  ARTIFACT-MODE class-2 (entry 3), CIRCUIT-OPEN row-split (this
  entry), no outstanding Phase-1-exit decisions remain.
- §4 *Exit definition* class-1 example updated to ORCH-FAIL-OPEN;
  class-3 examples appended with ORCH-CIRCUIT-OPEN.
- §4 *Today's reading* paragraph rewritten to reflect row-split
  resolution + ORCH-FAIL-OPEN sole class-1 blocker.
- §7 entry 2026-06-09 entry 4 (this entry): full row-split
  adjudication record + spec-A/B/C drift identification +
  credential-safety design rationale + two-commit split
  rationale + two methodology observations banked for separate
  follow-up entries.

`sprint-1-deferred.md` updates ship as part of this commit
(consistent with entry 3's same-commit discipline):
- Item #17 (ORCH re-audit) gets a *Spec-split update 2026-06-09
  entry 4* note pointing at this entry's row-split; the item
  itself stays CLOSED.
- New item #23 added: deferred Test 5 (caplog assertion
  `record.exc_info is None`) with trigger event named (Phase-2
  error-store channel design firms up).

No code in this commit. Tests: baseline preserved (1185 passed /
2 skipped — docs-only, no Python touchpoints). Commit N+1 lands
the FAIL-OPEN handler + 4 tests + checklist row flip in a single
code commit with full-gate review and entry-8 pre-push DA.

### 2026-06-09 entry 5 — ORCH-FAIL-OPEN shipped (Commit N+1) — Phase-1 exits

Shipped per the entry-4 adjudication: §1.8 stateless fail-open
handler in `failure_triage_agent.py::triage_failure`, plus 4 tests
in `tests/test_triage_orchestrator.py::TestRedactorFailOpen`.

**Score:** 15/17 = 88.2% → **16/17 = 94.1%**. **Phase-1 exits.**
ARTIFACT-MODE remains the sole class-2 carry-forward (does not
block per §4 rule). No outstanding Phase-1-exit decisions remain.

**Code (single insertion in `triage_failure`, after the existing
`except CredentialSentinelFired` clause):**

- `except Exception as exc` — catches `Exception`, NOT `BaseException`
  (KeyboardInterrupt / SystemExit propagate).
- Sentinel handler runs first by code order → sentinel never reaches
  this branch.
- Rationale carries `exc_type` ONLY (`f"redactor_fail_open: exc_type={exc_type}"`),
  never `str(exc)`.
- Application log via `logger.error("redactor_fail_open exc_type=%s", exc_type)`,
  NOT `logger.exception` — the traceback would carry `str(exc)` and
  relocate the leak from one trust boundary to another.
- Module-level `import logging` + `logger = logging.getLogger(__name__)`
  added.
- Load-bearing inline comment at the handler site documenting the
  credential-safety rationale (do-not-flip-error-to-exception).

**Tests (`TestRedactorFailOpen`, 4 tests):**

| # | Test | What it locks |
|---|---|---|
| 1 | `test_generic_exception_emits_fail_open` | RuntimeError → UNKNOWN_HANDED_TO_HUMAN; rationale prefix + `exc_type=RuntimeError`; exc message MUST NOT appear in rationale (substring asserts). |
| 2 | `test_keyboard_interrupt_propagates` | `pytest.raises(KeyboardInterrupt)` — the `Exception` vs `BaseException` distinction. |
| 3 | `test_credential_sentinel_still_wins` | Monkeypatch raises real `CredentialSentinelFired` → outcome=CREDENTIAL_SENTINEL_FIRED; `redactor_fail_open` MUST NOT appear in rationale (handler-precedence guarantee). |
| 4 | `test_no_credential_substring_in_any_field` | Recursive `model_dump()` walk over the RCARecord; canary substring + JWT-prefix banned from every str field; future-field-safe. |

**Mutation table (each row = a real test outcome).**

| Mutation | Test that catches it |
|---|---|
| Catch `BaseException` instead of `Exception` | Test 2 (KeyboardInterrupt would be swallowed and converted to UNKNOWN; `pytest.raises` would fail). |
| Reorder — broad `except Exception` before sentinel handler | Test 3 (sentinel outcome would lose to fail-open outcome). |
| Swap rationale to include `str(exc)` (e.g., `f"redactor_fail_open: {exc!r}"`) | Tests 1 + 4 (Test 1 substring asserts; Test 4 model_dump walk catches canary leak). |
| Remove `except` clause entirely | Tests 1 + 3 + 4 (each calls `triage_failure` after monkeypatching the redactor to raise; uncaught exception would propagate as test ERROR). |
| Flip `logger.error` → `logger.exception` | **Not currently caught by tests** — the load-bearing comment at the handler site is the transitional enforcement; sprint-1-deferred #23 (deferred Test 5 — caplog `record.exc_info is None`) locks this once Phase-2 error-store channel design firms up and the logger choice acquires real architectural weight. |

**§3 row flip:** ORCH-FAIL-OPEN status NOT STARTED → DONE with
full acceptance summary recorded in the row.

**Cascade flag:** **fully resolved** (entry 4) — confirmed by
landing here. ARTIFACT-MODE class-2 carry-forward is the only
open item, and it does not block per §4.

**Tests:** 1185 → **1189 passed / 2 skipped** (4 new in
TestRedactorFailOpen; baseline held on the other 1185).

**Entry-7 hook:** fired green — watched-path edits
(`scripts/automation/src/triage/**` + checklist row update +
§4 progress-table tick) staged in this single commit. Clean
own-dogfood instance.

**Entry-8 falsifiability bar:** if Commit N+1 ships clean on first
post-push read (with the docs-only entry 4 having shipped clean
as the second instance), the bar's *next 3 docs-only >200 LOC
commits* counter holds at 2/3 — the third instance (a future
docs-only entry) remains pending. Code commits are not in the
falsifiability set.

**Sprint-1 closeout note.** With Phase-1 exiting, the agent now
has the four safety properties named in the v2-plan: redactor +
sentinel; stateless fail-open boundary (this commit); held-out
accuracy gate (deferred-but-specified as BACKTEST-CORPUS class-3);
advisory-until-proven discipline (lesson 4 spike-or-iterate +
the §4 *Exit definition* taxonomy). Process scaffolding (the
§7 entry chain, the §2 anti-gaming discipline, the entry-7
hook + entry-8 pre-push DA) carried the heavy lift through
Sprint 1 and can run lighter in Phase-2 — the safety surfaces
are hardened where rigor is justified, the bookkeeping axis
banked its lessons (entry-4 "40-LOC arithmetic for a 17→16→17
denominator" — the four-line version is the right level next
time), and Phase-2 inherits a stable boundary contract.
