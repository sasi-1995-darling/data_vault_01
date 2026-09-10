#!/usr/bin/env python3
"""
test_conformance.py — suite-level conformance guards (#1913).

Closes the "green suite whose fixtures dodge the failing input" failure mode at
the *registry* level, rather than relying on a reviewer to notice it:

  (1) Trap -> check coverage — every check id cited in the modeling-traps catalog
      (.github/knowledge/data-vault/08-modeling-traps.md) must resolve to a live
      check in ``code_reviewer.CHECK_REGISTRY``. A trap that claims deterministic
      enforcement by a renamed or removed check fails here.

  (2) Registry integrity (the applicable slice of "check liveness") — every
      registry entry is callable and accepts the kwargs the runner passes it.
      This is not cosmetic: ``code_reviewer.review_file`` fail-closes — a check
      that raises (e.g. a drifted signature that no longer accepts one of those
      kwargs) is caught and turned into a merge-blocking ``FAIL`` finding ("did
      not complete"). So a signature-drifted check does not silently pass; it
      makes *every* reviewed file FAIL until fixed. This guard catches that drift
      at test time, before it turns the review gate into a repo-wide block. The
      exhaustive positive/negative fixture harness (every FAIL/WARN check fires
      on a realistic positive and stays silent on a negative) is a larger
      follow-up, out of scope here.

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_conformance.py -v
"""
import inspect
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_reviewer import CHECK_REGISTRY  # noqa: E402

PROJECT_ROOT = Path(__file__).resolve().parents[3]
TRAPS_DOC = PROJECT_ROOT / ".github" / "knowledge" / "data-vault" / "08-modeling-traps.md"

# Check-id grammar: a category letter A-Q followed by 1-2 digits (e.g. Q1, B4, H10).
_CHECK_ID_RE = re.compile(r"\b([A-Q]\d{1,2})\b")

# O and P are documented-pending categories in CODE_REVIEW_CHECKS.md (Multi-Source /
# Business Vault); the traps catalog may cite them before they are implemented.
_PENDING_CATEGORIES = ("O", "P")

# The runner calls every check with these four kwargs (plus optional ``repo_root``).
_RUNNER_KWARGS = {"sql_content", "file_path", "yaml_content", "file_status"}


# ---------------------------------------------------------------------------
# (1) Trap -> check coverage
# ---------------------------------------------------------------------------

class TestTrapCheckCoverage:

    def test_traps_catalog_exists(self):
        assert TRAPS_DOC.is_file(), f"modeling-traps catalog not found at {TRAPS_DOC}"

    def test_traps_cite_only_live_or_pending_checks(self):
        """Every check id cited in the traps catalog is a live CHECK_REGISTRY id
        (or a documented-pending O*/P* category). Catches a trap that claims
        deterministic enforcement by a check that was renamed or removed."""
        referenced = set(_CHECK_ID_RE.findall(TRAPS_DOC.read_text()))
        # Guard against the extraction silently matching nothing (which would make
        # the assertion below vacuous).
        assert referenced, "no check ids extracted from the traps catalog"

        registry = set(CHECK_REGISTRY)
        missing = sorted(
            cid for cid in referenced
            if cid not in registry and cid[0] not in _PENDING_CATEGORIES
        )
        assert not missing, (
            f"08-modeling-traps.md cites checks absent from CHECK_REGISTRY: {missing} "
            f"— a trap claims deterministic enforcement by a check that does not exist."
        )


# ---------------------------------------------------------------------------
# (2) Registry integrity — the applicable slice of "check liveness"
# ---------------------------------------------------------------------------

class TestRegistryIntegrity:

    def test_every_check_binds_runner_call(self):
        """The runner invokes every check as ``entry.fn(**kwargs)`` with
        sql_content/file_path/yaml_content/file_status (plus ``repo_root`` for
        checks whose signature accepts it). Verify each signature can actually
        *bind* that call — not merely that the parameter names exist — so drift
        such as a positional-only parameter (``/``) or a newly-required argument
        is caught. review_file fail-closes on a bind failure: it becomes a
        merge-blocking FAIL ("did not complete") on every reviewed file."""
        for check_id, entry in CHECK_REGISTRY.items():
            assert callable(entry.fn), f"{check_id}: registry entry is not callable"
            sig = inspect.signature(entry.fn)
            kwargs = {name: None for name in _RUNNER_KWARGS}
            # Mirror the runner: repo_root is passed only to checks that accept it.
            if "repo_root" in sig.parameters:
                kwargs["repo_root"] = None
            try:
                sig.bind(**kwargs)
            except TypeError as exc:
                raise AssertionError(
                    f"{check_id} ({entry.fn.__name__}): the runner call entry.fn(**kwargs) "
                    f"cannot bind {sorted(kwargs)} — {exc}. review_file would raise and "
                    f"fail-close every reviewed file into a FAIL."
                ) from exc

    def test_registry_entry_structure(self):
        """Each entry has a non-empty suffix pattern list and a category that
        prefixes the check id."""
        for check_id, entry in CHECK_REGISTRY.items():
            assert entry.file_patterns and all(p.startswith(".") for p in entry.file_patterns), (
                f"{check_id}: file_patterns should be non-empty suffixes, got {entry.file_patterns!r}"
            )
            assert entry.category and check_id.startswith(entry.category), (
                f"{check_id}: category {entry.category!r} does not prefix the id"
            )

    def test_registry_ids_match_check_id_grammar(self):
        """Every registry id matches the check-id grammar (letter A-Q + 1-2 digits),
        so the trap-coverage extraction regex in (1) can actually see them."""
        bad = sorted(cid for cid in CHECK_REGISTRY if not re.fullmatch(r"[A-Q]\d{1,2}", cid))
        assert not bad, f"CHECK_REGISTRY ids not matching the check-id grammar: {bad}"
