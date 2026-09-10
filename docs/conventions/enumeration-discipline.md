# Enumeration discipline (consumer-of-multi-exit-producer)

**Status:** Ratified (2026-06-19)
**Originally banked:** v3.2 of the C1.5 spec
**Enforcement:** human-only (reviewer practice on consumer specs)

## Rule

When specifying a consumer of a multi-exit-path producer, **enumerate
the producer's full exit-category set first** before specifying the
consumer's behaviour for any of them.

For a synchronous Python function, the exit categories are finite (4):

1. Normal `return` (including each distinct return value/type the
   producer's contract documents).
2. Raise of an exception type the producer's contract names.
3. Propagation of an exception from a callee that the producer
   doesn't catch (`Exception` subclass).
4. Propagation of `BaseException` (`KeyboardInterrupt`, `SystemExit`,
   `GeneratorExit`) — Python guarantees these propagate past every
   `except Exception` handler, so a consumer must either be safe
   under abrupt termination or document that it isn't.

Async functions and generators add categories (cancellation, partial
generator output, `__aexit__`); the principle is the same — the
category space is finite per language construct.

## Why "enumerate first"

The defect class this rule exists to prevent:

> *Consumer specified against the producer's HAPPY PATH only.  A path
> the producer can take in production is left undefined for the
> consumer because it never appeared in the spec author's mental
> model.*

This is the C1.5 gap-class that surfaced in cycles C3 → G1 → H1 → H7
of spec v3.4: each cycle found a row that hadn't been considered
because the prior round had not enumerated the producer's full exit
category space.  Once the category set was made finite and exhaustive,
gaps stopped surfacing — not because the spec became perfect, but
because there were no more category cells to fall through.

The enumeration converts an open-ended gap-search ("what else might
the producer do?") into a finite completeness check ("for each cell
in the 4-category table, is the consumer's response specified?").
The completeness check has a **provable terminal state**: when every
cell is filled, the consumer's contract is total over the producer's
full exit space.

## Promotion record

| Data point | Cycle | Bug class | Falsifiable prediction made? |
|------------|-------|-----------|------------------------------|
| 1 | C1.5 spec v3.2 → v3.3 | TypeError on non-dict input was not specified for the consumer | Banked: "if consumers are spec'd against a finite exit-category list, the next cycle will surface fewer category-class gaps" |
| 2 | C1.5 spec v3.3 → v3.4 | `Exception` propagation from internal helpers (`_detect_mode`, `_project_payload`, `_MATCHER.match_all`, `_classified`) was outside the redactor try/except | **Confirmed:** category gaps converged from 3-per-cycle to 1-per-cycle |
| 3 | C1.5 spec v3.4 (final) | `BaseException` propagation (intentional design: don't catch) was missing from the path table | **Confirmed:** with all four categories enumerated, the v3.4 DA pass surfaced no new category-class gaps |

Three data points + two confirmed falsifiable predictions = promotion
threshold met.

## How to apply this rule

When writing a consumer's contract against a producer:

1. **List the producer's exit categories first.**  For sync Python
   functions, the canonical four-cell list is the floor.  Add
   producer-specific cells (e.g., distinct return values that are
   semantically different — `None` vs valid record vs sentinel).

2. **Specify the consumer's behaviour for each cell.**  Specify
   "propagate" or "no-op" or "fail-open with rationale-X" — but
   specify *something* for every cell.  An undefined cell is a bug
   waiting to ship.

3. **Encode the cells as tests one-per-row.**  The path-table in the
   spec stops being a thing reasoned about and becomes a thing the
   test suite enforces.  Mutation tests on each category cell are
   cheap and high-yield.

4. **Stop specifying when every cell is closed.**  This is where the
   stopping-point candidate (below) ties in: enumeration converges,
   and the convergence point is the right time to move from spec
   refinement to build-and-test.

## Packet proof

The C1.5 spec's `triage_failure` function went from a 3-row exit table
in v3.1 (return classified / return unknown / fire sentinel) to a
10-row exit table in v3.4 covering all four sync exit categories.
Each of the seven added rows came from this enumeration discipline
applied iteratively, and each addition would have been a production
incident or debugging session if the consumer had shipped against the
3-row table.  The four most important paths added:

- Row 8: **operational dead-letter for `except Exception`** — caught
  the case where a redactor-internal helper has a bug and would
  otherwise crash the polling loop.
- Row 9: **`BaseException` does not propagate through `except
  Exception`** — designed and tested behaviour, but missing from the
  table; row 9 promotes the design decision to a verifiable contract.
- Row 1: **`TypeError` on non-dict input** — surfaces malformed input
  loudly rather than silently coercing, and the row pins
  `_unknown(rationale='triage_failure expects dict, got X')` as the
  consumer's response.
- Row 6: **redactor fail-open** — `Exception` from the redactor
  becomes `RCARecord(outcome=UNKNOWN_HANDED_TO_HUMAN)` with rationale
  carrying `exc_type` ONLY (not `str(exc)` — un-sentinel-checked
  content by construction).

## Application beyond this codebase

The rule is general to any multi-exit consumer.  The 4-category sync
Python set is the most common shape in this repo; other shapes
(language, runtime, IPC) have their own finite sets.  The discipline
is "make the set finite, enumerate it, specify each cell," not "use
exactly four cells."

---

# Stopping-point discipline (build-surfaces-residuals-cheaper)

**Status:** Ratified (2026-06-19)
**Originally banked:** v3.2 of the C1.5 spec
**Adjudicated:** 2026-06-19 (post-C7, end-of-build)
**Enforcement:** human-only (reviewer practice on spec-freeze decisions)

## Rule

**Adversarial spec-refinement has a stopping point, and the stopping
point is when the marginal finding drops from "bug that ships" to
"documentation of invariants the test suite would enforce anyway."**
Past that point, the rigor should move from reading to building.  A
discipline that only knows how to find the next gap will always find
one — the language's grammar guarantees it — which is precisely why
"we reached a provable terminal state" via the
enumeration-discipline rule above is the right moment to notice that
further reads will produce diminishing returns and let the tests do
the rest.

## Why this is paired with the enumeration discipline

The enumeration discipline converges on a complete table; this
candidate is the guardrail that keeps the convergence from becoming a
loop.  Promoting the enumeration rule without the stopping-point
candidate would set up a discipline that could mechanically refine a
spec past the point where refinement pays for itself.  Both rules
should be read together; one says "make the set finite," the other
says "and stop when the cells are filled."

## Falsifiable prediction (CONFIRMED 2026-06-19)

> *If we stop spec-refinement at the knee of the marginal-find
> curve, the build phase surfaces remaining issues at lower marginal
> cost than further DA cycles would have.*

The build phase of v3.4's seven components (C1 through C7) was the
experiment.  Outcome: **confirmed** — see Adjudication below.

### Measurement protocol

For each bug surfaced during the build of v3.4's components, record
a one-line classification:

- **`DA-catchable`** — would a hypothetical v3.5 DA pass have caught
  this?  `yes` / `no` / `unclear`.
- **`fix_cost`** — minutes / hours / days.
- **`category`** — the producer-exit category (or analogous category
  for non-Python concerns) the bug belongs to.

Promotion criterion: the prediction confirms only if **the
DA-catchable bugs were cheap (minutes-class) AND the
non-DA-catchable-at-spec-time bugs dominated the build's bug count.**
Either inversion (catchable bugs were expensive, OR catchable bugs
dominated count) is evidence the freeze was called too early — the
candidate fails its prediction and is re-banked with a refined
trigger condition.

### Where to record measurements

A line per build-phase bug, appended to a section in this file
titled `### Build-phase bug ledger (open while candidate is
unresolved)` until the candidate is promoted or refuted.  The ledger
is local to this rule's life-cycle and is removed on promotion (the
ratified rule will not need an ongoing ledger).

### Build-phase bug ledger (open while candidate is unresolved)

#### Denominator hygiene — what counts as a test of Lesson 2's prediction

Lesson 2's prediction is: *if we stop spec-refinement at the knee of the
marginal-find curve, the build phase surfaces remaining issues at lower
marginal cost than further DA cycles would have.* For that prediction to
be tested honestly, the ledger has to distinguish two categories of
ledger entry:

- **In-denominator (surprises the build surfaced).** Items the build
  uncovered that we *did not already know about at spec-freeze time*.
  These are the entries that actually test the prediction — they are the
  population of issues against which "lower marginal cost than further
  DA cycles" is measured. Each in-denominator entry is either evidence
  *for* the prediction (DA-uncatchable + cheap, or DA-catchable + cheap)
  or evidence *against* it (DA-catchable + expensive, or
  catchable-and-dominant by count).

- **Out-of-denominator (known-and-deferred carries, or net-zero
  verifications).** Items where either (a) the question was open at
  spec-freeze time and the build's job was to verify the answer in the
  bytes, or (b) the spec explicitly deferred a fix to a later component.
  These do not test the prediction in either direction: a deferred-by-
  design carry is neither a surprise the build caught nor a bug that
  shipped, and a byte-verification that resolves to "no change needed"
  is also neither. Recorded for traceability and for component-state
  reasoning, but excluded from the prediction's denominator.

Promotion / refutation reads only the **in-denominator** rows.

#### In-denominator: surprises the build surfaced

| # | Date | Component | Surprise | DA-catchable? | Fix cost | Category |
|---|------|-----------|----------|---------------|----------|----------|
| 1 | 2026-06-19 | C1 | Python runtime is 3.14.0, not 3.11+ as the working assumption held. On 3.14 `f"{m}"` produces `'EvidenceMode.ARTIFACT_PROJECTION'` (35 chars, overflows `VARCHAR(32)`); the `.value` lock was the right escape but the framing changed from "3.10 landmine" to "live 3.14 corruption risk + DDL column overflow." | **NO** — a DA pass reads code, not runtime; no spec review reaches the interpreter version | minutes (reframed a flag, no design change) | environment-not-spec |
| 2 | 2026-06-19 | C1 | The `@unique` test could not use the dynamic-class form (`class _Dup(str, type(EvidenceMode).__mro__[1])`) because Python 3.14 raises `TypeError: multiple bases have instance lay-out conflict`. Replaced with the observable-consequence form (`__members__` length + value-set equality). | **NO** — DA reads test design intent, not interpreter type-system specifics that surface only on class synthesis | minutes (one-test substitution) | environment-not-spec |
| 3 | 2026-06-19 | C6 | Pagination offset-stride bug in the poll-loop's paginate-until-seen helper: offset arithmetic translated the spec's "paginate, caps 100/page" into a stride that silently skipped runs at page boundaries (genuine correctness bug — silent data loss, not a crash). Caught by the build's own DA gate before any test exercised the bug shape. | **NO** — the spec correctly said "paginate, caps 100/page"; the bug was in the implementation-level offset arithmetic, which doesn't exist at spec time. A v3.5 DA pass would have read the spec, found it correct, and moved on. | minutes (off-by-one correction in the helper, plus a regression test pinning the page-boundary case) | implementation-not-spec |

*All three entries are the right shape for Lesson 2's prediction — what the build surfaced is structurally invisible to spec review, and all three were cheap. Entry 3 is the strongest evidence: a genuine correctness bug (silent data loss), provably uncatchable by spec-reading (the spec said the right thing; the bug was in implementation arithmetic), caught by the build's own gate at minutes-cost rather than in production.*

#### Out-of-denominator: known-and-deferred carries, byte-verifications

| # | Date | Component | Item | Status | Cost | Category |
|---|------|-----------|------|--------|------|----------|
| C2.a | 2026-06-19 | C2 | Redactor dispatch turned out to be a no-op: `redact_early_failure(payload: dict)` is shape-agnostic (single `_redact_node` recursion; docstring states "Same policy as artifact mode"). No separate `redact_artifact` exists or is needed — the same redactor handles both EARLY_FAILURE and ARTIFACT_PROJECTION shapes. (Function name `redact_early_failure` is misleading for a shape-agnostic redactor; renaming is its own cleanup PR, not this arc's job.) | **byte-verification, no-change** — the dispatch question was open at spec time; build's job was to verify in the bytes; verification resolved to "no scaffolding needed." Net-zero LOC. | zero (no change written) | scope-boundary |
| C2.b | 2026-06-19 | C2 | Empty-projection rationale string at `triage_failure` line ~416 says `"data.run_steps[-1] or data"` — shape-honest for EARLY_FAILURE but misleading on the ARTIFACT_PROJECTION path (which walks `data.failed_steps[0].results[0]`). | **resolved by C3 (2026-06-19)** — Gap-B `evidence_mode` propagation threaded `mode` through `_classified`/`_unknown`; the empty-projection rationale now uses `_evidence_source_phrase(mode)` (one place, mode→walk lookup) and names the artifact walk on the ARTIFACT_PROJECTION path. Mutation B locks the rationale-source contract. **Stays out-of-denominator** — a deferred-by-design carry moving to "resolved" is a scheduled outcome, not a build-surfaced surprise; doesn't move Lesson 2's prediction needle in either direction. | minutes (C3's mode-threading work; closed alongside Gap-B) | deferred-by-design (resolved) |

*Neither row tests Lesson 2's prediction. Row C2.a is a byte-verification that resolved to "no change"; row C2.b is a known-at-spec-time item explicitly deferred to C3. Recorded for traceability and for C3 directive scope (C3 now also owns C2.b's rationale-string fix as part of mode propagation), but excluded from the prediction's denominator.*

#### Final ledger status (end-of-build, 2026-06-19, post-C7)

- **In-denominator:** 3 entries across 7 components (C1 × 2, C6 × 1). All three DA-uncatchable, all three minutes-class.
- **Out-of-denominator:** 2 entries (both C2; one byte-verification, one deferred-by-design carry resolved by C3). C3, C4, C5, C7 added zero out-of-denominator entries — spec was sufficient, bytes matched expectation.
- **Components contributing zero in-denominator entries:** C2, C3, C4, C5, C7 (five of seven).
- **Components contributing entries:** C1 (2 environment entries — the 3.14 runtime + `@unique` test layout) and C6 (1 implementation entry — the offset-stride bug).

## Adjudication (2026-06-19)

**Lesson 2's prediction is CONFIRMED.**

The prediction's two conditions both hold across the 3-entry ledger:

1. **DA-catchable bugs were cheap.** There were zero DA-catchable bugs across the entire build. The prediction's first leg is satisfied vacuously — no catchable bug shipped past the freeze.
2. **Non-catchable-at-spec-time bugs dominated the in-denominator population.** All 3/3 entries were DA-uncatchable (the two C1 entries are environment-not-spec; the C6 entry is implementation-not-spec). The build's residual surface was uniformly outside what further spec-reading could have reached.

The C6 offset-stride bug is the strongest evidence — it is the only genuine correctness bug (silent data loss, not an environment correction) the build produced, and it was *provably* uncatchable by a v3.5 DA cycle: the spec correctly said "paginate, caps 100/page," and the bug lived in how the implementation translated that to offset arithmetic. The spec's domain ends at "paginate correctly"; the bug's domain begins at "here is how the helper computes the next offset." A v3.5 DA pass would have read the spec, found it correct, and moved on. The build's own DA gate caught it at minutes-cost — exactly the substitution the prediction names.

### Retroactive validation of the freeze decision

Had the team run v3.5, v3.6, etc., those passes would have found zero entries in this ledger — all three are DA-uncatchable. The marginal DA cycles would have cost time and surfaced zero of the actual remaining issues. "Stopping at v3.4 was correct" is now evidenced from the residual ledger, not just argued from the marginal-find curve. The freeze was the right call.

### Promotion record

| Data point | Component | Issue | DA-catchable? | Cost |
|------------|-----------|-------|---------------|------|
| 1 | C1 | 3.14 runtime corruption framing | No (environment) | minutes |
| 2 | C1 | `@unique` test layout substitution | No (environment) | minutes |
| 3 | C6 | Pagination offset-stride bug (silent data loss) | No (implementation) | minutes |

Three data points + one confirmed falsifiable prediction = promotion threshold met (the prediction's two-condition test is itself the falsifiable instrument; confirmation across 3/3 entries is the dataset).

### Standing-discipline note

This is the third ratified cross-cutting lesson in this conventions doc (joining the enumeration discipline above and the canonical-home rule in `docs/conventions/canonical-home-rule.md`). Per the standing extraction discipline: a third lesson would normally trigger creating a canonical home, but the canonical home already exists (this very doc), so ratification populates the existing slot without further extraction work.
