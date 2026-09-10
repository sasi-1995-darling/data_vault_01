"""
code_review_config.py — Configuration layer for code_reviewer.py

Implements five Configuration Decisions from CODE_REVIEW_CHECKS.md:
  CD-1: Git diff context (new vs modified file detection)
  CD-2: EXCLUDED_PATHS (legacy AutomateDV models skip ALL checks)
  CD-3: .code_review_ignore (Category G naming exceptions only)
  CD-4: governance_allowlist.yml (I2/I4/I5 governed database/schema/project
        allowlist + staging ref-exemptions + source resolver)
  CD-5: .code_review_grandfather (frozen burn-down list of pre-existing I2/I4/
        H10/H11 violations — downgrades FAIL→WARN by (check_id, file_path);
        the list only ever shrinks)
"""
import logging
import re
import subprocess
from enum import Enum
from fnmatch import fnmatch
from pathlib import Path

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# CD-2: Path Exclusion — Legacy AutomateDV models skip ALL checks
#
# These directories contain AutomateDV-generated Jinja templates that cannot
# conform to hand-written SQL standards. They are scheduled for retirement.
#
# IMPORTANT: These are DIRECTORY paths, not prefix patterns. The 66 stg_*
# files in models/bus_vault/ are NOT excluded — those are active PIT staging
# helpers that must be reviewed.
# ---------------------------------------------------------------------------
EXCLUDED_PATHS = [
    "models/staging/base/",
    "models/staging/stage/",
]


class FileStatus(Enum):
    """Whether a file is new or modified relative to the PR's base branch."""
    NEW = "new"
    MODIFIED = "modified"


def is_excluded(file_path: str) -> bool:
    """CD-2: Check if a file falls under an excluded directory path.

    Returns True if the file should skip ALL checks (not just naming).
    Uses startswith on normalized forward-slash paths — this is directory
    scoping, not prefix matching.
    """
    normalized = file_path.replace("\\", "/")
    return any(normalized.startswith(p) for p in EXCLUDED_PATHS)


def load_ignore_list(repo_root: Path) -> list[str]:
    """CD-3: Load .code_review_ignore — paths exempt from Category G checks.

    Returns a list of glob patterns. Files matching any pattern skip
    naming convention checks only; all other checks still run.
    """
    ignore_file = repo_root / "scripts" / "automation" / ".code_review_ignore"
    if not ignore_file.exists():
        logger.debug("No .code_review_ignore file found at %s", ignore_file)
        return []
    patterns = []
    for line in ignore_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        patterns.append(line)
    logger.debug("Loaded %d patterns from .code_review_ignore", len(patterns))
    return patterns


def is_naming_ignored(file_path: str, ignore_patterns: list[str]) -> bool:
    """CD-3: Check if a file matches any .code_review_ignore pattern.

    Matching files skip Category G (Naming Convention) checks only.
    All other check categories still run.
    """
    normalized = file_path.replace("\\", "/")
    return any(fnmatch(normalized, p) for p in ignore_patterns)


def get_file_statuses(base_branch: str = "origin/main") -> dict[str, FileStatus]:
    """CD-1: Get new vs modified status for each changed file in the PR diff.

    Uses `git diff --name-status` to determine whether each file is newly
    added (A) or modified (M/R/C). This distinction drives check G4's
    graduated enforcement: WARN for modified link_ files, FAIL for new ones.

    Returns a dict mapping relative file paths to their FileStatus.
    Returns empty dict if git is unavailable or diff fails.
    """
    try:
        result = subprocess.run(
            ["git", "diff", "--name-status", base_branch, "HEAD"],
            capture_output=True, text=True, check=True,
            timeout=30,
        )
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError) as e:
        logger.warning("git diff failed (%s), treating all files as NEW", e)
        return {}

    statuses: dict[str, FileStatus] = {}
    for line in result.stdout.strip().splitlines():
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        status_code = parts[0]
        # For renames (R100), the new path is the last element
        file_path = parts[-1]
        if status_code.startswith(("A", "C")):
            # A (added), C (copied) — new files for stricter enforcement
            statuses[file_path] = FileStatus.NEW
        else:
            # M (modified), R (renamed) — existing files, graduated enforcement
            statuses[file_path] = FileStatus.MODIFIED
    logger.debug("git diff found %d changed files", len(statuses))
    return statuses


# ---------------------------------------------------------------------------
# CD-4: Governance allowlist + sources YAML source-name → (database, schema)
# resolver. Both are MEMOIZED per repo_root because they're invoked once per
# I2 check call (potentially many SQL files) and the parse cost is non-trivial
# (~3 sources YAMLs out of ~1,800 model YAML files at fix time).
# ---------------------------------------------------------------------------

# Suffixes that mark a database as env-specific. Normalized to _PROD so a DEV
# equivalent of an allowlisted PROD database passes I2 automatically.
_ENV_SUFFIXES = ("_DEV", "_DEVELOPMENT", "_QA", "_TEST", "_STAGING", "_STAGE")

# Jinja env_var(...) substitution — render as 'prod' to compare against the
# allowlist's PROD form. Two-arg form (with default) also matched.
_ENV_VAR_RE = re.compile(
    r"\{\{\s*env_var\s*\(\s*['\"]\w+['\"]"
    r"(?:\s*,\s*['\"][^'\"]*['\"])?\s*\)\s*\}\}",
    re.IGNORECASE,
)


def normalize_database(db: str) -> str:
    """Normalize an env-specific database name to its PROD logical role.

    - Renders Jinja ``{{ env_var('FOO') }}`` and ``{{ env_var('FOO','dev') }}``
      as the literal string ``prod``.
    - Strips ``_DEV`` / ``_QA`` / ``_TEST`` / ``_STAGING`` / ``_STAGE`` /
      ``_DEVELOPMENT`` suffixes and replaces with ``_PROD``.
    - Returns uppercased result for case-insensitive comparison.

    Examples:
        ``psa_{{env_var('DBT_SOURCE_ENV')}}`` → ``PSA_PROD``
        ``EDP_BRONZE_DEV`` → ``EDP_BRONZE_PROD``
        ``BI_SANDBOX`` → ``BI_SANDBOX`` (unchanged; correctly fails)
    """
    if not db:
        return ""
    rendered = _ENV_VAR_RE.sub("prod", db)
    db_upper = rendered.upper()
    for suffix in _ENV_SUFFIXES:
        if db_upper.endswith(suffix):
            return db_upper[: -len(suffix)] + "_PROD"
    return db_upper


# Cache: {repo_root_str: allowlist_dict}
_ALLOWLIST_CACHE: dict[str, dict] = {}


def load_governance_allowlist(repo_root: Path) -> dict:
    """CD-4: Load governance_allowlist.yml from the repo root.

    Returns a dict with keys: ``allowed_databases``, ``allowed_schemas``,
    ``allowed_projects`` (all lists, possibly empty). Returns an empty
    allowlist if the file is missing — the caller is responsible for
    deciding whether to fail open or fail closed.
    """
    import yaml as _yaml  # local import; yaml is already a project dep

    cache_key = str(repo_root)
    if cache_key in _ALLOWLIST_CACHE:
        return _ALLOWLIST_CACHE[cache_key]

    path = Path(repo_root) / "governance_allowlist.yml"
    if not path.exists():
        logger.warning(
            "governance_allowlist.yml not found at %s — governance allowlist "
            "checks (I5, and any other consumer) will fail open against an "
            "empty allowlist",
            path,
        )
        empty = {"allowed_databases": [], "allowed_schemas": [], "allowed_projects": []}
        _ALLOWLIST_CACHE[cache_key] = empty
        return empty

    try:
        data = _yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    except _yaml.YAMLError as e:
        logger.warning(
            "governance_allowlist.yml failed to parse (%s) — governance "
            "allowlist checks will fail open against an empty allowlist",
            e,
        )
        empty = {"allowed_databases": [], "allowed_schemas": [], "allowed_projects": []}
        _ALLOWLIST_CACHE[cache_key] = empty
        return empty

    normalized = {
        "allowed_databases": [str(d).upper() for d in (data.get("allowed_databases") or [])],
        "allowed_schemas": [str(s).upper() for s in (data.get("allowed_schemas") or [])],
        "allowed_projects": [str(p).lower() for p in (data.get("allowed_projects") or [])],
    }
    _ALLOWLIST_CACHE[cache_key] = normalized
    logger.debug(
        "Loaded governance allowlist: %d databases, %d schemas, %d projects",
        len(normalized["allowed_databases"]),
        len(normalized["allowed_schemas"]),
        len(normalized["allowed_projects"]),
    )
    return normalized


def is_database_allowed(database: str, schema: str, allowlist: dict) -> bool:
    """Return True if (database, schema) is in the allowlist after env normalization.

    Database-level allowance subsumes schema-level: if a DB is in
    ``allowed_databases``, every schema in it passes. Otherwise, only the
    specific ``DB.SCHEMA`` combinations in ``allowed_schemas`` pass.
    """
    db_norm = normalize_database(database)
    if not db_norm:
        return False
    if db_norm in allowlist.get("allowed_databases", []):
        return True
    schema_norm = (schema or "").upper()
    if f"{db_norm}.{schema_norm}" in allowlist.get("allowed_schemas", []):
        return True
    return False


# Cache: {repo_root_str: {(source_name_lower, table_name_lower): (database, schema, yaml_basename)}}
_SOURCE_RESOLVER_CACHE: dict[str, dict] = {}


def load_source_resolver(repo_root: Path) -> dict:
    """CD-4: Build a (source_name, table_name) → (database, schema, yaml_basename) map.

    Discovers all dbt source YAML files under ``models/`` via a two-step:
      1. Filename prefilter: ``models/**/*sources*.yml`` and ``*.yaml``
      2. Parse-and-validate: must have top-level ``sources:`` list

    At fix time this matches 3 files out of ~1,800 YAML files in the repo
    (verified 2026-06-22). Memoized per repo_root.

    The third tuple element (``yaml_basename``) is used by I2's staging-discipline
    check to determine whether a source is legacy (registered in
    ``legacy_sources_yaml``) or new (any other YAML).

    Returns a dict; empty dict if no sources are found or any error occurs.
    """
    import yaml as _yaml

    cache_key = str(repo_root)
    if cache_key in _SOURCE_RESOLVER_CACHE:
        return _SOURCE_RESOLVER_CACHE[cache_key]

    resolver: dict[tuple[str, str], tuple[str, str, str]] = {}
    models_dir = Path(repo_root) / "models"
    if not models_dir.is_dir():
        _SOURCE_RESOLVER_CACHE[cache_key] = resolver
        return resolver

    candidates: set[Path] = set()
    for pattern in ("**/*sources*.yml", "**/*sources*.yaml"):
        candidates.update(models_dir.glob(pattern))

    for yml_path in sorted(candidates):
        try:
            data = _yaml.safe_load(yml_path.read_text(encoding="utf-8")) or {}
        except (_yaml.YAMLError, OSError):
            continue
        if not isinstance(data, dict):
            continue
        sources = data.get("sources")
        if not isinstance(sources, list):
            continue
        for src in sources:
            if not isinstance(src, dict):
                continue
            src_name = str(src.get("name") or "").lower()
            if not src_name:
                continue
            database = str(src.get("database") or "")
            # schema defaults to source name when omitted (dbt convention)
            schema = str(src.get("schema") or src.get("name") or "")
            for tbl in src.get("tables") or []:
                if isinstance(tbl, dict):
                    tbl_name = str(tbl.get("name") or "").lower()
                elif isinstance(tbl, str):
                    tbl_name = tbl.lower()
                else:
                    continue
                if not tbl_name:
                    continue
                resolver[(src_name, tbl_name)] = (database, schema, yml_path.name)

    _SOURCE_RESOLVER_CACHE[cache_key] = resolver
    logger.debug(
        "Loaded source resolver: %d (source,table) pairs from %d YAML files",
        len(resolver), len(candidates),
    )
    return resolver


def _reset_caches_for_tests() -> None:
    """Test-only helper: clear the memoization caches.

    Pytest fixtures that build per-test allowlists or sources YAMLs in tmp_path
    must call this before invoking I2, otherwise a prior test's cached data
    will leak across test boundaries.
    """
    _ALLOWLIST_CACHE.clear()
    _SOURCE_RESOLVER_CACHE.clear()
    _STAGING_CFG_CACHE.clear()
    _GRANDFATHER_CACHE.clear()


# Cache: {repo_root_str: set[(check_id, file_path_normalized)]}
_GRANDFATHER_CACHE: dict[str, set] = {}


def load_grandfather_list(repo_root: Path | None = None) -> set[tuple[str, str]]:
    """CD-5: Load the frozen grandfather list from
    ``scripts/automation/.code_review_grandfather``.

    Each non-comment, non-blank line is parsed as ``<check_id> <file_path>``.
    Returns a set of ``(check_id, file_path)`` tuples where file paths are
    forward-slash-normalized for cross-platform safety.

    BURN-DOWN-ONLY policy: this file is a frozen list of pre-existing debt.
    Findings whose (check_id, file_path) matches the list are downgraded
    FAIL → WARN with a ``[GRANDFATHERED]`` prefix; new violations (file not
    on the list) FAIL normally. The list is only ever shrunk (entries
    removed when files are cleaned up), never grown.

    ``repo_root`` may be ``None`` (common in unit tests that call a check
    function directly without setting up a fake repo). In that case the
    function returns an empty set — same fail-open semantics as a missing
    grandfather file.

    Returns an empty set if the file doesn't exist (fail open — checks
    proceed with no downgrades, so new repos / test fixtures aren't
    accidentally suppressed).
    """
    cache_key = str(repo_root)
    if cache_key in _GRANDFATHER_CACHE:
        return _GRANDFATHER_CACHE[cache_key]

    # Fail-open: if repo_root is None (no project context — common in unit
    # tests that call a check function directly without setting up a fake
    # repo), return an empty grandfather list. This preserves the documented
    # contract "no grandfather list → no downgrades, checks proceed normally."
    if repo_root is None:
        _GRANDFATHER_CACHE[cache_key] = set()
        return _GRANDFATHER_CACHE[cache_key]

    path = Path(repo_root) / "scripts" / "automation" / ".code_review_grandfather"
    if not path.exists():
        _GRANDFATHER_CACHE[cache_key] = set()
        return _GRANDFATHER_CACHE[cache_key]

    entries: set[tuple[str, str]] = set()
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        # Split on whitespace; tolerate multiple spaces between check_id and path
        parts = line.split(None, 1)
        if len(parts) != 2:
            logger.warning(
                ".code_review_grandfather: ignoring malformed line %r", raw_line
            )
            continue
        check_id = parts[0].strip()
        file_path = parts[1].strip().replace("\\", "/")
        entries.add((check_id, file_path))

    _GRANDFATHER_CACHE[cache_key] = entries
    logger.debug(
        "Loaded grandfather list: %d (check_id, file_path) entries", len(entries),
    )
    return entries


def is_grandfathered(check_id: str, file_path: str, grandfather: set[tuple[str, str]]) -> bool:
    """Return True if (check_id, file_path) is in the grandfather set.

    Normalizes ``file_path`` to forward slashes before comparison.
    """
    return (check_id, file_path.replace("\\", "/")) in grandfather


# Cache: {repo_root_str: {"default_db": str, "legacy_dbs": [str, ...], "legacy_yaml": str}}
_STAGING_CFG_CACHE: dict[str, dict] = {}

# Defaults applied when governance_allowlist.yml omits the staging-discipline keys.
# Kept here so the convention is documented in one place rather than scattered in
# the I2 check body.
_STAGING_CFG_DEFAULTS = {
    "default_db": "PSA_PROD",
    "legacy_dbs": ["PSA_PROD", "EDP_BRONZE_PROD"],
    "legacy_yaml": "_sources_base_legacy.yml",
    # Named exemptions for `ref()` in staging. Joined at I2 evaluation time with
    # the BKCC code-level exemption (`ref_business_key_collision`). Default empty
    # so a missing config doesn't accidentally widen the allowlist.
    "ref_exemptions": [],
}


def load_staging_discipline_config(repo_root: Path) -> dict:
    """CD-4: Load staging-discipline config from governance_allowlist.yml.

    Keys read from the YAML (all optional — missing keys fall back to
    sane defaults):
      - ``staging_source_db_default`` (str): permitted DB for sources NOT in
        the legacy YAML. Default ``PSA_PROD``.
      - ``staging_source_db_legacy`` (list[str]): permitted DBs for sources
        registered in ``legacy_sources_yaml``. Default ``[PSA_PROD, EDP_BRONZE_PROD]``.
      - ``legacy_sources_yaml`` (str): basename (not full path) of the YAML
        whose sources may opt into the legacy DB allowance. Default
        ``_sources_base_legacy.yml``.
      - ``staging_ref_exemptions`` (list[str]): named v_psa_stg models that
        staging is permitted to ``ref()`` (in addition to the BKCC code-level
        exemption). Stored lowercased for case-insensitive comparison. Default
        empty (conservative: failure to configure does not widen the rule).
        NOT a wildcard list — each entry is an exact model name. See the
        governance_allowlist.yml header for the rationale.

    Returns the normalized config dict. Memoized per repo_root.

    Returns the defaults silently if the allowlist file is missing — callers
    that need to fail open on missing config should check the result against
    their own "is configured" predicate, not rely on emptiness here.
    """
    import yaml as _yaml

    cache_key = str(repo_root)
    if cache_key in _STAGING_CFG_CACHE:
        return _STAGING_CFG_CACHE[cache_key]

    path = Path(repo_root) / "governance_allowlist.yml"
    if not path.exists():
        _STAGING_CFG_CACHE[cache_key] = dict(_STAGING_CFG_DEFAULTS)
        return _STAGING_CFG_CACHE[cache_key]

    try:
        data = _yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    except _yaml.YAMLError:
        _STAGING_CFG_CACHE[cache_key] = dict(_STAGING_CFG_DEFAULTS)
        return _STAGING_CFG_CACHE[cache_key]

    cfg = {
        "default_db": str(
            data.get("staging_source_db_default") or _STAGING_CFG_DEFAULTS["default_db"]
        ).upper(),
        "legacy_dbs": [
            str(d).upper()
            for d in (
                data.get("staging_source_db_legacy")
                or _STAGING_CFG_DEFAULTS["legacy_dbs"]
            )
        ],
        "legacy_yaml": str(
            data.get("legacy_sources_yaml") or _STAGING_CFG_DEFAULTS["legacy_yaml"]
        ),
        "ref_exemptions": [
            str(name).strip().lower()
            for name in (
                data.get("staging_ref_exemptions")
                or _STAGING_CFG_DEFAULTS["ref_exemptions"]
            )
            if str(name).strip()
        ],
    }
    _STAGING_CFG_CACHE[cache_key] = cfg
    return cfg
