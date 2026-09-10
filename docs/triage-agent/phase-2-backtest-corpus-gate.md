# Phase-2 BACKTEST-CORPUS acceptance gate

**Created:** 2026-06-09 (Phase-1 exit checklist §7 entry 2026-06-09 entry 2)
**Status:** **Acceptance gate spec — applies to Phase-2 BACKTEST-CORPUS work**
**NOT a Phase-1 exit bar.** Per the BACKTEST-CORPUS reclassification (see
checklist §7 entry 2026-06-09 entry 2), the ≥20-held-out-corpus criterion
is Phase-2 work. This document is the *acceptance gate* the Phase-2 work
must clear, drafted now while the substrate (label spec v1.0.0, pattern
catalog v1.2.0, harness, 7-payload baseline) is fresh in hand.

> **v1.1.0 fixture-repoint note (2026-06-11).** The label-spec schema was
> bumped from v1.0.0 → v1.1.0 as a transport-only change: payload_source
> flipped from `scratch` to `fixture` on all 7 P0.1 entries, with
> payload_path repointed to committed `docs/triage-agent/fixtures/*.json`
> equivalents. The gate clauses below operate on label-entry *content*
> (provenance citations, derivation text, acquisition timestamps), not on
> payload_source / payload_path mechanics, so this gate's semantics carry
> over verbatim. Clause (b) operational test (2) is restated explicitly
> at its definition site below.

## Why this exists now (not at Phase-2 open)

Two reasons:

1. **Substrate is loaded.** Defining the gate while the label spec,
   harness, baseline, and acquisition-channel analysis are immediate
   context is materially cheaper than reconstructing them at Phase-2
   open.
2. **Defining the bar after data is the failure mode.** The original
   §1.3 quality bar lacked a precision/recall PASS threshold — the
   harness reports numbers but no green/red bar existed. If the
   threshold is set *after* corpus accretion, the team will argue
   about the bar with the data already in hand (the audit-trail-
   sanity-check failure mode — deriving the pass condition after
   seeing the data, lessons-learned entry 6). Pinning the threshold
   now means the Phase-2 channel has a target to accrete *toward*,
   not a target derived from what was easy to accrete.

This gate is the relocated form of the §1.3 quality bar (see
checklist §7 entry 2026-06-09 entry 2, "Phase-2-precondition
relocation"). Before the agent's outputs are trusted in any
non-advisory capacity, this gate MUST be met.

## Scope

This gate governs the BACKTEST-CORPUS Phase-2 work item only. It does
NOT govern:

- The harness itself (BACKTEST-HARNESS, scored DONE Phase-1 at §7
  entry 2026-06-07).
- The Phase-1 7-payload in-sample baseline (separate baseline file;
  remains in-sample, explicitly captioned).
- Phase-2 webhook activation (which may proceed BEFORE this gate is
  met, because webhook activation is what produces corpus accretion
  — but the agent's outputs during the accretion window are
  advisory-only).

## Acceptance clauses

All five clauses MUST be met for the gate to be cleared. A "GATE MET"
declaration is itself a versioned artifact (date + commit + assessor)
that lands in the same commit as the corpus extension that crossed
the threshold.

---

### Clause (a) — Corpus size floor

**Requirement:** The held-out corpus MUST contain **≥20 labeled
held-out payloads**.

**Reconciliation:** §1.3 of `phase-1-exit-checklist.md` previously
read "20–30 labeled failures." The "30" was aspirational and was
silently dropped between §1.3 and §3 (audit-trail drift, per
checklist §7 entry 2026-06-09 entry 2 finding 4). **Reconciled here
to ≥20, more is better, no upper cap.** The "30" was never a binding
upper requirement; it was an aspirational ceiling. Floor is the bar.

**Non-counting items:** Synthetic payloads (clause-(c) coverage-
scaffolding role) do NOT count toward the ≥20 floor. In-sample
payloads (the existing 7) do NOT count toward the ≥20 floor (see
clause (b)).

---

### Clause (b) — In-sample / held-out ratio (load-bearing)

**Requirement:** The ≥20 payloads of clause (a) MUST be **≥20
*held-out*, full stop** — payloads that were NOT used to inform
catalog pattern design. The existing 7 P0.1 in-sample payloads
remain a *separately reported baseline* and are NOT subtracted from
the ≥20 floor.

**Why this is load-bearing:** Reading "≥20" as "7 in-sample + 13
held-out" silently contaminates the measurement with the 7 payloads
the patterns were designed against. The in-sample-fit caveat
already documented in `p01_labels.yml v1.0.0` header and
`backtest-baseline-2026-06-07.md` would re-enter through the back
door of corpus arithmetic. The whole point of "held-out" is that
the held-out set is *not the design substrate*.

**Operational test:** A payload is held-out if and only if:
1. It is not listed in any pattern's `provenance.citation` in
   `fbin_error_catalog.yml`.
2. It was acquired AFTER the pattern that classifies it was shipped
   (commit-date ordering on the acquisition vs. the pattern's
   landing commit).
3. The label entry's `provenance.derivation` field does not contain
   the word "informed" or otherwise indicate the payload guided
   catalog design.

> **v1.1.0 fixture-repoint note (2026-06-11).** All three operational
> tests are content-based (catalog citation, acquisition timestamp,
> derivation text). NONE consult `payload_source` or `payload_path`.
> Test (2) anchors on *acquisition* time, not on where the bytes are
> physically read from at backtest time — so a label whose
> payload_source flipped from `scratch` to `fixture` does not change
> its in-sample / held-out classification. The 7 P0.1 entries
> remained in-sample after the v1.1.0 repoint.

Any payload failing any of (1)-(3) is in-sample and counts toward
the separate baseline, not the ≥20 floor.

**Synthetic-payload exclusion (spans clauses b/c/e):** Synthetic
payloads (clause (c) coverage-scaffolding role) are NOT "held-out"
in the production sense — they are manufactured, not acquired.
They do NOT count toward the clause-(a) floor (already stated in
clause (a)) and they are NOT scored in the clause-(e) production
precision/recall computation. Their correctness is verified by the
separate coverage-correctness assertion specified in clause (c).
This separation is intentional: production metrics on production
data, coverage assertions on manufactured data; never mixed.

---

### Clause (c) — Pattern coverage breadth

**Requirement:** The held-out corpus MUST exercise:

- **≥1 payload labeled to each Phase-1 catalogued pattern** that is
  in the live catalog at gate-assessment time (today: `fk_orphan_v1`,
  `pr_isolated_schema_missing_upstream_v1`,
  `manifest_parse_failure_invalid_model_language_v1`; ≥3 patterns).
- **≥1 payload labeled `expected_pattern_id: null` /
  `expected_outcome: unknown_handed_to_human`** (a true zero-match
  case — the orchestrator's UNKNOWN branch).
- **≥1 payload that triggers `Outcome.CREDENTIAL_SENTINEL_FIRED`**
  (the sentinel-fire branch — note this branch is currently
  unexercised in the P0.1 corpus; reaching it in held-out is
  genuinely new coverage, not a restatement).

**Why:** Precision/recall computed over a corpus that never tests
whole branches of the agent is precision/recall on a subset of the
agent. The CREDENTIAL_SENTINEL_FIRED branch is the most likely
clause to require Strategy-C (synthetic) supplementation —
production may rarely produce a credential-bearing payload that
also survives sanitization-for-fixture-commit. A synthetic
sentinel-fire fixture is honest *if and only if* labeled
`derivation: synthetic` in provenance.

**Coverage-correctness assertion (resolves the
clause-(b)/(c)/(e) sentinel collision):** When the sentinel-fire
case is satisfied by a synthetic payload (the expected path —
see clause (b) "Synthetic-payload exclusion"), that payload is
verified by a **separate pass/fail coverage-correctness assertion**,
not by clause (e)'s precision/recall computation. The assertion is
binary: the agent MUST emit `Outcome.CREDENTIAL_SENTINEL_FIRED` on
the synthetic case. PASS = the sentinel branch is verified working.
FAIL = the sentinel branch is broken (stop-the-line, same class as
clause-(e) zero-tolerance verdicts). This keeps production
precision/recall clean (clause (e) scores production data only)
while ensuring the sentinel branch's correctness is actually
tested, not merely *covered-by-presence*. If a held-out *production*
sentinel-fire payload becomes available (rare but possible), it
counts toward clause (a) AND enters clause (e); the synthetic
assertion remains as additional regression coverage.

**Out of scope for this clause:** Multi-pattern co-fire cases are
Phase-1 explicitly out-of-scope (see `failure_triage_agent.py`
L274-282 placeholder; checklist §3 "Items NOT scored"
ORCH-MULTI-PATTERN). If multi-pattern co-fire becomes Phase-2
in-scope, this clause grows.

---

### Clause (d) — Label provenance shape

**Requirement:** Every held-out label entry MUST carry
`p01_labels.yml v1.0.0 / v1.1.0` provenance shape **verbatim** (the
v1.0.0→v1.1.0 bump did not change the provenance block; only
payload_source / payload_path values flipped):

```yaml
provenance:
  cluster_source: "<verifiable acquisition citation>"
  pattern_source: "<verifiable catalog/derivation citation>"
  derivation: "<one-sentence rationale distinguishing
                empirically-cited vs category-confirmed vs
                synthetic-coverage>"
```

No downgraded form is admissible. The discipline named in the
existing label spec header — *"best-guess labels lacking provenance
are inadmissible for backtest scoring without a recorded
rationale"* — applies verbatim to all held-out entries.

**Why:** The whole epistemic point of "held-out" is that
provenance proves it's held-out. A label entry that cannot cite
its acquisition channel + pattern derivation cannot be verified as
held-out by a reviewer. Provenance is the audit trail.

**New `derivation` values introduced by this gate:**

- `webhook_capture` — payload arrived via the Phase-2 webhook
  channel, with timestamp/HMAC-signature audit trail intact.
- `manual_pull_post_pattern_ship` — PAT-driven scratch pull
  acquired AFTER the matching pattern's landing commit (clause-(b)
  operational test (2) holds by construction).
- `synthetic` — handcrafted for coverage of a branch (clause-(c)
  use only); MUST cite which clause-(c) branch and which author
  designed it. NEVER counts toward clause (a).

---

### Clause (e) — Precision / recall PASS threshold (pinned)

**Requirement:** Computed over the held-out corpus (clause (a) +
(b)) ONLY (in-sample baseline reported separately, never
arithmetically combined with held-out; synthetic coverage payloads
excluded per clauses (b) and (c)), per-pattern AND aggregate:

| Metric | Threshold | Rationale |
|---|---|---|
| **Per-pattern precision** | **≥ 0.90** *(subject to minimum-n caveat below)* | A false-positive is a wrong classification trusted by an ops human; the Iron Rule mitigates dangerous *autonomous action* but does not protect against wrong *triage routing*. ≤1 FP per 10 classifications is the conservative floor. |
| **Per-pattern recall** | **≥ 0.70** *(subject to minimum-n caveat below)* | The agent is a co-pilot whose value depends on **sustained human trust**. Past a recall floor, ops humans learn the agent is unreliable and stop trusting its classifications *entirely* — including the ones it gets right. At that point the agent provides **negative** net value: humans do the work AND evaluate the agent's output. 0.70 is the floor below which trust collapses and the co-pilot becomes net-negative. (The mere routing-recovery cost of a single FN — "human looks at it" — would justify a much lower number; that's not the operative constraint. Trust erosion is.) |
| **Aggregate precision** | **≥ 0.90** | Same as per-pattern; aggregate guards against a corpus skewed toward one pattern hiding poor precision on another. Aggregate is computed across all held-out cases regardless of per-pattern n. |
| **`wrong_pattern` verdict count** | **= 0** | Cross-pattern confusion (CLASSIFIED-but-as-the-wrong-pattern) is structurally worse than `false_positive` — the agent confidently misroutes to a wrong handler. Zero tolerance. |
| **`sentinel_fired_unexpected` verdict count** | **= 0** | A surprise sentinel fire on a payload not labeled for it indicates either a redaction-side regression or a label-side gap. Either is investigation-blocking. Zero tolerance. |
| **`error_during_triage` verdict count** | **= 0** | The orchestrator raising on a held-out payload is a code defect; the agent must fail-open per §1.8, not raise. Zero tolerance. |
| **`skipped_payload_missing` verdict count** | **= 0** | Held-out payloads being missing from the corpus indicates an acquisition-channel break; a missing payload cannot be scored. Zero tolerance during gate assessment (transient absence outside gate assessment is expected per harness clean-clone CI design). |

**Why these numbers (Iron-Rule-conservative justification):**

- The agent emits triage suggestions. The Iron Rule (`rca_schema.py`
  invariants + `requires_human_review` semantics) forces human
  approval on dangerous actions (modify_test, modify_model, deploy
  changes). The agent is a **co-pilot for routing**, not an
  autonomous actor.
- Therefore: precision matters MORE than recall (a wrong
  classification trusted by an ops human is the harm; a missed
  classification adds review work AND erodes trust).
- 0.90 precision floor is conservative without being unattainable;
  the Phase-1 in-sample baseline scores 1.000/1.000 by
  construction, so anything below 0.90 on held-out indicates
  substantial generalization failure, not "small noise."
- 0.70 recall is the trust-erosion floor, not the routing-cost
  floor. Below 0.70 the agent's correct outputs stop being
  trusted-without-recheck and the co-pilot becomes net-negative.
- Zero-tolerance verdicts (`wrong_pattern`,
  `sentinel_fired_unexpected`, `error_during_triage`,
  `skipped_payload_missing`-during-assessment) are class-of-defect
  bars, not rate bars — any occurrence is a stop-the-line signal,
  not a rate-tracked metric.

**Minimum-n caveat for per-pattern rates (closes the small-sample
hole):** Per-pattern precision and per-pattern recall are
**measurable only when a pattern has ≥10 held-out payloads.** Below
that floor, the per-pattern rate is either 1.0 or 0.0 (or a few
discrete values) and carries no signal — a "≥0.90" bar on n=2 is
either trivially met or trivially failed and tests nothing. Pinned
**N=10 minimum per pattern for per-pattern rate assessment**, with
this disposition for thinly-represented patterns:

- **Patterns with held-out n ≥ 10:** assessed against the per-
  pattern precision (≥0.90) and per-pattern recall (≥0.70) bars
  above. Standard case.
- **Patterns with held-out n < 10:** per-pattern rates are NOT
  computed (recording "n/a, insufficient sample" in the gate
  assessment record). These patterns contribute to (1) the
  **aggregate** precision/recall bars (which apply unconditionally)
  and (2) a **coverage-presence requirement** — at least one
  held-out payload labeled to each Phase-1 catalogued pattern, per
  clause (c). The thinly-represented pattern is not waived; it is
  held to a smaller bar (coverage exists + aggregate passes)
  pending corpus growth that crosses n=10 for that pattern.
- **Why N=10:** at n=10, ≥0.90 precision means at most 1 FP
  (meaningful); ≥0.70 recall means at most 3 FN out of 10 actuals
  (meaningful). Below n=10 these statements degenerate into
  threshold-coincidence rather than measurement.
- **Why pinned now, not deferred:** without this caveat, a Phase-2
  assessor staring at a pattern with held-out n=2 hits the same
  spec-self-contradiction class as the sentinel collision —
  apply-literally-and-it-breaks. Pinning N=10 now closes the
  silent-waiver path (the audit-trail failure mode of "we'll
  decide at assessment time" — which is data-driven goalpost-
  moving with the data already in hand).

**These numbers are revisable BEFORE corpus accretion begins, but
NOT after.** Revising thresholds after seeing held-out data is the
audit-trail-sanity-check failure (lessons-learned entry 6).
Revisions require a session-open note in the §7 log of the Phase-2
exit checklist (analog to this checklist's §7). The
falsifiability-test-for-the-gate-spec-itself section below applies
to all clause-(e) numbers including N=10.

---

## Gate assessment procedure

When the held-out corpus appears to clear all five clauses:

1. Compute clause (a) count: held-out label entries (clause-(b) operational test applied).
2. Verify clause (b) operationally for each held-out entry (the three sub-tests).
3. Verify clause (c) coverage: each Phase-1 catalogued pattern has ≥1 held-out entry; ≥1 zero-match held-out entry exists; ≥1 sentinel-fire entry exists (synthetic allowed for this last per clause-(c) caveat).
4. Verify clause (d): all held-out entries pass the provenance-shape check + the `derivation` value is in the admissible set.
5. Run the harness; compute per-pattern + aggregate precision/recall and verdict-count tallies over held-out cases ONLY. Verify clause (e) thresholds.
6. Land a "GATE MET" record in this file's appendix (date + commit + assessor + the 7 numbers from clause (e)) in the SAME commit as the held-out corpus extension that crossed the threshold.

A failure on any clause is recorded as "GATE NOT MET" with the specific clause + gap, and Phase-2 BACKTEST-CORPUS remains open until remediated. No partial-credit.

---

## Falsifiability test for this gate spec itself

This spec is admissible only if the team would adopt the same five clauses if the existing 7-payload baseline scored *worse* than it does. The spec is justified by the consumer analysis (held-out accuracy is the precondition for trusting agent outputs in non-advisory capacity), NOT by the in-sample baseline arithmetic. If a future session proposes weakening any clause, the proposer MUST first answer: "would I propose this weakening if the current baseline scored 50% / 50% instead of 100% / 100%?" If no, the weakening proposal is rejected as data-driven goalpost-moving.

---

## Cross-references

- Reclassification rationale: `phase-1-exit-checklist.md` §7 entry 2026-06-09 entry 2.
- Phase-2 work brief (first item = deterministic minimizer): `sprint-1-deferred.md` #22.
- Existing label-spec discipline this gate inherits: `docs/triage-agent/fixtures/p01_labels.yml` v1.0.0 header.
- In-sample baseline (Phase-1, separately reported): `docs/triage-agent/backtest-baseline-2026-06-07.md`.
- Redaction contract the corpus depends on: `scripts/automation/src/triage/redact.py` v1.0.0.
- Catalog the corpus tests against: `scripts/automation/configs/fbin_error_catalog.yml` v1.2.0 (at gate-spec authoring).
