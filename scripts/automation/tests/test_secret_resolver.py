"""
test_secret_resolver.py — Unit tests for OS-keychain-backed secret resolver.

Covers every branch of the contract documented in src/secret_resolver.py:
  - Non-string input passed through unchanged
  - Plain (non-placeholder) string passed through unchanged
  - Placeholder with unknown id passed through unchanged
  - Non-macOS platform passed through unchanged (silent skip)
  - macOS + known id + keychain hit  -> returns secret
  - macOS + known id + keychain miss -> placeholder passed through
  - macOS + `security` CLI missing   -> placeholder passed through
  - macOS + timeout                  -> placeholder passed through
  - resolve_env_dict applies to string values only, preserves others
  - resolve_env_dict does not mutate input dict

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_secret_resolver.py -v
"""
import subprocess
import sys
from pathlib import Path
from unittest import mock

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

import secret_resolver  # noqa: E402
from secret_resolver import (  # noqa: E402
    INPUT_TO_KEYCHAIN,
    resolve_env_dict,
    resolve_placeholder,
)


# ── Pass-through contract ──────────────────────────────────────────────────────

class TestPassThrough:
    """Anything that isn't a resolvable placeholder must come back unchanged."""

    def test_non_string_none_passes_through(self):
        assert resolve_placeholder(None) is None

    def test_non_string_int_passes_through(self):
        assert resolve_placeholder(42) == 42

    def test_plain_string_passes_through(self):
        assert resolve_placeholder("FBHS-FBHS_GPG") == "FBHS-FBHS_GPG"

    def test_empty_string_passes_through(self):
        assert resolve_placeholder("") == ""

    def test_placeholder_with_unknown_id_passes_through(self):
        val = "${input:not_in_registry}"
        assert resolve_placeholder(val) == val

    def test_partial_placeholder_not_matched(self):
        # Must be the WHOLE value, not embedded
        val = "prefix${input:snowflake_password}suffix"
        assert resolve_placeholder(val) == val

    def test_malformed_placeholder_not_matched(self):
        for bad in ("${input:}", "${input}", "$input:snowflake_password",
                    "${input:foo;rm -rf /}", "${input:foo bar}"):
            assert resolve_placeholder(bad) == bad

    def test_trailing_content_not_matched(self, monkeypatch):
        """SECURITY: a string that STARTS with a placeholder but has trailing
        content must NOT be treated as the placeholder. Otherwise an attacker
        (or buggy mcp.json edit) could append content and exfiltrate the secret.

        Specifically locks in that the regex uses the `\\Z` end-of-string anchor
        rather than `$`. Python's `$` matches before a trailing newline by
        default, so a regex anchored with `$` would happily accept
        `\"${input:snowflake_password}\\n\"` and resolve the secret — a real
        bug that mutation testing caught during PR #1783.
        """
        monkeypatch.setattr(secret_resolver, "_is_macos", lambda: True)
        # If anchors were dropped, this lookup would be reached and "leak" the secret
        monkeypatch.setattr(secret_resolver, "_lookup_macos_keychain",
                            lambda s, a: "LEAKED-SECRET-MUST-NOT-APPEAR")
        for bad in ("${input:snowflake_password}suffix",
                    "${input:snowflake_password}; rm -rf /",
                    "${input:snowflake_password}\n",
                    "${input:snowflake_password} "):
            result = resolve_placeholder(bad)
            assert result == bad, f"trailing content leaked secret for: {bad!r}"
            assert "LEAKED" not in result


# ── Platform gating ────────────────────────────────────────────────────────────

class TestPlatformGating:

    def test_non_macos_returns_placeholder(self, monkeypatch):
        monkeypatch.setattr(secret_resolver, "_is_macos", lambda: False)
        # security CLI must NOT be called on non-macOS
        spy = mock.Mock(side_effect=AssertionError("should not be called"))
        monkeypatch.setattr(secret_resolver, "_lookup_macos_keychain", spy)
        val = "${input:snowflake_password}"
        assert resolve_placeholder(val) == val
        spy.assert_not_called()


# ── macOS keychain resolution ──────────────────────────────────────────────────

class TestMacosResolution:

    def _mock_macos(self, monkeypatch):
        monkeypatch.setattr(secret_resolver, "_is_macos", lambda: True)

    def test_known_id_hit_returns_secret(self, monkeypatch):
        self._mock_macos(monkeypatch)
        monkeypatch.setattr(
            secret_resolver, "_lookup_macos_keychain",
            lambda s, a: "the-real-pat-value" if (s, a) == ("fbin-snowflake", "pat") else None
        )
        assert resolve_placeholder("${input:snowflake_password}") == "the-real-pat-value"

    def test_known_id_miss_returns_placeholder(self, monkeypatch):
        self._mock_macos(monkeypatch)
        monkeypatch.setattr(secret_resolver, "_lookup_macos_keychain", lambda s, a: None)
        val = "${input:snowflake_password}"
        assert resolve_placeholder(val) == val

    def test_all_registered_ids_route_to_correct_keychain_entry(self, monkeypatch):
        """Critical contract: every entry in INPUT_TO_KEYCHAIN must route correctly."""
        self._mock_macos(monkeypatch)
        seen = []
        monkeypatch.setattr(
            secret_resolver, "_lookup_macos_keychain",
            lambda s, a: (seen.append((s, a)), f"secret-for-{s}-{a}")[1]
        )
        for input_id, expected in INPUT_TO_KEYCHAIN.items():
            result = resolve_placeholder(f"${{input:{input_id}}}")
            assert result == f"secret-for-{expected[0]}-{expected[1]}"
        # Every registered id was looked up via the correct (service, account)
        assert set(seen) == set(INPUT_TO_KEYCHAIN.values())


# ── Subprocess error handling ──────────────────────────────────────────────────

class TestKeychainSubprocessErrors:

    def _force_macos(self, monkeypatch):
        monkeypatch.setattr(secret_resolver, "_is_macos", lambda: True)

    def test_security_cli_missing_returns_none(self, monkeypatch):
        self._force_macos(monkeypatch)
        monkeypatch.setattr(
            secret_resolver.subprocess, "run",
            mock.Mock(side_effect=FileNotFoundError("security not found"))
        )
        val = "${input:snowflake_password}"
        assert resolve_placeholder(val) == val  # placeholder preserved

    def test_security_cli_timeout_returns_none(self, monkeypatch):
        self._force_macos(monkeypatch)
        monkeypatch.setattr(
            secret_resolver.subprocess, "run",
            mock.Mock(side_effect=subprocess.TimeoutExpired(cmd="security", timeout=5))
        )
        val = "${input:snowflake_password}"
        assert resolve_placeholder(val) == val

    def test_security_cli_nonzero_returns_none(self, monkeypatch):
        self._force_macos(monkeypatch)
        result = mock.Mock(returncode=44, stdout="", stderr="not found")
        monkeypatch.setattr(secret_resolver.subprocess, "run", mock.Mock(return_value=result))
        val = "${input:snowflake_password}"
        assert resolve_placeholder(val) == val

    def test_security_cli_empty_stdout_returns_none(self, monkeypatch):
        """Empty stdout (rc=0 but no secret) is treated as miss, not as ''."""
        self._force_macos(monkeypatch)
        result = mock.Mock(returncode=0, stdout="\n", stderr="")
        monkeypatch.setattr(secret_resolver.subprocess, "run", mock.Mock(return_value=result))
        val = "${input:snowflake_password}"
        assert resolve_placeholder(val) == val

    def test_security_cli_uses_arg_list_not_shell(self, monkeypatch):
        """Security gate: subprocess must be called with a list, never shell=True."""
        self._force_macos(monkeypatch)
        captured = {}

        def fake_run(*args, **kwargs):
            captured["args"] = args
            captured["kwargs"] = kwargs
            return mock.Mock(returncode=0, stdout="value\n", stderr="")

        monkeypatch.setattr(secret_resolver.subprocess, "run", fake_run)
        resolve_placeholder("${input:snowflake_password}")
        assert isinstance(captured["args"][0], list), "must pass arg list, not shell string"
        assert captured["kwargs"].get("shell") in (None, False), "shell=True is a security risk"
        assert "timeout" in captured["kwargs"], "must have a timeout"


# ── resolve_env_dict ──────────────────────────────────────────────────────────

class TestResolveEnvDict:

    def test_mixed_dict(self, monkeypatch):
        monkeypatch.setattr(secret_resolver, "_is_macos", lambda: True)
        monkeypatch.setattr(
            secret_resolver, "_lookup_macos_keychain",
            lambda s, a: "RESOLVED" if (s, a) == ("fbin-snowflake", "pat") else None
        )
        env = {
            "SNOWFLAKE_PASSWORD": "${input:snowflake_password}",
            "SNOWFLAKE_ACCOUNT":  "FBHS-FBHS_GPG",
            "TIMEOUT":            30,
            "EMPTY":              "",
            "OTHER":              "${input:not_in_registry}",
        }
        result = resolve_env_dict(env)
        assert result["SNOWFLAKE_PASSWORD"] == "RESOLVED"
        assert result["SNOWFLAKE_ACCOUNT"]  == "FBHS-FBHS_GPG"
        assert result["TIMEOUT"]            == 30
        assert result["EMPTY"]              == ""
        assert result["OTHER"]              == "${input:not_in_registry}"

    def test_does_not_mutate_input(self, monkeypatch):
        monkeypatch.setattr(secret_resolver, "_is_macos", lambda: True)
        monkeypatch.setattr(
            secret_resolver, "_lookup_macos_keychain", lambda s, a: "RESOLVED"
        )
        original = {"X": "${input:snowflake_password}"}
        snapshot = dict(original)
        _ = resolve_env_dict(original)
        assert original == snapshot, "resolve_env_dict must not mutate the input dict"


# ── Critical regression guard ──────────────────────────────────────────────────

class TestNoLeakage:
    """If resolution fails, the placeholder MUST come back — never an empty string,
    never None, never a partial value. The orchestrator's auth fallback depends
    on detecting the placeholder prefix `${input:` to know the credential was
    not provided."""

    def test_failed_resolution_preserves_input_prefix(self, monkeypatch):
        monkeypatch.setattr(secret_resolver, "_is_macos", lambda: True)
        monkeypatch.setattr(secret_resolver, "_lookup_macos_keychain", lambda s, a: None)
        result = resolve_placeholder("${input:snowflake_password}")
        assert result.startswith("${input:"), \
            "failed resolution must preserve placeholder so caller can detect 'not provided'"
