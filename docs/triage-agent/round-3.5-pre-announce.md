# Gate-D Round 3.5 — Pre-announce (REVISION 2)

**Branch:** `feature/dv-failure-triage-agent`
**HEAD at authoring:** `a02e44c3`
**Author:** Claude Opus 4.7
**Adjudicator:** Kumar
**Cross-review:** Copilot/Gemini (asymmetric — Rev 1 cross-reviewed; Rev 2 awaiting re-review)
**Status:** PRE-ANNOUNCE — no code touches, no candidates locked yet

This document supersedes Round 3 (Rev 1–5; final at SHA `0dbe5e72`)
for purposes of `truncate_logs` algorithm replacement. Round 3 is
preserved in git as historical record of the iteration that drove
the escalation. The Round-3.5 framing inherits Round 3's hard
constraints, shape battery, DA surface, categorical-coverage
families, and sign-off ladder structure; it locks four S1–S4
simplifications surfaced in the Rev 5→6 meta-adjudication and
recorded in [lessons-learned.md 2026-06-05 entry 2](./lessons-learned.md).

## Revision history

| Rev | SHA | Date | Adjudicator | Summary |
|---|---|---|---|---|
| 1 | `a02e44c3` | 2026-06-05 | Kumar | Initial Round-3.5 pre-announce. Inherits structure from Round 3 Rev 5 (SHA `0dbe5e72`). Locks S1–S4 from [lessons-learned.md 2026-06-05 entry 2](./lessons-learned.md): S1 explicit per-family criterion-4 aggregation; S2 parameter-extension viability path deleted; S3 step-1.5 collapsed to binary operability verdicts; S4 doc-wide quantitative-bounds annotation rule. Target tighter than Round 3 Rev 5 (917 lines) per Joe's cost-consciousness directive. |
| 2 | _this commit_ | 2026-06-05 | Kumar | Rev 1 asymmetric cross-review fold-in. **B1 promoted (S4 self-violation):** §3.6 numerics-classification list extended to cover §4.1 escalation thresholds (`≥ 3 new shapes`, `≥ 25% prevalence weight`), §10 step 1.5 measurement parameters (`≥ 1,000 bootstrap iterations`, `~5 min/payload` census estimate), §7 gate thresholds (`≥ +6` pytest delta, `50 lines` function smell). Meta-irony noted: Rev 1 replicated the Round-3 R10 defect class (R10 fixed in §3.3 → recurred elsewhere in same revision) at first-draft scale. Per S4 paragraph: cross-reviewer surfacing missed numerics triggered automatic findings entry; S4 working as designed. **R1 folded:** §10 step 1.5 verdict semantics tightened — equivocation language in adjudicator rationale is itself a not-operable signal; no third "maybe" verdict. **R2 folded:** §10 step 3a iteration-convergence trigger definitions made explicit — "rising" = non-decreasing across 3 consecutive cycles; "blocker count" = items first classified blocker by the cycle's cross-reviewer (no retroactive recount on later promotion); 3-cycle counter resets on any zero-blocker cycle. §9 wording reconciled to match. N-class items (F-POST language, canonical-parameterization explicit, §0 collapse, §9 trim) deferred unless Rev 2 cross-review surfaces them as substantive. |

---

## 0. Greenlight self-check (against the S1–S4 lock conditions)

| Lock condition | Where honored |
|---|---|
| **S1** Per-family criterion-4 aggregation declared explicitly | §3.2 family table (margin computation column) + §3.5 criterion 4 |
| **S2** Parameter-extension viability path struck; below-SLA = structurally non-viable, full stop | §3.2 family-viability paragraph + §6.1 working rules |
| **S3** §10 step 1.5 = binary operable/not-operable by adjudicator judgment | §10 step 1.5 (four measurement questions; no threshold table) |
| **S4** Every numeric is measured-cited or "design choice, no empirical basis" — no third category | §3.3 SLA derivation + meta-constraint paragraph at end of §3 |
| Round 3 inherits — HC-1…HC-5 unchanged | §2 |
| Round 3 inherits — shape battery S1–S6 | §4 |
| Round 3 inherits — DA surface 5.1–5.5 | §5 |
| Round 3 inherits — six categorical families (viability rule per S2) | §6.1 |
| Round 3 inherits — sign-off ladder (step 1.5 per S3; step 3a now Round-3.5.5) | §10 |

---

## 1. Objective & non-objective

**Objective.** Same scope as Round 3: replace the empirically falsified
`truncate_logs` algorithm in
[scripts/automation/src/triage/redact.py](../../scripts/automation/src/triage/redact.py)
with one that:

- **O1 (Cluster A — categorical):** produces in-window output on all
  3 Cluster A compile-phase `manifest_parse_failure` payloads, where
  "in-window" means the truncated output contains the ±256-char
  neighborhood of the first actionable error.
- **O2 (Cluster B/C — margin SLA):** preserves the actionable error in
  all 4 Cluster B/C payloads with margin to the nearest natural
  boundary meeting the corpus-derived SLA (§3.3).
- **O3 (rejection criterion):** ships with an explicit, written
  rejection / re-design trigger that a future payload sample can be
  measured against to invoke Round 4.

**Round-3.5 framing delta.** Round 3 attempted to lock all six
categorical families against a single SLA in one yardstick. The S2
simplification accepts that some families are structurally non-viable
for this corpus and treats non-viability as a finding rather than a
defect requiring parameter extension. Round 3.5 is the same scope
with the simpler decision rule.

**Non-objective.** Unchanged from Round 3:

- `REGEX_ELIGIBLE_FIELDS` membership beyond Round-2's `logs` addition.
- `_literal_stripped_preview` (compiled_code / raw_code).
- Field allowlist semantics for `message`, `truncated_debug_logs`,
  `status_message`.
- `EXCLUDED_PATTERNS` (locked Round 1).
- `rca_schema.py` contract version.
- Webhook / Phase 2 work.
- The `debug_logs` field (4.3 MB; Sprint-1 follow-up).

---

## 2. Hard constraints — non-negotiable

Carried forward unchanged from Round 3 Rev 5 §2.

| # | Constraint | Surface enforcing it |
|---|---|---|
| **HC-1** | No code modifications to `truncate_logs` or `ERROR_ANCHORS` until Round 3.5 closes via a single landing commit. | NOTICE block at [redact.py](../../scripts/automation/src/triage/redact.py); PR #1771 stays open |
| **HC-2** | No new `fbin_error_catalog.yml` patterns citing `signal_sources: [logs]` until Round 3.5 closes. | Mut9d catalog-load-time gate in `fbin_error_catalog.py` |
| **HC-3** | Mutation harness floor stays at **`12/12 CAUGHT`** (Mut1–Mut7 + structural baseline + Mut9a–Mut9d). Any Round-3.5 change preserves this floor; may only ADD. | `test_triage_redact.py` mutation tests |
| **HC-4** | `EXCLUDED_PATTERNS` list (`phone_us`, `cc_like`, `ssn`, `ip_address`) remains locked. | `EXCLUDED_PATTERNS` frozenset at [redact.py](../../scripts/automation/src/triage/redact.py) |
| **HC-5** | Field-aware allowlist ordering invariant unchanged: allowlist → hybrid truncation → credential sentinel → email pass. Round 3.5 may redefine the truncation step's internals; it may NOT move the step in the ordering. | Gate 7 contract assertion in `test_triage_redact.py` |

---

## 3. Methodology lock

**Rule:** the methodology below is locked as the FIRST artifact of
Round 3.5. Once locked, candidates are scored against a fixed
yardstick; no candidate may renegotiate the yardstick.

### 3.1 Evidence corpus (locked, pre-candidate)

**Base corpus (the 7 P0.1 payloads — non-negotiable):**

| Run ID | Cluster | `logs` size | Provenance |
|---|---|---:|---|
| 484675412 step 3 | C | 2,797 B | `~/scratch/triage-day4/` (re-pull, 2026-06-04, post-incident) |
| 485821754 step 3 | A | 2,893,220 B | same |
| 485850628 step 3 | A | 2,892,015 B | same |
| 485851058 step 3 | A | 2,893,220 B | same |
| 486060143 step 3 | C | 79,512 B | same |
| 487313189 step 3 | B | 10,570 B | same |
| 487333396 step 3 | B | 10,576 B | same |

**Extended corpus.** Per-cluster sample size is sufficient when ONE of
the following holds:

- **(a) Statistical sufficiency:** bootstrap 95% confidence interval
  on `p5(margin_to_nearest_natural_boundary)` has width ≤ 2 KB for
  that cluster. Rationale: SLA outputs are KB-resolution; a CI wider
  than 2 KB makes the SLA's KB-quantized value statistically
  indistinguishable from neighbors.
- **(b) Best-available corpus:** if dbt Cloud Admin v2 API does not
  yield enough distinct payloads of a given cluster within a 14-day
  pull window (DEV + QA + PROD), document the limitation in
  Appendix B, fail forward with the available n, and append a Round-4
  trigger condition tied to "when n_cluster ≥ sufficiency threshold
  becomes available."

The pre-§6 corpus pull records: (i) which clusters reach (a),
(ii) which fall back to (b), (iii) per-cluster bootstrap CI width
achieved. Pull script + provenance + sentinel-scan results + SHA256
manifest land in Appendix B of
[gate-d-logs-field-amendment.md](./gate-d-logs-field-amendment.md)
before §3.3 closes.

### 3.2 Measurement protocol (locked — S1 + S2 baked in)

For each candidate algorithm C and each payload P, produce the tuple:

```
(payload_id, cluster, candidate_id, candidate_family,
 anchor_match_name,                  # selected anchor, or None
 selected_position,                  # byte offset of selected anchor end
 actionable_error_position,          # ground-truth byte offset (§3.4)
 truncated_size,                     # bytes in output
 actionable_error_in_window,         # bool: ±256-char neighborhood ⊂ output
 margin_to_nearest_output_boundary,  # int (negative = out of output)
 output_boundary_definition_used,    # per-family table below
 nearest_boundary_distance,          # candidate-agnostic; §3.3 input
 pii_surface_hits,                   # via existing PII probe
 strategy_latency_us)                # wall-clock per truncate_logs call
```

**Per-family output-boundary definitions and criterion-4 aggregation
(S1 lock).** Each family declares its margin-computation rule
explicitly. The aggregation that feeds §3.5 criterion 4 is also
declared per family — no implicit "min across corpus" rule applies
uniformly.

| Family | `output-boundary` definition | Per-payload margin | Criterion-4 aggregation (S1) |
|---|---|---|---|
| **F-POS** | Two edges of anchor-centered window. | `min(error_pos − window_start, window_end − error_pos)` | `min(margin)` across extended corpus. |
| **F-SPEC** | Two edges of anchor-centered window. | Same as F-POS. | `min(margin)` across extended corpus. |
| **F-SEG** | Structural boundaries the candidate uses to delimit truncation (section break, phase header). | `min(error_pos − prev_chosen_boundary, next_chosen_boundary − error_pos)` | `min(margin)` across extended corpus. |
| **F-MODE** | Per-branch output boundary; each branch defines its own. | Computed per branch using that branch's boundary rule. | **`min(margin)` across branches × across extended corpus.** S1 explicit rule: F-MODE aggregation flattens branches into the corpus min. |
| **F-VAR** | Two edges of anchor-centered window using per-cluster anchor table + window size. | Same as F-POS, with per-cluster parameters. | `min(margin)` across extended corpus. **§6 provisional caveat:** if a per-cluster anchor table introduces a payload where no anchor of that cluster's table matches, treat as `margin = −∞` for aggregation and flag for §6 enumeration. |
| **F-POST** | Two edges of the raw tail-N-KB the truncation produces; downstream re-extraction is out of scope for the margin metric. | `min(error_pos − tail_start, tail_end − error_pos)` | `min(margin)` across extended corpus. **§6 provisional caveat:** if a candidate's extractor stage is integral to the in-window claim, §6 enumeration must add a stage-aware margin variant; pre-announce does not pre-commit to a stage-aware rule. |

**Single-yardstick property.** All five non-F-MODE families reduce to
`min(margin) across extended corpus`. F-MODE additionally flattens
branches into the same min. Each family's margin computation answers
the same question: "how much breathing room does the actionable error
have before a realistic log-format shift would push it out of the
truncator's output?"

**Family viability under criterion 4 (S2 lock — parameter-extension
path struck).** A family is "viable under §3.5 criterion 4" if there
exists at least one candidate in that family whose theoretical
ceiling on `margin_to_nearest_output_boundary` at its **canonical
parameterization** can reach the corpus-derived `SLA_min_margin`
(§3.3). A family whose canonical parameterization falls below the
SLA — e.g., F-POS at a default window-half of 4 KB when SLA derives
to 5 KB+ — is **structurally non-viable for this corpus, full
stop.** Non-viability is a **finding**, recorded in the DA artifact
and `lessons-learned.md`. There is no parameter-extended-variant
escape hatch (Round 3 Rev 5 §3.2 option (a) is struck per S2). The
viability check is computed against the SLA the moment §3.3 closes —
before §6 opens — so §6.1 categorical coverage does not force
dead-on-arrival candidates into the working session.

If no candidate in any viable family achieves
`min_margin_across_extended_corpus ≥ SLA_min_margin` without
violating §2 hard constraints, Round 3.5 escalates to Round 3.5.5
per §10 step 3a.

### 3.3 SLA derivation (candidate-agnostic; S4 annotation rule applies)

The minimum margin SLA is derived from the structure of the log
payloads themselves, not from any candidate's measured margins.

**Definition — "natural boundary":** the nearest byte offset (relative
to the ground-truth actionable error position from §3.4) where the log
text exhibits one of these structural breaks:

- consecutive newlines (≥ 2 `\n` in a row) — blank-line section break
- ISO-8601-like timestamp at line start (regex `^\d{2}:\d{2}:\d{2}` or
  `^\d{4}-\d{2}-\d{2}`) — new log event
- dbt section header (`==…==` rule lines; `Concurrency:`; `Done.`;
  `Finished running`) — phase boundary

For each ground-truth-labeled payload, measure `boundary_distance =
min(distance_to_prev_boundary, distance_to_next_boundary)`.

**SLA formula:**

```
SLA_min_margin = max(
    ceil_to_KB(p5(boundary_distances_across_extended_corpus)) * SAFETY_FACTOR,
    DESIGN_FLOOR
)
```

where:

- **`p5(boundary_distances_across_extended_corpus)`** — **measured;
  citation: `docs/triage-agent/fixtures/round3_boundary_distances.tsv`
  (produced during step 1.5 base-corpus measurement and extended in
  the working-session corpus pull).**
- **`SAFETY_FACTOR = 1.5`** — **design choice, no empirical basis.**
  Chosen as a round multiplier. Round-3.5 trigger condition: if
  empirical evidence of dbt-Cloud log-format changes accumulates over
  a rolling 12-month window such that any single observed change
  exceeds `1.5 × p5(boundary_distances)`, re-derive `SAFETY_FACTOR`
  from the new evidence and re-run §3.3.
- **`DESIGN_FLOOR = 1024 B`** — **design choice, no empirical basis.**
  Chosen as a round design floor sized to comfortably exceed typical
  short dbt error payloads. Working-session measurement: append p95
  actionable-error-line length as a new column to the boundary-
  distances fixture. If p95 line length exceeds 1024 B, raise
  `DESIGN_FLOOR` to `ceil_to_KB(p95_actionable_error_line_length)`
  and re-run §3.3.
- **`ceil_to_KB`** — rounds up to the nearest KB so the SLA is
  expressible in the same units as `ANCHOR_WINDOW_HALF_KB`.
- **`±256-char neighborhood` (Mut9a invariant; in-window definition):**
  **design choice, no empirical basis.** Carried unchanged from
  Round 1 / Round 2.

**dbt-format coupling (Round-4 trigger condition).** The natural-
boundary definitions contain dbt-specific log markers. If a dbt-Cloud
release produces any of: (a) removal or fundamental rename of `==`
rule lines; (b) removal or rename of the `Concurrency:` / `Done.` /
`Finished running` phase markers; (c) removal or rename of ISO-8601
timestamp prefixes at line start; (d) addition of a new phase marker
between existing markers (which silently shrinks
prev-boundary-to-error distance); (e) semantic change to an existing
marker's appearance pattern (e.g., `Done.` appearing mid-run rather
than at log tail) — the boundary-distance fixture MUST be re-measured
and the SLA re-derived before any further `logs`-citing catalog
patterns ship.

### 3.4 Ground-truth labeling protocol (locked)

For each payload in the extended corpus, the byte offset of the
"actionable error" is labeled by hand using these rules in order,
with rule selection recorded:

1. If the payload contains an `Encountered an error:` literal, its end
   position is the actionable error position.
2. Else if the payload contains a `Traceback (most recent call last):`
   literal, its end position is the actionable error position.
3. Else if the payload contains a `Database Error` / `Compilation
   Error` / `Runtime Error` literal, the end position of the first
   such occurrence is the actionable error position.
4. Else: payload is labeled `NO_GROUND_TRUTH` and excluded from
   in-window-rate scoring but retained for margin / latency / PII
   metrics. A payload count of `NO_GROUND_TRUTH > 10%` of extended
   corpus invalidates the SLA derivation.

Labeling output: one row per payload appended to
`docs/triage-agent/fixtures/round3_ground_truth.tsv`.

### 3.5 Scoring & winner-selection (locked, before candidates exist)

Candidates are scored on these criteria, in lexicographic order:

1. **Hard-constraint compliance (§2):** any violation = disqualified.
2. **In-window rate on Cluster A (objective O1):** must be 100% on the
   3 Cluster A base-corpus payloads AND ≥ 95% across the extended
   Cluster A corpus.
3. **In-window rate on Clusters B + C:** must be 100% on base corpus
   AND ≥ 99% across the extended corpus.
4. **Min `margin_to_nearest_output_boundary` ≥ SLA_min_margin (§3.3),
   aggregated per the per-family rule in §3.2 (S1 lock):** below =
   disqualified. SLA is candidate-agnostic per §3.3. For F-MODE
   candidates the aggregation is `min(margin) across branches across
   extended corpus`; for all other families it is `min(margin) across
   extended corpus`.
5. **Mut9a–Mut9d remain CAUGHT** under the candidate (re-run mutation
   harness against candidate code; not a paper review).
6. **Tie-break — mean PII surface hits:** lower wins.
7. **Tie-break — p95 latency ≤ 10 ms:** carried from Day-3.8
   acceptance §4; among compliant candidates, lower wins. **`10 ms`
   is a design choice, no empirical basis;** carried unchanged from
   Day-3.8.
8. **Tie-break — fewest new mutation invariants required to achieve
   floor compliance:** lower wins (simpler is better, all else equal).

Selection rule is total: ties past criterion 8 are resolved by
adjudicator decision and the chosen rationale is recorded as a fresh
[lessons-learned.md](./lessons-learned.md) entry.

### 3.6 Meta-constraint — quantitative-bounds annotation rule (S4 lock)

**Every numeric in this document is either (i) measured and cited to a
fixture file, OR (ii) explicitly labeled "design choice, no empirical
basis."** No third category. No unattributed quantitative ranges
("defensible range is 1.25–2.0", "200–800 B typical"). No "based on
prior experience" without citation. This rule is enforced at every
revision boundary, not just at Rev 1; a cross-reviewer surfacing a
numeric that fits neither category produces an automatic findings
entry requiring inline amendment before that revision converges.

Numerics in Rev 2, classified inline at their use sites:

- **Measured + cited:** the 7 base-corpus payloads (§3.1, citation
  `~/scratch/triage-day4/`); `p5(boundary_distances)` (§3.3,
  citation `round3_boundary_distances.tsv`); `12/12 CAUGHT`
  mutation floor (§2 HC-3, citation `test_triage_redact.py`).
- **Design choice, no empirical basis:** `2 KB` CI width (§3.1a);
  `14-day` pull window (§3.1b); `SAFETY_FACTOR = 1.5` (§3.3);
  `DESIGN_FLOOR = 1024 B` (§3.3); `±256-char` neighborhood (§3.3,
  carried from Round 1); `10%` NO_GROUND_TRUTH threshold (§3.4);
  `95% / 99% / 100%` in-window rates (§3.5 criteria 2–3);
  `p95 latency ≤ 10 ms` (§3.5 criterion 7, carried from Day-3.8);
  `≥ 3 new shapes by count` (§4.1 escalation threshold);
  `≥ 25% prevalence weight` (§4.1 escalation threshold);
  `≥ 1,000 bootstrap iterations` (§10 step 1.5(1));
  `~5 min/payload` census estimate (§10 step 1.5(4) — estimate
  superseded by base-corpus end-to-end measurement at step 1.5
  execution time; the estimate itself is design choice);
  `≥ +6` expected pytest delta (§7 gate 5).
- **Carried from existing standard (treated as inherited design
  choice, no Round-3.5-specific empirical basis):** `50 lines`
  function smell threshold (§7 gate 4, carried from `code_reviewer.py`
  category-K1 default).

**Rev 2 meta-observation.** Rev 1's §3.6 list omitted the six
numerics above. This was the exact Round-3 R10 defect class
(unattributed numerics) at first-draft scale, replicated in the
revision that purported to install S4 as the lock against it. Per
the S4 paragraph itself, the cross-reviewer's surfacing of these
omissions produced the automatic findings entry that folded into
this Rev 2. The meta-constraint is working as designed: it caught
its own first-draft violation at the first review pass. Future
revisions are responsible for the rule, not the drafter's memory.

---

## 4. Adversarial input shape battery (locked before §6)

Carried unchanged from Round 3 Rev 5 §4.

| Shape | Description | Observed in corpus? | Why it threatens anchor selection |
|---|---|---|---|
| **S1 — Front-loaded actionable, back-loaded noise** | Small high-signal block in first N KB; large low-signal payload in tail. | Yes — Cluster A (3/7) | The Cluster A reproducer. Defeats "last position wins". |
| **S2 — Back-loaded actionable, front-loaded noise** | Large boilerplate header; actionable error in tail. | Plausible (Cluster B/C step 3). | Defeats "first match wins" / "specificity-first hard ordering". |
| **S3 — Multiple actionable errors, interleaved** | Multiple matches separated by KB-to-MB intermediate output. | Plausible in multi-model runs. | Forces explicit policy: first vs last vs most-severe. |
| **S4 — No actionable anchor, only noise** | dbt run with no recognized error keyword (infrastructure / OOM). | Plausible (Cluster D). | Forces tail-fallback correctness. |
| **S5 — Actionable error in middle, symmetric noise** | Real error near byte N/2 of large payload; comparable telemetry on both sides. | Plausible. | Forces window-symmetry decisions. |
| **S6 — Pathological repeated anchor literal** | Payload contains the literal anchor string hundreds of times inside string literals or template fragments. | **Per §4.1 census, may already be empirically present in Cluster A.** | Defeats raw-token-frequency signals. |

**Battery construction.** Each shape gets ≥ 1 base-corpus representative
(where available per §4.1) PLUS ≥ 2 synthetic fixtures constructed to
make the shape pessimal for anchor selection. Synthetic fixtures live
under `docs/triage-agent/fixtures/round35_synthetic/`. Round-3.5 DA
(§5.5) explicitly interrogates synthetic fixtures for constructor
bias before any candidate is scored against them.

### 4.1 Anchor-match census on base ∪ extended corpus (runs BEFORE §6 opens)

Before §6 opens, run a one-shot census scanning all 9 `ERROR_ANCHORS`
patterns against each payload in `base ∪ extended` and categorizing
EVERY match as exactly one of:

- **(a) genuine actionable error context** — within ±256 chars of the
  ground-truth actionable error position.
- **(b) telemetry / template string literal** — inside a JSON string
  value, Python dict repr, SQL `IN(...)` literal, or logged template
  fragment.
- **(c) footer summary line** — `Finished running … failed`,
  `Done. PASS=…`, or similar.

**Classification authority.** Census classification of any new shape
surfaced by the extended-corpus scan is performed by a designated
reviewer who is NOT the author of the candidate that proposed (or
would benefit from) the shape. Default: the asymmetric cross-reviewer
(Copilot/Gemini); substitute a second human adjudicator if the
cross-reviewer is unavailable. The reviewer is named in the §10
working-session opening.

Census output: `docs/triage-agent/fixtures/round35_anchor_census.tsv`,
one row per `(payload_id, anchor_name, match_position, category,
classification_rule, corpus_source)`.

**Generalization escalation threshold.** If the census surfaces ≥ 3
new shapes by count, OR ≥ 25% prevalence weight of any single new
shape across the extended corpus, OR a single new family of failure
mechanism not enumerated in S1–S6 — Round-3.5.5 escalation per §10
step 3a. Otherwise, amend §4 in place via an inline Rev-N+1 revision
to this file, re-circulate briefly for adjudicator confirmation,
proceed to §6.

---

## 5. DA failure-mode interrogation surface (locked before §6)

Carried unchanged from Round 3 Rev 5 §5. The Round-3.5 DA must answer
EACH question for EACH candidate in §6 before scoring opens. A DA
that skips any question is incomplete and the candidate is held.

### 5.1 Cross-position selection questions

- **Q-CP1.** Two matches at p₁ ≪ p₂ where p₁ has higher specificity.
  Which does the candidate select? Justify for ALL six shapes S1–S6.
- **Q-CP2.** Three matches at p₁ < p₂ < p₃ with mixed specificity. Is
  the winner stable regardless of intervening noise size?
- **Q-CP3.** For shapes S3 + S6, demonstrate the selection rule does
  not silently degrade as the number of competing matches grows.
- **Q-CP4.** Specificity-first-hard-ordering candidates: what happens
  when the most-specific anchor matches inside a string literal (S6
  per §4.1 census)? Footer-aware candidates: what happens when the
  footer line is truncated by dbt Cloud before the artifact lands?
- **Q-CP5.** If the candidate ranks by both specificity AND position,
  state the lexicographic order explicitly; verify against a 4-input
  truth table of (high/low specificity) × (early/late position).

### 5.2 Same-position questions

- **Q-SP1.** Two anchors match at the same end position. State the
  tie-break rule; prove determinism under Python dict iteration order
  / regex engine changes.
- **Q-SP2.** A new anchor is added to `ERROR_ANCHORS`. Does the
  tie-break preserve existing winners for previously unambiguous
  inputs? If not, document migration impact.

### 5.3 Boundary questions

- **Q-B1.** `text` is exactly `LOGS_MAX_BYTES + 1`. Behavior at
  `LOGS_MAX_BYTES`, `LOGS_MAX_BYTES - 1`, `0`, `1`?
- **Q-B2.** Anchor matches at byte 0 or `len(text)`. Window math
  underflow/overflow? Mut9a `±256-char neighborhood` clamped?
- **Q-B3.** `bytes` or `str`? If `bytes`: demonstrate UTF-8 boundary
  safety on mid-codepoint slices. If `str` (current behavior):
  explicitly state "str-mode; Q-B3 N/A."
- **Q-B4.** Anchor match at p such that the window straddles both
  ends of `text`. Is the full-text output ≤ `LOGS_MAX_BYTES`?

### 5.4 Latency questions

- **Q-L1.** Worst-case time complexity on a 2.9 MB payload with K
  anchor patterns, M matches per pattern. Bound it.
- **Q-L2.** Regex catastrophic backtracking on any constructible
  adversarial input?
- **Q-L3.** Stable under Python regex cache invalidation in long
  sessions with many distinct patterns?

### 5.5 Synthetic-fixture-bias questions

- **Q-SF1.** For every synthetic fixture in §4, identify the algorithm
  the constructor was most likely imagining. Does the fixture also
  exercise a behavior the OTHER candidate would get right? If not,
  construct a paired fixture that does.
- **Q-SF2.** Synthetic fixtures missing a real-corpus analog: what
  would a real payload of this shape look like, and is it plausible
  to encounter one in DEV / QA / PROD?

---

## 6. Candidate enumeration & scoring (OPENS ONLY AFTER §3–§5 LOCK)

This section is **deliberately empty** at pre-announce time. Filling it
is the first activity of the Round-3.5 working session AFTER
adjudicator sign-off on §3 / §4 / §5.

### 6.1 Working rules (S2 viability rule applied)

- Pre-announce enumerates the design space from scratch. The two
  directions surfaced informally during P0.1 analysis
  ("specificity-first hard ordering"; "footer-aware `generic_failed`")
  enter §6 as **two among the families enumerated below**, not as the
  seed set.

- §6 must include ≥ 1 candidate from each family **that is viable
  under §3.2 criterion 4 at canonical parameterization given the
  corpus-derived SLA**, OR a structurally-non-viable finding. A
  family documented as structurally non-viable per §3.2 satisfies
  coverage by the non-viability finding itself — no dead-on-arrival
  candidate is required, and **no parameter-extended-variant rescue
  is attempted (S2 lock).** Counting candidates does not satisfy
  coverage; two candidates from the same family count as one.

  **Spanning-candidate accounting (carried from Round 3 Rev 5 R12).** A
  single candidate whose design spans more than one §6.1 family
  counts for exactly one family for §6.1 coverage purposes. Which
  family it counts for is a working-session adjudicator choice,
  recorded with rationale in `gate-d-round35-da.md` alongside the
  candidate's pseudocode. The other family it spans still requires
  its own coverage candidate (or a non-viability finding per §3.2).

  | Family | Description | Example |
  |---|---|---|
  | **F-POS** Position-based selection | Selection rule depends only on byte position. | Last match, first match, fixed-window-positional |
  | **F-SPEC** Specificity-based selection | Total order on anchor specificity; position used only as tie-break (or not at all). | Specificity-first hard ordering, weighted specificity |
  | **F-SEG** Segmented / structural | Selection respects log structure (sections, phases, footer lines). | Footer-aware `generic_failed`, section-boundary-aware window |
  | **F-MODE** Algorithm-per-branch mode switching | Detect a payload property (length, cluster signature), then dispatch to a structurally different ALGORITHM per branch. | Branch on `len(text) > THRESHOLD`: short → F-POS-style last-match; long → F-SEG-style footer-aware. |
  | **F-VAR** Parameters-per-branch variable window | Detect a payload property, then dispatch to the SAME algorithm with DIFFERENT PARAMETERS per branch. | Cluster-A-aware specialized anchor list with smaller window; default anchor list for B/C. |
  | **F-POST** Post-truncation re-extraction | Truncate by tail-fallback, then have a downstream stage extract the actual error block. | Tail-64 KB truncate + downstream re-extractor stage |

  A candidate that fits no family is documented as a NEW family with
  rationale.

- Each candidate carries: pseudocode; pseudocode complexity bound;
  list of new mutation invariants needed; explicit answers to all of
  Q-CP1…Q-SF2; worked examples for each of S1–S6 (with S6 examples
  drawn from §4.1 census if available).
- Scoring uses §3.5 yardstick verbatim. Yardstick is NOT renegotiated
  against candidates.
- If the winning candidate disqualifies on any criterion 1–5,
  Round 3.5 escalates to Round 3.5.5 per §10 step 3a — does NOT
  relax the yardstick.

**Taxonomy-completeness test (cross-reviewer).** Before §6 scoring
opens, the cross-reviewer of §6 enumeration MUST attempt to construct
at least one candidate that resists classification into the six §6.1
families, OR document why such construction is genuinely difficult
given the taxonomy. A taxonomy that classifies every attempted
candidate trivially fails its own completeness test.

---

## 7. Round-3.5 8-gate matrix (annotated vs Round 3 Rev 5 §7)

Carried unchanged in substance from Round 3 Rev 5 §7. Round-3.5
deltas are filename-level: artifact `gate-d-round35-da.md` (Gate 1);
snapshot `test_round35_in_window_snapshot` (Gate 8). Gates 2–7
unchanged.

Five BLOCK surfaces to unwind at Gate 3: (i) NOTICE block in
`redact.py` REMOVED; (ii) `sprint-1-deferred.md` item #14 → Closed;
(iii) `v2-plan.md` §1.3 BLOCK annotation removed;
(iv) `lessons-learned.md` 2026-06-05 entries retained with Round-3.5
closing addendum; (v) Mut9d runtime gate NOT modified (HC-2).

Gate 5 expected pytest delta ≥ +6 (Mut10a–Mut10c + in-window +
min-margin + ground-truth); exact number set by winning candidate.
Gate 6 floor `12/12` (HC-3); ceiling grows to `≥ 12 + K` where K =
candidate's declared new invariants.

Landing-commit body reports all 8 gates plus a "P0.2 inspection" line
documenting the §3.2 measurement protocol re-run against the winning
candidate on the extended corpus, with the resulting
`in-window rate / min margin / SLA` triple.

---

## 8. Deliverables & landing commit

The Round-3.5 landing commit (single commit, conventional-commit
style) modifies these files, no more:

- `scripts/automation/src/triage/redact.py` — replacement algorithm;
  NOTICE block removed; `truncate_logs` docstring updated.
- `scripts/automation/tests/test_triage_redact.py` — new Mut10a+
  invariants per winning candidate; new in-window + min-margin
  snapshots; existing Mut1–Mut9d preserved.
- `scripts/automation/tests/test_triage_matcher_perf.py` — re-baseline
  p95 latency target if winning candidate changes it.
- `docs/triage-agent/gate-d-logs-field-amendment.md` — new §7
  ("Round 3.5 — anchor selection redesign") after §6. §3.2 and §6
  remain as falsified historical record with cross-references.
  Appendix B (extended corpus provenance) appended if not already
  added during corpus pull.
- `docs/triage-agent/gate-d-round35-da.md` — new file; full DA
  artifact (§5 answers per candidate).
- `docs/triage-agent/fixtures/round3_ground_truth.tsv` — new file
  (Round-3 name retained for fixture-naming continuity).
- `docs/triage-agent/fixtures/round3_boundary_distances.tsv` — new
  file (candidate-agnostic SLA input data; same continuity).
- `docs/triage-agent/fixtures/round35_anchor_census.tsv` — new file
  (produced before §6 opens, carried into commit).
- `docs/triage-agent/fixtures/round35_synthetic/*` — new directory;
  one fixture per S1–S6 plus paired anti-bias fixtures per Q-SF1.
- `docs/triage-agent/sprint-1-deferred.md` — item #14 → Closed with
  landing commit SHA.
- `docs/triage-agent/lessons-learned.md` — new entry capturing what
  Round 3.5 surfaced beyond the Round-2 + iteration-convergence
  lessons.
- `docs/triage-agent/round-3-handoff.md` — marked CLOSED with
  forwarding note to landing commit.
- `docs/triage-agent/round-3.5-pre-announce.md` (this file) — marked
  CLOSED at the top with forwarding note to landing commit.
- `docs/triage-agent/v2-plan.md` §1.3 — BLOCK annotation removed.

The Mut9d catalog-load-time gate in `fbin_error_catalog.py` is **NOT
modified**. HC-2 remains in force until a follow-up commit ships the
first `logs`-citing catalog pattern with its own gate-passing
evidence.

---

## 9. Out-of-band notes

- **Round-3 historical record.** Round 3 Rev 1–5 remain in git
  (`gate-d-round3-preannounce.md` at SHA `0dbe5e72`). Do not delete;
  the iteration is itself the lesson. Reference text in
  [sprint-1-deferred.md item #14](./sprint-1-deferred.md) and
  [v2-plan.md §1.3](./v2-plan.md) already points to Round 3.5 per the
  209db052 escalation commit.
- **Token environment.** `~/scratch/triage-day4/` payloads were
  re-pulled 2026-06-04 under the rotated dbt PAT after the
  [security-incident-2026-06-04](./security-incident-2026-06-04.md).
  Extended-corpus pulls use the same rotated PAT and follow Sprint-1
  #13 production-token migration constraints.
- **Asymmetric cross-review continuation.** Copilot/Gemini's review of
  this pre-announce is itself the load-bearing gate. Per Joe's
  cost-consciousness directive, expected convergence is 1–2
  revisions, not 4+. If iteration shows blocker count failing to
  strictly decrease across 3 consecutive cycles (definitions per
  §10 step 3a — non-decrease fires the trigger, with counter reset
  on any zero-blocker cycle), or fixes recurring across sections of
  the same defect class, surface as a structural problem immediately
  rather than continuing to patch — that signal warrants Round-3.5.5
  design pivot, not Round-3.5 Rev 3/4/5 continued patching.
- **No code touches in this session past pre-announce sign-off.**
  Candidate enumeration (§6) starts in a fresh session after §3/§4/§5
  are adjudicator-locked.

---

## 10. Sign-off ladder (S3 binary operability check; step 3a is Round-3.5.5)

1. Adjudicator (user) reviews §1–§9. Lands edits if §3/§4/§5 need
   tightening.

   **1.5. Methodology operability check (S3 lock — binary verdicts).**
   After adjudicator sign-off on §3/§4/§5 and BEFORE the asymmetric
   cross-review of step 2 fires, run a one-shot operability check
   of the locked methodology against the **base corpus** (the 7 P0.1
   payloads — no extended-corpus pull yet). The check answers four
   measurement questions; **each produces a binary operable /
   not-operable verdict by adjudicator judgment, recorded with
   rationale in
   `docs/triage-agent/fixtures/round35_operability_check.md`. There is
   no threshold table; S3 deletes the Round 3 Rev 5 threshold table
   in favor of adjudicator-judgment verdicts with documented
   rationale.**

   **The four measurement questions:**

   1. **Bootstrap CI width on n = base.** Compute `boundary_distance`
      per §3.3 for each of the 7 base-corpus payloads, bootstrap-
      resample `p5(boundary_distances)` with ≥ 1,000 iterations,
      report 95% CI width in KB. Verdict: is the methodology operable
      given this CI width on n = 7, expecting the extended corpus to
      tighten it?
   2. **Distribution shape inspection for bimodality.** Plot the 7
      boundary-distance values; describe shape (single mode, suggests
      bimodality, too small to call). Verdict: is the methodology
      operable given this shape, or does it require per-cluster SLA
      derivation before the extended-corpus pull is worth running?
   3. **NO_GROUND_TRUTH rate on the base corpus.** Run §3.4 labeling
      rules against the 7 base payloads and count NO_GROUND_TRUTH
      outcomes. Verdict: is the methodology operable given this rate,
      or does §3.4 need a new labeling rule before extended-corpus
      labeling burns spend?
   4. **Census budget feasibility.** §4.1 estimates ~5 min/payload.
      Time actual base-corpus classification of one payload end-to-
      end; multiply by projected extended-corpus N. Verdict: is the
      methodology operable within the working-session time budget?

   **Verdict semantics (S3 lock).** Each question produces one of:

   - **operable** — proceed; rationale records why the observed
     finding is acceptable for moving to step 2.
   - **not-operable** — Round-3.5.5 escalation per §10 step 3a,
     regardless of which of the four questions fired. The
     methodology requires structural simplification before the
     extended-corpus pull is committed spend.

   **No third "maybe" verdict (Rev-2 R1 fix).** Equivocation
   language in the adjudicator's rationale ("marginal",
   "borderline", "proceed with caution", "on balance", "close
   call") is itself a **not-operable signal**. Operable means
   clearly operable. Ambiguous means not-operable. The verdict
   surface is binary precisely so that hedging surfaces the
   discipline failure rather than absorbing it. A rationale that
   reads as judgment-call rather than clear-finding is an
   automatic step-2 cross-review trigger to escalate the verdict
   to not-operable.

   **Critical-path role (preserved from Round 3 Rev 5).** The
   asymmetric review at step 2 re-fires against step 1.5's verdicts
   AND their recorded rationale, not just against §1–§9. A
   cross-reviewer may dispute an `operable` verdict on the basis of
   rationale; resolution is adjudicator-recorded.

   **Timing.** Step 1.5 runs against the base corpus only BEFORE the
   extended-corpus pull begins, for the same reason as Round 3
   Rev 5: extended-corpus pull is committed spend (dbt Cloud Admin v2
   API throughput + sentinel-scan time + SHA256 manifest), and
   running it before 1.5 confirms methodology operability burns that
   spend on a methodology that may need to be re-derived. 1.5's
   measurements use fixtures already on disk and the §3.4 labeling
   rules already locked — no new corpus pull required.

2. **Asymmetric cross-review (Copilot/Gemini)** pushes back on
   §1–§9 AND on step 1.5's four verdicts + rationale. Adjudicator
   resolves divergences.

3. Adjudicator opens §6 by signaling "open Round 3.5 candidate
   enumeration." Candidates produced per §6.1 categorical coverage;
   DA artifact authored per-candidate; §3.5 scoring runs.

   **3a. Round 3.5.5 escalation branch.** If §3.5 scoring disqualifies
   ALL candidates against criteria 1–5, OR if step 1.5 produced a
   not-operable verdict on any of the four questions, HALT before
   landing-commit drafting. Open a Round-3.5.5 pre-announce with
   revised §6 working rules — typically expanding the design space
   (e.g., relaxing HC-5 ordering invariant under explicit adjudicator
   decision; splitting `truncate_logs` into cluster-detected sub-
   routines; introducing a downstream re-extraction stage).
   **Round 3.5.5 produces its own pre-announce subject to its own
   adjudicator review (analogous to §10 step 1 of this ladder), its
   own asymmetric cross-review (analogous to step 2), and its own
   candidate enumeration opening (analogous to step 3), before
   reaching landing-commit drafting.** The yardstick (§3.5 criteria
   1–5) is not relaxed under deadline pressure — yardstick relaxation
   requires its own pre-announce + DA cycle.

   **Iteration-convergence trigger (carried from
   [lessons-learned.md 2026-06-05 entry 2](./lessons-learned.md);
   definitions tightened per Rev-2 R2 fix).**
   If blocker count fails to strictly decrease across 3 consecutive
   revision cycles of this Round-3.5 pre-announce, escalate to
   Round-3.5.5 design pivot regardless of whether individual
   findings are addressable. Operational definitions:

   - **Rising / fails-to-decrease.** Blocker count does not
     strictly decrease across the 3-cycle window: `count(Rev N+1)
     ≥ count(Rev N) AND count(Rev N+2) ≥ count(Rev N+1)`. A plateau
     (e.g., 2 → 2 → 2) is non-decreasing and therefore fires the
     trigger; only strict descent (e.g., 4 → 3 → 2) keeps the
     revision train alive.
   - **Blocker count.** Items classified blocker by the asymmetric
     cross-reviewer of that cycle. A refinement that is later
     promoted to blocker by adjudicator decision does not
     retroactively change the cycle's count; it is counted in the
     cycle whose cross-review surfaced the promotion. The drafter's
     own meta-observations (e.g., the Rev-2 B1 / R1 / R2 noted in
     the revision-history row) DO count toward the cycle's blocker
     count when accepted by the adjudicator.
   - **Counter reset.** The 3-cycle counter resets if any cycle
     produces zero blockers. A `0` cycle is evidence of
     convergence-in-progress; the trigger fires only on sustained
     non-descent.

   The Round-3 iteration is the empirical basis: Rev 3→4: 1
   blocker; Rev 4→5: 2 blockers; Rev 5→6: 4 blockers — strict
   non-decrease across 3 cycles, fires the trigger as defined.

4. Winning candidate moves to landing-commit drafting. Gates 1–8 run
   against the candidate code in a separate working session. Landing
   commit posted as a PR commit on PR #1771 (which stays the open
   PR; no new PR).

5. Sprint-1 #14 closes; NOTICE block removed; first `logs`-citing
   catalog pattern moves to a follow-up commit/PR with its own gate
   matrix.

---

**End pre-announce REVISION 2. Inherits structure from Round 3 Rev 5
(SHA `0dbe5e72`) and content base from Round-3.5 Rev 1 (SHA
`a02e44c3`). Locks S1–S4 from
[lessons-learned.md 2026-06-05 entry 2](./lessons-learned.md). Rev 2
folds Rev-1 cross-review findings: B1 (§3.6 S4-coverage extension to
§4.1 + §7 + §10 step 1.5 numerics) + R1 (§10 step 1.5 equivocation
rule) + R2 (§10 step 3a iteration-convergence trigger definitions).
N-class refinements deferred. No code touches. No §6 candidates
locked.**

**Awaiting §10 step 2 re-review by Copilot/Gemini against this
committed Revision 2. Per the iteration-convergence trigger in
§10 step 3a (Rev-2 definitions): Rev 1→Rev 2 produced 1 blocker.
For convergence, Rev 2→Rev 3 should produce strictly fewer
(target: 0). A second cycle with ≥ 1 blocker enters the 3-cycle
window; if Rev 3→Rev 4 then surfaces ≥ 1 blocker without strict
descent, the trigger fires and the work routes to Round-3.5.5
regardless of whether the Rev 4 findings are individually
addressable.**

---

## Closing block (added 2026-06-05, post-landing)

This pre-announce document is FROZEN as historical record. Round 3.5
did not produce a converging methodology; Round 3.5.5 was opened to
address the surface-area diagnosis Copilot surfaced in Rev-2
cross-review, and was in turn closed by a 5-rule algorithm spike that
bypassed the methodology entirely.

- **Spike outcome:** 15/15 PASS (7 real P0.1 + 8 synthetic). See
  [round-3.5.5-spike-results.md](./round-3.5.5-spike-results.md).
- **Landing commit:** on branch `feature/dv-failure-triage-agent`,
  ports 5-rule algorithm into
  [redact.py](../../scripts/automation/src/triage/redact.py),
  adds `TestTruncateLogsV2` (7 mutation tests) +
  `TestTruncateLogsSnapshots` (7 P0.1 pins), removes HC-1 NOTICE
  block, lifts BLOCK on Sprint-1 item #14.
- **Methodology lesson:** see
  [lessons-learned.md 2026-06-05 entry 4](./lessons-learned.md) —
  empirical cap on methodology-iteration cycles.

This document is not maintained going forward. Future methodology
work should follow the spike-or-iterate decision at the start of
Round 3 per entry 4.
