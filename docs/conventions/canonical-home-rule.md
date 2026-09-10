# Canonical-home propagation rule

**Status:** Ratified (2026-06-19)
**Originally banked:** 2026-06 (Finding-M lesson, [scripts/automation/lessons.md](../../scripts/automation/lessons.md))
**Enforcement:** human-only (no machine-enforceable check; reviewer practice)

## Rule

A discipline that exists only in one artifact's local prose does not
propagate; it will be independently re-derived (and sometimes wrong).
**For cross-cutting safety rules, create one canonical home and require
all downstream artifacts (DDL, docstrings, comments, handlers, specs,
tests) to cite it.**

The citation is a path-and-anchor reference to the canonical home, not
a prose copy.  When the rule changes, only the canonical home changes;
the citations remain valid because they resolve to the new content.

## Anti-pattern this rule replaces

Re-stating the rule in each artifact that needs it.  This produces:

- **Drift.**  Two artifacts that derived the same rule independently
  diverge over time as one is edited and the other is not.
- **Re-derivation cost.**  Each new artifact author re-reasons the rule
  from first principles, sometimes correctly and sometimes wrong.
- **Audit cost.**  A reviewer who wants to confirm one artifact's
  treatment of the rule has to read every other artifact that touches
  the rule to know whether they agree.

## Packet proof

PR1+PR3 of the credential-safety packet (2026-06) converted the
credential threat model from "one correct local derivation in
`redact.py`'s docstring" to a citable convention at
[`docs/triage-agent/credential-threat-model.md`](../triage-agent/credential-threat-model.md).
After extraction, the DDL, the redactor docstring, the orchestrator
fail-open handler, and the credential-sentinel rationale string all
cite the canonical home rather than restating the rule.  When R1's
"audit before transform" sequencing was added, the change landed in one
place; every cite continued to resolve correctly.

## How to apply this rule

When a discipline is being applied across two or more artifacts of
different types (e.g., DDL comment + Python handler + spec doc):

1. **Write the rule's full prose in exactly one file.**  Default
   location: this directory (`docs/conventions/`).  Domain-scoped
   rules may live in a domain doc (e.g., `docs/triage-agent/`) when
   the domain is the natural boundary.

2. **Cite the canonical home from every artifact that follows the
   rule.**  Citation form: a markdown link in prose, an SQL/Python
   comment with the relative path, or a docstring `See:` reference.
   Citations include path + anchor (`#section`) when the artifact
   needs only one section of the rule.

3. **When the rule is amended, amend the canonical home only.**  Run
   a `grep` for inbound citations to confirm scope and to flag any
   citing artifact that needs a corresponding change.

4. **A new domain rule that needs a citable home** triggers a check:
   does the rule already cross-cut multiple artifacts, or is it
   currently scoped to one?  Single-artifact rules stay local.
   Cross-cutting rules get extracted on first use, not "when there
   are three."

## Application to itself

This rule's original ratification note predicted its own extraction:

> "*The rule's own logic argues for extraction to a standalone
> conventions doc (e.g., `docs/conventions/canonical-home-rule.md`) —
> a rule about citability should itself be citable.  However,
> entry 3's threshold logic (decompose when unwieldy, not
> preemptively) is also sound.  Decision: stay in `lessons.md` for
> now, but flag extraction trigger — promote to a standalone
> conventions doc when a second cross-cutting rule joins it.*"

The trigger fired on 2026-06-19 when the **enumeration discipline**
rule reached its promotion threshold (3 data points, 2 confirmed
falsifiable predictions, see
[enumeration-discipline.md](enumeration-discipline.md)).  This file
is the extraction predicted by that note.

Inbound citations updated as part of the extraction:

- `scripts/automation/lessons.md` — entry now reads "*See
  [docs/conventions/canonical-home-rule.md](../../docs/conventions/canonical-home-rule.md);
  ratified 2026-06-19, extracted on the second-cross-cutting-rule
  trigger.*"
- `docs/conventions/README.md` — listed in the ratified-rules table.

## Limits and known noise modes

- **Citation rot.**  A relative path that breaks after a file move
  produces a 404-on-render rather than a wrong rule.  Acceptable
  failure mode (loud, not silent).  No CI check today; pre-commit hook
  candidate if rot becomes recurrent.
- **Over-extraction.**  Single-artifact rules pulled into this
  directory create indirection without benefit.  The threshold "two
  artifacts of different types" is the floor.  Domain-scoped rules
  with one consumer stay in the domain doc.
- **Stale prose in the canonical home.**  The rule does not protect
  against the canonical home itself going wrong; reviewer practice on
  changes to this directory is the only check.  This is the cost of
  citing-not-duplicating.
