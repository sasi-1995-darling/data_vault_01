"""source_column_utils.py — single source of truth for the YAML ``source_column`` field.

The generated YAML config stores ``source_column`` as a **list** of raw column
tokens (uniform shape for both single-column and composite business keys):

    source_column:
      - INVOICE_ID
      - LINE_NUMBER

    source_column:
      - INVOICE_ID          # single-column: still a list, length 1

Every reader must go through :func:`get_source_columns` (or
:func:`normalize_source_column`) instead of touching the raw field or
re-implementing comma parsing. Every writer must emit a list via the same
normalizer so the two composite call sites (raw-passthrough + BK-alias) cannot
drift apart again.

**Order is load-bearing.** The token order determines the ``CONCAT_WS`` argument
order, which determines the business key, which determines every hash key derived
from it. These helpers NEVER sort or de-duplicate — do not add ``sorted()`` or
``set()`` anywhere in this module or its callers.
"""

import warnings


class LegacySourceColumnWarning(DeprecationWarning):
    """A legacy comma-delimited ``source_column`` string was read.

    The canonical on-disk form is a YAML list. Comma-strings are still accepted
    (liberal reader) but are deprecated; this warning is the expiry signal so the
    two formats do not persist indefinitely and erode the one-accessor invariant.
    """

# Delimiter used inside the generated ``UPPER(CONCAT_WS('||', ...))`` business-key
# expression. Kept here as the single canonical literal so the arg-parse layer,
# the YAML writer, the XLSX Logic cell and the generated SQL all agree.
COMPOSITE_BK_DELIMITER = "||"

# Delimiter used when a ``source_column`` list must be flattened back to the
# legacy single-cell string form (the uppercase ``SOURCE COLUMN`` field consumed
# by build.py). Comma, no space — canonical, deterministic.
SOURCE_COLUMN_JOIN_DELIMITER = ","


def normalize_source_column(value):
    """Return ``value`` as a clean ``list[str]`` of source-column tokens.

    Liberal on input (writer/reader shared normalizer):

    - ``list``/``tuple`` -> each element stripped, empties dropped, ORDER KEPT.
    - legacy comma-delimited ``str`` (e.g. ``"INVOICE_ID, LINE_NUMBER"``) ->
      split on comma, each token stripped, empties dropped, ORDER KEPT. A
      *multi-column* legacy string additionally emits
      :class:`LegacySourceColumnWarning` (deprecation signal).
    - ``None`` -> ``[]``.

    Never sorts or de-duplicates — token order is semantically significant.
    """
    if value is None:
        return []
    if isinstance(value, (list, tuple)):
        items = list(value)
    else:
        text = str(value)
        items = text.split(",")
        if len([t for t in items if t.strip()]) > 1:
            warnings.warn(
                f"Legacy comma-delimited source_column {text!r} read; the canonical "
                f"form is a YAML list. Regenerate the config to migrate.",
                LegacySourceColumnWarning,
                stacklevel=2,
            )
    normalized = []
    for item in items:
        token = str(item).strip()
        if token:
            normalized.append(token)
    return normalized


def get_source_columns(col):
    """Read the ``source_column`` of a column dict as a ``list[str]``.

    ``col`` may be a column dict (the common case) or a raw ``source_column``
    value. Always returns a list, so callers never branch on the stored type.
    """
    if isinstance(col, dict):
        return normalize_source_column(col.get("source_column"))
    return normalize_source_column(col)


def source_columns_to_str(value, delimiter=SOURCE_COLUMN_JOIN_DELIMITER):
    """Flatten a ``source_column`` value to the legacy single-cell string form.

    Accepts the same inputs as :func:`get_source_columns` (a column dict, a list,
    or a legacy string). For a length-1 list this returns the bare token
    unchanged, preserving single-column SQL output exactly.
    """
    if isinstance(value, dict):
        cols = get_source_columns(value)
    else:
        cols = normalize_source_column(value)
    return delimiter.join(cols)
