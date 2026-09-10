#!/usr/bin/env python3
"""
pre_tool_guard.py — PreToolUse hook for pipeline enforcement.

Dual-protocol: works with both VS Code Copilot and Claude Code CLI.

10-Rule enforcement for v_psa_stg pipeline. This is the HARDEST enforcement
layer — even if the agent ignores SKILL.md, copilot-instructions.md, and
CLAUDE.md, this hook physically blocks every shortcut at the tool level.

  Rule 1: Block direct SQL/YAML file creation (Write/Edit) without approve-code
  Rule 2: Block direct code generator execution (Bash) without approve-xlsx
  Rule 3: Block direct XLSX generation (Bash) without generate-yaml
  Rule 4: Block reading existing v_psa_stg models (Read) without profile
  Rule 5: Always allow orchestrator commands (Bash pipeline_orchestrator.py)
  Rule 7: Block direct writes to .pipeline_state/ files
  Rule 8: Block Bash rm/mv of files under models/
  Rule 9: Block --force/--reviewed flags on approve-* commands (lesson #107)
  Rule 10: Block && chains that cross gate boundaries (lesson #107)
  Rule 6: Allow everything else

State files: scripts/automation/.pipeline_state/<model_name>.json

Dual-protocol support:
  VS Code Copilot:
    stdin  → {"toolName", "toolInput", ...}  (camelCase)
    stdout → JSON (informational)
    exit 0 → allow, exit 1 → deny

  Claude Code CLI:
    stdin  → {"tool_name", "tool_input", "tool_use_id", "cwd"}
    stdout → {"hookSpecificOutput": {"permissionDecision": "allow|deny", ...}}

VS Code tool name mapping:
    run_in_terminal → Bash
    send_to_terminal → Bash
    create_file → Write
    read_file → Read
    replace_string_in_file → Edit
    multi_replace_string_in_file → Edit

Enforcement modes (env var FBIN_HOOK_MODE):
    audit   — (default) logs what WOULD be blocked to /tmp/fbin_hook_audit.jsonl
    enforce — actively blocks (exit 1) on rule violations

Install: See .github/hooks/pipeline-guard.json for configuration.
"""

import json
import os
import re
import sys
from pathlib import Path

# Pipeline steps in order
ALL_STEPS = [
    "init", "profile", "approve-profile", "generate-yaml",
    "generate-xlsx", "approve-xlsx", "generate-code", "approve-code",
]

# Source registration file that requires approve-code
SOURCES_FILE = "_sources_staging_psa.yml"

# VS Code Copilot → Claude Code tool name mapping
# VS Code sends these tool names; our rules use Claude Code canonical names.
# Tools not in this map pass through unguarded (read-only/orchestration tools).
VSCODE_TOOL_MAP = {
    "run_in_terminal": "Bash",
    "send_to_terminal": "Bash",
    "get_terminal_output": "Bash",
    "create_file": "Write",
    "read_file": "Read",
    "replace_string_in_file": "Edit",
    "multi_replace_string_in_file": "Edit",
    "runSubagent": "Subagent",
}

# Audit log path (written when FBIN_HOOK_MODE=audit)
AUDIT_LOG = Path("/tmp/fbin_hook_audit.jsonl")


def main():
    try:
        raw_input = sys.stdin.read()
        hook_input = json.loads(raw_input)
    except (json.JSONDecodeError, EOFError, ValueError):
        _allow()
        return

    # Dual-protocol field reading: VS Code uses camelCase, Claude Code uses snake_case
    tool_name = (
        hook_input.get("toolName")
        or hook_input.get("tool_name")
        or ""
    )
    tool_input = hook_input.get("toolInput") or hook_input.get("tool_input") or {}
    # VS Code may send toolInput as a string (command text); normalize to dict
    if isinstance(tool_input, str):
        tool_input = {"command": tool_input, "file_path": tool_input}
    cwd = hook_input.get("cwd", os.getcwd())

    # Map VS Code tool names to Claude Code equivalents
    canonical_tool = VSCODE_TOOL_MAP.get(tool_name, tool_name)

    # Only guard relevant tools
    if canonical_tool not in ("Write", "Edit", "Bash", "Read"):
        _allow()
        return

    # Determine enforcement mode: "enforce" blocks, "audit" logs + allows
    # (mode is read later by _deny/_audit helpers via os.environ directly)
    _mode = os.environ.get("FBIN_HOOK_MODE", "audit").lower()  # noqa: F841

    project_root = _find_project_root(cwd)
    if not project_root:
        _allow()
        return

    state_dir = Path(project_root) / "scripts" / "automation" / ".pipeline_state"

    # --- RULE 9: Block --force flag on approve-* commands (lesson #107) ---
    # Must be checked BEFORE Rule 5 (orchestrator allow) to catch malicious flags
    if canonical_tool == "Bash":
        command = tool_input.get("command", "")
        # Check if command contains an approve gate AND the --force flag
        if any(gate in command for gate in [
                "approve-profile", "approve-xlsx", "approve-code"]):
            if "--force" in command or "--reviewed" in command:
                _deny(
                    "⛔ Force-approval of gating commands violates lesson #107.\n"
                    "Approval gates (approve-profile, approve-xlsx, approve-code) "
                    "require explicit user review.\n"
                    "Remove --force/--reviewed flag and present the output "
                    "(profile/XLSX/code) to the user for manual approval first.\n"
                    "Learn: lesson #107 in scripts/automation/lessons.md"
                )
                return

    # --- RULE 10: Block && chains that cross gate boundaries (lesson #107) ---
    # Must be checked BEFORE Rule 5 (orchestrator allow) to catch chained gates
    if canonical_tool == "Bash":
        command = tool_input.get("command", "")
        # Gates that require manual review between each step
        gate_steps = [
            "approve-profile", "approve-xlsx", "approve-code",
            "generate-code", "implement",
        ]
        # Check if command contains && and spans multiple gate steps
        if "&&" in command:
            # Extract orchestrator subcommands from the chained command
            parts = [p.strip() for p in command.split("&&")]
            gate_commands = [
                p for p in parts
                if any(gate in p for gate in gate_steps)
            ]
            # If 2+ gate commands in a single chain, block it
            if len(gate_commands) >= 2:
                _deny(
                    "⛔ Chained gate commands violate lesson #107 "
                    "gating discipline.\n"
                    "Each gate step (approve-profile, approve-xlsx, "
                    "approve-code, generate-code, implement) must be:\n"
                    "  1. Run in a separate terminal invocation\n"
                    "  2. Reviewed/approved by user before proceeding to next step\n"
                    "Do not use && to chain gates. Each step must be intentional and explicit.\n"
                    "Learn: lesson #107 in scripts/automation/lessons.md"
                )
                return

    # --- RULE 5: Allow orchestrator commands always ---
    if canonical_tool == "Bash":
        command = tool_input.get("command", "")
        if "pipeline_orchestrator.py" in command:
            _allow()
            return

    # --- RULE 7: Block direct writes to .pipeline_state/ files ---
    if canonical_tool in ("Write", "Edit"):
        file_path = tool_input.get("file_path", "") or tool_input.get("filePath", "")
        if file_path and ".pipeline_state" in file_path:
            _deny(
                "Direct modification of pipeline state files is forbidden.\n"
                "State files are managed exclusively by pipeline_orchestrator.py.\n"
                "Tampering with state can cause destructive overwrites of shared models."
            )
            return

    # --- RULE 8: Block Bash rm/mv of model files ---
    if canonical_tool == "Bash":
        command = tool_input.get("command", "")
        if re.match(r"\s*(rm|mv)\s+", command) and re.search(r'\bmodels/', command):
            _deny(
                "Direct rm/mv of model files is forbidden.\n"
                "Use pipeline_orchestrator.py to manage model file lifecycle.\n"
                "Deleting or moving model files outside the pipeline can break lineage."
            )
            return

    # --- RULE 1: Block direct SQL/YAML file creation without approve-code ---
    if canonical_tool in ("Write", "Edit"):
        file_path = tool_input.get("file_path", "") or tool_input.get("filePath", "")
        if file_path and _is_guarded_write(file_path):
            model_name = _model_from_file_path(file_path)
            if model_name:
                _check_model_state(
                    state_dir, model_name, "approve-code",
                    "Use pipeline_orchestrator.py \u2014 direct model file creation "
                    "requires completing all pipeline steps first.",
                )
            else:
                # Determine if this is a Raw Vault file that couldn't be mapped
                basename = os.path.basename(file_path)
                is_rv_file = any(
                    basename.startswith(pfx)
                    for pfx in ("hub_", "lnk_", "link_", "tlink_",
                                "sat_", "lsat_", "msat_", "lmsat_", "esat_")
                )
                if is_rv_file:
                    # Raw Vault file without __ source suffix — check active state
                    matched = _check_rv_file_in_active_state(state_dir, basename)
                    if not matched:
                        _deny(
                            "Cannot map Raw Vault file to a pipeline. "
                            "Use pipeline_orchestrator.py to generate Raw Vault objects."
                        )
                else:
                    # Source file edit (_sources_staging_psa.yml) — check any pipeline
                    _check_any_state(
                        state_dir, "approve-code",
                        "Use pipeline_orchestrator.py — direct source registration "
                        "requires completing all pipeline steps first.",
                    )
            return

    # --- RULE 2: Block direct code generator without approve-xlsx ---
    if canonical_tool == "Bash":
        command = tool_input.get("command", "")
        if _is_code_generator(command):
            model_name = _model_from_command(command)
            _check_pipeline_state(
                state_dir, model_name, "approve-xlsx",
                "XLSX must be reviewed and approved before code generation. "
                "Run: python3 scripts/automation/pipeline_orchestrator.py generate-xlsx, "
                "then approve-xlsx.",
            )
            return

    # --- RULE 3: Block direct XLSX generation without generate-yaml ---
    if canonical_tool == "Bash":
        command = tool_input.get("command", "")
        if _is_xlsx_generator(command):
            model_name = _model_from_command(command)
            _check_pipeline_state(
                state_dir, model_name, "generate-yaml",
                "YAML config must be generated before XLSX. "
                "Run: python3 scripts/automation/pipeline_orchestrator.py generate-yaml first.",
            )
            return

    # --- RULE 4: Block reading existing v_psa_stg models without profile ---
    if canonical_tool == "Read":
        file_path = tool_input.get("file_path", "") or tool_input.get("filePath", "")
        if file_path and _is_guarded_read(file_path):
            _check_any_state(
                state_dir, "profile",
                "Do not copy existing models. Use pipeline_orchestrator.py profile "
                "to profile the source table first. The orchestrator generates code "
                "from the profiled data, not from existing patterns.",
            )
            return

    # --- RULE 6: Allow everything else ---
    _allow()


# Raw Vault model prefixes that must go through the pipeline orchestrator
RAW_VAULT_PREFIXES = [
    "v_psa_stg_", "hub_", "lnk_", "link_", "tlink_",
    "sat_", "rsat_", "lsat_", "msat_", "lmsat_", "esat_",
]


# ---------------------------------------------------------------------------
# File/command detection
# ---------------------------------------------------------------------------

def _is_guarded_write(file_path):
    """Check if a file path is a guarded pipeline artifact."""
    basename = os.path.basename(file_path)
    # Normalize: accept both absolute (/models/) and relative (models/) paths
    normalized = file_path.replace("\\", "/")
    in_models = "/models/" in normalized or normalized.startswith("models/")
    # Raw Vault model files (SQL or YAML) under models/
    if in_models and any(
        basename.startswith(prefix)
        for prefix in RAW_VAULT_PREFIXES
    ) and re.search(r"\.(sql|yml|yaml)$", basename):
        return True
    # Source registration file
    if basename == SOURCES_FILE and in_models:
        return True
    return False


def _is_guarded_read(file_path):
    """Check if a file path is a guarded read (existing v_psa_stg models)."""
    basename = os.path.basename(file_path)
    normalized = file_path.replace("\\", "/")
    in_models = "/models/" in normalized or normalized.startswith("models/")
    return bool(
        re.match(r"v_psa_stg_.*\.sql$", basename) and in_models
    )


def _is_code_generator(command):
    """Check if command runs the code generator."""
    if "main.py" in command and ("--yaml-config" in command or "--rootdir" in command):
        return True
    if "build.py" in command and "automation" in command:
        return True
    return False


def _is_xlsx_generator(command):
    """Check if command runs the XLSX generator."""
    return "generate_tech_spec.py" in command



def _check_rv_file_in_active_state(state_dir, basename):
    """Check if a Raw Vault filename appears in any active pipeline state.

    Looks for the file in the 'generated_files' dict of each state file.
    Returns True if found in a pipeline that has reached approve-code.
    """
    import json as _json  # local import to avoid polluting module namespace
    state_dir = Path(state_dir)
    if not state_dir.exists():
        return False
    for sf in state_dir.glob("*.json"):
        try:
            with open(sf, encoding="utf-8") as f:
                state = _json.load(f)
        except (_json.JSONDecodeError, OSError):
            continue
        # Check if this state has generated the file
        generated = state.get("generated_files", {})
        for key in ("hub_sql", "hub_yml", "lnk_sql", "lnk_yml", "sat_sql", "sat_yml"):
            gen_path = generated.get(key, "")
            if gen_path and os.path.basename(gen_path) == basename:
                # Found — check if approve-code is completed
                completed = {s["step"] for s in state.get("steps_completed", [])}
                if "approve-code" in completed:
                    _allow()
                    return True
                else:
                    _deny(
                        f"Pipeline for {state.get('model_name', '?')} has not reached "
                        f"approve-code. Complete the pipeline first."
                    )
                    return True  # _deny already printed JSON; return to exit main()
    return False


def _model_from_file_path(file_path):
    """Extract model name from a pipeline artifact file path.

    Maps hub/sat/lnk files back to their parent v_psa_stg model name.
    Returns None for non-pipeline files.
    """
    basename = os.path.basename(file_path)
    # v_psa_stg files — direct match
    match = re.match(r"(v_psa_stg_[a-z0-9_]+__[a-z0-9_]+)\.(sql|yml|yaml)$", basename)
    if match:
        return match.group(1)
    # Hub/Sat/Link files — derive the v_psa_stg model name they belong to
    for prefix in ("hub_", "lnk_", "link_", "tlink_",
                   "sat_", "lsat_", "msat_", "lmsat_", "esat_", "rsat_"):
        if basename.startswith(prefix):
            remainder = basename[len(prefix):]
            entity_source = remainder.rsplit(".", 1)[0]
            if entity_source and "__" in entity_source:
                return f"v_psa_stg_{entity_source}"
    return None


def _model_from_command(command):
    """Extract model name from command arguments."""
    # --yaml-config path/to/entity__source.yml
    match = re.search(r"--yaml-config\s+\S*?([a-z0-9_]+__[a-z0-9_]+)\.yml", command)
    if match:
        return f"v_psa_stg_{match.group(1)}"
    # --model-name v_psa_stg_entity__source
    match = re.search(r"--model-name\s+(v_psa_stg_[a-z0-9_]+__[a-z0-9_]+)", command)
    if match:
        return match.group(1)
    return None


# ---------------------------------------------------------------------------
# State checking
# ---------------------------------------------------------------------------

def _check_model_state(state_dir, model_name, required_step, deny_msg):
    """Check if a specific model's pipeline has completed the required step."""
    state_file = state_dir / f"{model_name}.json"

    if not state_file.exists():
        _deny(
            f"No pipeline state found for '{model_name}'. {deny_msg}\n"
            f"Start with: python3 scripts/automation/pipeline_orchestrator.py init "
            f"--model-name {model_name} --schema <SCHEMA> --table <TABLE> "
            f"--bk <BK> --rec-src <REC_SRC>"
        )
        return

    completed = _get_completed_steps(state_file)
    if completed is None:
        _deny(f"Pipeline state file corrupt for '{model_name}'. Delete and reinitialize.")
        return

    if required_step not in completed:
        next_step = _next_step(completed)
        _deny(
            f"{deny_msg}\n"
            f"Pipeline '{model_name}' has not reached '{required_step}'.\n"
            f"Next step: python3 scripts/automation/pipeline_orchestrator.py {next_step}\n"
            f"Completed: {', '.join(sorted(completed)) or 'none'}"
        )
        return

    _allow()


def _check_pipeline_state(state_dir, model_name, required_step, deny_msg):
    """Check pipeline state — specific model if known, otherwise any active pipeline."""
    if model_name:
        _check_model_state(state_dir, model_name, required_step, deny_msg)
        return
    _check_any_state(state_dir, required_step, deny_msg)


def _check_any_state(state_dir, required_step, deny_msg):
    """Check if ANY active pipeline has completed the required step."""
    if not state_dir.exists() or not list(state_dir.glob("v_psa_stg_*.json")):
        _deny(
            f"No pipeline state found. {deny_msg}\n"
            f"Start with: python3 scripts/automation/pipeline_orchestrator.py init "
            f"--schema <SCHEMA> --table <TABLE> --bk <BK> --rec-src <REC_SRC>"
        )
        return

    state_files = list(state_dir.glob("v_psa_stg_*.json"))
    for sf in state_files:
        completed = _get_completed_steps(sf)
        if completed and required_step in completed:
            _allow()
            return

    model_names = [sf.stem for sf in state_files]
    _deny(
        f"{deny_msg}\n"
        f"Active pipelines: {', '.join(model_names)}\n"
        f"None have completed '{required_step}'."
    )


# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

def _get_completed_steps(state_file):
    """Load state file and return set of completed step names, or None on error."""
    try:
        with open(state_file, encoding="utf-8") as f:
            state = json.load(f)
        return {s["step"] for s in state.get("steps_completed", [])}
    except (json.JSONDecodeError, OSError, KeyError):
        return None


def _next_step(completed):
    """Determine the next pipeline step."""
    return next((s for s in ALL_STEPS if s not in completed), "init")


def _find_project_root(start_dir):
    """Walk up from start_dir looking for CLAUDE.md or .git."""
    current = Path(start_dir).resolve()
    for _ in range(20):
        if (current / "CLAUDE.md").exists() or (current / ".git").is_dir():
            return str(current)
        parent = current.parent
        if parent == current:
            break
        current = parent
    return None


def _allow():
    """Output allow decision (exit 0). Compatible with both VS Code and Claude Code."""
    # Claude Code protocol (JSON stdout)
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
        }
    }))
    # VS Code protocol: exit 0 = allow
    sys.exit(0)


def _deny(reason):
    """Handle deny decision. In enforce mode: exit 1. In audit mode: log + exit 0."""
    mode = os.environ.get("FBIN_HOOK_MODE", "audit").lower()

    if mode == "enforce":
        # Claude Code protocol (JSON stdout with deny)
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }))
        # VS Code protocol: exit 1 = deny
        sys.exit(1)
    else:
        # Audit mode: log what WOULD have been blocked, then allow
        _audit_log(reason)
        # Still output allow
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
            }
        }))
        sys.exit(0)


def _audit_log(reason):
    """Write audit entry to JSONL log showing what would have been blocked."""
    try:
        import datetime
        entry = {
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "event": "would_deny",
            "reason": reason.replace("\n", " | "),
        }
        with open(AUDIT_LOG, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry) + "\n")
    except OSError:
        pass  # Non-fatal — audit logging should never break the hook


if __name__ == "__main__":
    main()
