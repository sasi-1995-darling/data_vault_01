"""
secret_resolver.py — Resolve VS Code mcp.json ${input:<id>} placeholders from
the OS keychain (macOS only today; pluggable for Windows/Linux later).

Design contract (DO NOT BREAK):
  - resolve_placeholder(value) NEVER raises.
  - If `value` is not a string, returns value UNCHANGED (defensive — mcp.json
    technically allows non-string JSON values; we refuse to crash on them).
  - If `value` does not match ${input:<id>}, returns value UNCHANGED.
  - If the input id is not registered in INPUT_TO_KEYCHAIN, returns value UNCHANGED.
  - If the platform is not macOS, returns value UNCHANGED (silent skip).
  - If the keychain lookup fails for any reason, returns value UNCHANGED.
  - On success (string in, keychain hit), returns the resolved secret string.

Net effect: zero behavioral change for users who do not set up keychain entries.
Adopters get transparent secret resolution. The existing fallback chain in
pipeline_orchestrator._run_snowflake_query() handles all "still unresolved"
cases via the same error paths it uses today.

Security notes:
  - service / account names are hardcoded constants — no shell interpolation
    of untrusted input is possible.
  - subprocess.run is invoked with an arg list (never shell=True) and a
    short timeout to prevent hangs.
  - The resolved secret is returned in-process and never logged or written
    to disk by this module.

One-time setup (per adopter, on macOS):
    security add-generic-password -s fbin-snowflake -a pat   -w '<PAT>'   -U
    security add-generic-password -s fbin-github    -a pat   -w '<TOKEN>' -U
    security add-generic-password -s fbin-dbt-cloud -a token -w '<TOKEN>' -U
"""
from __future__ import annotations

import re
import subprocess
import sys
from typing import Any, Optional, Tuple

# ── Registry ──────────────────────────────────────────────────────────────────
# Maps the `id` field of a VS Code mcp.json input entry to
# (keychain_service, keychain_account). Add new entries here when you add
# a new ${input:...} placeholder to mcp.json.
INPUT_TO_KEYCHAIN: dict[str, Tuple[str, str]] = {
    "snowflake_password": ("fbin-snowflake", "pat"),
    "github_pat":         ("fbin-github",    "pat"),
    "dbt_cloud_token":    ("fbin-dbt-cloud", "token"),
}

# Match exactly ${input:<id>} where <id> is the form VS Code accepts:
# letters, digits, underscore, hyphen. Anchored with ^ and \Z to reject ANY
# trailing content (including a trailing \n — Python's `$` matches before
# a trailing newline by default, which is a subtle security footgun).
_PLACEHOLDER_RE = re.compile(r"^\$\{input:([A-Za-z0-9_\-]+)\}\Z")

# Short timeout — `security` is a local call; anything > 5s means trouble.
_KEYCHAIN_TIMEOUT_SEC = 5


def _is_macos() -> bool:
    return sys.platform == "darwin"


def _lookup_macos_keychain(service: str, account: str) -> Optional[str]:
    """Run `security find-generic-password -s <service> -a <account> -w`.

    Returns the secret string on success, or None on any failure
    (not found, permission denied, timeout, security CLI missing).
    Never raises.
    """
    try:
        result = subprocess.run(
            ["security", "find-generic-password",
             "-s", service, "-a", account, "-w"],
            capture_output=True,
            text=True,
            timeout=_KEYCHAIN_TIMEOUT_SEC,
            check=False,   # we inspect returncode ourselves
        )
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return None

    if result.returncode != 0:
        return None
    secret = result.stdout.rstrip("\n")
    return secret or None


def resolve_placeholder(value: Any) -> Any:
    """Resolve a VS Code mcp.json ${input:<id>} placeholder via OS keychain.

    Accepts Any because mcp.json values flow in untyped from JSON parsing
    (strings, numbers, bools, None). Non-strings are passed through unchanged
    so callers can wrap arbitrary env-dict values without pre-filtering.

    Returns:
        - `value` unchanged when it is not a string, not a placeholder, the
          id is unknown, the platform is unsupported, or the keychain lookup
          fails. The return type mirrors the input type in those cases.
        - the resolved secret string on success (always `str`).

    Never raises. Never logs the secret. Never logs the placeholder content.
    """
    if not isinstance(value, str):
        return value

    match = _PLACEHOLDER_RE.match(value)
    if not match:
        return value

    input_id = match.group(1)
    mapping = INPUT_TO_KEYCHAIN.get(input_id)
    if mapping is None:
        return value

    if not _is_macos():
        return value

    service, account = mapping
    resolved = _lookup_macos_keychain(service, account)
    if resolved is None:
        return value
    return resolved


def resolve_env_dict(env: dict) -> dict:
    """Apply resolve_placeholder() to every string value in an env dict.

    Returns a NEW dict — does not mutate the input.
    Non-string values are passed through unchanged.
    """
    return {k: (resolve_placeholder(v) if isinstance(v, str) else v)
            for k, v in env.items()}
