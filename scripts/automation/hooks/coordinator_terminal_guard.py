#!/usr/bin/env python3
"""
coordinator_terminal_guard.py — VS Code Copilot PreToolUse hook.

WARNING: NO ENFORCEMENT ACTIVE in current VS Code Copilot environment.
VS Code Copilot does NOT invoke hooks from .github/hooks/. This script
is preserved ONLY for future protocol adoption if VS Code adds
Claude-Code-style hook support. Do NOT rely on this for security
enforcement.

Blocks run_in_terminal and send_to_terminal for the DV Pipeline
Coordinator agent. All other agents are allowed terminal access.

This is the HARD enforcement layer. Prompt engineering (Cardinal Rule,
identity framing, tool restrictions in frontmatter) does NOT prevent
the LLM from using available tools. This hook physically denies the
tool call at the platform level, forcing the LLM to pivot to
runSubagent dispatch.

Detection Strategy:
  1. Check hook input for agent identity fields (VS Code may provide)
  2. If unavailable, default to DENY for terminal tools (fail-closed)

Diagnostics:
  First run logs hook input keys to /tmp/copilot_hook_debug.jsonl
  for one-time analysis of available fields. Delete after verified.

Hook Protocol:
  stdin  → JSON with tool invocation context
  stdout → JSON with permissionDecision: allow|deny

Uses ONLY stdlib — no pip packages required. Runs with system python3.
"""

import json
import os
import sys

# VS Code Copilot tool names to block
TERMINAL_TOOLS = frozenset({"run_in_terminal", "send_to_terminal"})

# Also check Claude Code tool names (in case VS Code translates)
CLAUDE_TERMINAL_TOOLS = frozenset({"Bash"})

# Agents that should be BLOCKED from terminal access
BLOCKED_AGENTS = frozenset({"DV Pipeline Coordinator"})

# Agents that should be ALLOWED terminal access (subagents)
ALLOWED_AGENTS = frozenset({
    "DV Source Analyzer",
    "DV Model Generator",
    "DV Validator",
})

# Debug log for one-time diagnostics
# TODO: Add log rotation (max 1MB or 1000 entries) if this hook is re-enabled.
# Currently inert — coordinator-terminal-guard.json has hooks: {}.
DEBUG_LOG = "/tmp/copilot_hook_debug.jsonl"


def main():
    # Per-developer bypass: set FBIN_HOOK_BYPASS=1 in your shell profile
    # to disable the hook for non-coordinator work. Unset before testing
    # the Coordinator. This avoids the fragile .json.disabled rename pattern.
    if os.environ.get("FBIN_HOOK_BYPASS") == "1":
        _allow()
        return

    try:
        raw = sys.stdin.read()
        hook_input = json.loads(raw)
    except (json.JSONDecodeError, EOFError, ValueError):
        _allow()
        return

    tool_name = hook_input.get("tool_name", "")

    # Only intercept terminal tools — allow everything else immediately
    if tool_name not in TERMINAL_TOOLS and tool_name not in CLAUDE_TERMINAL_TOOLS:
        _allow()
        return

    # --- Diagnostic logging (delete /tmp/copilot_hook_debug.jsonl after verified) ---
    _log_debug(hook_input, tool_name)

    # --- Agent detection ---
    # VS Code Copilot does NOT include agent name in hook input (verified via
    # debug log: keys are cwd, hook_event_name, session_id, timestamp,
    # tool_input, tool_name, tool_use_id, transcript_path — no agent field).
    #
    # The transcript_path points to session JSONL but the system prompt
    # (which contains the agent instructions) is NOT stored there — only
    # user messages and assistant responses. Searching for "DV Pipeline
    # Coordinator" in the transcript gives INVERTED results: it matches
    # sessions discussing the coordinator, not sessions running AS it.
    #
    # DESIGN DECISION: Fail-closed. Block ALL terminal access in this
    # workspace. The coordinator is the primary user-facing agent and
    # needs to be blocked. When working in non-coordinator sessions
    # (default Agent, debugging, etc.), rename this hook:
    #   mv .github/hooks/coordinator-terminal-guard.json \
    #      .github/hooks/coordinator-terminal-guard.json.disabled
    #
    # This is a known VS Code Copilot limitation: hooks cannot be
    # scoped to specific agents. The hook fires for all sessions.
    #
    # Fallback: try direct agent detection methods (future-proofing
    # for when VS Code adds agent identity to hook input).
    agent = _detect_agent(hook_input)

    if agent:
        if agent in BLOCKED_AGENTS:
            _deny_coordinator()
        elif agent in ALLOWED_AGENTS:
            _allow()
        else:
            # Unknown agent — allow (not the coordinator)
            _allow()
        return

    # No agent detected → fail-closed: block terminal
    _deny_coordinator()


def _detect_agent(hook_input: dict) -> str:
    """Try to extract agent name from hook input via direct fields."""

    # Method 1: Direct agent name fields in hook input
    for key in ("agentName", "agent_name", "agentSlug", "agent",
                "agentId", "agent_id", "chatAgent", "selectedAgent"):
        val = hook_input.get(key)
        if val and isinstance(val, str):
            return val

    # Method 2: Nested context/metadata object
    for container_key in ("context", "metadata", "session"):
        container = hook_input.get(container_key)
        if isinstance(container, dict):
            for key in ("agentName", "agent_name", "agent"):
                val = container.get(key)
                if val and isinstance(val, str):
                    return val

    # Method 3: Environment variable (VS Code might set this)
    for env_key in ("COPILOT_AGENT_NAME", "COPILOT_AGENT", "AGENT_NAME"):
        val = os.environ.get(env_key, "")
        if val:
            return val

    return ""


def _log_debug(hook_input: dict, tool_name: str):
    """Log hook input structure for diagnostics. Delete log after verified."""
    try:
        entry = {
            "tool_name": tool_name,
            "input_keys": sorted(hook_input.keys()),
            "input_preview": {
                k: (str(v)[:300] if not isinstance(v, dict) else
                    {"_keys": sorted(v.keys())} if isinstance(v, dict) else
                    str(v)[:300])
                for k, v in hook_input.items()
                if k != "tool_input"  # skip potentially large tool arguments
            },
            "env_copilot_keys": sorted([
                k for k in os.environ if "COPILOT" in k.upper() or "AGENT" in k.upper()
            ]),
        }
        with open(DEBUG_LOG, "a") as f:
            f.write(json.dumps(entry) + "\n")
    except OSError:
        pass


def _allow():
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
        }
    }))
    sys.exit(0)


def _deny_coordinator():
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                "DENIED: Terminal access is blocked for the DV Pipeline Coordinator. "
                "Use the 'runSubagent' tool to dispatch this command to a subagent."
            ),
            "additionalContext": (
                "You are the DV Pipeline Coordinator. You CANNOT run terminal "
                "commands yourself. You MUST use the 'runSubagent' tool to delegate.\n\n"
                "Use runSubagent like this:\n\n"
                "For init/profile/show-profile commands:\n"
                "  Delegate to 'DV Source Analyzer' with a prompt describing the "
                "pipeline_orchestrator.py command and all parameters.\n\n"
                "For approve-profile/generate-yaml/generate-xlsx/approve-xlsx/"
                "add-raw-vault/generate-code commands:\n"
                "  Delegate to 'DV Model Generator' with the command details.\n\n"
                "For approve-code/implement/dbt build commands:\n"
                "  Delegate to 'DV Validator' with the command details.\n\n"
                "Do NOT attempt run_in_terminal again — it will always be denied. "
                "runSubagent is your ONLY path to execution."
            ),
        }
    }))
    sys.exit(0)


if __name__ == "__main__":
    main()
