# Backtest baseline — P0.1 corpus

> **Historical snapshot — preserved intentionally.** This file is the
> baseline as-emitted on 2026-06-07 against harness `v1.0.0` and the
> P0.1 corpus, and is intentionally NOT edited in place when the harness
> or catalog moves forward. The version stamps below (harness, catalog,
> label spec) reflect what produced this snapshot, not the head of the
> repo today. A subsequent re-run under harness `v1.1.0` produced the
> same outcome metrics on the same P0.1 corpus; that re-run and the
> decision to preserve this file as the v1.0.0 anchor are recorded in
> [`sprint-1-deferred.md` §22](./sprint-1-deferred.md). Edits to this
> file would falsify it as a baseline; questions about "why does the
> harness version not match HEAD?" are answered by §22, not by
> rewriting the stamps here.

**Generated:** 2026-06-07 16:31 UTC
**Harness version:** `v1.0.0`  **Catalog schema:** `v1.2.0`
**Label spec:** `docs/triage-agent/fixtures/p01_labels.yml` (version `v1.0.0`)
**Cases total:** 7  **scored:** 7  **skipped (payload missing):** 0  **errored (triage raised):** 0

This report is **non-gating** in Phase 1 (per H6 adjudication 2026-06-07). Regenerate when `fbin_error_catalog.yml`, `redact.py`, or the committed fixtures change. Regression visibility happens via git-diff of this file, not via test failure. Drift in any of the four version stamps (harness, catalog schema, label spec, or label path) is itself a signal worth investigating.

## Corpus caveats (from label spec)

**In-sample corpus.** These 7 payloads INFORMED the Phase-1 catalog
design (Patterns 1–3). 100% precision/recall on this corpus reflects
in-sample fit, NOT generalization to novel failures. Out-of-sample
evidence requires Phase-2 corpus expansion against held-out
production failures — sprint-1-deferred captures the expansion
strategy.

Three of the seven labels are category-confirmed (485850628, 485851058
— Pattern 3) rather than empirically-cited in the catalog provenance.
See per-entry `provenance.derivation` for the distinction. Two of the
seven (Cluster C: 484675412, 486060143) are no-pattern-applicable per
sprint-1-deferred #15; their PASS verdict confirms the orchestrator's
zero-match branch, not catalog coverage of Cluster C.

CI gating: non-gating in Phase 1 (H6 adjudication 2026-06-07). Phase 2
promotes to gating once corpus stabilizes.

## Verdict counts

| Verdict | Count |
|---|---|
| `pass` | 7 |
| `false_positive` | 0 |
| `false_negative` | 0 |
| `wrong_pattern` | 0 |
| `sentinel_fired_unexpected` | 0 |
| `skipped_payload_missing` | 0 |
| `error_during_triage` | 0 |

## Per-pattern precision / recall

Computed over **scored** cases only — payloads missing from the local environment (e.g., `~/scratch/triage-day4/` absent in clean clones) are excluded from the denominator. `UNKNOWN` is the synthetic bucket for the no-match path.

| Pattern | TP | FP | FN | Precision | Recall |
|---|---:|---:|---:|---:|---:|
| `manifest_parse_failure_invalid_model_language_v1` | 3 | 0 | 0 | 1.000 | 1.000 |
| `pr_isolated_schema_missing_upstream_v1` | 2 | 0 | 0 | 1.000 | 1.000 |
| `UNKNOWN` | 2 | 0 | 0 | 1.000 | 1.000 |

## Per-case results

| run_id | cluster | verdict | expected pattern | observed pattern | expected outcome | observed outcome |
|---|---|---|---|---|---|---|
| 485821754 | A | `pass` | `manifest_parse_failure_invalid_model_language_v1` | `manifest_parse_failure_invalid_model_language_v1` | `classified` | `classified` |
| 485850628 | A | `pass` | `manifest_parse_failure_invalid_model_language_v1` | `manifest_parse_failure_invalid_model_language_v1` | `classified` | `classified` |
| 485851058 | A | `pass` | `manifest_parse_failure_invalid_model_language_v1` | `manifest_parse_failure_invalid_model_language_v1` | `classified` | `classified` |
| 487333396 | B | `pass` | `pr_isolated_schema_missing_upstream_v1` | `pr_isolated_schema_missing_upstream_v1` | `classified` | `classified` |
| 487313189 | B | `pass` | `pr_isolated_schema_missing_upstream_v1` | `pr_isolated_schema_missing_upstream_v1` | `classified` | `classified` |
| 484675412 | C | `pass` | `—` | `—` | `unknown_handed_to_human` | `unknown_handed_to_human` |
| 486060143 | C | `pass` | `—` | `—` | `unknown_handed_to_human` | `unknown_handed_to_human` |

## Observed rationale excerpts (first 240 chars)

- **485821754**: `pattern_id=manifest_parse_failure_invalid_model_language_v1 sub_class=manifest_parse_invalid_model_language provenance=gate_d_evidence:run_id=485821754`
- **485850628**: `pattern_id=manifest_parse_failure_invalid_model_language_v1 sub_class=manifest_parse_invalid_model_language provenance=gate_d_evidence:run_id=485821754`
- **485851058**: `pattern_id=manifest_parse_failure_invalid_model_language_v1 sub_class=manifest_parse_invalid_model_language provenance=gate_d_evidence:run_id=485821754`
- **487333396**: `pattern_id=pr_isolated_schema_missing_upstream_v1 sub_class=pr_schema_missing_upstream provenance=gate_d_evidence:run_id=487333396`
- **487313189**: `pattern_id=pr_isolated_schema_missing_upstream_v1 sub_class=pr_schema_missing_upstream provenance=gate_d_evidence:run_id=487333396`
- **484675412**: `no catalog pattern matched the projected signal (eligible fields populated: ['logs', 'status_message', 'truncated_debug_logs'])`
- **486060143**: `no catalog pattern matched the projected signal (eligible fields populated: ['logs', 'status_message', 'truncated_debug_logs'])`
