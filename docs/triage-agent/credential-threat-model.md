# Credential Threat Model — DV Failure Triage Agent

> Canonical home for the credential-safety convention. All payload-handling
> code in `scripts/automation/src/triage/` and all PRs that touch that tree
> MUST conform. Authored 2026-06-16 from the audit that surfaced Findings
> A, B, J, Q, R, T1–T5 — nine independent re-derivations of a convention
> that was correctly reasoned at exactly one site (Finding M).

## Status

Authoritative. Supersedes any prose-only assertions about credential safety
in other artifacts. Where this document conflicts with comments, docstrings,
or DDL headers, this document wins; the conflicting artifact is the bug.

## Threat Model

A credential exposed via *any* channel an operator, log, audit table, or
LLM can read is exfiltrated. The credential sentinel is the only authority
that can declare a payload credential-free. **Any transformation,
channel-routing, or interpolation that occurs before the sentinel runs on
the raw structure is a fail-open**, without regard to whether the
downstream channel was intended to consume the content.

## Three Rejected Intuitions

Three reasoning errors regularly produce fail-opens. Each has been
reasoned-and-rejected at the canonical inline statement
(`scripts/automation/src/triage/failure_triage_agent.py:256-285`).
Restated here as standalone rules.

1. **Channel-routing is not a mitigation.** "This output isn't read by
   the LLM" or "this stderr message isn't persisted" does not make
   credentials in that output safe. Any channel an operator can see —
   stderr, logs, fixture files, error tables, debug traces, batch
   summary output — is an exfiltration channel. Trust does not transfer
   between channels.

2. **Truncation-before-scan is fail-open.** A credential can appear at
   any byte offset. Truncating a payload before the sentinel inspects
   the raw structure removes evidence the sentinel needs. Scan first,
   truncate after. The reverse order is a leak by construction.

3. **Char-caps are not a credential mitigation.** Capping a leaked string
   at 200 or 240 characters does not unleak it. A 200-character credential
   is a leaked credential. Bounding the size of a leak is not a mitigation
   — it is a smaller leak.

## The Convention

Three operative rules. Each maps 1:1 to a checklist question below.

- **R1 — Sentinel-before-transform.** The credential sentinel MUST run
  on the raw payload structure before any lossy transform (truncation,
  field-routing, preview projection, serialization).

- **R2 — No exception interpolation.** Exception objects MUST NOT be
  interpolated on any path that handles a payload, or on any path that
  handles an exception raised while handling a payload. The only safe
  interpolation is `type(exc).__name__`. Exemptions require BOTH an
  inline comment naming the proving test AND the proving test itself,
  patterned on the exemplar in §Proving-Test Exemplar.

- **R3 — No safety claim without a proving test.** Comments, docstrings,
  and DDL headers MUST NOT claim content is "safe", "by construction",
  "excluded", "redacted", "sanitized", or similar WITHOUT citing the
  test that demonstrates the claim. Unsupported safety claims become
  load-bearing falsehoods in downstream artifacts.

### Construction Exemption (applies to R2 and R3)

A call site MAY be exempted from the proving-test requirement of R2 or
R3 when an inline comment names what *structurally* prevents
payload-derived content from reaching that site, AND:

1. The named construction is *falsifiable* — if a payload-derived value
   is later fed to that site, the comment becomes visibly false.
2. The named construction MUST cite the specific upstream code path
   (function, file, or validated pattern) that establishes it, so a
   reviewer can verify the provenance by reading that path rather than
   trusting the comment.

The construction exemption permits ONLY structural facts about the
call site's inputs — their origin and how they arrive. It does NOT
permit behavioral claims that depend on a function correctly sanitizing
input. A behavioral claim is "trust this code correctly filters the
value." A structural claim is "this code never receives a payload-
derived value in the first place." Only the latter is verifiable by
reading the call site without running a test.

**Required form for the inline comment:**

```
# R2 (or R3) construction exemption: <subject> at this site cannot
# carry payload-derived content because <named construction>.
# Falsifiable: this exemption fails if <enumerated change> ever
# happens here. See: docs/triage-agent/credential-threat-model.md
# §Construction Exemption.
```

**Valid named constructions** (illustrative, not exhaustive):
- "input is `configs/catalog.yaml`, developer-authored, loaded at
  import-time by `load_catalog`, never populated from runtime payload"
- "orphan paths come from `fixture_dir.glob('*.tmp')`; `.tmp` basenames
  are built by `_output_filename` from raw filenames validated against
  `RAW_FILENAME_PATTERN`, never derived from payload bytes"

**Invalid exemptions** (rejected by review):
- "this is safe" (no named construction, not verifiable)
- "by construction" (no specifics, cannot be reviewed or falsified)
- "the input is sanitized upstream" (behavioral claim about a function
  correctly sanitizing — must use the proving-test clause instead)

## Checklist (the load-bearing artifact)

Apply to any PR that touches `scripts/automation/src/triage/`,
`scripts/automation/tests/test_triage_*`, `scripts/automation/tests/test_redactor_pipeline.py`,
or the agent's DDL.

**Q1.** Does this code run the credential sentinel on the raw structure
BEFORE any lossy transform (truncation, field-routing, projection,
serialization)?

**Q2.** Does this code interpolate an exception object (`str(exc)`,
`repr(exc)`, `exc.args`, `exc.doc`, or any f-string `{exc}` /
`{exception}` / `{e}` form) on any path that handles a payload, or that
handles an exception raised while handling a payload — regardless of
whether the path appears to be post-redaction? If yes, is there an
inline citation to a proving test that demonstrates the exception
cannot carry payload-derived content?

**Q3.** Does this code or its accompanying comments / docstrings / DDL
headers claim content is "safe", "by construction", "excluded",
"redacted", or otherwise sanitized WITHOUT citing the proving test
that demonstrates the claim?

**Required answers:**

- Q1 = yes (or N/A with a cited rationale)
- Q2 = no — OR yes-with-cited-proving-test
- Q3 = no — OR yes-with-cited-proving-test

Any "no" on Q1 or "yes-without-citation" on Q2/Q3 is a blocking
finding. The exemption is justified by *citing the proving test*, not
by reviewer judgment. The conservative answer is the default; the
exception bears the burden of proof.

## Canonical Inline Expression

The convention is expressed inline at
`scripts/automation/src/triage/failure_triage_agent.py:256-285` — the
`except Exception` handler inside `triage_failure`. It reasons through
all three rejected intuitions and applies R2 strictly (`exc_type` only,
`logger.error` not `logger.exception`, no char-cap on rationale, no
routing-the-leak-from-one-boundary-to-another).

When in doubt about how to apply the convention at a specific call
site, read that handler. It is the worked example.

## Proving-Test Exemplar

The convention's Q2/Q3 exemption clause requires a *proving test*. The
exemplar is
`scripts/automation/tests/test_triage_orchestrator.py:434` —
`test_no_credential_substring_in_any_field`. Pattern:

1. Plant a credential-shaped canary (a JWT-shaped string in the
   exemplar) in a monkeypatched exception that the unit under test
   will raise or propagate.
2. Invoke the function under test.
3. Walk the resulting object structurally via `model_dump(mode="json")`
   and recurse through every str-valued field.
4. Assert the canary appears in zero fields.
5. Assert the canary's *prefix* is also absent (partial-leak protection
   — a half-credential is still a credential).
6. Belt-and-braces: assert on the contract surface (rationale shape,
   outcome enum) so a refactor that nullifies rationale doesn't
   silently turn the test into a no-op assertion sweep.

Any Q2/Q3 exemption MUST cite a test that follows this pattern. A test
that only checks specific named fields, that omits partial-leak
protection, or that lacks the belt-and-braces contract assertion is
NOT a proving test for the purposes of this convention.

## Phase-2 Gate

The following Phase-2 deliverables MUST NOT ship until this document
exists and contains the three numbered checklist questions (Q1, Q2, Q3)
verbatim:

- the dbt Cloud webhook handler
- the `dbt_cloud_client.py` API wrapper
- the `OPS_PROD.LOGS.TRIAGE_INVOCATIONS` Python writer

CI enforces presence by grepping this file for the three checklist
question markers (`**Q1.**`, `**Q2.**`, `**Q3.**`). File existence
alone is not sufficient — empty doc, stub doc, or doc missing the
checklist markers all fail the gate. Enforcement workflow:
`.github/workflows/credential-threat-model-gate.yaml` (added in PR 1
alongside this document).

The gate verifies the *existence and legibility* of this canonical home;
it does not verify that PR code conforms to the convention. Convention
conformance is enforced by human reviewers applying the checklist
(Q1/Q2/Q3) during PR review. A green check on the gate means "the
canonical home is present"; it does NOT mean "the PR is
credential-safe." See the SCOPE LIMITATION block in the workflow file
for the full statement.

## Why This Document Exists

The credential threat model was correctly reasoned at *one* call site
(the orchestrator's `except Exception` handler, Finding M) and
incorrectly re-derived at nine other sites in the same codebase
(Findings A, B, J, #9, Q, R, T1–T5; 2026-06-16 audit).

**A discipline that lives in one artifact's prose, rather than in a
canonical home that other artifacts reference, does not propagate — it
gets independently re-derived, sometimes wrong.** This is the
structural lesson the audit surfaced.

This document is the canonical home. Every Q2/Q3 exemption cites the
proving-test exemplar. Every safety claim in comments, DDL, or
docstrings cites this document. The next engineer who reaches for
"safe by construction" reads this and reaches for the sentinel
instead.
