"""Migrate `.vscode/mcp.json` from cleartext secrets to VS Code `${input:...}`.

Why this exists
---------------
Three cleartext secrets were observed in `.vscode/mcp.json` during a security
review on 2026-06-04:

  - servers.snow-mcp.env.SNOWFLAKE_PASSWORD
  - servers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN
  - servers.dbt-mcp.env.DBT_TOKEN

The file is `.gitignore`d and never committed, but `.gitignore` does NOT
prevent the VS Code "attach file to context" UI from sending the file
to the chat extension. Defense in depth requires that secrets never sit
in a file the IDE might attach, regardless of git status.

VS Code MCP supports `${input:varname}` substitution — the IDE prompts
at session start and stores the entered value in the OS keychain, not
on disk.

What this script does
---------------------
1. Reads `.vscode/mcp.json` (JSONC-aware: strips //, /* */ comments)
2. Rewrites the three known secret fields to `${input:NAME}` placeholders
3. Adds an `inputs` array with `password`-type prompts for each
4. Writes the new file to `.vscode/mcp.json.migrated` (does NOT overwrite)
5. Prints ONLY which paths changed, never the secret values

Operator does the cut-over manually:
    mv .vscode/mcp.json .vscode/mcp.json.preinput.bak  # local backup
    mv .vscode/mcp.json.migrated .vscode/mcp.json
    rm .vscode/mcp.json.preinput.bak                   # after smoke test

Then restart VS Code; first MCP tool call triggers the three prompts.

Safety notes
------------
- Never logs secret VALUES — only paths and the literal `${input:...}` strings
- Idempotent: re-running on an already-migrated file leaves it unchanged
- Refuses to run if any of the three target paths are missing
- Strips JSONC comments because Python stdlib `json` cannot parse them.
  Comments are NOT preserved in the output (intentional — the file should
  be machine-managed, not hand-edited).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


# ---- The migration plan: (json-path, input-id, prompt description) -------- #
# Adding a new secret? Append to this tuple. The script will refuse to run
# if a path is missing — that is the desired failure mode.
MIGRATIONS: tuple[tuple[tuple[str, ...], str, str], ...] = (
    (
        ("servers", "snow-mcp", "env", "SNOWFLAKE_PASSWORD"),
        "snowflake_password",
        "Snowflake PAT (JWT). Stored in OS keychain by VS Code.",
    ),
    (
        ("servers", "github", "env", "GITHUB_PERSONAL_ACCESS_TOKEN"),
        "github_pat",
        "GitHub Personal Access Token (fine-grained). Stored in OS keychain.",
    ),
    (
        ("servers", "dbt-mcp", "env", "DBT_TOKEN"),
        "dbt_cloud_token",
        "dbt Cloud service token (Admin v2 API read). Stored in OS keychain.",
    ),
)

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
SOURCE = REPO_ROOT / ".vscode" / "mcp.json"
DEST = REPO_ROOT / ".vscode" / "mcp.json.migrated"


# ---- JSONC comment stripping (line + block) ------------------------------- #
# Stateful single-pass scanner: tracks string boundaries so `https://...` and
# similar are preserved while `//` and `/* */` outside strings are stripped.
def _strip_jsonc(text: str) -> str:
    out: list[str] = []
    i = 0
    n = len(text)
    in_string = False
    while i < n:
        ch = text[i]
        if in_string:
            if ch == "\\" and i + 1 < n:
                # Preserve the escape and its argument verbatim.
                out.append(text[i : i + 2])
                i += 2
                continue
            if ch == '"':
                in_string = False
            out.append(ch)
            i += 1
            continue
        # Not in string — comments are possible.
        if ch == "/" and i + 1 < n and text[i + 1] == "/":
            # Line comment — skip to newline (preserve the newline itself).
            j = text.find("\n", i)
            if j == -1:
                break
            i = j
            continue
        if ch == "/" and i + 1 < n and text[i + 1] == "*":
            # Block comment — skip through */.
            j = text.find("*/", i + 2)
            if j == -1:
                raise ValueError("unterminated /* block comment")
            i = j + 2
            continue
        if ch == '"':
            in_string = True
        out.append(ch)
        i += 1
    return "".join(out)


def _walk(obj: Any, path: tuple[str, ...]) -> Any:
    """Return the nested value at `path`. Raises KeyError on miss."""
    cur = obj
    for key in path:
        if not isinstance(cur, dict) or key not in cur:
            raise KeyError(".".join(path))
        cur = cur[key]
    return cur


def _set(obj: Any, path: tuple[str, ...], value: Any) -> None:
    """Set the nested value at `path`."""
    cur = obj
    for key in path[:-1]:
        cur = cur[key]
    cur[path[-1]] = value


def migrate() -> int:
    if not SOURCE.exists():
        print(f"ERROR: source not found: {SOURCE}", file=sys.stderr)
        return 2

    raw = SOURCE.read_text(encoding="utf-8")
    try:
        cleaned = _strip_jsonc(raw)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 3

    try:
        doc = json.loads(cleaned)
    except json.JSONDecodeError as exc:
        print(f"ERROR: source is not valid JSON after comment strip: {exc}", file=sys.stderr)
        return 4

    # Validate every migration target exists. Refuse to partially migrate.
    missing: list[str] = []
    for path, _input_id, _prompt in MIGRATIONS:
        try:
            _walk(doc, path)
        except KeyError as exc:
            missing.append(str(exc))
    if missing:
        print(
            "ERROR: cannot migrate — missing paths in source:\n  - "
            + "\n  - ".join(missing),
            file=sys.stderr,
        )
        return 5

    # Rewrite each target. Print PATH only, never the value being replaced.
    print(f"Migrating {SOURCE} → {DEST}")
    print(f"  source size: {SOURCE.stat().st_size:,} bytes")
    rewrites = 0
    already = 0
    for path, input_id, _prompt in MIGRATIONS:
        existing = _walk(doc, path)
        placeholder = f"${{input:{input_id}}}"
        if existing == placeholder:
            print(f"  - {'.'.join(path):60s}  already migrated")
            already += 1
            continue
        # Length-only debug (never the value)
        if isinstance(existing, str):
            print(f"  - {'.'.join(path):60s}  rewriting ({len(existing)}-char value → ${{input:{input_id}}})")
        else:
            print(f"  - {'.'.join(path):60s}  rewriting (non-str → ${{input:{input_id}}})")
        _set(doc, path, placeholder)
        rewrites += 1

    # Inject or merge the `inputs` array at the top level.
    desired_inputs = [
        {
            "id": input_id,
            "type": "promptString",
            "description": prompt,
            "password": True,
        }
        for _path, input_id, prompt in MIGRATIONS
    ]
    existing_inputs = doc.get("inputs", [])
    if not isinstance(existing_inputs, list):
        print(f"ERROR: existing `inputs` is not a list: {type(existing_inputs).__name__}", file=sys.stderr)
        return 6
    existing_ids = {item.get("id") for item in existing_inputs if isinstance(item, dict)}
    merged = list(existing_inputs)
    for spec in desired_inputs:
        if spec["id"] in existing_ids:
            print(f"  - inputs[id={spec['id']!r}]                              already present")
        else:
            merged.append(spec)
            print(f"  - inputs[id={spec['id']!r}]                              added")
    doc["inputs"] = merged

    # Write the migrated doc to DEST. Not atomic, no fsync — durability
    # is provided by the documented review-before-promote pattern in
    # "Next steps" below (inspect DEST, rename SOURCE → .preinput.bak,
    # rename DEST → SOURCE), NOT by a write-then-sync guarantee here.
    # Earlier revision over-claimed "write then fsync"; corrected in
    # PR #1821 Commit 6 (R4 finding N5) so the comment matches the code.
    DEST.write_text(json.dumps(doc, indent=2) + "\n", encoding="utf-8")
    print(f"  dest size:   {DEST.stat().st_size:,} bytes")
    print(f"\nSummary: {rewrites} rewritten, {already} already migrated, "
          f"{len(desired_inputs)} input prompts ensured.")
    print(f"\nNext steps:")
    print(f"  1. Inspect {DEST.relative_to(REPO_ROOT)} (no secrets present)")
    print(f"  2. mv {SOURCE.relative_to(REPO_ROOT)} {SOURCE.relative_to(REPO_ROOT)}.preinput.bak")
    print(f"  3. mv {DEST.relative_to(REPO_ROOT)} {SOURCE.relative_to(REPO_ROOT)}")
    print(f"  4. Restart VS Code; first MCP tool call triggers the input prompts")
    print(f"  5. After smoke test passes, rm .vscode/mcp.json.preinput.bak")
    return 0


if __name__ == "__main__":
    sys.exit(migrate())
