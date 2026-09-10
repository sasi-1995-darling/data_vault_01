# Conventions

Cross-cutting rules that govern how downstream artifacts (code, DDL,
docstrings, comments, handlers, specs, tests) cite shared invariants.

These are **ratified rules**, not lessons.  Lessons live in
[scripts/automation/lessons.md](../../scripts/automation/lessons.md) and
graduate to this directory only when they meet the promotion threshold
(see each rule's own ratification note).  Once ratified, they belong
here — not in `lessons.md` — so downstream artifacts can cite a stable
URL rather than duplicating the prose.  This doc directory is itself a
load-bearing instance of the canonical-home rule applied to itself.

## Ratified rules

| Rule | File | Promoted | Enforcement |
|------|------|----------|-------------|
| Canonical-home propagation | [canonical-home-rule.md](canonical-home-rule.md) | 2026-06-19 | human-only |
| Enumeration discipline (consumer-of-multi-exit-producer) | [enumeration-discipline.md](enumeration-discipline.md) | 2026-06-19 | human-only |

## Candidate rules (banked-with-prediction)

Banked candidates are documented in the same file as the ratified rule
they are paired with, under a `## Candidate` section.  Promotion to a
ratified rule requires the candidate's falsifiable prediction to be
confirmed by an independent test.

- **Stopping-point discipline (paired with enumeration discipline)** —
  see [enumeration-discipline.md § Candidate](enumeration-discipline.md#candidate--stopping-point-discipline-banked-2026-06-19)

## Why a separate directory

The canonical-home rule's own ratification note (Finding-M, 2026-06)
predicted that it would extract to a standalone doc as soon as a second
cross-cutting rule joined it: "*the rule's own logic argues for
extraction to a standalone conventions doc — a rule about citability
should itself be citable*".  The enumeration discipline rule is that
second rule.  This directory is the predicted extraction firing on its
own stated trigger.
