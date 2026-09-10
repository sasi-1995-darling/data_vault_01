# Gate-D Round 3 — Pre-announce (REVISION 5)

**Branch:** `feature/dv-failure-triage-agent`
**HEAD at authoring:** `6ad48019`
**Author:** Claude Opus 4.7
**Adjudicator:** Kumar
**Cross-review:** Copilot/Gemini (asymmetric, ongoing)
**Status:** PRE-ANNOUNCE — no code touches, no candidates locked yet

This document is itself a reviewable artifact, modeled on the Day-3.8
predecessor (commit `ac2c384c`). It is committed to the branch BEFORE
asymmetric cross-review per §10 step 2, so cross-review pushback lands
against a SHA-citable file rather than a chat-message version.

## Revision history

New-revision discipline: every revision adds one row to this table
and updates the header above. The SHA in the table is the authoritative
frozen pointer to that revision's state; the filename stays stable
(living-document pattern). External citation MUST use SHA + filename,
not filename alone.

| Rev | SHA | Date | Adjudicator | Summary |
|---|---|---|---|---|
| 1 | (chat-only; uncommitted) | 2026-06-05 | user | Initial pre-announce draft |
| 2 | (chat-only; uncommitted) | 2026-06-05 | user | Gemini adjudication blockers + refinements resolved (B1: candidate-agnostic SLA; B2: bootstrap-CI sample sizing + 14-day fail-forward; B3: categorical coverage replacing count floor; R1: §4.1 anchor-match census; R2: Q-B3 input-type framing; R3: Gate 3 doc-level BLOCK unwind verification; R4: §10 step 3a Round-3.5 escalation branch) |
| 3 | `59d496ce` | 2026-06-05 | user | §3.3 dbt-format coupling documented as Round-4 trigger condition (Gemini non-blocking Option A) |
| 4 | `6ad48019` | 2026-06-05 | user | Claude self-review: B4 (Option C — single yardstick across all 6 families via per-family output-boundary definition); R5 (honest SAFETY_FACTOR re-labeling + 12-month Round-4 trigger); R6 (honest DESIGN_FLOOR rationale; no false §5.1 citation); R7 (§4.1 census extended to base ∪ extended corpus + 2-vs-3-shape escalation threshold); R8 (F-MODE = algorithm-per-branch / F-VAR = parameters-per-branch crisp distinction); R9 (taxonomy completeness test moved to cross-reviewer); N1 (§10 step 3a self-reference rewritten); N2 (this revision-history table is itself the N2 fix instance) |
| 5 | _this commit_ | 2026-06-05 | Kumar | Copilot cross-review + Claude adjudication: B5 promoted (§3.2 + §6.1 — restrict B3 categorical coverage to families viable under §3.2 criterion 4 given corpus-derived SLA; R12 spanning-candidate accounting folded into same edit — one family per spanning candidate, working-session adjudicator choice with rationale in DA artifact); Z1 promoted (§10 step 1.5 methodology operability check inserted with explicit Rev-5+ inline-amendment vs Round-3.5 escalation thresholds); R10 folded (§3.3 — stripped unattributed quantitative ranges from SAFETY_FACTOR and DESIGN_FLOOR rationale, reframed as design choices with no measured basis); R11 folded (§4.1 — census classification authority assigned to a designated reviewer who is NOT the proposing candidate's author; frequency-weighted escalation threshold added — ≥3 new shapes by count OR ≥25% prevalence weight of any single new shape triggers Round-3.5); R13 folded (§3.3 dbt-format Round-4 trigger extended with (d) additive new phase marker between existing markers, (e) semantic change to existing marker appearance pattern); N3 deferred to §6 working session opening |

---

## 0. Greenlight self-check (against original Gemini conditional)

| Condition | Where honored |
|---|---|
| (1) DA enumeration covers cross-position categorical space | §4 (shapes S1–S6 + §4.1 corpus census) and §5 |
| (2) Locked methodology before locked candidates | §3 (SLA + sampling + scoring) and §4 (shape battery) precede §6 (empty at pre-announce) |
| (3) All five hard constraints carried forward | §2 |
| (4) 8-gate matrix refined for Round 3 | §7 (annotated deltas vs Day-3.8 commit `ac2c384c`) |

---

## 1. Objective & non-objective

**Objective.** Replace the empirically falsified `truncate_logs`
algorithm in [scripts/automation/src/triage/redact.py](../../scripts/automation/src/triage/redact.py)
with one that:

- **O1 (Cluster A — categorical):** produces in-window output on all
  3 Cluster A compile-phase `manifest_parse_failure` payloads, where
  "in-window" means the truncated output contains the ±256-char
  neighborhood of the first actionable error (bytes 315–671 in the
  sample), not the `generic_failed` match at byte ≈ 2,690,340 inside
  manifest telemetry.
- **O2 (Cluster B/C — margin SLA):** preserves the actionable error in
  all 4 Cluster B/C payloads with margin to the nearest window edge
  meeting the candidate-agnostic SLA derived in §3.3.
- **O3 (rejection criterion):** ships with an explicit, written
  rejection / re-design trigger that a future payload sample can be
  measured against to invoke Round 4.

**Non-objective.** This round does NOT touch:

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

Carried forward from the handoff doc. **All five must remain unviolated
through the end of Round 3.** Any candidate requiring violation is
disqualified before scoring.

| # | Constraint | Surface enforcing it |
|---|---|---|
| **HC-1** | No code modifications to `truncate_logs` or `ERROR_ANCHORS` until Round 3 closes via a single landing commit. | NOTICE block at [redact.py](../../scripts/automation/src/triage/redact.py); PR #1771 stays open |
| **HC-2** | No new `fbin_error_catalog.yml` patterns citing `signal_sources: [logs]` until Round 3 closes. | Mut9d catalog-load-time gate in `fbin_error_catalog.py` |
| **HC-3** | Mutation harness floor stays at **`12/12 CAUGHT`** (Mut1–Mut7 + structural baseline + Mut9a–Mut9d). Any Round-3 change preserves this floor; may only ADD (e.g., Mut10a+). | `test_triage_redact.py` mutation tests |
| **HC-4** | `EXCLUDED_PATTERNS` list (`phone_us`, `cc_like`, `ssn`, `ip_address`) remains locked. | `EXCLUDED_PATTERNS` frozenset at [redact.py](../../scripts/automation/src/triage/redact.py) |
| **HC-5** | Field-aware allowlist ordering invariant unchanged: allowlist → hybrid truncation → credential sentinel → email pass. Round 3 may redefine the truncation step's internals; it may NOT move the step in the ordering. | Gate 7 contract assertion in `test_triage_redact.py` |

---

## 3. Methodology lock (must freeze before §6 candidate scoring begins)

**Rule:** the methodology below is locked as the FIRST artifact of
Round 3. Once locked, candidates are scored against a fixed yardstick;
no candidate may renegotiate the yardstick. This is the structural
defense against the Round-2 failure mode where the locked rule
("position wins outright") became its own implicit candidate.

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

**Extended corpus (empirical sample-size sufficiency; B2 fix):**

Per-cluster sample size is sufficient when ONE of the following holds:

- **(a) Statistical sufficiency:** bootstrap 95% confidence interval
  on `p5(margin_to_nearest_natural_boundary)` (the candidate-agnostic
  metric defined in §3.3) has width ≤ 2 KB for that cluster.
  Rationale for the 2 KB width target: SLA outputs are
  KB-resolution (matches `ANCHOR_WINDOW_HALF_KB` granularity); a CI
  wider than 2 KB makes the SLA's KB-quantized value statistically
  indistinguishable from neighbors.
- **(b) Best-available corpus:** if dbt Cloud Admin v2 API does not
  yield enough distinct payloads of a given cluster within a 14-day
  pull window (DEV + QA + PROD), document the corpus limitation in
  Appendix B, fail forward with the available n, and append a Round-4
  trigger condition tied to "when n_cluster ≥ statistical-sufficiency
  threshold becomes available."

The pre-§6 corpus pull explicitly records: (i) which clusters reach
(a), (ii) which clusters fall back to (b), (iii) per-cluster
bootstrap CI width achieved.

**Pull script + provenance + sentinel-scan results + SHA256 manifest**
for the extended corpus are recorded in a new Appendix B of
[gate-d-logs-field-amendment.md](./gate-d-logs-field-amendment.md)
before §3.3 closes.

### 3.2 Measurement protocol (locked — Rev-4 B4 fix: Option C single-yardstick margin)

**Rev-3 problem (B4 self-review finding).** Revision 3's tuple used
`margin_to_nearest_window_edge`, which is window-shaped semantics.
That metric only applies to candidates with a symmetric anchor-centered
window (F-POS / F-SPEC / F-MODE / F-VAR with variable-window
interpretation). F-SEG and F-POST families have no "window edge" in
the same sense — F-SEG bounds are structural; F-POST has a raw tail
with fixed edges, and the actual error extraction is downstream. The
Rev-3 metric quietly disqualified two of six required §6.1 families
before §6 scoring opened — structurally identical to the Round-2
failure mode.

**Rev-4 fix (Option C).** Redefine the metric as **"minimum survivable
distance from actionable error to the nearest output-boundary"** where
`output-boundary` is defined per-family but always reducible to the
same candidate-agnostic SLA (§3.3). The metric is renamed
`margin_to_nearest_output_boundary` to remove the window-shaped
connotation. Per-family output-boundary definitions:

| Family | `output-boundary` definition | Margin computation |
|---|---|---|
| **F-POS / F-SPEC / F-MODE / F-VAR** (window-shaped) | The two edges of the anchor-centered window the candidate emits. | `min(error_pos − window_start, window_end − error_pos)` |
| **F-SEG** (structural) | Whichever structural boundaries the candidate's algorithm uses to delimit truncation (section break, phase header, etc.). | `min(error_pos − prev_chosen_boundary, next_chosen_boundary − error_pos)` |
| **F-POST** (post-truncation re-extraction) | The two edges of the raw tail-N-KB the truncation produces (downstream re-extraction is OUT OF SCOPE for the margin metric — `truncate_logs` is what's being scored). | `min(error_pos − tail_start, tail_end − error_pos)` |

**Single-yardstick property.** All three definitions answer the same
question: "how much breathing room does the actionable error have
before one realistic log-format shift would push it out of the
truncator's output?" The SLA in §3.3 measures this property at the
structural level of the log payload itself; the per-family margin
measures it at the algorithm-output level. Both are reducible to the
same boundary-distance metric, which is why the yardstick stays
single across families. If a candidate's family forces a per-family
adjustment to the margin computation that is NOT reducible to this
same metric, the candidate is held pending Round-3.5 escalation
(§10 step 3a) — the asymmetry would re-enter by the back door.

**Family viability under criterion 4 (Rev-5 B5 fix).** A family is
"viable under §3.5 criterion 4" if there exists at least one
parameterization of a candidate in that family whose theoretical
ceiling on `margin_to_nearest_output_boundary` can reach the
corpus-derived `SLA_min_margin` (§3.3). A family whose smallest
design ceiling falls below the corpus-derived SLA — e.g., F-POS at
a default window-half of 4 KB when SLA derives to 5 KB+ — is
structurally non-viable for this corpus at that parameterization,
and either (a) requires a parameter-extended variant that can clear
SLA to satisfy §6.1 categorical coverage, or (b) is documented as
structurally non-viable, which is itself a Round-3 finding entered
into the DA artifact and `lessons-learned.md`. The viability check
is computed against the SLA the moment §3.3 closes — before §6
opens — so that B3 categorical coverage (§6.1) does not force
dead-on-arrival candidates into the working session.

For each candidate algorithm C and each payload P, produce the tuple:

```
(payload_id, cluster, candidate_id, candidate_family,
 anchor_match_name,                  # name of selected anchor, or None
 selected_position,                  # byte offset of selected anchor end
 actionable_error_position,          # ground-truth byte offset (§3.4)
 truncated_size,                     # bytes in output
 actionable_error_in_window,         # bool: ±256-char neighborhood ⊂ output
 margin_to_nearest_output_boundary,  # int (negative = out of output)
 output_boundary_definition_used,    # per §3.2 family table
 nearest_boundary_distance,          # candidate-agnostic; §3.3 input
 pii_surface_hits,                   # via existing PII probe
 strategy_latency_us)                # wall-clock per truncate_logs call
```

Aggregation: per-candidate row with columns:

- in-window rate (per cluster + overall) — primary metric
- min `margin_to_nearest_output_boundary` (per cluster + overall) — primary metric
- mean / p5 / p95 margin (per cluster + overall) — fragility metric
- mean / p95 PII surface hits — secondary metric
- mean / p95 truncated size in bytes — secondary metric
- p95 latency in microseconds — non-functional metric

### 3.3 SLA derivation (candidate-agnostic; B1 fix)

The minimum margin SLA is derived from the **structure of the log
payloads themselves**, not from any candidate's measured margins.

**Definition — "natural boundary":** the nearest byte offset (relative
to the ground-truth actionable error position from §3.4) where the log
text exhibits one of these structural breaks:

- consecutive newlines (≥ 2 `\n` in a row) — blank-line section break
- ISO-8601-like timestamp at line start (regex
  `^\d{2}:\d{2}:\d{2}` or `^\d{4}-\d{2}-\d{2}`) — new log event
- dbt section header (`==…==` rule lines; `Concurrency:`; `Done.`;
  `Finished running`) — phase boundary

For each ground-truth-labeled payload, measure
`boundary_distance = min(distance_to_prev_boundary, distance_to_next_boundary)`.
This metric is a property of the log payload, not of any algorithm —
it answers "how much slack does the actionable error have before the
nearest natural reformatting could shift its position?"

**SLA formula:**

```
SLA_min_margin = max(
    ceil_to_KB(p5(boundary_distances_across_extended_corpus)) * SAFETY_FACTOR,
    DESIGN_FLOOR
)
```

where:

- `p5(...)` is the 5th-percentile boundary distance across the entire
  extended corpus (not per-cluster, not per-candidate)
- `SAFETY_FACTOR = 1.5` — **design choice. 1.5 chosen as a round
  multiplier; no measured basis. Acceptable range is qualitative
  judgment, not a derived bound (Rev-5 R10 fix).** Rev-3 framed this
  as empirical ("dbt-Cloud has historically added/removed one
  trailing-summary block per minor version"); that claim had no
  citation and was self-review-flagged as dishonest-empirical (R5).
  Rev-4 retained an unattributed "defensible range is 1.25–2.0"
  framing that R10 cross-review caught as the same defect at lower
  amplitude — a quantitative range with no measured basis is still a
  fabricated bound. Honest framing: the multiplier is a judgment
  call with no derived range. **Round-4 trigger condition (R5
  addition):** if empirical evidence of dbt-Cloud log-format
  changes accumulates over a rolling 12-month window such that any
  single observed change exceeds `1.5 × p5(boundary_distances)`,
  re-derive `SAFETY_FACTOR` from the new evidence and re-run §3.3.
  Until that evidence accumulates, 1.5 stands as the chosen design
  point with no false empirical provenance.
- `DESIGN_FLOOR = 1024 B` — **design choice. 1024 B chosen as a
  round design floor sized to comfortably exceed typical short dbt
  error payloads; not measured (Rev-5 R10 fix).** Actionable-error
  line length has NOT been measured against the corpus in this
  pre-announce (Gate-D Round 1 §5.1 contains a field-policy table,
  not an error-line-length measurement — Rev-3 nearly cited it
  falsely, R6 self-review caught it). Rev-4 retained an unattributed
  "200–800 B" range as alleged first-principles support; R10 caught
  that as the same fabricated-bound pattern as the SAFETY_FACTOR
  range. Honest framing: 1024 B is a round design floor; quantitative
  comparison against actual dbt error payload sizes is deferred to
  the working-session measurement below. **Round-4 trigger condition
  (R6 addition):** during the Round-3 working session, measure p95
  actionable-error-line length across the extended corpus (cheap;
  same fixtures as boundary-distance measurement) and append to
  `docs/triage-agent/fixtures/round3_boundary_distances.tsv` as a new
  column. If p95 line length exceeds 1024 B, raise `DESIGN_FLOOR` to
  `ceil_to_KB(p95_actionable_error_line_length)` and re-run §3.3.
  Defer the actual measurement to the working session, not the
  pre-announce — pre-announce locks the methodology, not the data.

`ceil_to_KB` rounds up to the nearest KB so the SLA is expressible in
the same units as `ANCHOR_WINDOW_HALF_KB`.

**Properties this gains over Revision 1:**

- **Candidate-agnostic.** Boundary distances are measured before any
  candidate exists. The number computed is the same regardless of
  which candidate eventually wins.
- **Falsifiable.** Criterion 4 of §3.5 now has teeth: a candidate's
  observed min margin is compared against a number not derived from
  its own measurements.
- **Auditable.** The boundary-distance table for every payload lives
  in `docs/triage-agent/fixtures/round3_boundary_distances.tsv` and
  can be re-computed by anyone with corpus access.

**dbt-format coupling (Round-4 trigger condition; Rev-3 addition;
extended Rev-5 R13).** The three "natural boundary" definitions
above contain dbt-specific log markers (`==…==` rule lines,
`Concurrency:`, `Done.`, `Finished running`). SAFETY_FACTOR = 1.5 is
sized to absorb routine format jitter (one trailing-summary block
added or removed across a dbt minor release). It does NOT cover
structural removal of any of the three marker classes, NOR additive
expansion of the phase-marker set, NOR semantic drift in an existing
marker's appearance pattern. **Round-4 trigger condition:** if a
dbt-Cloud release produces any of —
(a) removal or fundamental rename of the `==` rule line format,
(b) removal or fundamental rename of the `Concurrency:` / `Done.` /
`Finished running` phase markers,
(c) removal or fundamental rename of ISO-8601 timestamp prefixes at
line start,
**(d) addition of a new phase marker between existing markers
(Rev-5 R13 addition)** — e.g., a new `Verifying:` phase between
`Concurrency:` and the run body, which silently shrinks the
prev-boundary-to-error distance for any actionable error in the run
body and invalidates the boundary-distance fixture's p5 derivation
without removing any existing marker,
**(e) semantic change to an existing marker's appearance pattern
(Rev-5 R13 addition)** — e.g., `Done.` appearing mid-run as a
per-model completion notice rather than only at log tail as a
run-completion notice, which changes the marker's role as a
"phase boundary" and again invalidates boundary-distance derivation
without touching the marker's textual form —
the boundary-distance fixture
(`docs/triage-agent/fixtures/round3_boundary_distances.tsv`) MUST be
re-measured and the SLA re-derived before any further `logs`-citing
catalog patterns ship. The coupling is accepted as inherent to a
dbt-specific tool; the trigger condition makes the coupling visible
to whoever re-runs the methodology 18+ months from now.

If no candidate achieves `min_margin_across_extended_corpus ≥
SLA_min_margin` without violating §2 hard constraints, Round 3
escalates to Round 3.5 per §10 step 3a.

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
`docs/triage-agent/fixtures/round3_ground_truth.tsv` (new). TSV chosen
because manual labeling will inevitably need spreadsheet review.

### 3.5 Scoring & winner-selection (locked, before candidates exist)

Candidates are scored on these criteria, in lexicographic order:

1. **Hard-constraint compliance (§2):** any violation = disqualified.
2. **In-window rate on Cluster A (objective O1):** must be 100% on the
   3 Cluster A base-corpus payloads AND ≥ 95% across the extended
   Cluster A corpus. Below 100% on base = disqualified.
3. **In-window rate on Clusters B + C:** must be 100% on base corpus
   AND ≥ 99% across the extended corpus.
4. **Min `margin_to_nearest_output_boundary` across extended corpus
   ≥ SLA_min_margin (§3.3):** below = disqualified. SLA is
   candidate-agnostic per §3.3. Margin metric is per-family-defined
   per §3.2 Option C (Rev-4 B4 fix) but reduces to the same
   single-yardstick boundary-distance metric, so the criterion applies
   uniformly across all six §6.1 families without the asymmetry Rev-3
   inherited from window-shaped semantics.
5. **Mut9a–Mut9d remain CAUGHT** under the candidate (re-run mutation
   harness against candidate code; not a paper review).
6. **Tie-break — mean PII surface hits:** lower wins.
7. **Tie-break — p95 latency ≤ 10 ms:** carried from Day-3.8
   acceptance §4; among compliant candidates, lower wins.
8. **Tie-break — fewest new mutation invariants required to achieve
   floor compliance:** lower wins (simpler is better, all else equal).

Selection rule is total: ties past criterion 8 are resolved by
adjudicator decision and the chosen rationale is recorded as a fresh
[lessons-learned.md](./lessons-learned.md) entry.

---

## 4. Adversarial input shape battery (locked before §6)

Generalized enumeration of input shapes against which every candidate
in §6 is scored. The battery generalizes the Cluster A shape; it is
not restricted to it.

| Shape | Description | Observed in corpus? | Why it threatens anchor selection |
|---|---|---|---|
| **S1 — Front-loaded actionable, back-loaded noise** | Small high-signal block in first N KB; large low-signal payload (manifest telemetry, macro dump, JSON dictionary) in tail. | Yes — Cluster A (3/7) | The Cluster A reproducer. Defeats "last position wins" when the noise contains low-specificity tokens. |
| **S2 — Back-loaded actionable, front-loaded noise** | Large boilerplate header / package banner / startup logs; actionable error in tail. | Plausible (Cluster B/C step 3 currently has ~9.6 KB of dbt run output then `Database Error` near end). | Defeats "first match wins" / "specificity-first hard ordering". Mirror image of S1. |
| **S3 — Multiple actionable errors, interleaved** | Multiple `Database Error` / `Runtime Error` matches, separated by KB-to-MB of intermediate output. | Plausible in multi-model runs. | Forces explicit policy: "first error" vs "last error" vs "most-severe error". Any candidate that doesn't state its rule is incomplete. |
| **S4 — No actionable anchor, only noise** | dbt run with no recognized error keyword (infrastructure failure, dbt-MCP server crash, OOM kill). | Plausible (Cluster D when it appears). | Forces tail-fallback correctness AND prevents accidental empty / full text. |
| **S5 — Actionable error in middle, symmetric noise** | Real error near byte N/2 of ~LOGS_MAX_BYTES-scale payload; comparable telemetry on both sides. | Plausible (single-model failure with large pre+post context). | Forces window-symmetry decisions. Asymmetric tail-biased windows fail here. |
| **S6 — Pathological repeated anchor literal** | Payload contains the literal anchor string (e.g., `Database Error`) hundreds of times inside string literals or template fragments, with the real error elsewhere. | **Per §4.1 census, may already be empirically present in Cluster A** — to be confirmed pre-§6. | Adversarial — defeats any candidate using raw token frequency as a signal. |

**Battery construction.** Each shape gets ≥ 1 base-corpus representative
(where available per §4.1) PLUS ≥ 2 synthetic fixtures constructed to
make the shape pessimal for anchor selection. Synthetic fixtures live
under `docs/triage-agent/fixtures/round3_synthetic/` with provenance
documented (script + seed + shape ID).

**Synthetic-fixture caveat.** Synthetic inputs may unintentionally favor
whichever algorithm the constructor was thinking about. Round-3 DA
(§5.5) explicitly interrogates synthetic fixtures for constructor bias.
Adjudicator review of synthetic fixtures happens BEFORE any candidate
is scored against them.

### 4.1 Anchor-match census on base ∪ extended corpus (R1 + R7, runs BEFORE §6 opens)

Before §6 opens, run a one-shot census that scans all 9 patterns in
`ERROR_ANCHORS` against each payload in **the union of base corpus
(7 payloads) AND extended corpus (per §3.1 sufficiency criterion)**
and categorizes EVERY match as exactly one of:

- **(a) genuine actionable error context** — the match is in or
  adjacent to (within ±256 chars) the ground-truth actionable error
  position labeled per §3.4.
- **(b) telemetry / template string literal** — the match is inside a
  JSON string value, a Python dict repr, a SQL `IN(...)` literal, or
  a logged template fragment. Manual classification with rule
  documented per match.
- **(c) footer summary line** — the match is in a dbt-emitted footer
  line of shape `Finished running … failed`, `Done. PASS=…`, or
  similar summary.

**Classification authority (Rev-5 R11 fix).** Census classification
of any new shape surfaced by the extended-corpus scan is performed
by a **designated reviewer who is NOT the author of the candidate
that proposed (or would benefit from) the shape**. This mirrors the
R9 fix that moved taxonomy completeness testing from author to
cross-reviewer: author-side classification of a shape one's own
candidate either introduces or depends on is the exact bias the
review discipline exists to prevent. The designated reviewer is
named in the §10 working-session opening; the asymmetric
cross-reviewer (Copilot/Gemini) is the default choice but a second
human adjudicator may be substituted if the cross-reviewer is
unavailable.

**Rev-4 R7 fix — scope:** Rev-3 ran census on base corpus only. That
asymmetry (extended corpus pulled for §3 measurement but not scanned
for §4 shape census) wasted the most informative empirical
opportunity in §3. Round-4 fix expands census scope to `base ∪
extended`.

Census output: `docs/triage-agent/fixtures/round3_anchor_census.tsv`,
one row per `(payload_id, anchor_name, match_position, category,
classification_rule, corpus_source)` where `corpus_source ∈ {base,
extended}`.

**Why this matters:** Cluster A manifest dumps almost certainly contain
`"failed"` and `"error"` JSON string values. If census confirms this,
Cluster A's failure mechanism is partially an S6 instance (pathological
repeated anchor literal), not purely an S1 instance (front-loaded
actionable, back-loaded noise). That changes which candidate families
in §6 are most relevant. Treating S6 as purely synthetic when it's
already empirically present would repeat the Round-2 generalization
failure at a different scale. Extended-corpus scan is the first chance
to surface NEW failure mechanisms (call them S7+) not enumerated in
the base-corpus-derived S1–S6.

**Rev-4 R7 fix — escalation threshold for new shapes surfaced by census
(extended Rev-5 R11 with frequency dimension):**

- **≤ 2 new shapes that fit as clear extensions of S1–S6 framing
  (e.g., "S1-variant with multi-line actionable header") AND no
  single new shape exceeds 25% prevalence weight across the
  extended corpus:** amend §4 in place via an inline Rev-N+1
  revision to this pre-announce file, re-circulate briefly for
  adjudicator confirmation, proceed to §6. Threshold rationale:
  minor extensions of an existing shape at low prevalence do not
  invalidate the categorical taxonomy in §6.1; updating the shape
  table is sufficient.
- **≥ 3 new shapes by count, OR ≥ 25% prevalence weight of any
  single new shape across the extended corpus, OR a single new
  family of failure mechanism (e.g., the hypothetical JSON-Lines
  `"status": "error"` case where the actionable error is a
  structured value, not a literal keyword):** Round-3.5 escalation
  per §10 step 3a. Threshold rationale: substantive empirical
  expansion of the design space — whether measured by distinct-shape
  count OR by single-shape prevalence weight — warrants a fresh
  pre-announce. The Rev-5 R11 frequency dimension closes the gap
  Rev-4's count-only threshold left open: two new shapes each at
  80% prevalence (collapsed by count into "2 new shapes, proceed")
  is empirically a much larger taxonomy shift than two new shapes
  each at 1-payload prevalence.

Estimated cost: 1 script + (7 base + extended) payloads + ~30 min
base-corpus classification + ~5 min/payload for extended-corpus
classification (scales with extended N).

---

## 5. DA failure-mode interrogation surface (locked before §6)

The Round-2 DA scoping error is the load-bearing thing this section
exists to prevent. The Round-3 DA must answer EACH of these questions
for EACH candidate in §6 before scoring opens. A DA that skips any
question is incomplete and the candidate is held.

### 5.1 Cross-position selection questions (the Round-2 gap)

For each candidate algorithm C:

- **Q-CP1.** Construct two anchor matches in the same input at byte
  positions p₁ ≪ p₂ where the anchor at p₁ has higher semantic
  specificity than the anchor at p₂. Which does C select? Justify why
  that is correct for **all six** shapes S1–S6, not just the shape
  that inspired the candidate.
- **Q-CP2.** Construct three matches at p₁ < p₂ < p₃ with mixed
  specificity (e.g., specific-generic-specific). Does C's rule produce
  the same winner regardless of intervening noise size? If the rule's
  output depends on byte distance between matches, justify why.
- **Q-CP3.** For shapes S3 + S6, demonstrate that C's selection rule
  does not silently degrade as the number of competing matches grows
  (e.g., O(n²) worst-case scan, or a "most recent" preference that
  flips at some n).
- **Q-CP4.** If C's rule is "specificity-first hard ordering" — what
  happens when the most-specific anchor matches inside a string
  literal embedded in the payload (shape S6, per §4.1 census)? If C's
  rule is "footer-aware" — what happens when the footer line is
  truncated by dbt Cloud before the artifact lands?
- **Q-CP5.** If C ranks anchors by both specificity AND position,
  state the lexicographic order explicitly. Verify against a 4-input
  truth table covering all four combinations of (high/low specificity)
  × (early/late position).

### 5.2 Same-position questions (carried from Round-2 DA — still required)

- **Q-SP1.** Two anchors match at exactly the same end position. State
  the tie-break rule and prove determinism (snapshot tests pass under
  Python dict iteration order changes, regex engine changes, etc.).
- **Q-SP2.** A new anchor is added to `ERROR_ANCHORS`. Does the
  tie-break rule preserve existing winners for inputs that previously
  had no ambiguity? If not, document the migration impact.

### 5.3 Boundary questions (locked)

- **Q-B1.** `text` is exactly `LOGS_MAX_BYTES + 1` bytes. What does
  the candidate return? At `LOGS_MAX_BYTES`, `LOGS_MAX_BYTES - 1`,
  `0`, `1`?
- **Q-B2.** Anchor matches at byte position 0 (very start) or at
  position `len(text)` (very end). Does window math underflow /
  overflow? Mut9a's `±256-char neighborhood` requirement — clamped
  correctly?
- **Q-B3 (R2 fix — input-type framing).** Does the candidate operate
  on `bytes` rather than `str`?
  - If **yes:** demonstrate UTF-8 boundary safety — show how the
    candidate avoids emitting invalid UTF-8 when a slice falls
    mid-codepoint, and document any normalization or
    error-handling-on-decode policy.
  - If **no** (candidate remains `str`-mode like current
    `truncate_logs`): explicitly state "`str`-mode; Q-B3 N/A." The
    current `truncate_logs` is `str`-mode and Python `str` slicing is
    codepoint-safe; the question is only live for candidates that
    move to `bytes`.
  - Bonus: combining characters / emoji in user-supplied model names
    or error messages are rare but possible; `str`-mode candidates
    inherit Python's per-codepoint semantics, which is correct
    behavior for our use case.
- **Q-B4.** Anchor match at position p such that `p − ANCHOR_WINDOW_HALF_KB·1024
  < 0` AND `p + ANCHOR_WINDOW_HALF_KB·1024 > len(text)`. The output
  is the full text; is that ≤ LOGS_MAX_BYTES?

### 5.4 Latency questions (locked)

- **Q-L1.** Candidate's worst-case time complexity on a 2.9 MB
  payload with K anchor patterns, M matches per pattern. Bound it.
- **Q-L2.** Regex catastrophic backtracking — does any candidate add
  a pattern admitting exponential backtracking on a constructible
  adversarial input? (Especially relevant if any candidate proposes a
  "footer-aware" regex with `.*` segments.)
- **Q-L3.** Is the candidate's behavior stable under Python regex
  cache invalidation (long sessions, many distinct patterns)?

### 5.5 Synthetic-fixture-bias questions (locked)

- **Q-SF1.** For every synthetic fixture in §4, identify the
  algorithm the constructor was most likely imagining. Does the
  fixture also exercise a behavior the OTHER candidate would get
  right? If not, construct a paired fixture that does.
- **Q-SF2.** Are any synthetic fixtures missing a real-corpus analog?
  If so, what would a real payload of this shape look like, and is it
  plausible to encounter one in DEV / QA / PROD?

---

## 6. Candidate enumeration & scoring (OPENS ONLY AFTER §3–§5 LOCK)

This section is **deliberately empty** at pre-announce time. Filling
it is the first activity of the Round-3 working session AFTER
adjudicator sign-off on §3 / §4 / §5.

### 6.1 Working rules (B3 fix — categorical coverage, not count)

- Pre-announce enumerates the design space from scratch. The two
  directions surfaced informally during P0.1 analysis
  ("specificity-first hard ordering"; "footer-aware `generic_failed`")
  enter §6 as **two among the families enumerated below**, not as the
  seed set.

- §6 must include ≥ 1 candidate from each of the following
  algorithmic families **that is viable under §3.2 criterion 4 given
  the corpus-derived SLA (Rev-5 B5 fix)**, OR explicit written
  justification (referencing §2 hard constraints, or §3.2 family
  viability) for why that family is inapplicable. A family
  documented as structurally non-viable under the corpus-derived SLA
  per §3.2 satisfies coverage by the non-viability finding itself —
  no dead-on-arrival candidate is required. Counting candidates does
  not satisfy this rule; **two candidates from the same family count
  as one for coverage purposes.**

  **Spanning-candidate accounting (Rev-5 R12 fix).** A single
  candidate whose design clearly spans more than one §6.1 family
  (e.g., a two-stage detect-and-rewrite that combines F-MODE
  branching with F-SEG structural truncation in one branch) counts
  **for exactly one family** for §6.1 coverage purposes. Which
  family it counts for is a working-session adjudicator choice,
  recorded with rationale in `gate-d-round3-da.md` alongside the
  candidate's pseudocode. The other family it spans still requires
  its own coverage candidate (or a non-viability finding per §3.2).

  | Family | Description (Rev-4 tightened per R8 where marked) | Example |
  |---|---|---|
  | **F-POS** Position-based selection | Selection rule depends only on byte position. | Last match, first match, fixed-window-positional |
  | **F-SPEC** Specificity-based selection | Selection rule is a total order on anchor specificity, position used only as tie-break (or not at all). | Specificity-first hard ordering, weighted specificity |
  | **F-SEG** Segmented / structural | Selection respects log structure (sections, phases, footer lines). | Footer-aware `generic_failed`, section-boundary-aware window, log-phase detector |
  | **F-MODE** _Algorithm-per-branch_ mode switching (Rev-4 R8) | Detect a payload property (length, cluster signature, etc.), then dispatch to a **structurally different ALGORITHM** per branch. The branches differ in selection logic, not just numeric parameters. | Branch on `len(text) > THRESHOLD`: short-payload → F-POS-style last-match; long-payload → F-SEG-style footer-aware. The two branches use DIFFERENT algorithms. |
  | **F-VAR** _Parameters-per-branch_ variable window (Rev-4 R8) | Detect a payload property (cluster signature, etc.), then dispatch to the **same algorithm with DIFFERENT PARAMETERS** per branch (anchor table membership, window size, weights). Algorithm structure identical across branches. | Cluster-A-aware specialized anchor list with smaller window; default anchor list + standard window for B/C. Same underlying scan algorithm; different anchor / window inputs. |
  | **F-POST** Post-truncation re-extraction | Truncate by tail-fallback (or similar simple rule), then have downstream LLM / regex extract the actual error block. Architecturally moves the problem rather than solving it in truncation. | Tail-64 KB truncate + downstream re-extractor stage |

  **F-MODE vs F-VAR boundary (Rev-4 R8 self-review fix).** Rev-3
  defined these two families ambiguously enough that a candidate
  could cover both with a single design ("detect-then-dispatch with
  different params"). The Rev-4 tightening makes the distinction
  crisp: **F-MODE = different algorithm per branch; F-VAR = same
  algorithm with different parameters per branch.** Coverage now
  requires a distinct candidate for each family. If a real candidate
  proposed during enumeration resists clean classification (e.g.,
  partial algorithm change + parameter change), document it as a
  third candidate spanning the boundary and surface as a taxonomy-
  completeness finding per the next bullet.

  A candidate that fits no family is documented as a NEW family with
  rationale.

- Each candidate carries: pseudocode; pseudocode complexity bound;
  list of new mutation invariants needed; explicit answers to all of
  Q-CP1…Q-SF2; worked examples for each of S1–S6 (with S6 examples
  drawn from §4.1 census if available, not pure synthesis).
- Scoring uses §3.5 yardstick verbatim. **Yardstick is NOT
  renegotiated against candidates.**
- If the winning candidate disqualifies on any criterion 1–5,
  Round 3 escalates to Round 3.5 per §10 step 3a — does NOT relax the
  yardstick.

**Taxonomy-completeness test (Rev-4 R9 fix — moved to cross-reviewer).**
The Rev-3 working rules asserted taxonomy completeness without testing
it; the Rev-4 R9 self-review noted that author-side testing of own
taxonomy is the exact failure mode the test exists to catch.
Replacement rule:

> Before §6 scoring opens, the **cross-reviewer** of §6 enumeration
> (Copilot/Gemini at §10 step 2 for the pre-announce taxonomy itself;
> the alternating reviewer at §10 step 3 for the enumerated
> candidates) MUST attempt to construct at least one candidate that
> resists classification into the six §6.1 families, OR document why
> such construction is genuinely difficult given the taxonomy. A
> taxonomy that classifies every attempted candidate trivially fails
> its own completeness test — the working session pauses to
> interrogate whether the taxonomy is gerrymandered or whether the
> design space is genuinely covered.

This places the test in the right hands (cross-reviewer, not author)
and gives it teeth (an attempt to resist, not just an assertion of
completeness).

---

## 7. Round-3 8-gate matrix (annotated deltas vs Day-3.8 `ac2c384c`)

| Gate | Day-3.8 form | Round-3 refinement |
|---|---|---|
| **1. Devil's Advocate** | "caught PR-marker-alone false-fire risk; added counter-test" | **EXPANDED** — written answers to every Q-CP1…Q-SF2 in §5 for every candidate in §6 before §6 scoring opens. DA artifact lands as a new file `docs/triage-agent/gate-d-round3-da.md` co-committed with the algorithm change. **This is the gate that Round-2 weakened.** |
| **2. Validator stress** | "2/2 positive, 5/5 negative, 0 false positives across all 7 redacted fixtures" | **EXPANDED** — winning candidate validated against (a) base corpus (7 payloads, 100% in-window required), (b) extended corpus (§3.5 thresholds), (c) all S1–S6 synthetic fixtures, (d) `NO_GROUND_TRUTH` fallback fixtures, (e) §4.1 census categorizations confirmed in candidate selection rationale. Sentinel / redaction counts reported per cluster. |
| **3. Code Reviewer** | "YAML follows header schema; tests follow existing class layout" | **EXPANDED (R3)** — PASS on `code_reviewer.py` against changed files PLUS verify all five BLOCK surfaces are unwound by the landing commit: (i) NOTICE block in [redact.py](../../scripts/automation/src/triage/redact.py) REMOVED (not edited); (ii) `sprint-1-deferred.md` item #14 moved to "Closed items" with landing commit SHA; (iii) `v2-plan.md` §1.3 BLOCK annotation removed; (iv) `lessons-learned.md` 2026-06-05 entry retained as historical record (do NOT delete) with a Round-3 closing addendum; (v) `fbin_error_catalog.py` Mut9d runtime gate **NOT modified** (HC-2 carries forward). Landing without all five surfaces unwound = Gate 3 FAIL even if code review is clean. |
| **4. Code Smell** | "no new functions; flat per-class test structure" | **UNCHANGED** — applies per candidate. Function > 50 lines requires justification or split. |
| **5. Regression** | "1046 passed, 2 skipped — up from 1026, delta +20" | **UNCHANGED in form** — full pytest run must pass. Test count delta reported. Expected delta ≥ +6 (Mut10a–Mut10c candidate-specific invariants + in-window + min-margin + ground-truth tests). Exact number set by winning candidate. |
| **6. Mutation harness** | "Mut1-Mut7 all CAUGHT via TestMutations / 11 tests" | **EXPANDED — floor and ceiling shift.** Floor stays `12/12` (HC-3); ceiling grows to `≥ 12 + K` where K is the count of new invariants the winning candidate requires. Each candidate declares its own K up-front (typically 2–4). Mutation report uses the "all CAUGHT" framing from `ac2c384c`. |
| **7. Contract** | "PatternMatch.classification = Classification enum verified for pattern 2" | **REFRAMED** — Round 3 does not ship a catalog pattern (HC-2). Contract gate verifies: (a) `truncate_logs` return-type tuple structure unchanged; (b) ordering invariant (HC-5) intact: allowlist → truncate → sentinel → email; (c) `redact_early_failure` callers see no signature change; (d) `_find_last_anchor_end` (if retained) keeps its return shape, or the replacement is documented in `redact.py` module docstring + gate-d-logs-field-amendment.md. |
| **8. Snapshot** | "test_shipped_catalog_count_snapshot pins count=2" | **REFRAMED** — Round 3 adds a NEW snapshot: `test_round3_in_window_snapshot` pins per-payload `(payload_id, candidate_anchor_name, in_window=True, margin ≥ SLA)` for the base corpus. Day-4 shipped-catalog count remains pinned at 2 (no change — HC-2 keeps catalog frozen). |

Landing-commit body reports all 8 gates in `ac2c384c` format, plus a
new "P0.2 inspection" line documenting the §3.2 measurement protocol
re-run against the winning candidate on the extended corpus, with the
resulting `in-window rate / min margin / SLA` triple.

---

## 8. Deliverables & landing commit

The Round-3 landing commit (single commit, conventional-commit style)
modifies these files, no more:

- `scripts/automation/src/triage/redact.py` — replacement algorithm;
  NOTICE block removed; `truncate_logs` docstring updated.
- `scripts/automation/tests/test_triage_redact.py` — new mutation
  invariants Mut10a+ per winning candidate; new in-window + min-margin
  snapshots; existing Mut1–Mut9d preserved.
- `scripts/automation/tests/test_triage_matcher_perf.py` — re-baseline
  p95 latency target if winning candidate changes it.
- `docs/triage-agent/gate-d-logs-field-amendment.md` — new §6
  ("Round 3 — anchor selection redesign") added AFTER §3.2. §3.2
  remains as the falsified historical record with a cross-reference
  to §6. Appendix B (extended corpus provenance) appended.
- `docs/triage-agent/gate-d-round3-da.md` — new file; full DA artifact
  (§5 answers per candidate).
- `docs/triage-agent/fixtures/round3_ground_truth.tsv` — new file.
- `docs/triage-agent/fixtures/round3_boundary_distances.tsv` — new
  file (B1 fix; candidate-agnostic SLA input data).
- `docs/triage-agent/fixtures/round3_anchor_census.tsv` — new file
  (R1 fix; produced before §6 opens, carried into commit).
- `docs/triage-agent/fixtures/round3_synthetic/*` — new directory;
  one fixture per S1–S6 plus paired anti-bias fixtures per Q-SF1.
- `docs/triage-agent/sprint-1-deferred.md` — item #14 moved to
  "Closed items" with landing commit SHA.
- `docs/triage-agent/lessons-learned.md` — new entry capturing what
  Round 3 surfaced beyond the Round-2 scope gap.
- `docs/triage-agent/round-3-handoff.md` — superseded; either deleted
  or marked CLOSED with a forwarding note to the landing commit.
- `docs/triage-agent/v2-plan.md` §1.3 — BLOCK annotation removed.

The Mut9d catalog-load-time gate in `fbin_error_catalog.py` is **NOT
modified**. HC-2 remains in force until a follow-up commit ships the
first `logs`-citing catalog pattern with its own gate-passing
evidence.

---

## 9. Out-of-band notes

- **Token environment.** `~/scratch/triage-day4/` payloads were
  re-pulled 2026-06-04 under the rotated dbt PAT after the
  [security-incident-2026-06-04](./security-incident-2026-06-04.md).
  Extended-corpus pulls in §3.1 use the same rotated PAT and follow
  Sprint-1 #13 production-token migration constraints.
- **Asymmetric cross-review continuation.** Copilot/Gemini's review of
  this pre-announce is itself the load-bearing gate Round 2 didn't
  get. Adjudicator-recorded outcome of that review lands as a
  pre-§6-scoring decision artifact (separate from the landing commit).
- **No code touches in this session past pre-announce sign-off.**
  Candidate enumeration (§6) starts in a fresh session after §3/§4/§5
  are adjudicator-locked.

---

## 10. Sign-off ladder (R4 fix — Round 3.5 branch explicit; Rev-5 Z1 — step 1.5 methodology operability check inserted)

1. Adjudicator (user) reviews §1–§9. Lands edits if §3/§4/§5 need
   tightening.

   **1.5. Methodology operability check (Rev-5 Z1 fix).** After
   adjudicator sign-off on §3/§4/§5 and BEFORE the asymmetric
   cross-review of step 2 fires, run a one-shot operability check
   of the locked methodology against the **base corpus** (the
   7 P0.1 payloads — no extended-corpus pull yet). The check
   answers four questions, each with an explicit pass/fail threshold:

   **(a) What 1.5 measures:**

   1. **Bootstrap CI width on n = base.** Compute
      `boundary_distance` per §3.3 for each of the 7 base-corpus
      payloads, bootstrap-resample `p5(boundary_distances)` with
      ≥ 1,000 iterations, report 95% CI width in KB. The §3.1(a)
      target is ≤ 2 KB on the *extended* corpus; on n = 7 the
      width will exceed that, and the question is "by how much."
   2. **Distribution shape inspection for bimodality.** Plot the
      7 boundary-distance values; report whether the empirical
      distribution shows a single mode, suggests bimodality
      (e.g., Cluster A values cluster separately from B/C
      values), or is too small to call. A bimodal base-corpus
      distribution implies `p5` on the pooled extended corpus may
      be a meaningless central tendency, and per-cluster SLA
      derivation may be the correct response.
   3. **NO_GROUND_TRUTH rate on the base corpus.** Run the §3.4
      labeling rules against the 7 base payloads and count
      `NO_GROUND_TRUTH` outcomes. The §3.4 SLA-invalidation
      threshold is > 10% on the extended corpus; the base-corpus
      rate is a leading indicator.
   4. **Census budget feasibility.** §4.1 estimates ~5 min/payload
      for extended-corpus classification. Time the actual base-corpus
      classification of one payload end-to-end; multiply by the
      projected extended-corpus N (target per §3.1(a) bootstrap
      sufficiency) to produce a working-session budget estimate.
      Report whether the estimate fits within the working-session
      time budget allocated by the adjudicator.

   **(b) What triggers Rev-5+ inline amendment vs Round-3.5
   escalation** (explicit thresholds, NOT "decide in the moment"):

   | Operability finding | Triggers |
   |---|---|
   | (1) Base-corpus CI width ≤ 4 KB | Proceed to step 2 (cross-review). Methodology is operable; extended-corpus pull will tighten further. |
   | (1) Base-corpus CI width > 4 KB AND ≤ 8 KB | **Rev-5+ inline amendment** to §3.3 to either (i) raise the per-cluster sufficiency target above 2 KB with documented rationale, OR (ii) commit to per-cluster SLA derivation if (a)(2) also indicates bimodality. Re-run step 2 against the amended revision. |
   | (1) Base-corpus CI width > 8 KB | **Round-3.5 escalation** per §10 step 3a. SLA derivation methodology is too noisy at this scale to lock; design space requires re-opening. |
   | (2) Clearly bimodal | **Rev-5+ inline amendment** to §3.3 to require per-cluster SLA derivation (not pooled p5). Re-run step 2. |
   | (2) Single mode or inconclusive | Proceed to step 2; document caveat in step-2 framing. |
   | (3) Base-corpus NO_GROUND_TRUTH rate > 25% (i.e., ≥ 2 of 7) | **Round-3.5 escalation**. §3.4 rules are insufficient; ground-truth labeling protocol needs redesign before extended-corpus pull is worth running. |
   | (3) Base-corpus NO_GROUND_TRUTH rate in (10%, 25%] (i.e., exactly 1 of 7) | **Rev-5+ inline amendment** to §3.4 adding a fourth labeling rule covering the observed unlabeled case. Re-run step 2. |
   | (3) Base-corpus NO_GROUND_TRUTH rate ≤ 10% (i.e., 0 of 7) | Proceed to step 2. |
   | (4) Census budget estimate within working-session time budget | Proceed to step 2. |
   | (4) Census budget estimate exceeds working-session time budget by ≤ 2× | **Rev-5+ inline amendment** to §4.1 reducing extended-corpus N (re-target §3.1 sufficiency to the largest N that fits the budget) and document the precision loss. Re-run step 2. |
   | (4) Census budget estimate exceeds working-session time budget by > 2× | **Round-3.5 escalation**. Census protocol needs structural simplification (e.g., automated category-(b) detection via JSON-string-context heuristic) before §6 can open. |

   Multiple simultaneous findings: any single Round-3.5 trigger
   escalates regardless of other findings. Multiple
   Rev-5+-inline-amendment triggers compose into a single Rev-N+1
   revision touching all relevant sections.

   **(c) Timing.** Step 1.5 runs against the **base corpus only**
   BEFORE the extended-corpus pull (referenced as Z1 in the
   adjudication) begins. The extended-corpus pull is committed
   spend (dbt Cloud Admin v2 API throughput + sentinel-scan time +
   SHA256 manifest); running it before 1.5 confirms methodology
   operability burns that spend on a methodology that may need to
   be re-derived. 1.5's base-corpus measurements use fixtures
   already on disk in `~/scratch/triage-day4/` and the §3.4
   labeling rules already locked — no new corpus pull required.
   Step 1.5 output lands in
   `docs/triage-agent/fixtures/round3_operability_check.md` as a
   new file before step 2 opens.

2. Asymmetric cross-review (Copilot/Gemini) pushes back on §3/§4/§5
   AND on step 1.5's findings. Adjudicator resolves divergences.
   **This is the Round-3 equivalent of the Round-2 gate that didn't
   fire.**
3. Adjudicator opens §6 by signaling "open Round 3 candidate
   enumeration." Candidates produced per §6.1 categorical coverage;
   DA artifact authored per-candidate; §3.5 scoring runs.

   **3a. Round 3.5 escalation branch.** If §3.5 scoring disqualifies
   ALL candidates against criteria 1–5, HALT before landing-commit
   drafting. Open a Round-3.5 pre-announce with revised §6 working
   rules — typically expanding the design space (e.g., relaxing HC-5
   ordering invariant under explicit adjudicator decision; splitting
   `truncate_logs` into cluster-detected sub-routines; introducing a
   downstream re-extraction stage). **Round 3.5 produces its own
   pre-announce subject to its own adjudicator review (analogous to
   §10 step 1 of this ladder), its own asymmetric cross-review
   (analogous to step 2), and its own candidate enumeration opening
   (analogous to step 3), before reaching landing-commit drafting.**
   (Rev-4 N1 fix: rewrote Rev-3's self-referential "goes through §10
   1–3" phrasing, which read like infinite recursion to a future
   reader.) **The yardstick (§3.5 criteria 1–5) is not relaxed under
   deadline pressure** — yardstick relaxation requires its own
   pre-announce + DA cycle.

4. Winning candidate moves to landing-commit drafting. Gates 1–8 run
   against the candidate code in a separate working session. Landing
   commit posted as a PR commit on PR #1771 (which stays the open PR;
   no new PR).
5. Sprint-1 #14 closes; NOTICE block removed; first `logs`-citing
   catalog pattern moves to a follow-up commit/PR with its own gate
   matrix.

---

**End pre-announce REVISION 5. Gemini-adjudication blockers
(B1+B2+B3) and refinements (R1+R2+R3+R4) carried forward from
Revisions 2–3. Claude-self-review blocker B4 (§3.2 Option C —
single yardstick across all six families via per-family
output-boundary definition) and refinements R5–R9 + N1–N2 carried
forward from Revision 4. Copilot-cross-review + Claude-adjudication
blockers (B5: §3.2 + §6.1 — restrict B3 categorical coverage to
families viable under §3.2 criterion 4 given corpus-derived SLA;
Z1: §10 step 1.5 methodology operability check inserted with
explicit Rev-5+ inline-amendment vs Round-3.5 escalation
thresholds) and refinements (R10: §3.3 stripped unattributed
quantitative ranges from SAFETY_FACTOR and DESIGN_FLOOR rationale;
R11: §4.1 census classification authority assigned to a designated
reviewer who is NOT the proposing candidate's author + frequency-
weighted escalation threshold; R12: §6.1 spanning-candidate
accounting — one family per spanning candidate, working-session
adjudicator choice with rationale in DA artifact, bound to the
same §6.1 edit as B5; R13: §3.3 dbt-format Round-4 trigger extended
with additive new phase marker and semantic change clauses) applied
in this revision. N3 (working-session enforcement question)
deferred to §6 working session opening per adjudication. No code
touches. No §6 candidates locked.**

**Awaiting §10 step 2: asymmetric cross-review by Copilot/Gemini
against this committed Revision 5. The asymmetric review re-fires
against the full Revision 5, not just against the Rev-4 → Rev-5
diffs — particularly stress-testing whether (i) the B5 viability
restriction in §3.2 + §6.1 genuinely closes the B3 ↔ criterion 4
interaction without re-introducing structural asymmetry, (ii) the
Z1 step 1.5 thresholds in §10 are tight enough to prevent the
methodology-vs-data lock that defined the Round-2 failure mode at
one level up, and (iii) the R10 framing reduction does not silently
remove guidance the working session will need. Substantial pushback
warrants Revision 6; nitpicks don't block §10 step 3.**
